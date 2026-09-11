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

    canvas.drawRect(selectionRect!, _selectionFillPaint);

    if (style.borderColor != null) {
      _selectionStrokePaint.strokeWidth = (style.borderWidth).clamp(0.5, 3.0);
      canvas.drawRect(selectionRect!, _selectionStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant SelectionRectanglePainter oldDelegate) {
    return oldDelegate.selectionRect != selectionRect ||
        oldDelegate.style != style ||
        oldDelegate.zoom != zoom;
  }
}
