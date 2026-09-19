import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:flutter/widgets.dart';
import 'package:lattice/src/features/connections/domain/models/connection.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/handles/domain/handle.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/handles/domain/handle_state.dart';
import 'package:lattice/src/core/utils/random_id_generator.dart';
import 'package:lattice/src/core/enums/enums.dart';

import 'dart:math';

typedef ConnectionValidator =
    bool Function(
      FlowNode sourceNode,
      FlowHandle sourceHandle,
      FlowNode targetNode,
      FlowHandle targetHandle,
    );

typedef EdgeFactory =
    FlowEdge Function({
      required String id,
      required String sourceNodeId,
      required String sourceHandleId,
      required String targetNodeId,
      required String targetHandleId,
    });

class ClosestHandleResult {
  final String nodeId;
  final FlowHandle handle;
  final double distance;
  // It's often useful to also return the node itself
  final FlowNode node;

  ClosestHandleResult({
    required this.nodeId,
    required this.handle,
    required this.distance,
    required this.node,
  });
}

class ConnectionService {
  // Starts a new drag connection from a handle.
  FlowCanvasState startConnection(
    FlowCanvasState state, {
    required String fromNodeId,
    required String fromHandleId,
    required Offset startPosition,
    ConnectionMode mode = ConnectionMode.strict,
    bool forceAllowStart = false,
    bool nodesConnectable = true,
  }) {
    final fromNode = state.nodes[fromNodeId];
    final fromHandle = fromNode?.effectiveHandles[fromHandleId];

    if (fromNode == null || fromHandle == null) return state;
    // Node + handle connectability always apply (RF: non-connectable nodes
    // and handles never start connections, forced or not). Null inherits
    // the canvas default (`NodeOptions.connectable`).
    if (!(fromNode.connectable ?? nodesConnectable)) return state;
    if (!fromHandle.isConnectable) return state;
    // Per-handle start gate: isConnectableStart / maxConnections (RF
    // per-Handle isConnectableStart). Forced starts (click-connect
    // completion, reconnect) bypass the role/capacity checks.
    if (!forceAllowStart && !fromHandle.allowsStart(mode)) return state;
    if (!forceAllowStart &&
        !fromHandle.hasCapacity(state.edges.values, fromNodeId)) {
      return state;
    }

    final handleKey = '$fromNodeId/$fromHandleId';
    final newHandleStates =
        Map<String, HandleRuntimeState>.from(state.handleStates)
          ..[handleKey] =
              (state.handleStates[handleKey] ?? const HandleRuntimeState())
                  .copyWith(active: true);

    final sourceDir = _determineHandlePosition(
      fromHandle.position,
      fromNode.size,
    );

    return state.copyWith(
      handleStates: newHandleStates,
      activeConnection: FlowConnection(
        id: IdGenerator.generateCompactId("pending_connection"),
        type: 'pending',
        startPoint: startPosition,
        endPoint: startPosition,
        fromNodeId: fromNodeId,
        fromHandleId: fromHandleId,
        sourcePosition: sourceDir,
        targetPosition: _oppositePosition(sourceDir),
      ),
      dragMode: DragMode.connection,
      connectionState: const FlowConnectionRuntimeState.idle(),
    );
  }

