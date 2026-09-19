import 'dart:math' as math;
import 'dart:ui';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/handles/domain/handle.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';

class NodeService {
  FlowNode? getNode(FlowCanvasState state, String nodeId) {
    if (!state.nodes.containsKey(nodeId)) return null;
    return state.nodes[nodeId]!;
  }

  NodeRuntimeState? getNodeRuntimeState(FlowCanvasState state, String nodeId) {
    if (!state.nodeStates.containsKey(nodeId)) return null;
    return state.nodeStates[nodeId]!;
  }

  FlowCanvasState addNode(FlowCanvasState state, FlowNode node,
      {ZIndexMode zIndexMode = ZIndexMode.auto}) {
    return addNodes(state, [node], zIndexMode: zIndexMode);
  }

  FlowCanvasState addNodes(
    FlowCanvasState state,
    Iterable<FlowNode> nodes, {
    ZIndexMode zIndexMode = ZIndexMode.auto,
  }) {
    if (nodes.isEmpty) return state;

    final newNodes = Map<String, FlowNode>.from(state.nodes);
    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    var nextZ = state.maxZIndex;

    for (final node in nodes) {
      if (newNodes.containsKey(node.id)) continue;

      // Lattice rule (ZIndexMode.auto only): child z must be strictly above
      // parent (within its render band). Basic/manual leave z untouched;
      // manual additionally skips the next-z allocation entirely.
      var assignedZ = node.zIndex;
      if (zIndexMode != ZIndexMode.manual) {
        assignedZ = math.max(nextZ + 1, node.zIndex);
      }
      final parentId = node.parentId;
      if (zIndexMode == ZIndexMode.auto && parentId != null) {
        final parent = newNodes[parentId] ?? state.nodes[parentId];
        if (parent != null) {
          assignedZ = math.max(assignedZ, parent.zIndex + 1);
        }
      }

      nextZ = math.max(nextZ, assignedZ);

      final newNode = node.copyWith(zIndex: assignedZ);
      newNodes[newNode.id] = newNode;
      // Initialize a default runtime state so nodes are interactable immediately
      if (!newNodeStates.containsKey(newNode.id)) {
        newNodeStates[newNode.id] = const NodeRuntimeState();
      }
    }

    // Second pass: if a parent was added in this batch after its children,
    // bump any children that ended up at or below the parent (auto only).
    if (zIndexMode == ZIndexMode.auto) {
      _ensureChildrenAboveParents(newNodes);
    }

    var maxZ = state.maxZIndex;
    var newMinZ = state.minZIndex;
    for (final n in newNodes.values) {
      maxZ = math.max(maxZ, n.zIndex);
      newMinZ = math.min(newMinZ, n.zIndex);
    }

    return state.copyWith(
      nodes: newNodes,
      nodeStates: newNodeStates,
      maxZIndex: maxZ,
      minZIndex: newMinZ,
    );
  }

  /// Ensures every child has `zIndex > parent.zIndex` (Lattice child rule).
  static void _ensureChildrenAboveParents(Map<String, FlowNode> nodes) {
    var changed = true;
    // Few passes are enough for shallow nesting; cap to avoid pathological loops.
    for (var i = 0; i < 8 && changed; i++) {
      changed = false;
      for (final entry in nodes.entries) {
        final parentId = entry.value.parentId;
        if (parentId == null) continue;
        final parent = nodes[parentId];
        if (parent == null) continue;
        if (entry.value.zIndex <= parent.zIndex) {
          nodes[entry.key] =
              entry.value.copyWith(zIndex: parent.zIndex + 1);
          changed = true;
        }
      }
    }
  }

