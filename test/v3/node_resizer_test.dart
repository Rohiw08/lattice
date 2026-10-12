import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _resizableNode(
  String id,
  Offset position, {
  Size size = const Size(160, 44),
  Size? minSize,
  Size? maxSize,
  bool keepAspectRatio = false,
}) {
  return LatticeNode(
    id: id,
    type: 'default',
    position: position,
    size: size,
    resizable: true,
    minSize: minSize,
    maxSize: maxSize,
    keepAspectRatio: keepAspectRatio,
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
}

void main() {
  group('node resizer overlay (widget)', () {
    testWidgets(
        'drag bottom-right corner grows node live and commits; undo restores',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [
          _resizableNode('a', const Offset(100, 100)),
        ],
      );
      addTearDown(controller.dispose);
      await _pumpCanvas(tester, controller);

      // Select first: the resizer only mounts handles for a single
      // selection.
      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      for (final LatticeResizeHandle handle in LatticeResizeHandle.values) {
        expect(
          find.byKey(ValueKey<String>('lattice-resize-${handle.name}')),
          findsOneWidget,
        );
      }

      var controllerNotes = 0;
      controller.addListener(() => controllerNotes++);

      // Bottom-right handle center is flow (260, 144); press just inside
      // the node so a node-drag would also be a candidate (priority check).
      final gesture = await tester.startGesture(const Offset(257, 141));
      await gesture.moveBy(const Offset(40, 20));
      await tester.pump();

      final drag = controller.container.read(latticeDragProvider);
      expect(drag.isActive, isTrue);
      expect(drag.liveSizes['a'], equals(const Size(200, 64)));
      // Resize routes through the resizer, not a node drag: position live.
      expect(drag.livePositions['a'], equals(const Offset(100, 100)));
      // Live writes go to the drag session only: document unchanged + zero
      // controller notifications.
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(160, 44)),
      );
      expect(controllerNotes, equals(0));

      await gesture.up();
      await tester.pump();

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(200, 64)),
      );
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(100, 100)),
      );
      expect(controllerNotes, equals(1));

      controller.undo();
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(160, 44)),
      );
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(100, 100)),
      );
    });

    testWidgets('shrinking below minSize clamps', (tester) async {
      final controller = LatticeController(
        initialNodes: [
          _resizableNode(
            'a',
            const Offset(100, 100),
            minSize: const Size(100, 50),
          ),
        ],
      );
      addTearDown(controller.dispose);
      await _pumpCanvas(tester, controller);

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('lattice-resize-bottomRight')),
        findsOneWidget,
      );

      final gesture = await tester.startGesture(const Offset(257, 141));
      await gesture.moveBy(const Offset(-100, -60));
      await tester.pump();

      // Tentative (60, -16) clamps to the node minSize (100, 50).
      expect(
        controller.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(100, 50)),
      );

      await gesture.up();
      await tester.pump();

      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(100, 50)),
      );

      controller.undo();
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(160, 44)),
      );
    });

    testWidgets('aspect lock keeps ratio from drag-start size',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [
          _resizableNode(
            'a',
            const Offset(100, 100),
            size: const Size(160, 80),
            keepAspectRatio: true,
          ),
        ],
      );
      addTearDown(controller.dispose);
      await _pumpCanvas(tester, controller);

      await tester.tapAt(const Offset(180, 140));
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('lattice-resize-bottomRight')),
        findsOneWidget,
      );

      // Bottom-right handle center is flow (260, 180).
      final gesture = await tester.startGesture(const Offset(257, 177));
      // Width delta dominates: scale 200/160 = 1.25 locks height to 100.
      await gesture.moveBy(const Offset(40, 10));
      await tester.pump();

      expect(
        controller.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(200, 100)),
      );

      await gesture.up();
      await tester.pump();

      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(200, 100)),
      );
    });

    testWidgets('resizer hidden for multi-selection', (tester) async {
      final controller = LatticeController(
        initialNodes: [
          _resizableNode('a', const Offset(100, 100)),
          _resizableNode('b', const Offset(400, 300)),
        ],
      );
      addTearDown(controller.dispose);
      await _pumpCanvas(tester, controller);

      controller.select({'a', 'b'});
      await tester.pump();

      for (final LatticeResizeHandle handle in LatticeResizeHandle.values) {
        expect(
          find.byKey(ValueKey<String>('lattice-resize-${handle.name}')),
          findsNothing,
        );
      }
    });

    testWidgets('resizer hidden for non-resizable node', (tester) async {
      final controller = LatticeController(
        initialNodes: [
          const LatticeNode(
            id: 'a',
            type: 'default',
            position: Offset(100, 100),
          ),
        ],
      );
      addTearDown(controller.dispose);
      await _pumpCanvas(tester, controller);

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );

      for (final LatticeResizeHandle handle in LatticeResizeHandle.values) {
        expect(
          find.byKey(ValueKey<String>('lattice-resize-${handle.name}')),
          findsNothing,
        );
      }

      // The verb itself is a no-op too: default is resizable-off.
      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
    });
  });

  group('resize verbs (no widgets)', () {
    test('beginResize no-ops for unknown id', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginResize('missing', LatticeResizeHandle.bottomRight);

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(notes, equals(0));
    });

    test('left handle shifts position; right handle does not', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      controller.beginResize('a', LatticeResizeHandle.left);
      controller.updateResize(const Offset(-20, 0));

      var drag = controller.container.read(latticeDragProvider);
      expect(drag.liveSizes['a'], equals(const Size(180, 44)));
      expect(drag.livePositions['a'], equals(const Offset(80, 100)));

      controller.endResize();
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(180, 44)),
      );
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(80, 100)),
      );

      controller.undo();
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(160, 44)),
      );
      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(100, 100)),
      );
    });

    test('top-left handle shifts both axes', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      controller.beginResize('a', LatticeResizeHandle.topLeft);
      controller.updateResize(const Offset(-20, -10));

      final drag = controller.container.read(latticeDragProvider);
      expect(drag.liveSizes['a'], equals(const Size(180, 54)));
      expect(drag.livePositions['a'], equals(const Offset(80, 90)));
    });

    test('default min clamps at 40x40', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      controller.updateResize(const Offset(-500, -500));

      expect(
        controller.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(40, 40)),
      );
    });

    test('maxSize and canvas-max clamp', () {
      final capped = LatticeController(
        initialNodes: [
          _resizableNode(
            'a',
            const Offset(100, 100),
            maxSize: const Size(200, 100),
          ),
        ],
      );
      addTearDown(capped.dispose);

      capped.beginResize('a', LatticeResizeHandle.bottomRight);
      capped.updateResize(const Offset(500, 500));
      expect(
        capped.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(200, 100)),
      );

      final uncapped = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(uncapped.dispose);

      uncapped.beginResize('a', LatticeResizeHandle.bottomRight);
      uncapped.updateResize(const Offset(5000, 5000));
      expect(
        uncapped.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(2000, 2000)),
      );
    });

    test('updateResize scales screen delta by zoom', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      controller.container.read(latticeCameraProvider.notifier).zoomBy(2.0);
      controller.beginResize('a', LatticeResizeHandle.right);
      controller.updateResize(const Offset(20, 0));

      expect(
        controller.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(170, 44)),
      );
    });

    test('aspect lock follows the dominant axis', () {
      final controller = LatticeController(
        initialNodes: [
          _resizableNode(
            'a',
            const Offset(100, 100),
            size: const Size(160, 80),
            keepAspectRatio: true,
          ),
        ],
      );
      addTearDown(controller.dispose);

      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      controller.updateResize(const Offset(10, 40));

      // Height delta dominates: scale 120/80 = 1.5 locks width to 240.
      expect(
        controller.container.read(latticeDragProvider).liveSizes['a'],
        equals(const Size(240, 120)),
      );
    });

    test('updateResize with no active resize is a no-op', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      var notes = 0;
      controller.addListener(() => notes++);

      controller.updateResize(const Offset(50, 50));

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(160, 44)),
      );
      expect(notes, equals(0));
    });

    test('endResize with no change is silent (no history)', () {
      final controller = LatticeController(
        initialNodes: [_resizableNode('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      var notes = 0;
      controller.addListener(() => notes++);

      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isTrue,
      );
      controller.endResize();

      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      expect(controller.canUndo, isFalse);
      expect(notes, equals(0));
    });
  });
}
