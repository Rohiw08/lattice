import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:lattice/src/features/edges/domain/edge_index.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:flutter/painting.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/edges/domain/edge_state.dart';

/// A stateless service for handling business logic related to selection.
class SelectionService {
  /// Returns list of selected nodes (full models).
  List<FlowNode> getSelectedNodes(FlowCanvasState state) =>
      state.selectedNodes.map((id) => state.nodes[id]!).toList();

  /// Returns list of selected Edges (full models).
  List<FlowEdge> getSelectedEdges(FlowCanvasState state) =>
      state.selectedEdges.map((id) => state.edges[id]!).toList();

  /// Adds a node to the selection without deselecting others.
  /// If already selected, does nothing.
  FlowCanvasState addNodeToSelection(FlowCanvasState state, String nodeId) {
    if (state.selectedNodes.contains(nodeId)) return state;
    final newSelectedNodes = {...state.selectedNodes, nodeId};
    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    newNodeStates[nodeId] = (newNodeStates[nodeId] ?? const NodeRuntimeState())
        .copyWith(selected: true);
    return state.copyWith(
      selectedNodes: newSelectedNodes,
      nodeStates: newNodeStates,
    );
  }

  /// Removes a node from the selection without touching others.
  FlowCanvasState removeNodeFromSelection(FlowCanvasState state, String nodeId) {
    if (!state.selectedNodes.contains(nodeId)) return state;
    final newSelectedNodes = {...state.selectedNodes}..remove(nodeId);
    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    newNodeStates[nodeId] = (newNodeStates[nodeId] ?? const NodeRuntimeState())
        .copyWith(selected: false);
    return state.copyWith(
      selectedNodes: newSelectedNodes,
      nodeStates: newNodeStates,
    );
  }

  /// Similar for edges.
  FlowCanvasState addEdgeToSelection(FlowCanvasState state, String edgeId) {
    if (state.selectedEdges.contains(edgeId)) return state;
    final newSelectedEdges = {...state.selectedEdges, edgeId};
    final newEdgeStates = Map<String, EdgeRuntimeState>.from(state.edgeStates);
    newEdgeStates[edgeId] = (newEdgeStates[edgeId] ?? const EdgeRuntimeState())
        .copyWith(selected: true);
    return state.copyWith(
      selectedEdges: newSelectedEdges,
      edgeStates: newEdgeStates,
    );
  }

  /// Removes an edge from the selection without touching others.
  FlowCanvasState removeEdgeFromSelection(FlowCanvasState state, String edgeId) {
    if (!state.selectedEdges.contains(edgeId)) return state;
    final newSelectedEdges = {...state.selectedEdges}..remove(edgeId);
    final newEdgeStates = Map<String, EdgeRuntimeState>.from(state.edgeStates);
    newEdgeStates[edgeId] = (newEdgeStates[edgeId] ?? const EdgeRuntimeState())
        .copyWith(selected: false);
    return state.copyWith(
      selectedEdges: newSelectedEdges,
      edgeStates: newEdgeStates,
    );
  }

  /// Selects / toggles a node.
  ///
  /// Lattice rules:
  /// - [addToSelection] true (multi-select key held): add if unselected, remove
  ///   if selected; leave other selections alone.
  /// - [addToSelection] false: replace selection with this node. Re-clicking an
  ///   already-selected node is a no-op (does not clear selection).
  FlowCanvasState toggleNodeSelection(
    FlowCanvasState state,
    String nodeId, {
    bool addToSelection = false,
  }) {
    final isAlreadySelected = state.selectedNodes.contains(nodeId);

    if (addToSelection) {
      if (isAlreadySelected) {
        return removeNodeFromSelection(state, nodeId);
      }
      return addNodeToSelection(state, nodeId);
    }

    // Exclusive: already selected → keep current selection (Lattice).
    if (isAlreadySelected) return state;

    final deselectedState = deselectAll(state);
    final newNodeStates =
        Map<String, NodeRuntimeState>.from(deselectedState.nodeStates);
    newNodeStates[nodeId] = (newNodeStates[nodeId] ?? const NodeRuntimeState())
        .copyWith(selected: true);

    return deselectedState.copyWith(
      selectedNodes: {nodeId},
      nodeStates: newNodeStates,
    );
  }

  /// Selects / toggles an edge (same Lattice multi vs exclusive rules as nodes).
  FlowCanvasState toggleEdgeSelection(
    FlowCanvasState state,
    String edgeId, {
    bool addToSelection = false,
  }) {
    final isAlreadySelected = state.selectedEdges.contains(edgeId);

    if (addToSelection) {
      if (isAlreadySelected) {
        return removeEdgeFromSelection(state, edgeId);
      }
      return addEdgeToSelection(state, edgeId);
    }

    if (isAlreadySelected) return state;

    final deselectedState = deselectAll(state);
    final newEdgeStates =
        Map<String, EdgeRuntimeState>.from(deselectedState.edgeStates);
    newEdgeStates[edgeId] = (newEdgeStates[edgeId] ?? const EdgeRuntimeState())
        .copyWith(selected: true);

    return deselectedState.copyWith(
      selectedEdges: {edgeId},
      edgeStates: newEdgeStates,
    );
  }

