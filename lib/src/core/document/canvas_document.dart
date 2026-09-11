import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:flutter/foundation.dart';

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

  Map<String, dynamic> toJson() {
    return {
      'v': version,
      'state': state.toJson(),
    };
  }

  factory CanvasDocument.fromJson(Map<String, dynamic> json) {
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
      state: _decodeStateForVersion(v, stateJson),
    );
  }

  factory CanvasDocument.fromState(FlowCanvasState state) {
    return CanvasDocument(
      version: currentVersion,
      state: state,
    );
  }
}

FlowCanvasState _decodeStateForVersion(int version, Map<String, dynamic> json) {
  switch (version) {
    case 1:
    default:
      return FlowCanvasState.fromJson(json);
  }
}
