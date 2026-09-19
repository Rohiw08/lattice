import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Stack that hit-tests children even when they sit outside the stack's layout
/// bounds (required for an infinite canvas after pan/zoom).
///
/// Unbounded stack pattern for infinite canvas hit-testing.
class InfiniteHitTestStack extends Stack {
  const InfiniteHitTestStack({
    super.key,
    super.alignment = AlignmentDirectional.topStart,
    super.textDirection,
    super.fit = StackFit.loose,
    super.clipBehavior = Clip.none,
    super.children = const <Widget>[],
  });

  @override
  RenderInfiniteHitTestStack createRenderObject(BuildContext context) {
    return RenderInfiniteHitTestStack(
      alignment: alignment,
      textDirection: textDirection ?? Directionality.maybeOf(context),
      fit: fit,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, RenderInfiniteHitTestStack renderObject) {
    renderObject
      ..alignment = alignment
      ..textDirection = textDirection ?? Directionality.maybeOf(context)
      ..fit = fit
      ..clipBehavior = clipBehavior;
  }
}

class RenderInfiniteHitTestStack extends RenderStack {
  RenderInfiniteHitTestStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip _size.contains(position) — children may live far outside layout size.
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => false;
}

/// SizedBox that keeps layout constraints but does not block hit tests outside
/// its box ([UnboundedSizedBox]).
class UnboundedSizedBox extends SingleChildRenderObjectWidget {
  const UnboundedSizedBox({super.key, this.width, this.height, super.child});

  final double? width;
  final double? height;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderConstrainedBox(
      additionalConstraints: BoxConstraints.tightFor(
        width: width,
        height: height,
      ),
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderConstrainedBox renderObject,
  ) {
    renderObject.additionalConstraints = BoxConstraints.tightFor(
      width: width,
      height: height,
    );
  }
}

class _UnboundedRenderConstrainedBox extends RenderConstrainedBox {
  _UnboundedRenderConstrainedBox({required super.additionalConstraints});

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      return child!.hitTest(result, position: position);
    }
    return false;
  }
}

/// [RepaintBoundary] that forwards hit tests outside its layout bounds
/// ([UnboundedRepaintBoundary]).
class UnboundedRepaintBoundary extends SingleChildRenderObjectWidget {
  const UnboundedRepaintBoundary({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderRepaintBoundary();
  }
}

class _UnboundedRenderRepaintBoundary extends RenderRepaintBoundary {
  _UnboundedRenderRepaintBoundary();

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      if (child!.hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}

/// Proxy box that skips bounds checks (for wrapping Listener / layers).
class UnboundedHitTestBox extends SingleChildRenderObjectWidget {
  const UnboundedHitTestBox({super.key, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _UnboundedRenderProxyBox();
  }
}

class _UnboundedRenderProxyBox extends RenderProxyBox {
  _UnboundedRenderProxyBox();

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (child != null) {
      if (child!.hitTest(result, position: position)) {
        result.add(BoxHitTestEntry(this, position));
        return true;
      }
    }
    return false;
  }
}

/// [Listener] that does not reject positions outside its layout size.
///
/// Required under [InteractiveViewer] when the pointer is in flow-space
/// coordinates that can exceed the viewport-sized box after pan/zoom.
class UnboundedListener extends SingleChildRenderObjectWidget {
  const UnboundedListener({
    super.key,
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerHover,
    this.onPointerCancel,
    this.onPointerSignal,
    this.onPointerPanZoomStart,
    this.behavior = HitTestBehavior.deferToChild,
    super.child,
  });

