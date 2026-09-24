import 'package:equatable/equatable.dart';
import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/connections/domain/models/connection.dart';
import 'package:lattice/src/features/dataflow/application/flow_dataflow.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:lattice/src/features/edges/domain/edge_state.dart';
import 'package:lattice/src/core/options/components/edge_options.dart';
import 'package:lattice/src/features/connections/presentation/painters/connection_painter.dart';
import 'package:lattice/src/features/edges/presentation/painter/edge_painter.dart';
import 'package:lattice/src/core/theme/components/connection_theme.dart';
import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/theme/flow_theme.dart';
import 'package:lattice/src/core/theme/theme_provider.dart';
import 'package:lattice/src/features/edge_labels/presentation/flow_edge_label.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lean state for static edge layer rebuilds (no viewport — IV owns the camera).
class PainterState extends Equatable {
  final DragMode dragMode;
  final Map<String, FlowEdge> edges;
  final Set<String> selectedEdges;
  final Map<String, EdgeRuntimeState> edgeStates;
  final FlowConnection? connection;
  final FlowConnectionRuntimeState? connectionState;
  final int geometryRevision;
  final int _edgesHash;
  final bool hasAnimatedEdges;

  const PainterState({
    required this.dragMode,
    required this.edges,
    required this.selectedEdges,
    required this.edgeStates,
    this.connection,
    this.connectionState,
    required this.geometryRevision,
    required int edgesHash,
    required this.hasAnimatedEdges,
  }) : _edgesHash = edgesHash;

  /// Builds the lean paint state from [s].
  ///
  /// [signature] carries the edge-set hash + animated flag, memoized on the
  /// edges-map identity by [EdgeGeometryService.edgesSignature] so this
  /// selector stays O(1) on hover/selection/viewport emissions (which reuse
  /// the same edges map) instead of re-scanning every edge each time.
  factory PainterState.fromState(
    FlowCanvasState s, {
    required ({int hash, bool hasAnimated}) signature,
  }) {
    return PainterState(
      dragMode: s.dragMode,
      edges: s.edges,
      selectedEdges: s.selectedEdges,
      edgeStates: s.edgeStates,
      connection: s.activeConnection,
      connectionState: s.connectionState,
      geometryRevision: s.geometryRevision,
      edgesHash: signature.hash,
      hasAnimatedEdges: signature.hasAnimated,
    );
  }

  @override
  List<Object?> get props => [
    dragMode,
    _edgesHash,
    selectedEdges,
    edgeStates,
    connection,
    connectionState,
    geometryRevision,
    hasAnimatedEdges,
  ];
}

/// Renders edges as static (RepaintBoundary) + animated + active (drag) layers.
class FlowEdgeLayer extends ConsumerWidget {
  const FlowEdgeLayer({super.key, this.layoutSize});

  /// Finite pane size from the surrounding [LayoutBuilder], used as the cull
  /// fallback on the first frame before `state.viewportSize` is seeded
  /// post-frame. Null-safe: culling still no-ops when neither is available.
  final Size? layoutSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final theme = FlowCanvasThemeProvider.of(context);
    final defaultEdgeStyle = (theme.edge ?? FlowEdgeStyle.system(context))
        .merge(EdgeOptions.resolve(context).style);
    final session = controller.interactionSession;

    final paintState = ref.watch(
      internalControllerProvider.select(
        (s) => PainterState.fromState(
          s,
          signature: controller.edgeGeometryService.edgesSignature(s.edges),
        ),
      ),
    );

    final precomputedPaths = controller.edgeGeometryService.precomputedPaths;

    final visibleEntries = paintState.edges.entries.where((e) {
      if (e.value.isHidden(context)) return false;
      if (paintState.edgeStates[e.key]?.reconnecting ?? false) return false;
      return true;
    });

    final elevate = EdgeOptions.resolve(context).elevateEdgeOnSelect;
    final globalLabel = EdgeOptions.resolve(context).label;
    // An edge shows a label when it (or the global default) provides one.
    bool hasLabel(MapEntry<String, FlowEdge> entry) =>
        entry.value.label != null || globalLabel != null;
    final selected = paintState.selectedEdges;

    final orderedEdges = <MapEntry<String, FlowEdge>>[];
    if (elevate) {
      orderedEdges.addAll(
        visibleEntries.where((e) => !selected.contains(e.key)),
      );
      orderedEdges.addAll(
        visibleEntries.where((e) => selected.contains(e.key)),
      );
    } else {
      orderedEdges.addAll(visibleEntries);
    }