  // Tracks the connection drag; triggers hover status if close to valid handle.
  FlowCanvasState updateConnection(
    FlowCanvasState state,
    Offset cursorPosition,
    NodeIndex nodeIndex, {
    double snapRadius = 20.0,
    ConnectionValidator? validator,
    ConnectionMode mode = ConnectionMode.strict,
    bool Function(ConnectionParams connection)? isValidConnection,
    Offset defaultOrigin = Offset.zero,
    bool nodesConnectable = true,
  }) {
    final connection = state.activeConnection;
    if (connection == null) return state;

    final sourceNode = state.nodes[connection.fromNodeId];
    final sourceHandle = sourceNode?.effectiveHandles[connection.fromHandleId];

    if (sourceNode == null || sourceHandle == null) {
      return cancelConnection(state);
    }

    final newHandleStates = Map<String, HandleRuntimeState>.from(
      state.handleStates,
    );

    // Clear previous valid/invalid target highlights.
    for (final key in newHandleStates.keys.toList()) {
      final s = newHandleStates[key]!;
      if (s.validTarget || s.invalidTarget) {
        newHandleStates[key] = s.copyWith(
          validTarget: false,
          invalidTarget: false,
        );
      }
    }

    String? targetNodeId;
    String? targetHandleId;
    String? currentTargetHandleKey;
    bool isValid = false;

    final zoom = state.viewport.zoom;
    final safeZoom = zoom <= 0 ? 1.0 : zoom;
    // Keep ~[snapRadius] screen pixels of tolerance in flow space.
    final effectiveSnap = (snapRadius / safeZoom).clamp(5.0, 8000.0);

    final closest = _findClosestHandle(
      state,
      nodeIndex,
      cursorPosition,
      snapRadius: effectiveSnap,
      mode: mode,
      defaultOrigin: defaultOrigin,
    );

    if (closest != null) {
      currentTargetHandleKey = '${closest.nodeId}/${closest.handle.id}';
      if (_isValidConnection(
        sourceNode,
        sourceHandle,
        closest.node,
        closest.handle,
        validator,
        mode: mode,
        isValidConnection: isValidConnection,
        existingEdges: state.edges.values,
        nodesConnectable: nodesConnectable,
      )) {
        targetNodeId = closest.nodeId;
        targetHandleId = closest.handle.id;
        newHandleStates[currentTargetHandleKey] =
            (newHandleStates[currentTargetHandleKey] ??
                    const HandleRuntimeState())
                .copyWith(validTarget: true, invalidTarget: false);
        isValid = true;
      } else {
        newHandleStates[currentTargetHandleKey] =
            (newHandleStates[currentTargetHandleKey] ??
                    const HandleRuntimeState())
                .copyWith(validTarget: false, invalidTarget: true);
      }
    }

    HandlePosition targetDir = connection.targetPosition;
    if (targetNodeId != null && targetHandleId != null) {
      final targetNode = state.nodes[targetNodeId]!;
      final targetHandle = targetNode.effectiveHandles[targetHandleId]!;
      targetDir = _determineHandlePosition(
        targetHandle.position,
        targetNode.size,
      );
    } else {
      targetDir = _oppositePosition(connection.sourcePosition);
    }

    final nextConnection = connection.copyWith(
      endPoint: cursorPosition,
      toNodeId: targetNodeId,
      toHandleId: targetHandleId,
      targetPosition: targetDir,
    );

    return state.copyWith(
      handleStates: newHandleStates,
      activeConnection: nextConnection,
      connectionState: FlowConnectionRuntimeState.hovering(
        targetHandleKey: currentTargetHandleKey ?? '',
        isValid: isValid,
      ),
    );
  }

  // Drops the connection; checks validity for creating edge, otherwise cancels.
  FlowCanvasState endConnection(
    FlowCanvasState state, {
    EdgeFactory? edgeFactory,
    ConnectionValidator? validator,
    ConnectionMode mode = ConnectionMode.strict,
    bool Function(ConnectionParams connection)? isValidConnection,
    bool autoCreateEdge = true,
    bool nodesConnectable = true,
  }) {
    final connection = state.activeConnection;
    if (connection == null) return state;

    final isComplete = connection.isComplete;
    final validState =
        state.connectionState is HoveringConnectionState &&
        (state.connectionState as HoveringConnectionState).isValid;

    final newHandleStates = _clearConnectionStates(state);

    if (isComplete &&
        validState &&
        connection.fromNodeId != null &&
        connection.fromHandleId != null &&
        connection.toNodeId != null &&
        connection.toHandleId != null) {
      final sourceNode = state.nodes[connection.fromNodeId!];
      final sourceHandle =
          sourceNode?.effectiveHandles[connection.fromHandleId!];
      final targetNode = state.nodes[connection.toNodeId!];
      final targetHandle = targetNode?.effectiveHandles[connection.toHandleId!];

      if (sourceNode != null &&
          sourceHandle != null &&
          targetNode != null &&
          targetHandle != null &&
          _isValidConnection(
            sourceNode,
            sourceHandle,
            targetNode,
            targetHandle,
            validator,
            mode: mode,
            isValidConnection: isValidConnection,
            existingEdges: state.edges.values,
            nodesConnectable: nodesConnectable,
          )) {
        if (!autoCreateEdge) {
          return state.copyWith(
            activeConnection: null,
            connectionState: const FlowConnectionRuntimeState.idle(),
            handleStates: newHandleStates,
            dragMode: DragMode.none,
          );
        }
        final newEdge = _createEdge(
          sourceNodeId: connection.fromNodeId!,
          sourceHandleId: connection.fromHandleId!,
          targetNodeId: connection.toNodeId!,
          targetHandleId: connection.toHandleId!,
          factory: edgeFactory,
        );
        final newEdges = Map<String, FlowEdge>.from(state.edges)
          ..[newEdge.id] = newEdge;

        return state.copyWith(
          edges: newEdges,
          activeConnection: null,
          connectionState: const FlowConnectionRuntimeState.idle(),
          handleStates: newHandleStates,
          dragMode: DragMode.none,
        );
      }
    }

    return state.copyWith(
      activeConnection: null,
      connectionState: FlowConnectionRuntimeState.released(
        targetHandleKey: connection.hasTarget
            ? '${connection.toNodeId}/${connection.toHandleId}'
            : null,
        isValid: false,
      ),
      handleStates: newHandleStates,
      dragMode: DragMode.none,
    );
  }

