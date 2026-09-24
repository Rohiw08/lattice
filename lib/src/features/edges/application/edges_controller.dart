import 'package:lattice/src/features/selection/application/selection_controller.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/dataflow/domain/node_connection.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EdgesController {
  final FlowCanvasInternalController _controller;
  final EdgeService _edgeService;
  final EdgeGeometryService _edgeGeometryService;
  final SelectionController _selectionController;
  final SpatialIndexService _spatialIndex;
  final Ref _ref;

  EdgesController({
    required FlowCanvasInternalController controller,
    required EdgeService edgeService,
    required EdgeGeometryService edgeGeometryService,
    required SelectionController selectionController,
    required SpatialIndexService spatialIndex,
    required Ref ref,
  })  : _controller = controller,
        _edgeService = edgeService,
        _edgeGeometryService = edgeGeometryService,
        _selectionController = selectionController,
        _spatialIndex = spatialIndex,
        _ref = ref;

  List<String> getEdgesFromNodes(Iterable<String> nodeIds) {
    return _edgeService.getEdgesFromNodes(_controller.currentState, nodeIds);
  }

  /// Returns the edge with [edgeId], or null when missing.
  FlowEdge? getEdge(String edgeId) {
    return _controller.currentState.edges[edgeId];
  }

  /// Returns the edges touching any of [nodeIds] as objects.
  ///
  /// Index-backed (O(degree), not O(E)) — prefer over filtering
  /// `flowEdgesProvider` for adjacency lookups on large graphs.
  List<FlowEdge> getConnectedEdges(Iterable<String> nodeIds) {
    final state = _controller.currentState;
    final ids = <String>{};
    for (final nodeId in nodeIds) {
      ids.addAll(_spatialIndex.edgeIndex.getEdgesForNode(nodeId));
    }
    final out = <FlowEdge>[];
    for (final id in ids) {
      final edge = state.edges[id];
      if (edge != null) out.add(edge);
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// Returns edges attached to a specific node handle.
  ///
  /// Lattice `useHandleConnections` / `getHandleConnections` counterpart.
  List<FlowEdge> getHandleConnections(String nodeId, String handleId) {
    final state = _controller.currentState;
    final out = <FlowEdge>[];
    for (final id
        in _spatialIndex.edgeIndex.getEdgesForHandle(nodeId, handleId)) {
      final edge = state.edges[id];
      if (edge != null) out.add(edge);
    }
    out.sort((a, b) => a.id.compareTo(b.id));
    return out;
  }

  /// Ids of nodes directly connected to [nodeId] (either direction).
  Set<String> getConnectedNodeIds(String nodeId) {
    return _spatialIndex.edgeIndex.getConnectedNodes(nodeId);
  }

  /// Whether [nodeId] has any connected edge.
  bool isNodeConnected(String nodeId) {
    return _spatialIndex.edgeIndex.isNodeConnected(nodeId);
  }

  /// Whether a specific handle has at least one connected edge.
  bool isHandleConnected(String nodeId, String handleId) {
    return _spatialIndex.edgeIndex.isHandleConnected(nodeId, handleId);
  }

  /// Returns the id of the topmost edge under a flow-space [position].
  ///
  /// Programmatic picking for eraser tools, lasso-of-edges, and edge
  /// context menus — anything that needs a hit without a pointer gesture.
  /// Uses the same cached path samples + `interactionWidth` tolerance as tap
  /// selection, so results match what a tap would select. Returns null when
  /// no edge is hit or geometry isn't committed yet.
  String? hitTestEdgeAt(Offset position) {
    final state = _controller.currentState;
    return _edgeGeometryService.hitTestEdgeAt(
      position,
      state,
      state.viewport.zoom,
    );
  }

  /// Warns through `onError` when [edge] references a missing endpoint node
  /// (the edge is then skipped, like RF's dangling-edge warning).
  void _warnDanglingEdge(FlowEdge edge) {
    final nodes = _controller.currentState.nodes;
    if (nodes.containsKey(edge.sourceNodeId) &&
        nodes.containsKey(edge.targetNodeId)) {
      return;
    }
    _ref.read(flowCanvasCallbacksProvider).onError?.call(FlowCanvasError(
          'edge-missing-node',
          'Edge "${edge.id}" references a missing node '
          '(${edge.sourceNodeId} → ${edge.targetNodeId}) and was skipped.',
        ));
  }

  void addEdge(FlowEdge edge) {
    _warnDanglingEdge(edge);
    _controller.mutate((s) => _edgeService.addEdge(s, edge));
    _edgeGeometryService.updateEdge(_controller.currentState, edge.id);
    final c = _ref.read(flowCanvasCallbacksProvider);
    final e = _controller.currentState.edges[edge.id];
    if (e != null) {
      c.onEdgesChange?.call([EdgeAddChange(edge: e)]);
    }
  }

  void addEdges(List<FlowEdge> edges) {
    if (edges.isEmpty) return;
    final skipped = <String>[];
    final nodes = _controller.currentState.nodes;
    for (final edge in edges) {
      if (!nodes.containsKey(edge.sourceNodeId) ||
          !nodes.containsKey(edge.targetNodeId)) {
        skipped.add(edge.id);
      }
    }
    if (skipped.isNotEmpty) {
      _ref.read(flowCanvasCallbacksProvider).onError?.call(FlowCanvasError(
            'edge-missing-node',
            'Skipped ${skipped.length} edge(s) with missing endpoint '
            'node(s): ${skipped.join(', ')}.',
          ));
    }
    _controller.mutate((s) => _edgeService.addEdges(s, edges));
    for (final edge in edges) {
      _edgeGeometryService.updateEdge(_controller.currentState, edge.id);
    }
    final c = _ref.read(flowCanvasCallbacksProvider);
    if (c.onEdgesChange == null) return;
    final out = <EdgeChange>[];
    for (final edge in edges) {
      final e = _controller.currentState.edges[edge.id];
      if (e != null) out.add(EdgeAddChange(edge: e));
    }
    if (out.isNotEmpty) c.onEdgesChange!(out);
  }

  void removeSelectedEdges() {
    final oldState = _controller.currentState;
    final edgesToRemove = Set<String>.from(oldState.selectedEdges);
    if (edgesToRemove.isEmpty) return;

    final c = _ref.read(flowCanvasCallbacksProvider);
    _controller
        .mutate((s) => _edgeService.removeEdges(s, edgesToRemove.toList()));
    _removeFromCaches(edgesToRemove, oldState.edges);
    c.onEdgesChange
        ?.call(edgesToRemove.map((id) => EdgeRemoveChange(id: id)).toList());
  }

  /// Removes one edge by id. No-op when missing.
  void removeEdge(String edgeId) => removeEdges([edgeId]);

  /// Removes edges by id in a single undo step.
  ///
  /// Selection entries for removed edges are cleaned in the same commit,
  /// and the spatial index + geometry caches are synced so handle/node
  /// queries never observe ghosts.
  void removeEdges(Iterable<String> edgeIds) {
    final oldState = _controller.currentState;
    final removed = <String>[
      for (final id in edgeIds)
        if (oldState.edges.containsKey(id)) id,
    ];
    if (removed.isEmpty) return;

    final removedSet = removed.toSet();
    _controller.mutate((s) {
      var next = _edgeService.removeEdges(s, removed);
      final stale = next.selectedEdges.intersection(removedSet);
      if (stale.isNotEmpty) {
        next = next.copyWith(
          selectedEdges: Set<String>.from(next.selectedEdges)
            ..removeAll(stale),
        );
      }
      return next;
    });
    _removeFromCaches(removedSet, oldState.edges);
    _ref
        .read(flowCanvasCallbacksProvider)
        .onEdgesChange
        ?.call(removed.map((id) => EdgeRemoveChange(id: id)).toList());
  }

  /// Drops stale index + geometry entries for [edgeIds] (O(degree)).
  ///
  /// [oldEdges] must be the pre-removal edge map — removed edges are
  /// already gone from current state by the time this runs.
  void _removeFromCaches(
      Set<String> edgeIds, Map<String, FlowEdge> oldEdges) {
    for (final id in edgeIds) {
      final edge = oldEdges[id];
      if (edge != null) _spatialIndex.edgeIndex.removeEdge(id, edge);
    }
    _edgeGeometryService.removeEdges(edgeIds);
    _controller.bumpSpatialVersion();
  }

  /// Updates the `data` payload of [edgeId] with [updater].
  void updateEdgeDataWith(String edgeId, EdgeDataUpdater updater) {
    final oldEdge = _controller.currentState.edges[edgeId];
    if (oldEdge == null) return;

    _controller.mutate((s) => _edgeService.updateEdgeData(s, edgeId, updater));
    _edgeGeometryService.updateEdge(_controller.currentState, edgeId);
  }

  /// Updates a whole edge (React Flow `updateEdge(id, edgeUpdate)`).
  ///
  /// [update] receives the current edge and returns the replacement
  /// (merge via `copyWith`, or build a fresh `FlowEdge` to replace —
  /// there is no partial-object form in Dart, so RF's `{ replace }`
  /// option collapses into what the updater returns). Missing ids are a
  /// safe no-op. Undoable; geometry caches refresh.
  void updateEdge(String edgeId, FlowEdge Function(FlowEdge edge) update) {
    final oldEdge = _controller.currentState.edges[edgeId];
    if (oldEdge == null) return;
    final replacement = update(oldEdge).copyWith(id: edgeId);
    _controller.mutate((s) {
      final nextEdges = Map<String, FlowEdge>.from(s.edges)
        ..[edgeId] = replacement;
      return s.copyWith(edges: nextEdges);
    });
    _edgeGeometryService.updateEdge(_controller.currentState, edgeId);
    _controller.bumpSpatialVersion();
  }

  /// Replaces the `data` map of [edgeId] (React Flow `updateEdgeData`).
  void setEdgeData(String edgeId, Map<String, dynamic> data) {
    updateEdgeDataWith(edgeId, (_) => Map<String, dynamic>.from(data));
  }

  /// Merges [patch] into the `data` map of [edgeId].
  ///
  /// Mirrors React Flow's default merge (`{...old, ...patch}`); pass
  /// `replace: true` for its `{ replace: true }` option.
  void patchEdgeData(
    String edgeId,
    Map<String, dynamic> patch, {
    bool replace = false,
  }) {
    updateEdgeDataWith(edgeId, (old) {
      if (replace) return Map<String, dynamic>.from(patch);
      return {...old, ...patch};
    });
  }

  /// Reactive-hook counterpart, imperatively.
  ///
  /// Returns connections on [nodeId], optionally narrowed by [handleType]
  /// and [handleId] — the `getNodeConnections` side of React Flow's
  /// `useNodeConnections`. Sorted by edge id for deterministic output.
  List<FlowNodeConnection> getNodeConnections(
    String nodeId, {
    HandleType? handleType,
    String? handleId,
  }) {
    final state = _controller.currentState;
    final out = <FlowNodeConnection>[];
    final edgeIds = handleId == null
        ? _spatialIndex.edgeIndex.getEdgesForNode(nodeId)
        : _spatialIndex.edgeIndex.getEdgesForHandle(nodeId, handleId);
    for (final id in edgeIds) {
      final edge = state.edges[id];
      if (edge == null) continue;
      final isSourceEnd = edge.sourceNodeId == nodeId &&
          (handleId == null || edge.sourceHandleId == handleId);
      final isTargetEnd = edge.targetNodeId == nodeId &&
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

  /// Ids feeding into [nodeId] (it is the target).
  ///
  /// Counterpart of React Flow's `getIncomers`.
  List<String> getIncomers(String nodeId, {String? handleId}) {
    final state = _controller.currentState;
    final out = <String>[];
    for (final edge in state.edges.values) {
      if (edge.targetNodeId == nodeId &&
          (handleId == null || edge.targetHandleId == handleId)) {
        out.add(edge.sourceNodeId);
      }
    }
    return out..sort();
  }

  /// Ids [nodeId] feeds into (it is the source).
  ///
  /// Counterpart of React Flow's `getOutgoers`.
  List<String> getOutgoers(String nodeId, {String? handleId}) {
    final state = _controller.currentState;
    final out = <String>[];
    for (final edge in state.edges.values) {
      if (edge.sourceNodeId == nodeId &&
          (handleId == null || edge.sourceHandleId == handleId)) {
        out.add(edge.targetNodeId);
      }
    }
    return out..sort();
  }

  void reconnectEdge({
    required String edgeId,
    String? newSourceNodeId,
    String? newSourceHandleId,
    String? newTargetNodeId,
    String? newTargetHandleId,
  }) {
    if (!_controller.currentState.edges.containsKey(edgeId)) {
      _ref.read(flowCanvasCallbacksProvider).onError?.call(FlowCanvasError(
            'reconnect-missing-edge',
            'Cannot reconnect missing edge "$edgeId" (already removed?).',
          ));
      return;
    }
    _controller.mutate((s) => _edgeService.reconnectEdge(s, edgeId,
        newSourceNodeId: newSourceNodeId,
        newSourceHandleId: newSourceHandleId,
        newTargetNodeId: newTargetNodeId,
        newTargetHandleId: newTargetHandleId));
  }

  void onEdgePointerHover(PointerEvent event, Offset localPosition) {
    final state = _controller.currentState;
    final hit = _edgeGeometryService.hitTestEdgeAt(
        localPosition, state, state.viewport.zoom);

    final currentHoveredId = state.hoveredEdgeId;
    final hitId = hit ?? "";
    final cbs = _ref.read(flowCanvasCallbacksProvider);

    if (hitId != currentHoveredId) {
      if (currentHoveredId.isNotEmpty) {
        final old = state.edges[currentHoveredId];
        if (old != null) {
          cbs.onEdgeMouseLeave?.call(old, localPosition);
        }
      }
      _controller.updateStateOnly(state.copyWith(hoveredEdgeId: hitId));
      if (hitId.isNotEmpty) {
        final next = state.edges[hitId];
        if (next != null) {
          cbs.onEdgeMouseEnter?.call(next, localPosition);
        }
      }
      return;
    }
    if (hitId.isNotEmpty) {
      final current = state.edges[hitId];
      if (current != null) {
        cbs.onEdgeMouseMove?.call(current, localPosition);
      }
    }
  }

  String? _lastEdgeTapId;
  DateTime? _lastEdgeTapTime;

  /// Clears a stale edge hover (pointer left all edge strokes, e.g. over
  /// empty canvas). Mirrors the leave half of [onEdgePointerHover]; no-op
  /// when nothing is hovered.
  void clearEdgeHover(Offset flowPosition) {
    final state = _controller.currentState;
    if (state.hoveredEdgeId.isEmpty) return;
    final old = state.edges[state.hoveredEdgeId];
    _controller.updateStateOnly(state.copyWith(hoveredEdgeId: ''));
    if (old != null) {
      _ref.read(flowCanvasCallbacksProvider).onEdgeMouseLeave?.call(
            old,
            flowPosition,
          );
    }
  }

  void onEdgeTapDown(
    TapDownDetails details,
    Offset localPosition, {
    int? pointer,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    // Space-pan owns the pointer: taps select/deselect nothing.
    if (_ref
        .read(flowOptionsProvider)
        .keyboardOptions
        .isPanActivationHeld) {
      return;
    }
    final state = _controller.currentState;

    if (_selectionController.shouldStartBoxSelection) {
      _selectionController.startSelection(localPosition, pointer: pointer);
      return;
    }

    final hit = _edgeGeometryService.hitTestEdgeAt(
        localPosition, state, state.viewport.zoom);

    _controller.updateStateOnly(state.copyWith(lastClickedEdgeId: hit ?? ""));

    if (hit != null) {
      final edgeOpts = _ref.read(flowOptionsProvider).edgeOptions;
      if ((state.edges[hit]?.selectable ?? edgeOpts.selectable) &&
          state.interactive) {
        final multi = _ref
            .read(flowOptionsProvider)
            .keyboardOptions
            .isMultiSelectionActive;
        _selectionController.selectEdge(hit, addToSelection: multi);
      }
      final edge = _controller.currentState.edges[hit];
      if (edge != null) {
        final cbs = _ref.read(flowCanvasCallbacksProvider);
        cbs.onEdgeClick?.call(edge, localPosition);
        final now = DateTime.now();
        final lastId = _lastEdgeTapId;
        final lastTime = _lastEdgeTapTime;
        if (lastId == hit &&
            lastTime != null &&
            now.difference(lastTime) <= kDoubleTapTimeout) {
          cbs.onEdgeDoubleClick?.call(edge, localPosition);
          _lastEdgeTapId = null;
          _lastEdgeTapTime = null;
        } else {
          _lastEdgeTapId = hit;
          _lastEdgeTapTime = now;
        }
      }
    } else {
      _selectionController.deselectAll();
    }
  }

  void onEdgeDoubleTap() {}

  void onEdgeLongPressStart(
      LongPressStartDetails details, Offset localPosition) {}
}
