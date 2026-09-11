import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionController {
  SelectionController({
    required CanvasStateAccessor controller,
    required SelectionService selectionService,
    required SpatialIndexService spatialIndex,
    required Ref ref,
    required GlobalKey viewportKey,
    required TransformationController transformationController,
  })  : _controller = controller,
        _selectionService = selectionService,
        _spatialIndex = spatialIndex,
        _ref = ref,
        _viewportKey = viewportKey,
        _transformationController = transformationController;

  final CanvasStateAccessor _controller;
  final SelectionService _selectionService;
  final SpatialIndexService _spatialIndex;
  final Ref _ref;
  final GlobalKey _viewportKey;
  final TransformationController _transformationController;

  Offset? _selectionDragOrigin;
  int? _activePointer;
  bool _globalRouteActive = false;

  /// Whether box-select should start (Lattice: selectionKeyPressed || selectionOnDrag).
  bool get shouldStartBoxSelection {
    if (_controller.currentState.isPanZoomLocked) return false;
    final options = _ref.read(flowOptionsProvider);
    if (options.viewportOptions.selectionOnDrag) return true;
    return options.keyboardOptions.isSelectionKeyActive;
  }

  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (_controller.currentState.isPanZoomLocked) return;
    _controller.updateStateOnly(
      _selectionService.toggleNodeSelection(_controller.currentState, nodeId,
          addToSelection: addToSelection),
    );
  }

  void selectEdge(String edgeId, {bool addToSelection = false}) {
    if (_controller.currentState.isPanZoomLocked) return;
    _controller.updateStateOnly(_selectionService.toggleEdgeSelection(
        _controller.currentState, edgeId,
        addToSelection: addToSelection));
  }

  void deselectAll() {
    if (_controller.currentState.isPanZoomLocked) return;
    _controller.updateStateOnly(
        _selectionService.deselectAll(_controller.currentState));
  }

  void selectAll() {
    if (_controller.currentState.isPanZoomLocked) return;
    _controller
        .updateStateOnly(_selectionService.selectAll(_controller.currentState));
  }

  /// Starts a marquee selection at [position] (flow / scene coords).
  ///
  /// Pass [pointer] to track move/up globally (across nodes/edges).
  void startSelection(Offset position, {int? pointer}) {
    if (_controller.currentState.isPanZoomLocked) return;
    _removeGlobalPointerRoute();
    _selectionDragOrigin = position;
    final stateAfterStart =
        _selectionService.startBoxSelection(_controller.currentState, position);
    _controller.updateStateOnly(
        stateAfterStart.copyWith(dragMode: DragMode.selection));

    if (pointer != null) {
      _activePointer = pointer;
      GestureBinding.instance.pointerRouter
          .addRoute(pointer, _onGlobalPointerEvent);
      _globalRouteActive = true;
    }
  }

  void updateSelection(Offset position, {SelectionMode? selectionMode}) {
    if (_controller.currentState.dragMode != DragMode.selection) return;
    final origin = _selectionDragOrigin;
    if (origin == null) return;

    final mode = selectionMode ??
        _ref.read(flowOptionsProvider).viewportOptions.selectionMode;

    final next = _selectionService.updateBoxSelection(
      _controller.currentState,
      origin,
      position,
      _spatialIndex.nodeIndex,
      _spatialIndex.edgeIndex,
      selectionMode: mode,
    );
    _controller.updateStateOnly(next);
  }

  void endSelection() {
    _removeGlobalPointerRoute();
    _selectionDragOrigin = null;
    _activePointer = null;

    if (_controller.currentState.dragMode != DragMode.selection) return;

    // Keep selectedNodes / selectedEdges / runtime flags from last update.
    _controller.mutate((s) => s.copyWith(
          selectionRect: Rect.zero,
          dragMode: DragMode.none,
        ));
  }

  void cancelSelection() {
    _removeGlobalPointerRoute();
    _selectionDragOrigin = null;
    _activePointer = null;
    if (_controller.currentState.dragMode != DragMode.selection) return;
    _controller.updateStateOnly(
      _selectionService.deselectAll(_controller.currentState).copyWith(
            selectionRect: Rect.zero,
            dragMode: DragMode.none,
          ),
    );
  }

  void _onGlobalPointerEvent(PointerEvent event) {
    if (_activePointer != null && event.pointer != _activePointer) return;

    if (event is PointerMoveEvent) {
      updateSelection(_globalToScene(event.position));
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      endSelection();
    }
  }

  void _removeGlobalPointerRoute() {
    final pointer = _activePointer;
    if (!_globalRouteActive || pointer == null) return;
    GestureBinding.instance.pointerRouter
        .removeRoute(pointer, _onGlobalPointerEvent);
    _globalRouteActive = false;
  }

  Offset _globalToScene(Offset global) {
    final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return global;
    final local = box.globalToLocal(global);
    return _transformationController.toScene(local);
  }
}
