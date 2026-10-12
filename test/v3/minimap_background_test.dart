import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

List<LatticeNode> _gridNodes(
  int count, {
  int columns = 50,
  double gap = 300.0,
}) {
  return <LatticeNode>[
    for (int i = 0; i < count; i++)
      LatticeNode(
        id: 'n$i',
        type: 'default',
        position: Offset((i % columns) * gap, (i ~/ columns) * gap),
      ),
  ];
}

Future<void> _pumpCanvasWithOverlays(
  WidgetTester tester,
  LatticeController controller,
  List<Widget> overlays,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeCanvas(controller: controller, overlays: overlays),
    ),
  );
  await tester.pump();
}

void main() {
  group('LatticeMinimap + LatticeBackground', () {
    testWidgets('minimap renders with 2500 nodes and mounts zero node shells',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(2500));
      addTearDown(controller.dispose);

      await _pumpCanvasWithOverlays(
        tester,
        controller,
        const <Widget>[LatticeMinimap()],
      );

      expect(find.byType(LatticeMinimap), findsOneWidget);
      // The minimap paints rects only: no node shell widgets in its subtree.
      expect(
        find.descendant(
          of: find.byType(LatticeMinimap),
          matching: find.byKey(const ValueKey<String>('n0')),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: find.byType(LatticeMinimap),
          matching: find.byKey(const ValueKey<String>('n2499')),
        ),
        findsNothing,
      );
    });

    testWidgets('minimap paints a keyed viewport rect', (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(10));
      addTearDown(controller.dispose);

      await _pumpCanvasWithOverlays(
        tester,
        controller,
        const <Widget>[LatticeMinimap()],
      );

      expect(
        find.byKey(const ValueKey<String>('minimapViewport')),
        findsOneWidget,
      );
    });

    testWidgets('drag on minimap changes the camera', (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(100));
      addTearDown(controller.dispose);

      await _pumpCanvasWithOverlays(
        tester,
        controller,
        const <Widget>[LatticeMinimap()],
      );

      final LatticeViewportValue before = controller
          .container
          .read(latticeCameraProvider.notifier)
          .viewport;

      await tester.drag(find.byType(LatticeMinimap), const Offset(20, 20));
      await tester.pump();

      final LatticeViewportValue after = controller
          .container
          .read(latticeCameraProvider.notifier)
          .viewport;
      expect(after.offset, isNot(equals(before.offset)));

      // Flush the camera settle timer so no fake-async timer is pending
      // at teardown.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
    });

    testWidgets('onViewportChange fires on drag end; null-safe without it',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(100));
      addTearDown(controller.dispose);

      LatticeViewportValue? seen;
      await _pumpCanvasWithOverlays(
        tester,
        controller,
        <Widget>[
          LatticeMinimap(
            onViewportChange: (LatticeViewportValue v) => seen = v,
          ),
        ],
      );

      await tester.drag(find.byType(LatticeMinimap), const Offset(-15, 10));
      await tester.pump();

      expect(seen, isNotNull);
      expect(
        seen,
        equals(
          controller.container
              .read(latticeCameraProvider.notifier)
              .viewport,
        ),
      );

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
    });

    testWidgets(
        'background renders dots and emits zero document notifications '
        'during 20 camera pans', (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(100));
      addTearDown(controller.dispose);

      await _pumpCanvasWithOverlays(
        tester,
        controller,
        const <Widget>[LatticeBackground()],
      );

      expect(find.byType(LatticeBackground), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(LatticeBackground),
          matching: find.byType(CustomPaint),
        ),
        findsWidgets,
      );

      var notifications = 0;
      controller.addListener(() => notifications++);

      final camera =
          controller.container.read(latticeCameraProvider.notifier);
      for (var i = 0; i < 20; i++) {
        camera.panBy(const Offset(50, 0));
        await tester.pump();
      }
      expect(notifications, equals(0));

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
    });
  });
}