  FlowCanvasState removeNode(FlowCanvasState state, String nodeId) {
    return removeNodes(state, [nodeId]);
  }

/// Removes nodes (Lattice `deleteElements` semantics).
  ///
  /// Removing a parent also removes its descendants (`parentHit`), and nodes
  /// with `deletable: false` are never removed — neither explicitly nor via
  /// a parent cascade. [nodesDeletable] is the canvas-level default
  /// (`NodeOptions.deletable`) for nodes that don't set the flag.
  FlowCanvasState removeNodes(
    FlowCanvasState state,
    List<String> nodeIds, {
    bool nodesDeletable = true,
  }) {
    if (nodeIds.isEmpty) return state;

    final newNodes = Map<String, FlowNode>.from(state.nodes);
    final newSelectedNodes = Set<String>.from(state.selectedNodes);

    final nodeIdSet = <String>{};
    for (final id in nodeIds) {
      nodeIdSet.addAll(getDescendants(state, [id]));
    }

    for (final nodeId in nodeIdSet) {
      final node = newNodes[nodeId];
      if (node == null) continue;
      if (!(node.deletable ?? nodesDeletable)) continue;
      newNodes.remove(nodeId)!;
      newSelectedNodes.remove(nodeId);
    }

    return state.copyWith(
      nodes: newNodes,
      selectedNodes: newSelectedNodes,
    );
  }

  FlowCanvasState moveSelectedNodes(
    FlowCanvasState state,
    Offset delta, {
    Offset defaultOrigin = Offset.zero,
    bool nodesDraggable = true,
    bool expandParentDefault = false,
  }) {
    return moveNodes(state, state.selectedNodes, delta,
        defaultOrigin: defaultOrigin,
        nodesDraggable: nodesDraggable,
        expandParentDefault: expandParentDefault);
  }

  FlowCanvasState moveNodes(
      FlowCanvasState state, Iterable<String> nodeIds, Offset delta,
      {bool includeDescendants = false,
      CoordinateExtent? nodeExtent,
      Offset defaultOrigin = Offset.zero,
      bool nodesDraggable = true,
      bool expandParentDefault = false}) {
    if (delta == Offset.zero || nodeIds.isEmpty) return state;

    final newNodes = Map<String, FlowNode>.from(state.nodes);

    // With Lattice-relative children, moving a parent does not rewrite child
    // positions. [includeDescendants] remains for rare absolute-style callers.
    final Set<String> allNodesToMove =
        includeDescendants ? getDescendants(state, nodeIds) : nodeIds.toSet();

    for (final id in allNodesToMove) {
      final node = newNodes[id];
      if (node == null) continue;
      final draggable = node.draggable ?? nodesDraggable;
      if (draggable) {
        var newPosition = node.position + delta;
        final origin = NodeLayout.resolveOrigin(node, defaultOrigin);
        final shift = Offset(origin.dx * node.size.width,
            origin.dy * node.size.height);

        // 0. Global nodeExtent clamping (absolute / root nodes).
        // The extent bounds the visual rect; the stored anchor clamps into
        // the extent shifted by the origin (identical when top-left).
        if (nodeExtent != null &&
            !nodeExtent.isInfinite &&
            node.parentId == null) {
          newPosition = Offset(
            (newPosition.dx - shift.dx)
                    .clamp(nodeExtent.minX, nodeExtent.maxX - node.size.width) +
                shift.dx,
            (newPosition.dy - shift.dy)
                    .clamp(nodeExtent.minY, nodeExtent.maxY - node.size.height) +
                shift.dy,
          );
        }

        // 1. Check Runtime Extent
        final runtimeState = state.nodeStates[id];
        if (runtimeState?.extent != null) {
          final extent = runtimeState!.extent!;
          newPosition =
              _clampPositionToRect(newPosition, node.size, extent, origin);
        }

        // 2. Lattice `extent: 'parent'`
        if (node.extent == FlowNodeExtent.parent && node.parentId != null) {
          final parent = newNodes[node.parentId!];
          if (parent != null) {
            newPosition = NodeLayout.clampToParent(
                newPosition, node.size, parent.size,
                childOrigin: origin);
          }
        }

        final newNode = node.copyWith(position: newPosition);
        newNodes[id] = newNode;
      }
    }

    var next = state.copyWith(nodes: newNodes);
    return applyExpandParent(next, allNodesToMove,
        defaultOrigin: defaultOrigin,
        expandParentDefault: expandParentDefault);
  }

/// Grows parents when children with [FlowNode.expandParent] sit outside
  /// (Lattice `expandParent` + `handleExpandParent`). Positions are
  /// parent-relative.
  ///
  /// Matches Lattice: the dragged child is clamped to the parent's new origin
  /// (`>= 0` relative), and **sibling children not in [movedIds] shift by the
  /// parent's origin delta** so their absolute flow positions stay put.
  FlowCanvasState applyExpandParent(
    FlowCanvasState state,
    Iterable<String> movedIds, {
    Offset defaultOrigin = Offset.zero,
    bool expandParentDefault = false,
  }) {
    final moved = movedIds.toSet();
    final newNodes = Map<String, FlowNode>.from(state.nodes);
    var changed = false;

    for (final id in movedIds) {
      final node = newNodes[id];
      if (node == null ||
          !(node.expandParent || expandParentDefault) ||
          node.parentId == null) {
        continue;
      }
      final parent = newNodes[node.parentId!];
      if (parent == null) continue;

      final fit = NodeLayout.expandParentFit(
        parentPosition: parent.position,
        parentSize: parent.size,
        childPosition: node.position,
        childSize: node.size,
        childOrigin: NodeLayout.resolveOrigin(node, defaultOrigin),
      );
      if (fit == null) continue;

      changed = true;
      newNodes[parent.id] =
          parent.copyWith(position: fit.parentPosition, size: fit.parentSize);
      newNodes[id] = node.copyWith(position: fit.childPosition);

      final originDelta = fit.parentPosition - parent.position;
      for (final sibling in state.nodes.values) {
        if (sibling.parentId == parent.id && !moved.contains(sibling.id)) {
          newNodes[sibling.id] =
              sibling.copyWith(position: sibling.position - originDelta);
        }
      }
    }

    if (!changed) return state;
    return state.copyWith(nodes: newNodes);
  }

