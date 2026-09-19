import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Layout direction (dagre `rankdir`).
enum FlowLayoutDirection {
  /// Layers/levels run top to bottom (dagre `TB`).
  topBottom,

  /// Layers/levels run bottom to top (dagre `BT`).
  bottomTop,

  /// Layers/levels run left to right (dagre `LR`).
  leftRight,

  /// Layers/levels run right to left (dagre `RL`).
  rightLeft,
}

/// Automatic graph layout (dagre/ELK counterpart).
///
/// React Flow points at dagre or ELK for auto-arranging graphs; those are
/// JavaScript libraries, so lattice bundles equivalent pure-Dart passes
/// instead. Both entries are **pure functions**: they take node/edge maps
/// and return a new node map with positioned copies (inputs untouched,
/// unplaced nodes keep identical instances). Apply with `load`, or loop
/// `controller.nodes.updateNode`:
///
/// ```dart
/// final laidOut = FlowLayout.layered(
///   controller.currentState.nodes,
///   controller.currentState.edges,
///   direction: FlowLayoutDirection.leftRight,
/// );
/// controller.load(controller.currentState.copyWith(nodes: laidOut));
/// unawaited(controller.viewport.fitView());
/// ```
///
/// Rules shared by both passes:
/// - Only root nodes (`parentId == null`) are placed; parented children
///   keep their relative positions and ride along (their parent moves).
///   Size parents to fit first (or rely on `expandParent`).
/// - Edges to missing nodes and self-loops are ignored for structure
///   (dagre drops unknown endpoints the same way).
/// - Node `size` drives spacing math, so mixed-size graphs don't overlap.
/// - Output coordinates start at [offset] (default origin); run
///   `getNodesBounds` + `fitView` afterwards like the dagre recipe.
abstract final class FlowLayout {
  const FlowLayout._();

  /// Layered (Sugiyama-style) layout for directed graphs — the dagre
  /// default for pipelines and DAGs.
  ///
  /// Longest-path layering, barycenter crossing reduction (two
  /// down/up sweep pairs), size-aware packing with layers centered on
  /// the widest one. Cyclic edges are layered greedily instead of
  /// reversed (dagre breaks cycles; the visual result is equivalent for
  /// feedback edges, which simply span layers backwards). Disconnected
  /// components are laid out separately and tiled with [nodeSpacing].
  ///
  /// [nodeSpacing] is the gap between node boxes in a layer (dagre
  /// `nodesep`), [layerSpacing] the gap between layer bands (dagre
  /// `ranksep`).
  static Map<String, FlowNode> layered(
    Map<String, FlowNode> nodes,
    Map<String, FlowEdge> edges, {
    FlowLayoutDirection direction = FlowLayoutDirection.topBottom,
    double nodeSpacing = 50.0,
    double layerSpacing = 80.0,
    Offset offset = Offset.zero,
  }) {
    assert(nodeSpacing >= 0, 'nodeSpacing must be non-negative');
    assert(layerSpacing >= 0, 'layerSpacing must be non-negative');
    final order = _rootIds(nodes);

    final horizontal =
        direction == FlowLayoutDirection.leftRight ||
            direction == FlowLayoutDirection.rightLeft;
    double widthOf(FlowNode node) =>
        horizontal ? node.size.height : node.size.width;
    double heightOf(FlowNode node) =>
        horizontal ? node.size.width : node.size.height;

    // Like dagre, even a lone root is placed at the offset origin; only a
    // rootless graph (all parented, nothing to place) passes through.
    final placement = <String, math.Point<double>>{};
    if (order.isEmpty) return Map<String, FlowNode>.from(nodes);

    double cursor = 0;
    var firstComponent = true;
    for (final component in _components(order, edges)) {
      final laid = _layerComponent(
        component,
        order,
        nodes,
        edges,
        widthOf,
        heightOf,
        nodeSpacing,
        layerSpacing,
      );
      if (!firstComponent && laid.isNotEmpty) cursor += nodeSpacing;
      firstComponent = false;
      var componentWidth = 0.0;
      for (final entry in laid.entries) {
        final node = nodes[entry.key]!;
        componentWidth =
            math.max(componentWidth, entry.value.x + widthOf(node) / 2);
      }
      for (final entry in laid.entries) {
        placement[entry.key] =
            math.Point(entry.value.x + cursor, entry.value.y);
      }
      cursor += componentWidth;
    }

    return _materialize(
        nodes, placement, widthOf, heightOf, direction, offset);
  }

