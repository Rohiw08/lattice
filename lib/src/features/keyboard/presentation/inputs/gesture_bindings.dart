import 'package:flutter/gestures.dart';

class GestureBindings {
  static double normalizedScrollZoomDelta(PointerScrollEvent event,
      {double scale = 0.08}) {
    return -event.scrollDelta.dy.sign * scale;
  }

  static Offset normalizedPanOnScroll(PointerScrollEvent event,
      {double speed = 1.0}) {
    return event.scrollDelta * speed;
  }
}
