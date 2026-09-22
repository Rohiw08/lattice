import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:lattice/src/features/background/presentation/painters/flow_space_background_painter.dart';

/// `patternOffset` phase-shifts the dot/grid lattice (RF Background `offset`);
/// it was previously ignored by the painter.
class _DotRecorder implements Canvas {
  final List<Offset> centers = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) => centers.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const gap = 20.0;
  const visible = Rect.fromLTWH(0, 0, 100, 100);

  List<Offset> paint({required Offset offset}) {
    final canvas = _DotRecorder();
    FlowSpaceBackgroundPainter(
      style: FlowBackgroundStyle(
        variant: BackgroundVariant.dots,
        gap: gap,
        patternOffset: offset,
        patternColor: const Color(0xFF000000),
      ),
      visibleFlow: visible,
      zoom: 1,
    ).paint(canvas, const Size(100, 100));
    return canvas.centers;
  }

  test('no offset places dots on the gap lattice (x % gap == 0)', () {
    for (final c in paint(offset: Offset.zero)) {
      expect(c.dx % gap, moreOrLessEquals(0));
    }
  });

  test('a 7px x-offset shifts every dot to x % gap == 7', () {
    final centers = paint(offset: const Offset(7, 0));
    expect(centers, isNotEmpty);
    for (final c in centers) {
      expect((c.dx - 7) % gap, moreOrLessEquals(0));
    }
  });
}
