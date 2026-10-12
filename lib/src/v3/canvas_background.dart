import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_theme.dart';
import 'lattice_viewport_value.dart';

/// Background pattern for the canvas pane.
enum LatticeBackgroundPattern { dots, lines, none }

/// Screen-space canvas background (dots or grid lines) derived from the
/// camera matrix.
///
/// The pattern comes from [style]; the paint colors come from the nearest
/// [LatticeThemeScope] background component (light fallback when mounted
/// standalone).
///
/// Watches ONLY [latticeCameraProvider]: camera ticks repaint it, but
/// document/selection/drag emissions never rebuild it. The painter's
/// [LatticeBackgroundPainter.shouldRepaint] compares the matrix instance,
/// so repaints happen only on matrix change.
class LatticeBackground extends ConsumerWidget {
  const LatticeBackground({
    super.key,
    this.style = LatticeBackgroundPattern.dots,
    this.gap = 24,
  });

  final LatticeBackgroundPattern style;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Matrix4 matrix = ref.watch(latticeCameraProvider);
    final LatticeTheme theme =
        LatticeThemeScope.maybeOf(context) ?? LatticeTheme.light();
    final LatticeBackgroundStyle background = theme.resolvedBackground;
    return SizedBox.expand(
      child: CustomPaint(
        painter: LatticeBackgroundPainter(
          matrix: matrix,
          style: style,
          gap: gap,
          dotColor: background.dotColor,
          lineColor: background.lineColor,
          dotRadius: background.dotRadius,
        ),
      ),
    );
  }
}

/// Paints [style] in screen space: the grid spacing is [gap] scaled by
/// the camera zoom (clamped to 8..96px to avoid dot explosion at extreme
/// zooms), offset by the camera translation modulo the spacing. Dots use
/// [dotRadius] (constant in screen space), lines use [lineColor].
class LatticeBackgroundPainter extends CustomPainter {
  LatticeBackgroundPainter({
    required this.matrix,
    required this.style,
    required this.gap,
    required this.dotColor,
    required this.lineColor,
    required this.dotRadius,
  });

  final Matrix4 matrix;
  final LatticeBackgroundPattern style;
  final double gap;
  final Color dotColor;
  final Color lineColor;
  final double dotRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == LatticeBackgroundPattern.none) return;
    final LatticeViewportValue viewport = LatticeViewportValue.fromMatrix(
      matrix,
    );
    final double zoom = viewport.zoom.isFinite ? viewport.zoom : 1.0;
    final double spacing = (gap * (zoom == 0 ? 1.0 : zoom)).clamp(8.0, 96.0);
    final double startX = _positiveMod(viewport.offset.dx, spacing);
    final double startY = _positiveMod(viewport.offset.dy, spacing);

    if (style == LatticeBackgroundPattern.dots) {
      final Paint paint = Paint()..color = dotColor;
      for (var x = startX; x <= size.width; x += spacing) {
        for (var y = startY; y <= size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
      return;
    }

    final Paint paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0;
    for (var x = startX; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = startY; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant LatticeBackgroundPainter oldDelegate) {
    return !identical(matrix, oldDelegate.matrix) ||
        style != oldDelegate.style ||
        gap != oldDelegate.gap ||
        dotColor != oldDelegate.dotColor ||
        lineColor != oldDelegate.lineColor ||
        dotRadius != oldDelegate.dotRadius;
  }
}

double _positiveMod(double value, double mod) {
  if (!value.isFinite || mod <= 0) return 0.0;
  return value - (value / mod).floor() * mod;
}
