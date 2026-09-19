import 'package:lattice/src/features/canvas/flow_canvas_controller.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/foundation.dart';
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

/// Elements about to be deleted (Lattice `onBeforeDelete` payload).
@immutable
class FlowDeleteCandidates {
  const FlowDeleteCandidates({required this.nodes, required this.edges});

  /// Node objects slated for removal (descendants included,
  /// `deletable: false` already filtered out).
  final List<FlowNode> nodes;

  /// Edge objects slated for removal (connected edges included).
  final List<FlowEdge> edges;
}

/// Elements actually deleted (Lattice `onDelete` payload and
/// `deleteElements` return value).
@immutable
class FlowDeletedElements {
  const FlowDeletedElements({required this.nodes, required this.edges});

  final List<FlowNode> nodes;
  final List<FlowEdge> edges;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Decision returned from [FlowCanvasCallbacks.onBeforeDelete].
@immutable
class FlowDeletePlan {
  /// Proceed with exactly [nodeIds]/[edgeIds] (intersected with what exists;
  /// descendants/connected edges still cascade).
  const FlowDeletePlan({this.nodeIds, this.edgeIds}) : veto = false;

  /// Cancel the whole deletion.
  const FlowDeletePlan.veto()
      : nodeIds = null,
        edgeIds = null,
        veto = true;

  final Iterable<String>? nodeIds;
  final Iterable<String>? edgeIds;
  final bool veto;
}

/// A diagnostic warning, mirroring RF's `onError` channel.
///
/// Emitted for recoverable misconfigurations (unregistered types, dangling
/// references, recreated registries) — never for fatal errors, which throw.
/// Codes are stable slugs (not numbers) so apps can filter on them.
@immutable
class FlowCanvasError {  const FlowCanvasError(this.code, this.message);

  /// Stable slug, e.g. `'unregistered-node-type'`, `'extent-without-parent'`,
  /// `'reconnect-missing-edge'`, `'edge-missing-node'`,
  /// `'registries-recreated'`.
  final String code;

  /// Human-readable detail (ids included where relevant).
  final String message;

  @override
  String toString() => 'FlowCanvasError($code): $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlowCanvasError &&
          other.code == code &&
          other.message == message;

  @override
  int get hashCode => Object.hash(code, message);
}

class FlowCanvasCallbacks {
  final void Function(List<NodeChange> changes)? onNodesChange;
  final void Function(List<EdgeChange> changes)? onEdgesChange;
  final void Function(CanvasViewportInfo info)? onViewportChange;
  final void Function(CanvasSelection selection)? onSelectionChange;

  /// Fired once after first layout, with the live controller (Lattice
  /// `onInit`). Use it to capture the controller, run an initial `fitView`,
  /// or seed viewport-dependent state.
  final void Function(FlowCanvasController controller)? onInit;

  /// Pointer observation callbacks (Lattice `onNodeClick` family).
  ///
  /// Tap-down semantics: they fire on pointer-down, the same tick selection
  /// changes — consistent within this library (unlike RF's click-complete,
  /// which needs the DOM event cycle). Positions are flow coordinates.
  final void Function(FlowNode node, Offset flowPosition)? onNodeClick;
  final void Function(FlowNode node, Offset flowPosition)? onNodeDoubleClick;
  final void Function(FlowNode node, Offset flowPosition)? onNodeContextMenu;
  final void Function(FlowNode node, Offset flowPosition)? onNodeMouseEnter;
  final void Function(FlowNode node, Offset flowPosition)? onNodeMouseMove;
  final void Function(FlowNode node, Offset flowPosition)? onNodeMouseLeave;

  /// Node-drag lifecycle around [onNodeDrag] (Lattice `onNodeDragStart/Stop`).
  ///
  /// Same [NodeChange] shape: positions with `dragging: true` for the drag
  /// set at start, committed positions at stop.
  final void Function(List<NodeChange> changes)? onNodeDragStart;
  final void Function(List<NodeChange> changes)? onNodeDragStop;

  /// Node-resize lifecycle (Lattice `onNodeResizeStart/Resize/End`).
  ///
  /// Payload is the resized node (RF also passes the event + full node
  /// list; reach those through the controller from [onInit] instead).
  final void Function(FlowNode node)? onNodeResizeStart;
  final void Function(FlowNode node)? onNodeResize;
  final void Function(FlowNode node)? onNodeResizeEnd;

