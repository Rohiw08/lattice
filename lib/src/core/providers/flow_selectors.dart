import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';

/// Reactive selectors over the enclosing [FlowCanvas] state.
///
/// These are the Flutter-idiomatic counterpart of `useNodes()`, `useEdges()`,
/// and `useViewport()`: watch them from any Riverpod `Consumer` rendered
/// inside [FlowCanvas] (overlays, panels, node builders) and the widget
/// rebuilds only when the selected slice changes.
///
/// ```dart
/// class NodeCountBadge extends ConsumerWidget {
///   const NodeCountBadge({super.key});
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final count = ref.watch(flowNodesProvider.select((nodes) => nodes.length));
///     return Text('Nodes: $count');
///   }
/// }
/// ```
///
/// Each [FlowCanvas] owns a private provider container, so selectors always
/// resolve against the nearest enclosing canvas — multiple canvases on one
/// page stay isolated.
///
/// For imperative calls (add/remove nodes, pan, fitView, …) use
/// `FlowCanvasScope.of(context)` instead.

/// All nodes of the enclosing canvas, keyed by id.
final flowNodesProvider = Provider<Map<String, FlowNode>>(
  (ref) => ref.watch(flowControllerProvider.select((s) => s.nodes)),
  name: 'flowNodesProvider',
);

/// All edges of the enclosing canvas, keyed by id.
final flowEdgesProvider = Provider<Map<String, FlowEdge>>(
  (ref) => ref.watch(flowControllerProvider.select((s) => s.edges)),
  name: 'flowEdgesProvider',
);

/// Current viewport (offset + zoom) of the enclosing canvas.
///
/// Committed on gesture end by default (`SyncViewportMode.end`); per-frame
/// overlay tracking should use the live matrix instead.
final flowViewportProvider = Provider<FlowViewport>(
  (ref) => ref.watch(flowControllerProvider.select((s) => s.viewport)),
  name: 'flowViewportProvider',
);

/// Ids of the currently selected nodes.
final flowSelectedNodeIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(flowControllerProvider.select((s) => s.selectedNodes)),
  name: 'flowSelectedNodeIdsProvider',
);

/// Ids of the currently selected edges.
final flowSelectedEdgeIdsProvider = Provider<Set<String>>(
  (ref) => ref.watch(flowControllerProvider.select((s) => s.selectedEdges)),
  name: 'flowSelectedEdgeIdsProvider',
);

/// Escape hatch: the whole canvas state for arbitrary selectors.
///
/// This is the `useStore(selector)` counterpart. Prefer the focused
/// providers above (or `.select` on them) — they rebuild less. Reach for
/// this only for slices no focused provider covers (e.g. `dragMode`,
/// connection state, z-range):
///
/// ```dart
/// final dragMode = ref.watch(
///   flowStateProvider.select((s) => s.dragMode),
/// );
/// ```
///
/// Read-only: this exposes state, never the internal controller. Mutate
/// through `FlowCanvasScope.of(context)` instead.
final flowStateProvider = Provider<FlowCanvasState>(
  (ref) => ref.watch(flowControllerProvider),
  name: 'flowStateProvider',
);

/// Change-listener for the viewport (React Flow `useOnViewportChange`
/// `onChange`).
///
/// Call inside `build` (like the `watch*` selectors): [onChange] runs
/// once per committed viewport change. Gesture start/end are covered by
/// `FlowCanvasCallbacks.onMoveStart/onMoveEnd` instead.
void watchViewportChange(
  WidgetRef ref,
  void Function(FlowViewport viewport) onChange,
) {
  ref.listen<FlowViewport>(flowViewportProvider, (_, next) {
    onChange(next);
  });
}

/// Change-listener for the selection (React Flow `useOnSelectionChange`).
///
/// Call inside `build`: [onChange] runs once per selection commit with
/// the selected ids at that moment (nodes + edges together, like RF's
/// `{ nodes, edges }` payload).
void watchSelectionChange(
  WidgetRef ref,
  void Function(CanvasSelection selection) onChange,
) {
  // Record-of-sets watch: set instances change only on real selection
  // changes (service fast paths guard rewraps), so identity compare keeps
  // this to one call per selection commit.
  ref.listen<(Set<String>, Set<String>)>(
    flowStateProvider.select(
      (s) => (s.selectedNodes, s.selectedEdges),
    ),
    (_, next) {
      onChange(CanvasSelection(
        nodeIds: Set<String>.from(next.$1),
        edgeIds: Set<String>.from(next.$2),
      ));
    },
  );
}
