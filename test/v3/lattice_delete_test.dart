import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

LatticeNode _locked(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(
    id: id,
    type: 'default',
    position: offset,
    deletable: false,
  );
}

LatticeNode _child(String id, String parentId) {
  return LatticeNode(
    id: id,
    type: 'default',
    position: Offset.zero,
    parentId: parentId,
  );
}

LatticeEdge _edge(String id, String from, String to) {
  return LatticeEdge(
    id: id,
    source: LatticeEndpoint(nodeId: from),
    target: LatticeEndpoint(nodeId: to),
  );
}

LatticeEdge _lockedEdge(String id, String from, String to) {
  return LatticeEdge(
    id: id,
    source: LatticeEndpoint(nodeId: from),
    target: LatticeEndpoint(nodeId: to),
    deletable: false,
  );
}

void main() {
  group('deleteElements cascade', () {
    test('delete parent removes descendants + connected edge in one entry',
        () {
      final controller = LatticeController(
        initialNodes: [_node('p'), _child('c', 'p'), _child('g', 'c'), _node('x')],
        initialEdges: [_edge('e1', 'p', 'x')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final LatticeDeletedElements removed = controller.deleteElements(
        nodeIds: const {'p'},
      );
      expect(notifications, equals(1));
      expect(
        removed.nodes.map((LatticeNode n) => n.id),
        unorderedEquals(<String>['p', 'c', 'g']),
      );
      expect(
        removed.edges.map((LatticeEdge e) => e.id),
        unorderedEquals(<String>['e1']),
      );
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['x']),
      );
      expect(controller.document.edges, isEmpty);
      expect(controller.canUndo, isTrue);
    });

    test('one undo() restores deleted parent, descendants and edge', () {
      final controller = LatticeController(
        initialNodes: [_node('p'), _child('c', 'p'), _node('x')],
        initialEdges: [_edge('e1', 'p', 'x')],
      );
      addTearDown(controller.dispose);
      final LatticeDocument before = controller.document;
      controller.deleteElements(nodeIds: const {'p'});
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.undo();
      expect(notifications, equals(1));
      expect(controller.document, equals(before));
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['p', 'c', 'x']),
      );
      expect(
        controller.document.edges.keys,
        unorderedEquals(<String>['e1']),
      );
      expect(controller.canUndo, isFalse);
    });

    test('descendant walk is cycle-safe', () {
      final controller = LatticeController(
        initialNodes: const [
          LatticeNode(
            id: 'a',
            type: 'default',
            position: Offset.zero,
            parentId: 'b',
          ),
          LatticeNode(
            id: 'b',
            type: 'default',
            position: Offset.zero,
            parentId: 'a',
          ),
        ],
      );
      addTearDown(controller.dispose);
      final LatticeDeletedElements removed = controller.deleteElements(
        nodeIds: const {'a'},
      );
      expect(
        removed.nodes.map((LatticeNode n) => n.id),
        unorderedEquals(<String>['a', 'b']),
      );
      expect(controller.document.nodes, isEmpty);
    });

    test('deletable:false node survives deleteSelection with its edge', () {
      final controller = LatticeController(
        initialNodes: [_locked('a'), _node('b')],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a'});
      var notifications = 0;
      controller.addListener(() => notifications++);
      final LatticeDeletedElements removed = controller.deleteSelection();
      expect(removed.isEmpty, isTrue);
      expect(notifications, equals(0));
      expect(controller.canUndo, isFalse);
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['a', 'b']),
      );
      expect(
        controller.document.edges.keys,
        unorderedEquals(<String>['e1']),
      );
    });

    test('locked node listed with deletable sibling: sibling goes, lock holds',
        () {
      final controller = LatticeController(
        initialNodes: [_locked('a'), _node('b')],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a', 'b'});
      final LatticeDeletedElements removed = controller.deleteElements(
        nodeIds: const {'a', 'b'},
      );
      expect(
        removed.nodes.map((LatticeNode n) => n.id),
        unorderedEquals(<String>['b']),
      );
      // e1 touched removed node 'b': pruned as a cascade edge.
      expect(
        removed.edges.map((LatticeEdge e) => e.id),
        unorderedEquals(<String>['e1']),
      );
      expect(controller.document.nodes.keys, unorderedEquals(<String>['a']));
      expect(controller.document.edges, isEmpty);
      // Selection coerced: removed ids dropped.
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        unorderedEquals(<String>['a']),
      );
    });

    test('explicitly listed deletable:false edge survives while siblings go',
        () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
        initialEdges: [_lockedEdge('e1', 'a', 'b'), _edge('e2', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final LatticeDeletedElements removed = controller.deleteElements(
        edgeIds: const {'e1', 'e2'},
      );
      expect(notifications, equals(1));
      expect(
        removed.edges.map((LatticeEdge e) => e.id),
        unorderedEquals(<String>['e2']),
      );
      expect(removed.nodes, isEmpty);
      expect(
        controller.document.edges.keys,
        unorderedEquals(<String>['e1']),
      );
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['a', 'b']),
      );
      controller.undo();
      expect(
        controller.document.edges.keys,
        unorderedEquals(<String>['e1', 'e2']),
      );
    });

    test('empty call performs no push, replace or notify', () {
      final controller = LatticeController(
        initialNodes: [_node('a')],
        initialEdges: const [],
      );
      addTearDown(controller.dispose);
      var notifications = 0;
      controller.addListener(() => notifications++);
      final LatticeDeletedElements empty = controller.deleteElements();
      expect(empty.isEmpty, isTrue);
      expect(notifications, equals(0));
      expect(controller.canUndo, isFalse);
      // Unknown ids are also a no-op.
      final LatticeDeletedElements ghosts = controller.deleteElements(
        nodeIds: const {'ghost'},
        edgeIds: const {'ghost-edge'},
      );
      expect(ghosts.isEmpty, isTrue);
      expect(notifications, equals(0));
      expect(controller.canUndo, isFalse);
      expect(controller.document.nodes.keys, unorderedEquals(<String>['a']));
    });

    test('selection coerced to surviving ids after delete', () {
      final controller = LatticeController(
        initialNodes: [_node('p'), _child('c', 'p'), _node('x')],
        initialEdges: [_edge('e1', 'p', 'x')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'p', 'c'}, const {'e1'});
      controller.deleteElements(nodeIds: const {'p'});
      final LatticeSelection selection =
          controller.container.read(latticeSelectionProvider);
      expect(selection.nodes, isEmpty);
      expect(selection.edges, isEmpty);
    });
  });

  group('json persistence verbs', () {
    test('loadJson(toJson()) round-trip preserves the graph', () {
      final LatticeDocument seeded = LatticeDocument(
        nodes: <String, LatticeNode>{
          'p': _node('p', const Offset(1, 2)),
          'c': const LatticeNode(
            id: 'c',
            type: 'custom',
            position: Offset(3, 4),
            data: 'payload',
            parentId: 'p',
            deletable: false,
          ),
          'x': _node('x', const Offset(9, 9)),
        },
        edges: <String, LatticeEdge>{
          'e1': _edge('e1', 'p', 'x'),
        },
        viewport: const LatticeViewportValue(
          offset: Offset(5, 6),
          zoom: 2.0,
        ),
      );
      final controller = LatticeController();
      addTearDown(controller.dispose);
      controller.load(seeded);
      final Map<String, Object?> json = controller.toJson();
      final other = LatticeController();
      addTearDown(other.dispose);
      other.loadJson(json);
      expect(other.document, equals(seeded));
    });

    test('loadJson resets history and clears selection', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.select(const {'a'});
      controller.addNode(_node('b', const Offset(2, 2)));
      expect(controller.canUndo, isTrue);
      final Map<String, Object?> json = controller.toJson();
      final LatticeDocument before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.loadJson(json);
      expect(notifications, equals(1));
      expect(controller.document, equals(before));
      expect(controller.canUndo, isFalse);
      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );
    });
  });
}
