import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/core/utils/json_converters.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/foundation.dart';

/// `{ nodes, edges, viewport }` snapshot (React Flow `ReactFlowJsonObject`).
typedef ReactFlowJsonObject = ({
  List<FlowNode> nodes,
  List<FlowEdge> edges,
  FlowViewport viewport,
});

/// Versioned file envelope for persisting a canvas graph.
///
/// Add migrations by branching on [version] in [fromJson].
@immutable
class CanvasDocument {
  const CanvasDocument({
    required this.version,
    required this.state,
  });

  static const int currentVersion = 1;

  final int version;
  final FlowCanvasState state;

  Map<String, dynamic> toJson([NodeDataToJson? encodeData]) {
    return {
      'v': version,
      'state': state.toJson(encodeData),
    };
  }

  factory CanvasDocument.fromJson(
    Map<String, dynamic> json, [
    NodeDataFromJson? decodeData,
  ]) {
    final v = (json['v'] as num?)?.toInt() ?? currentVersion;
    final stateJson = json['state'] as Map<String, dynamic>?;
    if (stateJson == null) {
      return CanvasDocument(
        version: v,
        state: FlowCanvasState.initial(),
      );
    }
    return CanvasDocument(
      version: v,
      state: _decodeStateForVersion(v, stateJson, decodeData),
    );
  }

  factory CanvasDocument.fromState(FlowCanvasState state) {
    return CanvasDocument(
      version: currentVersion,
      state: state,
    );
  }
}

FlowCanvasState _decodeStateForVersion(
  int version,
  Map<String, dynamic> json, [
  NodeDataFromJson? decodeData,
]) {
  switch (version) {
    case 1:
    default:
      return FlowCanvasState.fromJson(json, decodeData);
  }
}
