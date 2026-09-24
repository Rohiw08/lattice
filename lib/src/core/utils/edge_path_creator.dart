import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// Edge path builders with smooth orthogonal routing.
///
/// Step and smooth-step use the same orthogonal router as
/// `canvas geometry utilities` `getSmoothStepPath` (handle directions, leave-handle
/// offset, bend points). Smooth-step rounds corners with quadratic bends;
/// step keeps sharp corners (`borderRadius: 0`).
@immutable
class EdgePathCreator {
  const EdgePathCreator._();

  /// Default curvature for bezier edges (0–1).
  static const double defaultCurvature = 0.5;

  /// Default corner radius for [EdgePathType.smoothStep] (default: 5).
  static const double defaultBorderRadius = 8.0;

  /// Minimum leave-handle distance before the first bend (default: 20).
  static const double defaultStepOffset = 20.0;

  /// Default control-point floor for positioned bezier edges.
  static const double defaultControlOffset = 20.0;

  /// Creates a path for [type] between [start] and [end].
  static Path createPath(
    EdgePathType type,
    Offset start,
    Offset end, {
    double curvature = defaultCurvature,
    double borderRadius = defaultBorderRadius,
    double stepOffset = defaultStepOffset,
    HandlePosition sourcePosition = HandlePosition.right,
    HandlePosition targetPosition = HandlePosition.left,
  }) {
    assert(curvature >= 0.0 && curvature <= 1.0);
    assert(borderRadius >= 0.0);
    assert(stepOffset >= 0.0);

    switch (type) {
      case EdgePathType.bezier:
        return getBezierPathWithPositions(
          source: start,
          target: end,
          sourcePosition: sourcePosition,
          targetPosition: targetPosition,
          curvature: curvature,
        );
      case EdgePathType.straight:
        return _getStraightPath(start, end);
      case EdgePathType.step:
        return getSmoothStepPath(
          source: start,
          target: end,
          sourcePosition: sourcePosition,
          targetPosition: targetPosition,
          borderRadius: 0,
          offset: stepOffset,
        );
      case EdgePathType.smoothStep:
        return getSmoothStepPath(
          source: start,
          target: end,
          sourcePosition: sourcePosition,
          targetPosition: targetPosition,
          borderRadius: borderRadius,
          offset: stepOffset,
        );
      case EdgePathType.simpleBezier:
        return getSimpleBezierPath(
          source: start,
          target: end,
          sourcePosition: sourcePosition,
          targetPosition: targetPosition,
        );
    }
  }

