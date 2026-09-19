import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  required List<FlowCanvasError> errors,
  NodeRegistry? nodeRegistry,
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
            nodeRegistry: nodeRegistry,
            callbacks: FlowCanvasCallbacks(
              onError: errors.add,
            ),
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
  group('onError diagnostics (RF common-errors parity)', () {
    testWidgets('unregistered node type warns, falls back', (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.nodes.addNode(const FlowNode<String>(
        id: 'x',
        type: 'nope',
        position: Offset(10, 10),
        data: 'X',
      ));
      await tester.pump();

      expect(
        errors.map((e) => e.code),
        contains('unregistered-node-type'),
      );
      // Still added (fallback renders it).
      expect(controller.nodes.getNode('x'), isNotNull);
    });

    testWidgets('extent parent without parentId warns', (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.nodes.addNode(const FlowNode<String>(
        id: 'x',
        type: 'default',
        position: Offset(10, 10),
        data: 'X',
        extent: FlowNodeExtent.parent,
      ));
      await tester.pump();

      expect(
        errors.map((e) => e.code),
        contains('extent-without-parent'),
      );
    });

    testWidgets('dangling edge warns and is skipped', (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.nodes.addNode(const FlowNode<String>(
        id: 'a',
        type: 'input',
        position: Offset(10, 10),
        data: 'A',
      ));
      await tester.pump();
      errors.clear();

      controller.edges.addEdge(const FlowEdge(
        id: 'bad',
        sourceNodeId: 'a',
        targetNodeId: 'ghost',
      ));
      await tester.pump();

      expect(
        errors.map((e) => e.code),
        contains('edge-missing-node'),
      );
      expect(controller.edges.getEdge('bad'), isNull);
    });

    testWidgets('bulk add collapses dangling edges into one warning',
        (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.edges.addEdges(const [
        FlowEdge(id: 'bad1', sourceNodeId: 'x', targetNodeId: 'y'),
        FlowEdge(id: 'bad2', sourceNodeId: 'x', targetNodeId: 'y'),
      ]);
      await tester.pump();

      final codes =
          errors.where((e) => e.code == 'edge-missing-node').toList();
      expect(codes, hasLength(1));
      expect(codes.single.message, contains('bad1'));
      expect(codes.single.message, contains('bad2'));
    });

    testWidgets('reconnect of a missing edge warns', (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.edges.reconnectEdge(edgeId: 'ghost');
      await tester.pump();

      expect(
        errors.map((e) => e.code),
        contains('reconnect-missing-edge'),
      );
    });

    testWidgets('recreated registries warn (RF nodeTypes warning)',
        (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = FlowCanvasController();
      Future<void> pumpWith(NodeRegistry registry) {
        return tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: FlowCanvas(
                  controller: controller,
                  theme: FlowCanvasTheme.dark(),
                  nodeRegistry: registry,
                  callbacks: FlowCanvasCallbacks(onError: errors.add),
                ),
              ),
            ),
          ),
        );
      }

      await pumpWith(NodeRegistry());
      await tester.pump();
      expect(errors, isEmpty);

      // Same content, new identity: the classic per-build mistake.
      await pumpWith(NodeRegistry());
      await tester.pump();

      expect(
        errors.map((e) => e.code),
        contains('registries-recreated'),
      );
    });

    testWidgets('healthy flows stay silent', (tester) async {
      final errors = <FlowCanvasError>[];
      final controller = await _pump(tester, errors: errors);

      controller.nodes.addNode(const FlowNode<String>(
        id: 'a',
        type: 'input',
        position: Offset(10, 10),
        data: 'A',
      ));
      controller.nodes.addNode(const FlowNode<String>(
        id: 'b',
        type: 'output',
        position: Offset(200, 10),
        data: 'B',
      ));
      controller.edges.addEdge(const FlowEdge(
        id: 'e1',
        sourceNodeId: 'a',
        targetNodeId: 'b',
        sourceHandleId: 'source',
        targetHandleId: 'target',
      ));
      await tester.pump();

      expect(errors, isEmpty);
    });
  });
}
