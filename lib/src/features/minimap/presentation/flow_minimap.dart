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

class FlowMiniMap extends ConsumerStatefulWidget {
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

  /// Fired when empty minimap space is tapped, with the flow position
  /// (React Flow `onClick`). The viewport still centers there first.
  final void Function(Offset flowPosition)? onClick;

  /// Screen-reader label for the minimap (≈ React Flow `ariaLabel`).
  ///
  /// Null (default) falls back to
  /// `A11yOptions.labels.minimapLabel` (≈ React Flow `minimap.ariaLabel`).
  /// Set [includeInSemantics] false to exclude the minimap from the
  /// semantics tree.
  final String? semanticLabel;

  /// Whether the minimap appears in the semantics tree (default true).
  final bool includeInSemantics;

  const FlowMiniMap({
    super.key,
    this.size = const Size(200, 150),
    this.alignment = Alignment.bottomRight,
    this.margin = const EdgeInsets.all(20),
    this.minimapStyle,
    this.semanticLabel,
    this.includeInSemantics = true,
    this.pannable = true,
    this.zoomable = true,
    this.inversePan = false,
    this.nodeColor,
    this.nodeStrokeColor,
    this.nodeStrokeWidth,
    this.nodeBorderRadius,
    this.nodeBuilder,
    this.onClickNode,
    this.onClick,
  });

  @override
  ConsumerState<FlowMiniMap> createState() => _FlowMiniMapState();
}

class _FlowMiniMapState extends ConsumerState<FlowMiniMap> {
  /// Absolute-mapping pan session (same dead-zone semantics as node drag /
  /// resize): the committed offset is anchored at pan start, every update's
  /// delta accumulates into travel, and `anchor + travel` is written through
  /// the clamped viewport path. Dragging the viewport box into
  /// `translateExtent` and coming back dead-zones instead of keeping a
  /// permanent gap.
  Offset? _panAnchor;
  Offset _panTravel = Offset.zero;

  @override
  Widget build(BuildContext context) {
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
    final theme = baseTheme.merge(widget.minimapStyle);
    final committedList = graph.nodes.values.toList(growable: false);
    final canPan = widget.pannable && !isLocked;
    final canZoom = widget.zoomable && !isLocked;
    final semanticLabel = widget.includeInSemantics
        ? (widget.semanticLabel ??
            ref
                .read(flowOptionsProvider)
                .a11yOptions
                .labels
                .minimapLabel)
        : null;

    return Semantics(
      label: semanticLabel,
      container: true,
      excludeSemantics: semanticLabel == null,
      child: Align(
      alignment: widget.alignment,
      child: Container(
        margin: widget.margin,
        width: widget.size.width,
        height: widget.size.height,
        decoration: BoxDecoration(
          color: theme.effectiveBackgroundColor,
          borderRadius: theme.effectiveBorderRadius,
          border: Border.all(
              color: theme.effectiveMaskStrokeColor.withAlpha(125), width: 1),
          boxShadow: theme.effectiveShadows,
        ),
        child: ClipRRect(
          borderRadius: theme.effectiveBorderRadius,
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
              final defaultOrigin = ref
                  .read(flowOptionsProvider)
                  .nodeOptions
                  .nodeOrigin;
              // Keep fit-bounds from committed positions so the minimap
              // does not refit mid-drag; draw nodes at live drag positions.
              final bounds = MiniMapPainter.getCombinedBounds(
                  committedList, viewportRect,
                  defaultOrigin: defaultOrigin);
              final transform =
                  MiniMapPainter.calculateTransform(bounds, widget.size, theme);
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
                          livePositions, transform, controller,
                          defaultOrigin: defaultOrigin)
                      : null,
                  onPanStart: canPan
                      ? (_) => _onPanStart(controller)
                      : null,
                  onPanUpdate: canPan
                      ? (details) => _onPanUpdate(
                          details, transform, controller, live.zoom)
                      : null,
                  onPanEnd: canPan ? (_) => _onPanEnd() : null,
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: MiniMapPainter(
                        nodes: committedList,
                        viewport: viewportRect,
                        theme: theme,
                        selectedNodeIds: graph.selectedNodeIds,
                        nodeColor: widget.nodeColor,
                        nodeStrokeColor: widget.nodeStrokeColor,
                        nodeStrokeWidth: widget.nodeStrokeWidth,
                        nodeBorderRadius: widget.nodeBorderRadius,
                        nodeBuilder: widget.nodeBuilder,
                        livePositions: livePositions,
                        liveStamp: session.liveStamp,
                        defaultOrigin: defaultOrigin,
                        nodesSelectable: ref
                            .read(flowOptionsProvider)
                            .nodeOptions
                            .selectable,
                      ),
                      size: widget.size,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ));
  }

  void _onTapUp(
    TapUpDetails details,
    List<FlowNode> nodes,
    Map<String, Offset> livePositions,
    MiniMapTransform transform,
    FlowCanvasInternalController controller, {
    Offset defaultOrigin = Offset.zero,
  }) {
    if (transform.scale <= 0) return;

    final cartesianPosition = MiniMapPainter.fromMiniMapToCanvas(
        details.localPosition, transform, widget.size);

    final byId = {for (final n in nodes) n.id: n};
    FlowNode? clickedNode;
    for (final node in nodes.reversed) {
      final visualRect = NodeLayout.absoluteRect(node, byId,
          livePositions: livePositions, defaultOrigin: defaultOrigin);
      if (visualRect.contains(cartesianPosition)) {
        clickedNode = node;
        break;
      }
    }

    if (clickedNode != null && widget.onClickNode != null) {
      widget.onClickNode!(clickedNode);
    } else {
      widget.onClick?.call(cartesianPosition);
      controller.viewport.centerOnPosition(cartesianPosition);
    }
  }

  void _onPanStart(FlowCanvasInternalController controller) {
    _panAnchor = controller.currentState.viewport.offset;
    _panTravel = Offset.zero;
  }

  void _onPanUpdate(
    DragUpdateDetails details,
    MiniMapTransform transform,
    FlowCanvasInternalController controller,
    double mainCanvasZoom,
  ) {
    if (transform.scale <= 0) return;
    // Defensive anchor: updates should always follow onPanStart, but anchor
    // lazily if the session is missing.
    _panAnchor ??= controller.currentState.viewport.offset;
    final screenDelta = details.delta * (mainCanvasZoom / transform.scale);
    _panTravel += widget.inversePan ? screenDelta : -screenDelta;
    // Absolute clamped write (ViewportController.setViewport, zero duration):
    // identical to the old incremental panBy when unconstrained, dead-zone
    // when translateExtent clamps.
    controller.viewport.setViewport(
      controller.currentState.viewport.copyWith(
        offset: _panAnchor! + _panTravel,
      ),
    );
  }

  void _onPanEnd() {
    _panAnchor = null;
    _panTravel = Offset.zero;
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
