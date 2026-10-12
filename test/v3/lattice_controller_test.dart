import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

const LatticeEdge _edgeAB = LatticeEdge(
  id: 'e1',
  source: LatticeEndpoint(nodeId: 'a'),
  target: LatticeEndpoint(nodeId: 'b'),
);

void main() {
  group('LatticeOptions value', () {
    test('==/hashCode/copyWith/defaults', () {
      const a = LatticeOptions();
      const b = LatticeOptions();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.fitView, isFalse);
      expect(a.minZoom, equals(0.05));
      expect(a.maxZoom, equals(4.0));
      expect(a.defaultViewport, isNull);
      expect(
        a.copyWith(fitView: true, maxZoom: 2.0),
        equals(
          const LatticeOptions(fitView: true, minZoom: 0.05, maxZoom: 2.0),
        ),
      );
    });
  });

  group('LatticeController', () {
    test('initial nodes readable via container.read(latticeDocumentProvider)',
        () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b', const Offset(1, 2))],
      );
      addTearDown(controller.dispose);
      final document = controller.container.read(latticeDocumentProvider);
      expect(document.nodes.keys, unorderedEquals(<String>['a', 'b']));
      expect(controller.document, equals(document));
      expect(controller.isAttached, isFalse);
    });

    test('setNodes notifies controller listeners exactly once', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.setNodes([_node('a'), _node('c')]);
      expect(notifications, equals(1));
      expect(
        controller.container.read(latticeDocumentProvider).nodes.keys,
        unorderedEquals(<String>['a', 'c']),
      );
    });

    test('setEdges replaces edges only', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
        initialEdges: const [_edgeAB],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      const edge2 = LatticeEdge(
        id: 'e2',
        source: LatticeEndpoint(nodeId: 'b'),
        target: LatticeEndpoint(nodeId: 'a'),
      );
      controller.setEdges(const [edge2]);
      expect(notifications, equals(1));
      final document = controller.container.read(latticeDocumentProvider);
      expect(document.edges.keys, unorderedEquals(<String>['e2']));
      // Nodes untouched.
      expect(document.nodes.keys, unorderedEquals(<String>['a', 'b']));
    });

    test('load replaces all three parts and clears selection', () {
      final controller = LatticeController(
        initialNodes: [_node('a')],
        initialEdges: const [_edgeAB],
      );
      addTearDown(controller.dispose);
      controller.container
          .read(latticeSelectionProvider.notifier)
          .setSelection(const LatticeSelection(nodes: {'a'}, edges: {'e1'}));
      const viewport = LatticeViewportValue(offset: Offset(5, 6), zoom: 2.0);
      final next = LatticeDocument(
        nodes: {'z': _node('z')},
        edges: const {},
        viewport: viewport,
      );
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.load(next);
      expect(notifications, equals(1));
      expect(controller.document, equals(next));
      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );
    });

    test('options setter does not notify', () {
      final controller = LatticeController();
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.options = const LatticeOptions(fitView: true);
      expect(notifications, equals(0));
      expect(controller.options.fitView, isTrue);
    });

    test('double dispose() does not throw', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      controller.dispose();
      expect(controller.dispose, returnsNormally);
    });
  });
}
