// ignore_for_file: invalid_annotation_target, deprecated_member_use
// JsonKey on freezed factory params is copied to the generated field by
// freezed (see edge.dart, which uses the same convention).
import 'dart:math' as math;
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/theme/components/node_theme.dart';
import 'package:lattice/src/features/handles/domain/handle.dart';
import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/utils/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'node.freezed.dart';
part 'node.g.dart';

@Freezed(genericArgumentFactories: true)
abstract class FlowNode<T> with _$FlowNode<T> {
  const FlowNode._();

  // The primary, generated constructor
  const factory FlowNode({
    /// Unique identifier for this node.
    required String id,

    /// Optional ID of the parent node (for nested/grouped nodes).
    String? parentId,

    /// Type identifier for this node (e.g., 'default', 'input', 'output').
    required String type,

    /// Node position in flow coordinates.
    ///
    /// When [parentId] is null this is absolute (graph space).
    /// When [parentId] is set this is **relative to the parent’s top-left**,
    /// matching Lattice sub-flows (`{ x: 0, y: 0 }` = parent origin).
    @OffsetConverter() required Offset position,

    /// Custom data attached to this node.
    ///
    /// Optional, like Lattice's `data` (defaults to `{}` there, `null`
    /// here). The built-in node widgets never render it — your node widget
    /// decides how (and whether) to display `props.data`.
    T? data,

    /// Size of the node in logical pixels.
    @Default(Size(160, 44)) @SizeConverter() Size size,

    /// Z-index for rendering order (higher values render on top).
    @Default(0) int zIndex,

    /// Map of handles (connection points) attached to this node.
    @Default({}) Map<String, FlowHandle> handles,

    /// Whether this node should be hidden from view.
    @Default(false) bool? hidden,

    /// Whether this node can be dragged by the user.
    @Default(true) bool? draggable,

    /// Whether this node can be selected by the user.
    @Default(true) bool? selectable,

    /// Whether this node can be hovered by the user.
    @Default(true) bool? hoverable,

    /// Whether edges can be connected to/from this node.
    @Default(true) bool? connectable,

    /// Whether this node can be deleted by the user.
    @Default(true) bool? deletable,

    /// Whether this node can be resized by the user.
    @Default(true) bool? resizable,

    /// Whether this node can receive keyboard focus.
    @Default(true) bool? focusable,

    /// Grow the parent when this node is dragged past its edge (Lattice default: false).
    @Default(false) bool expandParent,

    /// Movement boundary (Lattice `extent`). `null` = unbounded (Lattice default).
    FlowNodeExtent? extent,

    /// Per-node visual style, merged over the theme's node style.
    ///
    /// Like `FlowEdge.style`: applied on top of the canvas theme for this
    /// node only. Not serialized.
    @JsonKey(ignore: true) FlowNodeStyle? style,
  }) = _FlowNode<T>;

  factory FlowNode.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$FlowNodeFromJson(json, fromJsonT);

  /// Custom factory method to create a FlowNode with common defaults.
  factory FlowNode.create({
    required String id,
    String? parentId,
    required String type,
    required Offset position,
    T? data,
    Size size = const Size(160, 44),
    int zIndex = 0,
    Map<String, FlowHandle> handles = const {},
    bool? hidden,
    bool? draggable,
    bool? selectable,
    bool? hoverable,
    bool? connectable,
    bool? deletable,
    bool? resizable,
    bool? focusable,
    bool expandParent = false,
    FlowNodeExtent? extent,
    FlowNodeStyle? style,
  }) {
    return FlowNode(
      id: id,
      type: type,
      position: position,
      size: size,
      parentId: parentId,
      data: data,
      handles: handles,
      zIndex: zIndex,
      hidden: hidden,
      draggable: draggable,
      selectable: selectable,
      hoverable: hoverable,
      connectable: connectable,
      deletable: deletable,
      resizable: resizable,
      focusable: focusable,
      expandParent: expandParent,
      extent: extent,
      style: style,
    );
  }

  /// Stored-space center (relative when parented).
  Offset get center => Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );

  /// Handles actually used by the renderer and connection logic.
  ///
  /// When [handles] is empty and [type] is a built-in node type
  /// (`default` / `input` / `output`), the standard Lattice handles are
  /// synthesized from [size] — so `FlowNode(id: ..., type: 'default', ...)`
  /// is directly connectable, exactly like Lattice's built-in components.
  Map<String, FlowHandle> get effectiveHandles {
    if (handles.isNotEmpty) return handles;
    switch (type) {
      case 'default':
        return {
          'target':
              _builtInHandle('target', HandleType.target, HandlePosition.top),
          'source': _builtInHandle(
              'source', HandleType.source, HandlePosition.bottom),
        };
      case 'input':
        return {
          'source': _builtInHandle(
              'source', HandleType.source, HandlePosition.bottom),
        };
      case 'output':
        return {
          'target':
              _builtInHandle('target', HandleType.target, HandlePosition.top),
        };
      default:
        return const {};
    }
  }

  FlowHandle _builtInHandle(String id, HandleType type, HandlePosition side) {
    return FlowHandle(
      id: id,
      type: type,
      position: _builtInHandleOffset(side, size),
      size: const Size(6, 6),
    );
  }

  static Offset _builtInHandleOffset(HandlePosition side, Size nodeSize) {
    switch (side) {
      case HandlePosition.top:
        return Offset(nodeSize.width / 2, 0);
      case HandlePosition.bottom:
        return Offset(nodeSize.width / 2, nodeSize.height);
      case HandlePosition.left:
        return Offset(0, nodeSize.height / 2);
      case HandlePosition.right:
        return Offset(nodeSize.width, nodeSize.height / 2);
    }
  }

  Offset get topLeft => position;

  Offset get topRight => Offset(
        position.dx + size.width,
        position.dy,
      );

  Offset get bottomLeft => Offset(
        position.dx,
        position.dy + size.height,
      );

  Offset get bottomRight => Offset(
        position.dx + size.width,
        position.dy + size.height,
      );

  /// Stored-space bounds (relative when parented).
  Rect get rect => Rect.fromLTWH(
        position.dx,
        position.dy,
        size.width,
        size.height,
      );

  Rect get interactionRect {
    final maxHandleSize =
        handles.values.map((h) => h.size).fold<double>(0, (max, size) {
      final larger = math.max(size.width, size.height);
      return math.max(larger, max);
    });
    return Rect.fromCenter(
      center: center,
      width: size.width + maxHandleSize,
      height: size.height + maxHandleSize,
    );
  }

  /// Flow position → coordinates relative to this node's top-left (stored space).
  Offset toNodeSpace(Offset flowPosition) => flowPosition - topLeft;

  /// Node-local position → stored coordinates.
  Offset toFlowSpace(Offset nodePosition) => topLeft + nodePosition;
}