  /// Pointer observation for edges (tap-down semantics, like nodes).
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeClick;
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeDoubleClick;
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeContextMenu;
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeMouseEnter;
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeMouseMove;
  final void Function(FlowEdge edge, Offset flowPosition)? onEdgeMouseLeave;

  /// Empty-canvas tap (Lattice `onPaneClick`). Fires alongside deselect.
  final void Function(Offset flowPosition)? onPaneClick;

  /// Empty-canvas secondary press (Lattice `onPaneContextMenu`).
  final void Function(Offset flowPosition)? onPaneContextMenu;

  /// Right-click on a selected node (Lattice `onSelectionContextMenu`).
  ///
  /// Fires alongside [onNodeContextMenu] with the selected nodes at that
  /// moment (the clicked node is one of them).
  final void Function(Offset flowPosition, List<FlowNode> nodes)?
      onSelectionContextMenu;

  /// Wheel scroll over the pane (Lattice `onPaneScroll`), in flow coords.
  ///
  /// Fires for processed scrolls (zoom or pan); locked panes and
  /// [FlowNoWheel] regions stay silent.
  final void Function(Offset flowPosition)? onPaneScroll;

  /// Pane hover observation (Lattice `onPaneMouseEnter/Move/Leave`), in
  /// flow coordinates. [onPaneMouseMove] fires per hover tick without
  /// rebuilding — cheap observers only.
  final void Function(Offset flowPosition)? onPaneMouseEnter;
  final void Function(Offset flowPosition)? onPaneMouseMove;
  final void Function()? onPaneMouseLeave;

  /// Marquee lifecycle (Lattice `onSelectionStart/End`), with the selection
  /// at that moment. State itself streams through [onSelectionChange].
  final void Function(CanvasSelection selection)? onSelectionStart;
  final void Function(CanvasSelection selection)? onSelectionEnd;

  /// Multi-node drag lifecycle (Lattice `onSelectionDragStart/Drag/Stop`),
  /// in the same [NodeChange] shape as [onNodeDrag]. [onNodeDrag] still
  /// fires alongside; use these when you only care about group drags.
  final void Function(List<NodeChange> changes)? onSelectionDragStart;
  final void Function(List<NodeChange> changes)? onSelectionDrag;
  final void Function(List<NodeChange> changes)? onSelectionDragStop;

  /// Fired when a user viewport gesture begins (Lattice `onMoveStart`).
  ///
  /// Covers InteractiveViewer pans/zooms and auxiliary (middle/right-drag)
  /// pans. Continuous movement itself is observable via [onViewportChange];
  /// per-frame callbacks would churn state, so track
  /// `controller.liveViewport` for those (like [FlowMiniMap] does).
  final void Function(CanvasViewportInfo info)? onMoveStart;

  /// Fired when a user viewport gesture ends with a committed viewport
  /// (Lattice `onMoveEnd`).
  final void Function(CanvasViewportInfo info)? onMoveEnd;

  final void Function(String sourceNodeId, String sourceHandleId)?
      onConnectStart;
  final void Function(FlowEdge? edge)? onConnectEnd;

  /// Click-to-connect lifecycle (Lattice `onClickConnectStart/End`),
  /// distinct from drag connects. Shapes mirror [onConnectStart]/[onConnectEnd].
  final void Function(String sourceNodeId, String sourceHandleId)?
      onClickConnectStart;
  final void Function(FlowEdge? edge)? onClickConnectEnd;

  /// Fired when an edge was auto-created (default). Prefer [onConnection] for canvas-style.
  final void Function(FlowEdge edge)? onConnect;

  /// canvas-style connection payload (always fired on successful connect).
  final void Function(ConnectionParams connection)? onConnection;

  /// Last-chance gate before a completed connection inserts an edge
  /// (Lattice `onBeforeConnect`: `(connection) => Edge | Connection |
  /// void | false | null`).
  ///
  /// Runs after validity checks in the drag and click-connect paths
  /// (reconnects use [onBeforeReconnect]). Return `false` to cancel; any
  /// other result proceeds — a [FlowEdge] inserts as-is (ids and extra
  /// props honored, validators and id generation skipped, like RF's
  /// `addEdge` passthrough), [ConnectionParams] proceed with possibly
  /// rewritten endpoints (re-validated by the drop path). Dart cannot
  /// distinguish RF's "void proceeds" from "null cancels", so only
  /// `false` cancels; omitting the callback keeps default behavior.
  final Object? Function(ConnectionParams connection)? onBeforeConnect;

