import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/painting.dart';

/// Lattice–compatible node layout helpers.
///
/// When [FlowNode.parentId] is set, [FlowNode.position] is **relative** to the
/// parent's stored position (Lattice sub-flow default). [FlowNode.position]
/// always marks the node's **anchor point** — the point inside the node at
/// its origin (see [resolveOrigin]). Flow-space drawing, hit-testing, and
/// edges use the visual rect from [absoluteRect], which shifts the anchor by
/// the origin; stored positions, drag math, and snapping stay in anchor
/// space, exactly like Lattice `XYDrag`.
abstract final class NodeLayout {
  const NodeLayout._();

  /// Resolves the origin (anchor fractions, `0..1` per axis) for [node].
  ///
  /// Per-node [FlowNode.origin] wins; otherwise the canvas
  /// `NodeOptions.nodeOrigin` passed as [defaultOrigin].
  static Offset resolveOrigin(
    FlowNode node, [
    Offset defaultOrigin = Offset.zero,
  ]) =>
      node.origin ?? defaultOrigin;

  /// Pixel shift from a node's anchor to its visual top-left.
  static Offset anchorShift(FlowNode node,
      [Offset defaultOrigin = Offset.zero]) {
    final o = resolveOrigin(node, defaultOrigin);
    return Offset(o.dx * node.size.width, o.dy * node.size.height);
  }

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
  ///
  /// The visual rect: anchor chain minus this node's own origin shift.
  /// Children anchor to the parent's stored position (not its visual
  /// top-left), so only the node's *own* origin shifts its rect.
  static Rect absoluteRect(
    FlowNode node,
    Map<String, FlowNode> nodes, {
    Map<String, Offset>? livePositions,
    Offset defaultOrigin = Offset.zero,
  }) {
    final anchor = absolutePosition(
      node.id,
      nodes,
      livePositions: livePositions,
    );
    final shift = anchorShift(node, defaultOrigin);
    return Rect.fromLTWH(anchor.dx - shift.dx, anchor.dy - shift.dy,
        node.size.width, node.size.height);
  }

  /// Absolute visual top-left of [nodeId] in flow coordinates.
  static Offset absoluteTopLeft(
    String nodeId,
    Map<String, FlowNode> nodes, {
    Map<String, Offset>? livePositions,
    Offset defaultOrigin = Offset.zero,
  }) {
    final node = nodes[nodeId];
    final anchor =
        absolutePosition(nodeId, nodes, livePositions: livePositions);
    if (node == null) return anchor;
    return anchor - anchorShift(node, defaultOrigin);
  }

  /// Clamp a **parent-relative anchor** so the child's *visual rect* stays
  /// inside the parent (Lattice `extent: 'parent'`).
  ///
  /// [childOrigin] is the child's resolved origin; the default (`Offset.zero`)
  /// reproduces the old top-left behavior exactly.
  static Offset clampToParent(
    Offset relative,
    Size childSize,
    Size parentSize, {
    Offset childOrigin = Offset.zero,
  }) {
    final minX = childOrigin.dx * childSize.width;
    final minY = childOrigin.dy * childSize.height;
    // Guard max >= min so oversized children pin instead of throwing
    // (`double.clamp` requires min <= max).
    final maxX = mathMax(
        minX, parentSize.width - (1 - childOrigin.dx) * childSize.width);
    final maxY = mathMax(
        minY, parentSize.height - (1 - childOrigin.dy) * childSize.height);
    return Offset(
      relative.dx.clamp(minX, maxX),
      relative.dy.clamp(minY, maxY),
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
    Offset childOrigin = Offset.zero,
  }) {
    var parentPos = parentPosition;
    var pSize = parentSize;
    var cPos = childPosition;
    var mutated = false;

    // Visual edges of the child (anchor minus origin shift).
    final shiftX = childOrigin.dx * childSize.width;
    final shiftY = childOrigin.dy * childSize.height;

    final left = cPos.dx - shiftX;
    if (left < 0) {
      parentPos = Offset(parentPos.dx + left, parentPos.dy);
      pSize = Size(pSize.width - left, pSize.height);
      cPos = Offset(cPos.dx - left, cPos.dy);
      mutated = true;
    }
    final top = cPos.dy - shiftY;
    if (top < 0) {
      parentPos = Offset(parentPos.dx, parentPos.dy + top);
      pSize = Size(pSize.width, pSize.height - top);
      cPos = Offset(cPos.dx, cPos.dy - top);
      mutated = true;
    }
    final right = cPos.dx + (childSize.width - shiftX);
    if (right > pSize.width) {
      pSize = Size(right, pSize.height);
      mutated = true;
    }
    final bottom = cPos.dy + (childSize.height - shiftY);
    if (bottom > pSize.height) {
      pSize = Size(pSize.width, bottom);
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
  /// [expandParentDefault] is the canvas-level default for children that
  /// don't set the flag. Boxes are child *visual* rects in the parent's
  /// stored frame (parent anchor + child anchor − child origin shift).
  static Rect? childExtentFloor(
    String parentId,
    Map<String, FlowNode> nodes, {
    Offset defaultOrigin = Offset.zero,
    bool expandParentDefault = false,
  }) {
    final parent = nodes[parentId];
    if (parent == null) return null;

    Rect? union;
    for (final child in nodes.values) {
      if (child.parentId != parentId) continue;
      if (child.extent != FlowNodeExtent.parent &&
          !(child.expandParent || expandParentDefault)) {
        continue;
      }

      final shift = anchorShift(child, defaultOrigin);
      final box = Rect.fromLTWH(
        parent.position.dx + child.position.dx - shift.dx,
        parent.position.dy + child.position.dy - shift.dy,
        child.size.width,
        child.size.height,
      );
      union = union == null ? box : union.expandToInclude(box);
    }
    return union;
  }

  static double mathMax(double a, double b) => a > b ? a : b;
}
