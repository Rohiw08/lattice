import 'package:equatable/equatable.dart';
import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/connections/domain/models/connection.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
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

  factory PainterState.fromState(FlowCanvasState s) {
    var hasAnimated = false;
    for (final e in s.edges.values) {
      if (e.animated) {
        hasAnimated = true;
        break;
      }
    }
    return PainterState(
      dragMode: s.dragMode,
      edges: s.edges,
      selectedEdges: s.selectedEdges,
      edgeStates: s.edgeStates,
      connection: s.activeConnection,
      connectionState: s.connectionState,
      geometryRevision: s.geometryRevision,
      edgesHash: Object.hashAll(s.edges.keys),
      hasAnimatedEdges: hasAnimated,
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
  const FlowEdgeLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final theme = FlowCanvasThemeProvider.of(context);
    final defaultEdgeStyle = theme.edge ?? FlowEdgeStyle.system(context);
    final session = controller.interactionSession;

    final paintState = ref.watch(internalControllerProvider.select(
      (s) => PainterState.fromState(s),
    ));

    final precomputedPaths = controller.edgeGeometryService.precomputedPaths;

    final visibleEntries = paintState.edges.entries.where((e) {
      if (e.value.isHidden(context)) return false;
      if (paintState.edgeStates[e.key]?.reconnecting ?? false) return false;
      return true;
    });

    final elevate = EdgeOptions.resolve(context).elevateEdgeOnSelect;
    final selected = paintState.selectedEdges;

    final orderedEdges = <MapEntry<String, FlowEdge>>[];
    if (elevate) {
      orderedEdges
          .addAll(visibleEntries.where((e) => !selected.contains(e.key)));
      orderedEdges
          .addAll(visibleEntries.where((e) => selected.contains(e.key)));
    } else {
      orderedEdges.addAll(visibleEntries);
    }

    final vpOpts = ref.read(flowOptionsProvider).viewportOptions;
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
      if (flowState.viewportSize == null || flowState.viewportSize!.isEmpty) {
        return source;
      }
      final rect = computeVisibleFlowRectFromCanvasTransform(
        controller.transformationController.value,
        flowState.viewportSize!,
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
          FlowCanvasDebug.countEdgePaint(staticOrdered.length +
              animatedOrdered.length +
              activeOrdered.length);
        }

        return Stack(
          children: [
            // Static edges — never tick with the animation controller.
            RepaintBoundary(
              child: CustomPaint(
                painter: EdgePainter(
                  edges: Map.fromEntries(staticOrdered),
                  edgeStates: paintState.edgeStates,
                  theme: theme,
                  defaultEdgeStyle: defaultEdgeStyle,
                  precomputedPaths: precomputedPaths,
                  geometryEpoch: paintState.geometryRevision,
                  liveStamp: 0,
                ),
                size: Size.infinite,
              ),
            ),
            // Animated edges — shared ticker, only while needed (VNF pattern).
            if (animatedOrdered.isNotEmpty)
              _AnimatedEdgesPaint(
                edges: Map.fromEntries(animatedOrdered),
                edgeStates: paintState.edgeStates,
                theme: theme,
                defaultEdgeStyle: defaultEdgeStyle,
                precomputedPaths: precomputedPaths,
                geometryEpoch: paintState.geometryRevision,
                liveStamp: session.liveStamp,
              ),
            CustomPaint(
              painter: EdgePainter(
                edges: Map.fromEntries(
                  activeOrdered.where((e) => !e.value.animated),
                ),
                edgeStates: paintState.edgeStates,
                theme: theme,
                defaultEdgeStyle: defaultEdgeStyle,
                precomputedPaths: precomputedPaths,
                geometryEpoch: paintState.geometryRevision,
                liveStamp: session.liveStamp,
              ),
              size: Size.infinite,
            ),
            if (activeOrdered.any((e) => e.value.animated))
              _AnimatedEdgesPaint(
                edges: Map.fromEntries(
                  activeOrdered.where((e) => e.value.animated),
                ),
                edgeStates: paintState.edgeStates,
                theme: theme,
                defaultEdgeStyle: defaultEdgeStyle,
                precomputedPaths: precomputedPaths,
                geometryEpoch: paintState.geometryRevision,
                liveStamp: session.liveStamp,
              ),
            ...staticOrdered
                .where((entry) => entry.value.label != null)
                .map((entry) => _buildEdgeLabel(
                      context,
                      entry.key,
                      entry.value,
                      paintState,
                      precomputedPaths,
                      theme,
                    )),
            ...animatedOrdered
                .where((entry) => entry.value.label != null)
                .map((entry) => _buildEdgeLabel(
                      context,
                      entry.key,
                      entry.value,
                      paintState,
                      precomputedPaths,
                      theme,
                    )),
            ...activeOrdered
                .where((entry) => entry.value.label != null)
                .map((entry) => _buildEdgeLabel(
                      context,
                      entry.key,
                      entry.value,
                      paintState,
                      precomputedPaths,
                      theme,
                    )),
            CustomPaint(
              painter: ConnectionPainter(
                connection: paintState.connection,
                connectionState: paintState.connectionState,
                style: () {
                  final base = theme.connection ??
                      FlowConnectionStyle.system(context);
                  var resolved =
                      base.merge(paintState.connection?.connectionStyle);
                  final lineType = ref
                      .read(flowOptionsProvider)
                      .connectionOptions
                      .connectionLineType;
                  if (lineType != null) {
                    resolved = resolved.copyWith(pathType: lineType);
                  }
                  return resolved;
                }(),
              ),
              size: Size.infinite,
            ),
          ],
        );
      },
    );

    return IgnorePointer(child: paintStack);
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
    if (edge.selectable == false) {
      states.add(FlowEdgeState.disabled);
    }
    if (paintState.selectedEdges.contains(edgeId)) {
      states.add(FlowEdgeState.selected);
    }
    if (edgeState?.hovered ?? false) {
      states.add(FlowEdgeState.hovered);
    }

    final labelStyle = edge.labelDecoration ??
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
      disabled: edge.selectable == false,
      style: labelStyle,
      child: edge.label,
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
  });

  final Map<String, FlowEdge> edges;
  final Map<String, EdgeRuntimeState> edgeStates;
  final FlowCanvasTheme theme;
  final FlowEdgeStyle defaultEdgeStyle;
  final Map<String, Path> precomputedPaths;
  final int geometryEpoch;
  final int liveStamp;

  @override
  State<_AnimatedEdgesPaint> createState() => _AnimatedEdgesPaintState();
}

class _AnimatedEdgesPaintState extends State<_AnimatedEdgesPaint>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: EdgePainter(
            edges: widget.edges,
            edgeStates: widget.edgeStates,
            theme: widget.theme,
            defaultEdgeStyle: widget.defaultEdgeStyle,
            precomputedPaths: widget.precomputedPaths,
            geometryEpoch: widget.geometryEpoch,
            liveStamp: widget.liveStamp,
            animationValue: _controller.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}
