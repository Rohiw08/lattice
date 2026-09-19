import 'package:flutter/painting.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';

typedef CellKey = String;

/// Mutable spatial index for fast node / handle lookups in **absolute** flow
/// space. Child [FlowNode.position] values may be parent-relative (Lattice default).
class NodeIndex {
  static const double _defaultCellSize = 250.0;

  final Map<String, FlowNode> _nodes;
  final Map<CellKey, Set<String>> _nodeSpatialGrid;
  final Map<CellKey, Set<String>> _handleSpatialGrid;
  final double _cellSize;

  /// Canvas default origin used when a node has no per-node [FlowNode.origin].
  ///
  /// Sticky across [SpatialIndexService.rebuild] unless overridden, so pure
  /// call sites (history, load) never reset it to zero behind the canvas's
  /// back. Updated from `NodeOptions.nodeOrigin` on init/options change.
  final Offset defaultOrigin;

  NodeIndex._({
    required Map<String, FlowNode> nodes,
    required Map<CellKey, Set<String>> nodeSpatialGrid,
    required Map<CellKey, Set<String>> handleSpatialGrid,
    required double cellSize,
    this.defaultOrigin = Offset.zero,
  })  : _nodes = nodes,
        _nodeSpatialGrid = nodeSpatialGrid,
        _handleSpatialGrid = handleSpatialGrid,
        _cellSize = cellSize;

  /// Creates an empty spatial index.
  factory NodeIndex.empty(
          {double cellSize = _defaultCellSize,
          Offset defaultOrigin = Offset.zero}) =>
      NodeIndex._(
        nodes: {},
        nodeSpatialGrid: {},
        handleSpatialGrid: {},
        cellSize: cellSize,
        defaultOrigin: defaultOrigin,
      );

  /// Builds an index from an initial set of nodes.
  factory NodeIndex.fromNodes(
    Iterable<FlowNode> nodes, {
    double cellSize = _defaultCellSize,
    Offset defaultOrigin = Offset.zero,
  }) {
    final nodeMap = <String, FlowNode>{
      for (final node in nodes) node.id: node,
    };
    final nodeGrid = <CellKey, Set<String>>{};
    final handleGrid = <CellKey, Set<String>>{};

    for (final node in nodeMap.values) {
      _addNodeToGrids(
          node, nodeMap, nodeGrid, handleGrid, cellSize, defaultOrigin);
    }

    return NodeIndex._(
      nodes: nodeMap,
      nodeSpatialGrid: nodeGrid,
      handleSpatialGrid: handleGrid,
      cellSize: cellSize,
      defaultOrigin: defaultOrigin,
    );
  }

  // --- PUBLIC API ---

  /// Returns the node with the given [nodeId], or `null` if not found.
  FlowNode? getNode(String nodeId) => _nodes[nodeId];

  /// Returns all nodes in this index.
  Iterable<FlowNode> get allNodes => _nodes.values;

  /// Queries nodes whose bounding boxes intersect the given [rect].
  ///
  /// The rectangle must be specified in **Cartesian coordinates**.
  /// Candidates come from the grid, then refined with AABB overlap.
  Set<String> queryNodesInRect(Rect rect) {
    final resultIds = <String>{};
    final cells = _getCellsInRect(rect, _cellSize);

    for (final cellKey in cells) {
      final ids = _nodeSpatialGrid[cellKey];
      if (ids == null) continue;
      for (final id in ids) {
        final node = _nodes[id];
        if (node != null &&
            NodeLayout.absoluteRect(node, _nodes,
                    defaultOrigin: defaultOrigin)
                .overlaps(rect)) {
          resultIds.add(id);
        }
      }
    }
    return resultIds;
  }

  /// Queries handle keys in grid cells within [searchRadius] flow units of [position].
  ///
  /// The fixed 3×3 cell window is insufficient when [searchRadius] exceeds roughly
  /// one cell (e.g. zoom-aware snap uses a large flow-space radius when zoomed out).
  Set<String> queryHandlesNear(
    Offset position, {
    double searchRadius = 20,
  }) {
    final gridX = (position.dx / _cellSize).floor();
    final gridY = (position.dy / _cellSize).floor();
    final nearbyHandles = <String>{};

    final radius = searchRadius <= 0 ? _cellSize : searchRadius;
    var extent = (radius / _cellSize).ceil();
    if (extent < 1) extent = 1;

    for (int dx = -extent; dx <= extent; dx++) {
      for (int dy = -extent; dy <= extent; dy++) {
        final key = '${gridX + dx}:${gridY + dy}';
        final handles = _handleSpatialGrid[key];
        if (handles != null) nearbyHandles.addAll(handles);
      }
    }
    return nearbyHandles;
  }

  /// Adds [node] to the index in-place.
  void addNode(FlowNode node) {
    _nodes[node.id] = node;
    _addNodeToGrids(node, _nodes, _nodeSpatialGrid, _handleSpatialGrid,
        _cellSize, defaultOrigin);
  }

  /// Removes [node] from the index in-place.
  void removeNode(FlowNode node) {
    if (!_nodes.containsKey(node.id)) return;
    _removeNodeFromGrids(node, _nodes, _nodeSpatialGrid, _handleSpatialGrid,
        _cellSize, defaultOrigin);
    _nodes.remove(node.id);
  }

