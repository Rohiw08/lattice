import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';

class KeyboardActionService {
  final NodeService nodeService;
  final SelectionService selectionService;
  final ClipboardService clipboardService;
  final EdgeService edgeService;
  final ViewportService viewportService;

  KeyboardActionService({
    required this.nodeService,
    required this.selectionService,
    required this.clipboardService,
    required this.edgeService,
    required this.viewportService,
  });

  /// Processes a keyboard action and returns the new state.
  /// Note: This service no longer interacts with HistoryService directly.
  FlowCanvasState handleAction(
    FlowCanvasState state,
    KeyboardAction action, {
    Offset arrowMoveDelta = const Offset(10, 10),
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
    required double zoomStep,
    Offset defaultOrigin = Offset.zero,
    bool nodesDeletable = true,
    bool edgesDeletable = true,
    bool nodesDraggable = true,
    bool expandParentDefault = false,
  }) {
    switch (action) {
      // --- MUTATION ACTIONS (will be wrapped in history by the controller) ---
      case KeyboardAction.selectAll:
        return selectionService.selectAll(state);
      case KeyboardAction.deselectAll:
        return selectionService.deselectAll(state);
      case KeyboardAction.deleteSelection:
        final selectedNodeIds = state.selectedNodes.toList();
        // Explicitly selected edges (null deletable counts as allowed,
        // mirroring NodeService). Connected edges of removed nodes go away
        // unconditionally so no edge dangles.
        final selectedEdgeIds = state.selectedEdges
            .where((id) =>
                state.edges[id]?.deletable ?? edgesDeletable)
            .toList();
        if (selectedNodeIds.isEmpty && selectedEdgeIds.isEmpty) return state;
        final connectedEdgeIds =
            edgeService.getEdgesFromNodes(state, selectedNodeIds);
        final stateAfterEdges = edgeService.removeEdges(
            state, [...connectedEdgeIds, ...selectedEdgeIds],
            edgesDeletable: edgesDeletable);
        final newState = nodeService.removeNodes(
            stateAfterEdges, selectedNodeIds,
            nodesDeletable: nodesDeletable);
        return newState;
      case KeyboardAction.moveUp:
        // Flow space is +y-down, so "up" on screen is a NEGATIVE dy.
        return nodeService.moveSelectedNodes(
            state, Offset(0, -arrowMoveDelta.dy),
            defaultOrigin: defaultOrigin,
            nodesDraggable: nodesDraggable,
            expandParentDefault: expandParentDefault);
      case KeyboardAction.moveDown:
        return nodeService.moveSelectedNodes(
            state, Offset(0, arrowMoveDelta.dy),
            defaultOrigin: defaultOrigin,
            nodesDraggable: nodesDraggable,
            expandParentDefault: expandParentDefault);
      case KeyboardAction.moveLeft:
        return nodeService.moveSelectedNodes(
            state, Offset(-arrowMoveDelta.dx, 0),
            defaultOrigin: defaultOrigin,
            nodesDraggable: nodesDraggable,
            expandParentDefault: expandParentDefault);
      case KeyboardAction.moveRight:
        return nodeService.moveSelectedNodes(
            state, Offset(arrowMoveDelta.dx, 0),
            defaultOrigin: defaultOrigin,
            nodesDraggable: nodesDraggable,
            expandParentDefault: expandParentDefault);
      case KeyboardAction.zoomIn:
      case KeyboardAction.zoomOut:
        {
          final size = state.viewportSize;
          final focal = (size != null && size.width > 0 && size.height > 0)
              ? Offset(size.width / 2, size.height / 2)
              : Offset.zero;
          final factor = action == KeyboardAction.zoomIn
              ? (1.0 + zoomStep)
              : (1.0 - zoomStep);
          return viewportService.zoom(
            state,
            zoomFactor: factor,
            focalViewportPoint: focal,
            minZoom: minZoom,
            maxZoom: maxZoom,
            translateExtent: translateExtent,
          );
        }
      case KeyboardAction.duplicateSelection:
        final payload = clipboardService.copy(state);
        if (payload.isEmpty) return state;
        return clipboardService.paste(state, payload,
            positionOffset: const Offset(30, 30),
            nodeService: nodeService,
            edgeService: edgeService);
      case KeyboardAction.resetZoom:
        final next =
            state.copyWith(viewport: state.viewport.copyWith(zoom: 1.0));
        return viewportService.applyTranslateExtent(next, translateExtent);

      // --- HISTORY ACTIONS (handled directly by the controller) ---
      case KeyboardAction.undo:
      case KeyboardAction.redo:
        // These actions are now handled in the controller, so we just return the current state.
        return state;
    }
  }
}
