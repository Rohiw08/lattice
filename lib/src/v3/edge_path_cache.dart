import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'edge_paths.dart';
import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';

/// Caches one rendered [Path] per edge id, recomputed incrementally.
///
/// [syncTo] recomputes only edges that are new, explicitly invalidated via
/// [invalidateEdges], or whose resolved endpoint anchors (or edge type)
/// changed since the last sync; paths for removed edges — or edges whose
/// endpoints no longer exist — are dropped. [recomputeCount] increments
/// per recomputed path (cheap test instrumentation).
class EdgePathCache {
  final Map<String, Path> _paths = <String, Path>{};
  final Map<String, Rect> _bounds = <String, Rect>{};
  final Map<String, _EdgeKey> _keys = <String, _EdgeKey>{};
  final Set<String> _dirty = <String>{};

  int _recomputeCount = 0;

  /// Number of paths recomputed across all [syncTo] calls.
  int get recomputeCount => _recomputeCount;

  /// Cached path for [edgeId], or null when absent/removed.
  Path? pathFor(String edgeId) => _paths[edgeId];

  /// Cached path bounds for [edgeId], or null when absent/removed.
  Rect? boundsFor(String edgeId) => _bounds[edgeId];

  /// Marks [ids] for recomputation on the next [syncTo].
  void invalidateEdges(Set<String> ids) {
    _dirty.addAll(ids);
  }

  /// Reconciles the cache with [doc].
  ///
  /// Endpoint anchor resolution: the handle's absolute position
  /// (`absoluteTopLeft + handle.position`) when `handleId` resolves in the
  /// endpoint node's handles (including synthesized defaults), else the
  /// node's center-right (source) / center-left (target) default ports.
  /// Absolute rects use [defaultOrigin].
  void syncTo(LatticeDocument doc, {required Offset defaultOrigin}) {
    final Set<String> removed = _paths.keys
        .where((String id) => !doc.edges.containsKey(id))
        .toSet();
    for (final String id in removed) {
      _paths.remove(id);
      _bounds.remove(id);
      _keys.remove(id);
      _dirty.remove(id);
    }

    for (final LatticeEdge edge in doc.edges.values) {
      final LatticeNode? sourceNode = doc.nodes[edge.source.nodeId];
      final LatticeNode? targetNode = doc.nodes[edge.target.nodeId];
      if (sourceNode == null || targetNode == null) {
        // Dangling endpoints: no valid path; drop any stale entry.
        _paths.remove(edge.id);
        _bounds.remove(edge.id);
        _keys.remove(edge.id);
        _dirty.remove(edge.id);
        continue;
      }

      final Rect sourceRect = latticeAbsoluteRect(
        doc.nodes,
        sourceNode.id,
        defaultOrigin: defaultOrigin,
      );
      final Rect targetRect = latticeAbsoluteRect(
        doc.nodes,
        targetNode.id,
        defaultOrigin: defaultOrigin,
      );
      final Offset sourceAnchor = _resolveAnchor(
        sourceNode,
        sourceRect,
        edge.source.handleId,
        isSource: true,
      );
      final Offset targetAnchor = _resolveAnchor(
        targetNode,
        targetRect,
        edge.target.handleId,
        isSource: false,
      );
      final _EdgeKey key = _EdgeKey(
        sourceAnchor: sourceAnchor,
        targetAnchor: targetAnchor,
        type: edge.type,
      );

      if (!_paths.containsKey(edge.id) ||
          _dirty.contains(edge.id) ||
          _keys[edge.id] != key) {
        final Path path = latticeEdgePath(
          sourceRect: sourceRect,
          sourceAnchor: sourceAnchor,
          targetRect: targetRect,
          targetAnchor: targetAnchor,
          type: edge.type,
        );
        _paths[edge.id] = path;
        _bounds[edge.id] = path.getBounds();
        _keys[edge.id] = key;
        _recomputeCount++;
      }
      _dirty.remove(edge.id);
    }
  }

  static Offset _resolveAnchor(
    LatticeNode node,
    Rect absoluteRect,
    String? handleId, {
    required bool isSource,
  }) {
    if (handleId != null) {
      final handle = node.resolveHandles()[handleId];
      if (handle != null) {
        return absoluteRect.topLeft + handle.position;
      }
    }
    return isSource ? absoluteRect.centerRight : absoluteRect.centerLeft;
  }
}

/// Resolved inputs for one cached edge path; any change forces recompute.
@immutable
class _EdgeKey {
  const _EdgeKey({
    required this.sourceAnchor,
    required this.targetAnchor,
    required this.type,
  });

  final Offset sourceAnchor;
  final Offset targetAnchor;
  final String type;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _EdgeKey &&
        other.sourceAnchor == sourceAnchor &&
        other.targetAnchor == targetAnchor &&
        other.type == type;
  }

  @override
  int get hashCode => Object.hash(sourceAnchor, targetAnchor, type);
}
