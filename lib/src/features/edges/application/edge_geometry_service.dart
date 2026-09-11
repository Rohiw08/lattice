import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/edge_index.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/core/utils/edge_path_creator.dart';
import 'package:lattice/src/core/enums/enums.dart';
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

  /// Retrieves the cached geometry for a given edge ID.
  EdgeGeom? getGeom(String edgeId) => _edgeCache[edgeId];

  /// Unmodifiable view of cached paths — do not allocate a new map each build.
  Map<String, Path> get precomputedPaths => _pathView;

  /// @Deprecated Use [precomputedPaths] — kept for call-site compatibility.
  Map<String, Path> getPrecomputedPaths() => _pathView;

  /// Updates the cache for all visible edges, removing any that no longer exist.
  void updateCache(FlowCanvasState state, Iterable<String> visibleEdgeIds) {
    final currentEdgeIds = Set<String>.from(visibleEdgeIds);
    _edgeCache.removeWhere((id, _) => !currentEdgeIds.contains(id));
    _edgeVersion.removeWhere((id, _) => !currentEdgeIds.contains(id));
    _pathView.removeWhere((id, _) => !currentEdgeIds.contains(id));

    for (final id in currentEdgeIds) {
      _ensureEdgeGeom(state, id);
    }
  }

  /// Updates only edges connected to specific nodes (OPTIMIZED).
  void updateEdgesForNodes(
      FlowCanvasState state, Set<String> nodeIds, EdgeIndex edgeIndex,
      {Map<String, Offset>? livePositions}) {
    if (nodeIds.isEmpty) return;

    final edgesToUpdate = <String>{};
    for (final nodeId in nodeIds) {
      edgesToUpdate.addAll(edgeIndex.getEdgesForNode(nodeId));
    }
    for (final edgeId in edgesToUpdate) {
      _ensureEdgeGeom(state, edgeId, livePositions: livePositions);
    }
  }

  /// Updates a single edge (useful when adding/modifying one edge).
  void updateEdge(FlowCanvasState state, String edgeId,
      {Map<String, Offset>? livePositions}) {
    _edgeVersion.remove(edgeId);
    _ensureEdgeGeom(state, edgeId, livePositions: livePositions);
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
  }) {
    final edge = state.edges[edgeId];
    if (edge == null) return;

    final sourceNode = state.nodes[edge.sourceNodeId];
    final targetNode = state.nodes[edge.targetNodeId];
    if (sourceNode == null || targetNode == null) return;

    final sourceAbs = NodeLayout.absolutePosition(
      sourceNode.id,
      state.nodes,
      livePositions: livePositions,
    );
    final targetAbs = NodeLayout.absolutePosition(
      targetNode.id,
      state.nodes,
      livePositions: livePositions,
    );

    final version = Object.hash(
      sourceAbs,
      sourceNode.size,
      targetAbs,
      targetNode.size,
      edge.sourceHandleId,
      edge.targetHandleId,
      edge.type,
    );

    final oldVersion = _edgeVersion[edgeId];
    if (oldVersion == version) return;

    final Offset sourceHandlePosition;
    HandlePosition sourceDir = HandlePosition.right;
    if (edge.sourceHandleId != null &&
        sourceNode.effectiveHandles.containsKey(edge.sourceHandleId!)) {
      final handlePos = sourceNode.effectiveHandles[edge.sourceHandleId!]!.position;
      sourceHandlePosition = sourceAbs + handlePos;
      sourceDir = _determineHandlePosition(handlePos, sourceNode.size);
    } else {
      sourceHandlePosition = sourceAbs +
          Offset(sourceNode.size.width / 2, sourceNode.size.height / 2);
    }

    final Offset targetHandlePosition;
    HandlePosition targetDir = HandlePosition.left;
    if (edge.targetHandleId != null &&
        targetNode.effectiveHandles.containsKey(edge.targetHandleId!)) {
      final handlePos = targetNode.effectiveHandles[edge.targetHandleId!]!.position;
      targetHandlePosition = targetAbs + handlePos;
      targetDir = _determineHandlePosition(handlePos, targetNode.size);
    } else {
      targetHandlePosition = targetAbs +
          Offset(targetNode.size.width / 2, targetNode.size.height / 2);
    }

    final path = EdgePathCreator.createPath(
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

