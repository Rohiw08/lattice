import 'package:freezed_annotation/freezed_annotation.dart';

part 'handle_state.freezed.dart';

/// Runtime (ephemeral) state for a handle.
///
/// Represents interactive flags that control visuals
/// and connection logic during graph manipulation.
@freezed
abstract class HandleRuntimeState with _$HandleRuntimeState {
  const factory HandleRuntimeState({
    /// Whether the handle is being hovered over.
    @Default(false) bool hovered,

    /// Click-to-connect source (`connectOnClick` / React Flow `clickconnecting`).
    @Default(false) bool selected,

    /// Whether this handle is currently active in a connection drag.
    @Default(false) bool active,

    /// Whether the handle is a valid target for the active connection.
    @Default(false) bool validTarget,

    /// Whether the handle is an invalid target under the pointer.
    @Default(false) bool invalidTarget,

    /// The number of edges currently connected to this handle.
    @Default(0) int connectionCount,

    /// The IDs of connected edges (for fast graph lookup).
    @Default(<String>[]) List<String> connectedEdgeIds,

    /// Whether the handle is playing an animation (e.g., pulsing).
    @Default(false) bool animating,
  }) = _HandleRuntimeState;
}