  static Path _getStraightPath(Offset start, Offset end) {
    return Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);
  }

  /// Public straight-line path (Lattice `getStraightPath`).
  static Path getStraightPath({
    required Offset source,
    required Offset target,
  }) =>
      _getStraightPath(source, target);

  // ── Smooth step / step (orthogonal router) ─────────────────────────────

  /// Port of `canvas geometry utilities` `getSmoothStepPath`.
  static Path getSmoothStepPath({
    required Offset source,
    required Offset target,
    HandlePosition sourcePosition = HandlePosition.bottom,
    HandlePosition targetPosition = HandlePosition.top,
    double borderRadius = defaultBorderRadius,
    double offset = defaultStepOffset,
    double stepPosition = 0.5,
    Offset? center,
  }) {
    final points = _getSmoothStepPoints(
      source: source,
      sourcePosition: sourcePosition,
      target: target,
      targetPosition: targetPosition,
      center: center,
      offset: offset,
      stepPosition: stepPosition,
    );

    if (points.length < 2) {
      return _getStraightPath(source, target);
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);

    for (var i = 1; i < points.length - 1; i++) {
      _appendBend(
        path,
        points[i - 1],
        points[i],
        points[i + 1],
        borderRadius,
      );
    }

    final last = points.last;
    path.lineTo(last.dx, last.dy);
    return path;
  }

  static Offset _handleDirection(HandlePosition position) {
    switch (position) {
      case HandlePosition.left:
        return const Offset(-1, 0);
      case HandlePosition.right:
        return const Offset(1, 0);
      case HandlePosition.top:
        return const Offset(0, -1);
      case HandlePosition.bottom:
        return const Offset(0, 1);
    }
  }

  static bool _isHorizontal(HandlePosition position) =>
      position == HandlePosition.left || position == HandlePosition.right;

  /// Primary travel direction after leaving the source gap point.
  static Offset _primaryDirection({
    required Offset sourceGapped,
    required HandlePosition sourcePosition,
    required Offset targetGapped,
  }) {
    if (_isHorizontal(sourcePosition)) {
      return sourceGapped.dx < targetGapped.dx
          ? const Offset(1, 0)
          : const Offset(-1, 0);
    }
    return sourceGapped.dy < targetGapped.dy
        ? const Offset(0, 1)
        : const Offset(0, -1);
  }

  static double _distance(Offset a, Offset b) => (b - a).distance;

  static List<Offset> _getSmoothStepPoints({
    required Offset source,
    required HandlePosition sourcePosition,
    required Offset target,
    required HandlePosition targetPosition,
    Offset? center,
    required double offset,
    required double stepPosition,
  }) {
    final sourceDir = _handleDirection(sourcePosition);
    final targetDir = _handleDirection(targetPosition);
    final sourceGapped = source + sourceDir * offset;
    final targetGapped = target + targetDir * offset;
    final dir = _primaryDirection(
      sourceGapped: sourceGapped,
      sourcePosition: sourcePosition,
      targetGapped: targetGapped,
    );
    final useX = dir.dx != 0;
    final currDir = useX ? dir.dx : dir.dy;
    final sourceDirComp = useX ? sourceDir.dx : sourceDir.dy;
    final targetDirComp = useX ? targetDir.dx : targetDir.dy;

    var points = <Offset>[];
    var sourceGapOffset = Offset.zero;
    var targetGapOffset = Offset.zero;

    // Opposite handles (e.g. Bottom → Top, Right → Left): default case.
    if (sourceDirComp * targetDirComp == -1) {
      late final double centerX;
      late final double centerY;
      if (useX) {
        centerX = center?.dx ??
            sourceGapped.dx +
                (targetGapped.dx - sourceGapped.dx) * stepPosition;
        centerY = center?.dy ?? (sourceGapped.dy + targetGapped.dy) / 2;
      } else {
        centerX = center?.dx ?? (sourceGapped.dx + targetGapped.dx) / 2;
        centerY = center?.dy ??
            sourceGapped.dy +
                (targetGapped.dy - sourceGapped.dy) * stepPosition;
      }

      final verticalSplit = [
        Offset(centerX, sourceGapped.dy),
        Offset(centerX, targetGapped.dy),
      ];
      final horizontalSplit = [
        Offset(sourceGapped.dx, centerY),
        Offset(targetGapped.dx, centerY),
      ];

      if (sourceDirComp == currDir) {
        points = useX ? verticalSplit : horizontalSplit;
      } else {
        points = useX ? horizontalSplit : verticalSplit;
      }
    } else {
      final sourceTarget = [Offset(sourceGapped.dx, targetGapped.dy)];
      final targetSource = [Offset(targetGapped.dx, sourceGapped.dy)];

      if (useX) {
        points = sourceDir.dx == currDir ? targetSource : sourceTarget;
      } else {
        points = sourceDir.dy == currDir ? sourceTarget : targetSource;
      }

      if (sourcePosition == targetPosition) {
        final sourceComp = useX ? source.dx : source.dy;
        final targetComp = useX ? target.dx : target.dy;
        final diff = (sourceComp - targetComp).abs();

        if (diff <= offset) {
          final gapOffset = min(offset - 1, offset - diff);
          if (sourceDirComp == currDir) {
            final gappedComp = useX ? sourceGapped.dx : sourceGapped.dy;
            final sourceCompVal = useX ? source.dx : source.dy;
            final sign = gappedComp > sourceCompVal ? -1.0 : 1.0;
            sourceGapOffset =
                useX ? Offset(sign * gapOffset, 0) : Offset(0, sign * gapOffset);
          } else {
            final gappedComp = useX ? targetGapped.dx : targetGapped.dy;
            final targetCompVal = useX ? target.dx : target.dy;
            final sign = gappedComp > targetCompVal ? -1.0 : 1.0;
            targetGapOffset =
                useX ? Offset(sign * gapOffset, 0) : Offset(0, sign * gapOffset);
          }
        }
      }

      if (sourcePosition != targetPosition) {
        final sourceOpp = useX ? sourceGapped.dy : sourceGapped.dx;
        final targetOpp = useX ? targetGapped.dy : targetGapped.dx;
        final targetDirOpp = useX ? targetDir.dy : targetDir.dx;
        final isSameDir = sourceDirComp == targetDirOpp;
        final sourceGtTargetOppo = sourceOpp > targetOpp;
        final sourceLtTargetOppo = sourceOpp < targetOpp;
        final flipSourceTarget = (sourceDirComp == 1 &&
                ((!isSameDir && sourceGtTargetOppo) ||
                    (isSameDir && sourceLtTargetOppo))) ||
            (sourceDirComp != 1 &&
                ((!isSameDir && sourceLtTargetOppo) ||
                    (isSameDir && sourceGtTargetOppo)));

        if (flipSourceTarget) {
          points = useX ? sourceTarget : targetSource;
        }
      }
    }

    final gappedSource = sourceGapped + sourceGapOffset;
    final gappedTarget = targetGapped + targetGapOffset;

    final pathPoints = <Offset>[source];
    if (gappedSource.dx != points.first.dx ||
        gappedSource.dy != points.first.dy) {
      pathPoints.add(gappedSource);
    }
    pathPoints.addAll(points);
    if (gappedTarget.dx != points.last.dx ||
        gappedTarget.dy != points.last.dy) {
      pathPoints.add(gappedTarget);
    }
    pathPoints.add(target);
    return pathPoints;
  }

  /// Corner-bend helper — appends a sharp or rounded corner at [b].
  static void _appendBend(
    Path path,
    Offset a,
    Offset b,
    Offset c,
    double size,
  ) {
    final bendSize = min(
      min(_distance(a, b) / 2, _distance(b, c) / 2),
      size,
    );
    final x = b.dx;
    final y = b.dy;

    // Collinear — no bend.
    if ((a.dx == x && x == c.dx) || (a.dy == y && y == c.dy)) {
      path.lineTo(x, y);
      return;
    }

    if (size <= 0 || bendSize < 0.5) {
      path.lineTo(x, y);
      return;
    }

    // First segment is horizontal.
    if (a.dy == y) {
      final xDir = a.dx < c.dx ? -1.0 : 1.0;
      final yDir = a.dy < c.dy ? 1.0 : -1.0;
      path.lineTo(x + bendSize * xDir, y);
      path.quadraticBezierTo(x, y, x, y + bendSize * yDir);
      return;
    }

    // First segment is vertical.
    final xDir = a.dx < c.dx ? 1.0 : -1.0;
    final yDir = a.dy < c.dy ? -1.0 : 1.0;
    path.lineTo(x, y + bendSize * yDir);
    path.quadraticBezierTo(x, y, x + bendSize * xDir, y);
  }

  // ── Bezier ───────────────────────────────────────────────────────

  /// Control point for [getSimpleBezierPath] (exact Lattice port): midpoint
  /// on the handle axis, anchor on the other.
  static Offset _simpleBezierControl(
    HandlePosition position,
    Offset p1,
    Offset p2,
  ) {
    if (position == HandlePosition.left ||
        position == HandlePosition.right) {
      return Offset(0.5 * (p1.dx + p2.dx), p1.dy);
    }
    return Offset(p1.dx, 0.5 * (p1.dy + p2.dy));
  }

  /// Simple cubic bezier between two points (Lattice `getSimpleBezierPath`,
  /// exact port of `SimpleBezierEdge`: midpoint controls, no curvature).
  static Path getSimpleBezierPath({
    required Offset source,
    required Offset target,
    HandlePosition sourcePosition = HandlePosition.bottom,
    HandlePosition targetPosition = HandlePosition.top,
  }) {
    final c1 = _simpleBezierControl(sourcePosition, source, target);
    final c2 = _simpleBezierControl(targetPosition, target, source);
    return Path()
      ..moveTo(source.dx, source.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, target.dx, target.dy);
  }

  static Path getBezierPathWithPositions({
    required Offset source,
    required Offset target,
    HandlePosition sourcePosition = HandlePosition.right,
    HandlePosition targetPosition = HandlePosition.left,
    double curvature = defaultCurvature,
    double controlOffset = defaultControlOffset,
  }) {
    assert(curvature >= 0.0 && curvature <= 1.0);
    assert(controlOffset >= 0.0);

    final path = Path()..moveTo(source.dx, source.dy);
    final dx = target.dx - source.dx;
    final dy = target.dy - source.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final offset = max(controlOffset, distance * curvature);

    final cp1 = _getControlPoint(source, sourcePosition, offset);
    final cp2 = _getControlPoint(target, targetPosition, offset);

    path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, target.dx, target.dy);
    return path;
  }

  static Offset _getControlPoint(
    Offset point,
    HandlePosition position,
    double offset,
  ) {
    switch (position) {
      case HandlePosition.left:
        return Offset(point.dx - offset, point.dy);
      case HandlePosition.right:
        return Offset(point.dx + offset, point.dy);
      case HandlePosition.top:
        return Offset(point.dx, point.dy - offset);
      case HandlePosition.bottom:
        return Offset(point.dx, point.dy + offset);
    }
  }

  /// Center + half-extents between two endpoints (React Flow `getEdgeCenter`).
  ///
  /// Exact port of `getEdgeCenter` in
  /// `xyflow/packages/system/src/utils/edges/general.ts`: used for straight
  /// edges and simple smooth-step labels (LTR, RTL, BTT, TTB). Returns
  /// `(center, offset)` where `offset` holds the non-negative half
  /// distances, so `center == source + offset` up to direction.
  static ({Offset center, Offset offset}) getEdgeCenter({
    required Offset source,
    required Offset target,
  }) {
    final xOffset = (target.dx - source.dx).abs() / 2;
    final centerX =
        target.dx < source.dx ? target.dx + xOffset : target.dx - xOffset;
    final yOffset = (target.dy - source.dy).abs() / 2;
    final centerY =
        target.dy < source.dy ? target.dy + yOffset : target.dy - yOffset;
    return (
      center: Offset(centerX, centerY),
      offset: Offset(xOffset, yOffset),
    );
  }
}
