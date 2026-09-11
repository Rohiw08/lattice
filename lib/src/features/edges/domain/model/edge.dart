// ignore_for_file: invalid_annotation_target, deprecated_member_use

import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/theme/components/edge_label_theme.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/edges/domain/edge_animation_effect.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'edge.freezed.dart';
part 'edge.g.dart';

/// Represents a permanent connection (edge) between two nodes in the flow canvas.
///
/// An edge connects a source node to a target node, optionally through specific
/// handles on those nodes. Edges can be customized with labels, markers, and
/// various interaction behaviors.
///
/// ## Usage
///
/// Create a basic edge:
/// ```
/// final edge = FlowEdge(
///   id: 'edge-1',
///   sourceNodeId: 'node-1',
///   targetNodeId: 'node-2',
///   pathType: EdgePathType.bezier,
/// );
/// ```
///
/// Create an edge with handles and styling:
/// ```
/// final edge = FlowEdge(
///   id: 'edge-1',
///   sourceNodeId: 'node-1',
///   targetNodeId: 'node-2',
///   sourceHandleId: 'output-1',
///   targetHandleId: 'input-1',
///   pathType: EdgePathType.bezier,
///   label: Text('Data Flow'),
///   endMarkerStyle: FlowEdgeMarkerStyle.arrow(),
///   style: FlowEdgeStyle.colored(color: Colors.blue),
/// );
/// ```
///
/// Query edge connections:
/// ```
/// if (edge.isConnectedToNode('node-1')) {
///   print('Edge connects to node-1');
/// }
///
/// if (edge.hasHandles) {
///   print('Edge uses specific handles');
/// }
/// ```
///
/// ## Comparison with FlowConnection
///
/// | Property | FlowEdge | FlowConnection |
/// |----------|----------|----------------|
/// | Purpose | Permanent graph relationship | Temporary visual feedback |
/// | Lifetime | Until deleted | Milliseconds (during drag) |
/// | Identification | Node/Handle IDs | Node IDs + screen coordinates |
/// | Persistence | Saved in graph state | Ephemeral UI state |
///
/// See also:
///
///  * [FlowConnection], for temporary connections during edge creation
///  * [FlowNode], for nodes that edges connect
///  * [FlowHandle], for connection points on nodes
@freezed
abstract class FlowEdge with _$FlowEdge {
  const FlowEdge._();

