import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/presentation/painter/edge_painter.dart';

/// React Flow parity: the canvas theme exposes a single `edgeMarker`, which is
/// the END arrowhead default. An edge with no explicit markers must therefore
/// render an arrowhead only at its TARGET end — never a spurious backward
/// arrowhead at the source (screenshot bug #6a). Explicitly setting
/// `startMarkerStyle` on an edge still draws a start marker.

/// Minimal [Canvas] that records the [Path]s handed to [drawPath]; everything
/// else is a no-op. Markers and the edge line are both drawn via `drawPath`,
/// so the recorded paths let us assert which ends got a marker.
class _RecordingCanvas implements Canvas {
  final List<Path> drawnPaths = [];

  @override
  void drawPath(Path path, Paint paint) => drawnPaths.add(path);

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

EdgePainter _painter(Map<String, FlowEdge> edges, Path path,
    {FlowCanvasTheme? theme}) {
  return EdgePainter(
    edges: edges,
    theme: theme ?? FlowCanvasTheme.dark(),
    defaultEdgeStyle: FlowEdgeStyle.colored(color: const Color(0xFF888888)),
    precomputedPaths: {'e1': path},
  );
}

Path _straightPath() => Path()
  ..moveTo(0, 0)
  ..lineTo(100, 0);

/// Marker paths are freshly allocated; the edge line is the exact object we
/// supplied. Everything drawn that is not that line is a marker.
List<Path> _markerPaths(_RecordingCanvas canvas, Path line) =>
    canvas.drawnPaths.where((p) => !identical(p, line)).toList();

void main() {
  test('handle-less edge draws a marker only at the target end (RF parity)',
      () {
    final line = _straightPath();
    final painter = _painter(
      {'e1': const FlowEdge(id: 'e1', sourceNodeId: 'a', targetNodeId: 'b')},
      line,
    );
    final canvas = _RecordingCanvas();
    painter.paint(canvas, const Size(200, 200));

    final markers = _markerPaths(canvas, line);
    // Exactly one marker (the end arrowhead), positioned at the target (100,0),
    // never at the source (0,0).
    expect(markers.length, 1);
    expect(markers.single.getBounds().center.dx, greaterThan(50));
  });

  test('explicit startMarkerStyle still renders a start marker', () {
    final line = _straightPath();
    final painter = _painter(
      {
        'e1': FlowEdge(
          id: 'e1',
          sourceNodeId: 'a',
          targetNodeId: 'b',
          startMarkerStyle: FlowEdgeMarkerStyle.dark(),
        ),
      },
      line,
    );
    final canvas = _RecordingCanvas();
    painter.paint(canvas, const Size(200, 200));

    final markers = _markerPaths(canvas, line);
    // Start (theme end default) + explicit start marker → both ends drawn.
    expect(markers.length, 2);
    expect(
      markers.any((p) => p.getBounds().center.dx < 50),
      isTrue,
      reason: 'a start marker should be drawn near the source',
    );
  });
}
