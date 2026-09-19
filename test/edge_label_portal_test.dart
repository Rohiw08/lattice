// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Edge-label portal parity (React Flow `<EdgeLabelRenderer>`):
///
/// [FlowEdge.overlayLabel] renders in a screen-space overlay at the path
/// midpoint — constant size, interactive — while [FlowEdge.label] stays a
/// canvas-space presentation badge.

class _DeleteButton extends StatelessWidget {
  const _DeleteButton({required this.controller, required this.edgeId});

  final FlowCanvasController controller;
  final String edgeId;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      key: Key('delete-$edgeId'),
      onPressed: () => controller.edges.removeEdge(edgeId),
      child: const Text('x'),
    );
  }
}

Future<FlowCanvasController> _pump(WidgetTester tester) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          overlays: const [FlowEdgeLabelPortal()],
          initialState: FlowCanvasState.initial().copyWith(
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
              'e1': FlowEdge(
                id: 'e1',
                sourceNodeId: 'a',
                targetNodeId: 'b',
                sourceHandleId: 'source',
                targetHandleId: 'target',
                overlayLabel: _DeleteButton(
                  controller: controller,
                  edgeId: 'e1',
                ),
              ),
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('portal label sits at the path midpoint', (tester) async {
    await _pump(tester);

    expect(find.byKey(Key('delete-e1')), findsOneWidget);
    final labelCenter = tester.getCenter(find.byKey(Key('delete-e1')));
    // Nodes at flow x 100..260 and 500..660 (origin centered on 800x600, so
    // screen x is +400): the horizontal edge midpoint is ~flow x 380.
    final aRight = tester.getTopRight(find.byKey(ValueKey('middle_a'))).dx;
    final bLeft = tester.getTopLeft(find.byKey(ValueKey('middle_b'))).dx;
    expect(labelCenter.dx, greaterThan(aRight));
    expect(labelCenter.dx, lessThan(bLeft));
  });

  testWidgets('portal label button is interactive', (tester) async {
    final controller = await _pump(tester);

    await tester.tap(find.byKey(Key('delete-e1')));
    await tester.pump();

    expect(controller.currentState.edges.containsKey('e1'), isFalse);
    expect(find.byKey(Key('delete-e1')), findsNothing);
  });

  testWidgets('portal lets empty areas fall through to the canvas',
      (tester) async {
    final controller = await _pump(tester);

    controller.selection.selectNode('a');
    await tester.pump();
    expect(controller.currentState.selectedNodes, contains('a'));

    // Top-left corner is empty canvas (labels sit mid-edge).
    await tester.tapAt(const Offset(10, 10));
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty,
        reason: 'overlay must not swallow pointers outside labels');
  });

  testWidgets('no portal overlay means no overlay labels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            initialState: FlowCanvasState.initial().copyWith(
              nodes: {
                'a': FlowNode<String>(
                  type: 'default',
                  id: 'a',
                  position: const Offset(100, 250),
                  data: 'A',
                ),
              },
              edges: const {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(FlowEdgeLabelPortal), findsNothing);
  });
}
