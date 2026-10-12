import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Currently selected node and edge ids.
///
/// Session state (not document state), so selection never lands in
/// undo stacks, serialization, or sync payloads.
@immutable
class LatticeSelection {
  const LatticeSelection({
    this.nodes = const {},
    this.edges = const {},
  });

  final Set<String> nodes;
  final Set<String> edges;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty;

  LatticeSelection copyWith({Set<String>? nodes, Set<String>? edges}) {
    return LatticeSelection(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeSelection &&
        _setsEqual(other.nodes, nodes) &&
        _setsEqual(other.edges, edges);
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(nodes),
        Object.hashAllUnordered(edges),
      );
}

/// Transient drag gesture state.
///
/// Deliberately a single extensible class (not sealed): new variants
/// (e.g. connect) add a constructor without breaking existing consumers,
/// which branch on [isActive] plus the payload they need instead of
/// exhaustive switches.
@immutable
class LatticeDragState {
  const LatticeDragState.idle()
      : ids = const {},
        livePositions = const {},
        rect = null,
        _active = false;

  const LatticeDragState.node({
    required this.ids,
    required this.livePositions,
  })  : rect = null,
        _active = true;

  const LatticeDragState.marquee({required this.rect})
      : ids = const {},
        livePositions = const {},
        _active = true;

  /// Ids being dragged (node variant).
  final Set<String> ids;

  /// Per-frame pointer-driven positions (node variant).
  final Map<String, Offset> livePositions;

  /// Current selection rectangle (marquee variant).
  final Rect? rect;

  final bool _active;

  bool get isActive => _active;
}

bool _setsEqual(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
