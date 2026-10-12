import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

List<LatticeNode> _gridNodes(
  int count, {
  int columns = 25,
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

int _mountedCount(WidgetTester tester, int count) {
  var mounted = 0;
  for (int i = 0; i < count; i++) {
    if (find.byKey(ValueKey('n$i')).evaluate().isNotEmpty) mounted++;
  }
  return mounted;
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  LatticeController controller, {
  Map<String, LatticeNodeBuilder> nodeBuilders = const {},
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeCanvas(controller: controller, nodeBuilders: nodeBuilders),
    ),
  );
  await tester.pump();
}

void main() {
  group('LatticeNodeLayer culling', () {
    testWidgets('pane shows only the visible subset of 500 nodes',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(500));
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);

      final mounted = _mountedCount(tester, 500);
      expect(mounted, greaterThan(0));
      expect(mounted, lessThan(500));
    });

    testWidgets('off-screen selected node stays mounted', (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(500));
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);
      expect(find.byKey(const ValueKey('n499')), findsNothing);

      controller.container
          .read(latticeSelectionProvider.notifier)
          .setSelection(const LatticeSelection(nodes: {'n499'}));
      await tester.pump();

      expect(find.byKey(const ValueKey('n499')), findsOneWidget);
    });

    testWidgets('removing a node leaves no stale shell', (tester) async {
      final nodes = _gridNodes(500);
      final controller = LatticeController(initialNodes: nodes);
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);
      expect(find.byKey(const ValueKey('n0')), findsOneWidget);

      controller.setNodes(nodes.where((node) => node.id != 'n0'));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const ValueKey('n0')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('first frame already culled, never the full 500',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(500));
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: LatticeCanvas(controller: controller)),
      );

      // Post-frame forced refresh runs inside pumpWidget: the provider
      // state is already culled before the next frame paints it.
      expect(
        controller.container.read(latticeCullProvider).length,
        lessThan(500),
      );

      await tester.pump();
      final mounted = _mountedCount(tester, 500);
      expect(mounted, greaterThan(0));
      expect(mounted, lessThan(500));
    });

    testWidgets('camera pans do not rebuild the node layer (2500 nodes)',
        (tester) async {
      final controller =
          LatticeController(initialNodes: _gridNodes(2500, columns: 50));
      addTearDown(controller.dispose);

      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: LatticeCanvas(
            controller: controller,
            nodeBuilders: <String, LatticeNodeBuilder>{
              'default': (context, node, selected) {
                builds++;
                return const SizedBox();
              },
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(builds, greaterThan(0));

      final camera =
          controller.container.read(latticeCameraProvider.notifier);

      camera.panBy(const Offset(50, 0));
      await tester.pump();
      final buildsAfterPan1 = builds;
      final cullAfterPan1 =
          Set<String>.of(controller.container.read(latticeCullProvider));
      expect(cullAfterPan1, isNotEmpty);
      expect(cullAfterPan1.length, lessThan(2500));

      for (var i = 1; i < 20; i++) {
        camera.panBy(const Offset(50, 0));
        await tester.pump();
      }

      expect(builds, equals(buildsAfterPan1));
      expect(
        controller.container.read(latticeCullProvider),
        equals(cullAfterPan1),
      );

      // Flush the camera settle timer so no fake-async timer is pending
      // at teardown. Assertions above already pinned the pan-flat behavior.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
    });
  });
}
