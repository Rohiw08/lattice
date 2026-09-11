import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'package:lattice/src/features/nodes/presentation/non_trackpad_pan_gesture_recognizer.dart';

/// Marks the node gesture shell in the hit-test path so
/// [NodeDragPanGestureRecognizer] only treats *interior* targets as interactive
/// (ignores canvas-level [Listener]s sitting above the node in the path).
class NodeDragShell extends SingleChildRenderObjectWidget {
  const NodeDragShell({super.key, required super.child});

  @override
  RenderNodeDragShell createRenderObject(BuildContext context) {
    return RenderNodeDragShell();
  }
}

class RenderNodeDragShell extends RenderProxyBox {
  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null && child!.hitTest(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Node-body pan that **does not start** when the pointer is on interactive UI
/// (buttons, text fields, ink wells, handle listeners, …).
///
/// Automatic Lattice `nodrag`: put [IconButton] / [TextField] in a node
/// without wrapping [FlowNoDrag].
class NodeDragPanGestureRecognizer extends NonTrackpadPanGestureRecognizer {
  NodeDragPanGestureRecognizer({super.debugOwner});

  @override
  void addAllowedPointer(PointerDownEvent event) {
    if (isInteractivePointerTarget(event)) {
      return;
    }
    super.addAllowedPointer(event);
  }

  /// Whether [event] landed on UI inside the node that should keep the pointer.
  static bool isInteractivePointerTarget(PointerDownEvent event) {
    final result = HitTestResult();
    GestureBinding.instance.hitTestInView(
      result,
      event.position,
      event.viewId,
    );
    for (final entry in result.path) {
      final target = entry.target;
      // Reached the node shell — anything further out is canvas chrome.
      if (target is RenderNodeDragShell) {
        break;
      }
      if (target is RenderSemanticsGestureHandler) {
        return true;
      }
      if (target is RenderEditable) {
        return true;
      }
      // Handle connect [Listener]s (and similar) inside the node.
      if (target is RenderPointerListener) {
        return true;
      }
    }
    return false;
  }

  @override
  String get debugDescription => 'node drag pan';
}
