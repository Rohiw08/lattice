import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/presentation/painter/edge_painter.dart';

/// A [Canvas] that records every [drawPath] call; everything else is a no-op.
/// The edge line is drawn (via [Canvas.drawPath]) BEFORE its markers, so
/// `paths.first` is always the line itself.
class _RecordingCanvas implements Canvas {
  final List<Path> paths = [];

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Total "on" ink across a path's contours.
double _inkLength(Path path) {
  var total = 0.0;
  for (final m in path.computeMetrics()) {
    total += m.length;
  }
  return total;
}

EdgePainter _painter(FlowEdgeStyle style) {
  const id = 'e1';
  return EdgePainter(
    edges: Map<String, FlowEdge>.of(const {
      id: FlowEdge(id: id, sourceNodeId: 'a', targetNodeId: 'b'),
    }),
    theme: FlowCanvasTheme.dark(),
    defaultEdgeStyle: style,
    // A straight 100px segment: long enough to hold several dashes.
    precomputedPaths: {
      id: Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0),
    },
  );
}

FlowEdgeStyle _lineStyle({List<double>? dashPattern}) => FlowEdgeStyle.colored(
      color: const Color(0xFF888888),
      dashPattern: dashPattern,
    );

void main() {
  test('a solid edge draws its line as the full, unbroken path', () {
    final canvas = _RecordingCanvas();
    _painter(_lineStyle()).paint(canvas, const Size(200, 200));
    expect(_inkLength(canvas.paths.first), closeTo(100, 0.001));
  });

  test('a dashed edge draws its line as dashes, not one solid stroke', () {
    final solid = _RecordingCanvas();
    _painter(_lineStyle()).paint(solid, const Size(200, 200));

    final dashed = _RecordingCanvas();
    _painter(_lineStyle(dashPattern: const [10, 5]))
        .paint(dashed, const Size(200, 200));

    // The bug: dashPattern was ignored, so the dashed line drew the full 100px
    // solid path (equal ink to the solid edge). The fix renders only the "on"
    // segments: [10,5] over 100px = 7 dashes = 70px of ink.
    expect(
      _inkLength(dashed.paths.first),
      lessThan(_inkLength(solid.paths.first)),
      reason: 'a dashed line must have gaps, so less ink than the solid line',
    );
    expect(_inkLength(dashed.paths.first), closeTo(70, 0.001));
  });

  group('buildDashedPath', () {
    int segmentCount(Path path) => path.computeMetrics().length;

    test('empty pattern returns the source path unchanged', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      expect(identical(EdgePainter.buildDashedPath(source, const []), source),
          isTrue);
    });

    test('an all-zero pattern has nothing to march, returns source', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      expect(
          identical(
              EdgePainter.buildDashedPath(source, const [0, 0]), source),
          isTrue);
    });

    test('[10,5] over 100px yields 7 dashes totalling 70px of ink', () {
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = EdgePainter.buildDashedPath(source, const [10, 5]);
      // Dashes at 0-10,15-25,30-40,45-55,60-70,75-85,90-100.
      expect(segmentCount(dashed), 7);
      expect(_inkLength(dashed), closeTo(70, 0.001));
    });

    test('an odd-length pattern alternates like SVG (implicitly doubled)', () {
      // [5] means dash 5, gap 5, dash 5, ... over 100px → 10 dashes, 50px ink.
      final source = Path()
        ..moveTo(0, 0)
        ..lineTo(100, 0);
      final dashed = EdgePainter.buildDashedPath(source, const [5]);
      expect(segmentCount(dashed), 10);
      expect(_inkLength(dashed), closeTo(50, 0.001));
    });
  });
}
