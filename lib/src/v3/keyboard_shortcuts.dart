import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_controller.dart';
import 'lattice_cull.dart';
import 'lattice_node.dart';
import 'lattice_scope.dart';
import 'session_providers.dart';

/// Opt-in keyboard shortcuts for a lattice canvas.
///
/// The canvas does NOT include this widget — users opt in by wrapping
/// their canvas (or canvas content) with it. Must mount under a
/// [LatticeScope] for the target controller: either as an ancestor of
/// [LatticeCanvas] inside an explicit outer scope ...
///
/// ```dart
/// LatticeScope(
///   controller: controller,
///   child: LatticeShortcuts(child: LatticeCanvas(controller: controller)),
/// )
/// ```
///
/// ... or inside the canvas subtree (e.g. an overlay), which is already
/// in the canvas-provided scope.
///
/// Wraps [child] in [CallbackShortcuts] around an autofocused [Focus]
/// (shortcuts only fire for key events from focused descendants, so the
/// [CallbackShortcuts] stays outside the [Focus]):
///
/// | Keys | Verb |
/// |---|---|
/// | Delete / Backspace | `deleteSelection()` |
/// | Ctrl/Cmd+C | `copySelection()` |
/// | Ctrl/Cmd+X | cut: `copySelection()` (no history) + `deleteSelection()` (one entry) — ONE history entry total |
/// | Ctrl/Cmd+V | `paste(at: viewportCenter)` — the pane center in flow coords via `screenToFlow`, or [Offset.zero] before first layout publishes a pane size |
/// | Ctrl/Cmd+Z | `undo()` |
/// | Ctrl/Cmd+Shift+Z, Ctrl/Cmd+Y | `redo()` |
/// | Arrows | nudge selected nodes by 1px (10px with Shift) via `moveNodes` — one history entry per keypress (key repeat streams one entry per event) |
///
/// Both `control` and `meta` variants are registered for C/X/V/Z/Y so
/// Cmd works on macOS and Ctrl elsewhere; the Ctrl spellings are pinned
/// by widget tests.
///
/// When [enabled] is false the bindings are inert (returns [child]
/// untouched).
class LatticeShortcuts extends ConsumerWidget {
  const LatticeShortcuts({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;

  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!enabled) return child;
    final LatticeController controller = LatticeScope.of(context);
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.delete):
            controller.deleteSelection,
        const SingleActivator(LogicalKeyboardKey.backspace):
            controller.deleteSelection,
        const SingleActivator(LogicalKeyboardKey.keyC, control: true):
            controller.copySelection,
        const SingleActivator(LogicalKeyboardKey.keyC, meta: true):
            controller.copySelection,
        const SingleActivator(LogicalKeyboardKey.keyX, control: true): () =>
            _cut(controller),
        const SingleActivator(LogicalKeyboardKey.keyX, meta: true): () =>
            _cut(controller),
        const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
            controller.paste(at: _viewportCenter(controller)),
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true): () =>
            controller.paste(at: _viewportCenter(controller)),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            controller.undo,
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            controller.undo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          control: true,
          shift: true,
        ): controller.redo,
        const SingleActivator(
          LogicalKeyboardKey.keyZ,
          meta: true,
          shift: true,
        ): controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, control: true):
            controller.redo,
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true):
            controller.redo,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            _nudge(controller, const Offset(-1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            _nudge(controller, const Offset(1, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _nudge(controller, const Offset(0, -1)),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _nudge(controller, const Offset(0, 1)),
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            () => _nudge(controller, const Offset(-10, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            () => _nudge(controller, const Offset(10, 0)),
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            () => _nudge(controller, const Offset(0, -10)),
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            () => _nudge(controller, const Offset(0, 10)),
      },
      child: Focus(autofocus: true, child: child),
    );
  }
}

/// Cut: copies the selection (no history) then deletes it (one entry) —
/// ONE history entry total, so a single undo restores the cut nodes.
void _cut(LatticeController controller) {
  controller.copySelection();
  controller.deleteSelection();
}

/// Pane center in flow coordinates, or [Offset.zero] before [LatticeCanvas]
/// publishes its first layout size.
Offset _viewportCenter(LatticeController controller) {
  final Size? pane = controller.container.read(latticePaneSizeProvider);
  if (pane == null) return Offset.zero;
  return controller.screenToFlow(Offset(pane.width / 2, pane.height / 2));
}

/// Shifts every selected node by [delta] via [LatticeController.moveNodes]
/// (one history entry). Empty selection (or selection with no surviving
/// document nodes) → `moveNodes` no-ops with no history entry.
void _nudge(LatticeController controller, Offset delta) {
  final Set<String> selected =
      controller.container.read(latticeSelectionProvider).nodes;
  if (selected.isEmpty) return;
  final Map<String, LatticeNode> nodes = controller.document.nodes;
  controller.moveNodes(<String, Offset>{
    for (final String id in selected)
      if (nodes[id] case final LatticeNode node) id: node.position + delta,
  });
}