  /// Updates [oldNode] to [newNode] within the index in-place.
  ///
  /// If [oldNode] does not exist, it behaves like [addNode].
  void updateNode(FlowNode oldNode, FlowNode newNode) {
    if (!_nodes.containsKey(oldNode.id)) {
      addNode(newNode);
      return;
    }

    // Fast path: skip update if identical in geometry
    if (identical(oldNode, newNode) || oldNode == newNode) return;

    _removeNodeFromGrids(oldNode, _nodes, _nodeSpatialGrid, _handleSpatialGrid,
        _cellSize, defaultOrigin);
    _nodes[newNode.id] = newNode;
    _addNodeToGrids(newNode, _nodes, _nodeSpatialGrid, _handleSpatialGrid,
        _cellSize, defaultOrigin);
  }

  /// Batch updates multiple nodes in-place.
  ///
  /// [updates] is a map of oldNode -> newNode.
  void updateNodes(Map<FlowNode, FlowNode> updates) {
    if (updates.isEmpty) return;

    for (final entry in updates.entries) {
      final oldNode = entry.key;
      final newNode = entry.value;

      if (_nodes.containsKey(oldNode.id)) {
        _removeNodeFromGrids(oldNode, _nodes, _nodeSpatialGrid,
            _handleSpatialGrid, _cellSize, defaultOrigin);
        _nodes[newNode.id] = newNode;
        _addNodeToGrids(newNode, _nodes, _nodeSpatialGrid, _handleSpatialGrid,
            _cellSize, defaultOrigin);
      }
    }
  }

  // --- INTERNAL HELPERS ---

  static void _addNodeToGrids(
    FlowNode node,
    Map<String, FlowNode> nodes,
    Map<CellKey, Set<String>> nodeGrid,
    Map<CellKey, Set<String>> handleGrid,
    double cellSize,
    Offset defaultOrigin,
  ) {
    final abs = NodeLayout.absoluteTopLeft(node.id, nodes,
        defaultOrigin: defaultOrigin);
    final absRect =
        Rect.fromLTWH(abs.dx, abs.dy, node.size.width, node.size.height);
    final nodeCells = _getCellsInRect(absRect, cellSize);
    for (final key in nodeCells) {
      nodeGrid.putIfAbsent(key, () => <String>{}).add(node.id);
    }

    for (final handle in node.effectiveHandles.values) {
      final handlePos = abs + handle.position;
      final key = _getCellKey(handlePos, cellSize);
      handleGrid
          .putIfAbsent(key, () => <String>{})
          .add('${node.id}/${handle.id}');
    }
  }

  static void _removeNodeFromGrids(
    FlowNode node,
    Map<String, FlowNode> nodes,
    Map<CellKey, Set<String>> nodeGrid,
    Map<CellKey, Set<String>> handleGrid,
    double cellSize,
    Offset defaultOrigin,
  ) {
    final abs = NodeLayout.absoluteTopLeft(node.id, nodes,
        defaultOrigin: defaultOrigin);
    final absRect =
        Rect.fromLTWH(abs.dx, abs.dy, node.size.width, node.size.height);
    final nodeCells = _getCellsInRect(absRect, cellSize);
    _removeFromGrid(nodeGrid, node.id, nodeCells.toList());

    final handleCells = <CellKey>[];
    for (final handle in node.effectiveHandles.values) {
      final handlePos = abs + handle.position;
      handleCells.add(_getCellKey(handlePos, cellSize));
    }
    _removeFromGrid(
      handleGrid,
      '${node.id}/',
      handleCells,
      prefixMatch: true,
    );
  }

  static void _removeFromGrid(
    Map<CellKey, Set<String>> grid,
    String id,
    List<CellKey> cells, {
    bool prefixMatch = false,
  }) {
    for (final cellKey in cells) {
      final idsInCell = grid[cellKey];
      if (idsInCell != null) {
        // Exact match for node ids. Prefix match only for handle keys
        // (`nodeId/…`) — never use startsWith on bare node ids (would
        // remove `node_10` when updating `node_1`).
        if (prefixMatch) {
          idsInCell.removeWhere(
              (element) => element == id || element.startsWith(id));
        } else {
          idsInCell.remove(id);
        }
        if (idsInCell.isEmpty) {
          grid.remove(cellKey);
        }
      }
    }
  }

  static Set<CellKey> _getCellsInRect(Rect rect, double cellSize) {
    final cells = <CellKey>{};
    final minX = (rect.left / cellSize).floor();
    final maxX = (rect.right / cellSize).floor();
    final minY = (rect.top / cellSize).floor();
    final maxY = (rect.bottom / cellSize).floor();

    for (int x = minX; x <= maxX; x++) {
      for (int y = minY; y <= maxY; y++) {
        cells.add('$x:$y');
      }
    }
    return cells;
  }

  static CellKey _getCellKey(Offset pos, double cellSize) {
    final cx = (pos.dx / cellSize).floor();
    final cy = (pos.dy / cellSize).floor();
    return '$cx:$cy';
  }

  @override
  String toString() =>
      'NodeIndex(nodes: ${_nodes.length}, cells: ${_nodeSpatialGrid.length}, handles: ${_handleSpatialGrid.length})';
}
