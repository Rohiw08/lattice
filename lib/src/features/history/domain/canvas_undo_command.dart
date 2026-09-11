import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:flutter/painting.dart';

/// Base type for compact undo steps (e.g. node position batches).
///
/// The default [HistoryService] records full [FlowCanvasState] snapshots; this
/// type is the extension point for future command-based history to avoid
/// cloning very large graphs on every edit.
abstract class CanvasUndoCommand {
  const CanvasUndoCommand();

  /// Graph state to restore when the user undoes this step (viewport is merged
  /// in [HistoryController] when appropriate).
  FlowCanvasState applyUndo(FlowCanvasState current);
}

/// Sets a batch of node positions in one immutable update (for custom undo hosts).
class NodePositionUndoCommand extends CanvasUndoCommand {
  NodePositionUndoCommand(this.targetPositions);

  final Map<String, Offset> targetPositions;

  @override
  FlowCanvasState applyUndo(FlowCanvasState current) {
    var s = current;
    for (final e in targetPositions.entries) {
      final n = s.nodes[e.key];
      if (n == null) continue;
      s = s.copyWith(
        nodes: {
          ...s.nodes,
          e.key: n.copyWith(position: e.value),
        },
      );
    }
    return s;
  }
}
