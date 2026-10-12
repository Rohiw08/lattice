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

Future<void> _pumpCanvas(
  WidgetTester tester,
  LatticeController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(home: LatticeCanvas(controller: controller)),
  );
  await tester.pump();
  await tester.pump();
}

LatticeEdgePainter _edgePainter(WidgetTester tester) {
  final List<CustomPaint> paints = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((CustomPaint w) => w.painter is LatticeEdgePainter)
      .toList();
  expect(paints, hasLength(1));
  return paints.single.painter! as LatticeEdgePainter;
}

void main() {
  group('LatticeEdgeLayer', () {
    testWidgets('painter receives only visible edges', (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          _node('a', Offset.zero),
          _node('b', const Offset(300, 0)),
          _node('c', const Offset(600, 0)),
          _node('d', const Offset(5000, 5000)),
          _node('e', const Offset(5300, 5000)),
        ],
        initialEdges: <LatticeEdge>[
          _edge('e1', 'a', 'b'),
          _edge('e2', 'b', 'c'),
          _edge('e3', 'd', 'e'),
        ],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      final LatticeEdgePainter painter = _edgePainter(tester);
      expect(painter.paintedIdsForTest, containsAll(<String>['e1', 'e2']));
      expect(painter.paintedIdsForTest, isNot(contains('e3')));
    });

    testWidgets('moving an unrelated node does not bump paint version',
        (tester) async {
      final LatticeNode a = _node('a', Offset.zero);
      final LatticeNode b = _node('b', const Offset(300, 0));
      final LatticeNode u = _node('u', const Offset(50, 400));
      final controller = LatticeController(
        initialNodes: <LatticeNode>[a, b, u],
        initialEdges: <LatticeEdge>[_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      final int before =
          controller.container.read(latticeEdgePaintVersionProvider);
      controller.setNodes(<LatticeNode>[
        a,
        b,
        u.copyWith(position: const Offset(60, 410)),
      ]);
      await tester.pump();
      await tester.pump();

      final int after =
          controller.container.read(latticeEdgePaintVersionProvider);
      expect(after, equals(before));
    });

    testWidgets('edge with missing endpoint paints nothing and throws nothing',
        (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          _node('a', Offset.zero),
          _node('b', const Offset(300, 0)),
        ],
        initialEdges: <LatticeEdge>[
          _edge('e1', 'a', 'b'),
          _edge('eBad', 'a', 'missing'),
        ],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      expect(tester.takeException(), isNull);
      final LatticeEdgePainter painter = _edgePainter(tester);
      expect(painter.paintedIdsForTest, contains('e1'));
      expect(painter.paintedIdsForTest, isNot(contains('eBad')));
    });
  });
}
