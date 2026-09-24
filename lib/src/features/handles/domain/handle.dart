// ignore_for_file: invalid_annotation_target
import 'package:flutter/foundation.dart';import 'package:flutter/material.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/utils/json_converters.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'handle.freezed.dart';
part 'handle.g.dart';

/// Represents a connection point (handle) on a flow node.
///
/// Handles define specific points where edges can connect to nodes. Each handle
/// has a type (source or target) that determines the direction of connections,
/// a position relative to the node, and interaction properties.
///
/// ## Handle Types
///
/// - **Source**: Outputs data/connections (typically on right side)
/// - **Target**: Receives data/connections (typically on left side)
///
/// ## Usage
///
/// Create a basic handle:
/// ```
/// final handle = FlowHandle(
///   id: 'output-1',
///   type: HandleType.source,
///   position: Offset(100, 50), // Relative to node
/// );
/// ```
///
/// Create a handle with custom styling:
/// ```
/// final handle = FlowHandle(
///   id: 'input-1',
///   type: HandleType.target,
///   position: Offset(0, 50),
///   isConnectable: true,
///   size: Size(12, 12),
///   maxConnections: 1, // Only allow one connection
/// );
/// ```
///
/// Check if point is over handle:
/// ```
/// if (handle.containsPoint(pointerPosition)) {
///   // User is hovering over handle
/// }
/// ```
///
/// Validate connection:
/// ```
/// if (sourceHandle.canConnectTo(targetHandle)) {
///   // Connection is allowed
/// }
/// ```
///
/// See also:
///
///  * [FlowNode], which contains handles
///  * [FlowEdge], which connects between handles
///  * [HandleType], for handle type definitions
@freezed
abstract class FlowHandle with _$FlowHandle {
  const FlowHandle._();

  /// Creates a flow handle.
  ///
  /// The [id] must be unique within the parent node.
  ///
  /// The [position] is relative to the node's top-left corner.
  ///
  /// The [size] determines the interaction area (typically 8-16 pixels).
  const factory FlowHandle({
    /// Unique identifier for this handle within its parent node.
    ///
    /// Common patterns:
    /// - 'input', 'output' for single handles
    /// - 'input-1', 'input-2' for multiple handles
    /// - 'port-a', 'port-b' for named ports
    required String id,

    /// The type of handle (source or target).
    ///
    /// - [HandleType.source]: Output handle (edges originate here)
    /// - [HandleType.target]: Input handle (edges terminate here)
    required HandleType type,

    /// Position of the handle's center relative to the node's top-left corner.
    ///
    /// Example positions:
    /// - Left side: Offset(0, nodeHeight / 2)
    /// - Right side: Offset(nodeWidth, nodeHeight / 2)
    /// - Top: Offset(nodeWidth / 2, 0)
    @OffsetConverter() required Offset position,

    /// Whether this handle can accept new connections.
    ///
    /// When false, users cannot create or connect edges to this handle.
    /// Existing connections remain intact.
    ///
    /// Use cases for false:
    /// - Maximum connections reached
    /// - Handle is disabled/inactive
    /// - Connection validation fails
    ///
    /// Default is true.
    @Default(true) bool isConnectable,

    /// Whether a connection drag may START here (React Flow `isConnectableStart`).
    ///
    /// Null (default) derives from [type]: sources (and `both`) start in
    /// strict mode, anything starts in loose mode. Set explicitly to allow a
    /// target handle to start connections, or to forbid a source from doing
    /// so. Serialized.
    bool? isConnectableStart,

    /// Whether a connection drag may LAND here (React Flow `isConnectableEnd`).
    ///
    /// Null (default) derives from [type]: targets (and `both`) land in
    /// strict mode, anything lands in loose mode. Set explicitly to turn a
    /// handle into a start-only or end-only port. Serialized.
    bool? isConnectableEnd,

    /// Per-handle connection validator (React Flow per-`Handle`
    /// `isValidConnection`).
    ///
    /// Runs inside the connection service alongside the canvas-wide
    /// validator; return false to reject. Not serialized.
    @JsonKey(includeFromJson: false, includeToJson: false)
    bool Function(ConnectionParams connection)? isValidConnection,

    /// Fired when an edge involving this handle is created (React Flow per-
    /// `Handle` `onConnect`). Not serialized.
    @JsonKey(includeFromJson: false, includeToJson: false)
    void Function(ConnectionParams connection)? onConnect,

    /// The size of the handle's interaction area.
    ///
    /// Defines the clickable/hoverable region. The actual visual representation
    /// may be smaller. Typical values: 8-16 pixels.
    ///
    /// Default is Size(10, 10).
    @Default(Size(10, 10)) @SizeConverter() Size size,

    /// Optional maximum number of connections allowed to this handle.
    ///
    /// When reached, [isConnectable] should be set to false.
    ///
    /// Examples:
    /// - null: Unlimited connections (default)
    /// - 1: Single connection only
    /// - 5: Up to 5 connections
    int? maxConnections,

    /// Optional validation group/category for this handle.
    ///
    /// Handles can only connect if their groups are compatible.
    /// Use this for type-safe connections (e.g., 'number', 'string', 'any').
    ///
    /// Examples:
    /// - null: Can connect to any handle (default)
    /// - 'data': Only connects to other 'data' handles
    /// - 'flow': Only connects to other 'flow' handles
    String? connectionGroup,

    /// Optional custom data attached to this handle.
    ///
    /// Store application-specific metadata like port names, data types, etc.
    @Default(<String, dynamic>{}) Map<String, dynamic> data,
  }) = _FlowHandle;

