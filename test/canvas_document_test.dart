import 'package:flutter/material.dart';
import 'package:lattice/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CanvasDocument round-trip preserves nodes', () {
    final state = FlowCanvasState.initial().copyWith(
      nodes: {
        'a': FlowNode.create(
          id: 'a',
          type: 'default',
          position: const Offset(12, 34),
          data: const {},
        ),
      },
    );
    final doc = CanvasDocument.fromState(state);
    final json = doc.toJson();
    final decoded = CanvasDocument.fromJson(json);

    expect(decoded.version, CanvasDocument.currentVersion);
    expect(decoded.state.nodes['a']?.position, const Offset(12, 34));
  });

  group('controller saveDocument / loadDocument', () {
    Future<void> pump(WidgetTester tester, FlowCanvasController controller) {
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
                    type: 'default',
                    position: Offset(80, 120),
                    data: 'A',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('saveDocument emits a versioned envelope', (tester) async {
      final controller = FlowCanvasController();
      await pump(tester, controller);
      await tester.pump();

      final doc = controller.saveDocument();
      expect(doc['v'], CanvasDocument.currentVersion);
      expect(doc['state'], isA<Map<String, dynamic>>());
    });

    testWidgets('loadDocument restores a saved graph, discarding later edits',
        (tester) async {
      final controller = FlowCanvasController();
      await pump(tester, controller);
      await tester.pump();

      // Save the single-node graph, then mutate.
      final saved = controller.saveDocument();
      controller.nodes.addNode(
        FlowNode.create(
          id: 'b',
          type: 'default',
          position: const Offset(300, 300),
          data: const {},
        ),
      );
      await tester.pump();
      expect(controller.currentState.nodes.keys, containsAll(['a', 'b']));

      // Restoring the document rolls back to exactly what was saved.
      controller.loadDocument(saved);
      await tester.pump();
      expect(controller.currentState.nodes.keys, ['a']);
      expect(
          controller.currentState.nodes['a']?.position, const Offset(80, 120));
    });
  });
}
