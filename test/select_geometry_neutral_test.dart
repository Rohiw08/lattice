// ignore_for_file: prefer_const_constructors
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// `_commitGeometry` skips the O(N+E) edge-geometry scan when the `nodes` and
/// `edges` map references are unchanged (selection/hover/viewport emissions).
/// These guards prove the skip is behaviour-safe: a pure selection change never
/// touches edge geometry, while a real node move still recomputes it.
Future<FlowCanvasController> _pump(WidgetTester tester) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {
              'a': FlowNode<String>(
                  id: 'a',
                  type: 'default',
                  position: Offset(0, 0),
                  size: Size(100, 40),
                  data: 'A'),
              'b': FlowNode<String>(
                  id: 'b',
                  type: 'default',
                  position: Offset(200, 0),
                  size: Size(100, 40),
                  data: 'B'),
            },
            edges: {
              'e1': FlowEdge(id: 'e1', sourceNodeId: 'a', targetNodeId: 'b'),
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  while (tester.binding.hasScheduledFrame) {
    await tester.pump();
  }
  return controller;
}

void main() {
  testWidgets('selecting a node does not bump geometryRevision', (tester) async {
    final c = await _pump(tester);
    final rev0 = c.currentState.geometryRevision;

    c.selection.selectNode('a');
    await tester.pump();

    expect(c.currentState.selectedNodes, contains('a'));
    expect(c.currentState.geometryRevision, rev0,
        reason: 'a pure selection change must not touch edge geometry');
  });

  testWidgets('moving a node still recomputes edge geometry', (tester) async {
    final c = await _pump(tester);
    final rev0 = c.currentState.geometryRevision;

    final moved = c.currentState.nodes['a']!.copyWith(
      position: const Offset(0, 300),
    );
    c.nodes.updateNode(moved);
    await tester.pump();

    expect(c.currentState.nodes['a']!.position, const Offset(0, 300));
    expect(c.currentState.geometryRevision, greaterThan(rev0),
        reason: 'a real node move must recompute connected edge geometry');
  });
}
