import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, Offset position) {
  return LatticeNode(id: id, type: 'default', position: position);
}

LatticeEdge _edge(String id, String source, String target) {
  return LatticeEdge(
    id: id,
    source: LatticeEndpoint(nodeId: source),
    target: LatticeEndpoint(nodeId: target),
  );
}

Map<String, LatticeEdgeLabelBuilder> _labels() {
  return <String, LatticeEdgeLabelBuilder>{
    'default': (BuildContext context, LatticeEdge edge) =>
        Text('label-${edge.id}'),
  };
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  LatticeController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeCanvas(controller: controller, labelBuilders: _labels()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Positioned _labelPosition(WidgetTester tester, String text) {
  return tester.widget<Positioned>(
    find.ancestor(of: find.text(text), matching: find.byType(Positioned)),
  );
}

void main() {
  group('LatticeEdgeLabelLayer', () {
    testWidgets('labeled visible edge shows its label text', (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          _node('a', Offset.zero),
          _node('b', const Offset(300, 0)),
        ],
        initialEdges: <LatticeEdge>[_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      expect(find.text('label-e1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('off-screen labeled edge mounts nothing', (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          _node('a', Offset.zero),
          _node('b', const Offset(300, 0)),
          _node('d', const Offset(5000, 5000)),
          _node('e', const Offset(5300, 5000)),
        ],
        initialEdges: <LatticeEdge>[
          _edge('e1', 'a', 'b'),
          _edge('e3', 'd', 'e'),
        ],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      expect(find.text('label-e1'), findsOneWidget);
      expect(find.text('label-e3'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('moving an endpoint moves the label', (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          _node('a', Offset.zero),
          _node('b', const Offset(300, 0)),
        ],
        initialEdges: <LatticeEdge>[_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      // Default ports: a.centerRight (160,22), b.centerLeft (300,22).
      final Positioned before = _labelPosition(tester, 'label-e1');
      expect(before.left, equals(230.0));
      expect(before.top, equals(22.0));

      controller.moveNodes(<String, Offset>{'b': const Offset(500, 0)});
      await tester.pump();
      await tester.pump();

      final Positioned after = _labelPosition(tester, 'label-e1');
      expect(find.text('label-e1'), findsOneWidget);
      expect(after.left, equals(330.0));
      expect(after.top, equals(22.0));
      expect(tester.takeException(), isNull);
    });
  });
}
