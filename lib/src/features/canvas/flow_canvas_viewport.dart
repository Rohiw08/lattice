import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/features/background/presentation/flow_background_pattern_layer.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/canvas/flow_canvas_pointer_layer.dart';
import 'package:lattice/src/features/edges/presentation/layer/edge_reconnect_layer.dart';
import 'package:lattice/src/features/edges/presentation/layer/edge_a11y_layer.dart';
import 'package:lattice/src/features/edges/presentation/layer/edges_layer.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/gesture_bindings.dart';
import 'package:lattice/src/features/nodes/domain/node_render_layer.dart';
import 'package:lattice/src/features/nodes/presentation/flow_interaction.dart';
import 'package:lattice/src/features/nodes/presentation/flow_node_a11y_layer.dart';
import 'package:lattice/src/features/nodes/presentation/nodes_layer.dart';
import 'package:lattice/src/features/selection/presentation/layers/selection_layer.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pan/zoom surface: [InteractiveViewer] + canvas-style scroll policy.
///
/// Hit-test chain: nothing inside the transformed child may use
/// Flutter's default `size.contains` gate (Listener / GestureDetector /
/// RepaintBoundary), or nodes whose flow coords lie outside the viewport-sized
/// layout box become unclickable while still painting.
///
/// Paint / hit order (layered paint order with z within each band):
/// 1. Deselect backdrop (empty canvas) — also starts Shift box-select
/// 2. Background pattern (flow space) — moves with IV
/// 3. Background nodes (groups) — behind edges, still hittable
/// 4. Edge paint
/// 5. Edge stroke hit targets
/// 6. Middle nodes
/// 7. Selection UI (paint only)
class FlowCanvasInteractiveSurface extends ConsumerStatefulWidget {
  const FlowCanvasInteractiveSurface({
    super.key,
    this.backgroundPatternStyle,
  });

  /// When set, dots/grid are painted in flow space under nodes.
  final FlowBackgroundStyle? backgroundPatternStyle;

  @override
  ConsumerState<FlowCanvasInteractiveSurface> createState() =>
      _FlowCanvasInteractiveSurfaceState();
}

