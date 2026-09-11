import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/painting.dart';

/// Builds a dense grid of nodes (and optional chain edges) for stress / benchmark
/// harnesses. Use with [FlowCanvas.initialState] or [FlowCanvasController.load].
FlowCanvasState buildSyntheticGrid({
  int cols = 32,
  int rows = 32,
  double spacingX = 220,
  double spacingY = 120,
  Size nodeSize = const Size(150, 80),
  String nodeType = 'default',
  bool withChainEdges = false,
}) {
  final nodes = <String, FlowNode>{};
  final edges = <String, FlowEdge>{};
  var z = 0;
  String? prevId;
  for (var j = 0; j < rows; j++) {
    for (var i = 0; i < cols; i++) {
      final id = 'n_${i}_$j';
      nodes[id] = FlowNode.create(
        id: id,
        type: nodeType,
        position: Offset(i * spacingX, j * spacingY),
        size: nodeSize,
        data: const {},
        zIndex: z++,
      );
      if (withChainEdges && prevId != null) {
        final eid = 'e_${prevId}_$id';
        edges[eid] = FlowEdge(
          id: eid,
          sourceNodeId: prevId,
          targetNodeId: id,
        );
      }
      prevId = id;
    }
  }
  return FlowCanvasState.initial().copyWith(nodes: nodes, edges: edges);
}
