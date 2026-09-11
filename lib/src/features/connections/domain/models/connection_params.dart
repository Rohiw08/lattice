import 'package:flutter/foundation.dart';

/// Lightweight connection descriptor (Lattice `Connection`).
///
/// Used by [FlowCanvasCallbacks.onConnection] / [isValidConnection] and for
/// controlled edge creation when [ConnectionOptions.autoCreateEdge] is false.
@immutable
class ConnectionParams {
  final String sourceNodeId;
  final String? sourceHandleId;
  final String targetNodeId;
  final String? targetHandleId;

  const ConnectionParams({
    required this.sourceNodeId,
    required this.targetNodeId,
    this.sourceHandleId,
    this.targetHandleId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionParams &&
        other.sourceNodeId == sourceNodeId &&
        other.sourceHandleId == sourceHandleId &&
        other.targetNodeId == targetNodeId &&
        other.targetHandleId == targetHandleId;
  }

  @override
  int get hashCode => Object.hash(
        sourceNodeId,
        sourceHandleId,
        targetNodeId,
        targetHandleId,
      );

  @override
  String toString() =>
      'ConnectionParams($sourceNodeId/$sourceHandleId → $targetNodeId/$targetHandleId)';
}
