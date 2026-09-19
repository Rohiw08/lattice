// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('resize handle is draggable from the part OUTSIDE the node box',
      (tester) async {
    final nodes = [
      FlowNode<String>(
        id: 'n',
        type: 'default',
        position: const Offset(50, 50),
        size: const Size(200, 100),
        // Resizing is opt-in (RF parity): the resizer only mounts for it.
        resizable: true,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            initialNodes: nodes,
          ),
        ),
      ),
    );
    await tester.pump();

    // Select the node so the resizer appears.
    await tester.tapAt(tester.getRect(find.byType(BaseNode).first).center);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BaseNode).first),
    );

    NodeResizeHandle bottomRightHandle() => tester
        .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
        .firstWhere((h) => h.direction == Alignment.bottomRight);

    // Fresh rects — the node grows on every drag, so widgets rebuild.
    Rect visualRect() => tester.getRect(
          find.descendant(
            of: find.byWidget(bottomRightHandle()),
            matching: find.byType(AnimatedContainer),
          ),
        );

    Size size() =>
        container.read(internalControllerProvider).nodes['n']!.size;

    Future<void> dragFrom(Offset start) async {
      final gesture = await tester.startGesture(start);
      await tester.pump();
      for (var i = 0; i < 10; i++) {
        await gesture.moveBy(const Offset(6, 4));
        await tester.pump();
      }
      await gesture.up();
      await tester.pump();
    }

    // Control: drag from the part of the handle INSIDE the node box.
    final nodeRect = tester.getRect(find.byType(BaseNode).first);
    final visual = visualRect();
    final inside = Offset(visual.left + 1, visual.top + 1);
    expect(nodeRect.contains(inside), isTrue,
        reason: 'test setup: control point must be inside the node box');

    final before = size();
    await dragFrom(inside);
    expect(size(), isNot(before),
        reason: 'control: dragging the handle from INSIDE the node must resize');

    // The bug: drag from the part of the handle OUTSIDE the node box.
    final nodeRect2 = tester.getRect(find.byType(BaseNode).first);
    final visual2 = visualRect();
    final outside = Offset(visual2.right - 1, visual2.bottom - 1);
    expect(nodeRect2.contains(outside), isFalse,
        reason: 'test setup: point must be outside the node box');

    final before2 = size();
    await dragFrom(outside);
    expect(size(), isNot(before2),
        reason: 'dragging the handle OUTSIDE the node box must resize');
  });
}