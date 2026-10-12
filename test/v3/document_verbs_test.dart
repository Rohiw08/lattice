import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

LatticeEdge _edge(String id, String from, String to) {
  return LatticeEdge(
    id: id,
    source: LatticeEndpoint(nodeId: from),
    target: LatticeEndpoint(nodeId: to),
  );
}

void main() {
  group('document verbs', () {
    test('addNode inserts and notifies once', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.addNode(_node('b', const Offset(3, 4)));
      expect(notifications, equals(1));
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['a', 'b']),
      );
      expect(
        controller.document.nodes['b']!.position,
        equals(const Offset(3, 4)),
      );
    });

    test('addNode with duplicate id overwrites', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.addNode(_node('a', const Offset(9, 9)));
      expect(controller.document.nodes['a']!.position, equals(const Offset(9, 9)));
      expect(controller.document.nodes.length, equals(1));
    });

    test('addEdge inserts and notifies once', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.addEdge(_edge('e1', 'a', 'b'));
      expect(notifications, equals(1));
      expect(controller.document.edges.keys, unorderedEquals(<String>['e1']));
    });

    test('moveNodes applies positions with single notification', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b', const Offset(5, 5))],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.moveNodes(const {
        'a': Offset(1, 1),
        'b': Offset(2, 2),
      });
      expect(notifications, equals(1));
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(1, 1)),
      );
      expect(
        controller.document.nodes['b']!.position,
        equals(const Offset(2, 2)),
      );
    });

    test('moveNodes ignores unknown ids', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.moveNodes(const {
        'a': Offset(7, 7),
        'ghost': Offset(1, 1),
      });
      expect(notifications, equals(1));
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(7, 7)),
      );
      expect(controller.document.nodes.containsKey('ghost'), isFalse);
    });

    test('moveNodes no-change performs no replace and no notify', () {
      final controller = LatticeController(
        initialNodes: [_node('a', const Offset(1, 1))],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.moveNodes(const {'a': Offset(1, 1)});
      expect(notifications, equals(0));
    });

    test('moveNodes unknown-only ids performs no notify', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.moveNodes(const {'ghost': Offset(1, 1)});
      expect(notifications, equals(0));
    });

    test('removeNodes removes and notifies once', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.removeNodes(const {'a'});
      expect(notifications, equals(1));
      expect(controller.document.nodes.keys, unorderedEquals(<String>['b']));
    });

    test('removeEdges removes and notifies once', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
        initialEdges: [_edge('e1', 'a', 'b'), _edge('e2', 'b', 'a')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.removeEdges(const {'e1'});
      expect(notifications, equals(1));
      expect(controller.document.edges.keys, unorderedEquals(<String>['e2']));
    });
  });

  group('selection ops', () {
    test('select sets selection provider without controller notification', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.select(const {'a'}, const {'e1'});
      expect(notifications, equals(0));
      final selection = controller.container.read(latticeSelectionProvider);
      expect(selection.nodes, unorderedEquals(<String>['a']));
      expect(selection.edges, unorderedEquals(<String>['e1']));
    });

    test('deselectAll empties selection', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.select(const {'a'});
      controller.deselectAll();
      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );
    });

    test('selectAll covers all node and edge ids', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
        initialEdges: [_edge('e1', 'a', 'b'), _edge('e2', 'b', 'a')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.selectAll();
      expect(notifications, equals(0));
      final selection = controller.container.read(latticeSelectionProvider);
      expect(selection.nodes, unorderedEquals(<String>['a', 'b']));
      expect(selection.edges, unorderedEquals(<String>['e1', 'e2']));
    });
  });

  group('load/save', () {
    test('load replaces everything and clears selection', () {
      final controller = LatticeController(
        initialNodes: [_node('a')],
        initialEdges: [_edge('e1', 'a', 'a')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a'}, const {'e1'});
      final next = LatticeDocument(
        nodes: <String, LatticeNode>{'z': _node('z')},
        edges: <String, LatticeEdge>{},
        viewport: const LatticeViewportValue(offset: Offset(5, 6), zoom: 2.0),
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

    test('save returns identical document', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      expect(identical(controller.save(), controller.document), isTrue);
    });
  });
}
