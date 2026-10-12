import 'dart:collection';

import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/edge_index.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/handles/domain/handle.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/core/utils/edge_path_creator.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Cached tangent at path ends for markers (avoids computeMetrics every paint).
class EdgeMarkerTangents {
  final Offset startPosition;
  final Offset startDirection;
  final Offset endPosition;
  final Offset endDirection;

  const EdgeMarkerTangents({
    required this.startPosition,
    required this.startDirection,
    required this.endPosition,
    required this.endDirection,
  });
}

/// A data class holding the pre-calculated geometry for an edge.
class EdgeGeom {
  final Path path;
  final Rect bounds;
  final List<Offset> samples;
  final EdgeMarkerTangents? markers;

  const EdgeGeom({
    required this.path,
    required this.bounds,
    required this.samples,
    this.markers,
  });
}

/// Manages the calculation, caching, and hit-testing of edge geometry.
class EdgeGeometryService {
  EdgeGeometryService();

  final Map<String, EdgeGeom> _edgeCache = {};
  final Map<String, int> _edgeVersion = {};
  final Map<String, Path> _pathView = {};

  /// Bumped whenever any cached path changes (for [shouldRepaint]).
  int geometryEpoch = 0;

  // Memoized edge-set signature (see [edgesSignature]).
  Map<String, FlowEdge>? _sigEdgesRef;
  int _sigHash = 0;
  bool _sigHasAnimated = false;

  /// Cheap, cached signature of the edge set: a hash of the edge ids plus
  /// whether any edge is animated.
  ///
  /// Both are O(edges) to compute, but they only change when the `edges` map
  /// itself is replaced (add/remove/modify) — never on a hover, selection,
  /// or viewport emission, which reuse the same map reference. Memoizing on
  /// map identity keeps the edge-layer selector O(1) on those frequent
  /// emissions instead of re-scanning every edge each time.
  ({int hash, bool hasAnimated}) edgesSignature(Map<String, FlowEdge> edges) {
    if (identical(edges, _sigEdgesRef)) {
      return (hash: _sigHash, hasAnimated: _sigHasAnimated);
    }
    var hasAnimated = false;
    for (final e in edges.values) {
      if (e.animated) {
        hasAnimated = true;
        break;
      }
    }
    _sigEdgesRef = edges;
    _sigHash = Object.hashAll(edges.keys);
    _sigHasAnimated = hasAnimated;
    return (hash: _sigHash, hasAnimated: hasAnimated);
  }

  /// Retrieves the cached geometry for a given edge ID.
  EdgeGeom? getGeom(String edgeId) => _edgeCache[edgeId];

  /// Unmodifiable view of cached paths — do not allocate a new map each build.
  Map<String, Path> get precomputedPaths => _pathView;

  /// Unmodifiable view of cached geometry (paths, bounds, marker tangents).
  ///
  /// Painters read marker tangents from here instead of running
  /// `computeMetrics` per edge per repaint. Same identity across builds;
  /// [EdgePainter.shouldRepaint] keys off epochs, not this map.
  Map<String, EdgeGeom> get geometries => UnmodifiableMapView(_edgeCache);

  /// Unmodifiable view of per-edge geometry versions.
  ///
  /// Painters compare versions for their own edge set to skip repaints
  /// when unrelated edges change (the global [geometryEpoch] bumps on any
  /// change). Same identity across builds.
  Map<String, int> get edgeVersions => UnmodifiableMapView(_edgeVersion);

  /// Updates the cache for all visible edges, removing any that no longer exist.
  void updateCache(
    FlowCanvasState state,
    Iterable<String> visibleEdgeIds, {
    Offset defaultOrigin = Offset.zero,
  }) {
    final currentEdgeIds = Set<String>.from(visibleEdgeIds);
    _edgeCache.removeWhere((id, _) => !currentEdgeIds.contains(id));
    _edgeVersion.removeWhere((id, _) => !currentEdgeIds.contains(id));
    _pathView.removeWhere((id, _) => !currentEdgeIds.contains(id));

    for (final id in currentEdgeIds) {
      _ensureEdgeGeom(state, id, defaultOrigin: defaultOrigin);
    }
  }

  /// Computes geometry for [edgeIds] that lack it (version-checked no-op
  /// for cached ones). Used by the cull filter so lazy mounts fill visible
  /// edges on demand instead of computing every edge eagerly at mount.
  void ensureGeoms(
    FlowCanvasState state,
    Iterable<String> edgeIds, {
    Offset defaultOrigin = Offset.zero,
  }) {
    for (final id in edgeIds) {
      if (_edgeCache.containsKey(id)) continue;
      _ensureEdgeGeom(state, id, defaultOrigin: defaultOrigin);
    }
  }

