// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Clamp dead-zone parity (React Flow `XYDrag.updateNodes` +
/// `calculateNodePosition`):
///
/// RF maps pointer -> node ABSOLUTELY (`nextPosition = pointer - distance`,
/// then clamp). Pushing into a clamp and coming back therefore pins the node
/// while the pointer is still inside the clamped-away region (dead zone) and
/// restores the origin exactly — never a permanent cursor/node gap.
///
/// An incremental (`live += delta`, then clamp) mapping instead moves the
/// node immediately on the way back and keeps the gap forever: returning the
/// pointer to its start does not return the node.

double _nodeFlowTop(WidgetTester tester, String nodeId) {
  final stack = find.byKey(ValueKey('middle_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .top!;
}

void main() {
  testWidgets(
      'clamped drag out-and-back pins in the dead zone and restores origin',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            initialState: FlowCanvasState.initial().copyWith(
              nodes: {
                'group_1': FlowNode<String>(
                  type: 'group',
                  id: 'group_1',
                  position: const Offset(100, 100),
                  size: const Size(360, 200),
                  data: 'Group',
                ),
                'node_a': FlowNode<String>(
                  type: 'default',
                  id: 'node_a',
                  parentId: 'group_1',
                  position: const Offset(100, 80),
                  size: const Size(160, 100),
                  data: 'A',
                  extent: FlowNodeExtent.parent,
                ),
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Child abs top starts at 180; the clamp pins it at abs 200 (parent
    // bottom 300 - child height 100).
    final start = tester.getRect(find.byKey(ValueKey('middle_node_a'))).center;
    final gesture = await tester.startGesture(start);
    await tester.pump();
    // Breaks touch slop; the framework absorbs this delta (standard slop
    // dead-band), so the drag effectively starts from the node origin.
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();

    // Drag DOWN 150px in steps (pushes 130px into the clamp).
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
    }
    expect(_nodeFlowTop(tester, 'node_a'), moreOrLessEquals(200.0),
        reason: 'child must pin at the parent bottom edge');

    // Move back UP 40px — still inside the clamped-away region.
    for (var i = 0; i < 2; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    expect(_nodeFlowTop(tester, 'node_a'), moreOrLessEquals(200.0),
        reason: 'RF dead zone: node stays pinned while the pointer is still '
            'inside clamped-away travel (no gap opens)');

    // Return the pointer fully (net travel past slop-break: zero).
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump();
    }
    await gesture.moveBy(const Offset(0, -10));
    await tester.pump();
    expect(_nodeFlowTop(tester, 'node_a'), moreOrLessEquals(160.0),
        reason: 'node must return exactly to its drag-activation point '
            '(180 origin minus the 20px slop dead-band absorbed by the '
            'framework): zero cursor/node gap');

    await gesture.up();
    await tester.pump();
    expect(_nodeFlowTop(tester, 'node_a'), moreOrLessEquals(160.0),
        reason: 'commit must preserve the live position with no offset');
  });
}
