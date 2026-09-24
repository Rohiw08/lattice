import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/theme_export.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:lattice/src/core/enums/enums.dart';

part 'connection.freezed.dart';

/// Represents a temporary connection being created by the user.
///
/// A connection is an ephemeral object that exists only during the edge
/// creation process. It tracks the visual state of a line being drawn from
/// a source handle to the current pointer position before the edge is finalized.
///
/// ## Lifecycle
///
/// 1. **Started**: User begins dragging from a source handle
///    ```
///    FlowConnection(
///      id: 'temp-connection',
///      type: 'default',
///      startPoint: sourceHandlePosition,
///      endPoint: pointerPosition,
///      fromNodeId: 'node-1',
///      fromHandleId: 'output-1',
///    )
///    ```
///
/// 2. **Active**: User drags to find a target (endPoint updates with pointer)
///    ```
///    connection.copyWith(
///      endPoint: newPointerPosition,
///    )
///    ```
///
/// 3. **Completed**: User releases on a valid target handle
///    ```
///    // Connection is converted to FlowEdge
///    FlowEdge(
///      id: generateEdgeId(),
///      sourceNodeId: connection.fromNodeId!,
///      targetNodeId: targetNodeId,
///      sourceHandleId: connection.fromHandleId,
///      targetHandleId: targetHandleId,
///    )
///    ```
///
/// 4. **Cancelled**: User releases on invalid target or presses Escape
///    ```
///    // Connection is discarded
///    ```
///
/// ## Comparison with FlowEdge
///
/// | Property | FlowConnection | FlowEdge |
/// |----------|---------------|----------|
/// | Purpose | Temporary visual feedback | Permanent graph relationship |
/// | Lifetime | Milliseconds (during drag) | Until deleted |
/// | Start/End | Screen coordinates (Offset) | Node/Handle IDs |
/// | Validation | Real-time during drag | Validated on creation |
///
/// ## Example
///
/// ```
/// // During connection creation
/// if (isDraggingConnection) {
///   final connectionPainter = ConnectionPainter(
///     connection: currentConnection,
///     connectionState: currentConnectionState,
///     style: theme.connectionStyle,
///   );
///   CustomPaint(painter: connectionPainter);
/// }
/// ```
///
/// See also:
///
///  * [FlowEdge], for permanent connections between nodes
///  * [FlowHandle], for connection points on nodes
@freezed
abstract class FlowConnection with _$FlowConnection {
  const FlowConnection._();

  /// Creates a flow connection.
  ///
  /// The [id] should be unique during the connection's lifetime (typically
  /// a temporary ID like 'temp-connection' since it's ephemeral).
  ///
  /// The [type] determines the visual style (e.g., 'default', 'bezier', 'step').
  ///
  /// [startPoint] and [endPoint] are screen coordinates where the connection
  /// line should be drawn.
  ///
  /// Optional node/handle IDs are set when dragging from a known source,
  /// and updated when hovering over valid targets.
  const factory FlowConnection({
    /// Unique identifier for this connection (typically temporary).
    required String id,

    /// The edge type identifier for styling (e.g., 'default', 'bezier', 'step').
    ///
    /// This is used to determine the path rendering algorithm when the
    /// connection is converted to an edge.
    required String type,

    /// Screen position where the connection starts (source handle position).
    ///
    /// This is typically the center of the source handle and remains
    /// fixed during the drag operation.
    required Offset startPoint,

    /// Screen position where the connection ends (current pointer position).
    ///
    /// This updates continuously as the user drags, following the pointer
    /// or snapping to target handles when hovering over valid targets.
    required Offset endPoint,

    /// ID of the source node, if dragging from a node handle.
    ///
    /// Null when creating a reverse connection (dragging from empty space).
    String? fromNodeId,

    /// ID of the source handle on the source node.
    ///
    /// Null when connecting from the node center or when creating a
    /// reverse connection.
    String? fromHandleId,

    /// ID of the target node, set when hovering over a valid target.
    ///
    /// Updated in real-time as the user drags over connectable nodes.
    /// Null while dragging in empty space.
    String? toNodeId,

    /// ID of the target handle, set when hovering over a valid target handle.
    ///
    /// Updated in real-time as the user drags over connectable handles.
    /// Null when connecting to the node center or while dragging in empty space.
    String? toHandleId,

    /// Handle position of the source (for rendering bezier curves).
    @Default(HandlePosition.right) HandlePosition sourcePosition,

    /// Handle position of the target (for rendering bezier curves).
    @Default(HandlePosition.left) HandlePosition targetPosition,

    /// Z-index for rendering order (higher values render on top).
    ///
    /// Connections are typically rendered above edges but below nodes.
    /// Default is 0.
    @Default(0) int zIndex,

    /// Custom styling for this connection.
    ///
    /// If null, uses the default connection style from the theme.
    /// The style includes stroke width, color, dash pattern, etc.
    FlowConnectionStyle? connectionStyle,

    /// Marker (arrow, dot, etc.) to render at the start of the connection.
    ///
    /// Typically null for connections since they usually only have end markers.
    FlowEdgeMarkerStyle? startMarker,

    /// Marker (arrow, dot, etc.) to render at the end of the connection.
    ///
    /// Usually an arrow to indicate direction. If null, no marker is rendered.
    FlowEdgeMarkerStyle? endMarker,
  }) = _FlowConnection;

