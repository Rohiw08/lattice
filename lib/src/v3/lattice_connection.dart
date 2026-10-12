import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_handle.dart';

/// Pure connection validation shared by the connect/reconnect flows.
///
/// Checks in order: (1) source node exists; (2) target node exists;
/// (3) source handle resolves via `resolveHandles()` — a null `handleId`
/// means the default port, valid iff the node has at least one source-type
/// handle; (4) target handle resolves symmetrically; (5) source handle is
/// source-type AND target handle is target-type (a null `handleId` carries
/// the side's implied type); (6) not the same `(nodeId, handleId)` on both
/// ends; (7) self-connection (same `nodeId`) rejected unless
/// [allowSelfConnections]; (8) duplicate — an existing edge with the exact
/// same `(source.nodeId, source.handleId, target.nodeId, target.handleId)` —
/// rejected unless [allowDuplicates].
///
/// Returns false on ANY failure; never throws for missing data.
bool latticeValidateConnection({
  required LatticeEndpoint source,
  required LatticeEndpoint target,
  required LatticeDocument doc,
  bool allowSelfConnections = false,
  bool allowDuplicates = false,
}) {
  // (1) source node exists.
  final sourceNode = doc.nodes[source.nodeId];
  if (sourceNode == null) return false;
  // (2) target node exists.
  final targetNode = doc.nodes[target.nodeId];
  if (targetNode == null) return false;

  // (3) source handle resolves.
  final Map<String, LatticeHandle> sourceHandles = sourceNode.resolveHandles();
  final LatticeHandleType sourceType;
  if (source.handleId == null) {
    if (!sourceHandles.values
        .any((LatticeHandle h) => h.type == LatticeHandleType.source)) {
      return false;
    }
    sourceType = LatticeHandleType.source;
  } else {
    final LatticeHandle? handle = sourceHandles[source.handleId];
    if (handle == null) return false;
    sourceType = handle.type;
  }

  // (4) target handle resolves symmetrically.
  final Map<String, LatticeHandle> targetHandles = targetNode.resolveHandles();
  final LatticeHandleType targetType;
  if (target.handleId == null) {
    if (!targetHandles.values
        .any((LatticeHandle h) => h.type == LatticeHandleType.target)) {
      return false;
    }
    targetType = LatticeHandleType.target;
  } else {
    final LatticeHandle? handle = targetHandles[target.handleId];
    if (handle == null) return false;
    targetType = handle.type;
  }

  // (5) direction check.
  if (sourceType != LatticeHandleType.source) return false;
  if (targetType != LatticeHandleType.target) return false;

  // (6) not the same (nodeId, handleId) on both ends.
  if (source.nodeId == target.nodeId &&
      source.handleId == target.handleId) {
    return false;
  }

  // (7) self-connection.
  if (source.nodeId == target.nodeId && !allowSelfConnections) return false;

  // (8) duplicate: exact match on all four endpoint fields.
  if (!allowDuplicates) {
    for (final LatticeEdge edge in doc.edges.values) {
      if (edge.source == source && edge.target == target) return false;
    }
  }

  return true;
}
