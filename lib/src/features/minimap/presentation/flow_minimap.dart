import 'package:equatable/equatable.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/minimap/presentation/painters/minimap_painter.dart';
import 'package:lattice/src/core/theme/components/minimap_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/viewport/domain/viewport_transform.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MinimapGraphModel extends Equatable {
  final Map<String, FlowNode> nodes;
  final Set<String> selectedNodeIds;
  final Size viewportSize;

  const _MinimapGraphModel({
    required this.nodes,
    required this.selectedNodeIds,
    required this.viewportSize,
  });

  @override
  List<Object?> get props => [nodes, selectedNodeIds, viewportSize];
}

typedef MiniMapNodeProperty<T> = T Function(FlowNode node);
typedef MiniMapNodeColorFunc = Color? Function(FlowNode node);
typedef MiniMapNodeBuilder = Path Function(FlowNode node);
typedef MiniMapNodeOnClick = void Function(FlowNode node);

class FlowMiniMap extends ConsumerWidget {
  final bool pannable;
  final bool zoomable;
  final bool inversePan;
  final Size size;
  final Alignment alignment;
  final EdgeInsetsGeometry margin;
  final FlowMinimapStyle? minimapStyle;

  final MiniMapNodeColorFunc? nodeColor;
  final MiniMapNodeColorFunc? nodeStrokeColor;
  final MiniMapNodeProperty<double>? nodeStrokeWidth;
  final MiniMapNodeProperty<double>? nodeBorderRadius;
  final MiniMapNodeBuilder? nodeBuilder;
  final MiniMapNodeOnClick? onClickNode;

  const FlowMiniMap({
    super.key,
    this.size = const Size(200, 150),
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.all(20),
    this.minimapStyle,
    this.pannable = true,
    this.zoomable = true,
    this.inversePan = false,
    this.nodeColor,
    this.nodeStrokeColor,
    this.nodeStrokeWidth,
    this.nodeBorderRadius,
    this.nodeBuilder,
    this.onClickNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final isLocked = ref.watch(
      internalControllerProvider.select((s) => s.isPanZoomLocked),
    );

    // Rebuild graph only when the nodes map identity or pane size changes —
    // not on every Freezed viewport tick.
    final graph = ref.watch(internalControllerProvider.select((s) {
      return _MinimapGraphModel(
        nodes: s.nodes,
        selectedNodeIds: s.selectedNodes,
        viewportSize: s.viewportSize ?? Size.zero,
      );
    }));

    final baseTheme =
        context.flowCanvasTheme.minimap ?? FlowMinimapStyle.system(context);
    final theme = baseTheme.merge(minimapStyle);
    final committedList = graph.nodes.values.toList(growable: false);
    final canPan = pannable && !isLocked;
    final canZoom = zoomable && !isLocked;

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: theme.borderRadius,
          border:
              Border.all(color: theme.maskStrokeColor.withAlpha(125), width: 1),
          boxShadow: theme.shadows,
        ),
        child: ClipRRect(
          borderRadius: theme.borderRadius,
          child: ListenableBuilder(
            listenable: Listenable.merge(
                [controller.liveViewport, controller.interactionSession]),
            builder: (context, _) {
              final live = controller.liveViewport.viewport;
              final vpSize = graph.viewportSize;
              final topLeft = flowPointFromViewportPoint(
                Offset.zero,
                live,
              );
              final bottomRight = flowPointFromViewportPoint(
                Offset(vpSize.width, vpSize.height),
                live,
              );
              final viewportRect = Rect.fromPoints(topLeft, bottomRight);
              // Keep fit-bounds from committed positions so the minimap
              // does not refit mid-drag; draw nodes at live drag positions.
              final bounds = MiniMapPainter.getCombinedBounds(
                  committedList, viewportRect);
              final transform =
                  MiniMapPainter.calculateTransform(bounds, size, theme);
              final session = controller.interactionSession;
              final livePositions = session.livePositions;

              return Listener(
                onPointerSignal: canZoom
                    ? (event) => _onPointerSignal(event, ref, controller)
                    : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: canPan
                      ? (details) => _onTapUp(details, committedList,
                          livePositions, transform, controller)
                      : null,
                  onPanUpdate: canPan
                      ? (details) => _onPanUpdate(
                          details, transform, controller, live.zoom)
                      : null,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MiniMapPainter(
                        nodes: committedList,
                        viewport: viewportRect,
                        theme: theme,
                        selectedNodeIds: graph.selectedNodeIds,
                        nodeColor: nodeColor,
                        nodeStrokeColor: nodeStrokeColor,
                        nodeStrokeWidth: nodeStrokeWidth,
                        nodeBorderRadius: nodeBorderRadius,
                        nodeBuilder: nodeBuilder,
                        livePositions: livePositions,
                        liveStamp: session.liveStamp,
                      ),
                      size: size,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onTapUp(
    TapUpDetails details,
    List<FlowNode> nodes,
    Map<String, Offset> livePositions,
    MiniMapTransform transform,
    FlowCanvasInternalController controller,
  ) {
    if (transform.scale <= 0) return;

    final cartesianPosition = MiniMapPainter.fromMiniMapToCanvas(
        details.localPosition, transform, size);

    final byId = {for (final n in nodes) n.id: n};
    FlowNode? clickedNode;
    for (final node in nodes.reversed) {
      final visualRect = NodeLayout.absoluteRect(node, byId,
          livePositions: livePositions);
      if (visualRect.contains(cartesianPosition)) {
        clickedNode = node;
        break;
      }
    }

    if (clickedNode != null && onClickNode != null) {
      onClickNode!(clickedNode);
    } else {
      controller.viewport.centerOnPosition(cartesianPosition);
    }
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    MiniMapTransform transform,
    FlowCanvasInternalController controller,
    double mainCanvasZoom,
  ) {
    if (transform.scale <= 0) return;
    final screenDelta = details.delta * (mainCanvasZoom / transform.scale);
    controller.viewport.panBy(inversePan ? screenDelta : -screenDelta);
  }

  void _onPointerSignal(PointerSignalEvent event, WidgetRef ref,
      FlowCanvasInternalController controller) {
    if (event is PointerScrollEvent) {
      final options = ref.read(flowOptionsProvider);
      final zoomDelta = -event.scrollDelta.dy * 0.001;
      controller.viewport.zoom(
        zoomFactor: zoomDelta,
        focalPoint: event.position,
        minZoom: options.viewportOptions.minZoom,
        maxZoom: options.viewportOptions.maxZoom,
      );
    }
  }
}
