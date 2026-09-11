import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/painting.dart';

/// Lattice–compatible node layout helpers.
///
/// When [FlowNode.parentId] is set, [FlowNode.position] is **relative** to the
/// parent's top-left (Lattice sub-flow default). Flow-space drawing, hit-testing,
/// and edges always use [absolutePosition].
abstract final class NodeLayout {
  const NodeLayout._();

  /// Absolute top-left of [nodeId] in flow coordinates.
  ///
  /// [livePositions] maps node id → live **stored** position (relative if the
  /// node has a parent, absolute if it is a root) during drag.
  static Offset absolutePosition(
    String nodeId,
    Map<String, FlowNode> nodes, {
    Map<String, Offset>? livePositions,
  }) {
    final node = nodes[nodeId];
    if (node == null) return Offset.zero;

    var pos = livePositions?[nodeId] ?? node.position;
    var parentId = node.parentId;
    final seen = <String>{nodeId};

    while (parentId != null && seen.add(parentId)) {
      final parent = nodes[parentId];
      if (parent == null) break;
      final parentPos = livePositions?[parentId] ?? parent.position;
      pos = Offset(parentPos.dx + pos.dx, parentPos.dy + pos.dy);
      parentId = parent.parentId;
    }
    return pos;
  }

  /// Absolute bounds of [node] (uses [node.id] lookup in [nodes]).
  static Rect absoluteRect(
    FlowNode node,
    Map<String, FlowNode> nodes, {
    Map<String, Offset>? livePositions,
  }) {
    final origin = absolutePosition(
      node.id,
      nodes,
      livePositions: livePositions,
    );
    return Rect.fromLTWH(origin.dx, origin.dy, node.size.width, node.size.height);
  }

  /// Clamp a **parent-relative** position so the child stays inside the parent
  /// (Lattice `extent: 'parent'`).
  static Offset clampToParent(
    Offset relative,
    Size childSize,
    Size parentSize,
  ) {
    final maxX = mathMax(0.0, parentSize.width - childSize.width);
    final maxY = mathMax(0.0, parentSize.height - childSize.height);
    return Offset(
      relative.dx.clamp(0.0, maxX),
      relative.dy.clamp(0.0, maxY),
    );
  }

  /// Union rect of a parent + child when the child sits past the parent's
  /// edge (Lattice `expandParent`): grow the parent so the child fits.
  ///
  /// Returns the new parent position/size and the child position snapped to
  /// the parent's new origin (Lattice clamps the dragged child to `>= 0` relative).
  /// `null` when the child already fits inside the parent.
  static ({Offset parentPosition, Size parentSize, Offset childPosition})?
      expandParentFit({
    required Offset parentPosition,
    required Size parentSize,
    required Offset childPosition,
    required Size childSize,
  }) {
    var parentPos = parentPosition;
    var pSize = parentSize;
    var cPos = childPosition;
    var mutated = false;

    if (cPos.dx < 0) {
      parentPos = Offset(parentPos.dx + cPos.dx, parentPos.dy);
      pSize = Size(pSize.width - cPos.dx, pSize.height);
      cPos = Offset(0, cPos.dy);
      mutated = true;
    }
    if (cPos.dy < 0) {
      parentPos = Offset(parentPos.dx, parentPos.dy + cPos.dy);
      pSize = Size(pSize.width, pSize.height - cPos.dy);
      cPos = Offset(cPos.dx, 0);
      mutated = true;
    }
    if (cPos.dx + childSize.width > pSize.width) {
      pSize = Size(cPos.dx + childSize.width, pSize.height);
      mutated = true;
    }
    if (cPos.dy + childSize.height > pSize.height) {
      pSize = Size(pSize.width, cPos.dy + childSize.height);
      mutated = true;
    }

    if (!mutated) return null;
    return (
      parentPosition: parentPos,
      parentSize: pSize,
      childPosition: cPos,
    );
  }

  /// Union of direct children that constrain parent resize (canvas
  /// `nodeToChildExtent` / `childExtent`).
  ///
  /// Includes children with [FlowNodeExtent.parent] or [FlowNode.expandParent].
  /// Coordinates match the parent's **stored** rect (parent.pos + child.pos).
  static Rect? childExtentFloor(
    String parentId,
    Map<String, FlowNode> nodes,
  ) {
    final parent = nodes[parentId];
    if (parent == null) return null;

    Rect? union;
    for (final child in nodes.values) {
      if (child.parentId != parentId) continue;
      if (child.extent != FlowNodeExtent.parent && !child.expandParent) {
        continue;
      }

      final box = Rect.fromLTWH(
        parent.position.dx + child.position.dx,
        parent.position.dy + child.position.dy,
        child.size.width,
        child.size.height,
      );
      union = union == null ? box : union.expandToInclude(box);
    }
    return union;
  }

  static double mathMax(double a, double b) => a > b ? a : b;
}
