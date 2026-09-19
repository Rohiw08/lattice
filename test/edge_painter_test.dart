import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/presentation/painter/edge_painter.dart';

/// Repaint contract for [EdgePainter]: a rebuilt painter must skip painting
/// when nothing it draws changed, and must repaint when its own edges did.
/// Layer builders hand it fresh map instances every build, so identity of the
/// edge map alone must not force a repaint.
EdgePainter _painter({
  required Map<String, FlowEdge> edges,
  Map<String, int>? versions,
  int geometryEpoch = 7,
  int liveStamp = 0,
  FlowCanvasTheme? theme,
}) {
  return EdgePainter(
    edges: edges,
    theme: theme ?? FlowCanvasTheme.dark(),
    defaultEdgeStyle: FlowEdgeStyle.colored(color: const Color(0xFF888888)),
    precomputedPaths: const {},
    versions: versions,
    geometryEpoch: geometryEpoch,
    liveStamp: liveStamp,
  );
}

Map<String, FlowEdge> _edges() => Map<String, FlowEdge>.of(const {
      'e1': FlowEdge(
        id: 'e1',
        sourceNodeId: 'a',
        targetNodeId: 'b',
      ),
      'e2': FlowEdge(
        id: 'e2',
        sourceNodeId: 'a',
        targetNodeId: 'c',
      ),
    });

void main() {
  test('skips repaint on rebuild with equal keys and unchanged versions',
      () {
    final theme = FlowCanvasTheme.dark();
    final oldPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      theme: theme,
    );
    // Fresh map instances, unrelated geometry epoch bump elsewhere.
    final newPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      geometryEpoch: 8,
      theme: theme,
    );
    expect(newPainter.shouldRepaint(oldPainter), isFalse);
  });

  test('repaints when one of its own edges versions bumps', () {
    final theme = FlowCanvasTheme.dark();
    final oldPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      theme: theme,
    );
    final newPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 2, 'e2': 1},
      geometryEpoch: 8,
      theme: theme,
    );
    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });

  test('repaints when the edge set changes', () {
    final theme = FlowCanvasTheme.dark();
    final oldPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      theme: theme,
    );
    final remaining = _edges()..remove('e2');
    final newPainter = _painter(
      edges: remaining,
      versions: const {'e1': 1},
      theme: theme,
    );
    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });

  test('repaints on live stamp ticks', () {
    final theme = FlowCanvasTheme.dark();
    final oldPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      theme: theme,
    );
    final newPainter = _painter(
      edges: _edges(),
      versions: const {'e1': 1, 'e2': 1},
      liveStamp: 1,
      theme: theme,
    );
    expect(newPainter.shouldRepaint(oldPainter), isTrue);
  });

  test('falls back to epoch when versions are unavailable', () {
    final theme = FlowCanvasTheme.dark();
    final oldPainter = _painter(edges: _edges(), theme: theme);
    // Same epoch: key-set equality alone is enough to skip.
    expect(_painter(edges: _edges(), theme: theme).shouldRepaint(oldPainter),
        isFalse);
    // Bumped epoch with no versions to compare: repaint.
    expect(
        _painter(edges: _edges(), geometryEpoch: 8, theme: theme)
            .shouldRepaint(oldPainter),
        isTrue);
  });
}