  Offset _clampPositionToRect(
      Offset position, Size size, Rect extent, Offset origin) {
    final shift =
        Offset(origin.dx * size.width, origin.dy * size.height);
    double x = position.dx - shift.dx;
    double y = position.dy - shift.dy;

    // Clamp visual rect, then shift back to anchor space.
    if (x < extent.left) x = extent.left;
    if (x + size.width > extent.right) x = extent.right - size.width;

    // Clamp y
    if (y < extent.top) y = extent.top;
    if (y + size.height > extent.bottom) y = extent.bottom - size.height;

    return Offset(x + shift.dx, y + shift.dy);
  }

FlowCanvasState updateNode(
    FlowCanvasState state,
    FlowNode node, {
    ZIndexMode zIndexMode = ZIndexMode.auto,
  }) {
    if (!state.nodes.containsKey(node.id)) return state;

    final newNodes = Map<String, FlowNode>.from(state.nodes);
    newNodes[node.id] = node;

    // Lattice `updateChildNode`: a parentId/zIndex change must keep every child
    // strictly above its parent (max(parentZ + 1, childZ)). Auto mode only.
    if (zIndexMode == ZIndexMode.auto) {
      _ensureChildrenAboveParents(newNodes);
      final parent = node.parentId != null ? newNodes[node.parentId!] : null;
      if (parent != null && newNodes[node.id]!.zIndex <= parent.zIndex) {
        newNodes[node.id] =
            newNodes[node.id]!.copyWith(zIndex: parent.zIndex + 1);
      }
    }

    var maxZ = state.maxZIndex;
    var minZ = state.minZIndex;
    for (final n in newNodes.values) {
      maxZ = math.max(maxZ, n.zIndex);
      minZ = math.min(minZ, n.zIndex);
    }

    return state.copyWith(
      nodes: newNodes,
      maxZIndex: maxZ,
      minZIndex: minZ,
    );
  }

  FlowCanvasState updateNodeRuntimeState(
      FlowCanvasState state, String nodeId, NodeRuntimeState runtime) {
    if (nodeId.isEmpty) return state;

    final newNodeStates = Map<String, NodeRuntimeState>.from(state.nodeStates);
    newNodeStates[nodeId] = runtime;
    return state.copyWith(
      nodeStates: newNodeStates,
    );
  }

