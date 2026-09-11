import 'dart:ui';
import 'package:flutter/foundation.dart';

/// Defines a rectangular boundary for constraining positions in 2D space.
///
/// Used primarily for two purposes in Lattice:
/// 1. **Viewport constraints** (`translateExtent`): Limits how far users can pan
/// 2. **Node constraints** (`nodeExtent`): Limits where nodes can be dragged
///
/// ## Lattice Compatibility
///
/// Matches Lattice's `CoordinateExtent` type [web:357]:
/// ```
/// type CoordinateExtent = [[number, number], [number, number]];
/// // [[minX, minY], [maxX, maxY]]
/// ```
///
/// ## Usage
///
/// Unconstrained (infinite canvas):
/// ```
/// const extent = CoordinateExtent(); // Default: infinite
/// ```
///
/// Constrain viewport to specific area:
/// ```
/// final extent = CoordinateExtent(
///   minX: -1000,
///   minY: -1000,
///   maxX: 1000,
///   maxY: 1000,
/// ); // 2000×2000 canvas
/// ```
///
/// Constrain nodes to visible area:
/// ```
/// final extent = CoordinateExtent.fromRect(
///   Rect.fromLTWH(0, 0, 1920, 1080)
/// );
/// ```
///
/// Common patterns:
/// ```
/// // Prevent panning left/right (lock horizontal)
/// CoordinateExtent(
///   minX: 0, maxX: 0,
///   minY: double.negativeInfinity,
///   maxY: double.infinity,
/// )
///
/// // Prevent panning up/down (lock vertical)
/// CoordinateExtent(
///   minX: double.negativeInfinity,
///   maxX: double.infinity,
///   minY: 0, maxY: 0,
/// )
/// ```
///
/// See also:
///
///  * [ViewportOptions.translateExtent], for viewport constraints
///  * [ViewportOptions.nodeExtent], for node dragging constraints
@immutable
class CoordinateExtent with Diagnosticable {
  /// Minimum X coordinate (left boundary).
  ///
  /// Use [double.negativeInfinity] for no left boundary.
  final double minX;

  /// Minimum Y coordinate (top boundary).
  ///
  /// Use [double.negativeInfinity] for no top boundary.
  final double minY;

  /// Maximum X coordinate (right boundary).
  ///
  /// Use [double.infinity] for no right boundary.
  final double maxX;

  /// Maximum Y coordinate (bottom boundary).
  ///
  /// Use [double.infinity] for no bottom boundary.
  final double maxY;

  /// Creates a coordinate extent with the specified boundaries.
  ///
  /// Defaults to unconstrained (infinite) boundaries.
  const CoordinateExtent({
    this.minX = double.negativeInfinity,
    this.minY = double.negativeInfinity,
    this.maxX = double.infinity,
    this.maxY = double.infinity,
  })  : assert(maxX >= minX, 'maxX must be >= minX'),
        assert(maxY >= minY, 'maxY must be >= minY');

  /// Creates an unconstrained extent (infinite canvas).
  ///
  /// Equivalent to the default constructor.
  const CoordinateExtent.infinite()
      : minX = double.negativeInfinity,
        minY = double.negativeInfinity,
        maxX = double.infinity,
        maxY = double.infinity;

  /// Creates an extent from a [Rect].
  ///
  /// Example:
  /// ```
  /// final extent = CoordinateExtent.fromRect(
  ///   Rect.fromLTWH(0, 0, 1920, 1080)
  /// );
  /// ```
  factory CoordinateExtent.fromRect(Rect rect) {
    return CoordinateExtent(
      minX: rect.left,
      minY: rect.top,
      maxX: rect.right,
      maxY: rect.bottom,
    );
  }

  /// Creates an extent centered at the origin with the specified dimensions.
  ///
  /// Example:
  /// ```
  /// // 2000×2000 canvas centered at origin
  /// final extent = CoordinateExtent.centered(
  ///   width: 2000,
  ///   height: 2000,
  /// );
  /// // Result: -1000 to +1000 in both axes
  /// ```
  factory CoordinateExtent.centered({
    required double width,
    required double height,
  }) {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    return CoordinateExtent(
      minX: -halfWidth,
      minY: -halfHeight,
      maxX: halfWidth,
      maxY: halfHeight,
    );
  }

  /// Creates an extent that locks horizontal panning.
  ///
  /// Prevents left/right movement while allowing vertical panning.
  const CoordinateExtent.lockHorizontal({
    double x = 0,
  })  : minX = x,
        maxX = x,
        minY = double.negativeInfinity,
        maxY = double.infinity;

  /// Creates an extent that locks vertical panning.
  ///
  /// Prevents up/down movement while allowing horizontal panning.
  const CoordinateExtent.lockVertical({
    double y = 0,
  })  : minX = double.negativeInfinity,
        maxX = double.infinity,
        minY = y,
        maxY = y;

  // ==========================================================================
  // Extent Properties
  // ==========================================================================

  /// Returns true if this extent is unconstrained (infinite).
  bool get isInfinite =>
      minX.isInfinite && minY.isInfinite && maxX.isInfinite && maxY.isInfinite;

  /// Returns true if horizontal movement is constrained.
  bool get hasHorizontalConstraint => minX.isFinite || maxX.isFinite;

  /// Returns true if vertical movement is constrained.
  bool get hasVerticalConstraint => minY.isFinite || maxY.isFinite;

  /// Returns true if this extent fully constrains movement.
  bool get isFullyConstrained =>
      minX.isFinite && minY.isFinite && maxX.isFinite && maxY.isFinite;

