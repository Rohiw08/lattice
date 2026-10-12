import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

const _nodeSize = Size(160, 44);

// Node 'a' at (100,100): source handle 'out' centered at node-local
// (80,41) => flow/screen (180,141). Node 'b' at (400,300): target
// handle 'in' centered at node-local (80,0) => flow/screen (480,300).
// Identity camera on the default 800x600 test surface, so flow == screen.
const _sourceHandleScreen = Offset(180, 141);
const _targetHandleScreen = Offset(480, 300);

List<LatticeNode> _connectNodes() {
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
  ];
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
}

void main() {
  group('connect flow', () {
    testWidgets(
        'press-drag-release from source handle to target handle creates edge',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _connectNodes());
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      // Handles mount even with the default node builder.
      expect(find.byType(LatticeHandleWidget), findsNWidgets(2));

      final gesture = await tester.startGesture(_sourceHandleScreen);
      await gesture.moveTo(_targetHandleScreen);
      await tester.pump();

      final drag = controller.container.read(latticeDragProvider);
      expect(drag.isActive, isTrue);
      expect(
        drag.from,
        equals(const LatticeEndpoint(nodeId: 'a', handleId: 'out')),
      );

      await gesture.up();
      await tester.pump();

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      final edges = controller.document.edges;
      expect(edges, hasLength(1));
      final edge = edges.values.single;
      expect(edge.id.startsWith('edge_'), isTrue);
      expect(
        edge.source,
        equals(const LatticeEndpoint(nodeId: 'a', handleId: 'out')),
      );
      expect(
        edge.target,
        equals(const LatticeEndpoint(nodeId: 'b', handleId: 'in')),
      );
      // Exactly one history entry for the valid connect.
      expect(controller.canUndo, isTrue);
    });

    testWidgets('dropping on empty pane creates nothing, no history',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _connectNodes());
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);
      expect(controller.canUndo, isFalse);

      final gesture = await tester.startGesture(_sourceHandleScreen);
      await gesture.moveTo(const Offset(700, 500));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.document.edges, isEmpty);
      expect(controller.canUndo, isFalse);
    });

    testWidgets('connect moves emit zero document notifications',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _connectNodes());
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      var notes = 0;
      controller.addListener(() => notes++);

      final gesture = await tester.startGesture(_sourceHandleScreen);
      for (var i = 0; i < 20; i++) {
        await gesture.moveBy(const Offset(5, 5));
      }
      await tester.pump();

      expect(notes, equals(0));
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isTrue,
      );

      // (280,241) lands on the empty pane: silent cancel, still no notify.
      await gesture.up();
      await tester.pump();

      expect(controller.document.edges, isEmpty);
      expect(notes, equals(0));
    });
  });
}