  // Cancels current connection.
  FlowCanvasState cancelConnection(FlowCanvasState state) {
    if (state.activeConnection == null) return state;
    return state.copyWith(
      activeConnection: null,
      connectionState: const FlowConnectionRuntimeState.idle(),
      handleStates: _clearConnectionStates(state),
      dragMode: DragMode.none,
    );
  }

  /// Clears transient handle highlights (valid/invalid/active) without
  /// touching the pending connection. Public for completion paths that
  /// insert an edge themselves (e.g. `onBeforeConnect` prebuilt edges).
  Map<String, HandleRuntimeState> clearConnectionHandleStates(
    FlowCanvasState state,
  ) => _clearConnectionStates(state);

  Map<String, HandleRuntimeState> _clearConnectionStates(
    FlowCanvasState state,
  ) {
    final newHandleStates = Map<String, HandleRuntimeState>.from(
      state.handleStates,
    );

    for (final key in newHandleStates.keys.toList()) {
      final s = newHandleStates[key]!;
      if (s.validTarget || s.invalidTarget || s.active) {
        newHandleStates[key] = s.copyWith(
          active: false,
          validTarget: false,
          invalidTarget: false,
        );
      }
    }
    return newHandleStates;
  }

  // Finds closest target handle, if any.
  ClosestHandleResult? _findClosestHandle(
    FlowCanvasState state,
    NodeIndex nodeIndex,
    Offset cursorPosition, {
    required double snapRadius,
    ConnectionMode mode = ConnectionMode.strict,
    Offset defaultOrigin = Offset.zero,
  }) {
    final connection = state.activeConnection;
    final sourceNode = state.nodes[connection!.fromNodeId];
    final sourceHandle = sourceNode?.effectiveHandles[connection.fromHandleId];

    if (sourceNode == null || sourceHandle == null) return null;

    final nearbyHandles = nodeIndex.queryHandlesNear(
      cursorPosition,
      searchRadius: snapRadius,
    );
    ClosestHandleResult? closest;
    double minDistance = double.infinity;

    for (final handleKey in nearbyHandles) {
      final keyParts = handleKey.split('/');
      final potentialTargetNodeId = keyParts[0];
      final potentialTargetHandleId = keyParts[1];

      if (potentialTargetNodeId == sourceNode.id) continue;

      final potentialTargetNode = state.nodes[potentialTargetNodeId];
      final potentialTargetHandle =
          potentialTargetNode?.effectiveHandles[potentialTargetHandleId];
      if (potentialTargetNode == null || potentialTargetHandle == null) {
        continue;
      }
      // Explicit end-only opt-out: never a landing candidate (both modes).
      // Plain isConnectable=false stays a candidate so it highlights as
      // invalid (existing behavior); the validator below rejects it.
      if (potentialTargetHandle.isConnectableEnd == false) continue;
      // Strict: only land on targets (unless explicitly end-enabled).
      if (mode == ConnectionMode.strict &&
          potentialTargetHandle.type == HandleType.source &&
          potentialTargetHandle.isConnectableEnd != true) {
        continue;
      }

      final handleCenter =
          NodeLayout.absoluteTopLeft(
            potentialTargetNodeId,
            state.nodes,
            defaultOrigin: defaultOrigin,
          ) +
          potentialTargetHandle.position;
      final dist = (cursorPosition - handleCenter).distance;

      if (dist <= snapRadius && dist < minDistance) {
        minDistance = dist;
        closest = ClosestHandleResult(
          nodeId: potentialTargetNodeId,
          handle: potentialTargetHandle,
          distance: dist,
          node: potentialTargetNode,
        );
      }
    }

    return closest;
  }

  /// Public wrapper used by click-to-connect to validate a concrete handle pair.
  bool isValidConnectionPair(
    FlowNode sourceNode,
    FlowHandle sourceHandle,
    FlowNode targetNode,
    FlowHandle targetHandle, {
    ConnectionMode mode = ConnectionMode.strict,
    bool Function(ConnectionParams connection)? isValidConnection,
    Iterable<FlowEdge> existingEdges = const [],
    bool nodesConnectable = true,
  }) {
    return _isValidConnection(
      sourceNode,
      sourceHandle,
      targetNode,
      targetHandle,
      null,
      mode: mode,
      isValidConnection: isValidConnection,
      existingEdges: existingEdges,
      nodesConnectable: nodesConnectable,
    );
  }

