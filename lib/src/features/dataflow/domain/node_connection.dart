import 'package:flutter/foundation.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';

/// A single graph connection, as observed from one node.
///
/// This is the Lattice counterpart of React Flow's `NodeConnection`
/// (`Connection & { edgeId }`): which edge connects which nodes through
/// which handles. Returned by [watchNodeConnections] and
/// `controller.edges.getNodeConnections`.
@immutable
class FlowNodeConnection {
  const FlowNodeConnection({
    required this.edgeId,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourceHandleId,
    this.targetHandleId,
  });

  /// Builds a connection view over [edge].
  factory FlowNodeConnection.fromEdge(FlowEdge edge) {
    return FlowNodeConnection(
      edgeId: edge.id,
      sourceNodeId: edge.sourceNodeId,
      targetNodeId: edge.targetNodeId,
      sourceHandleId: edge.sourceHandleId,
      targetHandleId: edge.targetHandleId,
    );
  }

  /// Id of the edge carrying this connection.
  final String edgeId;

  /// Node where the edge originates.
  final String sourceNodeId;

  /// Node where the edge terminates.
  final String targetNodeId;

  /// Handle on the source node, if the edge uses one.
  final String? sourceHandleId;

  /// Handle on the target node, if the edge uses one.
  final String? targetHandleId;

  /// The node on the opposite end from [nodeId], or null when [nodeId]
  /// is not part of this connection.
  String? oppositeOf(String nodeId) {
    if (nodeId == sourceNodeId) return targetNodeId;
    if (nodeId == targetNodeId) return sourceNodeId;
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowNodeConnection &&
          other.edgeId == edgeId &&
          other.sourceNodeId == sourceNodeId &&
          other.targetNodeId == targetNodeId &&
          other.sourceHandleId == sourceHandleId &&
          other.targetHandleId == targetHandleId;

  @override
  int get hashCode => Object.hash(
        edgeId,
        sourceNodeId,
        targetNodeId,
        sourceHandleId,
        targetHandleId,
      );

  @override
  String toString() =>
      'FlowNodeConnection($sourceNodeId/${sourceHandleId ?? '-'} '
      '-> $targetNodeId/${targetHandleId ?? '-'} via $edgeId)';
}

/// A `{ nodeId, handleId }` pair addressing one handle (React Flow
/// `NodeHandle`). Replaces `"$nodeId/$handleId"` string keys at API
/// boundaries; the index keeps the packed form internally.
@immutable
class FlowNodeHandle {
  const FlowNodeHandle({required this.nodeId, required this.handleId});

  final String nodeId;
  final String handleId;

  /// Packed form used by the spatial index (`nodeId/handleId`).
  String get key => '$nodeId/$handleId';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowNodeHandle &&
          other.nodeId == nodeId &&
          other.handleId == handleId;

  @override
  int get hashCode => Object.hash(nodeId, handleId);

  @override
  String toString() => 'FlowNodeHandle($key)';
}

/// Minimal `{ id, type, data }` view over a node.
///
/// This is the Lattice counterpart of React Flow's `useNodesData` return
/// value (`Pick<Node, 'id' | 'type' | 'data'>`). Rebuilds only when the
/// referenced node's id/type/data changes — position, selection, and
/// viewport moves never touch it.
@immutable
class NodeDataSlice {
  const NodeDataSlice({
    required this.id,
    required this.type,
    required this.data,
  });

  /// Id of the observed node.
  final String id;

  /// Type of the observed node.
  final String type;

  /// Current `data` payload (may be null).
  final Object? data;

  /// Typed read of [data]; null when missing or of another type.
  T? dataAs<T>() => data is T ? data as T : null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeDataSlice &&
          other.id == id &&
          other.type == type &&
          other.data == data;

  @override
  int get hashCode => Object.hash(id, type, data);
}
