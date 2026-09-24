import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/dataflow/application/flow_dataflow.dart';
import 'package:lattice/src/features/dataflow/domain/node_connection.dart';

/// Logic-only per-handle data binding.
///
/// This is the Lattice counterpart of the guide's inline `CustomHandle`
/// (`useNodeConnections` + `useNodesData` + `useEffect(onChange)`), in
/// Flutter shape:
///
/// - The visible handle dot still comes from the node's model (`FlowNode.handles`
///   rendered by [BaseNode]) — this widget adds no visuals of its own besides
///   [child] (typically a label row).
/// - It watches the connections on ([nodeId], [handleType], [handleId]),
///   reads the first connected node's `data`, and reports it via [onData]
///   outside the build pass (post-frame), so calling
///   `controller.nodes.updateNodeData` inside [onData] is safe.
///
/// ```dart
/// FlowDataHandle(
///   nodeId: props.id,
///   handleId: 'red',
///   handleType: HandleType.target,
///   onData: (data) => setState(() => channelValue = valueOf(data)),
///   child: const Text('R'),
/// )
/// ```
///
/// [onConnect]/[onDisconnect] mirror the hook params of the same name:
/// fired post-frame when the observed connection list changes.
class FlowDataHandle extends ConsumerStatefulWidget {
  const FlowDataHandle({
    super.key,
    required this.nodeId,
    required this.handleId,
    this.handleType = HandleType.target,
    required this.onData,
    this.onConnect,
    this.onDisconnect,
    this.child,
  });

  /// Id of the node owning the handle (usually `props.id`).
  final String nodeId;

  /// Id of the handle to observe (required when a node has several
  /// handles of the same type — exactly the guide's advice).
  final String handleId;

  /// Which end to observe; defaults to target (data flowing in).
  final HandleType handleType;

  /// Called with the first connected node's `data` (or null when
  /// unconnected). The guide defaults this to `0`; do that at the call
  /// site: `onData: (data) => setR((data as Map?)?['value'] ?? 0)`.
  final ValueChanged<Object?> onData;

  /// Called with the fresh connection list when connections are added.
  final ValueChanged<List<FlowNodeConnection>>? onConnect;

  /// Called with the removed connections when connections go away.
  final ValueChanged<List<FlowNodeConnection>>? onDisconnect;

  /// Label/content beside the (model-rendered) handle dot.
  final Widget? child;

  @override
  ConsumerState<FlowDataHandle> createState() => _FlowDataHandleState();
}

class _FlowDataHandleState extends ConsumerState<FlowDataHandle> {
  Object? _lastData = _sentinel;
  List<FlowNodeConnection> _prev = const [];
  static const _sentinel = Object();

  @override
  Widget build(BuildContext context) {
    final connections = watchNodeConnections(
      ref,
      widget.nodeId,
      handleType: widget.handleType,
      handleId: widget.handleId,
    );
    final sourceId = _firstSourceId(connections);
    final slice = watchNodesData(ref, sourceId);
    final data = slice?.data;

    if (!_sameData(_lastData, data)) {
      _lastData = data;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onData(data);
      });
    }

    final added = connections
        .where((c) => !_prev.any((p) => p.edgeId == c.edgeId))
        .toList();
    final removed = _prev
        .where((p) => !connections.any((c) => c.edgeId == p.edgeId))
        .toList();
    _prev = connections;
    if (added.isNotEmpty || removed.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (added.isNotEmpty) widget.onConnect?.call(added);
        if (removed.isNotEmpty) widget.onDisconnect?.call(removed);
      });
    }

    return widget.child ?? const SizedBox.shrink();
  }

  String? _firstSourceId(List<FlowNodeConnection> connections) {
    if (connections.isEmpty) return null;
    final c = connections.first;
    // For a target handle the data flows from the source node; for a
    // source handle, from the target node (observing what we feed).
    return widget.handleType == HandleType.source
        ? c.targetNodeId
        : c.sourceNodeId;
  }

  bool _sameData(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == _sentinel) return false;
    return a == b;
  }
}
