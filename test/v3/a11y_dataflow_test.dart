import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(
  String id,
  Offset position, {
  Object? data,
  String? semanticsLabel,
  int zIndex = 0,
}) {
  return LatticeNode(
    id: id,
    type: 'custom',
    position: position,
    data: data,
    semanticsLabel: semanticsLabel,
    zIndex: zIndex,
  );
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  LatticeController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(home: LatticeCanvas(controller: controller)),
  );
  // Flush post-frame callbacks (pane-size publish + forced cull refresh).
  await tester.pump();
  await tester.pump();
}

/// Labels of the node-shell [Semantics] widgets in widget-tree order
/// (stack/traversal order), restricted to the seeded node labels.
List<String> _shellLabels(WidgetTester tester) {
  return <String>[
    for (final Semantics semantics
        in tester.widgetList<Semantics>(find.byType(Semantics)))
      if (semantics.properties.label == 'Alpha' ||
          semantics.properties.label == 'Beta')
        semantics.properties.label!,
  ];
}

Semantics _shellByLabel(WidgetTester tester, String label) {
  return tester
      .widgetList<Semantics>(find.byType(Semantics))
      .firstWhere(
        (Semantics semantics) => semantics.properties.label == label,
      );
}

void main() {
  group('node shell semantics', () {
    testWidgets('labels resolve with fallbacks in z/stack order',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [
          // data-as-string fallback; lower zIndex.
          _node('a', Offset.zero, data: 'Alpha'),
          // explicit semanticsLabel wins over data; higher zIndex.
          _node(
            'b',
            const Offset(300, 300),
            data: 'ignored',
            semanticsLabel: 'Beta',
            zIndex: 1,
          ),
        ],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      expect(_shellLabels(tester), equals(<String>['Alpha', 'Beta']));
      expect(tester.takeException(), isNull);
    });

    testWidgets('selected shell flags selected + button', (tester) async {
      final controller = LatticeController(
        initialNodes: [
          _node('a', Offset.zero, data: 'Alpha'),
          _node('b', const Offset(300, 300), semanticsLabel: 'Beta'),
        ],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      controller.select({'b'});
      await tester.pump();

      final Semantics selected = _shellByLabel(tester, 'Beta');
      expect(selected.properties.button, isTrue);
      expect(selected.properties.selected, isTrue);

      final Semantics unselected = _shellByLabel(tester, 'Alpha');
      expect(unselected.properties.button, isTrue);
      expect(unselected.properties.selected, isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('id is the final label fallback', (tester) async {
      final controller = LatticeController(
        initialNodes: [_node('lonely', Offset.zero)],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      final List<String?> labels = <String?>[
        for (final Semantics semantics
            in tester.widgetList<Semantics>(find.byType(Semantics)))
          semantics.properties.label,
      ];
      expect(labels, contains('lonely'));
      expect(tester.takeException(), isNull);
    });
  });

  group('LatticeLiveRegion', () {
    Future<void> pumpLiveRegion(
      WidgetTester tester,
      LatticeController controller,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: UncontrolledProviderScope(
            container: controller.container,
            child: const LatticeLiveRegion(),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('announces selection then clearing', (tester) async {
      LatticeLiveRegion.lastAnnouncedForTest = null;
      final controller = LatticeController(
        initialNodes: [_node('a', Offset.zero)],
      );
      addTearDown(controller.dispose);

      await pumpLiveRegion(tester, controller);
      expect(LatticeLiveRegion.lastAnnouncedForTest, isNull);

      controller.select({'a'});
      await tester.pump();
      expect(LatticeLiveRegion.lastAnnouncedForTest, '1 nodes selected');

      controller.select({'a', 'b'});
      await tester.pump();
      expect(LatticeLiveRegion.lastAnnouncedForTest, '2 nodes selected');

      controller.deselectAll();
      await tester.pump();
      expect(LatticeLiveRegion.lastAnnouncedForTest, 'Selection cleared');
      expect(tester.takeException(), isNull);
    });

    testWidgets('announces edge creation', (tester) async {
      LatticeLiveRegion.lastAnnouncedForTest = null;
      final controller = LatticeController(
        initialNodes: [
          _node('a', Offset.zero),
          _node('b', const Offset(300, 300)),
        ],
      );
      addTearDown(controller.dispose);

      await pumpLiveRegion(tester, controller);
      expect(LatticeLiveRegion.lastAnnouncedForTest, isNull);

      controller.addEdge(
        const LatticeEdge(
          id: 'e1',
          source: LatticeEndpoint(nodeId: 'a'),
          target: LatticeEndpoint(nodeId: 'b'),
        ),
      );
      await tester.pump();
      expect(LatticeLiveRegion.lastAnnouncedForTest, 'Edge created');
      expect(tester.takeException(), isNull);
    });
  });

  group('dataflow providers', () {
    test('connections provider reflects an added edge', () {
      final controller = LatticeController(
        initialNodes: [
          _node('a', Offset.zero),
          _node('b', const Offset(300, 300)),
        ],
      );
      addTearDown(controller.dispose);

      var target =
          controller.container.read(latticeNodeConnectionsProvider('b'));
      expect(target.incoming, isEmpty);
      expect(target.outgoing, isEmpty);

      controller.addEdge(
        const LatticeEdge(
          id: 'e1',
          source: LatticeEndpoint(nodeId: 'a'),
          target: LatticeEndpoint(nodeId: 'b'),
        ),
      );

      target = controller.container.read(latticeNodeConnectionsProvider('b'));
      expect(target.incoming, equals(<String>{'e1'}));
      expect(target.outgoing, isEmpty);

      final source =
          controller.container.read(latticeNodeConnectionsProvider('a'));
      expect(source.outgoing, equals(<String>{'e1'}));
      expect(source.incoming, isEmpty);
    });

    test('node data provider tracks updateNodeData', () {
      final controller = LatticeController(
        initialNodes: [_node('a', Offset.zero, data: 'old')],
      );
      addTearDown(controller.dispose);

      expect(
        controller.container.read(latticeNodeDataProvider('a')),
        equals('old'),
      );
      expect(
        controller.container.read(latticeNodeDataProvider('missing')),
        isNull,
      );

      controller.updateNodeData('a', 'new');
      expect(
        controller.container.read(latticeNodeDataProvider('a')),
        equals('new'),
      );
    });
  });

  group('updateNodeData', () {
    test('replaces data with one history entry; undo restores', () {
      final controller = LatticeController(
        initialNodes: [_node('a', Offset.zero, data: 'old')],
      );
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.updateNodeData('a', 'new');
      expect(controller.document.nodes['a']!.data, equals('new'));
      expect(notifications, equals(1));

      controller.undo();
      expect(controller.document.nodes['a']!.data, equals('old'));
    });

    test('unknown id is a silent no-op', () {
      final controller = LatticeController(
        initialNodes: [_node('a', Offset.zero, data: 'old')],
      );
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(controller.canUndo, isFalse);

      controller.updateNodeData('missing', 'new');
      expect(controller.document.nodes['a']!.data, equals('old'));
      expect(notifications, equals(0));
      expect(controller.canUndo, isFalse);
    });
  });
}
