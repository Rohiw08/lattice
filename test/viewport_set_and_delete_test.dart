import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Parity tests for `setViewport` and `deleteElements`.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  FlowCanvasCallbacks callbacks = const FlowCanvasCallbacks(),
}) {
  return tester.pumpWidget(
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
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('setViewport', () {
    testWidgets('replaces offset+zoom, clamps zoom, transient (no history)',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset(100, 50), zoom: 2.0),
      );
      await tester.pump();
      expect(controller.currentState.viewport.offset, const Offset(100, 50));
      expect(controller.currentState.viewport.zoom, 2.0);

      // Zoom clamps to options instead of exploding the camera.
      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 1000),
      );
      await tester.pump();
      expect(controller.currentState.viewport.zoom, lessThan(1000));
      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.0001),
      );
      await tester.pump();
      expect(controller.currentState.viewport.zoom, greaterThan(0));

      // Transient: undo skips the viewport write.
      controller.nodes.addNode(
        const FlowNode<String>(
          id: 'z',
          type: 'default',
          position: Offset(500, 400),
          data: 'Z',
        ),
      );
      await tester.pump();
      controller.viewport.setViewport(
        const FlowViewport(offset: Offset(7, 7), zoom: 1.0),
      );
      await tester.pump();
      controller.history.undo();
      await tester.pump();
      expect(controller.nodes.getNode('z'), isNull);
    });

    testWidgets('locked canvas ignores setViewport', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.toggleLock();
      controller.viewport.setViewport(
        const FlowViewport(offset: Offset(100, 50), zoom: 2.0),
      );
      await tester.pump();
      expect(
        controller.currentState.viewport,
        isNot(
          const FlowViewport(offset: Offset(100, 50), zoom: 2.0),
        ),
      );
    });

    testWidgets('centerOnPosition centers, optional zoom (setCenter parity)',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.centerOnPosition(const Offset(200, 100));
      await tester.pump();
      final size = controller.currentState.viewportSize!;
      // Centered: flow point maps to the middle of the viewport.
      expect(
        controller.viewport.flowToViewport(const Offset(200, 100)),
        offsetMoreOrLessEquals(
          Offset(size.width / 2, size.height / 2),
        ),
      );

      controller.viewport.centerOnPosition(
        const Offset(200, 100),
        zoom: 2.0,
      );
      await tester.pump();
      expect(controller.currentState.viewport.zoom, 2.0);
      expect(
        controller.viewport.flowToViewport(const Offset(200, 100)),
        offsetMoreOrLessEquals(
          Offset(size.width / 2, size.height / 2),
        ),
      );

      // Zoom clamps like setViewport.
      controller.viewport.centerOnPosition(
        const Offset(200, 100),
        zoom: 1000,
      );
      await tester.pump();
      expect(controller.currentState.viewport.zoom, lessThan(1000));
    });
  });

  group('deleteElements', () {
    testWidgets('nodes cascade, edges pruned, single undo restores',
        (tester) async {
      final controller = FlowCanvasController();
      final nodeChanges = <NodeChange>[];
      final edgeChanges = <EdgeChange>[];
      await _pump(
        tester,
        controller: controller,
        callbacks: FlowCanvasCallbacks(
          onNodesChange: nodeChanges.addAll,
          onEdgesChange: edgeChanges.addAll,
        ),
      );
      await tester.pump();

      controller.deleteElements(nodeIds: const ['a'], edgeIds: const []);
      await tester.pump();

      // `a` and its edges are gone; callbacks fired once each.
      expect(controller.nodes.getNode('a'), isNull);
      expect(controller.nodes.getNode('b'), isNotNull);
      expect(controller.currentState.edges, isEmpty);
      expect(
        nodeChanges.whereType<NodeRemoveChange>().map((c) => c.id),
        contains('a'),
      );
      expect(
        edgeChanges.whereType<EdgeRemoveChange>().map((c) => c.id),
        contains('e1'),
      );

      // Single undo step restores nodes AND edges together.
      controller.history.undo();
      await tester.pump();
      expect(controller.nodes.getNode('a'), isNotNull);
      expect(controller.edges.getEdge('e1'), isNotNull);
    });

    testWidgets('explicit edge ids; deletable:false respected',
        (tester) async {
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
                initialNodes: const [
                  FlowNode<String>(
                    id: 'keep',
                    type: 'default',
                    position: Offset(80, 120),
                    data: 'keep',
                    deletable: false,
                  ),
                  FlowNode<String>(
                    id: 'x',
                    type: 'default',
                    position: Offset(320, 120),
                    data: 'X',
                  ),
                ],
                initialEdges: const [
                  FlowEdge(
                    id: 'locked_edge',
                    sourceNodeId: 'keep',
                    targetNodeId: 'x',
                    deletable: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Non-deletable node survives; non-deletable edge survives explicit id.
      controller.deleteElements(
        nodeIds: const ['keep'],
        edgeIds: const ['locked_edge'],
      );
      await tester.pump();
      expect(controller.nodes.getNode('keep'), isNotNull);
      expect(controller.edges.getEdge('locked_edge'), isNotNull);

      // Empty call is a no-op (no crash, no history entry).
      controller.deleteElements();
      await tester.pump();
      controller.history.undo();
      await tester.pump();
      expect(controller.nodes.getNode('keep'), isNotNull);
    });
  });
}
