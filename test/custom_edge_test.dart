// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';

/// Custom-edge parity (React Flow custom edges):
///
/// [EdgeTypeConfig.pathBuilder] replaces the path computation (bounds,
/// hit-testing, labels, and markers derive from it automatically) and
/// [EdgeTypeConfig.foregroundPainter] paints canvas-space decorations over
/// the base stroke. Widget content belongs in [FlowEdge.overlayLabel].

Path _archBuilder(FlowEdgePathInput input) {
  final path = Path()
    ..moveTo(input.source.dx, input.source.dy);
  final mid = (input.source + input.target) / 2;
  path.quadraticBezierTo(mid.dx, mid.dy - 120, input.target.dx,
      input.target.dy);
  return path;
}

FlowCanvasState _graph({FlowEdge? edge}) {
  return FlowCanvasState.initial().copyWith(
    nodes: {
      'a': FlowNode<String>(
        type: 'default',
        id: 'a',
        position: const Offset(100, 250),
        size: const Size(160, 44),
        data: 'A',
      ),
      'b': FlowNode<String>(
        type: 'default',
        id: 'b',
        position: const Offset(500, 250),
        size: const Size(160, 44),
        data: 'B',
      ),
    },
    edges: {
      'e1': edge ??
          FlowEdge(
            id: 'e1',
            sourceNodeId: 'a',
            targetNodeId: 'b',
            sourceHandleId: 'source',
            targetHandleId: 'target',
          ),
    },
  );
}

void main() {
  test('registry presets copy builders onto created edges', () {
    final registry = EdgeRegistry()
      ..register('arch', EdgeTypeConfig(pathBuilder: _archBuilder));
    final edge = registry.createEdge(
      id: 'e1',
      sourceNodeId: 'a',
      targetNodeId: 'b',
      type: 'arch',
    );
    expect(edge.pathBuilder, same(_archBuilder));
    expect(registry.getConfig('missing').pathBuilder, isNull);
  });

  test('custom path drives geometry (bounds/hit-test/labels/markers)', () {
    final service = EdgeGeometryService();
    final state = _graph(
      edge: FlowEdge(
        id: 'e1',
        sourceNodeId: 'a',
        targetNodeId: 'b',
        sourceHandleId: 'source',
        targetHandleId: 'target',
        pathBuilder: _archBuilder,
      ),
    );
    service.updateCache(state, ['e1']);
    final geom = service.getGeom('e1');
    expect(geom, isNotNull);
    // Straight chord sits at y ~272; the arch humps 120px up.
    expect(geom!.bounds.top, lessThan(200.0));
    expect(geom.samples, isNotEmpty);
    expect(geom.markers, isNotNull);
  });

  testWidgets('foreground painter runs over the base stroke', (tester) async {
    var painted = false;
    var sawSelected = false;
    final controller = FlowCanvasController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            initialState: _graph(
              edge: FlowEdge(
                id: 'e1',
                sourceNodeId: 'a',
                targetNodeId: 'b',
                sourceHandleId: 'source',
                targetHandleId: 'target',
                pathBuilder: _archBuilder,
                foregroundPainter: (canvas, ctx) {
                  painted = true;
                  sawSelected = ctx.selected;
                  expect(ctx.path, isNotNull);
                  expect(ctx.edge.id, 'e1');
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(painted, isTrue,
        reason: 'custom foreground must paint with the edge');
    expect(sawSelected, isFalse);

    controller.selection.selectEdge('e1');
    await tester.pump();
    expect(sawSelected, isTrue,
        reason: 'painter context must report selection');
  });
}
