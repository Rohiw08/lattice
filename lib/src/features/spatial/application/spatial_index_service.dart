import 'package:flutter/widgets.dart' show Offset;
import 'package:lattice/src/features/edges/domain/edge_index.dart';
import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';

/// Application-layer service serving as a mutable high-performance spatial cache.
///
/// Holds the `NodeIndex` and `EdgeIndex` which are updated in-place during interactions.
/// By storing this outside the immutable `FlowCanvasState`, we avoid 60fps cloning bottlenecks.
class SpatialIndexService {
  NodeIndex _nodeIndex = NodeIndex.empty();
  EdgeIndex _edgeIndex = EdgeIndex.empty();

  NodeIndex get nodeIndex => _nodeIndex;
  EdgeIndex get edgeIndex => _edgeIndex;

  /// Completely rebuilds the spatial indexes from a fresh set of nodes and edges.
  ///
  /// [defaultOrigin] (canvas `NodeOptions.nodeOrigin`) is sticky: when
  /// omitted the index keeps its previous value, so pure call sites
  /// (history, load, remote apply) never reset it behind the canvas's back.
  void rebuild(
    Iterable<FlowNode> nodes,
    Map<String, FlowEdge> edges, {
    Offset? defaultOrigin,
  }) {
    _nodeIndex = NodeIndex.empty(
        defaultOrigin: defaultOrigin ?? _nodeIndex.defaultOrigin);
    for (final node in nodes) {
      _nodeIndex.addNode(node);
    }

    _edgeIndex = EdgeIndex.empty();
    for (final entry in edges.entries) {
      _edgeIndex.addEdge(entry.value, entry.key);
    }
  }

  /// Applies a new canvas default origin and re-indexes [nodes]/[edges].
  ///
  /// Called on init and when `NodeOptions.nodeOrigin` changes at runtime;
  /// cell placement depends on the origin, so the grid must be rebuilt.
  void syncDefaultOrigin(
    Offset defaultOrigin,
    Iterable<FlowNode> nodes,
    Map<String, FlowEdge> edges,
  ) {
    if (defaultOrigin == _nodeIndex.defaultOrigin) return;
    rebuild(nodes, edges, defaultOrigin: defaultOrigin);
  }
}
