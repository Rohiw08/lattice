import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';
import 'package:lattice/src/features/history/application/history_controller.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_action_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:flutter/widgets.dart';

class KeyboardController {
  final CanvasStateAccessor _controller;
  final KeyboardActionService _keyboardActionService;
  final HistoryController _historyController;

  KeyboardController({
    required CanvasStateAccessor controller,
    required KeyboardActionService keyboardActionService,
    required HistoryController historyController,
  })  : _controller = controller,
        _keyboardActionService = keyboardActionService,
        _historyController = historyController;

  /// Executes a canvas action based on a keyboard event.
  void handleKeyboardAction(
    KeyboardAction action, {
    required KeyboardOptions options,
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
  }) {
    if (_controller.currentState.isPanZoomLocked) return;

    // Actions like undo/redo are handled by the HistoryController, not the service.
    if (action == KeyboardAction.undo) {
      _historyController.undo();
      return;
    }
    if (action == KeyboardAction.redo) {
      _historyController.redo();
      return;
    }

    // For all other actions, mutate the state via the service.
    _controller.mutate((s) => _keyboardActionService.handleAction(
          s,
          action,
          arrowMoveDelta:
              Offset(options.arrowKeyMoveSpeed, options.arrowKeyMoveSpeed),
          minZoom: minZoom,
          maxZoom: maxZoom,
          translateExtent: translateExtent,
          zoomStep: options.zoomStep,
        ));
  }
}
