import 'package:lattice/src/core/utils/random_id_generator.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Pure edge/nodes collection utils (Lattice `addEdge` / `reconnectEdge` /
/// `applyNodeChanges` / `applyEdgeChanges`), Map-flavored.
///
/// React Flow's versions take arrays; lattice state is `Map<String, …>`
/// keyed by id, so these take and return maps (fresh copy on change, same
/// instance when nothing changes — like RF returning the input array).
/// They are pure: no validation against nodes, no callbacks, no history.
/// Pair with the controllers (`EdgesController.addEdge`, …) for the
/// stateful path.

/// Whether an equivalent connection already exists (Lattice
/// `connectionExists` inside `addEdge`): same source/target, and same
/// handles when set.
bool edgeConnectionExists(FlowEdge edge, Iterable<FlowEdge> edges) {
  return edges.any((el) =>
      el.sourceNodeId == edge.sourceNodeId &&
      el.targetNodeId == edge.targetNodeId &&
      (el.sourceHandleId == edge.sourceHandleId ||
          (el.sourceHandleId == null && edge.sourceHandleId == null)) &&
      (el.targetHandleId == edge.targetHandleId ||
          (el.targetHandleId == null && edge.targetHandleId == null)));
}

/// Deterministic edge id for a connection (Lattice `getEdgeId`):
/// `flow-edge__<source>[<handle>]-<target>[<handle>]`.
///
/// Use it when a stable id matters (tests, multiplayer, recipes);
/// interactive creation mints random ids via [IdGenerator.generateEdgeId].
String edgeIdForConnection(ConnectionParams connection) {
  final source = connection.sourceHandleId == null
      ? connection.sourceNodeId
      : '${connection.sourceNodeId}${connection.sourceHandleId}';
  final target = connection.targetHandleId == null
      ? connection.targetNodeId
      : '${connection.targetNodeId}${connection.targetHandleId}';
  return 'flow-edge__$source-$target';
}

/// Adds [edge] unless an equivalent connection already exists (Lattice
/// `addEdge` dedup: same source/target/handles, even under another id).
///
/// Create the edge with `FlowEdge.fromConnection(params, id:
/// IdGenerator.generateEdgeId())` first — unlike RF's array form there is
/// no connection-or-edge union here because a `FlowEdge` always carries an
/// id. Self-loops are rejected by the `FlowEdge` assertion, like the
/// stateful path.
Map<String, FlowEdge> addEdge(
  Map<String, FlowEdge> edges,
  FlowEdge edge,
) {
  if (edgeConnectionExists(edge, edges.values)) return edges;
  return {...edges, edge.id: edge};
}

/// Rewrites [oldEdgeId]'s endpoints with [connection] (Lattice
/// `reconnectEdge(oldEdge, newConnection, edges)`).
///
/// Unchanged map when the edge is missing. [shouldReplaceId] (RF default
/// true) mints a fresh id via [IdGenerator.generateEdgeId], or uses
/// [newId]; false keeps the old id (what the live reconnect gesture does
/// so spatial indices stay stable).
Map<String, FlowEdge> reconnectEdge(
  Map<String, FlowEdge> edges, {
  required String oldEdgeId,
  required ConnectionParams connection,
  bool shouldReplaceId = true,
  String? newId,
}) {
  final oldEdge = edges[oldEdgeId];
  if (oldEdge == null) return edges;
  final id = shouldReplaceId
      ? (newId ?? IdGenerator.generateEdgeId())
      : oldEdgeId;
  final next = {
    ...edges,
    id: oldEdge.copyWith(
      id: id,
      sourceNodeId: connection.sourceNodeId,
      sourceHandleId: connection.sourceHandleId,
      targetNodeId: connection.targetNodeId,
      targetHandleId: connection.targetHandleId,
    ),
  };
  if (id != oldEdgeId) next.remove(oldEdgeId);
  return next;
}

/// Applies [NodeChange]s to a node map (Lattice `applyNodeChanges`).
///
/// Handles add/remove/position/dimensions. Selection is separate state
/// (`selectedNodes`), not a node field, so there is no select-change
/// counterpart — mutate selection through `SelectionController`.
Map<String, FlowNode> applyNodeChanges(
  Map<String, FlowNode> nodes,
  List<NodeChange> changes,
) {
  var next = nodes;
  var dirty = false;
  void fork() {
    if (!dirty) {
      next = Map<String, FlowNode>.from(nodes);
      dirty = true;
    }
  }

  for (final change in changes) {
    switch (change) {
      case NodeAddChange(:final node):
        fork();
        next[node.id] = node;
      case NodeRemoveChange(:final id):
        if (next.containsKey(id)) {
          fork();
          next.remove(id);
        }
      case NodePositionChange(:final id, :final position):
        final node = next[id];
        if (node != null && node.position != position) {
          fork();
          next[id] = node.copyWith(position: position);
        }
      case NodeDimensionsChange(:final id, :final size):
        final node = next[id];
        if (node != null && node.size != size) {
          fork();
          next[id] = node.copyWith(size: size);
        }
    }
  }
  return next;
}

/// Applies [EdgeChange]s to an edge map (Lattice `applyEdgeChanges`).
Map<String, FlowEdge> applyEdgeChanges(
  Map<String, FlowEdge> edges,
  List<EdgeChange> changes,
) {
  var next = edges;
  var dirty = false;
  void fork() {
    if (!dirty) {
      next = Map<String, FlowEdge>.from(edges);
      dirty = true;
    }
  }

  for (final change in changes) {
    switch (change) {
      case EdgeAddChange(:final edge):
        fork();
        next[edge.id] = edge;
      case EdgeRemoveChange(:final id):
        if (next.containsKey(id)) {
          fork();
          next.remove(id);
        }
    }
  }
  return next;
}
