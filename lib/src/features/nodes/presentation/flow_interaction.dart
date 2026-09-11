import 'dart:math' as math;

import 'package:lattice/src/features/nodes/presentation/non_trackpad_pan_gesture_recognizer.dart';
import 'package:lattice/src/features/nodes/presentation/unbounded_raw_gesture_detector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Hit-test helpers for canvas-style interaction utilities.
abstract final class FlowInteraction {
  /// Whether [event] is over a [FlowNoWheel] subtree.
  static bool blocksWheel(PointerEvent event) =>
      _pathHas<RenderFlowNoWheel>(event);

  /// Whether [event] is over a [FlowNoPan] subtree.
  static bool blocksPan(PointerEvent event) =>
      _pathHas<RenderFlowNoPan>(event);

  static bool _pathHas<T extends RenderObject>(PointerEvent event) {
    final result = HitTestResult();
    GestureBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );
    for (final entry in result.path) {
      if (entry.target is T) return true;
    }
    return false;
  }
}

/// Lattice `nodrag` — do not start a **node** drag from this subtree.
///
/// **Usually not needed** for buttons / fields / ink wells — node drag already
/// yields to those automatically. Use for custom [Listener]-only widgets.
///
/// ```dart
/// FlowNoDrag(child: MyCustomPointerWidget(...))
/// ```
class FlowNoDrag extends StatelessWidget {
  const FlowNoDrag({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UnboundedRawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        NonTrackpadPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                NonTrackpadPanGestureRecognizer>(
          () => NonTrackpadPanGestureRecognizer(),
          (recognizer) {
            recognizer
              ..onStart = (_) {}
              ..onUpdate = (_) {}
              ..onEnd = (_) {};
          },
        ),
      },
      child: child,
    );
  }
}

/// Lattice `nopan` — do not pan the **viewport** when dragging here.
///
/// Useful on non-draggable nodes or overlays where a drag would otherwise
/// move the canvas.
///
/// ```dart
/// FlowNoPan(child: MyFixedPanel(...))
/// ```
class FlowNoPan extends StatelessWidget {
  const FlowNoPan({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return UnboundedRawGestureDetector(
      behavior: HitTestBehavior.translucent,
      gestures: <Type, GestureRecognizerFactory>{
        NonTrackpadPanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
                NonTrackpadPanGestureRecognizer>(
          () => NonTrackpadPanGestureRecognizer(),
          (recognizer) {
            recognizer
              ..onStart = (_) {}
              ..onUpdate = (_) {}
              ..onEnd = (_) {};
          },
        ),
      },
      child: _FlowNoPanMarker(child: child),
    );
  }
}

class _FlowNoPanMarker extends SingleChildRenderObjectWidget {
  const _FlowNoPanMarker({required super.child});

  @override
  RenderFlowNoPan createRenderObject(BuildContext context) => RenderFlowNoPan();
}

/// Marker in the hit-test path for [FlowInteraction.blocksPan].
class RenderFlowNoPan extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null && child!.hitTest(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Lattice `nowheel` — do not zoom/pan the canvas on mouse wheel here.
///
/// Wrap scrollable content inside a node so wheel scrolls the child instead
/// of zooming the viewport.
///
/// ```dart
/// FlowNoWheel(
///   child: ListView(...),
/// )
/// ```
class FlowNoWheel extends StatelessWidget {
  const FlowNoWheel({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _FlowNoWheelMarker(
      child: Listener(
        onPointerSignal: (PointerSignalEvent event) {
          // Claim the signal for scrollables that use the resolver.
          GestureBinding.instance.pointerSignalResolver.register(event, (_) {});
        },
        child: child,
      ),
    );
  }
}

class _FlowNoWheelMarker extends SingleChildRenderObjectWidget {
  const _FlowNoWheelMarker({required super.child});

  @override
  RenderFlowNoWheel createRenderObject(BuildContext context) {
    return RenderFlowNoWheel();
  }
}

/// Marker in the hit-test path for [FlowInteraction.blocksWheel].
class RenderFlowNoWheel extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null && child!.hitTest(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Applies wheel zoom matching [InteractiveViewer]'s mouse-scroll curve.
double flowWheelZoomScaleChange(
  PointerScrollEvent event, {
  double scaleFactor = 200.0,
}) {
  return math.exp(-event.scrollDelta.dy / scaleFactor);
}