  /// Returns the width of the constrained area.
  ///
  /// Returns [double.infinity] if horizontally unconstrained.
  double get width => maxX - minX;

  /// Returns the height of the constrained area.
  ///
  /// Returns [double.infinity] if vertically unconstrained.
  double get height => maxY - minY;

  /// Returns the center point of the extent.
  ///
  /// Returns [Offset.zero] if any boundary is infinite.
  Offset get center {
    if (!isFullyConstrained) return Offset.zero;
    return Offset(
      (minX + maxX) / 2,
      (minY + maxY) / 2,
    );
  }

  /// Converts this extent to a [Rect].
  ///
  /// Only valid if [isFullyConstrained] is true.
  /// Throws [StateError] if any boundary is infinite.
  Rect toRect() {
    if (!isFullyConstrained) {
      throw StateError(
        'Cannot convert infinite extent to Rect. '
        'Extent must have finite boundaries.',
      );
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  // ==========================================================================
  // Constraint Application
  // ==========================================================================

  /// Clamps the given offset to this extent's boundaries.
  ///
  /// Example:
  /// ```
  /// final extent = CoordinateExtent(minX: 0, minY: 0, maxX: 100, maxY: 100);
  /// final clamped = extent.clamp(Offset(150, -50));
  /// // Result: Offset(100, 0)
  /// ```
  Offset clamp(Offset offset) {
    return Offset(
      offset.dx.clamp(minX, maxX),
      offset.dy.clamp(minY, maxY),
    );
  }

  /// Returns true if the given offset is within this extent's boundaries.
  ///
  /// Example:
  /// ```
  /// if (extent.contains(nodePosition)) {
  ///   // Position is valid
  /// }
  /// ```
  bool contains(Offset offset) {
    return offset.dx >= minX &&
        offset.dx <= maxX &&
        offset.dy >= minY &&
        offset.dy <= maxY;
  }

  /// Returns true if the given rect is completely within this extent.
  ///
  /// Useful for validating node bounds.
  bool containsRect(Rect rect) {
    return rect.left >= minX &&
        rect.top >= minY &&
        rect.right <= maxX &&
        rect.bottom <= maxY;
  }

  /// Returns true if this extent overlaps with another extent.
  bool overlaps(CoordinateExtent other) {
    return minX <= other.maxX &&
        maxX >= other.minX &&
        minY <= other.maxY &&
        maxY >= other.minY;
  }

  // ==========================================================================
  // Extent Manipulation
  // ==========================================================================

  /// Returns a new extent expanded by the given amount on all sides.
  ///
  /// Example:
  /// ```
  /// final expanded = extent.expand(50); // Add 50px padding
  /// ```
  CoordinateExtent expand(double amount) {
    return CoordinateExtent(
      minX: minX.isFinite ? minX - amount : minX,
      minY: minY.isFinite ? minY - amount : minY,
      maxX: maxX.isFinite ? maxX + amount : maxX,
      maxY: maxY.isFinite ? maxY + amount : maxY,
    );
  }

  /// Returns a new extent shrunk by the given amount on all sides.
  CoordinateExtent shrink(double amount) => expand(-amount);

  /// Returns the intersection of this extent with another.
  ///
  /// The result is the overlapping area, or null if they don't overlap.
  CoordinateExtent? intersect(CoordinateExtent other) {
    if (!overlaps(other)) return null;

    return CoordinateExtent(
      minX: maxOf(minX, other.minX),
      minY: maxOf(minY, other.minY),
      maxX: minOf(maxX, other.maxX),
      maxY: minOf(maxY, other.maxY),
    );
  }

  /// Returns the union of this extent with another.
  ///
  /// The result is the smallest extent that contains both extents.
  CoordinateExtent union(CoordinateExtent other) {
    return CoordinateExtent(
      minX: minOf(minX, other.minX),
      minY: minOf(minY, other.minY),
      maxX: maxOf(maxX, other.maxX),
      maxY: maxOf(maxY, other.maxY),
    );
  }

  // Helper methods for min/max that handle infinity
  @pragma('vm:prefer-inline')
  static double minOf(double a, double b) {
    if (a.isInfinite && a.isNegative) return a;
    if (b.isInfinite && b.isNegative) return b;
    return a < b ? a : b;
  }

  @pragma('vm:prefer-inline')
  static double maxOf(double a, double b) {
    if (a.isInfinite && !a.isNegative) return a;
    if (b.isInfinite && !b.isNegative) return b;
    return a > b ? a : b;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CoordinateExtent &&
        other.minX == minX &&
        other.minY == minY &&
        other.maxX == maxX &&
        other.maxY == maxY;
  }

  @override
  int get hashCode => Object.hash(minX, minY, maxX, maxY);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DoubleProperty('minX', minX, defaultValue: double.negativeInfinity));
    properties.add(
        DoubleProperty('minY', minY, defaultValue: double.negativeInfinity));
    properties.add(DoubleProperty('maxX', maxX, defaultValue: double.infinity));
    properties.add(DoubleProperty('maxY', maxY, defaultValue: double.infinity));
    properties
        .add(FlagProperty('infinite', value: isInfinite, ifTrue: 'INFINITE'));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (isInfinite) return 'CoordinateExtent.infinite()';
    if (!isFullyConstrained) {
      return 'CoordinateExtent(partially constrained)';
    }
    return 'CoordinateExtent(${width.toStringAsFixed(0)}×${height.toStringAsFixed(0)} at ${center.dx.toStringAsFixed(0)}, ${center.dy.toStringAsFixed(0)})';
  }
}