  final PointerDownEventListener? onPointerDown;
  final PointerMoveEventListener? onPointerMove;
  final PointerUpEventListener? onPointerUp;
  final void Function(PointerHoverEvent)? onPointerHover;
  final PointerCancelEventListener? onPointerCancel;
  final PointerSignalEventListener? onPointerSignal;
  final PointerPanZoomStartEventListener? onPointerPanZoomStart;
  final HitTestBehavior behavior;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderUnboundedListener(
      onPointerDown: onPointerDown,
      onPointerMove: onPointerMove,
      onPointerUp: onPointerUp,
      onPointerHover: onPointerHover,
      onPointerCancel: onPointerCancel,
      onPointerSignal: onPointerSignal,
      onPointerPanZoomStart: onPointerPanZoomStart,
      behavior: behavior,
    );
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant RenderObject renderObject) {
    final obj = renderObject as _RenderUnboundedListener;
    obj
      ..onPointerDown = onPointerDown
      ..onPointerMove = onPointerMove
      ..onPointerUp = onPointerUp
      ..onPointerHover = onPointerHover
      ..onPointerCancel = onPointerCancel
      ..onPointerSignal = onPointerSignal
      ..onPointerPanZoomStart = onPointerPanZoomStart
      ..behavior = behavior;
  }
}

class _RenderUnboundedListener extends RenderProxyBox {
  _RenderUnboundedListener({
    this.onPointerDown,
    this.onPointerMove,
    this.onPointerUp,
    this.onPointerHover,
    this.onPointerCancel,
    this.onPointerSignal,
    this.onPointerPanZoomStart,
    this.behavior = HitTestBehavior.deferToChild,
  });

  PointerDownEventListener? onPointerDown;
  PointerMoveEventListener? onPointerMove;
  PointerUpEventListener? onPointerUp;
  void Function(PointerHoverEvent)? onPointerHover;
  PointerCancelEventListener? onPointerCancel;
  PointerSignalEventListener? onPointerSignal;
  PointerPanZoomStartEventListener? onPointerPanZoomStart;
  HitTestBehavior behavior;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Visit children even when [position] is outside [size] (overflow UI).
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }

    // Empty chrome: only claim hits inside the layout box.
    if (!size.contains(position)) return false;

    var hitTarget = hitTestSelf(position);
    if (hitTarget || behavior == HitTestBehavior.translucent) {
      result.add(BoxHitTestEntry(this, position));
    }
    if (behavior == HitTestBehavior.opaque) {
      hitTarget = true;
    }
    return hitTarget;
  }

  @override
  bool hitTestSelf(Offset position) => behavior == HitTestBehavior.opaque;

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      onPointerDown?.call(event);
    } else if (event is PointerMoveEvent) {
      onPointerMove?.call(event);
    } else if (event is PointerUpEvent) {
      onPointerUp?.call(event);
    } else if (event is PointerHoverEvent) {
      onPointerHover?.call(event);
    } else if (event is PointerCancelEvent) {
      onPointerCancel?.call(event);
    } else if (event is PointerSignalEvent) {
      onPointerSignal?.call(event);
    } else if (event is PointerPanZoomStartEvent) {
      onPointerPanZoomStart?.call(event);
    }
  }
}

/// [Align] that forwards hit tests outside its layout bounds.
///
/// Required for resize handles that straddle the node's edge — [Align]'s
/// render object rejects positions outside its box (the node rect).
class UnboundedAlign extends SingleChildRenderObjectWidget {
  const UnboundedAlign({
    super.key,
    this.alignment = Alignment.center,
    this.widthFactor,
    this.heightFactor,
    super.child,
  });

  final AlignmentGeometry alignment;
  final double? widthFactor;
  final double? heightFactor;

