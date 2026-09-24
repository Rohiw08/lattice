import 'dart:async';

import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectionController {
  SelectionController({
    required FlowCanvasInternalController controller,
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

  final FlowCanvasInternalController _controller;
  final SelectionService _selectionService;
  final SpatialIndexService _spatialIndex;
  final Ref _ref;
  final GlobalKey _viewportKey;
  final TransformationController _transformationController;

  Offset? _selectionDragOrigin;
  int? _activePointer;
  bool _globalRouteActive = false;

  Timer? _autoPanTimer;
  Offset _autoPanVelocity = Offset.zero;
  Offset? _lastGlobalPosition;

  // Marquee move updates are coalesced to one per frame. Raw pointer moves can
  // arrive several times per frame, and each `updateSelection` runs an O(N)
  // spatial query and clones both runtime maps. We keep only the latest scene
  // position and flush it once on the next frame (mirrors InteractionSession's
  // `_scheduleNotify`). Auto-pan stays on its own 16ms timer, already
  // frame-bound.
  Offset? _pendingScenePosition;
  bool _moveScheduled = false;

  /// Whether box-select should start (Lattice: selectionKeyPressed || selectionOnDrag).
  ///
  /// Never while the pan-activation key is held — space+drag pans instead.
  /// Never while non-interactive (`setInteractive(false)`).
  bool get shouldStartBoxSelection {
    if (_controller.currentState.isPanZoomLocked) return false;
    if (!_controller.currentState.interactive) return false;
    final options = _ref.read(flowOptionsProvider);
    if (options.keyboardOptions.isPanActivationHeld) return false;
    if (options.viewportOptions.selectionOnDrag) return true;
    return options.keyboardOptions.isSelectionKeyActive;
  }

  void selectNode(String nodeId, {bool addToSelection = false}) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    if (!_ref.read(flowOptionsProvider).elementsSelectable) return;
    _controller.updateStateOnly(
      _selectionService.toggleNodeSelection(_controller.currentState, nodeId,
          addToSelection: addToSelection),
    );
  }

  void selectEdge(String edgeId, {bool addToSelection = false}) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    if (!_ref.read(flowOptionsProvider).elementsSelectable) return;
    _controller.updateStateOnly(_selectionService.toggleEdgeSelection(
        _controller.currentState, edgeId,
        addToSelection: addToSelection));
  }

  void deselectAll() {
    if (_controller.currentState.isPanZoomLocked) return;
    _controller.updateStateOnly(
        _selectionService.deselectAll(_controller.currentState));
  }

  void selectAll({bool nodes = true, bool edges = true}) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    if (!_ref.read(flowOptionsProvider).elementsSelectable) return;
    _controller.updateStateOnly(_selectionService.selectAll(
      _controller.currentState,
      nodes: nodes,
      edges: edges,
    ));
  }

  /// Starts a marquee selection at [position] (flow / scene coords).
  ///
  /// Pass [pointer] to track move/up globally (across nodes/edges).
  void startSelection(Offset position, {int? pointer}) {
    if (_controller.currentState.isPanZoomLocked) return;
    if (!_controller.currentState.interactive) return;
    if (!_ref.read(flowOptionsProvider).elementsSelectable) return;
    _removeGlobalPointerRoute();
    _stopSelectionAutoPan();
    _lastGlobalPosition = null;
    _pendingScenePosition = null;
    _selectionDragOrigin = position;
    final stateAfterStart =
        _selectionService.startBoxSelection(_controller.currentState, position);
    _controller.updateStateOnly(
        stateAfterStart.copyWith(dragMode: DragMode.selection));
    final state = _controller.currentState;
    _ref.read(flowCanvasCallbacksProvider).onSelectionStart?.call(
          CanvasSelection(
            nodeIds: Set<String>.from(state.selectedNodes),
            edgeIds: Set<String>.from(state.selectedEdges),
          ),
        );

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

    final options = _ref.read(flowOptionsProvider);
    final next = _selectionService.updateBoxSelection(
      _controller.currentState,
      origin,
      position,
      _spatialIndex.nodeIndex,
      _spatialIndex.edgeIndex,
      selectionMode: mode,
      defaultOrigin: options.nodeOptions.nodeOrigin,
      nodesSelectable: options.nodeOptions.selectable,
      edgesSelectable: options.edgeOptions.selectable,
    );
    _controller.updateStateOnly(next);
  }

  void endSelection() {
    // Apply the last coalesced move so the final selection reflects the
    // pointer's release position before we read it for the end callback.
    _flushPendingSelection();
    _stopSelectionAutoPan();
    _removeGlobalPointerRoute();
    _selectionDragOrigin = null;
    _activePointer = null;

    if (_controller.currentState.dragMode != DragMode.selection) return;

    // Persist auto-pan like node-drag end does, so the camera never snaps
    // back (no-op when the viewport did not move).
    _controller.commitLiveViewportToState();

    // Keep selectedNodes / selectedEdges / runtime flags from last update.
    // Transient UI state only (rect + drag mode): updateStateOnly, never
    // mutate — a marquee clear must not record an undo entry.
    _controller.updateStateOnly(_controller.currentState.copyWith(
      selectionRect: Rect.zero,
      dragMode: DragMode.none,
    ));
    final state = _controller.currentState;
    _ref.read(flowCanvasCallbacksProvider).onSelectionEnd?.call(
          CanvasSelection(
            nodeIds: Set<String>.from(state.selectedNodes),
            edgeIds: Set<String>.from(state.selectedEdges),
          ),
        );
  }

  void cancelSelection() {
    // Drop any coalesced move — the gesture is being abandoned.
    _pendingScenePosition = null;
    _stopSelectionAutoPan();
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
      _lastGlobalPosition = event.position;
      // Coalesce the marquee update to one flush per frame; auto-pan velocity
      // is cheap and stays synchronous so the ramp reacts immediately.
      _pendingScenePosition = _globalToScene(event.position);
      _scheduleMoveFlush();
      _handleSelectionAutoPan(event.position);
    } else if (event is PointerUpEvent || event is PointerCancelEvent) {
      endSelection();
    }
  }

  /// Schedules a single [updateSelection] flush on the next frame.
  void _scheduleMoveFlush() {
    if (_moveScheduled) return;
    _moveScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _moveScheduled = false;
      _flushPendingSelection();
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Applies the latest pending marquee position, if any.
  void _flushPendingSelection() {
    final position = _pendingScenePosition;
    if (position == null) return;
    _pendingScenePosition = null;
    updateSelection(position);
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

  // ─────────────────────────────────────────────────────────────────
  // AUTO-PAN (Lattice `autoPanOnSelection`)
  // ─────────────────────────────────────────────────────────────────
  //
  // Same ramp + live-matrix pattern as node-drag auto-pan: the world moves
  // under a stationary pointer, and the selection re-extends from the same
  // global position each tick.

  void _handleSelectionAutoPan(Offset globalPosition) {
    final options = _ref.read(flowOptionsProvider);
    if (!options.viewportOptions.autoPanOnSelection) {
      _stopSelectionAutoPan();
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
      _stopSelectionAutoPan();
      return;
    }

    _autoPanVelocity = Offset(dx, dy);

    if (_autoPanTimer == null || !_autoPanTimer!.isActive) {
      _autoPanTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        _performSelectionAutoPan();
      });
    }
  }

  void _performSelectionAutoPan() {
    if (_controller.currentState.dragMode != DragMode.selection ||
        _autoPanVelocity == Offset.zero) {
      return;
    }
    final global = _lastGlobalPosition;
    if (global == null) return;

    // Live matrix pan — no Freezed viewport write every tick.
    _controller.panLiveBy(_autoPanVelocity);
    updateSelection(_globalToScene(global));
  }

  void _stopSelectionAutoPan() {
    _autoPanTimer?.cancel();
    _autoPanTimer = null;
    _autoPanVelocity = Offset.zero;
  }
}
