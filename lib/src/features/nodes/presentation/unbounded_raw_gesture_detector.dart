import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

/// [RawGestureDetector] that hit-tests overflowing children.
///
/// Flutter's [Listener] / [RawGestureDetector] reject pointers outside the
/// layout [Size] before visiting children, so menus / panels drawn past the
/// node box never receive taps. Uses [UnboundedListener] instead.
class UnboundedRawGestureDetector extends StatefulWidget {
  const UnboundedRawGestureDetector({
    super.key,
    this.gestures = const <Type, GestureRecognizerFactory>{},
    this.behavior,
    required this.child,
  });

  final Map<Type, GestureRecognizerFactory> gestures;
  final HitTestBehavior? behavior;
  final Widget child;

  @override
  State<UnboundedRawGestureDetector> createState() =>
      _UnboundedRawGestureDetectorState();
}

class _UnboundedRawGestureDetectorState
    extends State<UnboundedRawGestureDetector> {
  Map<Type, GestureRecognizer>? _recognizers;

  @override
  void initState() {
    super.initState();
    _syncAll(widget.gestures);
  }

  @override
  void didUpdateWidget(UnboundedRawGestureDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAll(widget.gestures);
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers!.values) {
      recognizer.dispose();
    }
    _recognizers = null;
    super.dispose();
  }

  void _syncAll(Map<Type, GestureRecognizerFactory> gestures) {
    final old = _recognizers ?? <Type, GestureRecognizer>{};
    final next = <Type, GestureRecognizer>{};
    for (final type in gestures.keys) {
      final factory = gestures[type]!;
      final recognizer = old[type] ?? factory.constructor();
      assert(
        recognizer.runtimeType == type,
        'GestureRecognizerFactory of type $type created a '
        '${recognizer.runtimeType}.',
      );
      factory.initializer(recognizer);
      next[type] = recognizer;
    }
    for (final type in old.keys) {
      if (!next.containsKey(type)) {
        old[type]!.dispose();
      }
    }
    _recognizers = next;
  }

  void _handlePointerDown(PointerDownEvent event) {
    for (final recognizer in _recognizers!.values) {
      recognizer.addPointer(event);
    }
  }

  void _handlePointerPanZoomStart(PointerPanZoomStartEvent event) {
    for (final recognizer in _recognizers!.values) {
      recognizer.addPointerPanZoom(event);
    }
  }

  HitTestBehavior get _behavior =>
      widget.behavior ?? HitTestBehavior.deferToChild;

  @override
  Widget build(BuildContext context) {
    return UnboundedListener(
      onPointerDown: _handlePointerDown,
      onPointerPanZoomStart: _handlePointerPanZoomStart,
      behavior: _behavior,
      child: widget.child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final gestures = _recognizers?.values
            .map((r) => r.debugDescription)
            .toList(growable: false) ??
        const <String>[];
    properties.add(IterableProperty<String>('gestures', gestures));
  }
}
