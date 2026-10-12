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
}