  /// Creates a flow edge.
  ///
  /// The [id] must be unique within the canvas.
  ///
  /// [sourceNodeId] and [targetNodeId] must exist in the graph and cannot be
  /// the same (enforced by assertion).
  ///
  /// Optional [sourceHandleId] and [targetHandleId] specify which handles
  /// to connect. If null, connects to the node center.
  @Assert('sourceNodeId != targetNodeId',
      'Source and target cannot be the same node')
  const factory FlowEdge({
    /// Unique identifier for this edge.
    required String id,

    /// ID of the source node this edge originates from.
    required String sourceNodeId,

    /// ID of the target node this edge points to.
    required String targetNodeId,

    /// Optional handle ID on the source node where the edge connects.
    ///
    /// If null, the edge connects to the node's center or default position.
    String? sourceHandleId,

    /// Optional handle ID on the target node where the edge connects.
    ///
    /// If null, the edge connects to the node's center or default position.
    String? targetHandleId,

    /// Z-index for layering edges.
    ///
    /// Higher values render on top. Useful when [elevateEdgeOnSelect] is true.
    /// Default is 0.
    @Default(0) int zIndex,

    /// The path rendering algorithm for this edge.
    ///
    /// Determines the visual style of the connection line:
    /// - [EdgePathType.bezier] - Smooth curved path (default)
    /// - [EdgePathType.straight] - Direct line
    /// - [EdgePathType.step] - Right-angled path
    /// - [EdgePathType.smoothstep] - Smooth right-angled path
    @Default(EdgePathType.bezier) EdgePathType type,

    /// Width of the invisible interaction area around the edge for easier selection.
    ///
    /// Makes thin edges easier to click/hover. Typical values: 8-15.
    /// Default is 10.0.
    @Default(10.0) double interactionWidth,

    /// Optional widget to display as a label on the edge.
    ///
    /// Typically a Text widget, but can be any widget. Positioned at the
    /// center of the edge path.
    @JsonKey(ignore: true) Widget? label,

    /// Optional decoration for the label container.
    ///
    /// Controls background, border, padding, etc. of the label.
    /// If null, uses default decoration or no decoration.
    @JsonKey(ignore: true) FlowEdgeLabelStyle? labelDecoration,

    /// Optional custom marker style for the start of the edge.
    ///
    /// Common options: arrow, circle, diamond. If null, no start marker.
    @JsonKey(ignore: true) FlowEdgeMarkerStyle? startMarkerStyle,

    /// Optional custom marker style for the end of the edge.
    ///
    /// Common options: arrow, circle, diamond. If null, no end marker.
    @JsonKey(ignore: true) FlowEdgeMarkerStyle? endMarkerStyle,

    /// Optional custom style for this edge.
    ///
    /// Controls stroke width, color, dash pattern, etc.
    /// If null, uses the style from the current theme.
    @JsonKey(ignore: true) FlowEdgeStyle? style,

    /// Custom data that can be attached to this edge.
    ///
    /// Useful for storing application-specific metadata like weights,
    /// capacities, or custom properties.
    @Default(<String, dynamic>{}) Map<String, dynamic> data,

    /// When true, draws a flowing dash along the path (Lattice `animated`).
    ///
    /// Uses a shared ticker that only runs while any edge is animated; static
    /// edges stay on a separate [RepaintBoundary] so they do not repaint every
    /// frame (lattice performance pattern).
    @Default(false) bool animated,

    /// Optional custom effect when [animated] is true.
    ///
    /// Defaults to [FlowingDashEffect] (marching ants).
    @JsonKey(includeFromJson: false, includeToJson: false)
    EdgeAnimationEffect? animationEffect,

    /// Whether this edge should be hidden from view.
    ///
    /// Hidden edges are not rendered but remain in the data structure.
    /// If null, uses the global canvas setting.
    bool? hidden,

    /// Whether this edge can be deleted by the user.
    ///
    /// If null, uses the global canvas setting.
    bool? deletable,

    /// Whether this edge can be selected by the user.
    ///
    /// If null, uses the global canvas setting.
    bool? selectable,

    /// Whether this edge can receive keyboard focus.
    ///
    /// If null, uses the global canvas setting.
    bool? focusable,

    /// Whether this edge's connections can be changed by dragging.
    ///
    /// Allows reconnecting the edge to different nodes/handles.
    /// If null, uses the global canvas setting.
    bool? reconnectable,

    /// Whether this edge should be elevated (z-index increased) when selected.
    ///
    /// If null, uses the global canvas setting.
    bool? elevateEdgeOnSelect,
  }) = _FlowEdge;

  factory FlowEdge.fromJson(Map<String, dynamic> json) =>
      _$FlowEdgeFromJson(json);

  // ==========================================================================
  // Connection Query Methods (Domain Logic)
  // ==========================================================================

  /// Returns true if this edge is connected to the specified node.
  ///
  /// Checks both source and target ends.
  ///
  /// Example:
  /// ```
  /// if (edge.isConnectedToNode('node-1')) {
  ///   // Edge touches node-1
  /// }
  /// ```
  bool isConnectedToNode(String nodeId) =>
      sourceNodeId == nodeId || targetNodeId == nodeId;

  /// Returns true if this edge connects the two specified nodes in either direction.
  ///
  /// Example:
  /// ```
  /// if (edge.connectsNodes('node-1', 'node-2')) {
  ///   // Edge goes between these nodes (either direction)
  /// }
  /// ```
  bool connectsNodes(String nodeId1, String nodeId2) =>
      (sourceNodeId == nodeId1 && targetNodeId == nodeId2) ||
      (sourceNodeId == nodeId2 && targetNodeId == nodeId1);