    final vpOpts = ref.read(flowOptionsProvider).viewportOptions;
    final connOpts = ref.read(flowOptionsProvider).connectionOptions;
    final flowState = ref.read(internalControllerProvider);

    List<MapEntry<String, FlowEdge>> cull(
      List<MapEntry<String, FlowEdge>> source, {
      required Set<String> alwaysInclude,
    }) {
      if (!vpOpts.onlyRenderVisibleElements) return source;
      if (paintState.dragMode == DragMode.node ||
          paintState.dragMode == DragMode.connection) {
        return source;
      }
      // Fall back to the LayoutBuilder size on the first frame, before
      // `viewportSize` is seeded post-frame — otherwise culling can't engage
      // until frame 2 and every edge paints on the initial mount.
      final size = flowState.viewportSize ?? layoutSize;
      if (size == null || size.isEmpty) {
        return source;
      }
      final rect = computeVisibleFlowRectFromCanvasTransform(
        controller.transformationController.value,
        size,
        padding: vpOpts.renderCullingPadding,
      );
      return source.where((entry) {
        if (alwaysInclude.contains(entry.key)) return true;
        final geom = controller.edgeGeometryService.getGeom(entry.key);
        if (geom == null) return true;
        return geom.bounds.overlaps(rect);
      }).toList();
    }

