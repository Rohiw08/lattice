import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Regression test: first node drag on a fresh canvas with viewport culling.
///
/// Bug: with `onlyRenderVisibleElements: true`, the first drag's selection +
/// dragMode emissions rebuilt the node layer through a toggled
/// `ListenableBuilder` wrapper (conditioned on `viewportSize`), which
/// wholesale-unmounted every node shell mid-gesture. The in-flight gesture
/// recognizer was disposed: moves/up never arrived, displacement read 0.0,
/// and the drag stuck in `DragMode.node`.
///
/// Fixed contract: the cull transform-listener wrapper is keyed on the
/// *option* only and never toggles, so the dragged shell (and its
/// recognizer) survives dragStart's emissions. The drag commits, the mode
/// resets, and a second drag on the same canvas works too.
Future<FlowCanvasController> _pumpCullCanvas(WidgetTester tester) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: true,
            ),
          ),
          initialNodes: const [
            FlowNode<String>(
              id: 'node-0',
              type: 'default',
              position: Offset(0, 0),
              size: Size(50, 30),
              data: 'node-0',
            ),
            FlowNode<String>(
              id: 'node-1',
              type: 'default',
              position: Offset(100, 0),
              size: Size(50, 30),
              data: 'node-1',
            ),
            FlowNode<String>(
              id: 'node-2',
              type: 'default',
              position: Offset(200, 0),
              size: Size(50, 30),
              data: 'node-2',
            ),
          ],
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

Offset _nodeCenter(FlowCanvasController controller, String id) {
  final node = controller.currentState.nodes[id]!;
  return controller.viewport.flowToViewport(
    node.position + Offset(node.size.width / 2, node.size.height / 2),
  );
}

Future<double> _dragNodeBy(
  WidgetTester tester,
  FlowCanvasController controller,
  String id,
  Offset total,
) async {
  final before = controller.currentState.nodes[id]!.position.dx;
  final gesture = await tester.startGesture(_nodeCenter(controller, id));
  await tester.pump();
  for (var step = 0; step < 10; step++) {
    await gesture.moveBy(Offset(total.dx / 10, total.dy / 10));
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
  return controller.currentState.nodes[id]!.position.dx - before;
}

void main() {
  group('cull first-drag', () {
    testWidgets('fresh-canvas drag commits and resets drag mode',
        (tester) async {
      final controller = await _pumpCullCanvas(tester);

      final dx = await _dragNodeBy(
          tester, controller, 'node-0', const Offset(100, 0));

      expect(dx, greaterThan(5.0), reason: 'drag must displace node-0');
      expect(controller.currentState.selectedNodes.contains('node-0'), isTrue);
      expect(controller.currentState.dragMode, DragMode.none,
          reason: 'drop must end the drag session, not stick in node mode');
    });

    testWidgets('second drag on the same culled canvas also commits',
        (tester) async {
      final controller = await _pumpCullCanvas(tester);

      final dx0 = await _dragNodeBy(
          tester, controller, 'node-0', const Offset(100, 0));
      expect(dx0, greaterThan(5.0));

      final dx1 = await _dragNodeBy(
          tester, controller, 'node-1', const Offset(100, 0));
      expect(dx1, greaterThan(5.0));
      expect(controller.currentState.dragMode, DragMode.none);
    });
  });
}
