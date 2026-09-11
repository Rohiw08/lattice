import 'package:freezed_annotation/freezed_annotation.dart';

part 'connection_state.freezed.dart';

/// Represents the runtime state during a connection drag operation.
///
/// This state is ephemeral and reflects what the user is currently doing
/// while attempting to connect two handles. It is **not persisted**.
///
/// ## Example:
/// ```
/// // Initially invalid (no target picked)
/// state = const FlowConnectionRuntimeState.idle();
///
/// // Hovering over a valid connection target
/// state = const FlowConnectionRuntimeState.hovering(
///   targetHandleKey: 'node-2/handle-input',
///   isValid: true,
/// );
///
/// // When released or cancelled
/// state = const FlowConnectionRuntimeState.idle();
/// ```
@freezed
class FlowConnectionRuntimeState with _$FlowConnectionRuntimeState {
  /// The idle state (no active connection drag).
  const factory FlowConnectionRuntimeState.idle() = IdleConnectionState;

  /// User is currently dragging a connection (potential target may exist).
  const factory FlowConnectionRuntimeState.hovering({
    required String targetHandleKey,
    @Default(false) bool isValid,
  }) = HoveringConnectionState;

  /// Connection has been dropped (completed or cancelled).
  const factory FlowConnectionRuntimeState.released({
    String? targetHandleKey,
    @Default(false) bool isValid,
  }) = ReleasedConnectionState;
}