    final paintStack = ListenableBuilder(
      listenable: Listenable.merge([
        session,
        if (vpOpts.onlyRenderVisibleElements &&
            paintState.dragMode != DragMode.node &&
            paintState.dragMode != DragMode.connection)
          controller.transformationController,
      ]),
      builder: (context, _) {
        final activeIds = session.activeEdgeIds;
        final staticOrdered = cull(
          orderedEdges
              .where((e) => !activeIds.contains(e.key) && !e.value.animated)
              .toList(),
          alwaysInclude: selected,
        );
        final animatedOrdered = cull(
          orderedEdges
              .where((e) => !activeIds.contains(e.key) && e.value.animated)
              .toList(),
          alwaysInclude: selected,
        );
        final activeOrdered = cull(
          orderedEdges.where((e) => activeIds.contains(e.key)).toList(),
          alwaysInclude: activeIds,
        );

        if (kDebugMode && FlowCanvasDebug.logEdgePaint) {
          FlowCanvasDebug.countEdgePaint(
            staticOrdered.length +
                animatedOrdered.length +
                activeOrdered.length,
          );
        }

        return Stack(
          children: [
            // Static edges — never tick with the animation controller.
            RepaintBoundary(
              child: CustomPaint(
                painter: EdgePainter(
                  edgesSelectable: EdgeOptions.resolve(context).selectable,
                  edges: Map.fromEntries(staticOrdered),
                  edgeStates: paintState.edgeStates,
                  theme: theme,
                  defaultEdgeStyle: defaultEdgeStyle,
                  precomputedPaths: precomputedPaths,
                  geoms: controller.edgeGeometryService.geometries,
                  versions: controller.edgeGeometryService.edgeVersions,
                  geometryEpoch: paintState.geometryRevision,
                  liveStamp: 0,
                ),
                size: Size.infinite,
              ),
            ),
            // Animated edges — shared ticker, only while needed (VNF pattern).
            // Own RepaintBoundary so the ~60fps ticker repaint does not dirty
            // sibling layers (static edges, labels, connection painter).
            if (animatedOrdered.isNotEmpty)
              RepaintBoundary(
                child: _AnimatedEdgesPaint(
                  edges: Map.fromEntries(animatedOrdered),
                  edgeStates: paintState.edgeStates,
                  theme: theme,
                  defaultEdgeStyle: defaultEdgeStyle,
                  precomputedPaths: precomputedPaths,
                  geoms: controller.edgeGeometryService.geometries,
                  versions: controller.edgeGeometryService.edgeVersions,
                  geometryEpoch: paintState.geometryRevision,
                  liveStamp: session.liveStamp,
                ),
              ),
            // Active (drag) edges — repaint every drag frame; isolate them so
            // that per-frame repaint does not re-raster the sibling layers.
            RepaintBoundary(
              child: CustomPaint(
                painter: EdgePainter(
                  edgesSelectable: EdgeOptions.resolve(context).selectable,
                  edges: Map.fromEntries(
                    activeOrdered.where((e) => !e.value.animated),
                  ),
                  edgeStates: paintState.edgeStates,
                  theme: theme,
                  defaultEdgeStyle: defaultEdgeStyle,
                  precomputedPaths: precomputedPaths,
                  geoms: controller.edgeGeometryService.geometries,
                  versions: controller.edgeGeometryService.edgeVersions,
                  geometryEpoch: paintState.geometryRevision,
                  liveStamp: session.liveStamp,
                ),
                size: Size.infinite,
              ),
            ),
            if (activeOrdered.any((e) => e.value.animated))
              RepaintBoundary(
                child: _AnimatedEdgesPaint(
                  edges: Map.fromEntries(
                    activeOrdered.where((e) => e.value.animated),
                  ),
                  edgeStates: paintState.edgeStates,
                  theme: theme,
                  defaultEdgeStyle: defaultEdgeStyle,
                  precomputedPaths: precomputedPaths,
                  geoms: controller.edgeGeometryService.geometries,
                  versions: controller.edgeGeometryService.edgeVersions,
                  geometryEpoch: paintState.geometryRevision,
                  liveStamp: session.liveStamp,
                ),
              ),
            ...staticOrdered
                .where((entry) => hasLabel(entry))
                .map(
                  (entry) => _buildEdgeLabel(
                    context,
                    entry.key,
                    entry.value,
                    paintState,
                    precomputedPaths,
                    theme,
                  ),
                ),
            ...animatedOrdered
                .where((entry) => hasLabel(entry))
                .map(
                  (entry) => _buildEdgeLabel(
                    context,
                    entry.key,
                    entry.value,
                    paintState,
                    precomputedPaths,
                    theme,
                  ),
                ),
            ...activeOrdered
                .where((entry) => hasLabel(entry))
                .map(
                  (entry) => _buildEdgeLabel(
                    context,
                    entry.key,
                    entry.value,
                    paintState,
                    precomputedPaths,
                    theme,
                  ),
                ),
            if (connOpts.connectionLineBuilder == null)
              CustomPaint(
                painter: ConnectionPainter(
                  connection: paintState.connection,
                  connectionState: paintState.connectionState,
                  style: () {
                    final base = theme.connection ??
                        FlowConnectionStyle.system(context);
                    var resolved = base
                        .merge(connOpts.connectionLineStyle)
                        .merge(paintState.connection?.connectionStyle);
                    final lineType = connOpts.connectionLineType;
                    if (lineType != null) {
                      resolved = resolved.copyWith(pathType: lineType);
                    }
                    return resolved;
                  }(),
                ),
                size: Size.infinite,
              ),
            if (paintState.connection != null)
              _buildConnectionLine(
                  context, connOpts.connectionLineBuilder, paintState),
          ],
        );
      },
    );

