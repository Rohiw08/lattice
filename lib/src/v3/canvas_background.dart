import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_viewport_value.dart';

/// Background pattern for the canvas pane.
enum LatticeBackgroundStyle { dots, lines, none }

/// Screen-space canvas background (dots or grid lines) derived from the
/// camera matrix.
///
/// Watches ONLY [latticeCameraProvider]: camera ticks repaint it, but
/// document/selection/drag emissions never rebuild it. The painter's
/// [LatticeBackgroundPainter.shouldRepaint] compares the matrix instance,
/// so repaints happen only on matrix change.
class LatticeBackground extends ConsumerWidget {
  const LatticeBackground({
    super.key,
    this.style = LatticeBackgroundStyle.dots,
    this.gap = 24,
  });

  final LatticeBackgroundStyle style;
  final double gap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Matrix4 matrix = ref.watch(latticeCameraProvider);
    return SizedBox.expand(
      child: CustomPaint(
        painter: LatticeBackgroundPainter(
          matrix: matrix,
          style: style,
          gap: gap,
        ),
      ),
    );
  }
}

/// Paints [style] in screen space: the grid spacing is [gap] scaled by
/// the camera zoom (clamped to 8..96px to avoid dot explosion at extreme
/// zooms), offset by the camera translation modulo the spacing. Dot
/// radius stays constant at 1.5px regardless of zoom.
class LatticeBackgroundPainter extends CustomPainter {
  LatticeBackgroundPainter({
    required this.matrix,
    required this.style,
    required this.gap,
  });

  final Matrix4 matrix;
  final LatticeBackgroundStyle style;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    if (style == LatticeBackgroundStyle.none) return;
    final LatticeViewportValue viewport = LatticeViewportValue.fromMatrix(
      matrix,
    );
    final double zoom = viewport.zoom.isFinite ? viewport.zoom : 1.0;
    final double spacing = (gap * (zoom == 0 ? 1.0 : zoom)).clamp(8.0, 96.0);
    final double startX = _positiveMod(viewport.offset.dx, spacing);
    final double startY = _positiveMod(viewport.offset.dy, spacing);

    if (style == LatticeBackgroundStyle.dots) {
      // V3-6 Task 6: theme
      final Paint paint = Paint()..color = const Color(0xFFE2E8F0);
      for (var x = startX; x <= size.width; x += spacing) {
        for (var y = startY; y <= size.height; y += spacing) {
          canvas.drawCircle(Offset(x, y), 1.5, paint);
        }
      }
      return;
    }

    // V3-6 Task 6: theme
    final Paint paint = Paint()
      ..color = const Color(0xFFF1F5F9)
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
        gap != oldDelegate.gap;
  }
}

double _positiveMod(double value, double mod) {
  if (!value.isFinite || mod <= 0) return 0.0;
  return value - (value / mod).floor() * mod;
}
