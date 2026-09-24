import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/flow_selectors.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:lattice/src/features/dataflow/domain/node_connection.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Reactive + imperative dataflow helpers.
///
/// This is the Lattice counterpart of React Flow's computing-flows trio:
///
/// | React Flow | Lattice |
/// |---|---| 
/// | `useNodeConnections({ id, handleType, handleId })` | [watchNodeConnections] |
/// | `useNodesData(id \| ids)` | [watchNodesData] / [watchNodesDataMany] |
/// | `useHandleConnections` (deprecated) | `watchHandleConnections` (alias) |
/// | `updateNodeData` (merge) | `controller.nodes.updateNodeData` + [..] |
/// | `getHandleConnections` / `getNodeConnections` | `controller.edges.*` + [nodeConnectionsOf] |
///
/// Simplicity first: these are plain functions over the existing
/// `flowEdgesProvider` / `flowNodesProvider` selectors. No new providers,
/// no lookup tables — filtering a map on rebuild is the whole implementation.
///
/// ```dart
/// class ColorPreview extends ConsumerWidget {
///   const ColorPreview({super.key, required this.nodeId});
///   final String nodeId;
///
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final red = watchNodeConnections(ref, nodeId,
///         handleType: HandleType.target, handleId: 'red');
///     final source = watchNodesData(ref, red.firstOrNull?.sourceNodeId);
///     final r = (source?.dataAs<Map>()?['value'] as int?) ?? 0;
///     return Text('R=$r');
///   }
/// }
/// ```
List<FlowNodeConnection> watchNodeConnections(
  WidgetRef ref,
  String nodeId, {
  HandleType? handleType,
  String? handleId,
}) {
  // Select the stored map itself (stable identity across non-structural
  // emissions), never a derived collection — a fresh Iterable/List fails ==
  // every time and rebuilds all consumers on each commit (invariant #1).
  final edges = ref.watch(flowEdgesProvider);
  return nodeConnectionsOf(
    edges.values,
    nodeId,
    handleType: handleType,
    handleId: handleId,
  );
}

/// Pure (non-reactive) version of [watchNodeConnections] for tests and
/// one-off reads. Pass any edge iterable; no `ref` needed.
List<FlowNodeConnection> nodeConnectionsOf(
  Iterable<FlowEdge> edges,
  String nodeId, {
  HandleType? handleType,
  String? handleId,
}) {
  final out = <FlowNodeConnection>[];
  for (final edge in edges) {
    final isSourceEnd =
        edge.sourceNodeId == nodeId &&
        (handleId == null || edge.sourceHandleId == handleId);
    final isTargetEnd =
        edge.targetNodeId == nodeId &&
        (handleId == null || edge.targetHandleId == handleId);

    final matches = switch (handleType) {
      null => isSourceEnd || isTargetEnd,
      HandleType.source => isSourceEnd,
      HandleType.target => isTargetEnd,
      HandleType.both => isSourceEnd || isTargetEnd,
    };
    if (matches) out.add(FlowNodeConnection.fromEdge(edge));
  }
  out.sort((a, b) => a.edgeId.compareTo(b.edgeId));
  return out;
}

/// Deprecated React Flow name; identical to [watchNodeConnections].
///
/// React Flow deprecated `useHandleConnections` in favor of the more capable
/// `useNodeConnections`. We keep the alias so RF-shaped code still reads.
@Deprecated('Use watchNodeConnections instead.')
List<FlowNodeConnection> watchHandleConnections(
  WidgetRef ref,
  String nodeId, {
  HandleType? handleType,
  String? handleId,
}) =>
    watchNodeConnections(
      ref,
      nodeId,
      handleType: handleType,
      handleId: handleId,
    );

/// Reactive `{ id, type, data }` view over one node.
///
/// Returns null when [nodeId] is null or the node is missing — the Lattice
/// counterpart of `useNodesData(singleId)` returning null.
NodeDataSlice? watchNodesData(WidgetRef ref, String? nodeId) {
  if (nodeId == null) return null;
  return ref.watch(flowNodesProvider.select((nodes) {
    final node = nodes[nodeId];
    return node == null
        ? null
        : NodeDataSlice(id: node.id, type: node.type, data: node.data);
  }));
}

/// Reactive `{ id, type, data }` views over several nodes, in input order.
///
/// Missing ids are skipped. Counterpart of `useNodesData(ids[])`.
List<NodeDataSlice> watchNodesDataMany(WidgetRef ref, List<String> nodeIds) {
  if (nodeIds.isEmpty) return const [];
  // Join into one watch on the stored map (stable identity); derive the
  // list in the body so structural commits are the only rebuild trigger.
  final nodes = ref.watch(flowNodesProvider);
  final out = <NodeDataSlice>[];
  for (final id in nodeIds) {
    final FlowNode? node = nodes[id];
    if (node != null) {
      out.add(NodeDataSlice(id: node.id, type: node.type, data: node.data));
    }
  }
  return out;
}

/// Nodes feeding into [nodeId] (edges where it is the target).
///
/// Counterpart of React Flow's `getIncomers`. [handleId] optionally narrows
/// to one target handle.
List<String> incomersOf(
  Iterable<FlowEdge> edges,
  String nodeId, {
  String? handleId,
}) {
  final out = <String>[];
  for (final edge in edges) {
    if (edge.targetNodeId == nodeId &&
        (handleId == null || edge.targetHandleId == handleId)) {
      out.add(edge.sourceNodeId);
    }
  }
  return out..sort();
}

/// Nodes [nodeId] feeds into (edges where it is the source).
///
/// Counterpart of React Flow's `getOutgoers`. [handleId] optionally narrows
/// to one source handle.
List<String> outgoersOf(
  Iterable<FlowEdge> edges,
  String nodeId, {
  String? handleId,
}) {
  final out = <String>[];
  for (final edge in edges) {
    if (edge.sourceNodeId == nodeId &&
        (handleId == null || edge.sourceHandleId == handleId)) {
      out.add(edge.targetNodeId);
    }
  }
  return out..sort();
}

/// Perceived brightness of an RGB color, 0 (darkest) to 255 (brightest).
///
/// React Flow's computing-flows guide uses exactly this relative-luminance
/// formula; `>= 128` counts as light there and here ([isLightColor]).
double flowLuminance({required int r, required int g, required int b}) =>
    0.2126 * r + 0.7152 * g + 0.0722 * b;

/// Whether an RGB color reads as light (`luminance >= 128`).
bool isLightColor({required int r, required int g, required int b}) =>
    flowLuminance(r: r, g: g, b: b) >= 128;

/// Live connection snapshot (React Flow `useConnection`).
///
/// `inProgress` mirrors an active rubber-band drag; `isValid` mirrors the
/// current hover validity. Points are the pending connection's flow-space
/// endpoints (`FlowConnection.startPoint`/`endPoint`).
@immutable
class FlowConnectionInfo {
  const FlowConnectionInfo({
    required this.inProgress,
    this.fromNodeId,
    this.fromHandleId,
    this.toNodeId,
    this.toHandleId,
    this.fromPoint,
    this.toPoint,
    required this.isValid,
  });

  /// Idle state: no connection in progress.
  static const none =
      FlowConnectionInfo(inProgress: false, isValid: false);

  final bool inProgress;
  final String? fromNodeId;
  final String? fromHandleId;
  final String? toNodeId;
  final String? toHandleId;
  final Offset? fromPoint;
  final Offset? toPoint;
  final bool isValid;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowConnectionInfo &&
          other.inProgress == inProgress &&
          other.fromNodeId == fromNodeId &&
          other.fromHandleId == fromHandleId &&
          other.toNodeId == toNodeId &&
          other.toHandleId == toHandleId &&
          other.fromPoint == fromPoint &&
          other.toPoint == toPoint &&
          other.isValid == isValid;

  @override
  int get hashCode => Object.hash(
        inProgress,
        fromNodeId,
        fromHandleId,
        toNodeId,
        toHandleId,
        fromPoint,
        toPoint,
        isValid,
      );
}

/// Custom connection-line widget (React Flow `connectionLineComponent`).
///
/// Rendered in flow space over the rubber-band while a connection drag is
/// active (replacing the painted line — return an empty widget to hide it).
/// Endpoints come in flow coordinates via [FlowConnectionInfo.fromPoint] /
/// [toPoint]; paint canvas-space decorations with a `CustomPaint`, or place
/// flow-space widgets (markers, labels) directly.
typedef FlowConnectionLineBuilder = Widget Function(
  BuildContext context,
  FlowConnectionInfo info,
);

/// Reactive live-connection view (React Flow `useConnection`).
///
/// Rebuilds only when the pending connection or its hover validity changes —
/// use it to color handles or style a custom connection line while drawing.
FlowConnectionInfo watchConnection(WidgetRef ref) {
  final connection = ref.watch(
    flowStateProvider.select((s) => s.activeConnection),
  );
  final runtime = ref.watch(
    flowStateProvider.select((s) => s.connectionState),
  );
  if (connection == null) return FlowConnectionInfo.none;
  return FlowConnectionInfo(
    inProgress: true,
    fromNodeId: connection.fromNodeId,
    fromHandleId: connection.fromHandleId,
    toNodeId: connection.toNodeId,
    toHandleId: connection.toHandleId,
    fromPoint: connection.startPoint,
    toPoint: connection.endPoint,
    isValid: switch (runtime) {
      HoveringConnectionState(isValid: final v) => v,
      ReleasedConnectionState(isValid: final v) => v,
      _ => false,
    },
  );
}

/// Whether the graph finished initializing (React Flow `useNodesInitialized`).
///
/// Lattice nodes carry explicit sizes (no DOM measuring), so there is no
/// async measure pass: initialization completes with the first layout.
/// True once the canvas knows its viewport size — gate `fitView`/bounds
/// math on this instead of frame-counting.
bool watchNodesInitialized(WidgetRef ref) {
  return ref.watch(
    flowStateProvider.select((s) => s.viewportSize != null),
  );
}
