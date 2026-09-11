import 'package:lattice/src/core/state/flow_canvas_state.dart';

/// Narrow interface for reading and writing canvas state.
///
/// Sub-controllers depend on this abstraction instead of the full
/// [FlowCanvasInternalController], following the Dependency Inversion
/// Principle (SOLID-D). This decouples sub-controllers from the
/// concrete orchestrator and makes them independently testable.
///
/// The two write methods provide distinct semantics:
/// - [mutate]: records changes in undo/redo history
/// - [updateStateOnly]: applies transient/intermediate changes without history
abstract class CanvasStateAccessor {
  /// The current, immutable state of the canvas.
  FlowCanvasState get currentState;

  /// Applies a mutation and records the resulting state in undo/redo history.
  ///
  /// Use this for user-visible, undoable changes (e.g., adding a node,
  /// deleting an edge, completing a drag).
  void mutate(FlowCanvasState Function(FlowCanvasState) mutation);

  /// Updates the state WITHOUT recording in history.
  ///
  /// Use this for transient/intermediate changes that should not be
  /// individually undoable (e.g., mid-drag position updates, hover states,
  /// viewport panning).
  void updateStateOnly(FlowCanvasState newState);

  /// Pushes the current state as an undo checkpoint without mutating.
  ///
  /// Use when the graph was already updated via [updateStateOnly] (e.g. after
  /// a completed node drag) so the user can undo to the prior checkpoint.
  void commitHistoryCheckpoint();
}
