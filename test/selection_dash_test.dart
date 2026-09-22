import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/core/theme/components/selection_theme.dart';
import 'package:lattice/src/features/selection/presentation/painters/selection_painter.dart';

/// The selection box now honors the themed `dashLength`/`gapLength` (dashed
/// outline, RF's default dotted look) and `borderRadius` (rounded corners) —
/// all three were previously ignored by the painter.
class _RecordingCanvas implements Canvas {
  final List<RRect> rrects = [];
  final List<Path> paths = [];

  @override
  void drawRRect(RRect rrect, Paint paint) => rrects.add(rrect);

  @override
  void drawPath(Path path, Paint paint) => paths.add(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  const rect = Rect.fromLTWH(0, 0, 100, 100);

  test('default selection border is dashed (one border path, one fill rrect)',
      () {
    final canvas = _RecordingCanvas();
    SelectionRectanglePainter(
      selectionRect: rect,
      style: FlowSelectionStyle.light(), // dashLength 5, gapLength 5
      zoom: 1,
    ).paint(canvas, const Size(100, 100));

    expect(canvas.paths.length, 1, reason: 'dashed border is one composed path');
    expect(canvas.rrects.length, 1, reason: 'only the fill is an RRect');
  });

  test('dashLength 0 renders a solid border (two rrects, no path)', () {
    final canvas = _RecordingCanvas();
    SelectionRectanglePainter(
      selectionRect: rect,
      style: const FlowSelectionStyle(borderColor: Colors.red, dashLength: 0),
      zoom: 1,
    ).paint(canvas, const Size(100, 100));

    expect(canvas.paths, isEmpty);
    expect(canvas.rrects.length, 2, reason: 'fill + solid border');
  });

  test('borderRadius produces rounded corners on the fill', () {
    final canvas = _RecordingCanvas();
    SelectionRectanglePainter(
      selectionRect: rect,
      style: FlowSelectionStyle(
        borderColor: Colors.blue,
        borderRadius: BorderRadius.circular(8),
        dashLength: 0,
      ),
      zoom: 1,
    ).paint(canvas, const Size(100, 100));

    expect(canvas.rrects.first.tlRadiusX, 8);
  });
}