  factory FlowHandle.fromJson(Map<String, dynamic> json) =>
      _$FlowHandleFromJson(json);

  // ==========================================================================
  // Position & Bounds Calculations
  // ==========================================================================

  /// Connection / hit center of the handle in node-local space.
  ///
  /// [position] is stored as this center (Lattice style), not top-left.
  Offset get center => position;

  /// Returns the top-left corner of the handle's bounding box.
  Offset get topLeft => Offset(
        position.dx - size.width / 2,
        position.dy - size.height / 2,
      );

  /// Returns the bottom-right corner of the handle's bounding box.
  Offset get bottomRight => Offset(
        position.dx + size.width / 2,
        position.dy + size.height / 2,
      );

  /// Returns the rectangular bounds of the handle.
  ///
  /// Useful for hit testing and rendering.
  ///
  /// Example:
  /// ```
  /// final bounds = handle.bounds;
  /// canvas.drawRect(bounds, paint);
  /// ```
  Rect get bounds => Rect.fromCenter(
        center: position,
        width: size.width,
        height: size.height,
      );

  /// Returns an expanded bounds for easier interaction.
  ///
  /// Adds [expansion] pixels to all sides, making the handle easier to click.
  ///
  /// Example:
  /// ```
  /// final interactionBounds = handle.expandedBounds(4.0);
  /// if (interactionBounds.contains(pointerPosition)) {
  ///   // User is near the handle
  /// }
  /// ```
  Rect expandedBounds(double expansion) => Rect.fromCenter(
        center: position,
        width: size.width + expansion * 2,
        height: size.height + expansion * 2,
      );

  // ==========================================================================
  // Hit Testing
  // ==========================================================================

  /// Returns true if the given point is within the handle's bounds.
  ///
  /// Uses the standard [bounds] for testing.
  ///
  /// Example:
  /// ```
  /// void onPointerMove(PointerMoveEvent event) {
  ///   if (handle.containsPoint(event.localPosition)) {
  ///     setState(() => hoveredHandle = handle);
  ///   }
  /// }
  /// ```
  bool containsPoint(Offset point) => bounds.contains(point);

  /// Returns true if the given point is within an expanded interaction area.
  ///
  /// Makes handles easier to target by expanding the hit test region.
  ///
  /// Example:
  /// ```
  /// // 4px expansion makes the handle easier to click
  /// if (handle.containsPointExpanded(pointerPosition, 4.0)) {
  ///   // User is near the handle
  /// }
  /// ```
  bool containsPointExpanded(Offset point, double expansion) =>
      expandedBounds(expansion).contains(point);

  /// Returns the distance from the given point to the handle's center.
  ///
  /// Useful for finding the closest handle or implementing magnetic snapping.
  ///
  /// Example:
  /// ```
  /// final closestHandle = handles.reduce(
  ///   (a, b) => a.distanceToPoint(pointer) < b.distanceToPoint(pointer) ? a : b
  /// );
  /// ```
  double distanceToPoint(Offset point) => (point - center).distance;

  // ==========================================================================
  // Connection Validation
  // ==========================================================================

  /// Returns true if this handle is a source (output) handle.
  bool get isSource => type == HandleType.source;

  /// Returns true if this handle is a target (input) handle.
  bool get isTarget => type == HandleType.target;

