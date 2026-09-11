import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _groupFill = Color(0x40F0F0F0);

/// All decorations in the tree, keyed by the [DecoratedBox] widget instance.
Map<DecoratedBox, BoxDecoration> _decorations(WidgetTester tester) {
  final result = <DecoratedBox, BoxDecoration>{};
  for (final box
      in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final d = box.decoration;
    if (d is BoxDecoration && d.color != null) {
      result[box] = d;
    }
  }
  return result;
}

void main() {
  testWidgets(
      'demo replica: hovering group empty area changes nothing but its shadow',
      (tester) async {
    final nodes = [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(60, 40),
        size: const Size(360, 260),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'input',
        id: 'node_in',
        parentId: 'group_1',
        position: const Offset(30, 60),
        data: 'Input',
        extent: FlowNodeExtent.parent,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(180, 50),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_b',
        parentId: 'group_1',
        position: const Offset(180, 140),
        data: 'B',
        extent: FlowNodeExtent.parent,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_2',
        position: const Offset(500, 120),
        data: 'Default',
      ),
      FlowNode<String>(
        type: 'output',
        id: 'node_3',
        position: const Offset(500, 300),
        data: 'Output',
      ),
    ];
    final edges = [
      const FlowEdge(
        id: 'e1',
        sourceNodeId: 'node_in',
        targetNodeId: 'node_a',
        sourceHandleId: 'source',
        targetHandleId: 'target',
        type: EdgePathType.bezier,
        reconnectable: true,
      ),
      const FlowEdge(
        id: 'e2',
        sourceNodeId: 'node_in',
        targetNodeId: 'node_b',
        sourceHandleId: 'source',
        targetHandleId: 'target',
        type: EdgePathType.smoothStep,
        reconnectable: true,
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
            initialEdges: edges,
            overlays: const [FlowBackground()],
          ),
        ),
      ),
    );
    await tester.pump();

    final before = _decorations(tester);

    // Hover the group's empty area (bottom-right quarter, away from the
    // child nodes inside it), resolved from the actual on-screen rect.
    final groupBox =
        tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).firstWhere(
              (b) =>
                  b.decoration is BoxDecoration &&
                  (b.decoration as BoxDecoration).color == _groupFill,
            );
    final groupRect = tester.getRect(find.byWidget(groupBox));
    final hoverPoint = Offset(
      groupRect.left + groupRect.width * 0.75,
      groupRect.top + groupRect.height * 0.8,
    );
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(10, 10));
    await tester.pump();
    await gesture.moveTo(hoverPoint);
    await tester.pump();

    final after = _decorations(tester);

    // Compare by value: hovering rebuilds widgets, so new instances appear
    // even for unchanged nodes. Only decoration VALUE changes count.
    final beforeValues = before.values.toSet();
    final changedValues =
        after.values.where((d) => !beforeValues.contains(d)).toSet();

    expect(changedValues.length, 1,
        reason: 'only the group decoration value may change on hover; '
            'got $changedValues');

    final groupDecoration = changedValues.single;
    expect(groupDecoration.color, _groupFill,
        reason: 'Lattice group hover is shadow-only; bg must not change');
    expect(groupDecoration.boxShadow, const [
      BoxShadow(
        color: Color(0x14FFFFFF),
        blurRadius: 4,
        spreadRadius: 1,
        offset: Offset(0, 1),
      ),
    ]);
    expect(find.text('Group'), findsNothing,
        reason: 'Lattice v12 GroupNode renders no label by default');
  });
}
