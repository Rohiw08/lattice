// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Unit 2 regression: node drag under viewport culling must NOT mass-mount.
///
/// Before the fix, culling was wholesale-disabled while `dragMode ==
/// DragMode.node`, so grabbing one node on a culled canvas mounted **every**
/// node in a single pump (the drag-start spike). The fix freezes the pre-drag
/// visible set and mounts only `frozen ∪ dragAffected ∪ selected` for the
/// drag's duration — no mid-drag spatial query, no mass-mount.
///
/// A second case guards the `dragAffected` correctness fix: a parent dragging
/// an off-screen descendant must keep that descendant mounted (it rides along
/// via relative position), even though it was culled at rest.

Future<FlowCanvasController> _pump(
  WidgetTester tester,
  List<FlowNode<String>> nodes,
) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          // initialState skips auto-centering: flow coords == screen coords.
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {for (final n in nodes) n.id: n},
          ),
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: true,
            ),
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

Offset _viewportCenter(FlowCanvasController controller, String id) {
  final n = controller.currentState.nodes[id]!;
  return controller.viewport.flowToViewport(
    n.position + Offset(n.size.width / 2, n.size.height / 2),
  );
}

int _mountedNodes() => find.byType(BaseNode).evaluate().length;

void main() {
  group('cull drag freeze (Unit 2)', () {
    testWidgets('grabbing a visible node does not mass-mount culled nodes',
        (tester) async {
      // 3 nodes near the origin (visible), 17 far past the mount band
      // (renderCullingPadding 200 + nodeMountExtraPadding 400 = 600).
      final nodes = <FlowNode<String>>[
        for (var i = 0; i < 3; i++)
          FlowNode<String>(
            id: 'near-$i',
            type: 'default',
            position: Offset(20.0 + i * 90, 20),
            size: const Size(50, 30),
            data: 'near-$i',
          ),
        for (var i = 0; i < 17; i++)
          FlowNode<String>(
            id: 'far-$i',
            type: 'default',
            position: Offset(4000.0 + i * 90, 4000),
            size: const Size(50, 30),
            data: 'far-$i',
          ),
      ];
      final controller = await _pump(tester, nodes);

      final restCount = _mountedNodes();
      expect(restCount, lessThan(nodes.length),
          reason: 'far nodes must be culled at rest');

      // Grab a visible, initially-unselected node and hold the drag.
      final gesture =
          await tester.startGesture(_viewportCenter(controller, 'near-0'));
      await tester.pump();
      // Cross the drag slop so onNodeDragStart fires (select + dragMode=node).
      for (var s = 0; s < 6; s++) {
        await gesture.moveBy(const Offset(8, 0));
        await tester.pump();
      }

      // Precondition: the drag must actually be active, else the count
      // assertions below would pass vacuously.
      expect(controller.currentState.dragMode, DragMode.node,
          reason: 'drag must be active for this test to mean anything');

      final dragCount = _mountedNodes();
      expect(dragCount, lessThan(nodes.length),
          reason: 'drag-start must NOT mount all ${nodes.length} nodes');
      // Freeze reuses the pre-drag set (+ the dragged node, already visible),
      // so the count should not balloon.
      expect(dragCount, lessThanOrEqualTo(restCount + 1),
          reason: 'frozen visible set + dragged node only');

      await gesture.up();
      await tester.pump();
    });

    testWidgets('parent drag keeps an off-screen descendant mounted',
        (tester) async {
      // Parent visible at origin; child positioned relative to it, far off
      // screen so it is culled at rest. Dragging the parent must keep the
      // child mounted (it rides along via relative position → dragAffected).
      final nodes = <FlowNode<String>>[
        FlowNode<String>(
          id: 'parent',
          type: 'default',
          position: const Offset(40, 40),
          size: const Size(80, 50),
          data: 'parent',
        ),
        FlowNode<String>(
          id: 'child',
          type: 'default',
          parentId: 'parent',
          position: const Offset(3000, 3000),
          size: const Size(50, 30),
          data: 'child',
        ),
      ];
      final controller = await _pump(tester, nodes);

      expect(find.byKey(const ValueKey('middle_child')), findsNothing,
          reason: 'off-screen child is culled at rest');

      final gesture =
          await tester.startGesture(_viewportCenter(controller, 'parent'));
      await tester.pump();
      for (var s = 0; s < 6; s++) {
        await gesture.moveBy(const Offset(8, 0));
        await tester.pump();
      }

      expect(controller.currentState.dragMode, DragMode.node,
          reason: 'parent drag must be active');
      expect(find.byKey(const ValueKey('middle_child')), findsOneWidget,
          reason: 'dragged parent must keep its descendant mounted so its '
              'movement renders (dragAffected union)');

      await gesture.up();
      await tester.pump();
    });
  });
}
