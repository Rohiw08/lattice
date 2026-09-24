import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/features/handles/domain/handle_state.dart';

class HandleController {
  final CanvasStateAccessor _controller;

  HandleController({
    required CanvasStateAccessor controller,
  }) : _controller = controller;

  /// Updates the hover state for a specific handle.
  /// This is a transient UI change and is not recorded in history.
  void setHandleHover(String handleKey, bool isHovered) {
    final currentStates = Map<String, HandleRuntimeState>.from(
        _controller.currentState.handleStates);
    final currentState = currentStates[handleKey] ?? const HandleRuntimeState();

    // Avoid unnecessary state updates if the hover state is already correct.
    if (currentState.hovered == isHovered) return;

    currentStates[handleKey] = currentState.copyWith(hovered: isHovered);

    _controller.updateStateOnly(
      _controller.currentState.copyWith(handleStates: currentStates),
    );
  }

  /// React Flow `clickconnecting` — highlight the handle chosen as click-connect source.
  void setHandleActive(String handleKey, bool isActive) {
    final currentStates = Map<String, HandleRuntimeState>.from(
        _controller.currentState.handleStates);
    final currentState = currentStates[handleKey] ?? const HandleRuntimeState();
    if (currentState.active == isActive) return;

    currentStates[handleKey] = currentState.copyWith(active: isActive);
    _controller.updateStateOnly(
      _controller.currentState.copyWith(handleStates: currentStates),
    );
  }

  /// Click-to-connect source highlight ([HandleRuntimeState.selected]).
  void setHandleSelected(String handleKey, bool isSelected) {
    final currentStates = Map<String, HandleRuntimeState>.from(
        _controller.currentState.handleStates);
    final currentState = currentStates[handleKey] ?? const HandleRuntimeState();
    if (currentState.selected == isSelected) return;

    currentStates[handleKey] = currentState.copyWith(selected: isSelected);
    _controller.updateStateOnly(
      _controller.currentState.copyWith(handleStates: currentStates),
    );
  }
}
