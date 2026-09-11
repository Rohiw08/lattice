import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:flutter/painting.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/core/utils/random_id_generator.dart';

/// Service to handle copy/paste operations for nodes (and their connected edges).
class ClipboardService {
  /// Copies selected nodes and returns a transferable payload.
  Map<String, dynamic> copy(FlowCanvasState state) {
    final nodeIds = state.selectedNodes.toList();
    final nodes =
        nodeIds.map((id) => state.nodes[id]).whereType<FlowNode>().toList();

    // Include edges only if both ends are selected
    final edges = state.edges.values.where((e) {
      return nodeIds.contains(e.sourceNodeId) &&
          nodeIds.contains(e.targetNodeId);
    }).toList();

    return {
      'nodes': nodes,
      'edges': edges,
    };
  }

  /// Pastes previously copied nodes/edges, remaps IDs, and offsets positions.
  /// Pastes previously copied nodes/edges, remaps IDs, and offsets positions.
  FlowCanvasState paste(
    FlowCanvasState state,
    Map<String, dynamic> payload, {
    Offset positionOffset = const Offset(40, 40),
    // You will need access to NodeService and EdgeService
    required NodeService nodeService,
    required EdgeService edgeService,
  }) {
    final originalNodes = (payload['nodes'] as List<dynamic>? ?? const [])
        .whereType<FlowNode>()
        .toList();
    final originalEdges = (payload['edges'] as List<dynamic>? ?? const [])
        .whereType<FlowEdge>()
        .toList();

    if (originalNodes.isEmpty) return state;

    final idMap = <String, String>{};
    final List<FlowNode> newNodes = [];
    final List<FlowEdge> newEdges = [];

    // Prepare new nodes with new IDs and positions
    for (final node in originalNodes) {
      final newId = IdGenerator.generateNodeId();
      idMap[node.id] = newId;
      // Lattice copy/paste: remap parentId when the parent was copied too,
      // otherwise detach the child (parentId becomes null).
      final parentRemapped = node.parentId != null &&
              idMap.containsKey(node.parentId)
          ? idMap[node.parentId]
          : null;
      newNodes.add(node.copyWith(
        id: newId,
        parentId: parentRemapped,
        position: node.position + positionOffset,
      ));
    }

    // Prepare new edges with remapped source/target IDs
    for (final edge in originalEdges) {
      final newSource = idMap[edge.sourceNodeId];
      final newTarget = idMap[edge.targetNodeId];
      if (newSource == null || newTarget == null) continue;

      final newId = IdGenerator.generateEdgeId();
      newEdges.add(edge.copyWith(
        id: newId,
        sourceNodeId: newSource,
        targetNodeId: newTarget,
      ));
    }

    // Use the services to add the new elements to the state
    // This ensures the indexes are updated correctly.
    FlowCanvasState newState = state;
    newState = nodeService.addNodes(newState, newNodes);
    newState = edgeService.addEdges(newState, newEdges);
    return newState;
  }
}