  /// Tidy tree layout (Buchheim linear-time Reingold–Tilford) for
  /// trees and forests — the mindmap/org-chart pass.
  ///
  /// Children come from edges (`source` → `target`); siblings keep edge-map
  /// order. Parents center over their children, subtrees never overlap
  /// (sizes + [nodeSpacing] aware), each depth gets a size-aware band
  /// separated by [layerSpacing]. Forests tile like [layered].
  ///
  /// [rootId] picks the root; default is the first sourceless root node in
  /// map order (a forest lays out every sourceless node). Throws
  /// [ArgumentError] for an unknown [rootId].
  static Map<String, FlowNode> tree(
    Map<String, FlowNode> nodes,
    Map<String, FlowEdge> edges, {
    String? rootId,
    FlowLayoutDirection direction = FlowLayoutDirection.topBottom,
    double nodeSpacing = 50.0,
    double layerSpacing = 80.0,
    Offset offset = Offset.zero,
  }) {
    assert(nodeSpacing >= 0, 'nodeSpacing must be non-negative');
    assert(layerSpacing >= 0, 'layerSpacing must be non-negative');
    final participants = _rootIds(nodes).toSet();
    if (participants.isEmpty) {
      return Map<String, FlowNode>.from(nodes);
    }
    if (rootId != null && !participants.contains(rootId)) {
      throw ArgumentError.value(
          rootId, 'rootId', 'is not a root node in the graph');
    }

    final horizontal =
        direction == FlowLayoutDirection.leftRight ||
            direction == FlowLayoutDirection.rightLeft;
    double widthOf(FlowNode node) =>
        horizontal ? node.size.height : node.size.width;
    double heightOf(FlowNode node) =>
        horizontal ? node.size.width : node.size.height;

    final successors = _successors(participants, edges);
    final inDegree = <String, int>{for (final id in participants) id: 0};
    for (final entry in successors.entries) {
      for (final target in entry.value) {
        inDegree[target] = (inDegree[target] ?? 0) + 1;
      }
    }
    final roots = rootId != null
        ? [rootId]
        : [
            for (final id in participants)
              if (inDegree[id] == 0) id,
          ];
    final rootsOrAll = roots.isEmpty ? participants.toList() : roots;

    final placement = <String, math.Point<double>>{};
    final depths = <String, int>{};
    double cursor = 0;
    var firstTree = true;
    final visitedGlobal = <String>{};
    for (final root in rootsOrAll) {
      if (visitedGlobal.contains(root)) continue;
      final laid = _tidyTree(
        root,
        nodes,
        successors,
        visitedGlobal,
        depths,
        widthOf,
        nodeSpacing,
      );
      if (laid.isEmpty) continue;
      if (!firstTree) cursor += nodeSpacing;
      firstTree = false;
      var treeWidth = 0.0;
      for (final entry in laid.entries) {
        final node = nodes[entry.key]!;
        treeWidth = math.max(treeWidth, entry.value.x + widthOf(node) / 2);
      }
      for (final entry in laid.entries) {
        placement[entry.key] =
            math.Point(entry.value.x + cursor, entry.value.y);
      }
      cursor += treeWidth;
    }

    // Depths drive shared y bands (siblings across trees align); y holds
    // band centers (like x) for [_materialize].
    final bands = _bandTops(depths, nodes, heightOf, layerSpacing);
    final withBands = <String, math.Point<double>>{};
    placement.forEach((id, point) {
      withBands[id] = math.Point(
        point.x,
        bands[depths[id] ?? 0]!.top + bands[depths[id] ?? 0]!.height / 2,
      );
    });

    return _materialize(
        nodes, withBands, widthOf, heightOf, direction, offset);
  }

  // ── shared plumbing ────────────────────────────────────────────────

  /// Root ids in map order (parented children ride along, never placed).
  static List<String> _rootIds(Map<String, FlowNode> nodes) => [
        for (final entry in nodes.entries)
          if (entry.value.parentId == null) entry.key,
      ];

