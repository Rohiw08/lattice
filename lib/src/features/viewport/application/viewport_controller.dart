import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/fitview_options.dart';
import 'package:lattice/src/core/options/components/viewport_options.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ViewportController {
  ViewportController({
    required FlowCanvasInternalController controller,
    required ViewportService viewportService,
    required this.ref,
    required this.viewportHostKey,
  })  : _controller = controller,
        _viewportService = viewportService;

  final FlowCanvasInternalController _controller;
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

  /// Whether a programmatic camera flight is in progress.
  bool get isAnimating => _controller.isViewportAnimating;

  /// Stops a camera flight, keeping the live position (no snap-back).
  void cancelAnimation() => _controller.cancelViewportAnimation();

  /// Replaces the viewport wholesale (React Flow `setViewport` counterpart).
  ///
  /// Zoom is clamped to `[minZoom, maxZoom]` and the offset to
  /// `translateExtent`, mirroring [zoom]/[panBy]. Transient write (no
  /// history entry), like the other programmatic camera moves.
  Future<bool> setViewport(
    FlowViewport viewport, {
    double? minZoom,
    double? maxZoom,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final options = ref.read(flowOptionsProvider).viewportOptions;
    final zoom = viewport.zoom.clamp(
      minZoom ?? options.minZoom,
      maxZoom ?? options.maxZoom,
    );
    final clamped = _viewportService.clampViewport(
      FlowViewport(offset: viewport.offset, zoom: zoom),
      _translateExtent,
    );
    if (duration <= Duration.zero) {
      _controller.updateStateOnly(
        _controller.currentState.copyWith(viewport: clamped),
      );
      return Future.value(true);
    }
    return _controller.animateViewportTo(
      clamped,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// [focalPoint] is **viewer-local** (diagram pane), same space as [flowToViewport].
  Future<bool> zoom({
    required Offset focalPoint,
    required double minZoom,
    required double maxZoom,
    required double zoomFactor,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final target = _viewportService.zoom(
      _controller.currentState,
      zoomFactor: 1 + zoomFactor,
      focalViewportPoint: focalPoint,
      minZoom: minZoom,
      maxZoom: maxZoom,
      translateExtent: _translateExtent,
    );
    if (duration <= Duration.zero) {
      _controller.updateStateOnly(target);
      return Future.value(true);
    }
    return _controller.animateViewportTo(
      target.viewport,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// Zoom around the center of the diagram pane ([FlowCanvasState.viewportSize]).
  Future<bool> zoomAtViewportCenter({
    required bool zoomIn,
    required double minZoom,
    required double maxZoom,
    double step = 0.2,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final s = _controller.currentState;
    final size = s.viewportSize;
    final focal = (size != null && size.width > 0 && size.height > 0)
        ? Offset(size.width / 2, size.height / 2)
        : Offset.zero;
    return zoom(
      focalPoint: focal,
      minZoom: minZoom,
      maxZoom: maxZoom,
      zoomFactor: zoomIn ? step : -step,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// Zooms to an absolute [zoom] level around [focalPoint] (pane center by
  /// default). React Flow `zoomTo` counterpart.
  Future<bool> zoomTo(
    double zoom, {
    Offset? focalPoint,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final s = _controller.currentState;
    final size = s.viewportSize;
    final focal = focalPoint ??
        ((size != null && size.width > 0 && size.height > 0)
            ? Offset(size.width / 2, size.height / 2)
            : Offset.zero);
    final current = s.viewport.zoom;
    if (current <= 0) return Future.value(false);
    final options = ref.read(flowOptionsProvider).viewportOptions;
    return this.zoom(
      focalPoint: focal,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      zoomFactor: zoom / current - 1,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  Future<bool> fitView(
      {FitViewOptions fitviewOptions = const FitViewOptions(),
      ViewportOptions viewportOptions = const ViewportOptions()}) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final target = _viewportService.fitView(
      state: _controller.currentState,
      viewportOptions: viewportOptions,
      fitViewOptions: fitviewOptions,
      nodeOrigin: ref.read(flowOptionsProvider).nodeOptions.nodeOrigin,
    );
    if (fitviewOptions.duration <= Duration.zero) {
      _controller.updateStateOnly(target);
      return Future.value(true);
    }
    return _controller.animateViewportTo(
      target.viewport,
      duration: fitviewOptions.duration,
      ease: fitviewOptions.ease,
      interpolate: fitviewOptions.interpolate,
    );
  }

  /// Pure viewport computation (React Flow `getViewportForBounds`): what
  /// viewport would fit [bounds], without applying it. Null when there is
  /// nothing to fit (empty bounds/size) or the canvas is locked.
  FlowViewport? getViewportForBounds(
    Rect bounds, {
    EdgeInsets padding = const EdgeInsets.all(50),
    double? minZoom,
    double? maxZoom,
  }) {
    if (_controller.currentState.isPanZoomLocked) return null;
    final s = _controller.currentState;
    final size = s.viewportSize;
    if (size == null) return null;
    return _viewportService.viewportForBounds(
      bounds: bounds,
      viewportSize: size,
      viewportOptions: ref.read(flowOptionsProvider).viewportOptions,
      padding: padding,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
  }

  /// Fits an explicit flow-space [bounds] rect. React Flow `fitBounds`.
  Future<bool> fitBounds(
    Rect bounds, {
    EdgeInsets padding = const EdgeInsets.all(50),
    double? minZoom,
    double? maxZoom,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final target = _viewportService.fitViewportToBounds(
      state: _controller.currentState,
      bounds: bounds,
      viewportOptions: ref.read(flowOptionsProvider).viewportOptions,
      padding: padding,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    if (duration <= Duration.zero) {
      _controller.updateStateOnly(target);
      return Future.value(true);
    }
    return _controller.animateViewportTo(
      target.viewport,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// Centers the viewport so [flowPosition] (graph coordinates) is in the middle.
  ///
  /// React Flow `setCenter(x, y, {zoom})` counterpart. When [zoom] is given it
  /// is clamped to `[minZoom, maxZoom]` like [setViewport]. Pass a non-zero
  /// [duration] for an animated glide ([ease] + [interpolate] like
  /// [fitView]); the default is instant. See [isAnimating] /
  /// [cancelAnimation]. Returns true on landing, false when
  /// superseded, cancelled, or locked.
  Future<bool> centerOnPosition(
    Offset flowPosition, {
    double? zoom,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    if (_controller.currentState.isPanZoomLocked) return Future.value(false);
    final options = ref.read(flowOptionsProvider).viewportOptions;
    final resolvedZoom = zoom?.clamp(options.minZoom, options.maxZoom);
    final target = _viewportService.centerOnPosition(
      _controller.currentState,
      flowPosition,
      translateExtent: _translateExtent,
      zoom: resolvedZoom,
    );

    if (duration <= Duration.zero) {
      _controller.updateStateOnly(target);
      return Future.value(true);
    }
    return _controller.animateViewportTo(
      target.viewport,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
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

  /// Current zoom level (React Flow `getZoom`). Reads the live camera, so it
  /// is exact mid-gesture; committed state lags until interaction end.
  double getZoom() => _controller.liveViewport.viewport.zoom;

  /// Viewer-local offset → flow (graph) coordinates.
  ///
  /// When [snapToGrid] is set, snaps through the canvas [SnapGrid]
  /// (React Flow `screenToFlowPosition` snap options).
  Offset viewportToFlow(Offset viewport, {bool snapToGrid = false}) {
    final flow =
        _viewportService.viewportToFlow(_controller.currentState, viewport);
    if (!snapToGrid) return flow;
    return ref.read(flowOptionsProvider).viewportOptions.snapGrid.snap(flow);
  }

  /// React Flow `screenToFlowPosition` alias for [viewportToFlow] ("screen"
  /// = viewer-local here, matching RF's pane-relative client coords).
  Offset screenToFlowPosition(Offset screenPosition, {bool snapToGrid = false}) =>
      viewportToFlow(screenPosition, snapToGrid: snapToGrid);

  /// Flow (graph) coordinates → viewer-local offset.
  Offset flowToViewport(Offset flow) =>
      _viewportService.flowToViewport(_controller.currentState, flow);

  /// React Flow `flowToScreenPosition` alias for [flowToViewport].
  Offset flowToScreenPosition(Offset flowPosition) =>
      flowToViewport(flowPosition);

  /// Zooms in a step around the pane center (React Flow `zoomIn`).
  Future<bool> zoomIn({
    double step = 0.2,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    final options = ref.read(flowOptionsProvider).viewportOptions;
    return zoomAtViewportCenter(
      zoomIn: true,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      step: step,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// Zooms out a step around the pane center (React Flow `zoomOut`).
  Future<bool> zoomOut({
    double step = 0.2,
    Duration duration = Duration.zero,
    Curve ease = Curves.easeInOut,
    FitViewInterpolation interpolate = FitViewInterpolation.smooth,
  }) {
    final options = ref.read(flowOptionsProvider).viewportOptions;
    return zoomAtViewportCenter(
      zoomIn: false,
      minZoom: options.minZoom,
      maxZoom: options.maxZoom,
      step: step,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
    );
  }

  /// Flutter **global** logical position → flow coordinates (uses [viewportHostKey]).
  ///
  /// Returns null if the diagram is not laid out yet. When [snapToGrid] is
  /// set, snaps through the canvas [SnapGrid].
  Offset? flowPositionFromGlobal(Offset global, {bool snapToGrid = false}) {
    final box =
        viewportHostKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final viewport = box.globalToLocal(global);
    return viewportToFlow(viewport, snapToGrid: snapToGrid);
  }

  /// Flutter global → viewer-local (diagram pane), without applying zoom inverse.
  Offset? viewportPositionFromGlobal(Offset global) {
    final box =
        viewportHostKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(global);
  }
}
