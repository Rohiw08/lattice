import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:flutter/material.dart';

/// Paints background pattern in **flow space** (inside [InteractiveViewer]).
///
/// The viewer transform moves this with nodes — no viewport-offset syncing.
class FlowSpaceBackgroundPainter extends CustomPainter {
  FlowSpaceBackgroundPainter({
    required this.style,
    required this.visibleFlow,
    required this.zoom,
  });

  final FlowBackgroundStyle style;

  /// Visible region in flow coordinates (with padding).
  final Rect visibleFlow;

  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    if (style.variant == BackgroundVariant.none) return;
    final gap = style.gap;
    if (gap <= 0 || !gap.isFinite) return;
    if (visibleFlow.isEmpty || !visibleFlow.isFinite) return;

    final paint = Paint()
      ..color = style.patternColor
      ..strokeWidth = style.lineWidth
      ..blendMode = style.blendMode
      ..isAntiAlias = zoom > 0.4;

    final left = (visibleFlow.left / gap).floor() * gap;
    final top = (visibleFlow.top / gap).floor() * gap;

    switch (style.variant) {
      case BackgroundVariant.dots:
        paint.style = PaintingStyle.fill;
        final r = style.dotRadius;
        for (var x = left; x <= visibleFlow.right; x += gap) {
          for (var y = top; y <= visibleFlow.bottom; y += gap) {
            canvas.drawCircle(Offset(x, y), r, paint);
          }
        }
      case BackgroundVariant.grid:
        paint.style = PaintingStyle.stroke;
        for (var x = left; x <= visibleFlow.right; x += gap) {
          canvas.drawLine(
            Offset(x, visibleFlow.top),
            Offset(x, visibleFlow.bottom),
            paint,
          );
        }
        for (var y = top; y <= visibleFlow.bottom; y += gap) {
          canvas.drawLine(
            Offset(visibleFlow.left, y),
            Offset(visibleFlow.right, y),
            paint,
          );
        }
      case BackgroundVariant.cross:
        paint.style = PaintingStyle.stroke;
        final half = style.crossSize / 2;
        for (var x = left; x <= visibleFlow.right; x += gap) {
          for (var y = top; y <= visibleFlow.bottom; y += gap) {
            canvas.drawLine(Offset(x - half, y), Offset(x + half, y), paint);
            canvas.drawLine(Offset(x, y - half), Offset(x, y + half), paint);
          }
        }
      case BackgroundVariant.none:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant FlowSpaceBackgroundPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.visibleFlow != visibleFlow ||
        oldDelegate.zoom != zoom;
  }
}