  /// Successor lists (edge-map order) restricted to [participants].
  static Map<String, List<String>> _successors(
    Set<String> participants,
    Map<String, FlowEdge> edges,
  ) {
    final successors = <String, List<String>>{
      for (final id in participants) id: [],
    };
    for (final edge in edges.values) {
      if (edge.sourceNodeId == edge.targetNodeId) continue;
      if (!participants.contains(edge.sourceNodeId) ||
          !participants.contains(edge.targetNodeId)) {
        continue;
      }
      successors[edge.sourceNodeId]!.add(edge.targetNodeId);
    }
    return successors;
  }

  /// Weakly connected components (map order) for tiling.
  static List<List<String>> _components(
    List<String> order,
    Map<String, FlowEdge> edges,
  ) {
    final members = order.toSet();
    final adjacency = <String, Set<String>>{
      for (final id in order) id: {},
    };
    for (final edge in edges.values) {
      if (!members.contains(edge.sourceNodeId) ||
          !members.contains(edge.targetNodeId)) {
        continue;
      }
      adjacency[edge.sourceNodeId]!.add(edge.targetNodeId);
      adjacency[edge.targetNodeId]!.add(edge.sourceNodeId);
    }
    final seen = <String>{};
    final components = <List<String>>[];
    for (final id in order) {
      if (seen.contains(id)) continue;
      final component = <String>[];
      final stack = [id];
      seen.add(id);
      while (stack.isNotEmpty) {
        final current = stack.removeLast();
        component.add(current);
        for (final next in adjacency[current]!) {
          if (seen.add(next)) stack.add(next);
        }
      }
      components.add(component);
    }
    return components;
  }

  /// Vertical band tops/heights per depth from max node heights.
  static Map<int, ({double top, double height})> _bandTops(
    Map<String, int> depths,
    Map<String, FlowNode> nodes,
    double Function(FlowNode) heightOf,
    double layerSpacing,
  ) {
    final maxHeight = <int, double>{};
    for (final entry in depths.entries) {
      final node = nodes[entry.key];
      if (node == null) continue;
      maxHeight[entry.value] =
          math.max(maxHeight[entry.value] ?? 0, heightOf(node));
    }
    final bands = <int, ({double top, double height})>{};
    var top = 0.0;
    final ordered = maxHeight.keys.toList()..sort();
    for (var i = 0; i < ordered.length; i++) {
      final depth = ordered[i];
      if (i > 0) top += layerSpacing;
      bands[depth] = (top: top, height: maxHeight[depth]!);
      top += maxHeight[depth]!;
    }
    return bands;
  }

  /// Layout-space centers → flow-space positioned copies for root nodes.
  static Map<String, FlowNode> _materialize(
    Map<String, FlowNode> nodes,
    Map<String, math.Point<double>> placement,
    double Function(FlowNode) widthOf,
    double Function(FlowNode) heightOf,
    FlowLayoutDirection direction,
    Offset offset,
  ) {
    if (placement.isEmpty) return Map<String, FlowNode>.from(nodes);
    var contentW = 0.0;
    var contentH = 0.0;
    for (final entry in placement.entries) {
      final node = nodes[entry.key]!;
      contentW =
          math.max(contentW, entry.value.x + widthOf(node) / 2);
      contentH =
          math.max(contentH, entry.value.y + heightOf(node) / 2);
    }
    Offset convert(math.Point<double> center, FlowNode node) {
      final half =
          Offset(widthOf(node) / 2, heightOf(node) / 2);
      switch (direction) {
        case FlowLayoutDirection.topBottom:
          return Offset(center.x - half.dx, center.y - half.dy);
        case FlowLayoutDirection.bottomTop:
          return Offset(
              center.x - half.dx, contentH - center.y - half.dy);
        case FlowLayoutDirection.leftRight:
          // Layout x was the vertical axis (sizes were swapped).
          return Offset(center.y - node.size.width / 2,
              center.x - node.size.height / 2);
        case FlowLayoutDirection.rightLeft:
          return Offset(contentW - center.y - node.size.width / 2,
              center.x - node.size.height / 2);
      }
    }

    final next = Map<String, FlowNode>.from(nodes);
    placement.forEach((id, center) {
      final node = nodes[id]!;
      final topLeft = convert(center, node) + offset;
      if (topLeft != node.position) {
        next[id] = node.copyWith(position: topLeft);
      }
    });
    return next;
  }

