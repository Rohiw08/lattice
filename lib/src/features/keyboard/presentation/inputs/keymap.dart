import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'intent_actions.dart';

class Keymap {
  final Map<ShortcutActivator, Intent> shortcuts;

  const Keymap(this.shortcuts);

  /// Bonus bindings beyond the user-configurable shortcut map: they cannot
  /// collide with custom bindings (user entries win on conflict) and are
  /// silenced together with everything else when keyboard input is disabled.
  ///
  /// Platform-aware, matching [KeyboardOptions] defaults: the primary modifier
  /// is Cmd on macOS and Ctrl elsewhere, so Copy/Paste/FitView work with the
  /// platform-standard chord (a control-only map left macOS with no Cmd
  /// binding at all).
  factory Keymap.standard() {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;
    return Keymap({
      SingleActivator(LogicalKeyboardKey.keyF, control: !isMac, meta: isMac):
          const FitViewIntent(),
      SingleActivator(LogicalKeyboardKey.keyC, control: !isMac, meta: isMac):
          const CopyIntent(),
      SingleActivator(LogicalKeyboardKey.keyV, control: !isMac, meta: isMac):
          const PasteIntent(),
      SingleActivator(LogicalKeyboardKey.keyN,
              control: !isMac, meta: isMac, shift: true):
          const SelectAllIntent(selectEdges: false),
      SingleActivator(LogicalKeyboardKey.keyE,
              control: !isMac, meta: isMac, shift: true):
          const SelectAllIntent(selectNodes: false),
    });
  }
}
