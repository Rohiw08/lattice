import 'dart:math';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/domain/edge_animation_effect.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/theme/flow_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:lattice/src/features/edges/domain/edge_state.dart';

/// Painter for persistent edges using pre-computed paths.
class EdgePainter extends CustomPainter with DiagnosticableTreeMixin {
  final Map<String, FlowEdge> edges;
  final Map<String, EdgeRuntimeState> edgeStates;
  final FlowCanvasTheme theme;

  /// Canvas-level edge style already resolved against the brightness fallback
  /// (caller resolves `theme.edge ?? FlowEdgeStyle.system(context)` because a
  /// painter has no [BuildContext]).
  final FlowEdgeStyle defaultEdgeStyle;
  final Map<String, Path> precomputedPaths;
  final Map<String, EdgeGeom>? geoms;
  final int geometryEpoch;
  final int liveStamp;

  /// 0–1 when painting animated edges; null skips dash animation.
  final double? animationValue;

  /// Default effect for [FlowEdge.animated] without a custom [animationEffect].
  final EdgeAnimationEffect defaultAnimationEffect;

  final Paint _edgePaint;
  final Paint _markerPaint;

  EdgePainter({
    required this.edges,
    required this.theme,
    required this.defaultEdgeStyle,
    required this.precomputedPaths,
    this.edgeStates = const {},
    this.geoms,
    this.geometryEpoch = 0,
    this.liveStamp = 0,
    this.animationValue,
    this.defaultAnimationEffect = EdgeAnimationEffects.flowingDash,
  })  : _edgePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        _markerPaint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;
    _drawEdges(canvas);
  }

  void _drawEdges(Canvas canvas) {
    final defaultEdgeStyle = this.defaultEdgeStyle;
    final themeMarker = theme.edgeMarker;

    for (final entry in edges.entries) {
      final edgeId = entry.key;
      final edge = entry.value;

      final path = precomputedPaths[edgeId];
      if (path == null) continue;

      final state = edgeStates[edgeId];
      final states = _resolveEdgeStates(state, edge);
      // Canvas theme ← per-edge style (merge keeps theme hover/selected/…).
      final edgeStyle = defaultEdgeStyle.merge(edge.style);
      final strokeStyle = edgeStyle.resolveDecoration(states);

      _drawEdgeLine(canvas, path, strokeStyle, edge);
      _drawEdgeMarkers(
        canvas,
        path,
        edge,
        edgeStyle,
        strokeStyle,
        states,
        geoms?[edgeId],
        themeMarker,
      );
    }
  }

  Set<FlowEdgeState> _resolveEdgeStates(
      EdgeRuntimeState? state, FlowEdge edge) {
    final states = <FlowEdgeState>{};
    if (edge.selectable == false) states.add(FlowEdgeState.disabled);
    if (state?.selected ?? false) states.add(FlowEdgeState.selected);
    if (state?.hovered ?? false) states.add(FlowEdgeState.hovered);
    if (states.isEmpty) states.add(FlowEdgeState.normal);
    return states;
  }

  void _drawEdgeLine(
    Canvas canvas,
    Path path,
    FlowEdgeStrokeStyle strokeStyle,
    FlowEdge edge,
  ) {
    _edgePaint
      ..color = strokeStyle.color
      ..strokeWidth = strokeStyle.strokeWidth
      ..strokeCap = strokeStyle.strokeCap
      ..strokeJoin = strokeStyle.strokeJoin;

    if (edge.animated && animationValue != null) {
      final effect = edge.animationEffect ?? defaultAnimationEffect;
      effect.paint(canvas, path, _edgePaint, animationValue!);
      return;
    }

    canvas.drawPath(path, _edgePaint);
  }

  void _drawEdgeMarkers(
    Canvas canvas,
    Path path,
    FlowEdge edge,
    FlowEdgeStyle edgeStyle,
    FlowEdgeStrokeStyle strokeStyle,
    Set<FlowEdgeState> states,
    EdgeGeom? geom,
    FlowEdgeMarkerStyle? themeMarker,
  ) {
    // Per-edge → edge style → canvas theme.edgeMarker.
    final startMarkerStyle = edge.startMarkerStyle ??
        edgeStyle.startMarkerStyle ??
        themeMarker;
    if (startMarkerStyle != null) {
      _drawMarker(
        canvas,
        path,
        strokeStyle,
        startMarkerStyle,
        states,
        atStart: true,
        geom: geom,
      );
    }

    final endMarkerStyle =
        edge.endMarkerStyle ?? edgeStyle.endMarkerStyle ?? themeMarker;
    if (endMarkerStyle != null) {
      _drawMarker(
        canvas,
        path,
        strokeStyle,
        endMarkerStyle,
        states,
        atStart: false,
        geom: geom,
      );
    }
  }

  void _drawMarker(
    Canvas canvas,
    Path path,
    FlowEdgeStrokeStyle strokeStyle,
    FlowEdgeMarkerStyle markerStyle,
    Set<FlowEdgeState> states, {
    required bool atStart,
    EdgeGeom? geom,
  }) {
    Offset position;
    Offset direction;

    final cached = geom?.markers;
    if (cached != null) {
      position = atStart ? cached.startPosition : cached.endPosition;
      direction = atStart ? cached.startDirection : cached.endDirection;
    } else {
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) return;
      final metric = atStart ? metrics.first : metrics.last;
      final tangent = atStart
          ? metric.getTangentForOffset(0)
          : metric.getTangentForOffset(metric.length);
      if (tangent == null) return;
      position = tangent.position;
      direction = tangent.vector;
    }

    final resolvedMarkerStyle = markerStyle.resolve(states);

    _markerPaint
      ..color = resolvedMarkerStyle.color
      ..strokeWidth = resolvedMarkerStyle.strokeWidth
      ..style = PaintingStyle.stroke;

    final size = resolvedMarkerStyle.size.width;

    if (markerStyle.builder != null) {
      _markerPaint.style = PaintingStyle.fill;
      final metrics = path.computeMetrics().toList();
      if (metrics.isEmpty) return;
      final metric = atStart ? metrics.first : metrics.last;
      final tangent = atStart
          ? metric.getTangentForOffset(0)
          : metric.getTangentForOffset(metric.length);
      if (tangent == null) return;
      markerStyle.builder!(canvas, tangent, resolvedMarkerStyle);
      return;
    }

    final angle =
        atStart ? direction.direction + pi : direction.direction;

    _drawBuiltInMarker(
      canvas,
      markerStyle.markerType,
      position,
      angle,
      size,
    );
  }

  void _drawBuiltInMarker(
    Canvas canvas,
    EdgeMarkerType type,
    Offset position,
    double angle,
    double size,
  ) {
    switch (type) {
      case EdgeMarkerType.arrow:
        _drawArrow(canvas, position, angle, size, _markerPaint);
        break;
      case EdgeMarkerType.arrowClosed:
        _markerPaint.style = PaintingStyle.fill;
        _drawArrow(canvas, position, angle, size, _markerPaint, closed: true);
        break;
      case EdgeMarkerType.circle:
        _markerPaint.style = PaintingStyle.fill;
        canvas.drawCircle(position, size / 2, _markerPaint);
        break;
      case EdgeMarkerType.none:
        break;
    }
  }

  void _drawArrow(
    Canvas canvas,
    Offset position,
    double angle,
    double size,
    Paint paint, {
    bool closed = false,
  }) {
    const angleOffset = pi / 6;
    final leftAngle = angle - angleOffset;
    final rightAngle = angle + angleOffset;

    final leftPoint = Offset(
      position.dx - size * cos(leftAngle),
      position.dy - size * sin(leftAngle),
    );
    final rightPoint = Offset(
      position.dx - size * cos(rightAngle),
      position.dy - size * sin(rightAngle),
    );

    final arrowPath = Path();
    if (closed) {
      arrowPath
        ..moveTo(position.dx, position.dy)
        ..lineTo(leftPoint.dx, leftPoint.dy)
        ..lineTo(rightPoint.dx, rightPoint.dy)
        ..close();
    } else {
      arrowPath
        ..moveTo(leftPoint.dx, leftPoint.dy)
        ..lineTo(position.dx, position.dy)
        ..lineTo(rightPoint.dx, rightPoint.dy);
    }

    canvas.drawPath(arrowPath, paint);
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.geometryEpoch != geometryEpoch ||
        oldDelegate.liveStamp != liveStamp ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.edges != edges ||
        oldDelegate.edgeStates != edgeStates ||
        oldDelegate.theme != theme;
  }

  @override
  bool shouldRebuildSemantics(covariant EdgePainter oldDelegate) => false;
}
