import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/core/options/options_extensions.dart';

/// Defines the behavior and interaction options for nodes in the flow canvas.
///
/// Node options control how nodes behave and respond to user interactions,
/// including dragging, selection, deletion, and connection capabilities.
///
/// ```
/// {
///   type?: string;
///   hidden?: boolean;
///   draggable?: boolean;
///   selectable?: boolean;
///   connectable?: boolean;
///   deletable?: boolean;
///   focusable?: boolean;
///   zIndex?: number; // Similar to elevateNodesOnSelected
/// }
/// ```
///
/// ## Usage
///
/// Create custom node options:
/// ```
/// const options = NodeOptions(
///   draggable: true,
///   selectable: true,
///   connectable: true,
/// );
/// ```
///
/// See also:
///
///  * [EdgeOptions], for edge behavior configuration
///  * [FlowCanvasOptions], for global canvas options
///  * [FlowNode], which uses these options
@immutable
class NodeOptions with Diagnosticable {
  /// Creates node options with the specified behaviors.
  ///
  /// All boolean parameters default to common interactive settings:
  /// - Most interactions enabled (draggable, selectable, connectable, deletable, focusable)
  /// - Visual effects: [elevateNodesOnSelected] defaults on (Lattice).
  const NodeOptions({
    this.hidden = false,
    this.draggable = true,
    this.hoverable = true,
    this.selectable = true,
    this.connectable = true,
    this.deletable = true,
    this.resizable = true,
    this.focusable = true,
    this.elevateNodesOnSelected = true,
    this.expandParent = false,
  });

  /// View/present mode: no drag, resize, connect, or delete; selection allowed.
  const NodeOptions.readOnly()
      : hidden = false,
        draggable = false,
        hoverable = true,
        selectable = true,
        connectable = false,
        deletable = false,
        resizable = false,
        focusable = true,
        elevateNodesOnSelected = false,
        expandParent = false;

  /// Same behavior as the default constructor — useful for presets and docs.
  const NodeOptions.interactive() : this();

  /// Whether the node is hidden from view.
  ///
  /// Hidden nodes still exist in the graph but are not rendered.
  /// Useful for temporarily hiding nodes without removing them.
  ///
  /// Lattice equivalent: `hidden`.
  /// Defaults to false.
  final bool hidden;

  /// Whether the node can be dragged by the user.
  ///
  /// When false, the node is fixed in place and cannot be moved
  /// by dragging, though it can still be moved programmatically.
  ///
  /// Lattice equivalent: `draggable`.
  /// Defaults to true.
  final bool draggable;

  /// Whether the node can be selected by clicking or dragging.
  ///
  /// When false, the node cannot be interacted with for selection.
  /// Useful for background or decorative nodes.
  ///
  /// Lattice equivalent: `selectable`.
  /// Defaults to true.
  final bool selectable;

  /// Whether the node can be hovered.
  ///
  /// When false, the node cannot be interacted with for hover.
  /// Useful for background or decorative nodes.
  ///
  /// Defaults to true.
  final bool hoverable;

  /// Whether edges can be connected to/from this node.
  ///
  /// When false, users cannot create new connections to or from this node.
  /// Existing connections remain, but no new ones can be made.
  ///
  /// Lattice equivalent: `connectable`.
  /// Defaults to true.
  final bool connectable;

  /// Whether the node can be deleted by the user.
  ///
  /// When false, prevents deletion via keyboard shortcuts or UI actions.
  /// The node can still be removed programmatically.
  ///
  /// Lattice equivalent: `deletable`.
  /// Defaults to true.
  final bool deletable;

  /// Whether the node can be resized by the user.
  ///
  /// When false, the node resize handles are not shown.
  ///
  /// Defaults to true.
  final bool resizable;

  /// Whether the node can receive keyboard focus.
  ///
  /// When true, the node can be focused and respond to keyboard events
  /// like Delete or arrow keys for navigation.
  ///
  /// Lattice equivalent: `focusable`.
  /// Defaults to true (Lattice defaults to false).
  final bool focusable;

  /// Whether to elevate the node visually when selected.
  ///
  /// When true, selected nodes are rendered on top of other nodes,
  /// making them more prominent. This typically increases their z-index.
  ///
  /// Lattice equivalent: `elevateNodesOnSelect`.
  /// Defaults to true.
  final bool elevateNodesOnSelected;

  /// Whether this node triggers an automatic expansion of its parent group.
  final bool expandParent;

  /// Returns a copy of this options object with specified fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  ///
  /// Example:
  /// ```
  /// final newOptions = options.copyWith(
  ///   draggable: false,
  ///   deletable: false,
  /// );
  /// ```
  NodeOptions copyWith({
    bool? hidden,
    bool? draggable,
    bool? selectable,
    bool? hoverable,
    bool? connectable,
    bool? deletable,
    bool? resizable,
    bool? focusable,
    bool? elevateNodesOnSelected,
    bool? expandParent,
  }) {
    return NodeOptions(
      hidden: hidden ?? this.hidden,
      draggable: draggable ?? this.draggable,
      hoverable: hoverable ?? this.hoverable,
      selectable: selectable ?? this.selectable,
      connectable: connectable ?? this.connectable,
      deletable: deletable ?? this.deletable,
      resizable: resizable ?? this.resizable,
      focusable: focusable ?? this.focusable,
      elevateNodesOnSelected:
          elevateNodesOnSelected ?? this.elevateNodesOnSelected,
      expandParent: expandParent ?? this.expandParent,
    );
  }

  /// Retrieves the canvas-level [NodeOptions] from the nearest
  /// [FlowCanvasOptionsProvider] ancestor.
  ///
  /// Throws a [FlutterError] if no provider is found.
  static NodeOptions of(BuildContext context) {
    // Accesses the extension you already wrote
    return context.flowCanvasOptions.nodeOptions;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is NodeOptions &&
        other.hidden == hidden &&
        other.draggable == draggable &&
        other.hoverable == hoverable &&
        other.selectable == selectable &&
        other.connectable == connectable &&
        other.deletable == deletable &&
        other.resizable == resizable &&
        other.focusable == focusable &&
        other.elevateNodesOnSelected == elevateNodesOnSelected &&
        other.expandParent == expandParent;
  }

  @override
  int get hashCode => Object.hash(
        hidden,
        draggable,
        selectable,
        hoverable,
        connectable,
        deletable,
        resizable,
        focusable,
        elevateNodesOnSelected,
        expandParent,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('hidden',
        value: hidden, defaultValue: false, ifTrue: 'HIDDEN'));
    properties.add(FlagProperty('draggable',
        value: draggable, defaultValue: true, ifFalse: 'not draggable'));
    properties.add(FlagProperty('selectable',
        value: selectable, defaultValue: true, ifFalse: 'not selectable'));
    properties.add(FlagProperty('hoverable',
        value: selectable, defaultValue: true, ifFalse: 'not hoverable'));
    properties.add(FlagProperty('connectable',
        value: connectable, defaultValue: true, ifFalse: 'not connectable'));
    properties.add(FlagProperty('deletable',
        value: deletable, defaultValue: true, ifFalse: 'not deletable'));
    properties.add(FlagProperty('focusable',
        value: focusable, defaultValue: true, ifFalse: 'not focusable'));
    properties.add(FlagProperty('elevateNodesOnSelected',
        value: elevateNodesOnSelected,
        defaultValue: false,
        ifTrue: 'elevates on select'));
  }
}
