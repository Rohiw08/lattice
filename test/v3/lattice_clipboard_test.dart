import 'dart:ui';

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

LatticeNode _child(String id, Offset offset, String parentId) {
  return LatticeNode(
    id: id,
    type: 'default',
    position: offset,
    parentId: parentId,
  );
}

Set<String> _selectionOf(LatticeController controller) {
  return controller.container.read(latticeSelectionProvider).nodes;
}

void main() {
  group('LatticeClipboard', () {
    test('empty clipboard has no payload', () {
      expect(LatticeClipboard().hasPayload, isFalse);
    });

    test('store with empty lists clears the payload', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [_node('a')],
        edges: [_edge('e1', 'a', 'a')],
      );
      expect(clipboard.hasPayload, isTrue);
      clipboard.store(nodes: const [], edges: const []);
      expect(clipboard.hasPayload, isFalse);
    });

    test('paste offsets positions and assigns fresh ids in list order', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [_node('a'), _node('b', const Offset(10, 0))],
        edges: const [],
      );
      var calls = 0;
      final pasted = clipboard.paste(
        delta: const Offset(5, 5),
        freshIds: () {
          calls++;
          return <String>{'n$calls'};
        },
      );
      // freshIds called exactly once per pasted node, in list order.
      expect(calls, equals(2));
      expect(
        pasted.nodes.map((LatticeNode n) => n.id),
        orderedEquals(<String>['n1', 'n2']),
      );
      expect(pasted.nodes[0].position, equals(const Offset(5, 5)));
      expect(pasted.nodes[1].position, equals(const Offset(15, 5)));
      expect(pasted.edges, isEmpty);
    });

    test('paste rewires edge endpoints to the new ids', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [_node('a'), _node('b', const Offset(10, 0))],
        edges: [_edge('e1', 'a', 'b')],
      );
      var n = 0;
      final pasted = clipboard.paste(
        delta: Offset.zero,
        freshIds: () {
          n++;
          // First element names the node; leftovers pool to edges.
          return <String>{'n$n', 'e$n'};
        },
      );
      expect(pasted.nodes.map((LatticeNode x) => x.id), hasLength(2));
      final LatticeEdge edge = pasted.edges.single;
      expect(edge.id, equals('e1'));
      expect(edge.source.nodeId, equals(pasted.nodes[0].id));
      expect(edge.target.nodeId, equals(pasted.nodes[1].id));
    });

    test('paste remaps parentIds inside the set, detaches external ones', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [
          _node('p'),
          _child('c', const Offset(5, 5), 'p'),
          _child('o', const Offset(9, 9), 'ghost'),
        ],
        edges: const [],
      );
      var n = 0;
      final pasted = clipboard.paste(
        delta: Offset.zero,
        freshIds: () {
          n++;
          return <String>{'m$n'};
        },
      );
      expect(
        pasted.nodes.map((LatticeNode x) => x.id),
        orderedEquals(<String>['m1', 'm2', 'm3']),
      );
      // 'c' copy keeps the hierarchy, remapped to the pasted parent.
      expect(pasted.nodes[1].parentId, equals('m1'));
      // 'o' copy referenced a parent outside the set: becomes a root node.
      expect(pasted.nodes[2].parentId, isNull);
    });

    test('paste drops edges with endpoints outside the pasted set', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [_node('a')],
        edges: [_edge('e1', 'a', 'b')],
      );
      final pasted = clipboard.paste(
        delta: Offset.zero,
        freshIds: () => <String>{'n1'},
      );
      expect(pasted.nodes, hasLength(1));
      expect(pasted.edges, isEmpty);
    });

    test('paste throws when fresh ids run short for retained edges', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: [_node('a'), _node('b')],
        edges: [_edge('e1', 'a', 'b')],
      );
      expect(
        () => clipboard.paste(
          delta: Offset.zero,
          // Singletons: enough for the nodes, nothing left for the edge.
          freshIds: () => <String>{'only'},
        ),
        throwsStateError,
      );
    });

    test('edges-only payload has no payload', () {
      final clipboard = LatticeClipboard();
      clipboard.store(
        nodes: const [],
        edges: [_edge('e1', 'a', 'b')],
      );
      expect(clipboard.hasPayload, isFalse);
    });

    test('paste preserves all fields on internally-parented copies', () {
      final clipboard = LatticeClipboard();
      final child = LatticeNode(
        id: 'c',
        type: 'custom',
        position: const Offset(30, 40),
        origin: const Offset(1, 2),
        size: const Size(200, 100),
        data: const {'k': 'v'},
        parentId: 'p',
        zIndex: 7,
        handles: const {
          'h': LatticeHandle(
            id: 'h',
            type: LatticeHandleType.source,
            position: Offset(3, 4),
          ),
        },
        hidden: true,
        draggable: false,
        selectable: false,
        hoverable: false,
        connectable: false,
        deletable: false,
        resizable: true,
        focusable: true,
        minSize: const Size(50, 20),
        maxSize: const Size(400, 200),
        keepAspectRatio: true,
        expandParent: true,
        dragHandle: true,
        semanticsLabel: 'label',
        extent: const Rect.fromLTWH(0, 0, 10, 10),
      );
      clipboard.store(
        nodes: [_node('p', const Offset(10, 20)), child],
        edges: const [],
      );
      var n = 0;
      final pasted = clipboard.paste(
        delta: const Offset(5, 5),
        freshIds: () {
          n++;
          return <String>{'m$n'};
        },
      );
      expect(pasted.nodes, hasLength(2));
      final LatticeNode copy = pasted.nodes[1];
      expect(copy.id, equals('m2'));
      // Parent was pasted too: remapped to the pasted parent id.
      expect(copy.parentId, equals('m1'));
      expect(copy.position, equals(const Offset(35, 45)));
      expect(copy.type, equals(child.type));
      expect(copy.origin, equals(child.origin));
      expect(copy.size, equals(child.size));
      expect(copy.data, equals(child.data));
      expect(copy.zIndex, equals(child.zIndex));
      expect(copy.handles, equals(child.handles));
      expect(copy.hidden, equals(child.hidden));
      expect(copy.draggable, equals(child.draggable));
      expect(copy.selectable, equals(child.selectable));
      expect(copy.hoverable, equals(child.hoverable));
      expect(copy.connectable, equals(child.connectable));
      expect(copy.deletable, equals(child.deletable));
      expect(copy.resizable, equals(child.resizable));
      expect(copy.focusable, equals(child.focusable));
      expect(copy.minSize, equals(child.minSize));
      expect(copy.maxSize, equals(child.maxSize));
      expect(copy.keepAspectRatio, equals(child.keepAspectRatio));
      expect(copy.expandParent, equals(child.expandParent));
      expect(copy.dragHandle, equals(child.dragHandle));
      expect(copy.semanticsLabel, equals(child.semanticsLabel));
      expect(copy.extent, equals(child.extent));
    });
  });

  group('controller clipboard verbs', () {
    test('copy two connected nodes then paste offsets by delta from anchor',
        () {
      final controller = LatticeController(
        initialNodes: [
          _node('a', const Offset(10, 20)),
          _node('b', const Offset(50, 60)),
        ],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a', 'b'});
      controller.copySelection();
      var notifications = 0;
      controller.addListener(() => notifications++);
      // Payload anchor is the top-left of the payload bounds: (10, 20),
      // so pasting at (100, 100) applies delta (90, 80).
      controller.paste(at: const Offset(100, 100));
      expect(notifications, equals(1));
      final LatticeDocument doc = controller.document;
      expect(doc.nodes.length, equals(4));
      expect(doc.edges.length, equals(2));
      final LatticeEdge copy = doc.edges.values
          .singleWhere((LatticeEdge e) => e.id != 'e1');
      expect(copy.id, startsWith('edge_copy_'));
      final LatticeNode? sourceCopy = doc.nodes[copy.source.nodeId];
      final LatticeNode? targetCopy = doc.nodes[copy.target.nodeId];
      expect(sourceCopy, isNotNull);
      expect(targetCopy, isNotNull);
      expect(sourceCopy!.id, startsWith('node_copy_'));
      expect(targetCopy!.id, startsWith('node_copy_'));
      expect(sourceCopy.position, equals(const Offset(100, 100)));
      expect(targetCopy.position, equals(const Offset(140, 140)));
      // The paste selects exactly the new nodes.
      expect(
        _selectionOf(controller),
        unorderedEquals(<String>[sourceCopy.id, targetCopy.id]),
      );
      // One history entry: a single undo restores the seeded document.
      expect(controller.canUndo, isTrue);
      controller.undo();
      expect(controller.document.nodes.length, equals(2));
      expect(controller.document.edges.length, equals(1));
      expect(controller.canUndo, isFalse);
    });

    test('paste with colliding ids still unique', () {
      final controller = LatticeController(
        initialNodes: [
          _node('a'),
          _node('node_copy_1', const Offset(500, 500)),
        ],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a'});
      controller.copySelection();
      controller.paste(at: const Offset(100, 100));
      final Set<String> ids = controller.document.nodes.keys.toSet();
      expect(ids.length, equals(3));
      expect(ids, contains('a'));
      expect(ids, contains('node_copy_1'));
      final String fresh = ids.difference(<String>{'a', 'node_copy_1'}).single;
      expect(fresh, startsWith('node_copy_'));
      expect(fresh, isNot(equals('node_copy_1')));
      expect(
        controller.document.nodes[fresh]!.position,
        equals(const Offset(100, 100)),
      );
    });

    test('copy node without its connected edge drops the edge', () {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b', const Offset(30, 0))],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      // Nodes only: the edge endpoint 'b' is outside the selection.
      controller.select(const {'a'});
      controller.copySelection();
      controller.paste(at: const Offset(200, 200));
      expect(controller.document.nodes.length, equals(3));
      expect(controller.document.edges.length, equals(1));
      // Even an explicitly selected edge is dropped when an endpoint
      // is outside the copied node set.
      controller.select(const {'a'}, const {'e1'});
      controller.copySelection();
      controller.paste(at: const Offset(300, 300));
      expect(controller.document.nodes.length, equals(4));
      expect(controller.document.edges.length, equals(1));
    });

    test('paste with empty clipboard is a no-op with no history entry', () {
      final controller = LatticeController(initialNodes: [_node('a')]);
      addTearDown(controller.dispose);
      final LatticeDocument before = controller.document;
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.paste(at: const Offset(5, 5));
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
      // Copying an empty selection clears the payload: the next paste
      // is a no-op too.
      controller.select(const {'a'});
      controller.copySelection();
      controller.deselectAll();
      controller.copySelection();
      controller.paste(at: const Offset(5, 5));
      expect(notifications, equals(0));
      expect(identical(controller.document, before), isTrue);
      expect(controller.canUndo, isFalse);
    });

    test('duplicateSelection offsets +40,+40 in one history entry', () {
      final controller = LatticeController(
        initialNodes: [
          _node('a', const Offset(10, 20)),
          _node('b', const Offset(50, 60)),
        ],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      controller.select(const {'a', 'b'});
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.duplicateSelection();
      expect(notifications, equals(1));
      final LatticeDocument doc = controller.document;
      expect(doc.nodes.length, equals(4));
      final Set<Offset> positions =
          doc.nodes.values.map((LatticeNode n) => n.position).toSet();
      expect(positions, contains(const Offset(50, 60)));
      expect(positions, contains(const Offset(90, 100)));
      final LatticeEdge copy = doc.edges.values
          .singleWhere((LatticeEdge e) => e.id != 'e1');
      expect(doc.nodes[copy.source.nodeId]!.position,
          equals(const Offset(50, 60)));
      expect(doc.nodes[copy.target.nodeId]!.position,
          equals(const Offset(90, 100)));
      // Exactly one history entry: one undo removes both copies + edge
      // (the undo itself is the second controller notification).
      controller.undo();
      expect(notifications, equals(2));
      expect(controller.document.nodes.length, equals(2));
      expect(controller.document.edges.length, equals(1));
      expect(controller.canUndo, isFalse);
      // Empty selection duplicates nothing: no notify, no history.
      controller.deselectAll();
      controller.duplicateSelection();
      expect(notifications, equals(2));
      expect(controller.canUndo, isFalse);
    });

    test('pasting N nodes + E edges advances the id counter by exactly N+E',
        () {
      final controller = LatticeController(
        initialNodes: [
          _node('a', const Offset(10, 20)),
          _node('b', const Offset(50, 60)),
        ],
        initialEdges: [_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);
      int ordinal(String id) =>
          int.parse(id.substring(id.lastIndexOf('_') + 1));
      controller.select(const {'a', 'b'});
      controller.copySelection();
      controller.paste(at: const Offset(100, 100));
      final Set<String> afterFirst = <String>{
        ...controller.document.nodes.keys,
        ...controller.document.edges.keys,
      };
      final Set<String> fresh1 =
          afterFirst.difference(<String>{'a', 'b', 'e1'});
      // N=2 nodes + E=1 edge minted exactly 3 ids: ordinals 1..3.
      expect(fresh1, hasLength(3));
      expect(
        fresh1.where((String id) => id.startsWith('node_copy_')),
        hasLength(2),
      );
      expect(
        fresh1.where((String id) => id.startsWith('edge_copy_')),
        hasLength(1),
      );
      expect(fresh1.map(ordinal).toSet(), equals(<int>{1, 2, 3}));
      // A second paste of the same payload continues densely at 4..6
      // (no per-node edge-id burn) with all ids unique.
      controller.paste(at: const Offset(300, 300));
      final Set<String> afterSecond = <String>{
        ...controller.document.nodes.keys,
        ...controller.document.edges.keys,
      };
      final Set<String> fresh2 = afterSecond.difference(afterFirst);
      expect(fresh2, hasLength(3));
      expect(fresh2.map(ordinal).toSet(), equals(<int>{4, 5, 6}));
      expect(afterSecond.length, equals(afterFirst.length + 3));
    });
  });
}
