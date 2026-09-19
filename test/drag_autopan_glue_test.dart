// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Glue semantics when the pointer is HELD STILL inside an auto-pan margin
/// (timer ticks only, no gesture movement):
///
/// - Unclamped node: stays glued under the cursor — screen rect constant
///   while its flow position compensates the pan (React Flow `updateNodes`
///   with a frozen `lastPos`).
/// - `extent: parent` child (no expandParent): the clamp wins — the child
///   pins at the parent edge in flow space while the camera keeps panning,
///   so it separates from the cursor on screen (React Flow
///   `calculateNodePosition` parity, NOT a bug; use `expandParent` to keep
///   following).
/// - `expandParent` child: the parent grows, the child keeps following
///   (glued).

double _nodeFlowTop(WidgetTester tester, String nodeId) {
  final stack = find.byKey(ValueKey('middle_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .top!;
}

Rect _nodeScreenRect(WidgetTester tester, String nodeId) {
  return tester.getRect(find.byKey(ValueKey('middle_$nodeId')));
}

Future<void> _pumpCanvas(
  WidgetTester tester, {
  required List<FlowNode<String>> nodes,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {for (final n in nodes) n.id: n},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Starts a drag on [nodeId] and parks the pointer at [park] (inside an
/// auto-pan margin). Returns the active gesture; caller must `up()` it.
Future<TestGesture> _dragAndPark(
  WidgetTester tester,
  String nodeId,
  Offset park,
) async {
  final start = _nodeScreenRect(tester, nodeId).center;
  final gesture = await tester.startGesture(start);
  await tester.pump();
  // Past touch slop (~18px) so the drag activates.
  await gesture.moveBy(const Offset(30, 20));
  await tester.pump();
  await gesture.moveTo(park);
  await tester.pump();
  return gesture;
}

Future<void> _holdStill(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 32));
  }
}

void main() {
  testWidgets('held pointer in margin: unclamped node stays glued to cursor',
      (tester) async {
    await _pumpCanvas(tester, nodes: [
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        position: const Offset(100, 100),
        size: const Size(160, 100),
        data: 'A',
      ),
    ]);

    // Park 40px deep in the bottom margin (boundary at 600 - 50).
    final gesture = await _dragAndPark(tester, 'node_a', const Offset(400, 590));

    final screen0 = _nodeScreenRect(tester, 'node_a');
    final flowTop0 = _nodeFlowTop(tester, 'node_a');
    await _holdStill(tester);
    final screen1 = _nodeScreenRect(tester, 'node_a');
    final flowTop1 = _nodeFlowTop(tester, 'node_a');

    expect(flowTop1, greaterThan(flowTop0 + 30),
        reason: 'auto-pan must run during the hold (node flow compensates)');
    expect(screen1.top, moreOrLessEquals(screen0.top, epsilon: 1.0),
        reason: 'node must stay glued under the parked cursor on screen');
    expect(screen1.left, moreOrLessEquals(screen0.left, epsilon: 1.0));

    await gesture.up();
    await tester.pump();
  });

  testWidgets(
      'held pointer in margin: extent:parent child pins at the parent edge '
      'and separates from the cursor (Lattice calculateNodePosition)', (
    tester,
  ) async {
    await _pumpCanvas(tester, nodes: [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(100, 100),
        size: const Size(360, 200),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(100, 80),
        size: const Size(160, 100),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
    ]);

    final gesture = await _dragAndPark(tester, 'node_a', const Offset(400, 590));

    final screen0 = _nodeScreenRect(tester, 'node_a');
    await _holdStill(tester);
    final screen1 = _nodeScreenRect(tester, 'node_a');
    final flowTop1 = _nodeFlowTop(tester, 'node_a');

    // Pinned at the parent bottom edge in absolute flow space:
    // parent top (100) + parent height (200) - child height (100) = 200.
    expect(flowTop1, moreOrLessEquals(200.0, epsilon: 1.0),
        reason: 'child must pin at the parent bottom edge in flow space');
    expect(screen1.top, lessThan(screen0.top - 30),
        reason: 'camera keeps panning, so the pinned child separates from '
            'the parked cursor on screen (React Flow parity)');

    await gesture.up();
    await tester.pump();
  });

  testWidgets(
      'held pointer in margin: expandParent child keeps following while '
      'the parent grows', (tester) async {
    await _pumpCanvas(tester, nodes: [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(100, 100),
        size: const Size(360, 200),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(100, 80),
        size: const Size(160, 100),
        data: 'A',
        extent: FlowNodeExtent.parent,
        expandParent: true,
      ),
    ]);

    final gesture = await _dragAndPark(tester, 'node_a', const Offset(400, 590));

    final screen0 = _nodeScreenRect(tester, 'node_a');
    final groupH0 = tester
        .getRect(find.byKey(const ValueKey('background_group_1')))
        .height;
    await _holdStill(tester);
    final screen1 = _nodeScreenRect(tester, 'node_a');
    final groupH1 = tester
        .getRect(find.byKey(const ValueKey('background_group_1')))
        .height;

    expect(groupH1, greaterThan(groupH0 + 30),
        reason: 'parent must grow live while the child is dragged past its '
            'edge during auto-pan');
    expect(screen1.top, moreOrLessEquals(screen0.top, epsilon: 1.0),
        reason: 'child must stay glued under the parked cursor');

    await gesture.up();
    await tester.pump();
  });
}
