import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, Offset position) {
  return LatticeNode(id: id, type: 'default', position: position);
}

/// Nodes 'a' at (0,0) and 'b' at (2000,1000): content bounds
/// (0,0)-(2160,1044), wider than the 800x600 test surface so fitView
/// must zoom out (zoom <= 1.0).
LatticeController _wideController() {
  return LatticeController(
    initialNodes: [
      _node('a', Offset.zero),
      _node('b', const Offset(2000, 1000)),
    ],
  );
}

Future<void> _pumpCanvasWithControls(
  WidgetTester tester,
  LatticeController controller,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeCanvas(
        controller: controller,
        overlays: const <Widget>[LatticeControls()],
      ),
    ),
  );
  // Flush post-frame callbacks (pane-size publish + forced cull refresh).
  await tester.pump();
  await tester.pump();
}

LatticeViewportValue _cameraViewport(LatticeController controller) {
  return controller.container.read(latticeCameraProvider.notifier).viewport;
}

Future<void> _flushCameraSettle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump();
}

void main() {
  group('toolbar + panel', () {
    testWidgets('zoom-in button increases camera zoom', (tester) async {
      final controller = _wideController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithControls(tester, controller);
      expect(_cameraViewport(controller).zoom, equals(1.0));

      await tester.tap(find.byKey(const ValueKey<String>('latticeZoomIn')));
      await tester.pump();

      expect(_cameraViewport(controller).zoom, equals(1.25));

      await tester.tap(find.byKey(const ValueKey<String>('latticeZoomOut')));
      await tester.pump();

      expect(_cameraViewport(controller).zoom, closeTo(1.0, 1e-9));
      await _flushCameraSettle(tester);
    });

    testWidgets('fit button fits seeded nodes inside the pane',
        (tester) async {
      final controller = _wideController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithControls(tester, controller);

      await tester.tap(find.byKey(const ValueKey<String>('latticeFitView')));
      await tester.pump();

      final LatticeViewportValue viewport = _cameraViewport(controller);
      expect(viewport.zoom, lessThanOrEqualTo(1.0));

      final Matrix4 matrix =
          controller.container.read(latticeCameraProvider);
      final Map<String, LatticeNode> nodes =
          controller.container.read(latticeDocumentProvider).nodes;
      const Rect pane = Rect.fromLTWH(0, 0, 800, 600);
      for (final String id in nodes.keys) {
        final Rect mapped = MatrixUtils.transformRect(
          matrix,
          latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero),
        );
        expect(mapped.left, greaterThanOrEqualTo(-1e-6));
        expect(mapped.top, greaterThanOrEqualTo(-1e-6));
        expect(mapped.right, lessThanOrEqualTo(800.0 + 1e-6));
        expect(mapped.bottom, lessThanOrEqualTo(600.0 + 1e-6));
      }
      expect(pane.contains(const Offset(400, 300)), isTrue);
      await _flushCameraSettle(tester);
    });

    testWidgets('lock toggle blocks drags while tap-select still works',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [_node('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      await _pumpCanvasWithControls(tester, controller);

      await tester.tap(find.byKey(const ValueKey<String>('latticeLock')));
      await tester.pump();
      expect(controller.isLocked, isTrue);

      final gesture = await tester.startGesture(const Offset(150, 120));
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(
        controller.container
            .read(latticeDocumentProvider)
            .nodes['a']!
            .position,
        equals(const Offset(100, 100)),
      );

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );
      await _flushCameraSettle(tester);
    });

    testWidgets('panel positions child at the requested corner',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Stack(
            children: <Widget>[
              LatticePanel(
                position: LatticePanelPosition.topLeft,
                child: Text('tl'),
              ),
              LatticePanel(
                position: LatticePanelPosition.bottomRight,
                child: Text('br'),
              ),
            ],
          ),
        ),
      );

      final topLeft = tester.widget<Positioned>(
        find.ancestor(
          of: find.text('tl'),
          matching: find.byType(Positioned),
        ),
      );
      expect(topLeft.top, equals(16.0));
      expect(topLeft.left, equals(16.0));

      final bottomRight = tester.widget<Positioned>(
        find.ancestor(
          of: find.text('br'),
          matching: find.byType(Positioned),
        ),
      );
      expect(bottomRight.bottom, equals(16.0));
      expect(bottomRight.right, equals(16.0));
    });

    test('empty document fitView is a no-op with no notify', () {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      final Matrix4 before =
          controller.container.read(latticeCameraProvider);
      controller.fitView();
      expect(controller.container.read(latticeCameraProvider), equals(before));
      expect(notifications, equals(0));
    });

    test('saveViewport copies the camera into the document, history-free',
        () {
      final controller = _wideController();
      addTearDown(controller.dispose);

      controller.zoomIn();
      final LatticeViewportValue camera = _cameraViewport(controller);
      expect(
        controller.container.read(latticeDocumentProvider).viewport,
        isNot(equals(camera)),
      );

      var notifications = 0;
      controller.addListener(() => notifications++);
      expect(controller.canUndo, isFalse);

      controller.saveViewport();
      expect(
        controller.container.read(latticeDocumentProvider).viewport,
        equals(camera),
      );
      expect(notifications, equals(1));
      expect(controller.canUndo, isFalse);
    });

    test('locked zoom and fit verbs no-op', () {
      final controller = _wideController();
      addTearDown(controller.dispose);

      controller.toggleLock();
      expect(controller.isLocked, isTrue);

      final Matrix4 before =
          controller.container.read(latticeCameraProvider);
      controller.zoomIn();
      controller.zoomOut();
      controller.fitView();
      expect(controller.container.read(latticeCameraProvider), equals(before));
    });
  });
}
