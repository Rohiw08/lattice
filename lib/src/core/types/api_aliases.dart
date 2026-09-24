import 'dart:ui' show Offset;

import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/canvas/flow_canvas_controller.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/dataflow/domain/node_connection.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Migration-friendly aliases for React Flow API names.
///
/// Lattice renames a few RF types to avoid Flutter framework clashes
/// (`Position`, `Rect`, `ConnectionState`) or to be more explicit
/// (`ConnectionParams` over `Connection`, which collides with the ephemeral
/// `FlowConnection`). These typedefs let ported code keep RF names.
///
/// The `Node`/`Edge` aliases are convenient when porting RF examples but
/// collide easily with app models — prefer `FlowNode`/`FlowEdge` in new
/// code, or `hide` these on import.

/// React Flow `Node` (see [FlowNode]).
typedef Node<T> = FlowNode<T>;

/// React Flow `Edge` (see [FlowEdge]).
typedef Edge = FlowEdge;

/// React Flow `Position` (see [HandlePosition]).
typedef Position = HandlePosition;

/// React Flow `NodeOrigin`: anchor fractions (`Offset.zero` = top-left,
/// `Offset(0.5, 0.5)` = center).
typedef NodeOrigin = Offset;

/// React Flow `MarkerType`.
typedef MarkerType = EdgeMarkerType;

/// React Flow `HandleConnection` (see [FlowNodeConnection]).
typedef HandleConnection = FlowNodeConnection;

/// React Flow `IsValidConnection`.
typedef IsValidConnection = bool Function(ConnectionParams connection);

/// React Flow `OnConnect`.
typedef OnConnect = void Function(FlowEdge edge);

/// React Flow `OnConnectStart`.
typedef OnConnectStart = void Function(String sourceNodeId, String sourceHandleId);

/// React Flow `OnConnectEnd`.
typedef OnConnectEnd = void Function(FlowEdge? edge);

/// React Flow `OnReconnect`.
typedef OnReconnect = void Function(FlowEdge oldEdge, ConnectionParams connection);

/// React Flow `OnReconnectStart`.
typedef OnReconnectStart = void Function(String edgeId, HandleTypeEnd end);

/// React Flow `OnReconnectEnd`.
typedef OnReconnectEnd = void Function(FlowEdge? edge);

/// React Flow `OnBeforeConnect`.
typedef OnBeforeConnect = Object? Function(ConnectionParams connection);

/// React Flow `OnBeforeReconnect`.
typedef OnBeforeReconnect = Object? Function(FlowEdge newEdge, FlowEdge oldEdge);

/// React Flow `OnNodesChange`.
typedef OnNodesChange = void Function(List<NodeChange> changes);

/// React Flow `OnEdgesChange`.
typedef OnEdgesChange = void Function(List<EdgeChange> changes);

/// React Flow `OnSelectionChange`.
typedef OnSelectionChange = void Function(CanvasSelection selection);

/// React Flow `OnViewportChange`.
typedef OnViewportChange = void Function(CanvasViewportInfo info);

/// React Flow `OnDelete`.
typedef OnDelete = void Function(FlowDeletedElements deleted);

/// React Flow `OnNodesDelete`.
typedef OnNodesDelete = void Function(List<FlowNode> nodes);

/// React Flow `OnEdgesDelete`.
typedef OnEdgesDelete = void Function(List<FlowEdge> edges);

/// React Flow `OnBeforeDelete`.
typedef OnBeforeDelete = FlowDeletePlan? Function(FlowDeleteCandidates candidates);

/// React Flow `OnInit`.
typedef OnInit = void Function(FlowCanvasController controller);
