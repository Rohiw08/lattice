import 'package:flutter/gestures.dart';

/// Pan recognizer that ignores trackpad gestures (unbounded hit-testing).
///
/// Lets trackpad two-finger pan/zoom bubble to [InteractiveViewer] while
/// mouse/touch still drag nodes.
class NonTrackpadPanGestureRecognizer extends PanGestureRecognizer {
  NonTrackpadPanGestureRecognizer({super.debugOwner});

  @override
  void handleEvent(PointerEvent event) {
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    super.handleEvent(event);
  }

  @override
  bool isPointerAllowed(PointerEvent event) {
    if (event.kind == PointerDeviceKind.trackpad) {
      return false;
    }
    return super.isPointerAllowed(event);
  }

  @override
  void handleNonAllowedPointer(PointerDownEvent event) {
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    super.handleNonAllowedPointer(event);
  }

  @override
  void addPointerPanZoom(PointerPanZoomStartEvent event) {
    if (event.kind == PointerDeviceKind.trackpad) {
      return;
    }
    super.addPointerPanZoom(event);
  }
}
