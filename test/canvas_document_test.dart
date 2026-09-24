import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lattice/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

class _ColorData {
  const _ColorData(this.label, this.weight);
  final String label;
  final int weight;
}

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

  group('typed node data serialization', () {
    NodeRegistry buildRegistry() => NodeRegistry()
      ..registerTyped<_ColorData>(
        'color',
        (props) => const SizedBox.shrink(),
        toJson: (d) => {'label': d.label, 'weight': d.weight},
        fromJson: (j) {
          final map = j as Map<String, dynamic>;
          return _ColorData(map['label'] as String, map['weight'] as int);
        },
      );

    Future<FlowCanvasController> pumpTyped(WidgetTester tester) async {
      final controller = FlowCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                controller: controller,
                nodeRegistry: buildRegistry(),
                initialNodes: const [
                  FlowNode<_ColorData>(
                    id: 'c',
                    type: 'color',
                    position: Offset(40, 60),
                    data: _ColorData('teal', 7),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return controller;
    }

    testWidgets('saveDocument output survives jsonEncode with typed data',
        (tester) async {
      final controller = await pumpTyped(tester);

      final doc = controller.saveDocument();
      // The bug: identity encoding left the sealed/custom object in the map,
      // so jsonEncode threw. With a registered codec it must not.
      final encoded = jsonEncode(doc);
      expect(encoded, contains('"label":"teal"'));
      expect(encoded, contains('"weight":7'));
    });

    testWidgets('loadDocument rehydrates typed data through a full JSON trip',
        (tester) async {
      final controller = await pumpTyped(tester);

      // Round-trip through a real JSON string, then mutate and restore.
      final saved =
          jsonDecode(jsonEncode(controller.saveDocument())) as Map<String, dynamic>;
      controller.nodes.updateNodeData('c', const _ColorData('changed', 0));
      await tester.pump();

      controller.loadDocument(saved);
      await tester.pump();

      final data = controller.currentState.nodes['c']?.data;
      expect(data, isA<_ColorData>());
      expect((data as _ColorData).label, 'teal');
      expect(data.weight, 7);
      expect(controller.currentState.nodes['c']?.position, const Offset(40, 60));
    });
  });
}