    return IgnorePointer(child: paintStack);
  }

  /// Custom connection-line widget (React Flow `connectionLineComponent`).
  ///
  /// Laid out in the line's flow-space bounding box (RF renders in pane
  /// space instead) and pointer-transparent like the painted line.
  Widget _buildConnectionLine(
    BuildContext context,
    FlowConnectionLineBuilder? lineBuilder,
    PainterState paintState,
  ) {
    final connection = paintState.connection;
    if (lineBuilder == null || connection == null) {
      return const SizedBox.shrink();
    }
    final info = FlowConnectionInfo(
      inProgress: true,
      fromNodeId: connection.fromNodeId,
      fromHandleId: connection.fromHandleId,
      toNodeId: connection.toNodeId,
      toHandleId: connection.toHandleId,
      fromPoint: connection.startPoint,
      toPoint: connection.endPoint,
      isValid: switch (paintState.connectionState) {
        HoveringConnectionState s => s.targetHandleKey.isNotEmpty && s.isValid,
        ReleasedConnectionState s =>
          (s.targetHandleKey?.isNotEmpty ?? false) && s.isValid,
        _ => false,
      },
    );
    final from = connection.startPoint;
    final to = connection.endPoint;
    final left = from.dx < to.dx ? from.dx : to.dx;
    final top = from.dy < to.dy ? from.dy : to.dy;
    return Positioned(
      left: left,
      top: top,
      width: (from.dx - to.dx).abs().clamp(1.0, double.infinity),
      height: (from.dy - to.dy).abs().clamp(1.0, double.infinity),
      child: IgnorePointer(child: lineBuilder(context, info)),
    );
  }

  Widget _buildEdgeLabel(
    BuildContext context,
    String edgeId,
    FlowEdge edge,
    PainterState paintState,
    Map<String, Path> precomputedPaths,
    FlowCanvasTheme theme,
  ) {
    final path = precomputedPaths[edgeId];
    if (path == null) return const SizedBox.shrink();

    final metrics = path.computeMetrics().firstOrNull;
    if (metrics == null) return const SizedBox.shrink();

    final midpoint = metrics.length / 2;
    final tangent = metrics.getTangentForOffset(midpoint);
    if (tangent == null) return const SizedBox.shrink();

    final edgeState = paintState.edgeStates[edgeId];
    final states = <FlowEdgeState>{};
    final edgeSelectable = edge.isSelectable(context);
    if (!edgeSelectable) {
      states.add(FlowEdgeState.disabled);
    }
    if (paintState.selectedEdges.contains(edgeId)) {
      states.add(FlowEdgeState.selected);
    }
    if (edgeState?.hovered ?? false) {
      states.add(FlowEdgeState.hovered);
    }

    final labelStyle =
        edge.labelDecoration ??
        edge.style?.labelStyle ??
        theme.edge?.labelStyle ??
        theme.edgeLabel;

    return FlowEdgeLabel(
      id: 'label-$edgeId',
      position: tangent.position,
      rotation: -tangent.angle,
      parentId: edgeId,
      selected: edgeState?.selected ?? false,
      hovered: edgeState?.hovered ?? false,
      disabled: !edgeSelectable,
      style: labelStyle,
      // Global default label (EdgeOptions.label) when the edge has none.
      child: edge.label ?? EdgeOptions.resolve(context).label,
    );
  }
}

/// Shared [AnimationController] for animated edges — runs only while mounted
/// (i.e. while there is at least one animated edge to paint).
class _AnimatedEdgesPaint extends StatefulWidget {
  const _AnimatedEdgesPaint({
    required this.edges,
    required this.edgeStates,
    required this.theme,
    required this.defaultEdgeStyle,
    required this.precomputedPaths,
    required this.geometryEpoch,
    required this.liveStamp,
    this.geoms,
    this.versions,
  });

  final Map<String, FlowEdge> edges;
  final Map<String, EdgeRuntimeState> edgeStates;
  final FlowCanvasTheme theme;
  final FlowEdgeStyle defaultEdgeStyle;
  final Map<String, Path> precomputedPaths;
  final Map<String, EdgeGeom>? geoms;
  final Map<String, int>? versions;
  final int geometryEpoch;
  final int liveStamp;

  @override
  State<_AnimatedEdgesPaint> createState() => _AnimatedEdgesPaintState();
}

class _AnimatedEdgesPaintState extends State<_AnimatedEdgesPaint>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: never run the shared ticker while the platform asks
    // for no animations; edges paint one static frame instead. Managed here
    // (not just in build) so toggling the setting disposes the ticker
    // instead of orphaning it.
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion && _controller != null) {
      _controller!.dispose();
      _controller = null;
    } else if (!reduceMotion && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      )..repeat();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return CustomPaint(
        painter: EdgePainter(
          edgesSelectable: EdgeOptions.resolve(context).selectable,
          edges: widget.edges,
          edgeStates: widget.edgeStates,
          theme: widget.theme,
          defaultEdgeStyle: widget.defaultEdgeStyle,
          precomputedPaths: widget.precomputedPaths,
          geoms: widget.geoms,
          versions: widget.versions,
          geometryEpoch: widget.geometryEpoch,
          liveStamp: widget.liveStamp,
          animationValue: 0,
        ),
        size: Size.infinite,
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return CustomPaint(
          painter: EdgePainter(
            edgesSelectable: EdgeOptions.resolve(context).selectable,
            edges: widget.edges,
            edgeStates: widget.edgeStates,
            theme: widget.theme,
            defaultEdgeStyle: widget.defaultEdgeStyle,
            precomputedPaths: widget.precomputedPaths,
            geoms: widget.geoms,
            versions: widget.versions,
            geometryEpoch: widget.geometryEpoch,
            liveStamp: widget.liveStamp,
            animationValue: controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
