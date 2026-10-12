import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'lattice_edge.dart';

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
        from = null,
        liveEnd = null,
        reconnectEdgeId = null,
        _active = false;

  const LatticeDragState.node({
    required this.ids,
    required this.livePositions,
  })  : rect = null,
        from = null,
        liveEnd = null,
        reconnectEdgeId = null,
        _active = true;

  const LatticeDragState.marquee({required this.rect})
      : ids = const {},
        livePositions = const {},
        from = null,
        liveEnd = null,
        reconnectEdgeId = null,
        _active = true;

  const LatticeDragState.connect({
    required LatticeEndpoint from,
    required Offset liveEnd,
    this.reconnectEdgeId,
  })  : from = from,
        liveEnd = liveEnd,
        ids = const {},
        livePositions = const {},
        rect = null,
        _active = true;

  /// Ids being dragged (node variant).
  final Set<String> ids;

  /// Per-frame pointer-driven positions (node variant).
  final Map<String, Offset> livePositions;

  /// Current selection rectangle (marquee variant).
  final Rect? rect;

  /// Connection origin (connect variant; null otherwise).
  final LatticeEndpoint? from;

  /// Live pointer position of the in-progress connection (connect variant).
  final Offset? liveEnd;

  /// Edge being reconnected, or null for fresh connects (connect variant).
  final String? reconnectEdgeId;

  final bool _active;

  bool get isActive => _active;
}

bool _setsEqual(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
