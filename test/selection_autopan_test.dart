import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

void main() {
  group('RF-aligned defaults', () {
    test('edges do not elevate on select (RF: elevateEdgesOnSelect false)',
        () {
      expect(const EdgeOptions().elevateEdgeOnSelect, isFalse);
    });

    test('edge interactionWidth defaults to RF BaseEdge 20', () {
      const edge = FlowEdge(sourceNodeId: 'a', targetNodeId: 'b', id: 'e');
      expect(edge.interactionWidth, 20.0);
    });

    test('marquee auto-pan defaults on (RF: autoPanOnSelection)', () {
      expect(const ViewportOptions().autoPanOnSelection, isTrue);
    });
  });

  group('autoPanOnSelection', () {
    // NOTE: marquee/deselect gestures only land inside the flow-mapped box
    // (viewport offset maps it on screen), so all drags below stay in the
    // visible bottom-right quadrant. Pane taps outside that box are a
    // separate pre-existing dead zone, unrelated to auto-pan.
    Future<FlowCanvasController> pump(
      WidgetTester tester, {
      bool autoPanOnSelection = true,
    }) async {
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
                  viewportOptions: ViewportOptions(
                    selectionOnDrag: true,
                    autoPanOnSelection: autoPanOnSelection,
                  ),
                ),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'edge_node',
                    type: 'default',
                    // Flow (500,350): outside the initial marquee, revealed
                    // only once auto-pan extends it.
                    position: Offset(500, 350),
                    size: Size(60, 40),
                    data: 'E',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      return controller;
    }

    /// Drags from in-box empty space into the bottom-right margin and holds.
    Future<void> dragIntoMargin(WidgetTester tester) async {
      // Screen (450,350) → flow (50,50); screen (795,595) is deep in the
      // auto-pan margin with the default 800×600 viewport.
      final gesture = await tester.startGesture(const Offset(450, 350));
      await tester.pump();
      await gesture.moveTo(const Offset(795, 595));
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
      await gesture.up();
      await tester.pump();
    }

    testWidgets('marquee held in the margin pans and extends', (tester) async {
      final controller = await pump(tester);
      final before = controller.currentState.viewport.offset;

      await dragIntoMargin(tester);

      expect(
        controller.currentState.viewport.offset,
        isNot(equals(before)),
        reason: 'marquee in margin should auto-pan',
      );
    });

    testWidgets('opt-out disables marquee auto-pan', (tester) async {
      final controller = await pump(tester, autoPanOnSelection: false);
      final before = controller.currentState.viewport.offset;

      await dragIntoMargin(tester);

      expect(controller.currentState.viewport.offset, equals(before));
    });

    testWidgets('marquee covers nodes revealed by the pan', (tester) async {
      final controller = await pump(tester);

      final gesture = await tester.startGesture(const Offset(450, 350));
      await tester.pump();
      await gesture.moveTo(const Offset(795, 595));
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 32));
      }
      await gesture.up();
      await tester.pump();

      // The offscreen node entered the grown marquee while panning.
      expect(
        controller.currentState.selectedNodes,
        contains('edge_node'),
      );
    });
  });
}