  /// Whether a connection drag may start here under [mode].
  ///
  /// Honors [isConnectable] first, then the explicit [isConnectableStart]
  /// override, then the type default (sources and `both` start in strict
  /// mode; anything starts in loose mode).
  bool allowsStart(ConnectionMode mode) {
    if (!isConnectable) return false;
    if (isConnectableStart != null) return isConnectableStart!;
    return mode == ConnectionMode.loose ||
        type == HandleType.source ||
        type == HandleType.both;
  }

  /// Whether a connection drag may land here under [mode].
  ///
  /// Honors [isConnectable] first, then the explicit [isConnectableEnd]
  /// override, then the type default (targets and `both` land in strict
  /// mode; anything lands in loose mode).
  bool allowsEnd(ConnectionMode mode) {
    if (!isConnectable) return false;
    if (isConnectableEnd != null) return isConnectableEnd!;
    return mode == ConnectionMode.loose ||
        type == HandleType.target ||
        type == HandleType.both;
  }

  /// Whether [edges] still have room on this handle of [nodeId].
  ///
  /// Counts edges attached to either end; null [maxConnections] means
  /// unbounded. Pure (counts from state, no runtime sync needed).
  bool hasCapacity(Iterable<FlowEdge> edges, String nodeId) {
    final max = maxConnections;
    if (max == null) return true;
    var count = 0;
    for (final edge in edges) {
      if ((edge.sourceNodeId == nodeId && edge.sourceHandleId == id) ||
          (edge.targetNodeId == nodeId && edge.targetHandleId == id)) {
        if (++count >= max) return false;
      }
    }
    return true;
  }

  /// Returns true if this handle can potentially connect to another handle.
  ///
  /// Checks:
  /// - Both handles are connectable
  /// - Handles are different types (source ↔ target)
  /// - Connection groups are compatible (if defined)
  ///
  /// Example:
  /// ```
  /// if (sourceHandle.canConnectTo(targetHandle)) {
  ///   final edge = createEdge(sourceHandle, targetHandle);
  /// }
  /// ```
  bool canConnectTo(FlowHandle other) {
    // Both must be connectable
    if (!isConnectable || !other.isConnectable) {
      return false;
    }

    // Must be opposite types
    if (type == other.type) {
      return false;
    }

    // Check connection group compatibility
    if (connectionGroup != null && other.connectionGroup != null) {
      // If both have groups, they must match
      if (connectionGroup != other.connectionGroup) {
        return false;
      }
    }

    return true;
  }

  /// Returns true if this handle is compatible with the specified connection group.
  ///
  /// Used for validating potential connections during drag operations.
  ///
  /// Example:
  /// ```
  /// // While dragging from a 'data' source
  /// final validTargets = targetHandles.where(
  ///   (h) => h.isCompatibleWithGroup('data')
  /// );
  /// ```
  bool isCompatibleWithGroup(String? group) {
    if (connectionGroup == null || group == null) {
      return true; // Null groups are compatible with everything
    }
    return connectionGroup == group;
  }

  // ==========================================================================
  // Data Access Helpers
  // ==========================================================================

  /// Returns true if this handle has custom data attached.
  bool get hasData => data.isNotEmpty;

  /// Gets a data value by key, with type safety.
  ///
  /// Returns null if the key doesn't exist or the type doesn't match.
  ///
  /// Example:
  /// ```
  /// final portName = handle.getData<String>('portName');
  /// final dataType = handle.getData<String>('dataType');
  /// ```
  T? getData<T>(String key) {
    final value = data[key];
    return value is T ? value : null;
  }

  /// Gets a data value by key, with a fallback default.
  ///
  /// Example:
  /// ```
  /// final label = handle.getDataOrDefault('label', 'Unnamed Port');
  /// ```
  T getDataOrDefault<T>(String key, T defaultValue) {
    final value = getData<T>(key);
    return value ?? defaultValue;
  }

  // ==========================================================================
  // Visual State Helpers
  // ==========================================================================

  /// Returns true if this handle should be highlighted as a valid connection target.
  ///
  /// Used during connection creation to show which handles can accept the connection.
  ///
  /// Example:
  /// ```
  /// bool shouldHighlight(FlowHandle handle, FlowConnection? activeConnection) {
  ///   if (activeConnection == null) return false;
  ///   return handle.canAcceptConnection(
  ///     activeConnection.type,
  ///     activeConnection.fromHandleId,
  ///   );
  /// }
  /// ```
  bool canAcceptConnection(HandleType sourceType, String? connectionGroup) {
    if (!isConnectable) return false;
    if (type == sourceType) return false; // Must be opposite type
    return isCompatibleWithGroup(connectionGroup);
  }
}
