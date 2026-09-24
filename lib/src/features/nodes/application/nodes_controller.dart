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
import 'package:flutter/gestures.dart';
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
  }) : _controller = controller,
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

  /// Parent→children adjacency captured at drag-start. The tree shape is
  /// stable across a drag (only positions move), so [_moveNodesBy] reuses this
  /// every frame instead of rescanning all nodes via
  /// [NodeService.getDescendants].
  Map<String, List<String>>? _dragAdjacency;

  /// Accumulated pointer travel in flow units since drag start (gesture
  /// deltas + auto-pan tick compensation). React Flow `XYDrag.updateNodes`:
  /// RF maps pointer -> node ABSOLUTELY (`nextPosition = pointer -
  /// distance`) instead of accumulating per-frame deltas, so pushing into a
  /// clamp and returning the pointer leaves a dead zone — never a permanent
  /// gap — and restores the origin. Re-adding the accumulated travel to the
  /// drag-start positions gives the same semantics on delta-driven gestures
  /// (every set member's parent is static mid-drag: children of a dragged
  /// parent are excluded from the set, so start + travel is exact).
  Offset _pointerTravel = Offset.zero;

  // --- Resize session (absolute mapping, same dead-zone semantics as drag) ---
  String? _resizeNodeId;
  ResizeDirection? _resizeDirection;
  Rect? _resizeBaseRect;
  Offset _resizeTravel = Offset.zero;

  void _clearResizeSession() {
    _resizeNodeId = null;
    _resizeDirection = null;
    _resizeBaseRect = null;
    _resizeTravel = Offset.zero;
  }

  // ─────────────────────────────────────────────────────────────────
  // GETTERS / READ
  // ─────────────────────────────────────────────────────────────────

  FlowNode? getNode(String nodeId) {
    return _nodeService.getNode(_controller.currentState, nodeId);
  }

  NodeRuntimeState? getNodeRuntimeState(String nodeId) {
    return _nodeService.getNodeRuntimeState(_controller.currentState, nodeId);
  }

  /// Canvas default origin (`NodeOptions.nodeOrigin`) for rect resolution.
  ///
  /// Per-node [FlowNode.origin] wins where set; everywhere a visual rect is
  /// needed, resolve via `NodeLayout.absoluteRect(..., defaultOrigin:
  /// _nodeOrigin())`.
  Offset _nodeOrigin() => ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;

  /// Z-index management mode for structural bumps (add/update).
  ZIndexMode _zMode() => ref.read(flowOptionsProvider).zIndexMode;

  /// Returns nodes whose absolute bounds intersect [nodeId]'s bounds.
  ///
  /// React Flow `getIntersectingNodes` counterpart. The spatial grid prefilters
  /// candidates (sub-linear) before the precise rect test, so this stays
  /// cheap on large graphs — no full node scan.
  ///
  /// - [partially]: `true` (default) matches any overlap; `false` matches
  ///   only nodes fully contained in [nodeId]'s bounds.
  /// - Hidden nodes are skipped (they are not interactive).
  /// - Results are sorted by id for deterministic output.
  List<FlowNode> getIntersectingNodes(String nodeId, {bool partially = true}) {
    final state = _controller.currentState;
    final node = state.nodes[nodeId];
    if (node == null) return const [];
    final defaultOrigin = _nodeOrigin();
    final rect = NodeLayout.absoluteRect(
      node,
      state.nodes,
      defaultOrigin: defaultOrigin,
    );
    final out = <FlowNode>[];
    for (final id in _spatialIndex.nodeIndex.queryNodesInRect(rect)) {
      if (id == nodeId) continue;
      final other = state.nodes[id];
      if (other == null || (other.hidden ?? false)) continue;
      final otherRect = NodeLayout.absoluteRect(
        other,
        state.nodes,
        defaultOrigin: defaultOrigin,
      );
      final hits = partially
          ? rect.overlaps(otherRect)
          : (otherRect.left >= rect.left &&
                otherRect.top >= rect.top &&
                otherRect.right <= rect.right &&
                otherRect.bottom <= rect.bottom);
      if (hits) out.add(other);
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// Whether the absolute bounds of [aId] and [bId] overlap.
  ///
  /// React Flow `isNodeIntersecting` counterpart for node pairs. Returns false
  /// when either node is missing.
  bool isNodeIntersecting(String aId, String bId) {
    final state = _controller.currentState;
    final a = state.nodes[aId];
    final b = state.nodes[bId];
    if (a == null || b == null) return false;
    final defaultOrigin = _nodeOrigin();
    return NodeLayout.absoluteRect(
      a,
      state.nodes,
      defaultOrigin: defaultOrigin,
    ).overlaps(
      NodeLayout.absoluteRect(b, state.nodes, defaultOrigin: defaultOrigin),
    );
  }

  /// Nodes whose absolute bounds intersect [rect] (React Flow
  /// `getIntersectingNodes` rect form).
  ///
  /// Spatial-prefiltered, hidden nodes skipped, sorted by id.
  List<FlowNode> queryNodesInRect(Rect rect) {
    final state = _controller.currentState;
    final out = <FlowNode>[];
    for (final id in _spatialIndex.nodeIndex.queryNodesInRect(rect)) {
      final node = state.nodes[id];
      if (node == null || (node.hidden ?? false)) continue;
      out.add(node);
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// React Flow `multiSelectionActive` — Meta/Ctrl (or configured keys) held.
  bool _isMultiSelectionActive() {
    return ref.read(flowOptionsProvider).keyboardOptions.isMultiSelectionActive;
  }

  String? _lastTapNodeId;
  DateTime? _lastTapTime;

  /// True while a multi-node drag is live (drives onSelectionDrag*).
  bool _selectionDragActive = false;

  /// Position changes for [ids] (drag-set shape shared by onNodeDrag* and
  /// onSelectionDrag*). Live positions win; committed positions fill gaps.
  List<NodeChange> _dragSetChanges(Set<String> ids, {required bool dragging}) {
    final state = _controller.currentState;
    final live = _session.livePositions;
    return [
      for (final id in ids)
        if (state.nodes[id] != null)
          NodePositionChange(
            id: id,
            position: live[id] ?? state.nodes[id]!.position,
            dragging: dragging,
          ),
    ];
  }

  // ─────────────────────────────────────────────────────────────────
  // ADD / REMOVE / UPDATE NODES
  // ─────────────────────────────────────────────────────────────────

  /// Warns once per misconfigured node through `onError` (never throws).
  ///
  /// Checked at mutation points — not per rebuild — so a mistake warns
  /// once instead of spamming every frame like render-time warnings do.
  void _warnNodeMisuse(FlowNode node) {
    final onError = ref.read(flowCanvasCallbacksProvider).onError;
    if (onError == null) return;
    if (node.extent == FlowNodeExtent.parent && node.parentId == null) {
      onError(
        FlowCanvasError(
          'extent-without-parent',
          'Node "${node.id}" uses extent=parent without a parentId; '
              'the extent is ignored. Set parentId or remove the extent.',
        ),
      );
    }
    if (!ref.read(nodeRegistryProvider).isRegistered(node.type)) {
      onError(
        FlowCanvasError(
          'unregistered-node-type',
          'Node "${node.id}" has unregistered type "${node.type}" and falls '
              'back to the default look. Register it to silence this warning.',
        ),
      );
    }
  }

  void addNode(FlowNode node) {
    if (_controller.currentState.nodes.containsKey(node.id)) {
      throw ArgumentError('Node with id ${node.id} already exists');
    }
    _warnNodeMisuse(node);
    _controller.mutate(
      (s) => _nodeService.addNode(s, node, zIndexMode: _zMode()),
    );

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
    for (final node in nodes) {
      _warnNodeMisuse(node);
    }
    _controller.mutate(
      (s) => _nodeService.addNodes(s, nodes, zIndexMode: _zMode()),
    );

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
    // React Flow `getElementsToRemove`: removing a parent removes its descendants.
    final allRemoved = _nodeService.getDescendants(oldState, nodeIds);

    // The service skips `deletable: false` nodes (React Flow); edges must only be
    // removed for the nodes that actually go away.
    final stateWithoutNodes = _nodeService.removeNodes(
      oldState,
      allRemoved.toList(),
    );
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
        removedIds.map((id) => NodeRemoveChange(id: id)).toList(),
      );
    }
  }

  void updateNode(FlowNode node) {
    final oldNode = _nodeService.getNode(_controller.currentState, node.id);
    if (oldNode == null || oldNode == node) return;
    _controller.mutate(
      (s) => _nodeService.updateNode(s, node, zIndexMode: _zMode()),
    );
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

  /// Function-updater variant of [updateNodeData].
  ///
  /// React Flow's `updateNodeData(id, fn)` counterpart. [updater] receives
  /// the current `data` and returns the next one; a no-change (`==`) result
  /// is skipped. Use this for transforms (`ColorPreview -> Lightness`) where
  /// the next value derives from the previous one.
  ///
  /// ```dart
  /// controller.nodes.updateNodeDataWith('color', (old) => {...});
  /// ```
  void updateNodeDataWith(
    String nodeId,
    Object? Function(Object? old) updater,
  ) {
    final oldNode = getNode(nodeId);
    if (oldNode == null) return;
    updateNodeData(nodeId, updater(oldNode.data));
  }

  /// Merges [patch] into `Map` node data (React Flow's default merge).
  ///
  /// In React Flow `updateNodeData` shallow-merges (`{...old, ...patch}`)
  /// because JS data is always an object. In Dart only `Map` payloads can
  /// merge: when the current data is a `Map<String, dynamic>` the patch is
  /// merged over a copy; when it is null the patch becomes the data;
  /// otherwise this asserts in debug (replace instead via [updateNodeData]).
  ///
  /// Pass `replace: true` to mirror RF's `{ replace: true }` option.
  void patchNodeData(
    String nodeId,
    Map<String, dynamic> patch, {
    bool replace = false,
  }) {
    final oldNode = getNode(nodeId);
    if (oldNode == null) return;
    final old = oldNode.data;
    if (replace || old == null) {
      updateNodeData(nodeId, Map<String, dynamic>.from(patch));
      return;
    }
    assert(
      old is Map,
      'patchNodeData needs Map data (got ${old.runtimeType}); '
      'use updateNodeData to replace custom data objects.',
    );
    if (old is! Map) {
      updateNodeData(nodeId, Map<String, dynamic>.from(patch));
      return;
    }
    final merged = Map<String, dynamic>.from(old);
    merged.addAll(patch);
    updateNodeData(nodeId, merged);
  }

  /// Recomputes derived caches for [nodeId]'s subtree without touching the
  /// model or history.
  ///
  /// React Flow `updateNodeInternals` counterpart. Call after a custom node's
  /// *rendered* geometry changed without a model write (e.g. a handle
  /// builder that positions handles from measured widget size): re-registers
  /// spatial cells, refreshes attached edge paths, and bumps the edge
  /// revision so edges repaint. No-op for missing ids.
  void updateNodeInternals(String nodeId) {
    final state = _controller.currentState;
    if (!state.nodes.containsKey(nodeId)) return;
    final affected = _nodeService.getDescendants(state, {nodeId});
    for (final id in affected) {
      final n = state.nodes[id];
      if (n == null) continue;
      // NOTE: index.updateNode(old, new) skips equal instances by design,
      // so force re-registration explicitly.
      _spatialIndex.nodeIndex.removeNode(n);
      _spatialIndex.nodeIndex.addNode(n);
    }
    _edgeGeometryService.updateEdgesForNodes(
      state,
      affected,
      _spatialIndex.edgeIndex,
      defaultOrigin: _nodeOrigin(),
    );
    _controller.bumpSpatialVersion();
    // Transient revision touch (no history): wakes edge painters so the
    // refreshed paths actually repaint.
    _controller.updateStateOnly(
      state.copyWith(geometryRevision: state.geometryRevision + 1),
    );
  }

  /// Anchors a resize gesture: the base rect is captured at activation (the
  /// framework absorbs touch slop before the first update, so travel starts
  /// at zero from here) and every update's delta accumulates into travel.
  /// The service maps `base + travel` absolutely, so pushing an edge into
  /// the child-extent floor or min-size clamp and coming back dead-zones
  /// instead of keeping a gap (same semantics as node drag).
  void onNodeResizeStart(String nodeId, ResizeDirection direction) {
    final node = getNode(nodeId);
    if (node == null) {
      _clearResizeSession();
      return;
    }
    _resizeNodeId = nodeId;
    _resizeDirection = direction;
    _resizeBaseRect = node.rect;
    _resizeTravel = Offset.zero;
    ref.read(flowCanvasCallbacksProvider).onNodeResizeStart?.call(node);
  }

  void resizeNode(String nodeId, ResizeDirection direction, Offset delta) {
    final oldState = _controller.currentState;
    final oldNode = _nodeService.getNode(oldState, nodeId);
    if (oldNode == null) return;

    // Defensive anchor: updates should always follow onNodeResizeStart, but
    // re-anchor if the session is missing or targets something else.
    if (_resizeNodeId != nodeId ||
        _resizeDirection != direction ||
        _resizeBaseRect == null) {
      _resizeNodeId = nodeId;
      _resizeDirection = direction;
      _resizeBaseRect = oldNode.rect;
      _resizeTravel = Offset.zero;
    }
    _resizeTravel += delta;

    final options = ref.read(flowOptionsProvider);
    final minSize = options.viewportOptions.minNodeSize ?? const Size(50, 50);

    final newState = _nodeService.resizeNode(
      oldState,
      nodeId,
      direction,
      _resizeTravel,
      minSize: minSize,
      maxSize: options.viewportOptions.maxNodeSize,
      baseRect: _resizeBaseRect,
      defaultOrigin: options.nodeOptions.nodeOrigin,
      expandParentDefault: options.nodeOptions.expandParent,
    );

    final newNode = newState.nodes[nodeId];
    if (newNode == null || newNode == oldNode) return;

    _controller.updateStateOnly(newState);

    // Parent + all descendants: absolute child positions are stable after React Flow
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
      defaultOrigin: _nodeOrigin(),
    );
    _controller.bumpSpatialVersion();

    if (newNode.size != oldNode.size) {
      ref.read(flowCanvasCallbacksProvider).onNodesChange?.call([
        NodeDimensionsChange(id: nodeId, size: newNode.size),
      ]);
    }
    ref.read(flowCanvasCallbacksProvider).onNodeResize?.call(newNode);
  }

  void onNodeResizeEnd() {
    // Commit the final state to history
    final nodeId = _resizeNodeId;
    _controller.mutate((s) => s);
    _clearResizeSession();
    final node = nodeId == null ? null : getNode(nodeId);
    if (node != null) {
      ref.read(flowCanvasCallbacksProvider).onNodeResizeEnd?.call(node);
    }
  }

  void updateNodeRuntimeState(String nodeId, NodeRuntimeState nodeState) {
    final oldState = _controller.currentState;
    final oldNodeState = _nodeService.getNodeRuntimeState(oldState, nodeId);
    if (oldNodeState == null || oldNodeState == nodeState) return;
    _controller.updateStateOnly(
      _nodeService.updateNodeRuntimeState(oldState, nodeId, nodeState),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // INTERACTION — TAP / DRAG
  // ─────────────────────────────────────────────────────────────────

  /// Selection on tap-down. Child [FlowNoDrag] / buttons still win the arena.
  ///
  /// Skipped while the pan-activation key is held (space+click pans instead;
  /// keyboard Space on a focused node still selects via [FlowFocusableNode]).
  void onNodeTap(String nodeId, TapDownDetails details, bool isSelectable) {
    if (!isSelectable) return;
    if (ref.read(flowOptionsProvider).keyboardOptions.isPanActivationHeld) {
      return;
    }
    final state = _controller.currentState;
    final node = state.nodes[nodeId];
    final nodeOpts = ref.read(flowOptionsProvider).nodeOptions;
    if (node != null && !(node.selectable ?? nodeOpts.selectable)) return;
    final multi = _isMultiSelectionActive();
    // Non-interactive: taps still observe (onNodeClick below) but select
    // nothing — React Flow `setInteractive(false)` parity.
    if (state.interactive && (multi || !state.selectedNodes.contains(nodeId))) {
      _selectionController.selectNode(nodeId, addToSelection: multi);
    }
    if (node == null) return;
    final flowPos = _controller.viewport.flowPositionFromGlobal(
      details.globalPosition,
    );
    if (flowPos == null) return;
    final cbs = ref.read(flowCanvasCallbacksProvider);
    cbs.onNodeClick?.call(node, flowPos);
    // Manual double-tap (a second recognizer would delay single-tap
    // selection): second tap-down on the same node within the platform
    // double-tap timeout also fires onNodeDoubleClick.
    final now = DateTime.now();
    final lastId = _lastTapNodeId;
    final lastTime = _lastTapTime;
    if (lastId == nodeId &&
        lastTime != null &&
        now.difference(lastTime) <= kDoubleTapTimeout) {
      cbs.onNodeDoubleClick?.call(node, flowPos);
      _lastTapNodeId = null;
      _lastTapTime = null;
    } else {
      _lastTapNodeId = nodeId;
      _lastTapTime = now;
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
    String nodeId,
    DragStartDetails details,
    bool isSelectable,
  ) {
    // Handle connect-drag arms [DragMode.connection] first; don't steal it.
    if (_controller.currentState.dragMode == DragMode.connection ||
        _controller.currentState.activeConnection != null) {
      return;
    }

    // Space-pan owns the pointer (the recognizer usually yields already;
    // this covers programmatic drag starts).
    if (ref.read(flowOptionsProvider).keyboardOptions.isPanActivationHeld) {
      _ensureDragModeReset();
      return;
    }

    // Guard: if a previous drag wasn't cleaned up, reset first.
    if (_isDragActive) _resetDragState();

    final node = getNode(nodeId);
    final nodeOpts = ref.read(flowOptionsProvider).nodeOptions;
    if (node == null ||
        !(node.draggable ?? nodeOpts.draggable) ||
        !_controller.currentState.interactive) {
      _ensureDragModeReset();
      return;
    }

    final initialState = _controller.currentState;
    final isAlreadySelected = initialState.selectedNodes.contains(nodeId);

    // Prefer selecting on tap-down. Select here only if pan started without it.
    // React Flow `selectNodesOnDrag: false` drags unselected nodes without
    // selecting (and clears the existing selection first).
    FlowCanvasState stateAfterSelection = initialState;
    if (!nodeOpts.selectNodesOnDrag &&
        !isAlreadySelected &&
        !_isMultiSelectionActive()) {
      _selectionController.deselectAll();
      stateAfterSelection = _controller.currentState;
    } else if (isSelectable && !isAlreadySelected) {
      final multi = _isMultiSelectionActive();
      _selectionController.selectNode(nodeId, addToSelection: multi);
      stateAfterSelection = _controller.currentState;
    }

    // Whole selection moves only if this node was already selected (React Flow).
    final dragSet = isAlreadySelected
        ? Set<String>.from(stateAfterSelection.selectedNodes)
        : {nodeId};

    // React Flow `getDragItems` (`isParentSelected`): children whose parent is in the
    // drag set are excluded — they already move with the parent through
    // relative positions; dragging them directly would double-move them.
    dragSet.removeWhere(
      (id) => _hasAncestorInDragSet(stateAfterSelection, id, dragSet),
    );

    _nodesBeingDragged = dragSet;

    // Record start positions only for draggable nodes (per-node or global).
    _dragStartPositions = {};
    _pointerTravel = Offset.zero;
    final interactive = _controller.currentState.interactive;
    for (final id in _nodesBeingDragged) {
      final n = stateAfterSelection.nodes[id];
      if (n != null && (n.draggable ?? nodeOpts.draggable) && interactive) {
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
        _controller.currentState.copyWith(dragMode: DragMode.node),
      );
    }

    _isDragActive = true;

    // Cache the parent→children adjacency once; the tree shape is stable for
    // the whole gesture, so every frame reuses this instead of rescanning.
    _dragAdjacency = _nodeService.buildChildAdjacency(stateAfterSelection);

    // Edges of dragged nodes + descendants (absolute positions change when a
    // parent moves even if child stored coords do not).
    final activeEdges = <String>{};
    final affected = _nodeService.getDescendants(
      stateAfterSelection,
      _nodesBeingDragged,
      adjacency: _dragAdjacency,
    );
    for (final id in affected) {
      activeEdges.addAll(_spatialIndex.edgeIndex.getEdgesForNode(id));
    }
    _session.beginDrag(
      nodeIds: _nodesBeingDragged,
      startPositions: Map<String, Offset>.from(_dragStartPositions),
      edgeIds: activeEdges,
      affectedNodeIds: affected,
    );

    // Drag lifecycle around onNodeDrag (React Flow onNodeDragStart). Multi-node
    // drags additionally open the selection-drag lifecycle.
    _selectionDragActive = _nodesBeingDragged.length > 1;
    final startChanges = _dragSetChanges(_nodesBeingDragged, dragging: true);
    final cbs = ref.read(flowCanvasCallbacksProvider);
    cbs.onNodeDragStart?.call(startChanges);
    if (_selectionDragActive) {
      cbs.onSelectionDragStart?.call(startChanges);
    }

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
        _controller.currentState.copyWith(dragMode: DragMode.node),
      );
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
    final expandParentDefault =
        ref.read(flowOptionsProvider).nodeOptions.expandParent;

    // React Flow `calculateSnapOffset`: multi-drags share one snap offset so the
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
        // (React Flow skips the clamp while expandParent is set).
        if (n.extent == FlowNodeExtent.parent &&
            n.parentId != null &&
            !(n.expandParent || expandParentDefault)) {
          final parent = next.nodes[n.parentId!];
          if (parent != null) {
            finalPos = NodeLayout.clampToParent(
              finalPos,
              n.size,
              parent.size,
              childOrigin: NodeLayout.resolveOrigin(n, _nodeOrigin()),
            );
          }
        }
        if (finalPos != n.position) {
          next = _nodeService.updateNode(
            next,
            n.copyWith(position: finalPos),
            zIndexMode: _zMode(),
          );
        }
      }

      final size = liveSizes[id];
      if (size != null && size != n.size) {
        final current = next.nodes[id] ?? n;
        next = _nodeService.updateNode(
          next,
          current.copyWith(size: size),
          zIndexMode: _zMode(),
        );
      }
    }

    // expandParent final pass (React Flow `handleExpandParent` runs after the snapped
    // positions): grows parents and shifts siblings from committed state.
    next = _nodeService.applyExpandParent(
      next,
      draggedIds,
      defaultOrigin: _nodeOrigin(),
      expandParentDefault: expandParentDefault,
    );

    if (next != before) {
      _controller.updateStateOnly(next);
      // Re-sync spatial entries for dragged nodes, grown parents and shifted
      // siblings (absolute positions of children change when a parent moves).
      final affected =
          _nodeService.getDescendants(_controller.currentState, draggedIds,
              adjacency: _dragAdjacency)
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
        defaultOrigin: _nodeOrigin(),
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
          changes.add(
            NodePositionChange(id: id, position: n.position, dragging: false),
          );
        }
        if (liveSizes[id] != null && liveSizes[id] != n.size) {
          changes.add(NodeDimensionsChange(id: id, size: n.size));
        }
      }
      if (changes.isNotEmpty) {
        cbDragEnd.onNodesChange!(changes);
      }
    }

    // Drag-stop lifecycle (React Flow onNodeDragStop). Committed positions of
    // the dragged set; multi-drags close the selection-drag lifecycle too.
    final wasSelectionDrag = _selectionDragActive;
    _selectionDragActive = false;
    if (changedFromStart) {
      final stopChanges = _dragSetChanges(draggedIds, dragging: false);
      cbDragEnd.onNodeDragStop?.call(stopChanges);
      if (wasSelectionDrag) {
        cbDragEnd.onSelectionDragStop?.call(stopChanges);
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
    _pointerTravel = Offset.zero;
    _nodesBeingDragged.clear();
    _dragAdjacency = null;
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
      final oldEdge = state.edges[state.hoveredEdgeId];
      next = next.copyWith(hoveredEdgeId: '');
      if (oldEdge != null) {
        final leavePos = _controller.viewport.flowPositionFromGlobal(
          details.position,
        );
        if (leavePos != null) {
          ref
              .read(flowCanvasCallbacksProvider)
              .onEdgeMouseLeave
              ?.call(oldEdge, leavePos);
        }
      }
    }
    final nodeState = _nodeService.getNodeRuntimeState(next, nodeId);
    if (nodeState == null) {
      if (!identical(next, state)) _controller.updateStateOnly(next);
      return;
    }
    _controller.updateStateOnly(
      _nodeService.updateNodeRuntimeState(
        next,
        nodeId,
        nodeState.copyWith(hovered: true),
      ),
    );
    final node = _controller.currentState.nodes[nodeId];
    final flowPos = _controller.viewport.flowPositionFromGlobal(
      details.position,
    );
    if (node != null && flowPos != null) {
      ref
          .read(flowCanvasCallbacksProvider)
          .onNodeMouseEnter
          ?.call(node, flowPos);
    }
  }

  void onNodeMouseMove(String nodeId, PointerEvent details) {
    final node = _controller.currentState.nodes[nodeId];
    if (node == null) return;
    final flowPos = _controller.viewport.flowPositionFromGlobal(
      details.position,
    );
    if (flowPos == null) return;
    ref.read(flowCanvasCallbacksProvider).onNodeMouseMove?.call(node, flowPos);
  }

  void onNodeMouseLeave(String nodeId, PointerEvent details) {
    final nodeState = _nodeService.getNodeRuntimeState(
      _controller.currentState,
      nodeId,
    );
    if (nodeState == null) return;
    _controller.updateStateOnly(
      _nodeService.updateNodeRuntimeState(
        _controller.currentState,
        nodeId,
        nodeState.copyWith(hovered: false),
      ),
    );
    final node = _controller.currentState.nodes[nodeId];
    final flowPos = _controller.viewport.flowPositionFromGlobal(
      details.position,
    );
    if (node != null && flowPos != null) {
      ref
          .read(flowCanvasCallbacksProvider)
          .onNodeMouseLeave
          ?.call(node, flowPos);
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // PRIVATE — DRAG HELPERS
  // ─────────────────────────────────────────────────────────────────

  /// Single source-of-truth cleanup. Safe to call from any path.
  void _resetDragState() {
    _stopAutoPan();
    _controller.commitLiveViewportToState();
    _isDragActive = false;
    _selectionDragActive = false;
    _dragStartPositions = {};
    _pointerTravel = Offset.zero;
    _nodesBeingDragged.clear();
    _dragAdjacency = null;
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
    final cbs = ref.read(flowCanvasCallbacksProvider);
    if (cbs.onNodeDrag == null &&
        !(_selectionDragActive && cbs.onSelectionDrag != null)) {
      return;
    }
    final list = <NodeChange>[];
    final emitted = <String>{};
    final state = _controller.currentState;
    for (final id in ids) {
      final pos = _session.livePositions[id];
      if (pos != null) {
        list.add(NodePositionChange(id: id, position: pos, dragging: true));
        emitted.add(id);
      }
    }
    // expandParent effects (React Flow emits parent position + dimensions and shifted
    // sibling positions in the same change batch).
    for (final entry in _session.liveSizes.entries) {
      final node = state.nodes[entry.key];
      if (node == null) continue;
      final pos = _session.livePositions[entry.key];
      if (pos != null && pos != node.position && emitted.add(entry.key)) {
        list.add(
          NodePositionChange(id: entry.key, position: pos, dragging: true),
        );
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
        list.add(
          NodePositionChange(
            id: entry.key,
            position: entry.value,
            dragging: true,
          ),
        );
        emitted.add(entry.key);
      }
    }
    if (list.isNotEmpty) {
      cbs.onNodeDrag?.call(list);
      // Selection-drag mirrors the dragged set only (React Flow
      // onSelectionDrag), not expandParent side effects.
      final selectionHandler = _selectionDragActive
          ? ref.read(flowCanvasCallbacksProvider).onSelectionDrag
          : null;
      if (selectionHandler != null) {
        bool inDragSet(NodeChange c) => switch (c) {
          NodePositionChange(id: final id) => ids.contains(id),
          NodeDimensionsChange(id: final id) => ids.contains(id),
          _ => false,
        };
        final selectionList = list.where(inDragSet).toList();
        if (selectionList.isNotEmpty) selectionHandler(selectionList);
      }
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

    // Absolute mapping (React Flow `XYDrag.updateNodes`): the target is the
    // drag-start position plus total pointer travel — never last-frame-live
    // plus delta. Clamping that absolute target keeps the RF dead zone:
    // clamped-away travel is forgotten, so coming back pins until the
    // pointer leaves the clamped region and restores the origin exactly.
    _pointerTravel += canvasDelta;

    final state = _controller.currentState;
    final opts = ref.read(flowOptionsProvider);
    final vo = opts.viewportOptions;
    final nodeExtent = vo.nodeExtent;
    final defaultOrigin = opts.nodeOptions.nodeOrigin;
    final isMultiDrag = nodesToMove.length > 1;
    final snapToGrid = vo.snapToGrid;
    final snapGrid = vo.snapGrid;

    final next = <String, Offset>{};
    Offset? multiSnapOffset;
    for (final id in nodesToMove) {
      final node = state.nodes[id];
      if (node == null) continue;
      final start = _dragStartPositions[id];
      final current = _session.livePositions[id];
      if (start == null && current == null) continue;
      // React Flow `XYDrag.updateNodes`: snap every frame while dragging — single
      // nodes snap to the grid, multi-drags share one offset computed from
      // the first drag item so the selection moves as a unit.
      var raw = start != null ? start + _pointerTravel : current! + canvasDelta;
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
        defaultOrigin: defaultOrigin,
        expandParentDefault: opts.nodeOptions.expandParent,
      );
    }
    _session.setLivePositions(next);

    // React Flow `expandParent` + `handleExpandParent` (live): while a child with
    // expandParent is dragged past its parent's edge, grow the parent
    // position/size and shift sibling children so their absolute positions
    // stay put. Sizes stay live until drag end (parent grows on screen).
    for (final id in nodesToMove) {
      final node = state.nodes[id];
      if (node == null ||
          !(node.expandParent || opts.nodeOptions.expandParent) ||
          node.parentId == null) {
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
        childOrigin: NodeLayout.resolveOrigin(node, defaultOrigin),
      );
      if (fit == null) continue;

      _session.setLivePositions({
        parent.id: fit.parentPosition,
        id: fit.childPosition,
      });
      _session.setLiveSize(parent.id, fit.parentSize);

      final originDelta = fit.parentPosition - parentPos;
      for (final sibling in state.nodes.values) {
        if (sibling.parentId != parent.id || nodesToMove.contains(sibling.id)) {
          continue;
        }
        _session.setLivePositions({sibling.id: sibling.position - originDelta});
      }
    }

    final affected =
        _nodeService.getDescendants(state, nodesToMove,
            adjacency: _dragAdjacency)
          ..addAll(_session.livePositions.keys)
          ..addAll(_session.liveSizes.keys);
    _edgeGeometryService.updateEdgesForNodes(
      state,
      affected,
      _spatialIndex.edgeIndex,
      livePositions: _session.livePositions,
      defaultOrigin: defaultOrigin,
    );
    _emitNodeDragLivePositions(nodesToMove);
  }

  /// Clamps one node's next position (React Flow `calculateNodePosition`).
  ///
  /// - `extent: 'parent'` clamps in parent-relative space; [FlowNode.expandParent]
  ///   bypasses clamping entirely (React Flow) — `handleExpandParent` grows the parent.
  /// - [CoordinateExtent] (global `nodeExtent`) clamps in **absolute** flow
  ///   space, including for children; multi-drags use React Flow's per-node adjusted
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
    required Offset defaultOrigin,
    bool expandParentDefault = false,
  }) {
    final origin = NodeLayout.resolveOrigin(node, defaultOrigin);
    if (node.extent == FlowNodeExtent.parent) {
      final parent = node.parentId != null ? state.nodes[node.parentId!] : null;
      if (parent == null || node.expandParent || expandParentDefault) {
        return raw;
      }
      return NodeLayout.clampToParent(
        raw,
        node.size,
        parent.size,
        childOrigin: origin,
      );
    }

    if (nodeExtent == null || nodeExtent.isInfinite) return raw;

    final parentAbs = node.parentId != null
        ? NodeLayout.absolutePosition(
            node.parentId!,
            state.nodes,
            livePositions: _session.livePositions,
          )
        : Offset.zero;

    // Clamp in visual-topLeft space: the anchor→visual shift is constant
    // per node, so this is exactly the old math shifted (identical when the
    // origin is top-left). Keeps the RF dead zone with centered origins.
    final shift = Offset(
      origin.dx * node.size.width,
      origin.dy * node.size.height,
    );
    final absVisual = raw + parentAbs - shift;

    var extent = nodeExtent;
    if (isMultiDrag) {
      final box = _dragSetBounds(state, nodesToMove, defaultOrigin);
      if (box != null) {
        final currentVisual = parentAbs + (raw - canvasDelta) - shift;
        extent = CoordinateExtent(
          minX: currentVisual.dx - box.left + nodeExtent.minX,
          minY: currentVisual.dy - box.top + nodeExtent.minY,
          maxX:
              currentVisual.dx + node.size.width - box.right + nodeExtent.maxX,
          maxY:
              currentVisual.dy +
              node.size.height -
              box.bottom +
              nodeExtent.maxY,
        );
      }
    }
    final clampedVisual = _clampLivePosition(absVisual, node.size, extent);
    return clampedVisual + shift - parentAbs;
  }

  /// Union of the drag set's absolute *visual* rects (live positions).
  Rect? _dragSetBounds(
    FlowCanvasState state,
    Set<String> ids,
    Offset defaultOrigin,
  ) {
    Rect? union;
    for (final id in ids) {
      final node = state.nodes[id];
      if (node == null) continue;
      final rect = NodeLayout.absoluteRect(
        node,
        state.nodes,
        livePositions: _session.livePositions,
        defaultOrigin: defaultOrigin,
      );
      union = union == null ? rect : union.expandToInclude(rect);
    }
    return union;
  }

  /// React Flow `isParentSelected`: true when any ancestor of [id] is in [dragSet].
  bool _hasAncestorInDragSet(
    FlowCanvasState state,
    String id,
    Set<String> dragSet,
  ) {
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

    // React Flow `calcAutoPanVelocity`: ramps from ~speed/margin at the margin
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