  // ── layered pass ───────────────────────────────────────────────────

  /// Longest-path layers + barycenter order + packed centers per component.
  ///
  /// [inputOrder] (map order) seeds the within-layer order so ties and
  /// neighborless nodes stay stable and predictable.
  static Map<String, math.Point<double>> _layerComponent(
    List<String> component,
    List<String> inputOrder,
    Map<String, FlowNode> nodes,
    Map<String, FlowEdge> edges,
    double Function(FlowNode) widthOf,
    double Function(FlowNode) heightOf,
    double nodeSpacing,
    double layerSpacing,
  ) {
    final members = component.toSet();
    final predecessors = <String, List<String>>{
      for (final id in component) id: [],
    };
    final successors = <String, List<String>>{
      for (final id in component) id: [],
    };
    for (final edge in edges.values) {
      if (edge.sourceNodeId == edge.targetNodeId) continue;
      if (!members.contains(edge.sourceNodeId) ||
          !members.contains(edge.targetNodeId)) {
        continue;
      }
      successors[edge.sourceNodeId]!.add(edge.targetNodeId);
      predecessors[edge.targetNodeId]!.add(edge.sourceNodeId);
    }

    // Longest-path layering (Kahn); cyclic leftovers anchor greedily so
    // feedback edges span backwards instead of hanging the pass.
    final layerOf = <String, int>{};
    final inDegree = <String, int>{
      for (final id in component) id: predecessors[id]!.length,
    };
    final queue = [
      for (final id in component)
        if (inDegree[id] == 0) id,
    ];
    for (final id in queue) {
      layerOf[id] = 0;
    }
    var head = 0;
    while (head < queue.length) {
      final current = queue[head++];
      for (final next in successors[current]!) {
        inDegree[next] = inDegree[next]! - 1;
        layerOf[next] =
            math.max(layerOf[next] ?? 0, layerOf[current]! + 1);
        if (inDegree[next] == 0) queue.add(next);
      }
    }
    var leftovers =
        component.where((id) => !layerOf.containsKey(id)).toList();
    while (leftovers.isNotEmpty) {
      leftovers.sort((a, b) {
        final assignedA =
            predecessors[a]!.where(layerOf.containsKey).length;
        final assignedB =
            predecessors[b]!.where(layerOf.containsKey).length;
        return assignedB.compareTo(assignedA);
      });
      final id = leftovers.first;
      var layer = 0;
      for (final pred in predecessors[id]!) {
        if (layerOf.containsKey(pred)) {
          layer = math.max(layer, layerOf[pred]! + 1);
        }
      }
      layerOf[id] = layer;
      leftovers = leftovers.sublist(1);
    }

    final maxLayer = layerOf.values.fold(0, math.max);
    final order = List<List<String>>.generate(maxLayer + 1, (_) => []);
    final memberSet = component.toSet();
    for (final id in inputOrder) {
      if (memberSet.contains(id)) {
        order[layerOf[id]!].add(id);
      }
    }

    // Barycenter crossing reduction (down/up sweep pairs, stable ties).
    final centers = <String, double>{};
    for (var sweep = 0; sweep < 2; sweep++) {
      for (var layer = 1; layer <= maxLayer; layer++) {
        _barySort(order[layer], (id) => predecessors[id]!,
            (id) => centers[id], centers, nodes, widthOf, nodeSpacing);
      }
      for (var layer = maxLayer - 1; layer >= 0; layer--) {
        _barySort(order[layer], (id) => successors[id]!,
            (id) => centers[id], centers, nodes, widthOf, nodeSpacing);
      }
    }

    // Pack each layer, center on the widest, band vertically.
    var widest = 0.0;
    final layerWidths = <double>[];
    for (final layer in order) {
      var width = 0.0;
      for (final id in layer) {
        width += widthOf(nodes[id]!);
      }
      if (layer.isNotEmpty) width += nodeSpacing * (layer.length - 1);
      layerWidths.add(width);
      widest = math.max(widest, width);
    }
    final depths = {for (final id in component) id: layerOf[id]!};
    final bands = _bandTops(depths, nodes, heightOf, layerSpacing);

    final placement = <String, math.Point<double>>{};
    for (var layer = 0; layer < order.length; layer++) {
      var cursor = (widest - layerWidths[layer]) / 2;
      for (final id in order[layer]) {
        final node = nodes[id]!;
        final center = cursor + widthOf(node) / 2;
        centers[id] = center;
        // y is the band CENTER (like x); [_materialize] converts to top-left.
        placement[id] = math.Point(center, bands[layer]!.top + bands[layer]!.height / 2);
        cursor += widthOf(node) + nodeSpacing;
      }
    }
    return placement;
  }