class _FlowCanvasInteractiveSurfaceState
    extends ConsumerState<FlowCanvasInteractiveSurface> {
  /// Mirrors Lattice `selectionKeyPressed` so pan can be disabled while Shift is held.
  bool _selectionKeyHeld = false;

  /// Mirrors Lattice `panActivationKeyCode`: while held, left-drag pans.
  bool _spacePanHeld = false;

  /// Middle/right button pan (Lattice `panOnDrag={[1,2]}`) — IV only handles left.
  int? _auxPanPointer;
  Offset? _auxPanLastGlobal;
  bool _auxPanRouteActive = false;

  /// Pending secondary-button press for context-menu routing (Lattice
  /// `onNodeContextMenu` / `onEdgeContextMenu` / `onPaneContextMenu`).
  /// A press that moves past [_contextMenuSlop] becomes an aux-pan instead.
  int? _secondaryPointer;
  Offset? _secondaryDownGlobal;

  /// Tap tolerance for a context-menu press (aux pans always exceed it).
  static const double _contextMenuSlop = 8.0;

  /// True while InteractiveViewer / aux pan is actively moving the viewport.
  bool _viewportInteracting = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    final keyboardOptions = ref.read(flowOptionsProvider).keyboardOptions;
    _selectionKeyHeld = keyboardOptions.isSelectionKeyActive;
    _spacePanHeld = keyboardOptions.isPanActivationHeld;
  }

  @override
  void dispose() {
    _stopAuxiliaryPan();
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    super.dispose();
  }

  bool _onKeyEvent(KeyEvent event) {
    final keyboardOptions = ref.read(flowOptionsProvider).keyboardOptions;
    final active = keyboardOptions.isSelectionKeyActive;
    if (active != _selectionKeyHeld) {
      setState(() => _selectionKeyHeld = active);
    }
    final spacePan = keyboardOptions.isPanActivationHeld;
    if (spacePan != _spacePanHeld) {
      setState(() => _spacePanHeld = spacePan);
    }
    return false;
  }

  void _stopAuxiliaryPan() {
    if (_auxPanRouteActive) {
      GestureBinding.instance.pointerRouter
          .removeGlobalRoute(_onAuxiliaryPanRoute);
      if (mounted) {
        setState(() => _auxPanRouteActive = false);
      } else {
        _auxPanRouteActive = false;
      }
    }
    _auxPanPointer = null;
    _auxPanLastGlobal = null;
  }

  void _onAuxiliaryPanRoute(PointerEvent event) {
    if (event.pointer != _auxPanPointer) return;

    final controller = ref.read(internalControllerProvider.notifier);

    if (event is PointerMoveEvent) {
      final last = _auxPanLastGlobal;
      if (last == null) return;
      final delta = event.position - last;
      _auxPanLastGlobal = event.position;
      if (delta != Offset.zero) {
        controller.panLiveBy(delta);
      }
      return;
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _stopAuxiliaryPan();
      controller.onViewportInteractionEnd();
    }
  }

  void _maybeStartAuxiliaryPan(PointerDownEvent event) {
    final options = ref.read(flowOptionsProvider);
    final v = options.viewportOptions;
    final isLocked =
        ref.read(internalControllerProvider).isPanZoomLocked;
    final dragMode = ref.read(internalControllerProvider).dragMode;

    if (isLocked || dragMode != DragMode.none) return;
    if (!v.isAuxiliaryPanButton(event.buttons)) return;
    if (FlowInteraction.blocksPan(event)) return;

    final controller = ref.read(internalControllerProvider.notifier);
    _stopAuxiliaryPan();
    _auxPanPointer = event.pointer;
    _auxPanLastGlobal = event.position;
    GestureBinding.instance.pointerRouter.addGlobalRoute(_onAuxiliaryPanRoute);
    setState(() => _auxPanRouteActive = true);
    controller.onViewportInteractionStart();
  }

  void _trackSecondaryDown(PointerDownEvent event) {
    if (event.buttons & kSecondaryMouseButton == 0) return;
    _secondaryPointer = event.pointer;
    _secondaryDownGlobal = event.position;
  }

  /// Lattice `onPaneMouseEnter/Move` (flow coords). Pure observers: no
  /// setState, no rebuilds.
  void _firePaneEnter(PointerEnterEvent event) {
    final cb = ref.read(flowCanvasCallbacksProvider).onPaneMouseEnter;
    if (cb == null) return;
    final flow = ref
        .read(internalControllerProvider.notifier)
        .viewport
        .flowPositionFromGlobal(event.position);
    if (flow != null) cb(flow);
  }

  void _firePaneHover(PointerHoverEvent event) {
    final cb = ref.read(flowCanvasCallbacksProvider).onPaneMouseMove;
    if (cb == null) return;
    final flow = ref
        .read(internalControllerProvider.notifier)
        .viewport
        .flowPositionFromGlobal(event.position);
    if (flow != null) cb(flow);
  }

  void _maybeFireContextMenu(PointerUpEvent event) {    final downGlobal = _secondaryDownGlobal;
    if (event.pointer != _secondaryPointer || downGlobal == null) return;
    _secondaryPointer = null;
    _secondaryDownGlobal = null;
    if ((event.position - downGlobal).distance > _contextMenuSlop) return;
    final controller = ref.read(internalControllerProvider.notifier);
    controller.fireContextMenuAt(event.position);
  }

  void _onPointerSignal(PointerSignalEvent signal) {
    if (signal is! PointerScrollEvent) return;
    if (signal.kind != PointerDeviceKind.mouse) return;
    if (signal.scrollDelta.dy == 0 && signal.scrollDelta.dx == 0) return;

    final isLocked = ref.read(internalControllerProvider).isPanZoomLocked;
    if (isLocked) return;
    // Lattice `nowheel` — leave the event for scrollables under the pointer.
    if (FlowInteraction.blocksWheel(signal)) return;

    final v = ref.read(flowOptionsProvider).viewportOptions;
    final controller = ref.read(internalControllerProvider.notifier);

    // Lattice `preventScrolling` (default true): when false, don't claim the
    // wheel — let it fall through to an ancestor scrollable so the page can
    // scroll while the pointer is over the canvas.
    if (!v.preventScrolling) return;

    // Lattice `onPaneScroll` (flow coords), for processed scrolls only.
    final onPaneScroll =
        ref.read(flowCanvasCallbacksProvider).onPaneScroll;
    if (onPaneScroll != null) {
      final flow = controller.viewport.flowPositionFromGlobal(signal.position);
      if (flow != null) onPaneScroll(flow);
    }

    // Lattice `zoomActivationKeyCode`: when a gate set is configured, wheel
    // zoom needs a held key; otherwise the wheel falls back to pan/scroll.
    final zoomGated = v.zoomOnScroll &&
        !ref.read(flowOptionsProvider).keyboardOptions.isZoomActivationHeld;
    if (v.zoomOnScroll && !zoomGated) {
      final local = controller.viewport.viewportPositionFromGlobal(
        signal.position,
      );
      if (local == null) return;
      final scaleChange = flowWheelZoomScaleChange(
        signal,
        scaleFactor: kDefaultMouseScrollToScaleFactor,
      );
      controller.viewport.zoom(
        focalPoint: local,
        minZoom: v.minZoom,
        maxZoom: v.maxZoom,
        // Controller applies (1 + zoomFactor) as the multiply factor.
        zoomFactor: scaleChange - 1,
      );
      return;
    }

    if (v.panOnScroll) {
      final raw = GestureBindings.normalizedPanOnScroll(
        signal,
        speed: v.panOnScrollSpeed,
      );
      // Lattice `panOnScrollMode`: lock to one axis. A vertical-only wheel
      // still pans along the locked axis (fall back to the other component).
      Offset delta;
      switch (v.panOnScrollMode) {
        case PanOnScrollMode.horizontal:
          delta = Offset(raw.dx != 0 ? raw.dx : raw.dy, 0);
          break;
        case PanOnScrollMode.vertical:
          delta = Offset(0, raw.dy != 0 ? raw.dy : raw.dx);
          break;
        case PanOnScrollMode.free:
          delta = raw;
          break;
      }
      controller.panLiveBy(-delta);
      controller.commitLiveViewportToState();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(internalControllerProvider.notifier);
    final options = ref.read(flowOptionsProvider);
    final isLocked = ref.watch(
      internalControllerProvider.select((state) => state.isPanZoomLocked),
    );
    final dragMode = ref.watch(
      internalControllerProvider.select((state) => state.dragMode),
    );
    final v = options.viewportOptions;

    // Wheel zoom is handled in [_onPointerSignal] so [FlowNoWheel] can block it.
    // Keep IV's built-in scroll-zoom off (same as pan-on-scroll mode).
    const wheelZoomFactor = 1e12;
    final trackpadScrollCausesScale = v.zoomOnScroll;

    // Lattice: left pan off for marquee / selection key / active connection drag.
    // Do NOT disable pan for [DragMode.node] — node pan wins the arena; flipping
    // panEnabled mid-drag causes dual-motion jank.
    // Pan-activation key (Space) forces pan on instead, winning over marquee
    // and selection-key modes for the drag duration.
    final panEnabled = !isLocked &&
        dragMode != DragMode.selection &&
        dragMode != DragMode.connection &&
        (_spacePanHeld ||
            (!_selectionKeyHeld && !v.selectionOnDrag && v.panOnDragLeft));

    final cursors =
        context.flowCanvasTheme.cursor ?? FlowCursorStyle.system(context);
    final paneCursor = cursors.resolvePane(
      selection: dragMode == DragMode.selection ||
          _selectionKeyHeld ||
          v.selectionOnDrag,
      dragging: _viewportInteracting ||
          _auxPanRouteActive ||
          _spacePanHeld ||
          dragMode == DragMode.canvas,
      panEnabled: panEnabled,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return MouseRegion(
          cursor: paneCursor,
          onEnter: _firePaneEnter,
          onHover: _firePaneHover,
          onExit: (_) => ref
              .read(flowCanvasCallbacksProvider)
              .onPaneMouseLeave
              ?.call(),
          child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: isLocked ? null : (PointerDownEvent event) {
            _trackSecondaryDown(event);
            _maybeStartAuxiliaryPan(event);
          },
          onPointerUp: isLocked ? null : _maybeFireContextMenu,
          onPointerSignal: isLocked ? null : _onPointerSignal,
          child: AbsorbPointer(
            absorbing: isLocked,
            child: InteractiveViewer(
            key: controller.viewportKey,
            transformationController: controller.transformationController,
            boundaryMargin: const EdgeInsets.all(double.infinity),
            constrained: false,
            clipBehavior: Clip.none,
            minScale: v.minZoom,
            maxScale: v.maxZoom,
            scaleFactor: wheelZoomFactor,
            panEnabled: panEnabled,
            // `zoomOnPinch` gates touch pinch-to-zoom. InteractiveViewer routes
            // trackpad-scroll-scale through the same recognizer, so keep it on
            // when `zoomOnScroll` wants trackpad zoom even if pinch is off.
            scaleEnabled: !isLocked &&
                dragMode != DragMode.selection &&
                (v.zoomOnPinch || trackpadScrollCausesScale),
            trackpadScrollCausesScale: trackpadScrollCausesScale,
            onInteractionStart: (_) {
              setState(() => _viewportInteracting = true);
              controller.onViewportInteractionStart();
            },
            onInteractionEnd: (_) {
              setState(() => _viewportInteracting = false);
              controller.onViewportInteractionEnd();
            },
            child: UnboundedSizedBox(
              key: controller.canvasKey,
              width: width,
              height: height,
              child: InfiniteHitTestStack(
                clipBehavior: Clip.none,
                children: [
                  // Pane backdrop sized to the VISIBLE flow rect (not the
                  // fixed flow box): after any pan/zoom, taps and marquee
                  // starts outside the origin box would otherwise fall into
                  // a dead zone. Rebuilt per matrix tick; hit-test only.
                  ListenableBuilder(
                    listenable: controller.transformationController,
                    builder: (context, _) {
                      final visible =
                          _visibleFlowRect(controller, Size(width, height));
                      return UnboundedPositioned(
                        left: visible.left,
                        top: visible.top,
                        width: visible.width,
                        height: visible.height,
                        child: FlowCanvasDeselectLayer(
                          flowOrigin: visible.topLeft,
                        ),
                      );
                    },
                  ),
                  if (widget.backgroundPatternStyle != null)
                    UnboundedPositioned.fill(
                      child: FlowBackgroundPatternLayer(
                        style: widget.backgroundPatternStyle!,
                        viewportSize: Size(width, height),
                      ),
                    ),
                  UnboundedPositioned.fill(
                    child: FlowNodesLayer(
                      layer: NodeRenderLayer.background,
                      layoutSize: Size(width, height),
                    ),
                  ),
                  UnboundedPositioned.fill(
                    child: FlowEdgeLayer(layoutSize: Size(width, height)),
                  ),
                  const UnboundedPositioned.fill(child: EdgeA11yLayer()),
                  const UnboundedPositioned.fill(
                    child: FlowCanvasPointerLayer(),
                  ),
                  UnboundedPositioned.fill(
                    child: FlowNodesLayer(
                      layer: NodeRenderLayer.middle,
                      layoutSize: Size(width, height),
                    ),
                  ),
                  UnboundedPositioned.fill(
                    child: FlowNodesLayer(
                      layer: NodeRenderLayer.foreground,
                      layoutSize: Size(width, height),
                    ),
                  ),
                  // Always-mounted keyboard-focus / screen-reader proxies for
                  // every node (bodies above are culled). Ring paints over the
                  // node bodies; IgnorePointer keeps pointer behavior on the
                  // real bodies.
                  const UnboundedPositioned.fill(child: FlowNodeA11yLayer()),
                  const UnboundedPositioned.fill(child: SelectionLayer()),
                  const UnboundedPositioned.fill(child: EdgeReconnectLayer()),
                ],
              ),
            ),
            ),
          ),
          ),
        );
      },
    );
  }
}

/// Visible flow-space rect for the pane backdrop, clamped to finite bounds.
///
/// Pre-layout (empty size) the helper returns a ~infinite rect; clamping
/// keeps the positioned box finite so layout never sees absurd sizes.
Rect _visibleFlowRect(
  FlowCanvasInternalController controller,
  Size viewportSize,
) {
  final rect = computeVisibleFlowRectFromCanvasTransform(
    controller.transformationController.value,
    viewportSize,
  );
  double clamp(double v) => v.clamp(-1e6, 1e6);
  return Rect.fromLTRB(
    clamp(rect.left),
    clamp(rect.top),
    clamp(rect.right),
    clamp(rect.bottom),
  );
}