  /// Updates only edges connected to specific nodes (OPTIMIZED).
  void updateEdgesForNodes(
      FlowCanvasState state, Set<String> nodeIds, EdgeIndex edgeIndex,
      {Map<String, Offset>? livePositions,
      Offset defaultOrigin = Offset.zero}) {
    if (nodeIds.isEmpty) return;

    final edgesToUpdate = <String>{};
    for (final nodeId in nodeIds) {
      edgesToUpdate.addAll(edgeIndex.getEdgesForNode(nodeId));
    }
    for (final edgeId in edgesToUpdate) {
      _ensureEdgeGeom(state, edgeId,
          livePositions: livePositions, defaultOrigin: defaultOrigin);
    }
  }

  /// Updates a single edge (useful when adding/modifying one edge).
  void updateEdge(FlowCanvasState state, String edgeId,
      {Map<String, Offset>? livePositions,
      Offset defaultOrigin = Offset.zero}) {
    _edgeVersion.remove(edgeId);
    _ensureEdgeGeom(state, edgeId,
        livePositions: livePositions, defaultOrigin: defaultOrigin);
  }

  /// Removes edges from the cache (useful when edges are deleted).
  void removeEdges(Set<String> edgeIds) {
    for (final edgeId in edgeIds) {
      _edgeCache.remove(edgeId);
      _edgeVersion.remove(edgeId);
      _pathView.remove(edgeId);
    }
    if (edgeIds.isNotEmpty) geometryEpoch++;
  }

  /// Clears the entire cache.
  void clearCache() {
    _edgeCache.clear();
    _edgeVersion.clear();
    _pathView.clear();
    geometryEpoch++;
  }

  void _ensureEdgeGeom(
    FlowCanvasState state,
    String edgeId, {
    Map<String, Offset>? livePositions,
    Offset defaultOrigin = Offset.zero,
  }) {
    final edge = state.edges[edgeId];
    if (edge == null) return;

    final sourceNode = state.nodes[edge.sourceNodeId];
    final targetNode = state.nodes[edge.targetNodeId];
    if (sourceNode == null || targetNode == null) return;

    final sourceAbs = NodeLayout.absoluteTopLeft(
      sourceNode.id,
      state.nodes,
      livePositions: livePositions,
      defaultOrigin: defaultOrigin,
    );
    final targetAbs = NodeLayout.absoluteTopLeft(
      targetNode.id,
      state.nodes,
      livePositions: livePositions,
      defaultOrigin: defaultOrigin,
    );

    final version = Object.hash(
      sourceAbs,
      sourceNode.size,
      targetAbs,
      targetNode.size,
      edge.sourceHandleId,
      edge.targetHandleId,
      edge.type,
      edge.pathBuilder,
      // Paint-relevant fields (the painter skips repaints unless this
      // version or the epoch changes): style/marker/decoration inputs must
      // participate, or style-only updates would render stale pixels.
      edge.style,
      edge.startMarkerStyle,
      edge.endMarkerStyle,
      edge.foregroundPainter,
      edge.animationEffect,
      edge.animated,
      edge.selectable,
      edge.data,
    );

    final oldVersion = _edgeVersion[edgeId];
    if (oldVersion == version) return;

    if (kDebugMode) FlowCanvasDebug.countGeoCompute();

    // Resolve the source connection point. Prefer the edge's named handle;
    // when it is null or unknown, fall back to the node's first source-capable
    // handle — React Flow lands a handle-less edge end on the node's default
    // port of the matching type, not the node center. Center is a last resort
    // only when the node exposes no such handle at all (its old behavior for
    // every handle-less edge, which detached the arrowhead and drew a stray
    // arc from the geometric center).
    final sourceHandle =
        _resolveHandle(sourceNode, edge.sourceHandleId, HandleType.source);
    final Offset sourceHandlePosition;
    final HandlePosition sourceDir;
    if (sourceHandle != null) {
      sourceHandlePosition = sourceAbs + sourceHandle.position;
      sourceDir = _determineHandlePosition(sourceHandle.position, sourceNode.size);
    } else {
      sourceHandlePosition = sourceAbs +
          Offset(sourceNode.size.width / 2, sourceNode.size.height / 2);
      sourceDir = HandlePosition.right;
    }

    final targetHandle =
        _resolveHandle(targetNode, edge.targetHandleId, HandleType.target);
    final Offset targetHandlePosition;
    final HandlePosition targetDir;
    if (targetHandle != null) {
      targetHandlePosition = targetAbs + targetHandle.position;
      targetDir = _determineHandlePosition(targetHandle.position, targetNode.size);
    } else {
      targetHandlePosition = targetAbs +
          Offset(targetNode.size.width / 2, targetNode.size.height / 2);
      targetDir = HandlePosition.left;
    }

    final path = edge.pathBuilder?.call(FlowEdgePathInput(
          source: sourceHandlePosition,
          target: targetHandlePosition,
          sourceDir: sourceDir,
          targetDir: targetDir,
          edge: edge,
        )) ??
        EdgePathCreator.createPath(
          edge.type,
          sourceHandlePosition,
          targetHandlePosition,
          sourcePosition: sourceDir,
      targetPosition: targetDir,
    );
    final bounds = path.getBounds().inflate(8);

    final samples = <Offset>[];
    EdgeMarkerTangents? markers;
    final metrics = path.computeMetrics().toList();
    for (final m in metrics) {
      const step = 12.0;
      for (double d = 0; d <= m.length; d += step) {
        final pos = m.getTangentForOffset(d)?.position;
        if (pos != null) samples.add(pos);
      }
    }
    if (metrics.isNotEmpty) {
      final first = metrics.first;
      final last = metrics.last;
      final startT = first.getTangentForOffset(0);
      final endT = last.getTangentForOffset(last.length);
      if (startT != null && endT != null) {
        markers = EdgeMarkerTangents(
          startPosition: startT.position,
          startDirection: startT.vector,
          endPosition: endT.position,
          endDirection: endT.vector,
        );
      }
    }

    _edgeCache[edgeId] =
        EdgeGeom(path: path, bounds: bounds, samples: samples, markers: markers);
    _pathView[edgeId] = path;
    _edgeVersion[edgeId] = version;
    geometryEpoch++;
  }

