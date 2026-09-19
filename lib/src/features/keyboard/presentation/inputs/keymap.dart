import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'intent_actions.dart';

class Keymap {
  final Map<LogicalKeySet, Intent> shortcuts;

  const Keymap(this.shortcuts);

  /// Bonus bindings beyond the user-configurable shortcut map: they cannot
  /// collide with custom bindings (user entries win on conflict) and are
  /// silenced together with everything else when keyboard input is disabled.
  factory Keymap.standard() {
    return Keymap({
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyF):
          const FitViewIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
          const CopyIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
          const PasteIntent(),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyN): const SelectAllIntent(selectEdges: false),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyE): const SelectAllIntent(selectNodes: false),
    });
  }
}
