// application/services/history_service.dart

import 'package:flutter/foundation.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Linear undo/redo as full state checkpoints.
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

  /// Rebases stored snapshots onto a remote graph change so undo/redo never
  /// lose collaborator work.
  ///
  /// Called by `applyRemote` with the remote DELTA (not the full graph):
  /// every undo/redo entry drops remotely-removed ids and takes remote
  /// values for added/changed ids (remote wins on conflict —
  /// last-writer-wins per sync arrival). Undo then means "undo my op on top
  /// of the shared graph" instead of time-traveling to a stale snapshot
  /// that vaporizes a peer's work. Full maps would bake my own uncommitted
  /// work into every entry and make it un-undoable — hence delta-only.
  void rebaseRemote({
    required Set<String> removedNodeIds,
    required Map<String, FlowNode> remoteNodes,
    required Set<String> removedEdgeIds,
    required Map<String, FlowEdge> remoteEdges,
  }) {
    FlowCanvasState rebaseOne(FlowCanvasState entry) {
      final nodes = Map<String, FlowNode>.of(entry.nodes)
        ..removeWhere((id, _) => removedNodeIds.contains(id))
        ..addAll(remoteNodes);
      final edges = Map<String, FlowEdge>.of(entry.edges)
        ..removeWhere((id, _) => removedEdgeIds.contains(id))
        ..addAll(remoteEdges);
      return entry.copyWith(nodes: nodes, edges: edges);
    }

    for (var i = 0; i < _undoStack.length; i++) {
      _undoStack[i] = rebaseOne(_undoStack[i]);
    }
    for (var i = 0; i < _redoStack.length; i++) {
      _redoStack[i] = rebaseOne(_redoStack[i]);
    }
  }

  /// Clears all history.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }

  @visibleForTesting
  (int undo, int redo) get lengths => (_undoStack.length, _redoStack.length);
}
