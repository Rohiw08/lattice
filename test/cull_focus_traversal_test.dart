import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Unit 4 acceptance: keyboard focus-via-pan survives viewport culling.
///
/// With `onlyRenderVisibleElements: true`, an offscreen node's heavy *body*
/// is not mounted — so its FocusNode cannot live there. The always-mounted
/// [FlowNodeA11yLayer] proxy keeps one `flow-node-<id>` focus target per node
/// regardless of culling, so Tab still reaches the offscreen node and
/// `autoPanOnNodeFocus` pans it into view. Guards the whole point of the
/// "preserve focus-via-pan" decision: culling must not break a11y traversal.

String? _focusedLabel() => FocusManager.instance.primaryFocus?.debugLabel;

Future<FlowCanvasController> _pump(WidgetTester tester) async {
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
                minZoom: 0.2,
                onlyRenderVisibleElements: true,
              ),
            ),
            initialNodes: const [
              FlowNode<String>(
                id: 'near',
                type: 'default',
                position: Offset(80, 120),
                size: Size(120, 60),
                data: 'near',
              ),
              FlowNode<String>(
                id: 'far',
                type: 'default',
                position: Offset(3000, 2000),
                size: Size(120, 60),
                data: 'far',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  while (tester.binding.hasScheduledFrame) {
    await tester.pump();
  }
  return controller;
}

void main() {
  testWidgets('Tab reaches an offscreen node under culling and pans it in',
      (tester) async {
    final controller = await _pump(tester);

    // Precondition: the far body is culled (not mounted), while its proxy is.
    expect(find.byKey(const ValueKey('middle_far')), findsNothing,
        reason: 'far node body must be culled at rest');
    expect(find.byKey(const ValueKey('node-a11y-far')), findsOneWidget,
        reason: 'far node proxy is always mounted');

    final before = controller.currentState.viewport.offset;

    // Tab until the far node's proxy takes focus.
    for (var i = 0; i < 6 && _focusedLabel() != 'flow-node-far'; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(_focusedLabel(), 'flow-node-far',
        reason: 'Tab must reach the offscreen node via its proxy');

    // Focus panned it into view (autoPanOnNodeFocus default on).
    expect(controller.currentState.viewport.offset, isNot(equals(before)),
        reason: 'focusing the offscreen node must pan it into view');

    // Enter selects it (the proxy owns Enter/Space).
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(controller.currentState.selectedNodes, contains('far'));
  });
}
