import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'lattice_selection.dart';
import 'lattice_theme.dart';
import 'session_providers.dart';

/// Which border point of a node is being dragged to resize it.
enum LatticeResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

/// Handle square edge length in flow px. The theme carries paint values
/// only, so the square size stays a constant.
const double kLatticeResizeHandleSize = 10.0;

/// Flow-space center of [handle] on the border of [nodeRect].
Offset latticeResizeHandleCenter(
  Rect nodeRect,
  LatticeResizeHandle handle,
) {
  switch (handle) {
    case LatticeResizeHandle.topLeft:
      return nodeRect.topLeft;
    case LatticeResizeHandle.top:
      return Offset(nodeRect.center.dx, nodeRect.top);
    case LatticeResizeHandle.topRight:
      return nodeRect.topRight;
    case LatticeResizeHandle.right:
      return Offset(nodeRect.right, nodeRect.center.dy);
    case LatticeResizeHandle.bottomRight:
      return nodeRect.bottomRight;
    case LatticeResizeHandle.bottom:
      return Offset(nodeRect.center.dx, nodeRect.bottom);
    case LatticeResizeHandle.bottomLeft:
      return nodeRect.bottomLeft;
    case LatticeResizeHandle.left:
      return Offset(nodeRect.left, nodeRect.center.dy);
  }
}

/// Flow-space 10px square of [handle] on the border of [nodeRect],
/// centered on the border point.
Rect latticeResizeHandleRect(
  Rect nodeRect,
  LatticeResizeHandle handle,
) {
  return Rect.fromCenter(
    center: latticeResizeHandleCenter(nodeRect, handle),
    width: kLatticeResizeHandleSize,
    height: kLatticeResizeHandleSize,
  );
}

/// Corners first: on tiny nodes the corner and edge squares can overlap,
/// and the corner wins the tie.
const List<LatticeResizeHandle> _hitOrder = <LatticeResizeHandle>[
  LatticeResizeHandle.topLeft,
  LatticeResizeHandle.topRight,
  LatticeResizeHandle.bottomRight,
  LatticeResizeHandle.bottomLeft,
  LatticeResizeHandle.top,
  LatticeResizeHandle.right,
  LatticeResizeHandle.bottom,
  LatticeResizeHandle.left,
];

/// Hit-tests [flowPoint] against the 8 handle squares of [nodeRect].
/// Returns the handle whose square contains the point, or `null`.
LatticeResizeHandle? hitTestResizeHandle(Offset flowPoint, Rect nodeRect) {
  for (final LatticeResizeHandle handle in _hitOrder) {
    if (latticeResizeHandleRect(nodeRect, handle).contains(flowPoint)) {
      return handle;
    }
  }
  return null;
}

/// Absolute flow rect of node [id] with the active resize live values
/// applied (`liveSizes`/`livePositions` win over the document), so the
/// overlay tracks the node mid-gesture exactly like its shell.
Rect latticeResizeNodeRect(
  Map<String, LatticeNode> nodes,
  LatticeDragState drag,
  String id,
) {
  final LatticeNode? node = nodes[id];
  if (node == null) return Rect.zero;
  final Size? liveSize = drag.liveSizes[id];
  final Offset? livePosition = drag.livePositions[id];
  if (liveSize == null && livePosition == null) {
    return latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero);
  }
  final LatticeNode live = node.copyWith(
    position: livePosition ?? node.position,
    size: liveSize ?? node.size,
  );
  return latticeAnchorTopLeft(live, Offset.zero) & live.size;
}

/// Selection overlay: 8 drag handles on the border of the single
/// selected resizable node. Renders nothing unless the selection is
/// exactly one node whose `resizable` is true.
///
/// Handle drags are routed by the gesture router (which hit-tests these
/// same squares before connect/node candidates); this widget is visuals
/// only and owns no gesture state.
class LatticeNodeResizer extends ConsumerWidget {
  const LatticeNodeResizer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> selected = ref.watch(
      latticeSelectionProvider.select((selection) => selection.nodes),
    );
    if (selected.length != 1) return const SizedBox.shrink();
    final String id = selected.single;
    final Map<String, LatticeNode> nodes = ref.watch(latticeNodesProvider);
    final LatticeNode? node = nodes[id];
    if (node == null || node.resizable != true) {
      return const SizedBox.shrink();
    }
    final LatticeDragState drag = ref.watch(latticeDragProvider);
    final Rect rect = latticeResizeNodeRect(nodes, drag, id);
    final LatticeTheme theme =
        LatticeThemeScope.maybeOf(context) ?? LatticeTheme.light();
    final LatticeNodeStyle nodeStyle = theme.resolvedNode;
    return Stack(
      children: <Widget>[
        for (final LatticeResizeHandle handle in LatticeResizeHandle.values)
          Positioned(
            left: latticeResizeHandleCenter(rect, handle).dx -
                kLatticeResizeHandleSize / 2,
            top: latticeResizeHandleCenter(rect, handle).dy -
                kLatticeResizeHandleSize / 2,
            width: kLatticeResizeHandleSize,
            height: kLatticeResizeHandleSize,
            child: Container(
              key: ValueKey<String>('lattice-resize-${handle.name}'),
              decoration: BoxDecoration(
                // Surface fill + selection accent from the theme.
                color: nodeStyle.background,
                border: Border.all(
                  color: nodeStyle.selectedBorder,
                  width: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