  @override
  RenderUnboundedPositionedBox createRenderObject(BuildContext context) {
    return RenderUnboundedPositionedBox(
      alignment: alignment,
      textDirection: Directionality.maybeOf(context),
      widthFactor: widthFactor,
      heightFactor: heightFactor,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    RenderUnboundedPositionedBox renderObject,
  ) {
    renderObject
      ..alignment = alignment
      ..textDirection = Directionality.maybeOf(context)
      ..widthFactor = widthFactor
      ..heightFactor = heightFactor;
  }
}

class RenderUnboundedPositionedBox extends RenderPositionedBox {
  RenderUnboundedPositionedBox({
    super.child,
    super.alignment,
    super.textDirection,
    super.widthFactor,
    super.heightFactor,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip _size.contains(position) — children may sit outside the node rect.
    if (hitTestChildren(result, position: position) || hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// Semantics that does not reject positions outside its layout size.
///
/// [RenderSemanticsAnnotations] (used by the [Semantics] widget) applies the
/// default `size.contains` gate, which would hide node chrome that overflows
/// the node box (resize handles, connection handles, overlays) from pointer
/// hit-testing. This variant forwards hit tests to children regardless of
/// bounds — the same unbounded contract as the other widgets in this file —
/// while exposing the node-level semantics surface (label / hint /
/// selected / focusable / focused / tap).
class UnboundedSemantics extends SingleChildRenderObjectWidget {
  const UnboundedSemantics({
    super.key,
    this.container = false,
    this.label,
    this.hint,
    this.selected,
    this.focused,
    this.onTap,
    super.child,
  });

  final bool container;
  final String? label;
  final String? hint;
  final bool? selected;

  /// Non-null [focused] advertises the subtree as focusable (current
  /// Flutter semantics: focusability derives from `focused` being set).
  /// Pass null for non-focusable content.
  final bool? focused;
  final VoidCallback? onTap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderUnboundedSemantics(
      container: container,
      label: label,
      hint: hint,
      selected: selected,
      focused: focused,
      onTap: onTap,
      textDirection: Directionality.maybeOf(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final ro = renderObject as _RenderUnboundedSemantics;
    ro
      ..container = container
      ..label = label
      ..hint = hint
      ..selected = selected
      ..focused = focused
      ..onTap = onTap
      ..textDirection = Directionality.maybeOf(context);
  }
}

class _RenderUnboundedSemantics extends RenderSemanticsAnnotations {
  // ignore: use_super_parameters
  _RenderUnboundedSemantics({
    required bool container,
    required String? label,
    required String? hint,
    required bool? selected,
    required bool? focused,
    required VoidCallback? onTap,
    required TextDirection? textDirection,
  })  : _label = label,
        _hint = hint,
        _selected = selected,
        _focused = focused,
        _onTap = onTap,
        super(
          properties: SemanticsProperties(
            label: label,
            hint: hint,
            selected: selected,
            focused: focused,
            onTap: onTap,
            textDirection: textDirection,
          ),
          container: container,
          textDirection: textDirection,
        );

  String? _label;
  String? _hint;
  bool? _selected;
  bool? _focused;
  VoidCallback? _onTap;

  void _sync(TextDirection? textDirection) {
    properties = SemanticsProperties(
      label: _label,
      hint: _hint,
      selected: _selected,
      focused: _focused,
      onTap: _onTap,
      textDirection: textDirection,
    );
  }

  @override
  set container(bool value) {
    if (super.container == value) return;
    super.container = value;
    markNeedsSemanticsUpdate();
  }

  @override
  set textDirection(TextDirection? value) {
    if (textDirection == value) return;
    super.textDirection = value;
    _sync(value);
  }

  set label(String? value) {
    if (_label == value) return;
    _label = value;
    _sync(textDirection);
  }

  set hint(String? value) {
    if (_hint == value) return;
    _hint = value;
    _sync(textDirection);
  }

  set selected(bool? value) {
    if (_selected == value) return;
    _selected = value;
    _sync(textDirection);
  }

  set focused(bool? value) {
    if (_focused == value) return;
    _focused = value;
    _sync(textDirection);
  }

  set onTap(VoidCallback? value) {
    _onTap = value;
    _sync(textDirection);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Skip _size.contains(position) — node chrome may sit outside the box.
    if (hitTestChildren(result, position: position) ||
        hitTestSelf(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}

/// [Positioned] + [UnboundedHitTestBox] ([UnboundedPositioned]).
///
/// Use [.fill] for canvas layers so hit tests reach children whose flow
/// coordinates lie outside the viewport-sized layout box.
class UnboundedPositioned extends StatelessWidget {
  const UnboundedPositioned({
    super.key,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.width,
    this.height,
    required this.child,
  });

  const UnboundedPositioned.fill({super.key, required this.child})
      : left = 0.0,
        top = 0.0,
        right = 0.0,
        bottom = 0.0,
        width = null,
        height = null;

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double? width;
  final double? height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: width,
      height: height,
      child: UnboundedHitTestBox(child: child),
    );
  }
}
