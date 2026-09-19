import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  List<Widget> overlays = const [],
  FlowCanvasCallbacks callbacks = const FlowCanvasCallbacks(),
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            callbacks: callbacks,
            initialNodes: const [
              FlowNode<String>(
                id: 'a',
                type: 'input',
                position: Offset(80, 120),
                data: 'A',
              ),
              FlowNode<String>(
                id: 'b',
                type: 'output',
                position: Offset(320, 120),
                data: 'B',
              ),
            ],
            initialEdges: const [
              FlowEdge(
                id: 'e1',
                sourceNodeId: 'a',
                targetNodeId: 'b',
                sourceHandleId: 'source',
                targetHandleId: 'target',
              ),
            ],
            overlays: overlays,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  group('FlowViewportPortal', () {
    testWidgets('pins content to flow coordinates', (tester) async {
      const anchor = Offset(200, 150);
      final controller = await _pump(
        tester,
        overlays: const [
          FlowViewportPortal(
            position: anchor,
            child: SizedBox(
              key: ValueKey('portal-child'),
              width: 20,
              height: 20,
            ),
          ),
        ],
      );

      final expected = controller.viewport.flowToViewport(anchor);
      final actual = tester.getTopLeft(find.byKey(const ValueKey('portal-child')));
      expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 1));
      expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 1));
    });

    testWidgets('tracks pan and zoom', (tester) async {
      const anchor = Offset(200, 150);
      final controller = await _pump(
        tester,
        overlays: const [
          FlowViewportPortal(
            position: anchor,
            child: SizedBox(
              key: ValueKey('portal-child'),
              width: 20,
              height: 20,
            ),
          ),
        ],
      );
      final finder = find.byKey(const ValueKey('portal-child'));

      await controller.viewport.centerOnPosition(const Offset(500, 400));
      await tester.pump();
      var expected = controller.viewport.flowToViewport(anchor);
      var actual = tester.getTopLeft(finder);
      expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 1));
      expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 1));

      await controller.viewport.zoomTo(2.0);
      await tester.pump();
      expected = controller.viewport.flowToViewport(anchor);
      actual = tester.getTopLeft(finder);
      expect(actual.dx, moreOrLessEquals(expected.dx, epsilon: 1));
      expect(actual.dy, moreOrLessEquals(expected.dy, epsilon: 1));

      // Content scales with the canvas, like node chrome.
      final scale = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(FlowViewportPortal),
              matching: find.byType(Transform),
            ),
          )
          .map((t) => t.transform.getMaxScaleOnAxis())
          .firstWhere(
            (s) => (s - 2.0).abs() < 0.01,
            orElse: () => -1,
          );
      expect(scale, 2.0);
    });
  });

  group('sync payload (toSyncJson)', () {
    testWidgets('strips selection, keeps the graph', (tester) async {
      final controller = await _pump(tester);
      controller.selection.selectNode('a');
      await tester.pump();

      final full = controller.toJson();
      expect(full['selectedNodes'], contains('a'));

      final sync = controller.toSyncJson();
      expect(sync['selectedNodes'], isEmpty);
      expect(sync['selectedEdges'], isEmpty);
      expect((sync['nodes'] as Map).keys, containsAll(['a', 'b']));
      expect((sync['edges'] as Map).keys, contains('e1'));

      // Decodable, selection defaults to empty.
      final decoded = FlowCanvasState.fromJson(sync);
      expect(decoded.selectedNodes, isEmpty);
      expect(decoded.nodes.keys, containsAll(['a', 'b']));
    });
  });

  group('applyRemote', () {
    testWidgets(
        'replaces graph, preserves selection+viewport+history, stays silent',
        (tester) async {
      final nodeChanges = <NodeChange>[];
      final edgeChanges = <EdgeChange>[];
      final controller = await _pump(
        tester,
        callbacks: FlowCanvasCallbacks(
          onNodesChange: nodeChanges.addAll,
          onEdgesChange: edgeChanges.addAll,
        ),
      );

      // Local op (history) + local selection + note the viewport.
      controller.nodes.addNode(const FlowNode<String>(
        id: 'local',
        type: 'default',
        position: Offset(500, 400),
        data: 'L',
      ));
      controller.selection.selectNode('a');
      await tester.pump();
      final viewportBefore = controller.currentState.viewport;
      nodeChanges.clear();
      edgeChanges.clear();

      // Remote peer state: everything plus a remote-only node.
      final remote = controller.currentState.copyWith(
        nodes: {
          ...controller.currentState.nodes,
          'remote': const FlowNode<String>(
            id: 'remote',
            type: 'default',
            position: Offset(700, 100),
            data: 'R',
          ),
        },
        // A hostile/mistaken peer selection must not leak through.
        selectedNodes: {'b'},
      );
      controller.applyRemote(remote);
      await tester.pump();

      // Graph replaced …
      expect(controller.nodes.getNode('remote')?.data, 'R');
      expect(controller.nodes.getNode('local')?.data, 'L');
      // … local UI state untouched …
      expect(controller.currentState.selectedNodes, {'a'});
      expect(controller.currentState.viewport, viewportBefore);
      // … and no change callbacks (no sync echo loop).
      expect(nodeChanges, isEmpty);
      expect(edgeChanges, isEmpty);

      // Undo still undoes MY op, not the remote one.
      controller.history.undo();
      await tester.pump();
      expect(controller.nodes.getNode('local'), isNull);
      expect(controller.nodes.getNode('remote')?.data, 'R');

      // Redo is coherent too: my op returns on top of the shared graph.
      controller.history.redo();
      await tester.pump();
      expect(controller.nodes.getNode('local')?.data, 'L');
      expect(controller.nodes.getNode('remote')?.data, 'R');
    });
  });
}
