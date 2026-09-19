import 'dart:ui';

import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/core/enums/enums.dart';

class _EdgeUpdateInfo {
  final bool needsUpdate;
  final bool fullUpdate;
  final Set<String> specificNodes;
  final Set<String> addedEdges;
  final Set<String> modifiedEdges;
  final Set<String> removedEdges;

  _EdgeUpdateInfo({
    required this.needsUpdate,
    this.fullUpdate = false,
    this.specificNodes = const {},
    this.addedEdges = const {},
    this.modifiedEdges = const {},
    this.removedEdges = const {},
  });
}

class EdgeGeometryController {
  final EdgeGeometryService _edgeGeometryService;
  final SpatialIndexService _spatialIndex;
  FlowCanvasState? _previousState;

  // Cache node positions for fast comparison
  Map<String, Offset> _previousNodePositions = {};
  Map<String, Size> _previousNodeSizes = {};
  Map<String, FlowEdge> _previousEdges = {};

  EdgeGeometryController({
    required EdgeGeometryService edgeGeometryService,
    required SpatialIndexService spatialIndex,
  })  : _edgeGeometryService = edgeGeometryService,
        _spatialIndex = spatialIndex;

  /// Returns whether edge paths were rebuilt (layout repaint signal).
  bool updateGeometryIfNeeded(
    FlowCanvasState newState, {
    Offset defaultOrigin = Offset.zero,
  }) {
    final updateInfo = _shouldUpdateEdgeGeometry(newState);

    if (!updateInfo.needsUpdate) {
      // Pan/zoom and other no-op geometry frames: skip O(N) cache copies.
      return false;
    }

    if (updateInfo.fullUpdate) {
      _edgeGeometryService.updateCache(newState, newState.edges.keys,
          defaultOrigin: defaultOrigin);
    } else {
      if (updateInfo.removedEdges.isNotEmpty) {
        _edgeGeometryService.removeEdges(updateInfo.removedEdges);
      }
      final edgesToUpdate = {
        ...updateInfo.addedEdges,
        ...updateInfo.modifiedEdges
      };
      if (edgesToUpdate.isNotEmpty) {
        for (final edgeId in edgesToUpdate) {
          _edgeGeometryService.updateEdge(newState, edgeId,
              defaultOrigin: defaultOrigin);
        }
      }
      if (updateInfo.specificNodes.isNotEmpty) {
        _edgeGeometryService.updateEdgesForNodes(
            newState, updateInfo.specificNodes, _spatialIndex.edgeIndex,
            defaultOrigin: defaultOrigin);
      }
    }

    _updateCaches(newState);
    return true;
  }

  _EdgeUpdateInfo _shouldUpdateEdgeGeometry(FlowCanvasState newState) {
    if (_previousState == null) {
      return _EdgeUpdateInfo(needsUpdate: true, fullUpdate: true);
    }

    final edgeChanges = _detectEdgeChanges(_previousEdges, newState.edges);

    if (edgeChanges.added.isNotEmpty ||
        edgeChanges.removed.isNotEmpty ||
        edgeChanges.modified.isNotEmpty) {
      return _EdgeUpdateInfo(
        needsUpdate: true,
        addedEdges: edgeChanges.added,
        removedEdges: edgeChanges.removed,
        modifiedEdges: edgeChanges.modified,
      );
    }

    if (newState.dragMode == DragMode.node) {
      final movedNodes = _getMovedNodesOptimized(newState);
      if (movedNodes.isNotEmpty) {
        return _EdgeUpdateInfo(
          needsUpdate: true,
          specificNodes: movedNodes,
        );
      }
    }

    final changedNodes = _getChangedNodesOptimized(newState);
    if (changedNodes.isNotEmpty) {
      return _EdgeUpdateInfo(
        needsUpdate: true,
        specificNodes: changedNodes,
      );
    }

    return _EdgeUpdateInfo(needsUpdate: false);
  }

  Set<String> _getMovedNodesOptimized(FlowCanvasState current) {
    final movedNodes = <String>{};
    for (final nodeId in current.selectedNodes) {
      final cachedPos = _previousNodePositions[nodeId];
      final currentPos = current.nodes[nodeId]?.position;
      if (cachedPos != null && currentPos != null && cachedPos != currentPos) {
        movedNodes.add(nodeId);
      }
    }
    return movedNodes;
  }

  Set<String> _getChangedNodesOptimized(FlowCanvasState current) {
    final changedNodes = <String>{};
    final allNodeIds = {..._previousNodePositions.keys, ...current.nodes.keys};

    for (final nodeId in allNodeIds) {
      final oldPos = _previousNodePositions[nodeId];
      final newPos = current.nodes[nodeId]?.position;
      final oldSize = _previousNodeSizes[nodeId];
      final newSize = current.nodes[nodeId]?.size;

      if (oldPos != newPos || oldSize != newSize) {
        changedNodes.add(nodeId);
      }
    }
    return changedNodes;
  }

  _EdgeChanges _detectEdgeChanges(
      Map<String, FlowEdge> oldEdges, Map<String, FlowEdge> newEdges) {
    final added = <String>{};
    final removed = <String>{};
    final modified = <String>{};

    final oldKeys = oldEdges.keys.toSet();
    final newKeys = newEdges.keys.toSet();

    added.addAll(newKeys.difference(oldKeys));
    removed.addAll(oldKeys.difference(newKeys));

    final commonKeys = oldKeys.intersection(newKeys);
    for (final key in commonKeys) {
      if (oldEdges[key] != newEdges[key]) {
        modified.add(key);
      }
    }

    return _EdgeChanges(added: added, removed: removed, modified: modified);
  }

  void _updateCaches(FlowCanvasState state) {
    _previousState = state;
    _previousNodePositions = {
      for (final entry in state.nodes.entries) entry.key: entry.value.position
    };
    _previousNodeSizes = {
      for (final entry in state.nodes.entries) entry.key: entry.value.size
    };
    _previousEdges = Map.from(state.edges);
  }
}

class _EdgeChanges {
  final Set<String> added;
  final Set<String> removed;
  final Set<String> modified;

  _EdgeChanges({
    required this.added,
    required this.removed,
    required this.modified,
  });
}
