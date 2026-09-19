// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Toolbar parity (React Flow `<NodeToolbar />` / `<EdgeToolbar />`):
///
/// overlays that track their element through pan/zoom/drag at a constant
/// screen size. Visibility follows selection unless pinned with [isVisible].

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  bool? nodeVisible,
  bool? edgeVisible,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          overlays: [
            FlowNodeToolbar(
              nodeId: 'a',
              isVisible: nodeVisible,
              child: Text('node-tb', key: Key('node-tb')),
            ),
            FlowEdgeToolbar(
              edgeId: 'e1',
              isVisible: edgeVisible,
              child: Text('edge-tb', key: Key('edge-tb')),
            ),
          ],
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {
              'a': FlowNode<String>(
                type: 'default',
                id: 'a',
                position: const Offset(100, 100),
                size: const Size(160, 44),
                data: 'A',
              ),
              'b': FlowNode<String>(
                type: 'default',
                id: 'b',
                position: const Offset(400, 100),
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
  testWidgets('node toolbar follows selection and sits above the node',
      (tester) async {
    final controller = await _pump(tester);

    expect(find.byKey(Key('node-tb')), findsNothing,
        reason: 'hidden while the node is unselected');

    controller.selection.selectNode('a');
    await tester.pump();

    expect(find.byKey(Key('node-tb')), findsOneWidget);
    final tbTop = tester.getTopLeft(find.byKey(Key('node-tb'))).dy;
    final nodeTop =
        tester.getTopLeft(find.byKey(ValueKey('middle_a'))).dy;
    expect(tbTop, lessThan(nodeTop),
        reason: 'default top toolbar must sit above the node edge');
  });

  testWidgets('node toolbar isVisible pins visibility', (tester) async {
    final controller = await _pump(tester, nodeVisible: false);

    controller.selection.selectNode('a');
    await tester.pump();

    expect(find.byKey(Key('node-tb')), findsNothing,
        reason: 'explicit false hides even when selected');
  });

  testWidgets('node toolbar isVisible true shows without selection',
      (tester) async {
    await _pump(tester, nodeVisible: true);
    expect(find.byKey(Key('node-tb')), findsOneWidget);
  });

  testWidgets('edge toolbar follows edge selection at the path middle',
      (tester) async {
    final controller = await _pump(tester);

    expect(find.byKey(Key('edge-tb')), findsNothing);

    controller.selection.selectEdge('e1');
    await tester.pump();

    expect(find.byKey(Key('edge-tb')), findsOneWidget);
    final tbCenter = tester.getCenter(find.byKey(Key('edge-tb')));
    final aRight =
        tester.getTopRight(find.byKey(ValueKey('middle_a'))).dx;
    final bLeft = tester.getTopLeft(find.byKey(ValueKey('middle_b'))).dx;
    expect(tbCenter.dx, greaterThan(aRight - 1));
    expect(tbCenter.dx, lessThan(bLeft + 1));
  });
}
