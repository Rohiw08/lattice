import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'node.dart';

/// Builder bag for custom node widgets (Lattice `NodeProps`-style).
///
/// Prefer this over raw [FlowNode] when registering with
/// [NodeRegistry.registerTyped]: [data] is typed, and [selected] / [dragging] /
/// [hovered] reflect live interaction state.
///
/// Use [node] when you need the full model (handles, flags, [FlowNode.copyWith]).
@immutable
class NodeProps<T> {
  const NodeProps({
    required this.id,
    required this.type,
    required this.data,
    required this.position,
    required this.size,
    required this.selected,
    required this.dragging,
    required this.hovered,
    required this.node,
    this.parentId,
  });

  /// Builds props from a [FlowNode] plus live runtime flags.
  factory NodeProps.fromNode(
    FlowNode node, {
    bool selected = false,
    bool dragging = false,
    bool hovered = false,
  }) {
    return NodeProps(
      id: node.id,
      type: node.type,
      data: node.data as T?,
      position: node.position,
      size: node.size,
      selected: selected,
      dragging: dragging,
      hovered: hovered,
      parentId: node.parentId,
      node: node,
    );
  }

  final String id;
  final String type;
  final T? data;
  final Offset position;
  final Size size;
  final bool selected;
  final bool dragging;
  final bool hovered;
  final String? parentId;

  /// Full node model for advanced cases (handles, copyWith, flags).
  final FlowNode node;

  /// Re-types [data] for typed builders. Throws if [data] is not [R].
  NodeProps<R> cast<R>() {
    return NodeProps<R>(
      id: id,
      type: type,
      data: data as R?,
      position: position,
      size: size,
      selected: selected,
      dragging: dragging,
      hovered: hovered,
      parentId: parentId,
      node: node,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is NodeProps<T> &&
            other.id == id &&
            other.type == type &&
            other.data == data &&
            other.position == position &&
            other.size == size &&
            other.selected == selected &&
            other.dragging == dragging &&
            other.hovered == hovered &&
            other.parentId == parentId &&
            other.node == node;
  }

  @override
  int get hashCode => Object.hash(
        id,
        type,
        data,
        position,
        size,
        selected,
        dragging,
        hovered,
        parentId,
        node,
      );
}
