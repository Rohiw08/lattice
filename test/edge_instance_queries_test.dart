import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Parity tests for edge instance queries (`getConnectedEdges`,
/// `useHandleConnections`) and edge-by-id mutation (`getEdge`,
/// `removeEdge(s)`).
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
              FlowNode<String>(
                id: 'c',
                type: 'output',
                position: Offset(320, 300),
                data: 'C',
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
              FlowEdge(
                id: 'e2',
                sourceNodeId: 'a',
                targetNodeId: 'c',
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
  group('edge queries', () {
    testWidgets('getEdge / getConnectedEdges / getHandleConnections',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      expect(controller.edges.getEdge('e1')?.targetNodeId, 'b');
      expect(controller.edges.getEdge('missing'), isNull);

      final fromA =
          controller.edges.getConnectedEdges(['a']).map((e) => e.id);
      expect(fromA, containsAll(['e1', 'e2']));
      expect(
        controller.edges.getConnectedEdges(['b']).map((e) => e.id),
        ['e1'],
      );

      final onSource =
          controller.edges.getHandleConnections('a', 'source').map((e) => e.id);
      expect(onSource, containsAll(['e1', 'e2']));
      expect(
        controller.edges.getHandleConnections('b', 'target').map((e) => e.id),
        ['e1'],
      );
      expect(
        controller.edges.getHandleConnections('b', 'source'),
        isEmpty,
      );

      expect(
        controller.edges.getConnectedNodeIds('a'),
        containsAll(['b', 'c']),
      );
      expect(controller.edges.isNodeConnected('a'), isTrue);
      expect(controller.edges.isNodeConnected('nope'), isFalse);
      expect(controller.edges.isHandleConnected('a', 'source'), isTrue);
      expect(controller.edges.isHandleConnected('a', 'target'), isFalse);
    });
  });

  group('removeEdge(s)', () {
    testWidgets('removes by id, cleans selection, single undo restores',
        (tester) async {
      final controller = FlowCanvasController();
      final removed = <String>[];
      await _pump(
        tester,
        controller: controller,
        callbacks: FlowCanvasCallbacks(
          onEdgesChange: (changes) {
            for (final c in changes) {
              if (c is EdgeRemoveChange) removed.add(c.id);
            }
          },
        ),
      );
      await tester.pump();

      controller.selection.selectEdge('e1');
      await tester.pump();
      expect(controller.currentState.selectedEdges, contains('e1'));

      controller.edges.removeEdge('e1');
      await tester.pump();

      expect(controller.edges.getEdge('e1'), isNull);
      expect(controller.currentState.selectedEdges, isNot(contains('e1')));
      expect(removed, ['e1']);
      // Index observes no ghosts.
      expect(controller.edges.getHandleConnections('a', 'source').length, 1);
      expect(controller.edges.isHandleConnected('b', 'target'), isFalse);

      controller.history.undo();
      await tester.pump();
      expect(controller.edges.getEdge('e1'), isNotNull);
    });

    testWidgets('removeEdges batch + missing ids are no-ops', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.edges.removeEdges(['e1', 'e2', 'missing']);
      await tester.pump();
      expect(controller.currentState.edges, isEmpty);

      controller.history.undo();
      await tester.pump();
      // One undo step restores the whole batch.
      expect(controller.currentState.edges.length, 2);

      controller.edges.removeEdge('missing');
      await tester.pump();
      expect(controller.currentState.edges.length, 2);
    });

    testWidgets('removeSelectedEdges syncs the spatial index', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.selection.selectEdge('e1');
      await tester.pump();
      controller.edges.removeSelectedEdges();
      await tester.pump();

      expect(controller.edges.getEdge('e1'), isNull);
      expect(
        controller.edges.getHandleConnections('b', 'target'),
        isEmpty,
      );
    });
  });

  group('hitTestEdgeAt', () {
    testWidgets('hits the edge path, misses empty space', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();
      await tester.pump();

      // Sweep the straight a→b corridor in flow coords: the bezier must be
      // hit somewhere along it (same samples + tolerance as tap selection).
      final a = controller.nodes.getNode('a')!;
      final b = controller.nodes.getNode('b')!;
      final from = a.center;
      final to = b.center;
      String? hit;
      for (var t = 0.0; t <= 1.0; t += 0.05) {
        hit = controller.edges.hitTestEdgeAt(
          Offset.lerp(from, to, t)!,
        );
        if (hit != null) break;
      }
      expect(hit, 'e1');

      expect(controller.edges.hitTestEdgeAt(const Offset(5000, 5000)), isNull);
    });
  });
}
