import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/options/components/fitview_options.dart';
import 'package:lattice/src/core/options/components/viewport_options.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewportController {
  ViewportController({
    required CanvasStateAccessor controller,
    required ViewportService viewportService,
    required this.ref,
    required this.viewportHostKey,
  })  : _controller = controller,
        _viewportService = viewportService;

  final CanvasStateAccessor _controller;
  final ViewportService _viewportService;
  final Ref ref;
  final GlobalKey viewportHostKey;

  CoordinateExtent get _translateExtent =>
      ref.read(flowOptionsProvider).viewportOptions.translateExtent;

  void setViewportSize(Size size) {
    final currentState = _controller.currentState;
    if (currentState.viewportSize != size) {
      _controller.updateStateOnly(currentState.copyWith(viewportSize: size));
    }
  }

  void panBy(Offset delta) {
    if (_controller.currentState.isPanZoomLocked) return;
    final newState = _viewportService.pan(
      _controller.currentState,
      delta,
      _translateExtent,
    );
    _controller.updateStateOnly(newState);
  }

  void toggleLock() {
    final currentState = _controller.currentState;
    _controller.updateStateOnly(
        currentState.copyWith(isPanZoomLocked: !currentState.isPanZoomLocked));
  }

  /// [focalPoint] is **viewer-local** (diagram pane), same space as [flowToViewport].
  void zoom({
    required Offset focalPoint,
    required double minZoom,
    required double maxZoom,
    required double zoomFactor,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    final newState = _viewportService.zoom(
      _controller.currentState,
      zoomFactor: 1 + zoomFactor,
      focalViewportPoint: focalPoint,
      minZoom: minZoom,
      maxZoom: maxZoom,
      translateExtent: _translateExtent,
    );
    _controller.updateStateOnly(newState);
  }

  /// Zoom around the center of the diagram pane ([FlowCanvasState.viewportSize]).
  void zoomAtViewportCenter({
    required bool zoomIn,
    required double minZoom,
    required double maxZoom,
    double step = 0.2,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;
    final s = _controller.currentState;
    final size = s.viewportSize;
    final focal = (size != null && size.width > 0 && size.height > 0)
        ? Offset(size.width / 2, size.height / 2)
        : Offset.zero;
    zoom(
      focalPoint: focal,
      minZoom: minZoom,
      maxZoom: maxZoom,
      zoomFactor: zoomIn ? step : -step,
    );
  }

  void fitView(
      {FitViewOptions fitviewOptions = const FitViewOptions(),
      ViewportOptions viewportOptions = const ViewportOptions()}) {
    if (_controller.currentState.isPanZoomLocked) return;
    final newState = _viewportService.fitView(
        state: _controller.currentState,
        viewportOptions: viewportOptions,
        fitViewOptions: fitviewOptions);
    _controller.updateStateOnly(newState);
  }

  /// Centers the viewport so [flowPosition] (graph coordinates) is in the middle.
  void centerOnPosition(Offset flowPosition) {
    if (_controller.currentState.isPanZoomLocked) return;
    final newState = _viewportService.centerOnPosition(
      _controller.currentState,
      flowPosition,
      translateExtent: _translateExtent,
    );

    _controller.updateStateOnly(newState);
  }

  void resetView() {
    if (_controller.currentState.isPanZoomLocked) return;
    var newState =
        _controller.currentState.copyWith(viewport: const FlowViewport());
    newState =
        _viewportService.applyTranslateExtent(newState, _translateExtent);
    _controller.updateStateOnly(newState);
  }

  // --- Flow ↔ viewport ↔ Flutter global ---

  /// Viewer-local offset → flow (graph) coordinates.
  Offset viewportToFlow(Offset viewport) =>
      _viewportService.viewportToFlow(_controller.currentState, viewport);

  /// Flow (graph) coordinates → viewer-local offset.
  Offset flowToViewport(Offset flow) =>
      _viewportService.flowToViewport(_controller.currentState, flow);

  /// Flutter **global** logical position → flow coordinates (uses [viewportHostKey]).
  ///
  /// Returns null if the diagram is not laid out yet.
  Offset? flowPositionFromGlobal(Offset global) {
    final box =
        viewportHostKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final viewport = box.globalToLocal(global);
    return viewportToFlow(viewport);
  }

  /// Flutter global → viewer-local (diagram pane), without applying zoom inverse.
  Offset? viewportPositionFromGlobal(Offset global) {
    final box =
        viewportHostKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }
}
