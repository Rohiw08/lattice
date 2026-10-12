import 'dart:ui';

import 'lattice_edge.dart';
import 'lattice_node.dart';

/// Session clipboard for copy/paste/duplicate.
///
/// Holds a snapshot payload of nodes + edges (value copies taken at
/// [store] time). [paste] is a pure transform: it offsets positions by
/// [delta] and renames every element through caller-supplied fresh ids,
/// so the same payload pastes repeatedly without id collisions.
class LatticeClipboard {
  List<LatticeNode> _nodes = const <LatticeNode>[];
  List<LatticeEdge> _edges = const <LatticeEdge>[];

  /// Whether a paste would produce content.
  bool get hasPayload => _nodes.isNotEmpty || _edges.isNotEmpty;

  /// Replaces the payload. Storing empty lists clears it.
  void store({
    required List<LatticeNode> nodes,
    required List<LatticeEdge> edges,
  }) {
    _nodes = List<LatticeNode>.of(nodes);
    _edges = List<LatticeEdge>.of(edges);
  }

  /// Pastes the stored payload:
  /// - offsets every stored node position by [delta];
  /// - calls [freshIds] exactly once per stored node, in stored order.
  ///   The FIRST element of each returned set (iteration order) becomes
  ///   that node's new id; the leftover elements across all calls form a
  ///   pool (in call order) from which retained edges take new ids in
  ///   stored order. Throws [StateError] when the pool runs short.
  /// - rewrites edge endpoints and node `parentId`s through the old-id to
  ///   new-id map; drops edges with an endpoint outside the stored node
  ///   set; detaches nodes whose parent is outside the set (root node).
  ({List<LatticeNode> nodes, List<LatticeEdge> edges}) paste({
    required Offset delta,
    required Set<String> Function() freshIds,
  }) {
    final Map<String, String> remap = <String, String>{};
    final List<LatticeNode> nodes = <LatticeNode>[];
    final List<String> edgeIdPool = <String>[];
    for (final LatticeNode node in _nodes) {
      final Set<String> ids = freshIds();
      if (ids.isEmpty) {
        throw StateError(
          'LatticeClipboard.paste: freshIds() returned an empty set.',
        );
      }
      final String newId = ids.first;
      remap[node.id] = newId;
      edgeIdPool.addAll(ids.skip(1));
      nodes.add(_moved(node, newId, node.position + delta, remap));
    }
    final List<LatticeEdge> edges = <LatticeEdge>[];
    var poolIndex = 0;
    for (final LatticeEdge edge in _edges) {
      final String? newSource = remap[edge.source.nodeId];
      final String? newTarget = remap[edge.target.nodeId];
      if (newSource == null || newTarget == null) continue;
      if (poolIndex >= edgeIdPool.length) {
        throw StateError(
          'LatticeClipboard.paste: freshIds() supplied '
          '${edgeIdPool.length} spare ids but the payload retains '
          '${_edges.length} edges.',
        );
      }
      edges.add(
        edge.copyWith(
          id: edgeIdPool[poolIndex++],
          source: LatticeEndpoint(
            nodeId: newSource,
            handleId: edge.source.handleId,
          ),
          target: LatticeEndpoint(
            nodeId: newTarget,
            handleId: edge.target.handleId,
          ),
        ),
      );
    }
    return (nodes: nodes, edges: edges);
  }
}

/// Copies [node] to [newId]/[position], remapping its parent through
/// [remap]. A parent outside the pasted set detaches (root node), mirroring
/// the edge-drop rule: references leaving the copied set do not survive.
LatticeNode _moved(
  LatticeNode node,
  String newId,
  Offset position,
  Map<String, String> remap,
) {
  final String? oldParent = node.parentId;
  if (oldParent == null) {
    return node.copyWith(id: newId, position: position);
  }
  // copyWith cannot null parentId, so rebuild explicitly; [remap]
  // yields null for external parents (detach).
  return LatticeNode(
    id: newId,
    type: node.type,
    position: position,
    origin: node.origin,
    size: node.size,
    data: node.data,
    parentId: remap[oldParent],
    zIndex: node.zIndex,
    handles: node.handles,
    hidden: node.hidden,
    draggable: node.draggable,
    selectable: node.selectable,
    hoverable: node.hoverable,
    connectable: node.connectable,
    deletable: node.deletable,
    resizable: node.resizable,
    focusable: node.focusable,
    minSize: node.minSize,
    maxSize: node.maxSize,
    keepAspectRatio: node.keepAspectRatio,
    expandParent: node.expandParent,
    dragHandle: node.dragHandle,
    semanticsLabel: node.semanticsLabel,
    extent: node.extent,
  );
}
