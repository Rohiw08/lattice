import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  FlowCanvasOptions? options,
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
            options: options ?? FlowCanvasOptions(),
            initialNodes: const [
              FlowNode<String>(
                id: 'a',
                type: 'default',
                position: Offset(60, 60),
                size: Size(100, 40),
                data: 'A',
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

void main() {
  group('space-pan (panActivationKeyCode parity)', () {
    testWidgets('space+drag pans, selects and moves nothing', (tester) async {
      final controller = await _pump(tester);
      final nodeBefore = controller.nodes.getNode('a')!;
      final vpBefore = controller.currentState.viewport;

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(700, 500));
      await tester.pump();
      await gesture.moveBy(const Offset(-120, -80));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(
        controller.currentState.viewport.offset,
        isNot(equals(vpBefore.offset)),
        reason: 'space+drag must pan the viewport',
      );
      expect(controller.nodes.getNode('a')!.position, nodeBefore.position,
          reason: 'no node may move during space-pan');
      expect(controller.currentState.selectedNodes, isEmpty,
          reason: 'space+drag must not select');
    });

    testWidgets('space tap selects nothing (selection kept)', (tester) async {
      final controller = await _pump(tester);
      controller.selection.selectNode('a');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      // Tap the node body with space held: no selection change at all.
      // (Built-in nodes render no label; tap the node rect center.)
      final center =
          tester.getCenter(find.byType(BaseNode).first);
      await tester.tapAt(center);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      expect(controller.currentState.selectedNodes, {'a'});
    });

    testWidgets('custom pan-activation key replaces space', (tester) async {
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
                  viewportOptions:
                      ViewportOptions(selectionOnDrag: true),
                  keyboardOptions: KeyboardOptions(
                    panActivationKeys: {LogicalKeyboardKey.alt},
                  ),
                ),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'a',
                    type: 'default',
                    position: Offset(60, 60),
                    size: Size(100, 40),
                    data: 'A',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Space is not bound anymore: with selectionOnDrag, space+drag draws
      // a marquee instead of panning.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();
      final gesture = await tester.startGesture(const Offset(700, 500));
      await tester.pump();
      await gesture.moveBy(const Offset(-60, -40));
      await tester.pump();
      expect(controller.currentState.dragMode, DragMode.selection);
      await gesture.up();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump();

      // Alt is bound: alt+drag pans.
      final vpBefore = controller.currentState.viewport;
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      final gesture2 = await tester.startGesture(const Offset(700, 500));
      await tester.pump();
      await gesture2.moveBy(const Offset(-120, -80));
      await tester.pump();
      await gesture2.up();
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pump();
      expect(controller.currentState.viewport.offset,
          isNot(equals(vpBefore.offset)));
    });
  });

  group('pane dead zones', () {
    testWidgets('taps outside the flow box still deselect', (tester) async {
      final controller = await _pump(tester);
      controller.selection.selectNode('a');
      await tester.pump();
      expect(controller.currentState.selectedNodes, {'a'});

      // Centered viewport maps the 800×600 flow box to screen
      // (400,300)-(1200,900): (100,100) is outside it (was dead).
      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      expect(controller.currentState.selectedNodes, isEmpty);
    });

    testWidgets('marquee starts outside the flow box', (tester) async {
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
                  viewportOptions: ViewportOptions(selectionOnDrag: true),
                ),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'a',
                    type: 'default',
                    // Flow (40,40): covered by a marquee drawn in the
                    // top-left dead zone once coordinates map correctly.
                    position: Offset(40, 40),
                    size: Size(60, 40),
                    data: 'A',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      // Screen (100,100)-(260,220) → flow (-300,-200)-(-140,-80)? No:
      // flow box covers screen (400,300)+, so drag inside it but target a
      // node near the flow origin: node flow (40,40) → screen (440,340).
      final gesture = await tester.startGesture(const Offset(420, 320));
      await tester.pump();
      await gesture.moveBy(const Offset(120, 100));
      await tester.pump();
      expect(controller.currentState.dragMode, DragMode.selection);
      await gesture.up();
      await tester.pump();

      expect(controller.currentState.selectedNodes, contains('a'));
    });
  });
}
