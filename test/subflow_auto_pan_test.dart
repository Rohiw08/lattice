// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Auto-pan during node drag shares the `_moveNodesBy` path used by normal
/// drags, so expandParent / clamping behave identically (Lattice
/// `autoPanOnNodeDrag` → `calcAutoPan` → drag-items move).

double _nodeTop(WidgetTester tester, String layerName, String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .top!;
}

double _nodeLeft(WidgetTester tester, String layerName, String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .left!;
}

Future<void> _pumpCanvas(WidgetTester tester, {List<FlowNode<String>>? nodes}) async {
  final fixture = nodes ??
      [
        FlowNode<String>(
          type: 'default',
          id: 'node_a',
          position: const Offset(100, 100),
          size: const Size(160, 100),
          data: 'A',
        ),
      ];
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {for (final n in fixture) n.id: n},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
      'dragging a node into the auto-pan margin pans the viewport (node '
      'stays under the cursor, Lattice calcAutoPan)', (tester) async {
    await _pumpCanvas(tester);

    // Node center (180,150). Drag it up so the cursor lands at (180,20),
    // inside the 50px top margin.
    final start = Offset(
      _nodeLeft(tester, 'middle', 'node_a') + 80,
      _nodeTop(tester, 'middle', 'node_a') + 50,
    );
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, -150));
    await tester.pump();

    final topBefore = _nodeTop(tester, 'middle', 'node_a');

    // margin=50, speed=15, cursor 30px into the band:
    // velocity = (30 / 50) * 15 = 9 px/tick (Lattice ramp, not full speed).
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final topAfter = _nodeTop(tester, 'middle', 'node_a');

    final panDistance = topBefore - topAfter;
    expect(
      panDistance,
      greaterThan(30),
      reason: 'node flow position must move against the pan so the node '
          'stays under the cursor (~9px per 16ms tick)',
    );
    expect(
      panDistance,
      lessThanOrEqualTo(140),
      reason: 'ramped velocity must not exceed full speed (15px/tick * ~12 '
          'ticks = 180 max; ramp starts below full speed)',
    );

    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(_nodeTop(tester, 'middle', 'node_a'), topAfter,
        reason: 'auto-pan must stop when the drag ends');
  });

  testWidgets(
      'auto-pan keeps clamping to extent:parent and expandParent grows the '
      'parent while panning', (tester) async {
    await _pumpCanvas(
      tester,
      nodes: [
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
          position: const Offset(150, 40),
          size: const Size(160, 100),
          data: 'A',
          extent: FlowNodeExtent.parent,
          expandParent: true,
        ),
      ],
    );

    // Child abs (250,140) center (330,190). Drag up so the cursor reaches
    // (330,20) — far above the group — expandParent should grow the group
    // live while auto-pan runs.
    final gesture = await tester.startGesture(const Offset(330, 190));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, -190));
    await tester.pump();

    final groupHeight0 = tester.getRect(find.byKey(const ValueKey('background_group_1'))).height;

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    final groupHeight1 = tester.getRect(find.byKey(const ValueKey('background_group_1'))).height;
    final childTop1 = _nodeTop(tester, 'middle', 'node_a');

    expect(groupHeight1, greaterThan(groupHeight0),
        reason: 'child dragged past the parent top edge grows the parent '
            'live during auto-pan (Lattice handleExpandParent)');
    expect(childTop1, lessThan(140),
        reason: 'child must keep moving up (auto-pan + no clamp while '
            'expandParent is set, Lattice)');

    await gesture.up();
    await tester.pump();
  });
}