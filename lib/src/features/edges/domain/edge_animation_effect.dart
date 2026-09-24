import 'dart:ui';

/// Animation effect drawn along an edge path (VNF-style).
///
/// [animationValue] cycles 0→1 from a shared [AnimationController] that only
/// runs while at least one edge is animated.
abstract interface class EdgeAnimationEffect {
  void paint(
    Canvas canvas,
    Path path,
    Paint basePaint,
    double animationValue,
  );
}

/// Marching-ants / flowing dashes — React Flow `animated: true` look.
///
/// Uses path metrics + extractPath (same path-metrics approach) so only
/// dash segments are drawn; geometry stays on the precomputed edge [Path].
class FlowingDashEffect implements EdgeAnimationEffect {
  const FlowingDashEffect({
    this.speed = 1,
    this.dashLength = 10,
    this.gapLength = 5,
  })  : assert(speed > 0),
        assert(dashLength > 0),
        assert(gapLength > 0);

  /// Complete pattern cycles per animation period (integer → seamless loop).
  final int speed;

  /// Dash length in path units (flow space pixels).
  final int dashLength;

  /// Gap length in path units.
  final int gapLength;

  @override
  void paint(
    Canvas canvas,
    Path path,
    Paint basePaint,
    double animationValue,
  ) {
    final totalDashLength = dashLength + gapLength;
    final animationOffset =
        (animationValue * speed * totalDashLength) % totalDashLength;

    for (final metric in path.computeMetrics()) {
      var distance = animationOffset - totalDashLength;
      var isDash = true;

      while (distance < metric.length) {
        final segmentLength = (isDash ? dashLength : gapLength).toDouble();
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + segmentLength).clamp(0.0, metric.length);

        if (isDash && start < end) {
          canvas.drawPath(metric.extractPath(start, end), basePaint);
        }

        distance += segmentLength;
        isDash = !isDash;
      }
    }
  }
}

/// Built-in presets.
abstract final class EdgeAnimationEffects {
  static const flowingDash = FlowingDashEffect();
  static const flowingDashFast = FlowingDashEffect(speed: 2);
  static const flowingDashSlow =
      FlowingDashEffect(speed: 1, dashLength: 15, gapLength: 8);
}
