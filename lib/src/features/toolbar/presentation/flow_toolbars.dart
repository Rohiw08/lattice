import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';

/// Alignment of a toolbar along its anchor edge (Lattice `align`).
enum FlowToolbarAlign {
  /// Start of the edge (left for top/bottom, top for left/right).
  start,

  /// Middle of the edge (default).
  center,

  /// End of the edge (right for top/bottom, bottom for left/right).
  end,
}

/// Shared anchor math for [FlowNodeToolbar] and [FlowEdgeToolbar].
abstract final class FlowToolbarAnchor {
  const FlowToolbarAnchor._();

  /// Viewer-space anchor point for [rect] with [position]/[align].
  static Offset anchorFor(
    Rect rect,
    HandlePosition position,
    FlowToolbarAlign align,
  ) {
    final t = switch (align) {
      FlowToolbarAlign.start => 0.0,
      FlowToolbarAlign.center => 0.5,
      FlowToolbarAlign.end => 1.0,
    };
    return switch (position) {
      HandlePosition.top =>
        Offset(rect.left + rect.width * t, rect.top),
      HandlePosition.bottom =>
        Offset(rect.left + rect.width * t, rect.bottom),
      HandlePosition.left =>
        Offset(rect.left, rect.top + rect.height * t),
      HandlePosition.right =>
        Offset(rect.right, rect.top + rect.height * t),
    };
  }

  /// Fractional shift so the toolbar sits outside [position]'s edge.
  static Offset fractionalShift(HandlePosition position) => switch (position) {
        HandlePosition.top => const Offset(-0.5, -1.0),
        HandlePosition.bottom => const Offset(-0.5, 0.0),
        HandlePosition.left => const Offset(-1.0, -0.5),
        HandlePosition.right => const Offset(0.0, -0.5),
      };

  /// Screen-space margin pushing the toolbar off the edge by [offset].
  static EdgeInsets marginFor(HandlePosition position, double offset) =>
      switch (position) {
        HandlePosition.top => EdgeInsets.only(bottom: offset),
        HandlePosition.bottom => EdgeInsets.only(top: offset),
        HandlePosition.left => EdgeInsets.only(right: offset),
        HandlePosition.right => EdgeInsets.only(left: offset),
      };
}

/// Floating toolbar attached to a node (Lattice `<NodeToolbar />`).
///
/// Place in `FlowCanvas(overlays: [...])`. Tracks the node through pan, zoom,
/// and live drags at a constant screen size (it never scales with the
/// canvas). [isVisible] defaults to following the node's selection; pass an
/// explicit value to pin it.
class FlowNodeToolbar extends ConsumerWidget {
  const FlowNodeToolbar({
    super.key,
    required this.nodeId,
    required this.child,
    this.isVisible,
    this.position = HandlePosition.top,
    this.align = FlowToolbarAlign.center,
    this.offset = 10.0,
  });

  final String nodeId;
  final Widget child;

  /// Null (default) = visible while [nodeId] is selected.
  final bool? isVisible;

  /// Which node edge the toolbar sits outside of.
  final HandlePosition position;

  /// Alignment along that edge.
  final FlowToolbarAlign align;