  /// Last-chance gate before a reconnect commits (Lattice
  /// `onBeforeReconnect`: `(newEdge, oldEdge) => Edge | void |
  /// false | null`).
  ///
  /// [newEdge] is the old edge with the dragged end rewritten. Return
  /// `false` to cancel (the edge snaps back); any other result commits —
  /// a returned [FlowEdge] commits in place of the candidate (kept under
  /// the old id so indices stay consistent). Only `false` cancels (see
  /// [onBeforeConnect]); omitting the callback keeps default behavior.
  final Object? Function(FlowEdge newEdge, FlowEdge oldEdge)?
      onBeforeReconnect;

  /// Custom validity (Lattice `isValidConnection`). Return false to reject.
  final bool Function(ConnectionParams connection)? isValidConnection;

  final void Function(List<NodeChange> changes)? onNodeDrag;

  /// Veto/transform gate before any user-intent deletion (Lattice
  /// `onBeforeDelete`).
  ///
  /// Runs for [FlowCanvasInternalController.deleteElements] and Delete-key
  /// removal with the candidates (deletable-filtered, cascades included).
  /// Return null to proceed, `FlowDeletePlan.veto()` to cancel, or a plan
  /// with replacement id lists. Synchronous by design (unlike RF's promise).
  /// Direct state writes (`NodesController.removeNodes`, …) bypass it, like
  /// RF's raw `setNodes` bypasses `onBeforeDelete`.
  final FlowDeletePlan? Function(FlowDeleteCandidates candidates)?
      onBeforeDelete;

  /// Combined deletion notification (Lattice `onDelete`) with the removed
  /// objects. See also [onNodesDelete]/[onEdgesDelete].
  final void Function(FlowDeletedElements deleted)? onDelete;

  /// Node-only deletion notification (Lattice `onNodesDelete`).
  final void Function(List<FlowNode> nodes)? onNodesDelete;

  /// Edge-only deletion notification (Lattice `onEdgesDelete`).
  final void Function(List<FlowEdge> edges)? onEdgesDelete;

  /// Diagnostic channel for recoverable misconfigurations (RF `onError`).
  ///
  /// Never fires for fatal errors (those throw). Subscribe to surface
  /// mistakes like unregistered types or dangling edges during development.
  final void Function(FlowCanvasError error)? onError;

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
    this.onInit,
    this.onNodeClick,
    this.onNodeDoubleClick,
    this.onNodeContextMenu,
    this.onNodeMouseEnter,
    this.onNodeMouseMove,
    this.onNodeMouseLeave,
    this.onNodeDragStart,
    this.onNodeDragStop,
    this.onNodeResizeStart,
    this.onNodeResize,
    this.onNodeResizeEnd,
    this.onEdgeClick,
    this.onEdgeDoubleClick,
    this.onEdgeContextMenu,
    this.onEdgeMouseEnter,
    this.onEdgeMouseMove,
    this.onEdgeMouseLeave,
    this.onPaneClick,
    this.onPaneContextMenu,
    this.onSelectionContextMenu,
    this.onPaneScroll,
    this.onPaneMouseEnter,
    this.onPaneMouseMove,
    this.onPaneMouseLeave,
    this.onSelectionStart,
    this.onSelectionEnd,
    this.onSelectionDragStart,
    this.onSelectionDrag,
    this.onSelectionDragStop,
    this.onMoveStart,
    this.onMoveEnd,
    this.onConnectStart,
    this.onConnectEnd,
    this.onClickConnectStart,
    this.onClickConnectEnd,
    this.onConnect,
    this.onConnection,
    this.onBeforeConnect,
    this.onBeforeReconnect,
    this.isValidConnection,
    this.onNodeDrag,
    this.onBeforeDelete,
    this.onDelete,
    this.onNodesDelete,
    this.onEdgesDelete,
    this.onError,
    this.onReconnectStart,
    this.onReconnect,
    this.onReconnectEnd,
  });
}

/// Which end of an edge is being reconnected.
enum HandleTypeEnd { source, target }
