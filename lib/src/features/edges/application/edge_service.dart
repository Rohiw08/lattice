import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';

/// A function type for updating the data map of a FlowEdge.
///
/// It receives the current data map and should return a new, updated map.
typedef EdgeDataUpdater = Map<String, dynamic> Function(
    Map<String, dynamic> currentData);

/// A stateless service for handling all logic related to managing edges.
///
/// This service operates on a `FlowCanvasState` object and returns a new, updated
/// state, ensuring immutability.
class EdgeService {
  List<String> getEdgesFromNodes(
      FlowCanvasState state, Iterable<String> nodeIds) {
    final nodeIdSet = nodeIds.toSet();
    return state.edges.values
        .where((e) =>
            nodeIdSet.contains(e.sourceNodeId) ||
            nodeIdSet.contains(e.targetNodeId))
        .map((e) => e.id)
        .toList();
  }

  /// Adds a single edge to the canvas state.
  FlowCanvasState addEdge(FlowCanvasState state, FlowEdge edge) {
    if (state.edges.containsKey(edge.id)) return state; // Already exists
    if (!state.nodes.containsKey(edge.sourceNodeId) ||
        !state.nodes.containsKey(edge.targetNodeId)) {
      return state; // Source or target node does not exist
    }

    final newEdges = Map<String, FlowEdge>.from(state.edges);
    newEdges[edge.id] = edge;

    return state.copyWith(
      edges: newEdges,
    );
  }

  /// Imports a list of edges, skipping any that already exist or are invalid.
  FlowCanvasState addEdges(FlowCanvasState state, List<FlowEdge> edges) {
    if (edges.isEmpty) return state;

    Map<String, FlowEdge> newEdges = Map.from(state.edges);
    bool changed = false;

    for (final edge in edges) {
      if (newEdges.containsKey(edge.id)) continue;
      if (!state.nodes.containsKey(edge.sourceNodeId) ||
          !state.nodes.containsKey(edge.targetNodeId)) {
        continue;
      }
      newEdges[edge.id] = edge;
      changed = true;
    }

    return changed ? state.copyWith(edges: newEdges) : state;
  }

  /// Removes a single edge from the canvas state.
  ///
  /// Edges with `deletable: false` are kept. Selection entries for removed
  /// edges are cleaned in the same commit. [edgesDeletable] is the
  /// canvas-level default (`EdgeOptions.deletable`) for edges that don't
  /// set the flag.
  FlowCanvasState removeEdge(FlowCanvasState state, String edgeId,
      {bool edgesDeletable = true}) {
    final edge = state.edges[edgeId];
    if (edge == null || !(edge.deletable ?? edgesDeletable)) return state;

    final newEdges = Map<String, FlowEdge>.from(state.edges);
    newEdges.remove(edgeId);

    return state.copyWith(
      edges: newEdges,
      selectedEdges: Set<String>.from(state.selectedEdges)..remove(edgeId),
    );
  }

  /// Removes a list of edges efficiently.
  ///
  /// Edges with `deletable: false` are kept. Selection entries for removed
  /// edges are cleaned in the same commit. [edgesDeletable] is the
  /// canvas-level default for edges that don't set the flag.
  FlowCanvasState removeEdges(FlowCanvasState state, List<String> edgeIds,
      {bool edgesDeletable = true}) {
    if (edgeIds.isEmpty) return state;

    final newEdges = Map<String, FlowEdge>.from(state.edges);
    final removed = <String>[];
    bool changed = false;

    for (final edgeId in edgeIds) {
      final edge = newEdges[edgeId];
      if (edge != null && (edge.deletable ?? edgesDeletable)) {
        newEdges.remove(edgeId);
        removed.add(edgeId);
        changed = true;
      }
    }
    if (!changed) return state;

    return state.copyWith(
      edges: newEdges,
      selectedEdges: Set<String>.from(state.selectedEdges)..removeAll(removed),
    );
  }

  /// Updates the data payload of a specific edge.
  FlowCanvasState updateEdgeData(
    FlowCanvasState state,
    String edgeId,
    EdgeDataUpdater updater,
  ) {
    final edge = state.edges[edgeId];
    if (edge == null) return state;

    // Your FlowEdge `data` property is dynamic, so we handle it safely.
    final currentData = edge.data;

    final updatedEdge = edge.copyWith(data: updater(currentData));
    final newEdges = Map<String, FlowEdge>.from(state.edges);
    newEdges[edgeId] = updatedEdge;

    return state.copyWith(edges: newEdges);
  }

  /// Reconnects an edge to a new source or target handle.
  FlowCanvasState reconnectEdge(
    FlowCanvasState state,
    String edgeId, {
    String? newSourceNodeId,
    String? newSourceHandleId,
    String? newTargetNodeId,
    String? newTargetHandleId,
  }) {
    final edge = state.edges[edgeId];
    if (edge == null) return state;

    // Validate that the new nodes exist
    if ((newSourceNodeId != null &&
            !state.nodes.containsKey(newSourceNodeId)) ||
        (newTargetNodeId != null &&
            !state.nodes.containsKey(newTargetNodeId))) {
      return state;
    }

    final updatedEdge = edge.copyWith(
      sourceNodeId: newSourceNodeId ?? edge.sourceNodeId,
      sourceHandleId: newSourceHandleId ?? edge.sourceHandleId,
      targetNodeId: newTargetNodeId ?? edge.targetNodeId,
      targetHandleId: newTargetHandleId ?? edge.targetHandleId,
    );

    // This is an atomic operation: the index is updated for the new connection.
    final stateWithoutOldEdge = removeEdge(state, edgeId);
    return addEdge(stateWithoutOldEdge, updatedEdge);
  }
}
