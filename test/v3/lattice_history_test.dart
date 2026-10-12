import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

void main() {
  group('history undo/redo', () {
    test('add then undo restores document', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      final before = controller.document;
      controller.addNode(_node('b', const Offset(3, 4)));
      expect(controller.document.nodes.containsKey('b'), isTrue);
      expect(controller.canUndo, isTrue);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.undo();
      expect(notifications, equals(1));
      expect(controller.document, equals(before));
      expect(controller.document.nodes.containsKey('b'), isFalse);
    });

    test('undo then redo reapplies', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.addNode(_node('b', const Offset(3, 4)));
      final withB = controller.document;
      controller.undo();
      expect(controller.canRedo, isTrue);
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.redo();
      expect(notifications, equals(1));
      expect(controller.document, equals(withB));
      expect(controller.document.nodes.containsKey('b'), isTrue);
    });

    test('150 pushes cap length at 100', () {
      final history = LatticeHistoryController();
      var doc = LatticeDocument.empty();
      for (var i = 0; i < 150; i++) {
        history.push(doc);
        doc = doc.withNode(_node('n$i'));
      }
      expect(history.length, equals(100));
      expect(history.canUndo, isTrue);
    });

    test('load resets history', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.addNode(_node('b'));
      expect(controller.canUndo, isTrue);
      controller.load(
        LatticeDocument(
          nodes: <String, LatticeNode>{'z': _node('z')},
          edges: const {},
          viewport: const LatticeViewportValue(),
        ),
      );
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('rapid coalescePush with identical pre-images collapses', () {
      final history = LatticeHistoryController();
      final doc = LatticeDocument.empty();
      for (var i = 0; i < 10; i++) {
        history.coalescePush(doc);
      }
      expect(history.length, equals(1));
    });

    test('undo on empty stack: no notify, document unchanged', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      final before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.undo();
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
    });
  });

  group('history hardening', () {
    test('A: setNodes resets history (load semantics)', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.addNode(_node('b'));
      expect(controller.canUndo, isTrue);
      controller.setNodes([_node('a'), _node('c')]);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['a', 'c']),
      );
    });

    test('A: setEdges resets history (load semantics)', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.addNode(_node('b'));
      expect(controller.canUndo, isTrue);
      controller.setEdges(const []);
      expect(controller.canUndo, isFalse);
      expect(controller.canRedo, isFalse);
    });

    test('B: removeNodes with unknown ids skips push+replace+notify', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      final before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.removeNodes(const {'ghost'});
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
    });

    test('B: removeEdges with unknown ids skips push+replace+notify', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      final before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.removeEdges(const {'ghost'});
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
    });

    test('B: addNode with identical value skips push+replace+notify', () {
      final controller = LatticeController(
        initialNodes: [_node('a', const Offset(1, 1))],
      );
      addTearDown(controller.dispose);
      final before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.addNode(_node('a', const Offset(1, 1)));
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
    });

    test('B: addEdge with identical value skips push+replace+notify', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
        initialEdges: [
          LatticeEdge(
            id: 'e1',
            source: const LatticeEndpoint(nodeId: 'a'),
            target: const LatticeEndpoint(nodeId: 'b'),
          ),
        ],
      );
      addTearDown(controller.dispose);
      final before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.addEdge(
        LatticeEdge(
          id: 'e1',
          source: const LatticeEndpoint(nodeId: 'a'),
          target: const LatticeEndpoint(nodeId: 'b'),
        ),
      );
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
    });

    test('C: delete selected node then undo keeps only existing ids', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'b'});
      controller.removeNodes(const {'b'});
      // Selection still names the removed node until undo coerces it.
      controller.undo();
      expect(
        controller.document.nodes.keys,
        unorderedEquals(<String>['a', 'b']),
      );
      final selection = controller.container.read(latticeSelectionProvider);
      expect(selection.nodes, unorderedEquals(<String>['b']));
      for (final String id in selection.nodes) {
        expect(controller.document.nodes.containsKey(id), isTrue);
      }
    });

    test('C: redo coerces selection to existing ids (no dangling ids)', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a', 'b'});
      controller.removeNodes(const {'b'});
      controller.undo();
      controller.redo();
      expect(controller.document.nodes.keys, unorderedEquals(<String>['a']));
      final selection = controller.container.read(latticeSelectionProvider);
      expect(selection.nodes, unorderedEquals(<String>['a']));
      for (final String id in selection.nodes) {
        expect(controller.document.nodes.containsKey(id), isTrue);
      }
    });

    test('C: undo drops ghost selection ids', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      controller.select(const {'ghost'});
      controller.addNode(_node('b'));
      controller.undo();
      expect(controller.document.nodes.keys, unorderedEquals(<String>['a']));
      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );
    });
  });
}
