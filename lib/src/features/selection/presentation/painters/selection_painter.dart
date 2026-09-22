import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/theme_export.dart';

class SelectionRectanglePainter extends CustomPainter {
  final Rect? selectionRect;
  final FlowSelectionStyle style;
  final double zoom; // To scale the border correctly

  final Paint _selectionFillPaint;
  final Paint _selectionStrokePaint;

  SelectionRectanglePainter({
    required this.selectionRect,
    required this.style,
    required this.zoom,
  })  : _selectionFillPaint = Paint()
          ..color = style.fillColor ?? Colors.transparent,
        _selectionStrokePaint = Paint()
          ..color = style.borderColor ?? Colors.transparent
          ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (selectionRect == null) return;

    // Honor the themed corner radius (RF default is square; rounded is opt-in).
    final rrect = style.effectiveBorderRadius.toRRect(selectionRect!);
    canvas.drawRRect(rrect, _selectionFillPaint);

    if (style.borderColor == null) return;
    _selectionStrokePaint.strokeWidth =
        style.effectiveBorderWidth.clamp(0.5, 3.0);

    // Dashed border when dash+gap are positive (RF's default dotted outline);
    // dashLength: 0 renders solid.
    final dash = style.effectiveDashLength;
    final gap = style.effectiveGapLength;
    if (dash > 0 && gap > 0) {
      canvas.drawPath(_dashedOutline(rrect, dash, gap), _selectionStrokePaint);
    } else {
      canvas.drawRRect(rrect, _selectionStrokePaint);
    }
  }

  /// Marches the RRect perimeter, emitting a `dash`-long segment every
  /// `dash + gap`, composed into one path (one draw call).
  static Path _dashedOutline(RRect rrect, double dash, double gap) {
    final source = Path()..addRRect(rrect);
    final out = Path();
    final period = dash + gap;
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0.0, metric.length);
        out.addPath(metric.extractPath(distance, next), Offset.zero);
        distance += period;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(covariant SelectionRectanglePainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect ||
        oldDelegate.style != style ||
        oldDelegate.zoom != zoom;
  }
}
