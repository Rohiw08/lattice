// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds the [Positioned] that places a node at its absolute flow position.
Positioned _nodePosition(WidgetTester tester, String layerName, String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester.widget<Positioned>(
    find.descendant(of: stack, matching: find.byType(Positioned)).first,
  );
}

/// On-screen center of a node's stack (Positioned gives no width/height).
Offset _nodeCenter(WidgetTester tester, String layerName, String nodeId) {
  return tester
      .getRect(find.byKey(ValueKey('${layerName}_$nodeId')))
      .center;
}

List<FlowNode<String>> _subflowFixture() => [
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
    ];

/// State with nodes and a pre-seeded selection (drag set = selection, Lattice).
/// A provided [initialState] also disables canvas auto-centering, so flow
/// coordinates equal screen coordinates in these tests.
FlowCanvasState _stateWith(
  List<FlowNode<String>> nodes,
  Set<String> selected,
) {
  return FlowCanvasState.initial().copyWith(
    nodes: {for (final n in nodes) n.id: n},
    selectedNodes: selected,
  );
}

Future<void> _pumpCanvas(WidgetTester tester, {Set<String>? selected}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialState: _stateWith(_subflowFixture(), selected ?? {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Drags from [start] by [delta]. The first move crosses the drag slop and
/// is consumed by the recognizer, so the second move carries the full delta.
Future<void> _dragFrom(
  WidgetTester tester,
  Offset start,
  Offset delta,
) async {
  final gesture = await tester.startGesture(start);
  await tester.pump();
  await gesture.moveBy(const Offset(30, 20));
  await tester.pump();
  await gesture.moveBy(delta);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets(
      'Lattice drag set: selected parent + selected child -> child moves exactly once',
      (tester) async {
    await _pumpCanvas(tester, selected: {'group_1', 'node_a'});

    final groupRect = tester.getRect(find.byType(GroupNode));
    final grab = Offset(
      groupRect.left + groupRect.width * 0.27,
      groupRect.top + groupRect.height * 0.84,
    );

    final g0 = _nodePosition(tester, 'background', 'group_1');
    final a0 = _nodePosition(tester, 'middle', 'node_a');
    final in0 = _nodePosition(tester, 'middle', 'node_in');

    await _dragFrom(tester, grab, const Offset(90, 60));

    final g1 = _nodePosition(tester, 'background', 'group_1');
    final a1 = _nodePosition(tester, 'middle', 'node_a');
    final in1 = _nodePosition(tester, 'middle', 'node_in');

    final groupDelta = Offset(g1.left! - g0.left!, g1.top! - g0.top!);
    expect(groupDelta, const Offset(90, 60));

    expect(
      Offset(a1.left! - a0.left!, a1.top! - a0.top!),
      groupDelta,
      reason:
          'selected child of a dragged parent must move exactly once with the '
          'parent (Lattice drag set excludes children of dragged parents)',
    );
    expect(
      Offset(in1.left! - in0.left!, in1.top! - in0.top!),
      groupDelta,
      reason: 'unselected child follows the parent exactly once',
    );
  });

  testWidgets('selected child drags alone; parent and siblings stay put',
      (tester) async {
    await _pumpCanvas(tester);

    final childCenter = _nodeCenter(tester, 'middle', 'node_a');
    await tester.tapAt(childCenter);
    await tester.pump();

    final g0 = _nodePosition(tester, 'background', 'group_1');
    final a0 = _nodePosition(tester, 'middle', 'node_a');
    final in0 = _nodePosition(tester, 'middle', 'node_in');

    await _dragFrom(tester, childCenter, const Offset(70, 50));

    final g1 = _nodePosition(tester, 'background', 'group_1');
    final a1 = _nodePosition(tester, 'middle', 'node_a');
    final in1 = _nodePosition(tester, 'middle', 'node_in');

    expect(g1.left!, g0.left!);
    expect(g1.top!, g0.top!);
    expect(in1.left!, in0.left!);
    expect(in1.top!, in0.top!);
    // node_a: (180,50) + (70,50) = (250,100) -> x clamped to 200 by the
    // parent box (360 - 160), so the stored delta is (20, 50).
    expect(Offset(a1.left! - a0.left!, a1.top! - a0.top!), const Offset(20, 50));
  });
}