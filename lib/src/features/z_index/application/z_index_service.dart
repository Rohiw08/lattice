import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';

class ZIndexService {
  FlowCanvasState bringToFront(FlowCanvasState state, String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null) return state;

    final newZIndex = state.maxZIndex + 1;

    final updatedNodes = Map<String, FlowNode>.from(state.nodes)
      ..[nodeId] = node.copyWith(zIndex: newZIndex);

    return state.copyWith(
      nodes: updatedNodes,
      maxZIndex: newZIndex,
      zOrderEpoch: state.zOrderEpoch + 1,
    );
  }

  /// Send a node to back in O(1) using cached minZIndex
  FlowCanvasState sendToBack(FlowCanvasState state, String nodeId) {
    final node = state.nodes[nodeId];
    if (node == null) return state;

    final newZIndex = state.minZIndex - 1;

    final updatedNodes = Map<String, FlowNode>.from(state.nodes)
      ..[nodeId] = node.copyWith(zIndex: newZIndex);

    return state.copyWith(
      nodes: updatedNodes,
      minZIndex: newZIndex,
      zOrderEpoch: state.zOrderEpoch + 1,
    );
  }

  /// Bring selected nodes to front in O(S) (S = # of selected nodes)
  FlowCanvasState bringSelectedToFront(FlowCanvasState state) {
    if (state.nodes.isEmpty || state.selectedNodes.isEmpty) return state;

    final updatedNodes = Map<String, FlowNode>.from(state.nodes);
    int zIndex = state.maxZIndex + 1;

    for (final nodeId in state.selectedNodes) {
      final node = updatedNodes[nodeId];
      if (node != null) {
        updatedNodes[nodeId] = node.copyWith(zIndex: zIndex++);
      }
    }

    return state.copyWith(
      nodes: updatedNodes,
      maxZIndex: zIndex - 1,
      zOrderEpoch: state.zOrderEpoch + 1,
    );
  }

  /// Send selected nodes to back in O(S)
  FlowCanvasState sendSelectedToBack(FlowCanvasState state) {
    if (state.nodes.isEmpty || state.selectedNodes.isEmpty) return state;

    final updatedNodes = Map<String, FlowNode>.from(state.nodes);
    int zIndex = state.minZIndex - state.selectedNodes.length;

    for (final nodeId in state.selectedNodes) {
      final node = updatedNodes[nodeId];
      if (node != null) {
        updatedNodes[nodeId] = node.copyWith(zIndex: zIndex++);
      }
    }

    return state.copyWith(
      nodes: updatedNodes,
      minZIndex: zIndex - state.selectedNodes.length,
      zOrderEpoch: state.zOrderEpoch + 1,
    );
  }
}
