import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Parity tests for `updateNodeInternals`: derived-cache refresh without
/// model or history changes.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
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
  testWidgets('missing id is a safe no-op', (tester) async {
    final controller = FlowCanvasController();
    await _pump(tester, controller: controller);
    await tester.pump();

    final before = controller.currentState;
    controller.nodes.updateNodeInternals('nope');
    await tester.pump();

    // NOTE: Freezed wraps `nodes` in a fresh unmodifiable view per access,
    // so compare state identity (no write happened at all).
    expect(identical(controller.currentState, before), isTrue);
  });

  testWidgets('refreshes caches, keeps model, adds no undo step',
      (tester) async {
    final controller = FlowCanvasController();
    await _pump(tester, controller: controller);
    await tester.pump();

    final revision = controller.currentState.geometryRevision;
    final before = controller.currentState;
    controller.nodes.updateNodeInternals('a');
    await tester.pump();

    // Model contents equal (transient revision touch only), revision
    // bumped so edge painters repaint.
    expect(
      controller.currentState.nodes,
      equals(before.nodes),
    );
    expect(controller.nodes.getNode('a')?.position, const Offset(80, 120));
    expect(
      controller.currentState.geometryRevision,
      revision + 1,
    );
    // Queries observe consistent post-refresh state.
    expect(controller.edges.isNodeConnected('a'), isTrue);
    expect(
      controller.edges.getHandleConnections('a', 'source').map((e) => e.id),
      ['e1'],
    );
    expect(
      controller.nodes.isNodeIntersecting('a', 'b'),
      isFalse,
    );

    // No history entry: undo skips straight past the refresh.
    controller.nodes.addNode(
      const FlowNode<String>(
        id: 'z',
        type: 'default',
        position: Offset(500, 400),
        data: 'Z',
      ),
    );
    await tester.pump();
    controller.nodes.updateNodeInternals('z');
    await tester.pump();
    controller.history.undo();
    await tester.pump();
    expect(controller.nodes.getNode('z'), isNull);
  });

  testWidgets('queries stay correct after resize + refresh', (tester) async {
    final controller = FlowCanvasController();
    await _pump(tester, controller: controller);
    await tester.pump();

    // Grow `a` so it overlaps `b`, then refresh derived caches.
    final grown = controller.nodes.getNode('a')!.copyWith(
      size: const Size(400, 200),
    );
    controller.nodes.updateNode(grown);
    await tester.pump();
    controller.nodes.updateNodeInternals('a');
    await tester.pump();

    expect(controller.nodes.isNodeIntersecting('a', 'b'), isTrue);
    expect(
      controller.nodes.getIntersectingNodes('a').map((n) => n.id),
      contains('b'),
    );
  });
}
