import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/options/flow_options.dart';

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ResetZoomIntent extends Intent {
  const ResetZoomIntent();
}

class FitViewIntent extends Intent {
  const FitViewIntent();
}

class SelectAllIntent extends Intent {
  final bool selectNodes;
  final bool selectEdges;
  const SelectAllIntent({
    this.selectNodes = true,
    this.selectEdges = true,
  });
}

class DeselectAllIntent extends Intent {
  const DeselectAllIntent();
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class DuplicateIntent extends Intent {
  const DuplicateIntent();
}

/// Arrow-key nudge. Handled through [KeyboardController] so Shift-boost and
/// live-region announcements apply uniformly.
class MoveIntent extends Intent {
  final KeyboardAction direction;
  const MoveIntent(this.direction);
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

/// Maps a user-configured [KeyboardAction] to the intent dispatched through
/// the framework [Shortcuts] pipeline, so custom bindings and built-ins
/// share one matching engine and one guarded execution path.
Intent intentForKeyboardAction(KeyboardAction action) {
  return switch (action) {
    KeyboardAction.moveUp ||
    KeyboardAction.moveDown ||
    KeyboardAction.moveLeft ||
    KeyboardAction.moveRight =>
      MoveIntent(action),
    KeyboardAction.deleteSelection => const DeleteIntent(),
    KeyboardAction.selectAll => const SelectAllIntent(),
    KeyboardAction.deselectAll => const DeselectAllIntent(),
    KeyboardAction.duplicateSelection => const DuplicateIntent(),
    KeyboardAction.zoomIn => const ZoomInIntent(),
    KeyboardAction.zoomOut => const ZoomOutIntent(),
    KeyboardAction.resetZoom => const ResetZoomIntent(),
    KeyboardAction.undo => const UndoIntent(),
    KeyboardAction.redo => const RedoIntent(),
  };
}

/// Decorates a canvas [Action] so it never fires while a text field holds
/// primary focus (RF: ignore keydown from inputs/textareas).
///
/// Checked synchronously at invoke time from live focus state — deliberately
/// not implemented by swapping the shortcuts map on focus change, which
/// leaves a window (focus already moved, rebuild not yet run) where canvas
/// bindings are still live and a keystroke deletes the selection instead of
/// editing text. Disabled actions report [KeyEventResult.ignored], so the
/// bubble continues to the app-level text intents and the field edits
/// normally; canvas behavior is untouched when nothing is being edited.
class EditingGuardAction<T extends Intent> extends Action<T> {
  EditingGuardAction(this.inner);

  final Action<T> inner;

  static bool _editing() {
    final primary = FocusManager.instance.primaryFocus;
    final context = primary?.context;
    if (context == null) return false;
    if (context.widget is EditableText) return true;
    var editing = false;
    context.visitAncestorElements((element) {
      if (element.widget is EditableText) editing = true;
      return !editing;
    });
    return editing;
  }

  @override
  bool isEnabled(T intent) => !_editing() && inner.isEnabled(intent);

  @override
  Object? invoke(T intent) {
    if (_editing()) return null;
    return inner.invoke(intent);
  }
}

Map<Type, Action<Intent>> buildActions(
  FlowCanvasInternalController controller,
  FlowCanvasOptions options,
) {
  final kb = options.keyboardOptions;
  final vp = options.viewportOptions;
  void keyboard(KeyboardAction action) {
    controller.keyboard.handleKeyboardAction(
      action,
      options: kb,
      a11yOptions: options.a11yOptions,
      minZoom: vp.minZoom,
      maxZoom: vp.maxZoom,
      translateExtent: vp.translateExtent,
      defaultOrigin: options.nodeOptions.nodeOrigin,
      nodeOptions: options.nodeOptions,
      edgeOptions: options.edgeOptions,
    );
  }

  final actions = <Type, Action<Intent>>{
    ZoomInIntent: CallbackAction<ZoomInIntent>(      onInvoke: (_) {
        controller.viewport.zoomAtViewportCenter(
          zoomIn: true,
          minZoom: vp.minZoom,
          maxZoom: vp.maxZoom,
        );
        return null;
      },
    ),
    ZoomOutIntent: CallbackAction<ZoomOutIntent>(
      onInvoke: (_) {
        controller.viewport.zoomAtViewportCenter(
          zoomIn: false,
          minZoom: vp.minZoom,
          maxZoom: vp.maxZoom,
        );
        return null;
      },
    ),
    ResetZoomIntent: CallbackAction<ResetZoomIntent>(
      onInvoke: (_) {
        keyboard(KeyboardAction.resetZoom);
        return null;
      },
    ),
    FitViewIntent: CallbackAction<FitViewIntent>(
      onInvoke: (_) {
        controller.viewport.fitView(
          viewportOptions: vp,
          fitviewOptions: vp.fitViewOptions,
        );
        return null;
      },
    ),
    SelectAllIntent: CallbackAction<SelectAllIntent>(
      onInvoke: (intent) {
        controller.selection.selectAll(
          nodes: intent.selectNodes,
          edges: intent.selectEdges,
        );
        return null;
      },
    ),
    DeselectAllIntent: CallbackAction<DeselectAllIntent>(
      onInvoke: (_) {
        controller.selection.deselectAll();
        return null;
      },
    ),
    // Single undoable step (see KeyboardActionService.deleteSelection).
    DeleteIntent: CallbackAction<DeleteIntent>(
      onInvoke: (_) {
        keyboard(KeyboardAction.deleteSelection);
        return null;
      },
    ),
    DuplicateIntent: CallbackAction<DuplicateIntent>(
      onInvoke: (_) {
        keyboard(KeyboardAction.duplicateSelection);
        return null;
      },
    ),
    MoveIntent: CallbackAction<MoveIntent>(
      onInvoke: (intent) {
        keyboard(intent.direction);
        return null;
      },
    ),
    UndoIntent: CallbackAction<UndoIntent>(
      onInvoke: (_) {
        controller.history.undo();
        return null;
      },
    ),
    RedoIntent: CallbackAction<RedoIntent>(
      onInvoke: (_) {
        controller.history.redo();
        return null;
      },
    ),
    CopyIntent: CallbackAction<CopyIntent>(
      onInvoke: (_) {
        controller.clipboard.copySelection();
        return null;
      },
    ),
    PasteIntent: CallbackAction<PasteIntent>(
      onInvoke: (_) {
        controller.clipboard.paste();
        return null;
      },
    ),
  };

  // Every canvas action goes through the editing guard: no per-action
  // boilerplate, no focus-change rebuilds, no race window.
  return actions.map(
    (type, action) => MapEntry(type, EditingGuardAction<Intent>(action)),
  );
}