  // ==========================================================================
  // Connection State Helpers
  // ==========================================================================

  /// Returns true if this connection has a valid source (from node/handle).
  ///
  /// Example:
  /// ```
  /// if (connection.hasSource) {
  ///   // Can attempt to create the edge
  /// }
  /// ```
  bool get hasSource => fromNodeId != null;

  /// Returns true if this connection has a valid target (to node/handle).
  ///
  /// This is updated in real-time as the user drags over valid targets.
  ///
  /// Example:
  /// ```
  /// if (connection.hasTarget) {
  ///   // Highlight the target as valid
  ///   // Show "release to connect" feedback
  /// }
  /// ```
  bool get hasTarget => toNodeId != null;

  /// Returns true if this connection is complete (has both source and target).
  ///
  /// A complete connection can be converted to a [FlowEdge].
  ///
  /// Example:
  /// ```
  /// void onPointerUp() {
  ///   if (connection.isComplete) {
  ///     final edge = _createEdgeFromConnection(connection);
  ///     addEdge(edge);
  ///   }
  ///   clearConnection();
  /// }
  /// ```
  bool get isComplete => hasSource && hasTarget;

  /// Returns true if this connection is being dragged from a specific handle.
  ///
  /// When false, the connection originates from the node center or is a
  /// reverse connection (dragging from empty space).
  bool get hasSourceHandle => fromHandleId != null;

  /// Returns true if this connection is targeting a specific handle.
  ///
  /// When false, the connection will attach to the node center if completed.
  bool get hasTargetHandle => toHandleId != null;

  /// Returns true if this connection forms a self-loop (same source and target node).
  ///
  /// Self-loops are typically invalid and should be prevented in most use cases.
  ///
  /// Example:
  /// ```
  /// if (connection.isSelfLoop) {
  ///   // Show error feedback
  ///   // Prevent edge creation
  /// }
  /// ```
  bool get isSelfLoop => hasSource && hasTarget && fromNodeId == toNodeId;

  /// Returns the approximate length of the connection line in pixels.
  ///
  /// Useful for animations or visual feedback based on connection distance.
  ///
  /// Example:
  /// ```
  /// final dashInterval = connection.length / 20; // Scale dashes with length
  /// ```
  double get length => (endPoint - startPoint).distance;

  /// Returns the direction vector from start to end (normalized).
  ///
  /// Useful for calculating marker rotations or handle positions.
  ///
  /// Example:
  /// ```
  /// final direction = connection.direction;
  /// final arrowAngle = atan2(direction.dy, direction.dx);
  /// ```
  Offset get direction {
    final delta = endPoint - startPoint;
    final distance = delta.distance;
    return distance > 0 ? delta / distance : Offset.zero;
  }
}
