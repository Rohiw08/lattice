import 'dart:async';
import 'package:lattice/src/features/selection/application/selection_controller.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/canvas/interaction_session.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NodesController {
  NodesController({
    required FlowCanvasInternalController controller,
    required NodeService nodeService,
    required EdgeService edgeService,
    required SelectionController selectionController,
    required SpatialIndexService spatialIndex,
    required EdgeGeometryService edgeGeometryService,
    required GlobalKey viewportKey,
    required InteractionSession interactionSession,
    required this.ref,
  })  : _controller = controller,
        _nodeService = nodeService,
        _edgeService = edgeService,
        _selectionController = selectionController,
        _spatialIndex = spatialIndex,
        _edgeGeometryService = edgeGeometryService,
        _viewportKey = viewportKey,
        _session = interactionSession;

  final FlowCanvasInternalController _controller;
  final NodeService _nodeService;
  final EdgeService _edgeService;
  final SelectionController _selectionController;
  final SpatialIndexService _spatialIndex;
  final EdgeGeometryService _edgeGeometryService;
  final GlobalKey _viewportKey;
  final InteractionSession _session;
  final Ref ref;

  // --- Drag state ---
  bool _isDragActive = false;
  Map<String, Offset> _dragStartPositions = {};
  Set<String> _nodesBeingDragged = {};

  // ─────────────────────────────────────────────────────────────────
  // GETTERS / READ
  // ─────────────────────────────────────────────────────────────────

  FlowNode? getNode(String nodeId) {
    return _nodeService.getNode(_controller.currentState, nodeId);
  }

  NodeRuntimeState? getNodeRuntimeState(String nodeId) {
    return _nodeService.getNodeRuntimeState(_controller.currentState, nodeId);
  }

  /// Lattice `multiSelectionActive` — Meta/Ctrl (or configured keys) held.
  bool _isMultiSelectionActive() {
    return ref.read(flowOptionsProvider).keyboardOptions.isMultiSelectionActive;
  }

  // ─────────────────────────────────────────────────────────────────
  // ADD / REMOVE / UPDATE NODES
  // ─────────────────────────────────────────────────────────────────

  void addNode(FlowNode node) {
    if (_controller.currentState.nodes.containsKey(node.id)) {
      throw ArgumentError('Node with id ${node.id} already exists');
    }
    _controller.mutate((s) => _nodeService.addNode(s, node));

    // Sync using the node from the NEW state so that zIndex and any
    // service-level assignments are captured in the spatial index.
    final finalNode = _controller.currentState.nodes[node.id];
    if (finalNode != null) {
      _spatialIndex.nodeIndex.addNode(finalNode);
      _controller.bumpSpatialVersion();
    }
    final cb = ref.read(flowCanvasCallbacksProvider);
    if (finalNode != null) {
      cb.onNodesChange?.call([NodeAddChange(node: finalNode)]);
    }
  }

  void addNodes(List<FlowNode> nodes) {
    for (final node in nodes) {
      if (_controller.currentState.nodes.containsKey(node.id)) {
        throw ArgumentError('Node with id ${node.id} already exists');
      }
    }
    _controller.mutate((s) => _nodeService.addNodes(s, nodes));

    for (final node in nodes) {
      final finalNode = _controller.currentState.nodes[node.id];
      if (finalNode != null) {
        _spatialIndex.nodeIndex.addNode(finalNode);
      }
    }
    _controller.bumpSpatialVersion();
    final cbAdd = ref.read(flowCanvasCallbacksProvider);
    if (cbAdd.onNodesChange != null) {
      final out = <NodeChange>[];
      for (final node in nodes) {
        final n = _controller.currentState.nodes[node.id];
        if (n != null) out.add(NodeAddChange(node: n));
      }
      if (out.isNotEmpty) cbAdd.onNodesChange!(out);
    }
  }

  void removeNode(String nodeId) => removeNodes({nodeId});

  void removeSelectedNodes() {
    final state = _controller.currentState;
    if (state.selectedNodes.isEmpty) return;
    removeNodes(Set<String>.from(state.selectedNodes));
  }

  void removeNodes(Iterable<String> nodeIds) {
    final oldState = _controller.currentState;
    if (nodeIds.isEmpty) return;
    // Lattice `getElementsToRemove`: removing a parent removes its descendants.
    final allRemoved = _nodeService.getDescendants(oldState, nodeIds);

    // The service skips `deletable: false` nodes (Lattice); edges must only be
    // removed for the nodes that actually go away.
    final stateWithoutNodes =
        _nodeService.removeNodes(oldState, allRemoved.toList());
    final removedIds = <String>[
      for (final id in allRemoved)
        if (oldState.nodes.containsKey(id) &&
            !stateWithoutNodes.nodes.containsKey(id))
          id,
    ];
    if (removedIds.isEmpty) return;

    final edgeIds = _edgeService.getEdgesFromNodes(oldState, removedIds);
    final newState = _edgeService.removeEdges(stateWithoutNodes, edgeIds);
    _controller.mutate((_) => newState);

    for (final edgeId in edgeIds) {
      final edge = oldState.edges[edgeId];
      if (edge != null) {
        _spatialIndex.edgeIndex.removeEdge(edgeId, edge);
      }
    }

    for (final nodeId in removedIds) {
      final node = oldState.nodes[nodeId];
      if (node != null) {
        _spatialIndex.nodeIndex.removeNode(node);
      }
    }
    _controller.bumpSpatialVersion();
    final cbR = ref.read(flowCanvasCallbacksProvider);
    if (cbR.onEdgesChange != null && edgeIds.isNotEmpty) {
      cbR.onEdgesChange!(edgeIds.map((e) => EdgeRemoveChange(id: e)).toList());
    }
    if (cbR.onNodesChange != null && removedIds.isNotEmpty) {
      cbR.onNodesChange!(
          removedIds.map((id) => NodeRemoveChange(id: id)).toList());
    }
  }

  void updateNode(FlowNode node) {
    final oldNode = _nodeService.getNode(_controller.currentState, node.id);
    if (oldNode == null || oldNode == node) return;
    _controller.mutate((s) => _nodeService.updateNode(s, node));
    _spatialIndex.nodeIndex.updateNode(oldNode, node);
    _controller.bumpSpatialVersion();
  }

  /// Replaces [FlowNode.data] for [nodeId] without rebuilding the whole node.
  ///
  /// Prefer this over [updateNode] + [FlowNode.copyWith] when only payload
  /// changes (labels, form fields, colors, etc.).
  ///
  /// ```dart
  /// controller.nodes.updateNodeData(id, MyData(label: 'Hi'));
  /// ```
  void updateNodeData(String nodeId, Object? data) {
    final oldNode = getNode(nodeId);
    if (oldNode == null || oldNode.data == data) return;
    updateNode(oldNode.copyWith(data: data));
  }

  void resizeNode(String nodeId, ResizeDirection direction, Offset delta) {
    final oldState = _controller.currentState;
    final oldNode = _nodeService.getNode(oldState, nodeId);
    if (oldNode == null) return;

    final options = ref.read(flowOptionsProvider);
    final minSize = options.viewportOptions.minNodeSize ?? const Size(50, 50);

    final newState = _nodeService.resizeNode(
      oldState,
      nodeId,
      direction,
      delta,
      minSize: minSize,
    );

    final newNode = newState.nodes[nodeId];
    if (newNode == null || newNode == oldNode) return;

    _controller.updateStateOnly(newState);

    // Parent + all descendants: absolute child positions are stable after Lattice
    // compensation, but parent size/handles and spatial cells still change.
    // Always refresh edges so they never stay stuck on stale geometry.
    final affected = _nodeService.getDescendants(newState, {nodeId});
    for (final id in affected) {
      final before = oldState.nodes[id];
      final after = newState.nodes[id];
      if (before == null || after == null) continue;
      if (before != after) {
        _spatialIndex.nodeIndex.updateNode(before, after);
      }
    }

    _edgeGeometryService.updateEdgesForNodes(
      _controller.currentState,
      affected,
      _spatialIndex.edgeIndex,
    );
    _controller.bumpSpatialVersion();

    if (newNode.size != oldNode.size) {
      ref.read(flowCanvasCallbacksProvider).onNodesChange?.call([
        NodeDimensionsChange(id: nodeId, size: newNode.size),
      ]);
    }
  }

  void onNodeResizeEnd() {
    // Commit the final state to history
    _controller.mutate((s) => s);
  }

  void updateNodeRuntimeState(String nodeId, NodeRuntimeState nodeState) {
    final oldState = _controller.currentState;
    final oldNodeState = _nodeService.getNodeRuntimeState(oldState, nodeId);
    if (oldNodeState == null || oldNodeState == nodeState) return;
    _controller.updateStateOnly(
        _nodeService.updateNodeRuntimeState(oldState, nodeId, nodeState));
  }

  // ─────────────────────────────────────────────────────────────────
  // INTERACTION — TAP / DRAG
  // ─────────────────────────────────────────────────────────────────

  /// Selection on tap-down. Child [FlowNoDrag] / buttons still win the arena.
  void onNodeTap(String nodeId, TapDownDetails details, bool isSelectable) {
    if (!isSelectable) return;
    final state = _controller.currentState;
    final node = state.nodes[nodeId];
    if (node != null && !(node.selectable ?? true)) return;
    final multi = _isMultiSelectionActive();
    if (multi || !state.selectedNodes.contains(nodeId)) {
      _selectionController.selectNode(nodeId, addToSelection: multi);
    }
  }

  /// Abort node drag so a handle can start a connection.
  void yieldToConnectionGesture() {
    if (_isDragActive) {
      onNodePanCancel();
      return;
    }
    final state = _controller.currentState;
    if (state.dragMode == DragMode.node && state.activeConnection == null) {
      _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
    }
  }

  void onNodePanCancel() {
    if (kDebugMode && FlowCanvasDebug.logInteraction) {
      FlowCanvasDebug.interaction(
        'onNodePanCancel',
        'wasDragActive=$_isDragActive dragMode=${_controller.currentState.dragMode}',
      );
    }
    _resetDragState();
  }

  /// Called when a genuine drag starts (pointer has moved enough to count).
  void onNodeDragStart(
      String nodeId, DragStartDetails details, bool isSelectable) {
    // Handle connect-drag arms [DragMode.connection] first; don't steal it.
    if (_controller.currentState.dragMode == DragMode.connection ||
        _controller.currentState.activeConnection != null) {
      return;
    }

    // Guard: if a previous drag wasn't cleaned up, reset first.
    if (_isDragActive) _resetDragState();

    final node = getNode(nodeId);
    if (node == null || !(node.draggable ?? true)) {
      _ensureDragModeReset();
      return;
    }

    final initialState = _controller.currentState;
    final isAlreadySelected = initialState.selectedNodes.contains(nodeId);

    // Prefer selecting on tap-down. Select here only if pan started without it.
    FlowCanvasState stateAfterSelection = initialState;
    if (isSelectable && !isAlreadySelected) {
      final multi = _isMultiSelectionActive();
      _selectionController.selectNode(nodeId, addToSelection: multi);
      stateAfterSelection = _controller.currentState;
    }

    // Whole selection moves only if this node was already selected (Lattice).
    final dragSet = isAlreadySelected
        ? Set<String>.from(stateAfterSelection.selectedNodes)
        : {nodeId};

    // Lattice `getDragItems` (`isParentSelected`): children whose parent is in the
    // drag set are excluded — they already move with the parent through
    // relative positions; dragging them directly would double-move them.
    dragSet.removeWhere(
        (id) => _hasAncestorInDragSet(stateAfterSelection, id, dragSet));

    _nodesBeingDragged = dragSet;

    // Record start positions only for draggable nodes.
    _dragStartPositions = {};
    for (final id in _nodesBeingDragged) {
      final n = stateAfterSelection.nodes[id];
      if (n != null && (n.draggable ?? true)) {
        _dragStartPositions[id] = n.position;
      }
    }

    // Keep only nodes that have a valid start position.
    _nodesBeingDragged.retainWhere((id) => _dragStartPositions.containsKey(id));
    if (_nodesBeingDragged.isEmpty) {
      _ensureDragModeReset();
      return;
    }

    // Disable InteractiveViewer pan only for selection/connection — not node
    // drag. dragMode.node is still set as a session flag (geometry / cull).
    if (_controller.currentState.dragMode != DragMode.node) {
      _controller.updateStateOnly(
          _controller.currentState.copyWith(dragMode: DragMode.node));
    }

    _isDragActive = true;

    // Edges of dragged nodes + descendants (absolute positions change when a
    // parent moves even if child stored coords do not).
    final activeEdges = <String>{};
    final affected = _nodeService.getDescendants(
      stateAfterSelection,
      _nodesBeingDragged,
    );
    for (final id in affected) {
      activeEdges.addAll(_spatialIndex.edgeIndex.getEdgesForNode(id));
    }
    _session.beginDrag(
      nodeIds: _nodesBeingDragged,
      startPositions: Map<String, Offset>.from(_dragStartPositions),
      edgeIds: activeEdges,
    );

    if (kDebugMode && FlowCanvasDebug.logInteraction) {
      FlowCanvasDebug.interaction(
        'onNodeDragStart',
        'nodeId=$nodeId dragging=${_nodesBeingDragged.length} ids=$_nodesBeingDragged',
      );
    }
  }

  /// Called every frame while the pointer is moving.
  void onNodeDragUpdate(DragUpdateDetails details) {
    if (!_isDragActive) return;
    if (_nodesBeingDragged.isEmpty) return;

    if (_controller.currentState.dragMode != DragMode.node) {
      _controller.updateStateOnly(
          _controller.currentState.copyWith(dragMode: DragMode.node));
    }

    _moveNodesBy(details.delta, _nodesBeingDragged);
    _handleAutoPan(details.globalPosition);
  }

  /// Called when the pointer is lifted — the drag completed successfully.
  void onNodeDragEnd(DragEndDetails details) {
    if (!_isDragActive) {
      if (kDebugMode && FlowCanvasDebug.logInteraction) {
        FlowCanvasDebug.interaction(
          'onNodeDragEnd',
          'skipped (!isDragActive) dragMode=${_controller.currentState.dragMode}',
        );
      }
      // Don't clear [DragMode.connection] — handle connect owns that gesture.
      final mode = _controller.currentState.dragMode;
      if (mode == DragMode.connection) return;
      if (_session.isActive || mode == DragMode.node) {
        _resetDragState();
      } else {
        _ensureDragModeReset();
      }
      return;
    }

    // Clear the active flag immediately so a following pointer-up cannot
    // re-enter and double-commit.
    _isDragActive = false;
    _stopAutoPan();
    // Persist auto-pan into Freezed before node commit. Otherwise the live
    // matrix is ahead of state.viewport and the next updateStateOnly would
    // either leave Freezed stale or (previously) snap the camera back.
    _controller.commitLiveViewportToState();

    final draggedIds = Set<String>.from(_nodesBeingDragged);
    final live = Map<String, Offset>.from(_session.livePositions);
    final liveSizes = Map<String, Size>.from(_session.liveSizes);
    final before = _controller.currentState;
    var next = before;

    final vo = ref.read(flowOptionsProvider).viewportOptions;

    // Lattice `calculateSnapOffset`: multi-drags share one snap offset so the
    // selection moves as a unit; single nodes snap individually.
    if (vo.snapToGrid && draggedIds.isNotEmpty) {
      if (draggedIds.length > 1) {
        final refPos = live[draggedIds.first];
        if (refPos != null) {
          final offset = vo.snapGrid.snap(refPos) - refPos;
          if (offset != Offset.zero) {
            for (final id in draggedIds) {
              final p = live[id];
              if (p != null) live[id] = p + offset;
            }
          }
        }
      } else {
        final refPos = live[draggedIds.first];
        if (refPos != null) live[draggedIds.first] = vo.snapGrid.snap(refPos);
      }
    }

    // Commit live positions (dragged + expandParent-grown parents + shifted
    // siblings) and live sizes (grown parents).
    final affectedIds = <String>{
      ...draggedIds,
      ...live.keys,
      ...liveSizes.keys,
    };
    for (final id in affectedIds) {
      final n = next.nodes[id];
      if (n == null) continue;

      final pos = live[id];
      if (pos != null) {
        var finalPos = pos;
        // extent: 'parent' without expandParent clamps to the parent box
        // (Lattice skips the clamp while expandParent is set).
        if (n.extent == FlowNodeExtent.parent &&
            n.parentId != null &&
            !n.expandParent) {
          final parent = next.nodes[n.parentId!];
          if (parent != null) {
            finalPos =
                NodeLayout.clampToParent(finalPos, n.size, parent.size);
          }
        }
        if (finalPos != n.position) {
          next = _nodeService.updateNode(next, n.copyWith(position: finalPos));
        }
      }

      final size = liveSizes[id];
      if (size != null && size != n.size) {
        final current = next.nodes[id] ?? n;
        next = _nodeService.updateNode(next, current.copyWith(size: size));
      }
    }

    // expandParent final pass (Lattice `handleExpandParent` runs after the snapped
    // positions): grows parents and shifts siblings from committed state.
    next = _nodeService.applyExpandParent(next, draggedIds);

    if (next != before) {
      _controller.updateStateOnly(next);
      // Re-sync spatial entries for dragged nodes, grown parents and shifted
      // siblings (absolute positions of children change when a parent moves).
      final affected =
          _nodeService.getDescendants(_controller.currentState, draggedIds)
            ..addAll(liveSizes.keys)
            ..addAll(live.keys);
      for (final id in affected) {
        final committed = _controller.currentState.nodes[id];
        final indexed = _spatialIndex.nodeIndex.getNode(id);
        if (committed == null) continue;
        if (indexed == null) {
          _spatialIndex.nodeIndex.addNode(committed);
        } else {
          _spatialIndex.nodeIndex.updateNode(indexed, committed);
        }
      }
      _edgeGeometryService.updateEdgesForNodes(
        _controller.currentState,
        affected,
        _spatialIndex.edgeIndex,
      );
      if (kDebugMode) FlowCanvasDebug.countDragCommit();
    }

    // Always invalidate cull cache after a drag gesture so remount uses
    // fresh spatial + Freezed positions.
    _controller.bumpSpatialVersion();

    _session.endDrag();

    final finalState = _controller.currentState;
    final changedFromStart = draggedIds.any((id) {
      final start = _dragStartPositions[id];
      final n = finalState.nodes[id];
      return start != null && n != null && n.position != start;
    });

    if (changedFromStart) {
      _controller.commitHistoryCheckpoint();
    }

    final cbDragEnd = ref.read(flowCanvasCallbacksProvider);
    if (changedFromStart && cbDragEnd.onNodesChange != null) {
      final changes = <NodeChange>[];
      final finalState = _controller.currentState;
      for (final id in affectedIds) {
        final n = finalState.nodes[id];
        if (n == null) continue;
        final start = _dragStartPositions[id];
        if (start == null || n.position != start) {
          changes.add(NodePositionChange(
            id: id,
            position: n.position,
            dragging: false,
          ));
        }
        if (liveSizes[id] != null && liveSizes[id] != n.size) {
          changes.add(NodeDimensionsChange(id: id, size: n.size));
        }
      }
      if (changes.isNotEmpty) {
        cbDragEnd.onNodesChange!(changes);
      }
    }

    _ensureDragModeReset();

    if (kDebugMode && FlowCanvasDebug.logInteraction) {
      FlowCanvasDebug.interaction(
        'onNodeDragEnd',
        'changedFromStart=$changedFromStart dragMode=${_controller.currentState.dragMode}',
      );
    }

    _dragStartPositions = {};
    _nodesBeingDragged.clear();
  }

  // ─────────────────────────────────────────────────────────────────
  // INTERACTION — MOUSE HOVER
  // ─────────────────────────────────────────────────────────────────

  void onNodeMouseEnter(String nodeId, PointerEvent details) {
    final state = _controller.currentState;
    // Clear edge hover when the pointer enters a node (edge hit layer no longer
    // receives hover once the node is on top).
    var next = state;
    if (state.hoveredEdgeId.isNotEmpty) {
      next = next.copyWith(hoveredEdgeId: '');
    }
    final nodeState = _nodeService.getNodeRuntimeState(next, nodeId);
    if (nodeState == null) {
      if (!identical(next, state)) _controller.updateStateOnly(next);
      return;
    }
    _controller.updateStateOnly(_nodeService.updateNodeRuntimeState(
        next, nodeId, nodeState.copyWith(hovered: true)));
  }

  void onNodeMouseMove(String nodeId, PointerEvent details) {}

  void onNodeMouseLeave(String nodeId, PointerEvent details) {
    final nodeState =
        _nodeService.getNodeRuntimeState(_controller.currentState, nodeId);
    if (nodeState == null) return;
    _controller.updateStateOnly(_nodeService.updateNodeRuntimeState(
        _controller.currentState, nodeId, nodeState.copyWith(hovered: false)));
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIVATE — DRAG HELPERS
  // ─────────────────────────────────────────────────────────────────

  /// Single source-of-truth cleanup. Safe to call from any path.
  void _resetDragState() {
    _stopAutoPan();
    _controller.commitLiveViewportToState();
    _isDragActive = false;
    _dragStartPositions = {};
    _nodesBeingDragged.clear();
    if (_session.isActive) _session.endDrag();
    _ensureDragModeReset();
  }

  /// Resets dragMode to none via updateStateOnly (no history entry).
  void _ensureDragModeReset() {
    final state = _controller.currentState;
    // Connection / selection own their modes — node drag must not clobber them.
    if (state.dragMode == DragMode.node) {
      _controller.updateStateOnly(state.copyWith(dragMode: DragMode.none));
    }
  }

  void _emitNodeDragLivePositions(Set<String> ids) {
    final handler = ref.read(flowCanvasCallbacksProvider).onNodeDrag;
    if (handler == null) return;
    final list = <NodeChange>[];
    final emitted = <String>{};
    final state = _controller.currentState;
    for (final id in ids) {
      final pos = _session.livePositions[id];
      if (pos != null) {
        list.add(NodePositionChange(
          id: id,
          position: pos,
          dragging: true,
        ));
        emitted.add(id);
      }
    }
    // expandParent effects (Lattice emits parent position + dimensions and shifted
    // sibling positions in the same change batch).
    for (final entry in _session.liveSizes.entries) {
      final node = state.nodes[entry.key];
      if (node == null) continue;
      final pos = _session.livePositions[entry.key];
      if (pos != null &&
          pos != node.position &&
          emitted.add(entry.key)) {
        list.add(NodePositionChange(
          id: entry.key,
          position: pos,
          dragging: true,
        ));
      }
      if (entry.value != node.size) {
        list.add(NodeDimensionsChange(id: entry.key, size: entry.value));
      }
    }
    for (final entry in _session.livePositions.entries) {
      if (emitted.contains(entry.key)) continue;
      final node = state.nodes[entry.key];
      if (node == null) continue;
      if (entry.value != node.position) {
        list.add(NodePositionChange(
          id: entry.key,
          position: entry.value,
          dragging: true,
        ));
        emitted.add(entry.key);
      }
    }
    if (list.isNotEmpty) {
      handler(list);
    }
  }

  Offset _clampLivePosition(
    Offset position,
    Size size,
    CoordinateExtent? nodeExtent,
  ) {
    if (nodeExtent == null || nodeExtent.isInfinite) return position;
    return Offset(
      position.dx.clamp(nodeExtent.minX, nodeExtent.maxX - size.width),
      position.dy.clamp(nodeExtent.minY, nodeExtent.maxY - size.height),
    );
  }

  void _moveNodesBy(Offset canvasDelta, Set<String> nodesToMove) {
    if (!_isDragActive) return;
    if (nodesToMove.isEmpty) return;
    if (canvasDelta == Offset.zero) return;

    final state = _controller.currentState;
    final vo = ref.read(flowOptionsProvider).viewportOptions;
    final nodeExtent = vo.nodeExtent;
    final isMultiDrag = nodesToMove.length > 1;
    final snapToGrid = vo.snapToGrid;
    final snapGrid = vo.snapGrid;

    final next = <String, Offset>{};
    Offset? multiSnapOffset;
    for (final id in nodesToMove) {
      final current = _session.livePositions[id];
      final node = state.nodes[id];
      if (current == null || node == null) continue;
      // Lattice `XYDrag.updateNodes`: snap every frame while dragging — single
      // nodes snap to the grid, multi-drags share one offset computed from
      // the first drag item so the selection moves as a unit.
      var raw = current + canvasDelta;
      if (snapToGrid) {
        if (!isMultiDrag) {
          raw = snapGrid.snap(raw);
        } else if (multiSnapOffset == null && id == nodesToMove.first) {
          multiSnapOffset = snapGrid.snap(raw) - raw;
        }
        if (multiSnapOffset != null) {
          raw = Offset(
            (raw.dx + multiSnapOffset.dx).roundToDouble(),
            (raw.dy + multiSnapOffset.dy).roundToDouble(),
          );
        }
      }
      next[id] = _clampNodeLivePosition(
        state,
        id,
        node,
        raw,
        canvasDelta,
        nodeExtent,
        isMultiDrag: isMultiDrag,
        nodesToMove: nodesToMove,
      );
    }
    _session.setLivePositions(next);

    // Lattice `expandParent` + `handleExpandParent` (live): while a child with
    // expandParent is dragged past its parent's edge, grow the parent
    // position/size and shift sibling children so their absolute positions
    // stay put. Sizes stay live until drag end (parent grows on screen).
    for (final id in nodesToMove) {
      final node = state.nodes[id];
      if (node == null || !node.expandParent || node.parentId == null) {
        continue;
      }
      final parent = state.nodes[node.parentId!];
      if (parent == null) continue;
      final childPos = _session.livePositions[id];
      if (childPos == null) continue;

      final parentPos = _session.livePositions[parent.id] ?? parent.position;
      final parentSize = _session.liveSizes[parent.id] ?? parent.size;

      final fit = NodeLayout.expandParentFit(
        parentPosition: parentPos,
        parentSize: parentSize,
        childPosition: childPos,
        childSize: node.size,
      );
      if (fit == null) continue;

      _session.setLivePositions({
        parent.id: fit.parentPosition,
        id: fit.childPosition,
      });
      _session.setLiveSize(parent.id, fit.parentSize);

      final originDelta = fit.parentPosition - parentPos;
      for (final sibling in state.nodes.values) {
        if (sibling.parentId != parent.id ||
            nodesToMove.contains(sibling.id)) {
          continue;
        }
        _session.setLivePositions(
            {sibling.id: sibling.position - originDelta});
      }
    }

    final affected =
        _nodeService.getDescendants(state, nodesToMove)
          ..addAll(_session.livePositions.keys)
          ..addAll(_session.liveSizes.keys);
    _edgeGeometryService.updateEdgesForNodes(
      state,
      affected,
      _spatialIndex.edgeIndex,
      livePositions: _session.livePositions,
    );
    _emitNodeDragLivePositions(nodesToMove);
  }

  /// Clamps one node's next position (Lattice `calculateNodePosition`).
  ///
  /// - `extent: 'parent'` clamps in parent-relative space; [FlowNode.expandParent]
  ///   bypasses clamping entirely (Lattice) — `handleExpandParent` grows the parent.
  /// - [CoordinateExtent] (global `nodeExtent`) clamps in **absolute** flow
  ///   space, including for children; multi-drags use Lattice's per-node adjusted
  ///   extents so the whole selection stays inside the extent.
Offset _clampNodeLivePosition(
    FlowCanvasState state,
    String id,
    FlowNode node,
    Offset raw,
    Offset canvasDelta,
    CoordinateExtent? nodeExtent, {
    required bool isMultiDrag,
    required Set<String> nodesToMove,
  }) {
    if (node.extent == FlowNodeExtent.parent) {
      final parent = node.parentId != null ? state.nodes[node.parentId!] : null;
      if (parent == null || node.expandParent) return raw;
      return NodeLayout.clampToParent(raw, node.size, parent.size);
    }

    if (nodeExtent == null || nodeExtent.isInfinite) return raw;

    final parentAbs = node.parentId != null
        ? NodeLayout.absolutePosition(
            node.parentId!,
            state.nodes,
            livePositions: _session.livePositions,
          )
        : Offset.zero;

    final absRaw = raw + parentAbs;

    var extent = nodeExtent;
    if (isMultiDrag) {
      final box = _dragSetBounds(state, nodesToMove);
      if (box != null) {
        final currentAbs = parentAbs + (raw - canvasDelta);
        extent = CoordinateExtent(
          minX: currentAbs.dx - box.left + nodeExtent.minX,
          minY: currentAbs.dy - box.top + nodeExtent.minY,
          maxX: currentAbs.dx + node.size.width - box.right + nodeExtent.maxX,
          maxY: currentAbs.dy + node.size.height - box.bottom + nodeExtent.maxY,
        );
      }
    }
    final clampedAbs = _clampLivePosition(absRaw, node.size, extent);
    return clampedAbs - parentAbs;
  }

  /// Union of the drag set's absolute rects (live positions).
  Rect? _dragSetBounds(FlowCanvasState state, Set<String> ids) {
    Rect? union;
    for (final id in ids) {
      final node = state.nodes[id];
      if (node == null) continue;
      final abs = NodeLayout.absolutePosition(
        id,
        state.nodes,
        livePositions: _session.livePositions,
      );
      final rect = Rect.fromLTWH(
          abs.dx, abs.dy, node.size.width, node.size.height);
      union = union == null ? rect : union.expandToInclude(rect);
    }
    return union;
  }

  /// Lattice `isParentSelected`: true when any ancestor of [id] is in [dragSet].
  bool _hasAncestorInDragSet(
      FlowCanvasState state, String id, Set<String> dragSet) {
    var parentId = state.nodes[id]?.parentId;
    final seen = <String>{id};
    while (parentId != null && seen.add(parentId)) {
      if (dragSet.contains(parentId)) return true;
      parentId = state.nodes[parentId]?.parentId;
    }
    return false;
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIVATE — AUTO PAN
  // ─────────────────────────────────────────────────────────────────

  Timer? _autoPanTimer;
  Offset _autoPanVelocity = Offset.zero;

  void _handleAutoPan(Offset globalPosition) {
    final options = ref.read(flowOptionsProvider);
    if (!options.viewportOptions.autoPanOnNodeDrag) {
      _stopAutoPan();
      return;
    }
    final viewportSize = _controller.currentState.viewportSize;
    if (viewportSize == null) return;

    final renderBox =
        _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPosition);
    final margin = options.viewportOptions.autoPanMargin;
    final speed = options.viewportOptions.autoPanSpeed;

    // Lattice `calcAutoPanVelocity`: ramps from ~speed/margin at the margin
    // boundary up to `speed` at the canvas edge.
    double autoPanVelocityAt(double distanceFromEdge) {
      if (margin <= 0) return speed;
      return (distanceFromEdge.clamp(1.0, margin) / margin) * speed;
    }

    double dx = 0;
    double dy = 0;

    if (localPos.dx < margin) {
      dx = autoPanVelocityAt(margin - localPos.dx);
    } else if (localPos.dx > viewportSize.width - margin) {
      dx = -autoPanVelocityAt(localPos.dx - (viewportSize.width - margin));
    }

    if (localPos.dy < margin) {
      dy = autoPanVelocityAt(margin - localPos.dy);
    } else if (localPos.dy > viewportSize.height - margin) {
      dy = -autoPanVelocityAt(localPos.dy - (viewportSize.height - margin));
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
    if (!_isDragActive || _autoPanVelocity == Offset.zero) return;

    // Live matrix pan — no Freezed viewport write every tick.
    _controller.panLiveBy(_autoPanVelocity);

    final zoom = _controller.liveViewport.zoom;
    final canvasDelta = -_autoPanVelocity / zoom;
    _moveNodesBy(canvasDelta, _nodesBeingDragged);
  }

  void _stopAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
    _autoPanVelocity = Offset.zero;
  }
}
