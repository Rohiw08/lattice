import 'package:flutter/material.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/intent_actions.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/keymap.dart';

class KeyboardAdapter extends StatefulWidget {
  final FlowCanvasInternalController controller;
  final FlowCanvasOptions options;
  final Keymap keymap;
  final Widget child;

  const KeyboardAdapter({
    super.key,
    required this.controller,
    required this.options,
    required this.keymap,
    required this.child,
  });

  @override
  State<KeyboardAdapter> createState() => _KeyboardAdapterState();
}

class _KeyboardAdapterState extends State<KeyboardAdapter> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kb = widget.options.keyboardOptions;
    // Single dispatch pipeline: user bindings (first, so custom mappings win
    // on conflict) plus the bonus keymap. Empty when disabled — a disabled
    // canvas answers no shortcut at all.
    //
    // Text-field protection lives in [EditingGuardAction], not here: every
    // canvas action reports disabled while a field holds primary focus, so
    // editing keys bubble past the canvas to the app-level text intents.
    final Map<ShortcutActivator, Intent> shortcuts = kb.enabled
        ? {
            ...kb.shortcuts.map(
              (activator, action) =>
                  MapEntry(activator, intentForKeyboardAction(action)),
            ),
            ...widget.keymap.shortcuts,
          }
        : const {};
    final Map<Type, Action<Intent>> actions =
        buildActions(widget.controller, widget.options);

    return Shortcuts(
      shortcuts: shortcuts,
      child: Actions(
        actions: actions,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            // Never swallow: canvas actions guard themselves via
            // [EditingGuardAction], and returning handled here would stop the
            // bubble before the app-level text intents that fields need.
            return KeyEventResult.ignored;
          },
          child: Listener(
            onPointerDown: (_) {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
