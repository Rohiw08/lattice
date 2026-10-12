import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

/// Depends on [LatticeScope] so scope notifications rebuild it.
class _ScopeProbe extends StatelessWidget {
  const _ScopeProbe({required this.onBuild});

  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    LatticeScope.of(context);
    onBuild();
    return const SizedBox();
  }
}

void main() {
  group('LatticeCanvas', () {
    testWidgets('mounts latticePane and tracks attach state', (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(home: LatticeCanvas(controller: controller)),
      );

      expect(find.byKey(const ValueKey('latticePane')), findsOneWidget);
      expect(controller.isAttached, isTrue);

      await tester.pumpWidget(const SizedBox());
      expect(controller.isAttached, isFalse);
    });

    testWidgets('overlay Consumer reads the seeded node count',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [_node('a'), _node('b'), _node('c')],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: LatticeCanvas(
            controller: controller,
            overlays: [
              Consumer(
                builder: (context, ref, _) {
                  final nodes = ref.watch(latticeNodesProvider);
                  return Text('nodes:${nodes.length}');
                },
              ),
            ],
          ),
        ),
      );

      expect(find.text('nodes:3'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('mounting a second canvas throws StateError', (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: [
              Expanded(child: LatticeCanvas(controller: controller)),
              Expanded(child: LatticeCanvas(controller: controller)),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isStateError);

      await tester.pumpWidget(const SizedBox());
      expect(controller.isAttached, isFalse);
    });

    testWidgets('fresh-but-equal options do not rebuild scope dependents',
        (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      var probeBuilds = 0;
      final probe = _ScopeProbe(onBuild: () => probeBuilds++);
      Widget buildApp() {
        // Fresh instance with equal values on every build (never const).
        controller.options = LatticeOptions();
        return MaterialApp(
          home: LatticeCanvas(controller: controller, overlays: [probe]),
        );
      }

      await tester.pumpWidget(buildApp());
      expect(probeBuilds, equals(1));

      await tester.pumpWidget(buildApp());
      await tester.pumpWidget(buildApp());
      expect(probeBuilds, equals(1));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('LatticeScope.of returns the controller in the subtree',
        (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      LatticeController? seen;
      await tester.pumpWidget(
        MaterialApp(
          home: LatticeCanvas(
            controller: controller,
            overlays: [
              Builder(
                builder: (context) {
                  seen = LatticeScope.of(context);
                  return const SizedBox();
                },
              ),
            ],
          ),
        ),
      );

      expect(seen, same(controller));

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('LatticeScope.of asserts outside a scope', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              LatticeScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(tester.takeException(), isAssertionError);
    });
  });
}