  /// Resizes a single node directionally based on the gesture delta.
  ///
  /// Matches Lattice NodeResizer: when the parent's top/left (origin) moves,
  /// **direct children keep their absolute flow positions** by compensating
  /// their relative [FlowNode.position] (`child.pos -= originDelta`).
  ///
  /// [baseRect] anchors an absolute mapping for live gestures: pass the
  /// rect captured at resize start and the *accumulated* travel as [delta].
  /// The target is then `base + travel` (clamped), so pushing into the
  /// [NodeLayout.childExtentFloor] or min-size clamp and coming back leaves
  /// a dead zone instead of a permanent gap — the same absolute semantics
  /// as node drag (`XYDrag.updateNodes`). Without [baseRect] the delta
  /// applies to the current rect (one-shot/programmatic use).
  FlowCanvasState resizeNode(
    FlowCanvasState state,
    String nodeId,
    ResizeDirection direction,
    Offset delta, {
    Size minSize = const Size(50, 50),
    Rect? baseRect,
    Offset defaultOrigin = Offset.zero,
    bool expandParentDefault = false,
  }) {
    final node = state.nodes[nodeId];
    if (node == null || delta == Offset.zero) return state;

    final rect = baseRect ?? node.rect;
    double newLeft = rect.left;
    double newTop = rect.top;
    double newRight = rect.right;
    double newBottom = rect.bottom;

    switch (direction) {
      case ResizeDirection.topLeft:
        newLeft += delta.dx;
        newTop += delta.dy;
        break;
      case ResizeDirection.topRight:
        newTop += delta.dy;
        newRight += delta.dx;
        break;
      case ResizeDirection.bottomLeft:
        newLeft += delta.dx;
        newBottom += delta.dy;
        break;
      case ResizeDirection.bottomRight:
        newRight += delta.dx;
        newBottom += delta.dy;
        break;
      case ResizeDirection.top:
        newTop += delta.dy;
        break;
      case ResizeDirection.bottom:
        newBottom += delta.dy;
        break;
      case ResizeDirection.left:
        newLeft += delta.dx;
        break;
      case ResizeDirection.right:
        newRight += delta.dx;
        break;
    }

    // Lattice childExtent: children with extent:parent / expandParent set a floor
    // on how far the *moving* edges may shrink.
    final childExtent = NodeLayout.childExtentFloor(
        nodeId, state.nodes,
        defaultOrigin: defaultOrigin,
        expandParentDefault: expandParentDefault);
    if (childExtent != null) {
      final affectsLeft = direction == ResizeDirection.left ||
          direction == ResizeDirection.topLeft ||
          direction == ResizeDirection.bottomLeft;
      final affectsRight = direction == ResizeDirection.right ||
          direction == ResizeDirection.topRight ||
          direction == ResizeDirection.bottomRight;
      final affectsTop = direction == ResizeDirection.top ||
          direction == ResizeDirection.topLeft ||
          direction == ResizeDirection.topRight;
      final affectsBottom = direction == ResizeDirection.bottom ||
          direction == ResizeDirection.bottomLeft ||
          direction == ResizeDirection.bottomRight;

      if (affectsLeft) newLeft = math.min(newLeft, childExtent.left);
      if (affectsRight) newRight = math.max(newRight, childExtent.right);
      if (affectsTop) newTop = math.min(newTop, childExtent.top);
      if (affectsBottom) newBottom = math.max(newBottom, childExtent.bottom);
    }

    // Resolve size constraints (Lattice min/maxWidth/Height +
    // keepAspectRatio): the opposite edges stay anchored while the dragged
    // edges absorb width/height clamps. With no per-node constraints this
    // reproduces the old edge clamps exactly.
    final effectiveMin = node.minSize ?? minSize;
    final effectiveMax = node.maxSize;
    var width = newRight - newLeft;
    var height = newBottom - newTop;
    if (node.keepAspectRatio && rect.width > 0 && rect.height > 0) {
      final aspect = rect.width / rect.height;
      final scale = math.max(width / rect.width, height / rect.height);
      if (scale > 0) {
        width = rect.width * scale;
        height = width / aspect;
      }
    }
    width = math.max(width, effectiveMin.width);
    height = math.max(height, effectiveMin.height);
    if (effectiveMax != null) {
      width = math.min(width, effectiveMax.width);
      height = math.min(height, effectiveMax.height);
    }
    switch (direction) {
      case ResizeDirection.topLeft:
        newLeft = newRight - width;
        newTop = newBottom - height;
        break;
      case ResizeDirection.topRight:
        newRight = newLeft + width;
        newTop = newBottom - height;
        break;
      case ResizeDirection.bottomLeft:
        newLeft = newRight - width;
        newBottom = newTop + height;
        break;
      case ResizeDirection.bottomRight:
        newRight = newLeft + width;
        newBottom = newTop + height;
        break;
      case ResizeDirection.top:
        newTop = newBottom - height;
        newRight = newLeft + width;
        break;
      case ResizeDirection.bottom:
        newBottom = newTop + height;
        newRight = newLeft + width;
        break;
      case ResizeDirection.left:
        newLeft = newRight - width;
        newBottom = newTop + height;
        break;
      case ResizeDirection.right:
        newRight = newLeft + width;
        newBottom = newTop + height;
        break;
    }

    final newRect = Rect.fromLTRB(newLeft, newTop, newRight, newBottom);
    final oldSize = node.size;
    final newSize = newRect.size;
    final oldPos = node.position;
    final newPos = Offset(newRect.left, newRect.top);

    // Lattice `shouldResize`: veto before committing. The gesture keeps its
    // absolute base+travel anchor, so a veto dead-zones cleanly.
    final shouldResize = node.shouldResize;
    if (shouldResize != null &&
        !shouldResize(FlowResizeProposal(
          nodeId: nodeId,
          direction: direction,
          position: newPos,
          size: newSize,
        ))) {
      return state;
    }
    final originDelta = newPos - oldPos;

    // Proportionally update handle positions so they stay on the same relative spot
    final Map<String, FlowHandle> updatedHandles = {};
    if (oldSize.width > 0 && oldSize.height > 0) {
      node.effectiveHandles.forEach((id, handle) {
        final relX = handle.position.dx / oldSize.width;
        final relY = handle.position.dy / oldSize.height;
        updatedHandles[id] = handle.copyWith(
          position: Offset(relX * newSize.width, relY * newSize.height),
        );
      });
    }

    final newNode = node.copyWith(
      position: newPos,
      size: newSize,
      handles: updatedHandles.isEmpty ? node.effectiveHandles : updatedHandles,
    );

    var next = updateNode(state, newNode);

    // Lattice: when top/left moves, correct children so they stay put in flow space.
    if (originDelta != Offset.zero) {
      next = _compensateChildrenForParentOriginShift(
        next,
        parentId: nodeId,
        originDelta: originDelta,
      );
    }

    return next;
  }

