import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final Map<LogicalKeySet, Intent> shortcuts = widget.keymap.shortcuts;
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
            final kb = widget.options.keyboardOptions;
            if (!kb.enabled) return KeyEventResult.ignored;

            // Find matching activator
            ShortcutActivator? matched;
            for (final activator in kb.shortcuts.keys) {
              if (activator.accepts(event, HardwareKeyboard.instance)) {
                matched = activator;
                break;
              }
            }
            if (matched == null) return KeyEventResult.ignored;
            final mapped = kb.shortcuts[matched];
            if (mapped == null) return KeyEventResult.ignored;

            widget.controller.keyboard.handleKeyboardAction(
              mapped,
              options: kb,
              minZoom: widget.options.viewportOptions.minZoom,
              maxZoom: widget.options.viewportOptions.maxZoom,
              translateExtent: widget.options.viewportOptions.translateExtent,
            );
            return KeyEventResult.handled;
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
