import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Parity tests for the instance/query APIs:
/// `getIntersectingNodes` / `isNodeIntersecting`.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  List<FlowNode<Object>> nodes = const [],
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
            initialNodes: nodes,
          ),
        ),
      ),
    ),
  );
}

List<FlowNode<Object>> _fixture() => <FlowNode<Object>>[
      const FlowNode<String>(
        id: 'box',
        type: 'default',
        position: Offset(0, 0),
        size: Size(400, 400),
        data: 'box',
      ),
      const FlowNode<String>(
        id: 'inside',
        type: 'default',
        position: Offset(50, 50),
        size: Size(100, 100),
        data: 'inside',
      ),
      const FlowNode<String>(
        id: 'overlap',
        type: 'default',
        position: Offset(350, 350),
        size: Size(100, 100),
        data: 'overlap',
      ),
      const FlowNode<String>(
        id: 'far',
        type: 'default',
        position: Offset(600, 600),
        size: Size(100, 100),
        data: 'far',
      ),
      const FlowNode<String>(
        id: 'ghost',
        type: 'default',
        position: Offset(60, 60),
        size: Size(80, 80),
        data: 'ghost',
        hidden: true,
      ),
    ];

void main() {
  group('getIntersectingNodes', () {
    testWidgets('partial matches any overlap; full requires containment',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, nodes: _fixture());
      await tester.pump();

      final partial =
          controller.nodes.getIntersectingNodes('box').map((n) => n.id);
      expect(partial, containsAll(['inside', 'overlap']));
      expect(partial, isNot(contains('far')));

      final full = controller.nodes
          .getIntersectingNodes('box', partially: false)
          .map((n) => n.id);
      expect(full, contains('inside'));
      expect(full, isNot(contains('overlap')));
      expect(full, isNot(contains('far')));
    });

    testWidgets('hidden nodes are skipped; results sorted by id',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, nodes: _fixture());
      await tester.pump();

      final ids = controller.nodes
          .getIntersectingNodes('box')
          .map((n) => n.id)
          .toList();
      expect(ids, isNot(contains('ghost')));
      expect(ids, orderedEquals([...ids]..sort()));
    });

    testWidgets('missing id returns empty', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, nodes: _fixture());
      await tester.pump();

      expect(controller.nodes.getIntersectingNodes('nope'), isEmpty);
    });
  });

  group('isNodeIntersecting', () {
    testWidgets('overlap true, disjoint and missing false', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, nodes: _fixture());
      await tester.pump();

      expect(controller.nodes.isNodeIntersecting('box', 'overlap'), isTrue);
      expect(controller.nodes.isNodeIntersecting('box', 'far'), isFalse);
      expect(controller.nodes.isNodeIntersecting('box', 'nope'), isFalse);
    });
  });

  group('flowStateProvider', () {
    testWidgets('arbitrary slices rebuild (useStore parity)', (tester) async {
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
                initialNodes: _fixture(),
                overlays: [
                  Consumer(
                    builder: (context, ref, _) {
                      final count = ref.watch(
                        flowStateProvider.select((s) => s.nodes.length),
                      );
                      final mode = ref.watch(
                        flowStateProvider.select((s) => s.dragMode),
                      );
                      return Text(
                        'nodes:$count mode:${mode.name}',
                        key: const ValueKey('store'),
                        textDirection: TextDirection.ltr,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('nodes:5 mode:none'), findsOneWidget);
      controller.nodes.addNode(
        const FlowNode<String>(
          id: 'extra',
          type: 'default',
          position: Offset(10, 500),
          data: 'extra',
        ),
      );
      await tester.pump();

      expect(find.text('nodes:6 mode:none'), findsOneWidget);
    });
  });
}
