import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, Offset position) {
  return LatticeNode(id: id, type: 'default', position: position);
}

/// Node 'a' occupies flow rect (100,100)-(260,144); node 'b' sits at
/// (400,300)-(560,344). Default 800x600 test surface, identity camera.
LatticeController _seededController() {
  return LatticeController(
    initialNodes: [
      _node('a', const Offset(100, 100)),
      _node('b', const Offset(400, 300)),
    ],
  );
}

Future<void> _pumpCanvas(WidgetTester tester, LatticeController controller) async {
  await tester.pumpWidget(
    MaterialApp(home: LatticeCanvas(controller: controller)),
  );
  // Flush post-frame callbacks (pane-size publish + forced cull refresh).
  await tester.pump();
}

void main() {
  group('gesture router + controller verbs', () {
    testWidgets('tap node selects it', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);
      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();

      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );
    });

    testWidgets('tap empty pane clears with a single emission', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );

      var controllerNotes = 0;
      controller.addListener(() => controllerNotes++);
      var selectionEmissions = 0;
      controller.container.listen<LatticeSelection>(
        latticeSelectionProvider,
        (_, _) => selectionEmissions++,
      );

      await tester.tapAt(const Offset(700, 500));
      await tester.pump();

      expect(
        controller.container.read(latticeSelectionProvider).isEmpty,
        isTrue,
      );
      expect(selectionEmissions, equals(1));
      expect(controllerNotes, equals(0));

      // No-op when already empty: no further emissions.
      await tester.tapAt(const Offset(700, 500));
      await tester.pump();
      expect(selectionEmissions, equals(1));
      expect(controllerNotes, equals(0));
    });

    testWidgets('drag node 100px right: live then single-notify commit',
        (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      var controllerNotes = 0;
      controller.addListener(() => controllerNotes++);

      final gesture = await tester.startGesture(const Offset(150, 120));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();

      final drag = controller.container.read(latticeDragProvider);
      expect(drag.isActive, isTrue);
      expect(drag.livePositions['a'], equals(const Offset(200, 100)));

      await gesture.up();
      await tester.pump();

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(
        controller.container
            .read(latticeDocumentProvider)
            .nodes['a']!
            .position,
        equals(const Offset(200, 100)),
      );
      expect(controllerNotes, equals(1));
    });

    testWidgets('pointer-up outside pane ends drag (no stuck state)',
        (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      final gesture = await tester.startGesture(const Offset(150, 120));
      await gesture.moveBy(const Offset(50, 0));
      await tester.pump();
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isTrue,
      );

      await gesture.moveTo(const Offset(-50, -50));
      await gesture.up();
      await tester.pump();

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
    });
  });

  group('controller drag/marquee verbs (no widgets)', () {
    test('beginNodeDrag selects an unselected node first', () {
      final controller = _seededController();
      addTearDown(controller.dispose);

      controller.beginNodeDrag('b');

      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'b'}),
      );
      final drag = controller.container.read(latticeDragProvider);
      expect(drag.isActive, isTrue);
      expect(drag.livePositions['b'], equals(const Offset(400, 300)));
    });

    test('updateNodeDrag scales screen delta by zoom', () {
      final controller = _seededController();
      addTearDown(controller.dispose);

      controller.container.read(latticeCameraProvider.notifier).zoomBy(2.0);
      controller.beginNodeDrag('a');
      controller.updateNodeDrag(const Offset(20, 0));

      expect(
        controller.container.read(latticeDragProvider).livePositions['a'],
        equals(const Offset(110, 100)),
      );
    });

    test('endNodeDrag with no move skips the commit (silent)', () {
      final controller = _seededController();
      addTearDown(controller.dispose);

      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginNodeDrag('a');
      controller.endNodeDrag();

      expect(notes, equals(0));
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(
        controller.container
            .read(latticeDocumentProvider)
            .nodes['a']!
            .position,
        equals(const Offset(100, 100)),
      );
    });

    test('marquee selects overlapping nodes; append unions', () {
      final controller = _seededController();
      addTearDown(controller.dispose);

      controller.beginMarquee(const Offset(0, 0));
      controller.updateMarquee(const Offset(300, 200));
      controller.endMarquee();

      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );

      // Append unions with the existing selection.
      controller.container
          .read(latticeSelectionProvider.notifier)
          .setSelection(const LatticeSelection(nodes: {'b'}));
      controller.beginMarquee(const Offset(0, 0));
      controller.updateMarquee(const Offset(300, 200));
      controller.endMarquee(append: true);

      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a', 'b'}),
      );
    });
  });
}
