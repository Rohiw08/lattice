import 'dart:ui';

import 'package:lattice/src/features/edges/domain/edge_animation_effect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FlowingDashEffect paints without throwing', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(100, 0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const FlowingDashEffect().paint(canvas, path, paint, 0.25);
    expect(recorder.endRecording(), isNotNull);
  });
}
