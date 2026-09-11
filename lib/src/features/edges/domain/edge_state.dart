import 'package:freezed_annotation/freezed_annotation.dart';

part 'edge_state.freezed.dart';

/// Runtime (transient) state for an individual edge.
///
/// These flags control how the edge behaves and renders in real time,
/// such as hover, selection, reconnection, or animation feedback.
///
/// This is not serialized — purely for UI runtime state tracking only.
@freezed
abstract class EdgeRuntimeState with _$EdgeRuntimeState {
  const factory EdgeRuntimeState({
    /// Whether this edge is currently valid (e.g., connection rules pass).
    @Default(true) bool valid,

    /// Whether the edge is highlighted as selected.
    @Default(false) bool selected,

    /// Whether the edge is being hovered over (UI effect trigger).
    @Default(false) bool hovered,

    /// Whether the edge has an active animation effect running.
    @Default(false) bool animating,

    /// Whether the edge is currently being reconnected to another node.
    @Default(false) bool reconnecting,
  }) = _EdgeRuntimeState;
}