  /// One stable barycenter sort of [layer] by [neighbors]' centers.
  static void _barySort(
    List<String> layer,
    List<String> Function(String id) neighborsOf,
    double? Function(String id) centerOf,
    Map<String, double> centers,
    Map<String, FlowNode> nodes,
    double Function(FlowNode) widthOf,
    double nodeSpacing,
  ) {
    final index = {for (var i = 0; i < layer.length; i++) layer[i]: i};
    final keys = <String, double>{};
    for (final id in layer) {
      var sum = 0.0;
      var count = 0;
      for (final neighbor in neighborsOf(id)) {
        final center = centerOf(neighbor);
        if (center != null) {
          sum += center;
          count++;
        }
      }
      keys[id] = count == 0 ? index[id]!.toDouble() : sum / count;
    }
    layer.sort((a, b) {
      final order = keys[a]!.compareTo(keys[b]!);
      return order != 0 ? order : index[a]!.compareTo(index[b]!);
    });
    // Refresh centers left-to-right so later layers barycenter on the new
    // order within the same sweep (Gauss-Seidel converges faster).
    var cursor = 0.0;
    for (final id in layer) {
      final center = cursor + widthOf(nodes[id]!) / 2;
      centers[id] = center;
      cursor += widthOf(nodes[id]!) + nodeSpacing;
    }
  }

  // ── tidy-tree pass (Buchheim) ──────────────────────────────────────

  /// Buchheim tidy positions (x centers; y banded by the caller).
  static Map<String, math.Point<double>> _tidyTree(
    String rootId,
    Map<String, FlowNode> nodes,
    Map<String, List<String>> successors,
    Set<String> visitedGlobal,
    Map<String, int> depths,
    double Function(FlowNode) widthOf,
    double nodeSpacing,
  ) {
    // DFS tree (back/cross edges skipped so cycles terminate; nodes
    // claimed by an earlier forest tree are never re-added).
    final treeNodes = <String, _TreeNode>{};
    _TreeNode build(
        String id, _TreeNode? parent, Set<String> visiting, int depth) {
      final node = treeNodes.putIfAbsent(id, () => _TreeNode(id));
      node.parent ??= parent;
      depths[id] = depth;
      if (!visiting.add(id)) return node;
      for (final childId in successors[id] ?? const []) {
        if (visiting.contains(childId)) continue;
        if (treeNodes.containsKey(childId)) continue;
        if (visitedGlobal.contains(childId)) continue;
        final child = build(childId, node, visiting, depth + 1);
        child.index = node.children.length;
        node.children.add(child);
      }
      visiting.remove(id);
      visitedGlobal.add(id);
      return node;
    }

    final root = build(rootId, null, {}, 0);
    double distance(_TreeNode a, _TreeNode b) =>
        nodeSpacing +
        widthOf(nodes[a.id]!) / 2 +
        widthOf(nodes[b.id]!) / 2;

    void firstWalk(_TreeNode v) {
      v.ancestor ??= v;
      if (v.children.isEmpty) {
        final sibling = _leftSibling(v);
        if (sibling != null) {
          v.x = sibling.x + distance(v, sibling);
        }
        return;
      }
      var defaultAncestor = v.children.first;
      for (final child in v.children) {
        firstWalk(child);
        defaultAncestor = _apportion(child, defaultAncestor, distance);
      }
      _executeShifts(v);
      final midpoint =
          (v.children.first.x + v.children.last.x) / 2;
      final sibling = _leftSibling(v);
      if (sibling != null) {
        v.x = sibling.x + distance(v, sibling);
        v.mod = v.x - midpoint;
      } else {
        v.x = midpoint;
      }
    }

    firstWalk(root);
    final placement = <String, math.Point<double>>{};
    void secondWalk(_TreeNode v, double mod) {
      placement[v.id] = math.Point(v.x + mod, 0);
      for (final child in v.children) {
        secondWalk(child, mod + v.mod);
      }
    }

    secondWalk(root, 0);
    // Normalize so the leftmost center sits at its half width (x >= 0).
    var minX = double.infinity;
    for (final entry in placement.entries) {
      minX = math.min(
          minX, entry.value.x - widthOf(nodes[entry.key]!) / 2);
    }
    if (minX.isFinite && minX != 0) {
      for (final id in placement.keys.toList()) {
        placement[id] = math.Point(placement[id]!.x - minX, 0);
      }
    }
    return placement;
  }

