import 'dart:ui';

import 'lattice_layout.dart';
import 'lattice_node.dart';

/// Grid-based spatial index over node absolute rects.
///
/// A node belongs to every cell its absolute rect touches (cell size 256
/// logical px). Absolute rects are computed with the canvas default origin
/// passed to [rebuild]; [queryNodes] takes rects in the same absolute flow
/// space, so callers must pass the same origin the layers use.
class LatticeSpatialIndex {
  /// Cell edge length in logical px.
  static const double cellSize = 256.0;

  Map<String, LatticeNode> _nodes = <String, LatticeNode>{};
  Offset _defaultOrigin = Offset.zero;
  final Map<String, Set<String>> _cells = <String, Set<String>>{};
  final Map<String, Rect> _rects = <String, Rect>{};

  /// Rebuilds the index from [nodes], resolving absolute rects with
  /// [defaultOrigin].
  void rebuild(
    Map<String, LatticeNode> nodes, {
    required Offset defaultOrigin,
  }) {
    _nodes = Map<String, LatticeNode>.of(nodes);
    _defaultOrigin = defaultOrigin;
    _cells.clear();
    _rects.clear();
    for (final LatticeNode node in _nodes.values) {
      final Rect rect = latticeAbsoluteRect(
        _nodes,
        node.id,
        defaultOrigin: _defaultOrigin,
      );
      _rects[node.id] = rect;
      _add(node.id, rect);
    }
  }

  /// Incrementally refreshes the cells for a moved node.
  ///
  /// [before] supplies the previous geometry for cell removal; [after]
  /// supplies the new geometry. Unknown ids are added. Descendants of
  /// [after.id] (via the `parentId` chain) are refreshed too, since their
  /// absolute rects shift with the parent.
  void moveNode(LatticeNode before, LatticeNode after) {
    final Rect? oldRect = _rects[before.id];
    if (oldRect != null) {
      _remove(before.id, oldRect);
    }
    _nodes[after.id] = after;
    final Rect newRect = latticeAbsoluteRect(
      _nodes,
      after.id,
      defaultOrigin: _defaultOrigin,
    );
    _rects[after.id] = newRect;
    _add(after.id, newRect);

    for (final LatticeNode node in _nodes.values) {
      if (node.id == after.id || !_isDescendantOf(node, after.id)) continue;
      final Rect? previous = _rects[node.id];
      if (previous != null) _remove(node.id, previous);
      final Rect next = latticeAbsoluteRect(
        _nodes,
        node.id,
        defaultOrigin: _defaultOrigin,
      );
      _rects[node.id] = next;
      _add(node.id, next);
    }
  }

  /// Incrementally drops [ids] from the index. Unknown ids are ignored.
  void removeNodes(Set<String> ids) {
    for (final String id in ids) {
      final Rect? rect = _rects.remove(id);
      if (rect != null) _remove(id, rect);
      _nodes.remove(id);
    }
  }

  /// Returns ids of nodes whose absolute rect overlaps [flowRect].
  ///
  /// Candidates come from the grid cells [flowRect] touches, then are
  /// refined with exact rect overlap.
  Set<String> queryNodes(Rect flowRect) {
    final Set<String> result = <String>{};
    for (final String cell in _cellsInRect(flowRect)) {
      final Set<String>? ids = _cells[cell];
      if (ids == null) continue;
      for (final String id in ids) {
        final Rect? rect = _rects[id];
        if (rect != null && rect.overlaps(flowRect)) {
          result.add(id);
        }
      }
    }
    return result;
  }

  bool _isDescendantOf(LatticeNode node, String ancestorId) {
    String? parentId = node.parentId;
    final Set<String> visited = <String>{node.id};
    while (parentId != null && visited.add(parentId)) {
      if (parentId == ancestorId) return true;
      parentId = _nodes[parentId]?.parentId;
    }
    return false;
  }

  void _add(String id, Rect rect) {
    for (final String cell in _cellsInRect(rect)) {
      _cells.putIfAbsent(cell, () => <String>{}).add(id);
    }
  }

  void _remove(String id, Rect rect) {
    for (final String cell in _cellsInRect(rect)) {
      final Set<String>? ids = _cells[cell];
      if (ids == null) continue;
      ids.remove(id);
      if (ids.isEmpty) _cells.remove(cell);
    }
  }

  static Set<String> _cellsInRect(Rect rect) {
    final int minX = (rect.left / cellSize).floor();
    final int maxX = (rect.right / cellSize).floor();
    final int minY = (rect.top / cellSize).floor();
    final int maxY = (rect.bottom / cellSize).floor();
    final Set<String> cells = <String>{};
    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('$x:$y');
      }
    }
    return cells;
  }
}