  // The methods below are for multi-selection, which you may want to disable or keep.
  // For now, they remain but the primary toggle methods enforce single selection.
  FlowCanvasState selectAll(
    FlowCanvasState state, {
    bool nodes = true,
    bool edges = true,
  }) {
    final newSelectedNodes = nodes ? state.nodes.keys.toSet() : <String>{};
    final newSelectedEdges = edges ? state.edges.keys.toSet() : <String>{};

    final newNodeStates = <String, NodeRuntimeState>{};
    for (final id in newSelectedNodes) {
      final existing = state.nodeStates[id];
      newNodeStates[id] = existing?.copyWith(selected: true) ??
          const NodeRuntimeState(selected: true);
    }

    final newEdgeStates = <String, EdgeRuntimeState>{};
    for (final id in newSelectedEdges) {
      final existing = state.edgeStates[id];
      newEdgeStates[id] = existing?.copyWith(selected: true) ??
          const EdgeRuntimeState(selected: true);
    }

    return state.copyWith(
      selectedNodes: newSelectedNodes,
      selectedEdges: newSelectedEdges,
      nodeStates: newNodeStates,
      edgeStates: newEdgeStates,
    );
  }

  /// Deselects all nodes and edges. This is now the primary helper for ensuring a clean slate.
  FlowCanvasState deselectAll(FlowCanvasState state) {
    if (state.selectedNodes.isEmpty && state.selectedEdges.isEmpty) {
      return state;
    }

    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    for (final nodeId in state.selectedNodes) {
      newNodeStates[nodeId] =
          (newNodeStates[nodeId] ?? const NodeRuntimeState())
              .copyWith(selected: false);
    }
    final newEdgeStates = Map<String, EdgeRuntimeState>.from(state.edgeStates);
    for (final edgeId in state.selectedEdges) {
      newEdgeStates[edgeId] =
          (newEdgeStates[edgeId] ?? const EdgeRuntimeState())
              .copyWith(selected: false);
    }

    return state.copyWith(
      selectedNodes: {},
      selectedEdges: {},
      nodeStates: newNodeStates,
      edgeStates: newEdgeStates,
    );
  }

  FlowCanvasState startBoxSelection(FlowCanvasState state, Offset position) {
    return deselectAll(state).copyWith(
      selectionRect: Rect.fromPoints(position, position),
    );
  }

  FlowCanvasState updateBoxSelection(
    FlowCanvasState state,
    Offset origin,
    Offset position,
    NodeIndex nodeIndex,
    EdgeIndex edgeIndex, {
    SelectionMode selectionMode = SelectionMode.full,
    Offset defaultOrigin = Offset.zero,
    bool nodesSelectable = true,
    bool edgesSelectable = true,
  }) {
    final newSelectionRect = Rect.fromPoints(origin, position);
    var newSelectedNodes = nodeIndex.queryNodesInRect(newSelectionRect);

    // Unselectable nodes never join a marquee (Lattice `selectable`).
    newSelectedNodes = newSelectedNodes.where((id) {
      final node = state.nodes[id];
      return node != null && (node.selectable ?? nodesSelectable);
    }).toSet();

    if (selectionMode == SelectionMode.full) {
      newSelectedNodes = newSelectedNodes.where((id) {
        final node = state.nodes[id];
        if (node == null) return false;
        final abs = NodeLayout.absoluteRect(node, state.nodes,
            defaultOrigin: defaultOrigin);
        return newSelectionRect.left <= abs.left &&
            newSelectionRect.top <= abs.top &&
            newSelectionRect.right >= abs.right &&
            newSelectionRect.bottom >= abs.bottom;
      }).toSet();
    }

    final edgesInArea = <String>{};
    for (final nodeId in newSelectedNodes) {
      final connectedEdges = edgeIndex.getEdgesForNode(nodeId);
      for (final edgeId in connectedEdges) {
        final edge = state.edges[edgeId];
        if (edge != null &&
            (edge.selectable ?? edgesSelectable) &&
            newSelectedNodes.contains(edge.sourceNodeId) &&
            newSelectedNodes.contains(edge.targetNodeId)) {
          edgesInArea.add(edgeId);
        }
      }
    }
    final newSelectedEdges = edgesInArea;

    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    final newEdgeStates = Map<String, EdgeRuntimeState>.from(state.edgeStates);

    for (final oldSelectedId in state.selectedNodes) {
      if (!newSelectedNodes.contains(oldSelectedId)) {
        newNodeStates[oldSelectedId] =
            (newNodeStates[oldSelectedId] ?? const NodeRuntimeState())
                .copyWith(selected: false);
      }
    }

    for (final newSelectedId in newSelectedNodes) {
      newNodeStates[newSelectedId] =
          (newNodeStates[newSelectedId] ?? const NodeRuntimeState())
              .copyWith(selected: true);
    }

    for (final oldSelectedId in state.selectedEdges) {
      if (!newSelectedEdges.contains(oldSelectedId)) {
        newEdgeStates[oldSelectedId] =
            (newEdgeStates[oldSelectedId] ?? const EdgeRuntimeState())
                .copyWith(selected: false);
      }
    }
    for (final newSelectedId in newSelectedEdges) {
      newEdgeStates[newSelectedId] =
          (newEdgeStates[newSelectedId] ?? const EdgeRuntimeState())
              .copyWith(selected: true);
    }

    return state.copyWith(
      selectionRect: newSelectionRect,
      selectedNodes: newSelectedNodes.toSet(),
      selectedEdges: newSelectedEdges,
      nodeStates: newNodeStates,
      edgeStates: newEdgeStates,
    );
  }

  FlowCanvasState endBoxSelection(FlowCanvasState state) {
    return state.copyWith(
      selectionRect: Rect.zero,
    );
  }
}