  String? hitTestEdgeAt(Offset localPos, FlowCanvasState state, double zoom) {
    const double baseTolerance = 8.0;

    for (final edgeId in _edgeCache.keys.toList().reversed) {
      final geom = _edgeCache[edgeId];
      if (geom == null) continue;

      final tolerance =
          ((state.edges[edgeId]?.interactionWidth ?? 10.0) / (2.0 * zoom))
              .clamp(baseTolerance, 64.0);

      if (!geom.bounds.inflate(tolerance).contains(localPos)) {
        continue;
      }

      if (_isPointNearSamples(geom.samples, localPos, tolerance)) {
        return edgeId;
      }
    }
    return null;
  }

  /// Resolves the handle an edge end connects to.
  ///
  /// Prefers the explicitly named [handleId]; when it is null or absent, returns
  /// the node's first handle able to serve [role] (its own type, or `both`) so a
  /// handle-less edge end lands on the node's default port — React Flow parity —
  /// instead of the node center. Returns null only when the node exposes no
  /// handle for [role], leaving the caller's center fallback as the last resort.
  FlowHandle? _resolveHandle(FlowNode node, String? handleId, HandleType role) {
    final handles = node.effectiveHandles;
    if (handleId != null) {
      final named = handles[handleId];
      if (named != null) return named;
    }
    for (final handle in handles.values) {
      if (handle.type == role || handle.type == HandleType.both) return handle;
    }
    return null;
  }

  HandlePosition _determineHandlePosition(Offset handleOffset, Size nodeSize) {
    final distLeft = handleOffset.dx;
    final distRight = nodeSize.width - handleOffset.dx;
    final distTop = handleOffset.dy;
    final distBottom = nodeSize.height - handleOffset.dy;

    final minDist = [distLeft, distRight, distTop, distBottom]
        .reduce((a, b) => a < b ? a : b);

    if (minDist == distLeft) return HandlePosition.left;
    if (minDist == distRight) return HandlePosition.right;
    if (minDist == distTop) return HandlePosition.top;
    return HandlePosition.bottom;
  }

  bool _isPointNearSamples(List<Offset> samples, Offset p, double tolerance) {
    final tolSq = tolerance * tolerance;
    for (final s in samples) {
      if ((s - p).distanceSquared <= tolSq) {
        return true;
      }
    }
    return false;
  }
}

