import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show Tristate;
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Accessibility parity: focus traversal, Enter/Space selection,
/// Shift-boost arrows, auto-pan on focus, semantics labels, live
/// announcements, reduced motion, minimap label.
List<FlowNode<Object>> _nodes() => const <FlowNode<Object>>[
      FlowNode<String>(
        id: 'a',
        type: 'input',
        position: Offset(80, 120),
        data: 'A',
        semanticsLabel: 'Custom A',
      ),
      FlowNode<String>(
        id: 'b',
        type: 'output',
        position: Offset(320, 120),
        data: 'B',
      ),
      FlowNode<String>(
        id: 'c',
        type: 'output',
        position: Offset(320, 300),
        data: 'C',
        focusable: false,
      ),
    ];

const _edges = <FlowEdge>[
  FlowEdge(
    id: 'e1',
    sourceNodeId: 'a',
    targetNodeId: 'b',
    sourceHandleId: 'source',
    targetHandleId: 'target',
  ),
];

Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  FlowCanvasOptions? options,
  List<Widget> overlays = const [],
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            // Plain defaults: shortcuts ship enabled out of the box.
            options: options ?? FlowCanvasOptions(),
            initialNodes: _nodes(),
            initialEdges: _edges,
            overlays: overlays,
          ),
        ),
      ),
    ),
  );
}

String? _focusedLabel() =>
    FocusManager.instance.primaryFocus?.debugLabel;

Future<List<String?>> _tabThrough(WidgetTester tester, int count) async {
  final seen = <String?>[];
  for (var i = 0; i < count; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    seen.add(_focusedLabel());
  }
  return seen;
}

void main() {
  group('focus traversal', () {
    testWidgets('Tab walks nodes spatially, skips focusable:false',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final seen = await _tabThrough(tester, 5);
      // First stop is node A (top-left in reading order).
      expect(seen.first, 'flow-node-a');
      // B and the edge anchor are both reachable…
      expect(seen, contains('flow-node-b'));
      expect(seen, contains('flow-edge-e1'));
      // …but the focusable:false node never takes focus.
      expect(seen, isNot(contains('flow-node-c')));
    });
  });

  group('Enter/Space selection', () {
    testWidgets('Enter selects the focused node', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      // Tab until node A is focused.
      for (var i = 0; i < 5 && _focusedLabel() != 'flow-node-a'; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_focusedLabel(), 'flow-node-a');

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(controller.currentState.selectedNodes, contains('a'));
    });
  });

  group('arrow keys', () {
    testWidgets('plain arrows move 10px, Shift boosts 5x', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        controller.nodes.getNode('a')!.position,
        const Offset(90, 120),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pump();
      expect(
        controller.nodes.getNode('a')!.position,
        const Offset(140, 120),
      );
    });
  });

  group('autoPanOnNodeFocus', () {
    testWidgets('focusing an off-screen node pans it into view',
        (tester) async {
      final controller = FlowCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                controller: controller,
                theme: FlowCanvasTheme.dark(),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'near',
                    type: 'default',
                    position: Offset(80, 120),
                    data: 'near',
                  ),
                  FlowNode<String>(
                    id: 'far',
                    type: 'default',
                    position: Offset(3000, 2000),
                    data: 'far',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final before = controller.currentState.viewport.offset;
      for (var i = 0; i < 4 && _focusedLabel() != 'flow-node-far'; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_focusedLabel(), 'flow-node-far');
      expect(controller.currentState.viewport.offset, isNot(equals(before)));
    });

    testWidgets('disabled option leaves the viewport alone', (tester) async {
      final controller = FlowCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                controller: controller,
                theme: FlowCanvasTheme.dark(),
                options: FlowCanvasOptions(
                  a11yOptions: A11yOptions(autoPanOnNodeFocus: false),
                ),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'near',
                    type: 'default',
                    position: Offset(80, 120),
                    data: 'near',
                  ),
                  FlowNode<String>(
                    id: 'far',
                    type: 'default',
                    position: Offset(3000, 2000),
                    data: 'far',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final before = controller.currentState.viewport.offset;
      for (var i = 0; i < 4 && _focusedLabel() != 'flow-node-far'; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
      }
      expect(_focusedLabel(), 'flow-node-far');
      expect(controller.currentState.viewport.offset, equals(before));
    });
  });

  group('semantics', () {
    testWidgets('nodes and edges expose labels + selection', (tester) async {
      final controller = FlowCanvasController();
      final handle = tester.ensureSemantics();
      try {
        await _pump(tester, controller: controller);
        await tester.pump();

        // Explicit semanticsLabel wins…
        expect(find.bySemanticsLabel('Custom A'), findsOneWidget);
        // …String data is the fallback, edge ids get an "Edge" prefix.
        expect(find.bySemanticsLabel('B'), findsOneWidget);
        expect(find.bySemanticsLabel('Edge e1'), findsOneWidget);

        controller.selection.selectNode('a');
        await tester.pump();
        final node = tester.getSemantics(find.bySemanticsLabel('Custom A'));
        expect(node.flagsCollection.isSelected, Tristate.isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('minimap carries its label', (tester) async {
      final controller = FlowCanvasController();
      final handle = tester.ensureSemantics();
      try {
        await _pump(
          tester,
          controller: controller,
          overlays: const [FlowMiniMap()],
        );
        await tester.pump();
        expect(find.bySemanticsLabel('Minimap'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  group('live announcements', () {
    testWidgets('keyboard move + delete announce', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(
        find.text('Moved selection right. New position, x: 90, y: 120'),
        findsOneWidget,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      // Node A plus its attached edge.
      expect(find.text('Deleted 2 selected elements'), findsOneWidget);
    });

    testWidgets('announcements:false stays silent', (tester) async {
      final controller = FlowCanvasController();
      await _pump(
        tester,
        controller: controller,
        options: FlowCanvasOptions(
          a11yOptions: const A11yOptions(announcements: false),
        ),
      );
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(find.textContaining('Moved selection'), findsNothing);
    });
  });

  group('reduced motion', () {
    testWidgets('disableAnimations removes the edge ticker', (tester) async {
      Widget canvas(FlowCanvasController controller) => MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 600,
                child: FlowCanvas(
                  controller: controller,
                  theme: FlowCanvasTheme.dark(),
                  initialNodes: const [
                    FlowNode<String>(
                      id: 'a',
                      type: 'input',
                      position: Offset(80, 120),
                      data: 'A',
                    ),
                    FlowNode<String>(
                      id: 'b',
                      type: 'output',
                      position: Offset(320, 120),
                      data: 'B',
                    ),
                  ],
                  initialEdges: const [
                    FlowEdge(
                      id: 'e1',
                      sourceNodeId: 'a',
                      targetNodeId: 'b',
                      sourceHandleId: 'source',
                      targetHandleId: 'target',
                      animated: true,
                    ),
                  ],
                ),
              ),
            ),
          );

      // Animated canvas drives edges from a ticker-backed builder (plus
      // framework builders unrelated to edges)…
      final animated = FlowCanvasController();
      await tester.pumpWidget(canvas(animated));
      await tester.pump();
      final animatedBuilders =
          find.byType(AnimatedBuilder).evaluate().length;
      expect(animatedBuilders, greaterThan(0));

      // …while reduced motion removes exactly the edge builder: one static
      // frame, no ticker.
      final still = FlowCanvasController();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: canvas(still),
        ),
      );
      await tester.pump();
      expect(
        find.byType(AnimatedBuilder).evaluate().length,
        animatedBuilders - 1,
      );
      // …but the edge still paints.
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
