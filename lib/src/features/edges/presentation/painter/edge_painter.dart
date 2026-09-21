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

  /// Per-edge geometry versions (see `EdgeGeometryService.edgeVersions`).
  ///
  /// Compared for this painter's own edge ids so unrelated geometry
  /// changes don't repaint it; the global [geometryEpoch] alone would.
  final Map<String, int>? versions;
  final int geometryEpoch;
  final int liveStamp;

  /// 0–1 when painting animated edges; null skips dash animation.
  final double? animationValue;

  /// Canvas default for edges that don't set `selectable`
  /// (`EdgeOptions.selectable`, RF `edgesSelectable`). Drives the disabled
  /// state tint; the caller resolves `EdgeOptions` (a painter has no
  /// [BuildContext]).
  final bool edgesSelectable;

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
    this.versions,
    this.geometryEpoch = 0,
    this.liveStamp = 0,
    this.animationValue,
    this.edgesSelectable = true,
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
      final foreground = edge.foregroundPainter;
      if (foreground != null) {
        foreground(
          canvas,
          FlowEdgePaintContext(
            path: path,
            edge: edge,
            selected: states.contains(FlowEdgeState.selected),
            hovered: states.contains(FlowEdgeState.hovered),
          ),
        );
      }
    }
  }

  Set<FlowEdgeState> _resolveEdgeStates(
      EdgeRuntimeState? state, FlowEdge edge) {
    final states = <FlowEdgeState>{};
    if (!(edge.selectable ?? edgesSelectable)) {
      states.add(FlowEdgeState.disabled);
    }
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

    final dashPattern = strokeStyle.dashPattern;
    if (dashPattern != null && dashPattern.isNotEmpty) {
      canvas.drawPath(buildDashedPath(path, dashPattern), _edgePaint);
      return;
    }

    canvas.drawPath(path, _edgePaint);
  }

  /// Builds a dashed copy of [source] from a `[on, off, on, off, …]` pattern
  /// of lengths in path units (matches SVG `stroke-dasharray`, which Flutter's
  /// [Paint] has no native support for).
  ///
  /// The pattern cycles: an odd-length list repeats to an even one implicitly
  /// (`[5]` → dash 5 / gap 5 / …). Returns [source] unchanged when the pattern
  /// is empty or sums to zero (nothing to march), so callers can pass it
  /// straight to [Canvas.drawPath].
  @visibleForTesting
  static Path buildDashedPath(Path source, List<double> pattern) {
    if (pattern.isEmpty) return source;
    var patternTotal = 0.0;
    for (final segment in pattern) {
      patternTotal += segment;
    }
    if (patternTotal <= 0) return source;

    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      var patternIndex = 0;
      var drawing = true; // pattern[0] is the first "on" (dash) length.
      while (distance < metric.length) {
        final segmentLength = pattern[patternIndex % pattern.length];
        final next = distance + segmentLength;
        if (drawing && segmentLength > 0) {
          dashed.addPath(
            metric.extractPath(distance, next.clamp(0.0, metric.length)),
            Offset.zero,
          );
        }
        distance = next;
        drawing = !drawing;
        patternIndex++;
      }
    }
    return dashed;
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
    // NOTE: `edges` is rebuilt as a fresh map every build by the layer, so
    // identity comparison would repaint unconditionally. Compare key sets
    // instead (O(n), microseconds), then per-edge geometry versions so
    // unrelated edge changes don't repaint this painter either. Content
    // changes always bump versions via the geometry service, and selection
    // changes swap `edgeStates` identity.
    return (oldDelegate.geometryEpoch != geometryEpoch &&
            !_sameVersions(oldDelegate)) ||
        oldDelegate.liveStamp != liveStamp ||
        oldDelegate.animationValue != animationValue ||
        !_sameEdgeIds(oldDelegate.edges, edges) ||
        oldDelegate.edgeStates != edgeStates ||
        oldDelegate.theme != theme;
  }

  /// True when every edge painted here has the same geometry version as in
  /// [oldDelegate]. Missing version maps fall back to repainting. The maps
  /// may be identical instances (the service mutates in place), so values
  /// are always compared per painted edge id.
  bool _sameVersions(EdgePainter oldDelegate) {
    final oldVersions = oldDelegate.versions;
    final newVersions = versions;
    if (oldVersions == null || newVersions == null) return false;
    for (final id in edges.keys) {
      if (oldVersions[id] != newVersions[id]) return false;
    }
    return true;
  }

  /// Key-set equality for edge maps rebuilt per build (see [shouldRepaint]).
  static bool _sameEdgeIds(
      Map<String, FlowEdge> a, Map<String, FlowEdge> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key)) return false;
    }
    return true;
  }

  @override
  bool shouldRebuildSemantics(covariant EdgePainter oldDelegate) => false;
}
