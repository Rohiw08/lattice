// Defines snapping resolution for aligning nodes, handles, and guides.
import 'dart:ui';
import 'package:flutter/foundation.dart';

///
/// Used to make dragging feel “grid-aligned” and visually consistent.
@immutable
class SnapGrid {
  /// The horizontal grid cell size.
  final double width;

  /// The vertical grid cell size.
  final double height;

  /// Creates a snapping grid definition.
  const SnapGrid({
    this.width = 10,
    this.height = 10,
  });

  /// Creates a new grid with modified dimensions.
  SnapGrid copyWith({double? width, double? height}) {
    return SnapGrid(
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }

  /// Returns a new coordinate snapped to the grid.
  Offset snap(Offset position) {
    return Offset(
      (position.dx / width).round() * width,
      (position.dy / height).round() * height,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SnapGrid &&
          runtimeType == other.runtimeType &&
          width == other.width &&
          height == other.height);

  @override
  int get hashCode => Object.hash(width, height);
}
