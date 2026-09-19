import 'dart:math';
import 'package:lattice/src/features/connections/domain/models/connection.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:lattice/src/core/theme/components/connection_theme.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/utils/edge_path_creator.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:flutter/widgets.dart';

class ConnectionPainter extends CustomPainter {
  final FlowConnection? connection;
  final FlowConnectionRuntimeState? connectionState;
  final FlowConnectionStyle style;

  final Paint _connectionPaint;

  ConnectionPainter({
    required this.connection,
    required this.connectionState,
    required this.style,
  }) : _connectionPaint = Paint()
          // Default setup, will be overridden in paint
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (connection == null) return;

    _drawConnection(canvas);
  }

  void _drawConnection(Canvas canvas) {
    final conn = connection!;

    // Zero-length / click-just-started: bezier stubs stick out of the handle.
    if ((conn.endPoint - conn.startPoint).distance < 2.0) {
      return;
    }

    // Determine validity and stroke style based on runtime state
    final (validity, _) = switch (connectionState) {
      HoveringConnectionState s => (
          s.targetHandleKey.isEmpty
              ? ConnectionValidity.none
              : (s.isValid
                  ? ConnectionValidity.valid
                  : ConnectionValidity.invalid),
          s.targetHandleKey
        ),
      ReleasedConnectionState s => (
          (s.targetHandleKey == null || s.targetHandleKey!.isEmpty)
              ? ConnectionValidity.none
              : (s.isValid
                  ? ConnectionValidity.valid
                  : ConnectionValidity.invalid),
          s.targetHandleKey
        ),
      IdleConnectionState _ => (ConnectionValidity.none, null),
      null => (ConnectionValidity.none, null),
      FlowConnectionRuntimeState() => (ConnectionValidity.none, null),
    };

    final strokeStyle = style.resolveStroke(validity);

    // Configure the main paint object
    _connectionPaint
      ..color = strokeStyle.color
      ..strokeWidth = strokeStyle.strokeWidth;

    // Convert connection points to render space
    final renderStart = conn.startPoint;
    final renderEnd = conn.endPoint;

    // If a custom builder exists, call it and return.
    // The builder is now responsible for drawing the entire connection, including markers.
    if (style.connectionBuilder != null) {
      style.connectionBuilder!(
        canvas, // Pass the actual canvas
        renderStart,
        renderEnd,
        strokeStyle, // Pass the resolved stroke style
      );
      return; // Skip default drawing if builder is used
    }

    // Build the path using EdgePathCreator
    final path = EdgePathCreator.createPath(
      style.pathType, // Use pathType from the main style
      renderStart,
      renderEnd,
      sourcePosition: conn.sourcePosition,
      targetPosition: conn.targetPosition,
    );

    // Draw the connection path
    canvas.drawPath(path, _connectionPaint);

    // Draw markers (only if no custom builder was used)
    if (style.startMarkerStyle case final FlowEdgeMarkerStyle s?) {
      _drawMarker(canvas, path, strokeStyle.color, s, atStart: true);
    }
    if (style.endMarkerStyle case final FlowEdgeMarkerStyle e?) {
      _drawMarker(canvas, path, strokeStyle.color, e, atStart: false);
    }
  }

  // _buildPath method removed as path creation is now inline or handled by builder

  void _drawMarker(
    Canvas canvas,
    Path path,
    Color baseColor,
    FlowEdgeMarkerStyle markerStyle, {
    required bool atStart,
  }) {
    // Get path metrics
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) {
      return;
    }

    final metric = atStart ? metrics.first : metrics.last;
    final tangent = atStart
        ? metric.getTangentForOffset(0)
        : metric.getTangentForOffset(metric.length);

    if (tangent == null) return;

    // Resolve marker decoration
    final resolvedMarkerDecoration = markerStyle.decoration;

    // Configure marker paint locally to avoid state reuse issues
    final paint = Paint()
      ..color = resolvedMarkerDecoration.color
      ..strokeWidth = resolvedMarkerDecoration.strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final size = resolvedMarkerDecoration.size.width;

    // Handle custom builder
    if (markerStyle.builder != null) {
      paint.style = PaintingStyle.fill;
      markerStyle.builder!(canvas, tangent, resolvedMarkerDecoration);
      return;
    }

    // Calculate angle
    var angle = tangent.vector.direction;
    if (atStart) angle += pi;

    // Draw built-in marker types
    switch (markerStyle.markerType) {
      case EdgeMarkerType.arrow:
        _drawDefaultArrow(canvas, tangent.position, angle, size, paint,
            close: false);
        break;
      case EdgeMarkerType.arrowClosed:
        paint.style = PaintingStyle.fill;
        _drawDefaultArrow(canvas, tangent.position, angle, size, paint,
            close: true);
        break;
      case EdgeMarkerType.circle:
        paint.style = PaintingStyle.fill;
        canvas.drawCircle(tangent.position, size / 2, paint);
        break;
      case EdgeMarkerType.none:
        break;
    }
  }

  // Renamed _drawDefaultArrow, removed tangent, added position/angle args
  // Removed 'reverse' parameter, handled by angle calculation in _drawMarker
  void _drawDefaultArrow(
    Canvas canvas,
    Offset position,
    double angle,
    double size,
    Paint paint, {
    required bool close,
  }) {
    // Arrow head angle (30 degrees)
    const angleOffset = pi / 6;
    final leftAngle = angle - angleOffset;
    final rightAngle = angle + angleOffset;

    // Calculate the points relative to the angle
    final p2 = Offset(
      position.dx - size * cos(leftAngle),
      position.dy - size * sin(leftAngle),
    );
    final p3 = Offset(
      position.dx - size * cos(rightAngle),
      position.dy - size * sin(rightAngle),
    );

    final path = Path();
    if (close) {
      path
        ..moveTo(position.dx, position.dy) // Start at the tip
        ..lineTo(p2.dx, p2.dy) // Line to left wing point
        ..lineTo(p3.dx, p3.dy) // Line to right wing point
        ..close(); // Close back to the tip
    } else {
      path
        ..moveTo(p2.dx, p2.dy) // Start at left wing point
        ..lineTo(position.dx, position.dy) // Line to the tip
        ..lineTo(p3.dx, p3.dy); // Line to the right wing point
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ConnectionPainter old) {
    // Comparison remains the same
    return old.connection != connection ||
        old.connectionState != connectionState ||
        old.style != style;
  }
}