  /// Returns true if this edge is connected to the specified handle.
  ///
  /// Checks both source and target handle IDs.
  ///
  /// Example:
  /// ```
  /// if (edge.isConnectedToHandle('output-1')) {
  ///   // Edge is attached to this handle
  /// }
  /// ```
  bool isConnectedToHandle(String handleId) =>
      sourceHandleId == handleId || targetHandleId == handleId;

  /// Returns true if this edge is connected to the specified handle on the specified node.
  ///
  /// More specific than [isConnectedToHandle] - requires both node and handle to match.
  ///
  /// Example:
  /// ```
  /// if (edge.isConnectedToNodeHandle('node-1', 'output-1')) {
  ///   // Edge is attached to output-1 on node-1
  /// }
  /// ```
  bool isConnectedToNodeHandle(String nodeId, String handleId) =>
      (sourceNodeId == nodeId && sourceHandleId == handleId) ||
      (targetNodeId == nodeId && targetHandleId == handleId);

  /// Returns the ID of the node at the opposite end from [nodeId].
  ///
  /// Returns null if [nodeId] is not connected to this edge.
  ///
  /// Example:
  /// ```
  /// final oppositeId = edge.getOppositeNodeId('node-1');
  /// if (oppositeId != null) {
  ///   print('Other end connects to $oppositeId');
  /// }
  /// ```
  String? getOppositeNodeId(String nodeId) {
    if (sourceNodeId == nodeId) return targetNodeId;
    if (targetNodeId == nodeId) return sourceNodeId;
    return null;
  }

  /// Returns the handle ID at the opposite end from the specified node and handle.
  ///
  /// Returns null if the specified node/handle combo doesn't match either end,
  /// or if the opposite end doesn't use a specific handle.
  ///
  /// Example:
  /// ```
  /// final oppositeHandle = edge.getOppositeHandle('node-1', 'output-1');
  /// // Returns the target handle ID if source matches
  /// ```
  String? getOppositeHandle(String nodeId, String? handleId) {
    if (sourceNodeId == nodeId && sourceHandleId == handleId) {
      return targetHandleId;
    }
    if (targetNodeId == nodeId && targetHandleId == handleId) {
      return sourceHandleId;
    }
    return null;
  }

  // ==========================================================================
  // Edge State Properties
  // ==========================================================================

  /// Returns true if this edge is a self-loop (both ends connect to the same node).
  ///
  /// Note: This should not occur due to the assertion in the constructor,
  /// but is provided for validation in edge creation workflows.
  bool get isSelfLoop => sourceNodeId == targetNodeId;

  /// Returns true if this edge uses specific handles (not node centers).
  ///
  /// Example:
  /// ```
  /// if (edge.hasHandles) {
  ///   // Edge connects to specific handle points
  /// } else {
  ///   // Edge connects to node centers
  /// }
  /// ```
  bool get hasHandles => sourceHandleId != null || targetHandleId != null;

  /// Returns true if both source and target use specific handles.
  bool get hasBothHandles => sourceHandleId != null && targetHandleId != null;

  /// Returns true if this edge has a visual label.
  bool get hasLabel => label != null;

  /// Returns true if this edge has any markers (start or end).
  bool get hasMarkers => startMarkerStyle != null || endMarkerStyle != null;

  /// Returns true if this edge has custom data attached.
  bool get hasData => data.isNotEmpty;

  // ==========================================================================
  // Data Access Helpers
  // ==========================================================================

  /// Gets a data value by key, with type safety.
  ///
  /// Returns null if the key doesn't exist or the type doesn't match.
  ///
  /// Example:
  /// ```
  /// final weight = edge.getData<double>('weight');
  /// final label = edge.getData<String>('label');
  /// ```
  T? getData<T>(String key) {
    final value = data[key];
    return value is T ? value : null;
  }

  /// Gets a data value by key, with a fallback default.
  ///
  /// Example:
  /// ```
  /// final weight = edge.getDataOrDefault('weight', 1.0);
  /// ```
  T getDataOrDefault<T>(String key, T defaultValue) {
    final value = getData<T>(key);
    return value ?? defaultValue;
  }
}
