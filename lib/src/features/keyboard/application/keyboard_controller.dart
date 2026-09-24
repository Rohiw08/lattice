import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/edge_options.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/features/a11y/application/a11y_announcer.dart';
import 'package:lattice/src/features/a11y/domain/a11y_options.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/history/application/history_controller.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:flutter/services.dart';

class KeyboardController {
  final CanvasStateAccessor _controller;
  final KeyboardService _keyboardService;
  final HistoryController _historyController;
  final A11yAnnouncer _announcer;

  /// Arrow-key step multiplier while Shift is held (RF parity).
  static const double shiftMoveBoost = 5.0;

  KeyboardController({
    required CanvasStateAccessor controller,
    required KeyboardService keyboardService,
    required HistoryController historyController,
    required A11yAnnouncer announcer,
  })  : _controller = controller,
        _keyboardService = keyboardService,
        _historyController = historyController,
        _announcer = announcer;

  /// Executes a canvas action based on a keyboard event.
  void handleKeyboardAction(
    KeyboardAction action, {
    required KeyboardOptions options,
    required A11yOptions a11yOptions,
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
    Offset defaultOrigin = Offset.zero,
    NodeOptions nodeOptions = const NodeOptions(),
    EdgeOptions edgeOptions = const EdgeOptions(),
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

    final boost =
        HardwareKeyboard.instance.isShiftPressed ? shiftMoveBoost : 1.0;
    if (_isMoveAction(action)) {
      _moveWithAnnouncement(
        action,
        options: options,
        a11yOptions: a11yOptions,
        boost: boost,
        minZoom: minZoom,
        maxZoom: maxZoom,
        translateExtent: translateExtent,
        defaultOrigin: defaultOrigin,
        nodeOptions: nodeOptions,
      );
      return;
    }
    if (action == KeyboardAction.deleteSelection) {
      _deleteWithAnnouncement(
        options: options,
        a11yOptions: a11yOptions,
        minZoom: minZoom,
        maxZoom: maxZoom,
        translateExtent: translateExtent,
        nodeOptions: nodeOptions,
        edgeOptions: edgeOptions,
      );
      return;
    }

    // For all other actions, mutate the state via the service.
    _controller.mutate((s) => _keyboardService.handleAction(
          s,
          action,
          arrowMoveDelta:
              Offset(options.arrowKeyMoveSpeed, options.arrowKeyMoveSpeed),
          minZoom: minZoom,
          maxZoom: maxZoom,
          translateExtent: translateExtent,
          zoomStep: options.zoomStep,
          defaultOrigin: defaultOrigin,
          nodesDeletable: nodeOptions.deletable,
          edgesDeletable: edgeOptions.deletable,
          nodesDraggable: nodeOptions.draggable,
          expandParentDefault: nodeOptions.expandParent,
        ));
  }

  static bool _isMoveAction(KeyboardAction action) {
    return action == KeyboardAction.moveUp ||
        action == KeyboardAction.moveDown ||
        action == KeyboardAction.moveLeft ||
        action == KeyboardAction.moveRight;
  }

  static String _directionOf(KeyboardAction action) {
    return switch (action) {
      KeyboardAction.moveUp => 'up',
      KeyboardAction.moveDown => 'down',
      KeyboardAction.moveLeft => 'left',
      _ => 'right',
    };
  }

  void _moveWithAnnouncement(
    KeyboardAction action, {
    required KeyboardOptions options,
    required A11yOptions a11yOptions,
    required double boost,
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
    Offset defaultOrigin = Offset.zero,
    NodeOptions nodeOptions = const NodeOptions(),
  }) {
    final before = _controller.currentState;
    final firstId =
        before.selectedNodes.isEmpty ? null : before.selectedNodes.first;
    final beforePos =
        firstId == null ? null : before.nodes[firstId]?.position;

    _controller.mutate((s) => _keyboardService.handleAction(
          s,
          action,
          arrowMoveDelta: Offset(
            options.arrowKeyMoveSpeed * boost,
            options.arrowKeyMoveSpeed * boost,
          ),
          minZoom: minZoom,
          maxZoom: maxZoom,
          translateExtent: translateExtent,
          zoomStep: options.zoomStep,
          defaultOrigin: defaultOrigin,
          nodesDraggable: nodeOptions.draggable,
          expandParentDefault: nodeOptions.expandParent,
        ));

    final after = _controller.currentState;
    final afterPos =
        firstId == null ? null : after.nodes[firstId]?.position;
    if (a11yOptions.announcements &&
        beforePos != null &&
        afterPos != null &&
        beforePos != afterPos) {
      _announcer.announce(
        a11yOptions.labels
            .nodeMoved(_directionOf(action), afterPos.dx, afterPos.dy),
      );
    }
  }

  void _deleteWithAnnouncement({
    required KeyboardOptions options,
    required A11yOptions a11yOptions,
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
    NodeOptions nodeOptions = const NodeOptions(),
    EdgeOptions edgeOptions = const EdgeOptions(),
  }) {
    final before = _controller.currentState;
    if (before.selectedNodes.isEmpty && before.selectedEdges.isEmpty) return;

    // Route user-intent Delete through deleteElements so the veto gate
    // (onBeforeDelete) and onDelete fire exactly like RF's deleteKeyCode
    // path — still a single undo step.
    final internal = _controller;
    if (internal is FlowCanvasInternalController) {
      final deleted = internal.deleteElements(
        nodeIds: before.selectedNodes,
        edgeIds: before.selectedEdges,
      );
      if (a11yOptions.announcements && deleted.isNotEmpty) {
        _announcer.announce(
          a11yOptions.labels
              .selectionDeleted(deleted.nodes.length + deleted.edges.length),
        );
      }
      return;
    }

    _controller.mutate((s) => _keyboardService.handleAction(
          s,
          KeyboardAction.deleteSelection,
          arrowMoveDelta:
              Offset(options.arrowKeyMoveSpeed, options.arrowKeyMoveSpeed),
          minZoom: minZoom,
          maxZoom: maxZoom,
          translateExtent: translateExtent,
          zoomStep: options.zoomStep,
          nodesDeletable: nodeOptions.deletable,
          edgesDeletable: edgeOptions.deletable,
        ));

    if (a11yOptions.announcements) {
      final after = _controller.currentState;
      final removed = (before.nodes.length - after.nodes.length) +
          (before.edges.length - after.edges.length);
      if (removed > 0) {
        _announcer.announce(
          a11yOptions.labels.selectionDeleted(removed),
        );
      }
    }
  }
}
