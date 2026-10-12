import 'dart:ui';

import 'lattice_node.dart';

/// Stored anchor minus origin shift.
///
/// `topLeft = position - origin * size` where `origin` is
/// `node.origin ?? defaultOrigin` (fractions 0..1 per axis).
Offset latticeAnchorTopLeft(LatticeNode node, Offset defaultOrigin) {
  final Offset origin = node.origin ?? defaultOrigin;
  return Offset(
    node.position.dx - origin.dx * node.size.width,
    node.position.dy - origin.dy * node.size.height,
  );
}

/// Anchor top-left of [id], plus ancestors' anchor top-lefts when the
/// `parentId` chain exists.
///
/// Unknown id returns [Offset.zero]. Terminates on parent cycles
/// (visited set) and on missing parents (stops at the last resolvable
/// ancestor).
Offset latticeAbsoluteTopLeft(
  Map<String, LatticeNode> nodes,
  String id, {
  required Offset defaultOrigin,
}) {
  LatticeNode? current = nodes[id];
  if (current == null) return Offset.zero;
  Offset result = Offset.zero;
  final Set<String> visited = <String>{};
  while (current != null && visited.add(current.id)) {
    result += latticeAnchorTopLeft(current, defaultOrigin);
    final String? parentId = current.parentId;
    current = parentId == null ? null : nodes[parentId];
  }
  return result;
}

/// Absolute rect of [id]: `topLeft & size`.
Rect latticeAbsoluteRect(
  Map<String, LatticeNode> nodes,
  String id, {
  required Offset defaultOrigin,
}) {
  final LatticeNode? node = nodes[id];
  if (node == null) return Rect.zero;
  return latticeAbsoluteTopLeft(nodes, id, defaultOrigin: defaultOrigin) &
      node.size;
}

/// Whether the absolute rect of [node] overlaps [rect].
///
/// Touching counts as overlap iff [Rect.overlaps] says so — delegated,
/// not reimplemented.
bool latticeOverlapsRect(
  Map<String, LatticeNode> nodes,
  LatticeNode node,
  Rect rect, {
  required Offset defaultOrigin,
}) {
  final Map<String, LatticeNode> scoped = <String, LatticeNode>{
    ...nodes,
    node.id: node,
  };
  return latticeAbsoluteRect(
    scoped,
    node.id,
    defaultOrigin: defaultOrigin,
  ).overlaps(rect);
}
