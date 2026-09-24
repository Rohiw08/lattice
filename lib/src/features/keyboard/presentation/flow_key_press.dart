import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';

/// Rebuilds while any of [keys] is held (React Flow `useKeyPress`).
///
/// Modifier-aware via [KeyboardOptions.isAnyMultiSelectionKeyPressed], so
/// `{LogicalKeyboardKey.control}` matches either Control key:
///
/// ```dart
/// FlowKeyPress(
///   keys: const {LogicalKeyboardKey.shift},
///   builder: (context, pressed) => Text(
///     pressed ? 'release to drop' : 'hold Shift to multi-select',
///   ),
/// )
/// ```
///
/// This only *observes* keys. To trigger canvas actions, bind
/// [KeyboardAction]s in [KeyboardOptions.shortcuts] instead.
class FlowKeyPress extends StatefulWidget {
  const FlowKeyPress({
    super.key,
    required this.keys,
    required this.builder,
  });

  /// Keys to watch; pressed is true while ANY of them is held.
  final Set<LogicalKeyboardKey> keys;

  final Widget Function(BuildContext context, bool pressed) builder;

  @override
  State<FlowKeyPress> createState() => _FlowKeyPressState();
}

class _FlowKeyPressState extends State<FlowKeyPress> {
  late bool _pressed;

  @override
  void initState() {
    super.initState();
    _pressed = _read();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didUpdateWidget(FlowKeyPress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _pressed = _read();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _read() =>
      KeyboardOptions.isAnyMultiSelectionKeyPressed(widget.keys);

  bool _onKey(KeyEvent event) {
    final next = _read();
    if (next != _pressed && mounted) {
      setState(() => _pressed = next);
    }
    // Never consume: canvas shortcuts and fields still receive the event.
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _pressed);
}
