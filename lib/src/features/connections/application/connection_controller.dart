import 'dart:async';

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/connections/application/connection_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:lattice/src/features/edges/domain/edge_state.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionController {
  ConnectionController({
    required CanvasStateAccessor controller,
    required ConnectionService connectionService,
    required EdgeService edgeService,
    required SpatialIndexService spatialIndex,
    required Ref ref,
    required GlobalKey viewportKey,
  })  : _controller = controller,
        _connectionService = connectionService,
        _edgeService = edgeService,
        _spatialIndex = spatialIndex,
        _ref = ref,
        _viewportKey = viewportKey;

  final CanvasStateAccessor _controller;
  final ConnectionService _connectionService;
  final EdgeService _edgeService;
  final SpatialIndexService _spatialIndex;
  final Ref _ref;
  final GlobalKey _viewportKey;

  /// Click-to-connect first handle (Lattice `connectOnClick` / `connectionClickStartHandle`).
  String? _clickFromNodeId;
  String? _clickFromHandleId;

  /// Active edge reconnect (Lattice edgesReconnectable).
  String? _reconnectingEdgeId;
  HandleTypeEnd? _reconnectEnd;

  /// Pointer-driven connect-drag (bypasses InteractiveViewer Scale arena).
  int? _activePointer;
  bool _globalRouteActive = false;
  String? _armedNodeId;
  String? _armedHandleId;
  Offset? _pointerDownGlobal;
  double get _connectSlop =>
      _ref.read(flowOptionsProvider).connectionOptions.connectionDragThreshold;

  Timer? _autoPanTimer;
  Offset _autoPanVelocity = Offset.zero;
  Offset? _lastCursorGlobal;

  ConnectionOptions get _connOpts =>
      _ref.read(flowOptionsProvider).connectionOptions;

  ViewportOptions get _vpOpts => _ref.read(flowOptionsProvider).viewportOptions;

  EdgeOptions get _edgeOpts => _ref.read(flowOptionsProvider).edgeOptions;

  Offset get _nodeOrigin =>
      _ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;

  /// Canvas default for nodes that don't set `connectable`
  /// (`NodeOptions.connectable`, RF `nodesConnectable`).
  bool get _nodesConnectable =>
      _ref.read(flowOptionsProvider).nodeOptions.connectable;

  FlowCanvasCallbacks get _callbacks => _ref.read(flowCanvasCallbacksProvider);

  bool Function(ConnectionParams)? get _isValid => _callbacks.isValidConnection;

  /// Arm a connection from a handle using raw pointer events.
  ///
  /// Uses [Listener] + a global pointer route so InteractiveViewer's
  /// [ScaleGestureRecognizer] cannot swallow the gesture. The rubber-band
  /// line starts after a small slop so taps stay click-friendly.
  void onConnectionPointerDown(
    String nodeId,
    String handleId,
    PointerDownEvent event,
  ) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    final internal = _controller;
    if (internal is FlowCanvasInternalController) {
      internal.nodes.yieldToConnectionGesture();
    }

    final state = _controller.currentState;
    final node = state.nodes[nodeId];
    final handle = node?.effectiveHandles[handleId];
    if (node == null || handle == null) return;

    final canDragStart =
        _connOpts.connectionMode == ConnectionMode.loose ||
        handle.type == HandleType.source ||
        handle.type == HandleType.both;

    // Second click of click-to-connect, or a target handle: tap-only arm.
    final clickInProgress =
        _connOpts.connectOnClick && _clickFromNodeId != null;
    if (clickInProgress || (!canDragStart && _connOpts.connectOnClick)) {
      _armPointer(event, nodeId, handleId, tapOnly: true);
      return;
    }

    if (!canDragStart) return;

    // Claim drag mode early so InteractiveViewer disables pan for this gesture.
    if (state.dragMode != DragMode.connection) {
      _controller.updateStateOnly(
        state.copyWith(dragMode: DragMode.connection),
      );
    }

    _armPointer(event, nodeId, handleId, tapOnly: false);
  }

  bool _pointerTapOnly = false;

  void _armPointer(
    PointerDownEvent event,
    String nodeId,
    String handleId, {
    required bool tapOnly,
  }) {
    _removeGlobalPointerRoute();
    _activePointer = event.pointer;
    _armedNodeId = nodeId;
    _armedHandleId = handleId;
    _pointerDownGlobal = event.position;
    _pointerTapOnly = tapOnly;
    GestureBinding.instance.pointerRouter.addRoute(
      event.pointer,
      _onGlobalPointerEvent,
    );
    _globalRouteActive = true;
  }

  void _onGlobalPointerEvent(PointerEvent event) {
    if (_activePointer != event.pointer) return;
    if (event is PointerMoveEvent) {
      if (_pointerTapOnly) return;
      final armedNode = _armedNodeId;
      final armedHandle = _armedHandleId;
      if (_controller.currentState.activeConnection == null &&
          armedNode != null &&
          armedHandle != null) {
        final down = _pointerDownGlobal;
        if (down == null) return;
        if ((event.position - down).distance < _connectSlop) return;
        // Drag connect — clear sticky click-connect so modes don't mix.
        // A previous click arm resolves as cancelled (it never completed).
        if (_clickFromNodeId != null) {
          _callbacks.onClickConnectEnd?.call(null);
        }
        _clearClickConnect();
        startConnection(armedNode, armedHandle);
      }
      final flow = _globalToFlow(event.position);
      if (flow == null) return;
      updateConnection(flow, globalPosition: event.position);
    } else if (event is PointerUpEvent) {
      final hadConnection = _controller.currentState.activeConnection != null;
      final armedNode = _armedNodeId;
      final armedHandle = _armedHandleId;
      final tapOnly = _pointerTapOnly;
      final down = _pointerDownGlobal;
      final movedBeyondSlop =
          down != null && (event.position - down).distance >= _connectSlop;
      _clearPointerArm();

      // Click-to-connect: a handle tap must go through [onHandleTap], even when
      // a rubber-band is already active from the first click. Previously we
      // called [endConnection] whenever activeConnection != null, which aborted
      // the second click before the target was applied.
      final treatAsClickConnectTap =
          _connOpts.connectOnClick &&
          armedNode != null &&
          armedHandle != null &&
          (tapOnly || !movedBeyondSlop);
      if (treatAsClickConnectTap) {
        onHandleTap(armedNode, armedHandle);
        return;
      }

      if (hadConnection) {
        endConnection();
      } else {
        final state = _controller.currentState;
        if (state.dragMode == DragMode.connection &&
            state.activeConnection == null) {
          _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
        }
      }
    } else if (event is PointerCancelEvent) {
      _clearPointerArm();
      cancelConnection();
    }
  }

  void _clearPointerArm() {
    _removeGlobalPointerRoute();
    _activePointer = null;
    _armedNodeId = null;
    _armedHandleId = null;
    _pointerDownGlobal = null;
    _pointerTapOnly = false;
  }

  void _removeGlobalPointerRoute() {
    final pointer = _activePointer;
    if (!_globalRouteActive || pointer == null) return;
    GestureBinding.instance.pointerRouter.removeRoute(
      pointer,
      _onGlobalPointerEvent,
    );
    _globalRouteActive = false;
  }

  Offset? _globalToFlow(Offset global) {
    final internal = _controller;
    if (internal is! FlowCanvasInternalController) return null;
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final local = box.globalToLocal(global);
    return internal.transformationController.toScene(local);
  }

  void onConnectionPanCancel() {
    _clearPointerArm();
    final state = _controller.currentState;
    if (state.dragMode == DragMode.connection &&
        state.activeConnection == null) {
      _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
    }
  }

  /// Handle click — Lattice `connectOnClick`.
  ///
  /// Lattice does **not** show a rubber-band after the first click; it only stores
  /// `connectionClickStartHandle` and highlights the handle (`clickconnecting`).
  /// The edge is created on the second handle click.
  void onHandleTap(String nodeId, String handleId) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_connOpts.connectOnClick) return;

    final internal = _controller;
    final handleCtrl = internal is FlowCanvasInternalController
        ? internal.handle
        : null;

    // ── First click: remember source, highlight only (no connection line).
    if (_clickFromNodeId == null) {
      final node = _controller.currentState.nodes[nodeId];
      final handle = node?.effectiveHandles[handleId];
      if (node == null || handle == null) return;

      final canStart =
          _connOpts.connectionMode == ConnectionMode.loose ||
          handle.type == HandleType.source ||
          handle.type == HandleType.both;
      if (!canStart) return;

      _clickFromNodeId = nodeId;
      _clickFromHandleId = handleId;
      handleCtrl?.setHandleSelected('$nodeId/$handleId', true);
      _callbacks.onConnectStart?.call(nodeId, handleId);
      _callbacks.onClickConnectStart?.call(nodeId, handleId);

      // Ensure no leftover drag-mode claim from the pointer arm.
      final state = _controller.currentState;
      if (state.dragMode == DragMode.connection &&
          state.activeConnection == null) {
        _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
      }
      return;
    }

    // ── Same handle again: cancel click-connect (Lattice clears start handle).
    if (_clickFromNodeId == nodeId && _clickFromHandleId == handleId) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    }

    final fromNodeId = _clickFromNodeId!;
    final fromHandleId = _clickFromHandleId!;
    final state = _controller.currentState;
    final sourceNode = state.nodes[fromNodeId];
    final sourceHandle = sourceNode?.effectiveHandles[fromHandleId];
    final targetNode = state.nodes[nodeId];
    final targetHandle = targetNode?.effectiveHandles[handleId];

    if (sourceNode == null ||
        sourceHandle == null ||
        targetNode == null ||
        targetHandle == null) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    }

    final valid = _connectionService.isValidConnectionPair(
      sourceNode,
      sourceHandle,
      targetNode,
      targetHandle,
      mode: _connOpts.connectionMode,
      isValidConnection: _isValid,
      existingEdges: state.edges.values,
      nodesConnectable: _nodesConnectable,
    );

    if (!valid) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    }

    var params = ConnectionParams(
      sourceNodeId: fromNodeId,
      sourceHandleId: fromHandleId,
      targetNodeId: nodeId,
      targetHandleId: handleId,
    );
    // RF reports the attempted connection (not gate rewrites) to
    // onConnect-style observers; the gated result drives edge creation.
    final originalParams = params;

    // Lattice `onBeforeConnect` (same contract as the drag path): false
    // cancels, a FlowEdge inserts as-is, ConnectionParams rewrite endpoints.
    // No callback keeps default behavior.
    FlowEdge? prebuilt;
    final gate = _callbacks.onBeforeConnect;
    final gated = gate == null ? params : gate(params);
    if (gated == false) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    } else if (gated is FlowEdge) {
      prebuilt = gated;
      params = ConnectionParams(
        sourceNodeId: gated.sourceNodeId,
        sourceHandleId: gated.sourceHandleId,
        targetNodeId: gated.targetNodeId,
        targetHandleId: gated.targetHandleId,
      );
    } else if (gated is ConnectionParams) {
      params = gated;
    }

    // Build pending connection + end in the same turn so no rubber-band paints.
    // Rewritten endpoints (from the gate) are looked up fresh; a dangling
    // rewrite cancels like an invalid drop. The click pipeline needs
    // concrete handles for geometry (the drag path tolerates nulls).
    final gatedSourceHandleId = params.sourceHandleId;
    final gatedTargetHandleId = params.targetHandleId;
    if (gatedSourceHandleId == null || gatedTargetHandleId == null) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    }
    final gatedTargetNode = state.nodes[params.targetNodeId];
    final gatedTargetHandle =
        gatedTargetNode?.effectiveHandles[params.targetHandleId];
    final gatedSourceNode = state.nodes[params.sourceNodeId];
    final gatedSourceHandle =
        gatedSourceNode?.effectiveHandles[params.sourceHandleId];
    if (prebuilt == null &&
        (gatedTargetNode == null ||
            gatedTargetHandle == null ||
            gatedSourceNode == null ||
            gatedSourceHandle == null)) {
      _clearClickConnect();
      _callbacks.onConnectEnd?.call(null);
      _callbacks.onClickConnectEnd?.call(null);
      return;
    }
    if (prebuilt != null) {
      _clearClickConnect();
      final edge = prebuilt;
      // RF `addEdge` passthrough with its guards: dangling endpoints or an
      // equivalent connection cancel like an invalid drop.
      final liveNodes = _controller.currentState.nodes;
      final dangling =
          !liveNodes.containsKey(edge.sourceNodeId) ||
          !liveNodes.containsKey(edge.targetNodeId);
      if (dangling ||
          edgeConnectionExists(edge, _controller.currentState.edges.values)) {
        _callbacks.onConnection?.call(originalParams);
        _callbacks.onConnectEnd?.call(null);
        _callbacks.onClickConnectEnd?.call(null);
        return;
      }
      _controller.mutate((s) => _edgeService.upsertEdge(s, edge));
      final added = _controller.currentState.edges[edge.id];
      if (added != null) _spatialIndex.edgeIndex.addEdge(added, edge.id);
      _callbacks.onConnection?.call(originalParams);
      _callbacks.onConnectEnd?.call(added);
      if (added != null) {
        _callbacks.onConnect?.call(added);
        _fireHandleConnectCallbacks(originalParams);
      }
      _callbacks.onClickConnectEnd?.call(added);
      return;
    }
    final sourceAbs =
        NodeLayout.absoluteTopLeft(
          params.sourceNodeId,
          state.nodes,
          defaultOrigin: _nodeOrigin,
        ) +
        gatedSourceHandle!.position;
    final targetAbs =
        NodeLayout.absoluteTopLeft(
          params.targetNodeId,
          state.nodes,
          defaultOrigin: _nodeOrigin,
        ) +
        gatedTargetHandle!.position;

    var next = _connectionService.startConnection(
      state.copyWith(dragMode: DragMode.connection),
      fromNodeId: params.sourceNodeId,
      fromHandleId: gatedSourceHandleId,
      startPosition: sourceAbs,
      mode: _connOpts.connectionMode,
      forceAllowStart: true,
      nodesConnectable: _nodesConnectable,
    );
    next = next.copyWith(
      activeConnection: next.activeConnection?.copyWith(
        endPoint: targetAbs,
        toNodeId: params.targetNodeId,
        toHandleId: gatedTargetHandleId,
      ),
      connectionState: FlowConnectionRuntimeState.hovering(
        targetHandleKey: '${params.targetNodeId}/${params.targetHandleId}',
        isValid: true,
      ),
    );
    _controller.updateStateOnly(next);

    _clearClickConnect();

    final before = _controller.currentState;
    _controller.mutate((s) {
      final newState = _connectionService.endConnection(
        s,
        mode: _connOpts.connectionMode,
        isValidConnection: _isValid,
        autoCreateEdge: _connOpts.autoCreateEdge,
        nodesConnectable: _nodesConnectable,
        defaultEdgeType: _edgeOpts.type ?? EdgePathType.bezier,
      );
      final newEdges = newState.edges.keys.toSet().difference(
        s.edges.keys.toSet(),
      );
      for (final edgeId in newEdges) {
        final newEdge = newState.edges[edgeId];
        if (newEdge != null) {
          _spatialIndex.edgeIndex.addEdge(newEdge, edgeId);
        }
      }
      return newState;
    });

    final after = _controller.currentState;
    FlowEdge? created;
    for (final id in after.edges.keys) {
      if (!before.edges.containsKey(id)) {
        created = after.edges[id];
        break;
      }
    }

    _callbacks.onConnection?.call(originalParams);
    _callbacks.onConnectEnd?.call(created);
    if (created != null) {
      _callbacks.onConnect?.call(created);
      _fireHandleConnectCallbacks(originalParams);
    }
    _callbacks.onClickConnectEnd?.call(created);
  }

  void startConnection(
    String nodeId,
    String handleId, {
    bool forceAllowStart = false,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    final state = _controller.currentState;
    final sourceNode = state.nodes[nodeId];
    final sourceHandle = sourceNode?.effectiveHandles[handleId];
    if (sourceNode == null || sourceHandle == null) return;
    if (!(sourceNode.connectable ?? _nodesConnectable)) return;

    final handleCenter =
        NodeLayout.absoluteTopLeft(
          nodeId,
          state.nodes,
          defaultOrigin: _nodeOrigin,
        ) +
        sourceHandle.position;

    final nextState = _connectionService.startConnection(
      state.copyWith(dragMode: DragMode.connection),
      fromNodeId: nodeId,
      fromHandleId: handleId,
      startPosition: handleCenter,
      mode: _connOpts.connectionMode,
      forceAllowStart: forceAllowStart,
      nodesConnectable: _nodesConnectable,
    );
    _controller.updateStateOnly(nextState);
    _callbacks.onConnectStart?.call(nodeId, handleId);
  }

  /// Begin reconnecting [edgeId] from [end] (source or target endpoint).
  void startReconnect({
    required String edgeId,
    required HandleTypeEnd end,
    required Offset cursorFlow,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_connOpts.edgesReconnectable) return;
    final state = _controller.currentState;
    final edge = state.edges[edgeId];
    if (edge == null) return;
    final allowed =
        edge.reconnectable ??
        _ref.read(flowOptionsProvider).edgeOptions.reconnectable;
    if (!allowed) return;

    _reconnectingEdgeId = edgeId;
    _reconnectEnd = end;
    _callbacks.onReconnectStart?.call(edgeId, end);

    // Hide the old edge while the rubber-band is active (Lattice behavior).
    _setEdgeReconnecting(edgeId, true);

    // Line originates from the fixed end.
    final fixedNodeId = end == HandleTypeEnd.target
        ? edge.sourceNodeId
        : edge.targetNodeId;
    final fixedHandleId = end == HandleTypeEnd.target
        ? edge.sourceHandleId
        : edge.targetHandleId;
    if (fixedHandleId == null) return;

    startConnection(fixedNodeId, fixedHandleId, forceAllowStart: true);
    updateConnection(cursorFlow, globalPosition: null);
  }

  void _setEdgeReconnecting(String edgeId, bool reconnecting) {
    final state = _controller.currentState;
    final prev = state.edgeStates[edgeId] ?? const EdgeRuntimeState();
    final nextStates = Map<String, EdgeRuntimeState>.from(state.edgeStates)
      ..[edgeId] = prev.copyWith(reconnecting: reconnecting);
    _controller.updateStateOnly(state.copyWith(edgeStates: nextStates));
  }

  void updateConnection(Offset canvasPosition, {Offset? globalPosition}) {
    final state = _controller.currentState;
    final activeConnection = state.activeConnection;

    if (state.dragMode != DragMode.connection || activeConnection == null) {
      return;
    }

    if (activeConnection.endPoint != canvasPosition) {
      final nextState = _connectionService.updateConnection(
        state,
        canvasPosition,
        _spatialIndex.nodeIndex,
        snapRadius: _connOpts.connectionRadius,
        mode: _connOpts.connectionMode,
        isValidConnection: _isValid,
        defaultOrigin: _nodeOrigin,
        nodesConnectable: _nodesConnectable,
      );
      _controller.updateStateOnly(nextState);
    }

    if (globalPosition != null && _vpOpts.autoPanOnConnect) {
      _lastCursorGlobal = globalPosition;
      _handleAutoPan(globalPosition);
    }
  }

  void endConnection() {
    _clearPointerArm();
    final before = _controller.currentState;
    final pending = before.activeConnection;
    if (pending == null) {
      // Reconnect cancelled with no pending line.
      if (_reconnectingEdgeId != null) {
        _abortReconnect();
      }
      return;
    }

    _stopAutoPan();
    final internal = _controller;
    if (internal is FlowCanvasInternalController) {
      internal.commitLiveViewportToState();
    }

    var params =
        (pending.fromNodeId != null &&
            pending.toNodeId != null &&
            pending.isComplete)
        ? ConnectionParams(
            sourceNodeId: pending.fromNodeId!,
            sourceHandleId: pending.fromHandleId,
            targetNodeId: pending.toNodeId!,
            targetHandleId: pending.toHandleId,
          )
        : null;

    final reconnectingId = _reconnectingEdgeId;
    final reconnectEnd = _reconnectEnd;

    // Reconnect must never fall through to "create a new edge".
    if (reconnectingId != null) {
      if (params != null) {
        _finishReconnect(
          before: before,
          edgeId: reconnectingId,
          end: reconnectEnd!,
          params: params,
        );
      } else {
        _abortReconnect();
        // Cancel from the CURRENT state: `before` predates the committed
        // auto-pan viewport, and resurrecting it snaps the camera back.
        _controller.updateStateOnly(
          _connectionService.cancelConnection(_controller.currentState),
        );
        _callbacks.onConnectEnd?.call(null);
      }
      return;
    }

    final wasValidHover =
        before.connectionState is HoveringConnectionState &&
        (before.connectionState as HoveringConnectionState).isValid;

    // Lattice `onBeforeConnect`: false cancels; a FlowEdge inserts as-is;
    // ConnectionParams proceed with rewritten endpoints (re-validated by
    // the drop path below). No callback (or a pass-through return) keeps
    // default behavior. Observers below report the attempted connection,
    // like RF's `onconnect(connection)`.
    final originalParams = params;
    FlowEdge? prebuilt;
    if (params != null && wasValidHover) {
      final gate = _callbacks.onBeforeConnect;
      final gated = gate == null ? params : gate(params);
      if (gated == false) {
        _controller.updateStateOnly(
          _connectionService.cancelConnection(_controller.currentState),
        );
        _callbacks.onConnectEnd?.call(null);
        _clearClickConnect();
        return;
      } else if (gated is FlowEdge) {
        prebuilt = gated;
        params = ConnectionParams(
          sourceNodeId: gated.sourceNodeId,
          sourceHandleId: gated.sourceHandleId,
          targetNodeId: gated.targetNodeId,
          targetHandleId: gated.targetHandleId,
        );
      } else if (gated is ConnectionParams) {
        params = gated;
      }
    }

    _controller.mutate((s) {
      var working = s;
      final pendingNow = working.activeConnection;
      // Stamp rewritten endpoints onto the pending line so the drop path
      // creates (and re-validates) exactly what the gate approved.
      if (prebuilt == null &&
          params != null &&
          pendingNow != null &&
          (pendingNow.toNodeId != params.targetNodeId ||
              pendingNow.toHandleId != params.targetHandleId ||
              pendingNow.fromNodeId != params.sourceNodeId ||
              pendingNow.fromHandleId != params.sourceHandleId)) {
        working = working.copyWith(
          activeConnection: pendingNow.copyWith(
            fromNodeId: params.sourceNodeId,
            fromHandleId: params.sourceHandleId,
            toNodeId: params.targetNodeId,
            toHandleId: params.targetHandleId,
          ),
        );
      }
      if (prebuilt != null) {
        final edge = prebuilt;
        // RF `addEdge` passthrough guards: dangling endpoints or an
        // equivalent connection insert nothing (observers still fire).
        final dangling =
            !working.nodes.containsKey(edge.sourceNodeId) ||
            !working.nodes.containsKey(edge.targetNodeId);
        if (dangling || edgeConnectionExists(edge, working.edges.values)) {
          return working.copyWith(
            activeConnection: null,
            connectionState: const FlowConnectionRuntimeState.idle(),
            handleStates: _connectionService.clearConnectionHandleStates(
              working,
            ),
            dragMode: DragMode.none,
          );
        }
        final withEdge = _edgeService.upsertEdge(working, edge);
        final added = withEdge.edges[edge.id];
        if (added != null) _spatialIndex.edgeIndex.addEdge(added, edge.id);
        return withEdge.copyWith(
          activeConnection: null,
          connectionState: const FlowConnectionRuntimeState.idle(),
          handleStates: _connectionService.clearConnectionHandleStates(working),
          dragMode: DragMode.none,
        );
      }
      final newState = _connectionService.endConnection(
        working,
        mode: _connOpts.connectionMode,
        isValidConnection: _isValid,
        autoCreateEdge: _connOpts.autoCreateEdge,
        nodesConnectable: _nodesConnectable,
        defaultEdgeType: _edgeOpts.type ?? EdgePathType.bezier,
      );
      final newEdges = newState.edges.keys.toSet().difference(
        s.edges.keys.toSet(),
      );
      for (final edgeId in newEdges) {
        final newEdge = newState.edges[edgeId];
        if (newEdge != null) {
          _spatialIndex.edgeIndex.addEdge(newEdge, edgeId);
        }
      }
      return newState;
    });

    final after = _controller.currentState;
    FlowEdge? created;
    for (final id in after.edges.keys) {
      if (!before.edges.containsKey(id)) {
        created = after.edges[id];
        break;
      }
    }

    if (originalParams != null && wasValidHover) {
      // Re-check validity for controlled mode callbacks.
      final stillOk = _isValid?.call(originalParams) ?? true;
      if (stillOk) {
        _callbacks.onConnection?.call(originalParams);
      }
    }
    _callbacks.onConnectEnd?.call(created);
    if (created != null) {
      _callbacks.onConnect?.call(created);
      if (originalParams != null) {
        _fireHandleConnectCallbacks(originalParams);
      }
    }
    _clearClickConnect();
  }

  /// Fires per-handle `onConnect` callbacks (Lattice per-`Handle`
  /// `onConnect`) for a freshly created edge's endpoint handles.
  void _fireHandleConnectCallbacks(ConnectionParams params) {
    final state = _controller.currentState;
    final sourceHandleId = params.sourceHandleId;
    if (sourceHandleId != null) {
      state
          .nodes[params.sourceNodeId]
          ?.effectiveHandles[sourceHandleId]
          ?.onConnect
          ?.call(params);
    }
    final targetHandleId = params.targetHandleId;
    if (targetHandleId != null) {
      state
          .nodes[params.targetNodeId]
          ?.effectiveHandles[targetHandleId]
          ?.onConnect
          ?.call(params);
    }
  }

  void _abortReconnect() {
    final id = _reconnectingEdgeId;
    if (id != null) {
      _setEdgeReconnecting(id, false);
      _callbacks.onReconnectEnd?.call(null);
    }
    _reconnectingEdgeId = null;
    _reconnectEnd = null;
  }

  void _finishReconnect({
    required FlowCanvasState before,
    required String edgeId,
    required HandleTypeEnd end,
    required ConnectionParams params,
  }) {
    final oldEdge = before.edges[edgeId];
    final hoverValid =
        before.connectionState is HoveringConnectionState &&
        (before.connectionState as HoveringConnectionState).isValid;

    // Drop the rubber-band first; keep reconnecting flag until mutate finishes.
    // Cancel from the CURRENT state: `before` predates the committed auto-pan
    // viewport, and resurrecting it snaps the camera back to the pre-pan spot.
    _controller.updateStateOnly(
      _connectionService.cancelConnection(_controller.currentState),
    );

    FlowEdge? updated;
    final liveNodes = _controller.currentState.nodes;
    if (oldEdge != null &&
        hoverValid &&
        (_isValid?.call(params) ?? true) &&
        liveNodes.containsKey(oldEdge.sourceNodeId) &&
        liveNodes.containsKey(oldEdge.targetNodeId) &&
        liveNodes.containsKey(params.targetNodeId)) {
      late final String newSourceNodeId;
      late final String? newSourceHandleId;
      late final String newTargetNodeId;
      late final String? newTargetHandleId;

      if (end == HandleTypeEnd.target) {
        newSourceNodeId = oldEdge.sourceNodeId;
        newSourceHandleId = oldEdge.sourceHandleId;
        newTargetNodeId = params.targetNodeId;
        newTargetHandleId = params.targetHandleId;
      } else {
        newSourceNodeId = params.targetNodeId;
        newSourceHandleId = params.targetHandleId;
        newTargetNodeId = oldEdge.targetNodeId;
        newTargetHandleId = oldEdge.targetHandleId;
      }

      // Lattice `onBeforeReconnect`: candidate = old edge with the dragged
      // end rewritten. false cancels (edge snaps back); a FlowEdge commits
      // in its place under the old id. No callback keeps default behavior.
      final candidate = oldEdge.copyWith(
        sourceNodeId: newSourceNodeId,
        sourceHandleId: newSourceHandleId,
        targetNodeId: newTargetNodeId,
        targetHandleId: newTargetHandleId,
      );
      final reconnectGate = _callbacks.onBeforeReconnect;
      final gated = reconnectGate == null
          ? candidate
          : reconnectGate(candidate, oldEdge);
      if (gated == false) {
        _setEdgeReconnecting(edgeId, false);
      } else {
        final replacement = gated is FlowEdge ? gated : candidate;
        _controller.mutate((s) {
          final next =
              _edgeService.upsertEdge(s, replacement.copyWith(id: edgeId));
          final edge = next.edges[edgeId];
          if (edge != null) {
            _spatialIndex.edgeIndex.removeEdge(edgeId, oldEdge);
            _spatialIndex.edgeIndex.addEdge(edge, edgeId);
          }
          // Clear reconnecting flag on the updated edge state.
          final prev = next.edgeStates[edgeId] ?? const EdgeRuntimeState();
          return next.copyWith(
            edgeStates: {
              ...next.edgeStates,
              edgeId: prev.copyWith(reconnecting: false),
            },
          );
        });
        updated = _controller.currentState.edges[edgeId];
        _callbacks.onReconnect?.call(oldEdge, params);
        _callbacks.onConnection?.call(
          ConnectionParams(
            sourceNodeId: newSourceNodeId,
            sourceHandleId: newSourceHandleId,
            targetNodeId: newTargetNodeId,
            targetHandleId: newTargetHandleId,
          ),
        );
      }
    } else {
      _setEdgeReconnecting(edgeId, false);
    }

    _reconnectingEdgeId = null;
    _reconnectEnd = null;
    _callbacks.onReconnectEnd?.call(updated);
    _clearClickConnect();
  }

  void cancelConnection() {
    _stopAutoPan();
    _clearPointerArm();
    final state = _controller.currentState;
    final reconnectingId = _reconnectingEdgeId;

    if (state.activeConnection == null && reconnectingId == null) {
      if (_clickFromNodeId != null) {
        _callbacks.onClickConnectEnd?.call(null);
        _clearClickConnect();
      }
      if (state.dragMode == DragMode.connection) {
        _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
      }
      return;
    }

    final nextState = _connectionService.cancelConnection(state);
    _controller.updateStateOnly(nextState);

    if (reconnectingId != null) {
      _setEdgeReconnecting(reconnectingId, false);
      _callbacks.onReconnectEnd?.call(null);
      _reconnectingEdgeId = null;
      _reconnectEnd = null;
    } else {
      _callbacks.onConnectEnd?.call(null);
    }
    _clearClickConnect();
  }

  void _clearClickConnect() {
    final fromNode = _clickFromNodeId;
    final fromHandle = _clickFromHandleId;
    if (fromNode != null && fromHandle != null) {
      final internal = _controller;
      if (internal is FlowCanvasInternalController) {
        internal.handle.setHandleSelected('$fromNode/$fromHandle', false);
      }
    }
    _clickFromNodeId = null;
    _clickFromHandleId = null;
  }

  // ── Auto-pan during connection (Lattice autoPanOnConnect) ───────────────

  void _handleAutoPan(Offset globalPosition) {
    final viewportSize = _controller.currentState.viewportSize;
    if (viewportSize == null) return;

    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPosition);
    final margin = _vpOpts.autoPanMargin;
    final speed = _vpOpts.autoPanSpeed;

    double dx = 0;
    double dy = 0;
    if (localPos.dx < margin) {
      dx = speed;
    } else if (localPos.dx > viewportSize.width - margin) {
      dx = -speed;
    }
    if (localPos.dy < margin) {
      dy = speed;
    } else if (localPos.dy > viewportSize.height - margin) {
      dy = -speed;
    }

    if (dx == 0 && dy == 0) {
      _stopAutoPan();
      return;
    }

    _autoPanVelocity = Offset(dx, dy);
    if (_autoPanTimer == null || !_autoPanTimer!.isActive) {
      _autoPanTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _performAutoPan();
      });
    }
  }

  void _performAutoPan() {
    if (_controller.currentState.dragMode != DragMode.connection ||
        _autoPanVelocity == Offset.zero) {
      return;
    }
    final internal = _controller;
    if (internal is FlowCanvasInternalController) {
      internal.panLiveBy(_autoPanVelocity);
    }
    // Keep rubber-band end under the cursor in flow space.
    final global = _lastCursorGlobal;
    if (global == null) return;
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    if (internal is! FlowCanvasInternalController) return;
    final local = box.globalToLocal(global);
    final scene = internal.transformationController.toScene(local);
    updateConnection(scene, globalPosition: global);
  }

  void _stopAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
    _autoPanVelocity = Offset.zero;
    _lastCursorGlobal = null;
  }
}
