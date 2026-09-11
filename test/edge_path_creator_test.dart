import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/utils/edge_path_creator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoothStep bottom→top leaves handle then bends with rounded corners',
      () {
    final path = EdgePathCreator.createPath(
      EdgePathType.smoothStep,
      const Offset(100, 0),
      const Offset(300, 200),
      sourcePosition: HandlePosition.bottom,
      targetPosition: HandlePosition.top,
      borderRadius: 8,
      stepOffset: 20,
    );

    final metrics = path.computeMetrics().toList();
    expect(metrics, isNotEmpty);
    expect(metrics.first.length, greaterThan(200));

    // Path should leave source downward (offset) before bending — not a
    // naive horizontal mid-X step that ignores handle direction.
    final samples = <Offset>[];
    for (final m in metrics) {
      for (double d = 0; d <= m.length; d += 5) {
        final t = m.getTangentForOffset(d);
        if (t != null) samples.add(t.position);
      }
    }
    expect(samples.first.dx, closeTo(100, 1));
    expect(samples.first.dy, closeTo(0, 1));
    // Shortly after start, still near source x and below source (left handle).
    final nearStart = samples[2];
    expect(nearStart.dx, closeTo(100, 2));
    expect(nearStart.dy, greaterThan(5));
  });

  test('step uses sharp corners (borderRadius 0) with same router', () {
    final sharp = EdgePathCreator.createPath(
      EdgePathType.step,
      const Offset(0, 0),
      const Offset(200, 100),
      sourcePosition: HandlePosition.right,
      targetPosition: HandlePosition.left,
    );
    final smooth = EdgePathCreator.createPath(
      EdgePathType.smoothStep,
      const Offset(0, 0),
      const Offset(200, 100),
      sourcePosition: HandlePosition.right,
      targetPosition: HandlePosition.left,
      borderRadius: 8,
    );
    // Rounded corners cut the sharp corner, so smooth is slightly shorter.
    final sharpLen = sharp.computeMetrics().first.length;
    final smoothLen = smooth.computeMetrics().first.length;
    expect(smoothLen, lessThan(sharpLen));
    expect(smoothLen, greaterThan(sharpLen * 0.9));
  });

  test('bezier uses distance * curvature control offset', () {
    final path = EdgePathCreator.getBezierPathWithPositions(
      source: const Offset(0, 0),
      target: const Offset(200, 100),
      sourcePosition: HandlePosition.right,
      targetPosition: HandlePosition.left,
      curvature: 0.5,
      controlOffset: 20,
    );
    final metrics = path.computeMetrics().toList();
    expect(metrics, isNotEmpty);
    // Curved path is longer than the straight chord.
    final chord = (const Offset(200, 100) - const Offset(0, 0)).distance;
    expect(metrics.first.length, greaterThan(chord));
  });
}
