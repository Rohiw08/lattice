import 'package:lattice/src/features/selection/application/selection_controller.dart';
import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EdgesController {
  final CanvasStateAccessor _controller;
  final EdgeService _edgeService;
  final EdgeGeometryService _edgeGeometryService;
  final SelectionController _selectionController;
  final Ref _ref;

  EdgesController({
    required CanvasStateAccessor controller,
    required EdgeService edgeService,
    required EdgeGeometryService edgeGeometryService,
    required SelectionController selectionController,
    required Ref ref,
  })  : _controller = controller,
        _edgeService = edgeService,
        _edgeGeometryService = edgeGeometryService,
        _selectionController = selectionController,
        _ref = ref;

  List<String> getEdgesFromNodes(Iterable<String> nodeIds) {
    return _edgeService.getEdgesFromNodes(_controller.currentState, nodeIds);
  }

  void addEdge(FlowEdge edge) {
    _controller.mutate((s) => _edgeService.addEdge(s, edge));
    _edgeGeometryService.updateEdge(_controller.currentState, edge.id);
    final c = _ref.read(flowCanvasCallbacksProvider);
    final e = _controller.currentState.edges[edge.id];
    if (e != null) {
      c.onEdgesChange?.call([EdgeAddChange(edge: e)]);
    }
  }

  void addEdges(List<FlowEdge> edges) {
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
    final edgesToRemove =
        Set<String>.from(_controller.currentState.selectedEdges);
    if (edgesToRemove.isEmpty) return;

    final c = _ref.read(flowCanvasCallbacksProvider);
    _controller
        .mutate((s) => _edgeService.removeEdges(s, edgesToRemove.toList()));
    _edgeGeometryService.removeEdges(edgesToRemove);
    c.onEdgesChange
        ?.call(edgesToRemove.map((id) => EdgeRemoveChange(id: id)).toList());
  }

  void updateEdge(String edgeId, EdgeDataUpdater updater) {
    final oldEdge = _controller.currentState.edges[edgeId];
    if (oldEdge == null) return;

    _controller.mutate((s) => _edgeService.updateEdgeData(s, edgeId, updater));
    _edgeGeometryService.updateEdge(_controller.currentState, edgeId);
  }

  void reconnectEdge({
    required String edgeId,
    String? newSourceNodeId,
    String? newSourceHandleId,
    String? newTargetNodeId,
    String? newTargetHandleId,
  }) {
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

    if (hitId != currentHoveredId) {
      _controller.updateStateOnly(state.copyWith(hoveredEdgeId: hitId));
    }
  }

  void onEdgeTapDown(
    TapDownDetails details,
    Offset localPosition, {
    int? pointer,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    final state = _controller.currentState;

    if (_selectionController.shouldStartBoxSelection) {
      _selectionController.startSelection(localPosition, pointer: pointer);
      return;
    }

    final hit = _edgeGeometryService.hitTestEdgeAt(
        localPosition, state, state.viewport.zoom);

    _controller.updateStateOnly(state.copyWith(lastClickedEdgeId: hit ?? ""));

    if (hit != null) {
      if (state.edges[hit]?.selectable ?? true) {
        final multi = _ref
            .read(flowOptionsProvider)
            .keyboardOptions
            .isMultiSelectionActive;
        _selectionController.selectEdge(hit, addToSelection: multi);
      }
    } else {
      _selectionController.deselectAll();
    }
  }

  void onEdgeDoubleTap() {}

  void onEdgeLongPressStart(
      LongPressStartDetails details, Offset localPosition) {}
}
