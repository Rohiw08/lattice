// application/services/history_service.dart

import 'package:flutter/foundation.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';

/// Linear undo/redo as full state checkpoints. For large graphs, prefer future
/// compact steps (`canvas_undo_command.dart`).
class HistoryService {
  final List<FlowCanvasState> _undoStack = <FlowCanvasState>[];
  final List<FlowCanvasState> _redoStack = <FlowCanvasState>[];

  // The maximum number of history states to keep.
  final int limit;

  HistoryService({this.limit = 50});

  /// The current state in the history.
  FlowCanvasState? get current =>
      _undoStack.isNotEmpty ? _undoStack.last : null;

  /// Initialize history with a starting state.
  void init(FlowCanvasState initial) {
    clear();
    _undoStack.add(initial);
  }

  /// Pushes a new state onto the history stack.
  void record(FlowCanvasState newState) {
    // If the new state is identical to the current one, do nothing.
    if (_undoStack.isNotEmpty && newState == _undoStack.last) return;

    _undoStack.add(newState);
    _redoStack.clear(); // A new action clears the redo stack.

    // Enforce the history limit.
    if (limit > 0 && _undoStack.length > limit) {
      _undoStack.removeAt(0);
    }
  }

  /// Undo to the previous state. Returns the new current state.
  FlowCanvasState? undo() {
    if (_undoStack.length <= 1) return null;
    final currentState = _undoStack.removeLast();
    _redoStack.add(currentState);
    return _undoStack.last;
  }

  /// Redo to the next state. Returns the new current state.
  FlowCanvasState? redo() {
    if (_redoStack.isEmpty) return null;

    final nextState = _redoStack.removeLast();
    _undoStack.add(nextState);

    return nextState;
  }

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  @visibleForTesting
  (int undo, int redo) get lengths => (_undoStack.length, _redoStack.length);
}