  /// Subtracts [originDelta] from each direct child's relative position so
  /// their absolute flow positions are unchanged (parent-origin NodeResizer).
  FlowCanvasState _compensateChildrenForParentOriginShift(
    FlowCanvasState state, {
    required String parentId,
    required Offset originDelta,
  }) {
    final newNodes = Map<String, FlowNode>.from(state.nodes);
    var changed = false;

    for (final entry in state.nodes.entries) {
      final child = entry.value;
      if (child.parentId != parentId) continue;
      newNodes[entry.key] = child.copyWith(
        position: child.position - originDelta,
      );
      changed = true;
    }

    if (!changed) return state;
    return state.copyWith(nodes: newNodes);
  }

  /// Builds a parent→children adjacency map from [state] in one O(N) pass.
  ///
  /// The parent/child structure is stable across a drag gesture (only
  /// positions change), so callers on the drag hot path build this once at
  /// drag-start and pass it back into [getDescendants] every frame instead of
  /// rescanning all nodes each time.
  Map<String, List<String>> buildChildAdjacency(FlowCanvasState state) {
    final parentToChildren = <String, List<String>>{};
    for (final node in state.nodes.values) {
      if (node.parentId != null) {
        parentToChildren.putIfAbsent(node.parentId!, () => []).add(node.id);
      }
    }
    return parentToChildren;
  }

  /// returns a set of all descendant nodes for the given roots
  ///
  /// Pass [adjacency] (from [buildChildAdjacency]) to skip the O(N) parent
  /// scan — used on the drag hot path where the tree shape does not change.
  Set<String> getDescendants(
    FlowCanvasState state,
    Iterable<String> rootNodeIds, {
    Map<String, List<String>>? adjacency,
  }) {
    if (rootNodeIds.isEmpty) return {};

    final parentToChildren = adjacency ?? buildChildAdjacency(state);

    final allNodes = <String>{};
    final queue = List<String>.from(rootNodeIds);

    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (allNodes.contains(id)) continue;
      allNodes.add(id);

      final children = parentToChildren[id];
      if (children != null) {
        queue.addAll(children);
      }
    }
    return allNodes;
  }
}

