import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/painting.dart';

sealed class NodeChange {
  const NodeChange();
}

final class NodeAddChange extends NodeChange {
  final FlowNode node;
  const NodeAddChange({required this.node});
}

final class NodeRemoveChange extends NodeChange {
  final String id;
  const NodeRemoveChange({required this.id});
}

final class NodePositionChange extends NodeChange {
  final String id;
  final Offset position;
  final bool dragging;
  const NodePositionChange({
    required this.id,
    required this.position,
    this.dragging = false,
  });
}

final class NodeDimensionsChange extends NodeChange {
  final String id;
  final Size size;
  const NodeDimensionsChange({required this.id, required this.size});
}

sealed class EdgeChange {
  const EdgeChange();
}

final class EdgeAddChange extends EdgeChange {
  final FlowEdge edge;
  const EdgeAddChange({required this.edge});
}

final class EdgeRemoveChange extends EdgeChange {
  final String id;
  const EdgeRemoveChange({required this.id});
}

class CanvasViewportInfo {
  final FlowViewport viewport;
  final Size? viewportSize;
  const CanvasViewportInfo({required this.viewport, this.viewportSize});
}

class CanvasSelection {
  final Set<String> nodeIds;
  final Set<String> edgeIds;
  const CanvasSelection({required this.nodeIds, required this.edgeIds});
}

class FlowCanvasCallbacks {
  final void Function(List<NodeChange> changes)? onNodesChange;
  final void Function(List<EdgeChange> changes)? onEdgesChange;
  final void Function(CanvasViewportInfo info)? onViewportChange;
  final void Function(CanvasSelection selection)? onSelectionChange;

  final void Function(String sourceNodeId, String sourceHandleId)?
      onConnectStart;
  final void Function(FlowEdge? edge)? onConnectEnd;

  /// Fired when an edge was auto-created (default). Prefer [onConnection] for canvas-style.
  final void Function(FlowEdge edge)? onConnect;

  /// canvas-style connection payload (always fired on successful connect).
  final void Function(ConnectionParams connection)? onConnection;

  /// Custom validity (Lattice `isValidConnection`). Return false to reject.
  final bool Function(ConnectionParams connection)? isValidConnection;

  final void Function(List<NodeChange> changes)? onNodeDrag;

  /// Edge reconnect lifecycle (Lattice `onReconnect` / Start / End).
  final void Function(String edgeId, HandleTypeEnd end)? onReconnectStart;
  final void Function(FlowEdge oldEdge, ConnectionParams connection)?
      onReconnect;
  final void Function(FlowEdge? edge)? onReconnectEnd;

  const FlowCanvasCallbacks({
    this.onNodesChange,
    this.onEdgesChange,
    this.onViewportChange,
    this.onSelectionChange,
    this.onConnectStart,
    this.onConnectEnd,
    this.onConnect,
    this.onConnection,
    this.isValidConnection,
    this.onNodeDrag,
    this.onReconnectStart,
    this.onReconnect,
    this.onReconnectEnd,
  });
}

/// Which end of an edge is being reconnected.
enum HandleTypeEnd { source, target }