  static _TreeNode? _leftSibling(_TreeNode v) {
    final parent = v.parent;
    if (parent == null) return null;
    final index = parent.children.indexOf(v);
    return index > 0 ? parent.children[index - 1] : null;
  }

  static _TreeNode? _nextLeft(_TreeNode v) =>
      v.thread ?? (v.children.isEmpty ? null : v.children.first);

  static _TreeNode? _nextRight(_TreeNode v) =>
      v.thread ?? (v.children.isEmpty ? null : v.children.last);

  static void _executeShifts(_TreeNode v) {
    var shift = 0.0;
    var change = 0.0;
    for (var i = v.children.length - 1; i >= 0; i--) {
      final child = v.children[i];
      child.x += shift;
      child.mod += shift;
      change += child.change;
      shift += child.shift + change;
    }
  }

  static void _moveSubtree(
      _TreeNode left, _TreeNode right, double shift) {
    // Sibling-index difference (both are direct children of one parent —
    // guaranteed by [_ancestor]), NOT global preorder numbers: only the
    // spanned sibling range shares the shift bookkeeping.
    final subtrees = right.index - left.index;
    right.change -= shift / subtrees;
    right.shift += shift;
    left.change += shift / subtrees;
    right.x += shift;
    right.mod += shift;
  }

  static _TreeNode _ancestor(
      _TreeNode vim, _TreeNode v, _TreeNode defaultAncestor) {
    final parent = v.parent;
    if (parent != null &&
        vim.ancestor != null &&
        parent.children.contains(vim.ancestor)) {
      return vim.ancestor!;
    }
    return defaultAncestor;
  }

  static _TreeNode _apportion(
    _TreeNode v,
    _TreeNode defaultAncestor,
    double Function(_TreeNode a, _TreeNode b) distance,
  ) {
    final left = _leftSibling(v);
    if (left == null) return defaultAncestor;
    var vip = v;
    var vop = v;
    var vim = left;
    var vom = vip.parent!.children.first;
    var sip = vip.mod;
    var sop = vop.mod;
    var sim = vim.mod;
    var som = vom.mod;
    while (_nextRight(vim) != null && _nextLeft(vip) != null) {
      vim = _nextRight(vim)!;
      vip = _nextLeft(vip)!;
      vom = _nextLeft(vom)!;
      vop = _nextRight(vop)!;
      vop.ancestor = v;
      final shift =
          (vim.x + sim) - (vip.x + sip) + distance(vim, vip);
      if (shift > 0) {
        _moveSubtree(_ancestor(vim, v, defaultAncestor), v, shift);
        sip += shift;
        sop += shift;
      }
      sim += vim.mod;
      sip += vip.mod;
      som += vom.mod;
      sop += vop.mod;
    }
    if (_nextRight(vim) != null && _nextRight(vop) == null) {
      vop.thread = _nextRight(vim);
      vop.mod += sim - sop;
    }
    if (_nextLeft(vip) != null && _nextLeft(vom) == null) {
      vom.thread = _nextLeft(vip);
      vom.mod += sip - som;
      defaultAncestor = v;
    }
    return defaultAncestor;
  }
}

/// Buchheim working node (see [FlowLayout.tree]).
class _TreeNode {
  _TreeNode(this.id);

  final String id;
  _TreeNode? parent;
  final List<_TreeNode> children = [];

  /// Position within [parent]'s children (sibling order).
  int index = 0;
  double x = 0;
  double mod = 0;
  double shift = 0;
  double change = 0;
  _TreeNode? ancestor;
  _TreeNode? thread;
}