  /// Screen-space gap between the node edge and the toolbar.
  final double offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final selected = ref.watch(
      internalControllerProvider.select((s) => s.selectedNodes.contains(nodeId)),
    );
    final defaultOrigin = ref.watch(
      flowOptionsProvider.select((o) => o.nodeOptions.nodeOrigin),
    );
    if (isVisible ?? selected) {
      return ListenableBuilder(
        listenable: Listenable.merge(
            [controller.liveViewport, controller.interactionSession]),
        builder: (context, _) {
          final state = controller.currentState;
          final node = state.nodes[nodeId];
          if (node == null || (node.hidden ?? false)) {
            return const SizedBox.shrink();
          }
          final rect = _nodeRect(controller, state.nodes, node, defaultOrigin);
          return _positioned(controller, rect, child);
        },
      );
    }
    return const SizedBox.shrink();
  }

  Rect _nodeRect(
    FlowCanvasInternalController controller,
    Map<String, FlowNode> nodes,
    FlowNode node,
    Offset defaultOrigin,
  ) {
    final session = controller.interactionSession;
    final live = session.isActive ? session.livePositions : null;
    // Live resize grows the node while the anchor stays put.
    final size = session.liveSizes[nodeId] ?? node.size;
    final sized = node.size == size
        ? node
        : node.copyWith(size: size);
    return NodeLayout.absoluteRect(
      sized,
      nodes,
      livePositions: live,
      defaultOrigin: defaultOrigin,
    );
  }

  Widget _positioned(
    FlowCanvasInternalController controller,
    Rect rect,
    Widget child,
  ) {
    final live = controller.liveViewport.viewport;
    Offset toViewer(Offset flow) =>
        flow * live.zoom + live.offset;
    final anchor = FlowToolbarAnchor.anchorFor(rect, position, align);
    final at = toViewer(anchor);
    final shift = FlowToolbarAnchor.fractionalShift(position);
    return Positioned(
      left: at.dx,
      top: at.dy,
      child: FractionalTranslation(
        translation: shift,
        child: Padding(
          padding: FlowToolbarAnchor.marginFor(position, offset),
          child: child,
        ),
      ),
    );
  }
}

/// Floating toolbar attached to an edge (Lattice `<EdgeToolbar />`).
///
/// Place in `FlowCanvas(overlays: [...])`. Anchors to the edge's path-bounds
/// center (or [flowPoint] when given) at a constant screen size. [isVisible]
/// defaults to following the edge's selection; pass an explicit value to
/// pin it.
class FlowEdgeToolbar extends ConsumerWidget {
  const FlowEdgeToolbar({
    super.key,
    required this.edgeId,
    required this.child,
    this.isVisible,
    this.flowPoint,
    this.alignX = FlowToolbarAlign.center,
    this.alignY = FlowToolbarAlign.center,
    this.offset = 10.0,
  });

  final String edgeId;
  final Widget child;

  /// Null (default) = visible while [edgeId] is selected.
  final bool? isVisible;

  /// Explicit flow-space anchor. Defaults to the edge path-bounds center.
  final Offset? flowPoint;

  final FlowToolbarAlign alignX;
  final FlowToolbarAlign alignY;

  /// Screen-space gap applied above the anchor.
  final double offset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final selected = ref.watch(
      internalControllerProvider.select((s) => s.selectedEdges.contains(edgeId)),
    );
    if (isVisible ?? selected) {
      return ListenableBuilder(
        listenable: Listenable.merge(
            [controller.liveViewport, controller.interactionSession]),
        builder: (context, _) {
          final state = controller.currentState;
          final edge = state.edges[edgeId];
          if (edge == null || (edge.hidden ?? false)) {
            return const SizedBox.shrink();
          }
          final geom = controller.edgeGeometryService.getGeom(edgeId);
          final anchor = flowPoint ?? geom?.bounds.center;
          if (anchor == null) return const SizedBox.shrink();
          final live = controller.liveViewport.viewport;
          final at = anchor * live.zoom + live.offset;
          // Align against the anchor like NodeToolbar: alignX/alignY pick
          // the anchor point, the toolbar hangs above it by [offset].
          final double fx = switch (alignX) {
            FlowToolbarAlign.start => 0.0,
            FlowToolbarAlign.center => -0.5,
            FlowToolbarAlign.end => -1.0,
          };
          final double fy = switch (alignY) {
            FlowToolbarAlign.start => 0.0,
            FlowToolbarAlign.center => -0.5,
            FlowToolbarAlign.end => -1.0,
          };
          return Positioned(
            left: at.dx,
            top: at.dy,
            child: FractionalTranslation(
              translation: Offset(fx, fy),
              child: Padding(
                padding: EdgeInsets.only(bottom: offset),
                child: child,
              ),
            ),
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}
