import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

const _nodeSize = Size(160, 44);

// Node 'a' at (100,100): source handle 'out' centered at (180,141).
// Node 'b' at (400,300): target handle 'in' centered at (480,300).
// Node 'c' at (400,100): target handle 'in' centered at (480,100) and
// source handle 'out' centered at (480,141).
// Identity camera in controller-only tests, so flow == screen.
List<LatticeNode> _reconnectNodes() {
  return const <LatticeNode>[
    LatticeNode(
      id: 'a',
      type: 'custom',
      position: Offset(100, 100),
      size: _nodeSize,
      handles: <String, LatticeHandle>{
        'out': LatticeHandle(
          id: 'out',
          type: LatticeHandleType.source,
          position: Offset(77, 38),
        ),
      },
    ),
    LatticeNode(
      id: 'b',
      type: 'custom',
      position: Offset(400, 300),
      size: _nodeSize,
      handles: <String, LatticeHandle>{
        'in': LatticeHandle(
          id: 'in',
          type: LatticeHandleType.target,
          position: Offset(77, -3),
        ),
      },
    ),
    LatticeNode(
      id: 'c',
      type: 'custom',
      position: Offset(400, 100),
      size: _nodeSize,
      handles: <String, LatticeHandle>{
        'in': LatticeHandle(
          id: 'in',
          type: LatticeHandleType.target,
          position: Offset(77, -3),
        ),
        'out': LatticeHandle(
          id: 'out',
          type: LatticeHandleType.source,
          position: Offset(77, 38),
        ),
      },
    ),
  ];
}

const _sourceA = LatticeEndpoint(nodeId: 'a', handleId: 'out');
const _targetB = LatticeEndpoint(nodeId: 'b', handleId: 'in');
const _targetC = LatticeEndpoint(nodeId: 'c', handleId: 'in');
const _sourceC = LatticeEndpoint(nodeId: 'c', handleId: 'out');

LatticeEdge _edge() {
  return const LatticeEdge(id: 'e1', source: _sourceA, target: _targetB);
}

LatticeController _controller() {
  final controller = LatticeController(
    initialNodes: _reconnectNodes(),
    initialEdges: <LatticeEdge>[_edge()],
  );
  addTearDown(controller.dispose);
  return controller;
}

void main() {
  group('edge reconnect', () {
    test(
      'reconnect target end to a new handle updates edge, one undo restores',
      () {
        final controller = _controller();
        expect(controller.canUndo, isFalse);
        var notes = 0;
        controller.addListener(() => notes++);

        controller.beginReconnect('e1', sourceEnd: false);

        final drag = controller.container.read(latticeDragProvider);
        expect(drag.isActive, isTrue);
        expect(drag.from, equals(_sourceA));
        expect(drag.liveEnd, equals(const Offset(480, 300)));
        expect(drag.reconnectEdgeId, equals('e1'));
        expect(notes, equals(0));

        controller.endReconnect(_targetC);

        final edge = controller.document.edges['e1']!;
        expect(edge.source, equals(_sourceA));
        expect(edge.target, equals(_targetC));
        expect(notes, equals(1));
        expect(
          controller.container.read(latticeDragProvider).isActive,
          isFalse,
        );

        controller.undo();
        expect(controller.document.edges['e1']!.target, equals(_targetB));
        expect(controller.canUndo, isFalse);

        controller.redo();
        expect(controller.document.edges['e1']!.target, equals(_targetC));
      },
    );

    test(
      'reconnect source end to a new handle updates edge, one undo restores',
      () {
        final controller = _controller();
        var notes = 0;
        controller.addListener(() => notes++);

        controller.beginReconnect('e1', sourceEnd: true);

        final drag = controller.container.read(latticeDragProvider);
        expect(drag.isActive, isTrue);
        expect(drag.from, equals(_targetB));
        expect(drag.liveEnd, equals(const Offset(180, 141)));
        expect(drag.reconnectEdgeId, equals('e1'));
        expect(notes, equals(0));

        controller.endReconnect(_sourceC);

        final edge = controller.document.edges['e1']!;
        expect(edge.source, equals(_sourceC));
        expect(edge.target, equals(_targetB));
        expect(notes, equals(1));

        controller.undo();
        expect(controller.document.edges['e1']!.source, equals(_sourceA));
        expect(controller.canUndo, isFalse);
      },
    );

    test('updateReconnect moves liveEnd through screenToFlow', () {
      final controller = _controller();
      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginReconnect('e1', sourceEnd: false);
      controller.updateReconnect(const Offset(10, 20));

      final drag = controller.container.read(latticeDragProvider);
      expect(drag.isActive, isTrue);
      expect(drag.from, equals(_sourceA));
      expect(drag.liveEnd, equals(const Offset(10, 20)));
      expect(drag.reconnectEdgeId, equals('e1'));
      expect(notes, equals(0));
    });

    test('cancel with null target leaves document and history untouched', () {
      final controller = _controller();
      var notes = 0;
      controller.addListener(() => notes++);
      expect(controller.canUndo, isFalse);

      controller.beginReconnect('e1', sourceEnd: false);
      controller.endReconnect(null);

      expect(controller.document.edges['e1']!.target, equals(_targetB));
      expect(controller.canUndo, isFalse);
      expect(controller.container.read(latticeDragProvider).isActive, isFalse);
      expect(notes, equals(0));
    });

    test('reconnect to same handle is a no-op with no history entry', () {
      final controller = _controller();
      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginReconnect('e1', sourceEnd: false);
      controller.endReconnect(_targetB);

      expect(controller.document.edges['e1']!.target, equals(_targetB));
      expect(controller.canUndo, isFalse);
      expect(controller.container.read(latticeDragProvider).isActive, isFalse);
      expect(notes, equals(0));
    });

    test('reconnect to an invalid target cancels silently', () {
      final controller = _controller();
      var notes = 0;
      controller.addListener(() => notes++);

      // A source-type handle can never be a reconnect target.
      controller.beginReconnect('e1', sourceEnd: false);
      controller.endReconnect(_sourceA);

      expect(controller.document.edges['e1'], equals(_edge()));
      expect(controller.canUndo, isFalse);
      expect(controller.container.read(latticeDragProvider).isActive, isFalse);
      expect(notes, equals(0));
    });

    test('reconnect to a duplicate endpoint pair cancels silently', () {
      final controller = LatticeController(
        initialNodes: _reconnectNodes(),
        initialEdges: <LatticeEdge>[
          _edge(),
          const LatticeEdge(id: 'e2', source: _sourceA, target: _targetC),
        ],
      );
      addTearDown(controller.dispose);
      var notes = 0;
      controller.addListener(() => notes++);

      // e1's target is already e2's target pair (a.out -> c.in).
      controller.beginReconnect('e1', sourceEnd: false);
      controller.endReconnect(_targetC);

      expect(controller.document.edges['e1']!.target, equals(_targetB));
      expect(controller.canUndo, isFalse);
      expect(controller.container.read(latticeDragProvider).isActive, isFalse);
      expect(notes, equals(0));
    });

    test('beginReconnect with unknown id is a no-op', () {
      final controller = _controller();
      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginReconnect('missing', sourceEnd: false);

      expect(controller.container.read(latticeDragProvider).isActive, isFalse);
      expect(controller.canUndo, isFalse);
      expect(notes, equals(0));
    });
  });
}