  bool _isValidConnection(
    FlowNode sourceNode,
    FlowHandle sourceHandle,
    FlowNode targetNode,
    FlowHandle targetHandle,
    ConnectionValidator? customValidator, {
    ConnectionMode mode = ConnectionMode.strict,
    bool Function(ConnectionParams connection)? isValidConnection,
    Iterable<FlowEdge> existingEdges = const [],
    bool nodesConnectable = true,
  }) {
    if (sourceNode.id == targetNode.id) return false;
    if (!sourceHandle.isConnectable || !targetHandle.isConnectable) {
      return false;
    }
    if (!(sourceNode.connectable ?? nodesConnectable) ||
        !(targetNode.connectable ?? nodesConnectable)) {
      return false;
    }

    // Explicit role opt-outs apply in every mode (loose included).
    if (sourceHandle.isConnectableStart == false) return false;
    if (targetHandle.isConnectableEnd == false) return false;

    if (mode == ConnectionMode.strict) {
      // Lattice Strict: only source → target (unless the handle explicitly
      // opts into the other role via isConnectableStart/End).
      if (sourceHandle.type == HandleType.target &&
          sourceHandle.isConnectableStart != true) {
        return false;
      }
      if (targetHandle.type == HandleType.source &&
          targetHandle.isConnectableEnd != true) {
        return false;
      }
    }

    // Per-handle capacity (declarative maxConnections).
    if (!sourceHandle.hasCapacity(existingEdges, sourceNode.id) ||
        !targetHandle.hasCapacity(existingEdges, targetNode.id)) {
      return false;
    }

    final params = ConnectionParams(
      sourceNodeId: sourceNode.id,
      sourceHandleId: sourceHandle.id,
      targetNodeId: targetNode.id,
      targetHandleId: targetHandle.id,
    );

    // Per-handle validators run before the canvas-wide one.
    if (sourceHandle.isValidConnection != null &&
        !sourceHandle.isValidConnection!(params)) {
      return false;
    }
    if (targetHandle.isValidConnection != null &&
        !targetHandle.isValidConnection!(params)) {
      return false;
    }
    if (isValidConnection != null && !isValidConnection(params)) {
      return false;
    }
    if (customValidator != null) {
      return customValidator(
        sourceNode,
        sourceHandle,
        targetNode,
        targetHandle,
      );
    }
    return true;
  }

  FlowEdge _createEdge({
    required String sourceNodeId,
    required String sourceHandleId,
    required String targetNodeId,
    required String targetHandleId,
    EdgeFactory? factory,
  }) {
    final edgeId = IdGenerator.generateEdgeId();
    if (factory != null) {
      return factory(
        id: edgeId,
        sourceNodeId: sourceNodeId,
        sourceHandleId: sourceHandleId,
        targetNodeId: targetNodeId,
        targetHandleId: targetHandleId,
      );
    }
    return FlowEdge(
      id: edgeId,
      sourceNodeId: sourceNodeId,
      sourceHandleId: sourceHandleId,
      targetNodeId: targetNodeId,
      targetHandleId: targetHandleId,
    );
  }

  List<FlowEdge> getConnectedEdges(
    FlowCanvasState state,
    String nodeId,
    String handleId,
  ) {
    return state.edges.values
        .where(
          (edge) =>
              (edge.sourceNodeId == nodeId &&
                  edge.sourceHandleId == handleId) ||
              (edge.targetNodeId == nodeId && edge.targetHandleId == handleId),
        )
        .toList();
  }

  HandlePosition _determineHandlePosition(Offset handleOffset, Size nodeSize) {
    final distLeft = handleOffset.dx;
    final distRight = nodeSize.width - handleOffset.dx;
    final distTop = handleOffset.dy;
    final distBottom = nodeSize.height - handleOffset.dy;

    final minDist = [distLeft, distRight, distTop, distBottom].reduce(min);

    if (minDist == distLeft) return HandlePosition.left;
    if (minDist == distRight) return HandlePosition.right;
    if (minDist == distTop) return HandlePosition.top;
    return HandlePosition.bottom;
  }

  HandlePosition _oppositePosition(HandlePosition pos) {
    switch (pos) {
      case HandlePosition.left:
        return HandlePosition.right;
      case HandlePosition.right:
        return HandlePosition.left;
      case HandlePosition.top:
        return HandlePosition.bottom;
      case HandlePosition.bottom:
        return HandlePosition.top;
    }
  }
}
