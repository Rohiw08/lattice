import 'package:lattice/src/features/nodes/presentation/builtin_nodes.dart';
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
/// By default registers Lattice–compatible built-ins:
/// `input`, `default`, `output`, `group`. Like Lattice v12, the built-in widgets
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

  /// Creates a registry with Lattice built-in node types registered.
  NodeRegistry() : _builders = {} {
    _registerDefaultTypes();
  }

  /// Creates an empty registry with no built-in types.
  NodeRegistry.empty() : _builders = {};

  /// Registers Lattice built-in node types (`input`, `default`, `output`, `group`).
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
  void register(String type, NodeWidgetBuilder builder) {
    assert(type.isNotEmpty, 'Node type cannot be empty');
    _builders[type] = (props) => builder(props.node);
  }

  /// Registers a type with a typed [NodeProps] builder (recommended).
  ///
  /// [T] should match the [FlowNode.data] type for nodes of this [type].
  /// For untyped payloads, use `registerTyped<Object?>` (or cast inside the
  /// builder) — there is no separate untyped props API.
  void registerTyped<T>(String type, TypedNodePropsBuilder<T> builder) {
    assert(type.isNotEmpty, 'Node type cannot be empty');
    _builders[type] = (props) => builder(props.cast<T>());
  }

  /// Unregisters a node type. Returns true if a type was removed.
  bool unregister(String type) =>
      type.isNotEmpty && _builders.remove(type) != null;

  /// Whether [type] is registered.
  bool isRegistered(String type) => _builders.containsKey(type);

  /// Removes all registered types.
  void clear() => _builders.clear();

  /// Resolves a widget for [props], falling back to the built-in `default` look.
  Widget buildWidget(NodeProps props) =>
      _builders[props.type]?.call(props) ??
      DefaultNode(node: props.node);

  /// Immutable copy of registered builders.
  Map<String, NodePropsWidgetBuilder> get builders =>
      Map.unmodifiable(_builders);
}
