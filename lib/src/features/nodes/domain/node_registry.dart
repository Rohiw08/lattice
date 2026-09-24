import 'package:lattice/src/features/nodes/presentation/builtin_nodes.dart';
import 'package:lattice/src/core/utils/json_converters.dart';
import 'package:flutter/material.dart';

import 'models/node.dart';
import 'models/node_props.dart';

/// Legacy builder: receives the full [FlowNode] only.
typedef NodeWidgetBuilder = Widget Function(FlowNode node);

/// Builder that receives a [NodeProps] bag (id, data, selected, dragging, …).
typedef NodePropsWidgetBuilder = Widget Function(NodeProps props);

/// Typed builder: [NodeProps.data] is [T] (no cast in your widget).
typedef TypedNodePropsBuilder<T> = Widget Function(NodeProps<T> props);

/// Maps [FlowNode.type] strings to widget builders.
///
/// By default registers React Flow–compatible built-ins:
/// `input`, `default`, `output`, `group`. Like React Flow v12, the built-in widgets
/// render **no label** — your node widget decides what `props.data` looks like.
///
/// ### Custom nodes
///
/// Prefer [registerTyped] so [data] is typed and interaction flags are available:
///
/// ```dart
/// registry.registerTyped<MyData>('color', (props) {
///   return BaseNode(
///     node: props.node,
///     child: Row(children: [
///       Text(props.data.label),
///       IconButton(...), // no FlowNoDrag needed
///     ]),
///     overlay: showPanel ? MyPanel() : null, // side UI, automatic
///   );
/// });
/// ```
///
/// Or keep [register] if you only need [FlowNode]:
///
/// ```dart
/// registry.register('custom', (node) => MyCustomNode(node: node));
/// ```
///
/// **Handles:** put [FlowHandle]s on the model (`node.handles`), then either
/// wrap with [BaseNode] (renders them) or place your own [Handle]
/// widgets. Omitting both means the node cannot start/end connections.
class NodeRegistry {
  final Map<String, NodePropsWidgetBuilder> _builders;

  /// Per-type serializers for [FlowNode.data]. Empty unless a type registers
  /// one via [registerTyped] (`toJson`/`fromJson`) or [register] (`codec`).
  final Map<String, NodeDataCodec> _codecs = {};

  /// Creates a registry with React Flow built-in node types registered.
  NodeRegistry() : _builders = {} {
    _registerDefaultTypes();
  }

  /// Creates an empty registry with no built-in types.
  NodeRegistry.empty() : _builders = {};

  /// Registers React Flow built-in node types (`input`, `default`, `output`, `group`).
  void _registerDefaultTypes() {
    register(BuiltInNodeType.input, (n) => InputNode(node: n));
    register(
      BuiltInNodeType.defaultType,
      (n) => DefaultNode(node: n),
    );
    register(BuiltInNodeType.output, (n) => OutputNode(node: n));
    register(BuiltInNodeType.group, (n) => GroupNode(node: n));
  }

  /// Registers a type whose builder receives only [FlowNode] (unchanged API).
  ///
  /// Pass [codec] to make non-primitive [FlowNode.data] survive
  /// `saveDocument`/`toJson`; omit it when `data` is already JSON-encodable
  /// (primitives, `Map`, `List`). Prefer [registerTyped] for typed data.
  void register(String type, NodeWidgetBuilder builder, {NodeDataCodec? codec}) {
    assert(type.isNotEmpty, 'Node type cannot be empty');
    _builders[type] = (props) => builder(props.node);
    if (codec != null) _codecs[type] = codec;
  }

  /// Registers a type with a typed [NodeProps] builder (recommended).
  ///
  /// [T] should match the [FlowNode.data] type for nodes of this [type].
  /// For untyped payloads, use `registerTyped<Object?>` (or cast inside the
  /// builder) — there is no separate untyped props API.
  ///
  /// Supply [toJson] **and** [fromJson] together to persist typed `data`
  /// (e.g. a sealed class) through `saveDocument`/`loadDocument`; without
  /// them, `data` must be JSON-encodable:
  ///
  /// ```dart
  /// registry.registerTyped<MyData>(
  ///   'color',
  ///   (props) => MyNode(props),
  ///   toJson: (d) => {'label': d.label},
  ///   fromJson: (j) => MyData((j as Map)['label'] as String),
  /// );
  /// ```
  void registerTyped<T>(
    String type,
    TypedNodePropsBuilder<T> builder, {
    Object? Function(T data)? toJson,
    T Function(Object? json)? fromJson,
  }) {
    assert(type.isNotEmpty, 'Node type cannot be empty');
    assert((toJson == null) == (fromJson == null),
        'Provide both toJson and fromJson, or neither.');
    _builders[type] = (props) => builder(props.cast<T>());
    if (toJson != null && fromJson != null) {
      _codecs[type] = NodeDataCodec(
        encode: (data) => data == null ? null : toJson(data as T),
        decode: (json) => json == null ? null : fromJson(json),
      );
    }
  }

  /// Unregisters a node type (and its data codec). Returns true if a builder
  /// was removed.
  bool unregister(String type) {
    _codecs.remove(type);
    return type.isNotEmpty && _builders.remove(type) != null;
  }

  /// Whether [type] is registered.
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Encodes [data] for a node of [type] using its registered [NodeDataCodec],
  /// or returns it unchanged when none is registered.
  Object? encodeData(String type, Object? data) {
    final codec = _codecs[type];
    return codec == null ? data : codec.encode(data);
  }

  /// Rehydrates [json] into `data` for a node of [type] using its registered
  /// [NodeDataCodec], or returns it unchanged when none is registered.
  Object? decodeData(String type, Object? json) {
    final codec = _codecs[type];
    return codec == null ? json : codec.decode(json);
  }

  /// Removes all registered types and their data codecs.
  void clear() {
    _builders.clear();
    _codecs.clear();
  }

  /// Resolves a widget for [props], falling back to the built-in `default` look.
  Widget buildWidget(NodeProps props) =>
      _builders[props.type]?.call(props) ??
      DefaultNode(node: props.node);

  /// Immutable copy of registered builders.
  Map<String, NodePropsWidgetBuilder> get builders =>
      Map.unmodifiable(_builders);
}
