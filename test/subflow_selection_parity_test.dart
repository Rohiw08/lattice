// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Lattice v12 parity: selection does NOT mark ancestors selected.
///
/// `markParentAsSelected` was removed in v12 — `getSelectionChanges` /
/// `applyNodeChanges` / `adoptUserNodes` are all plain id-based. Parent
/// selection only matters via the drag set: `getDragItems` excludes a child
/// whose parent is selected (`isParentSelected`), which is covered by
/// subflow_drag_set_test. These tests guard against re-introducing elevation.

/// On-screen center of a node's stack (Positioned gives no width/height).
Offset _nodeCenter(WidgetTester tester, String layerName, String nodeId) {
  return tester
      .getRect(find.byKey(ValueKey('${layerName}_$nodeId')))
      .center;
}

/// Group at (100,100) 400x300; child node_a at absolute (150,160) 160x100,
/// center (230,210). All nodes well inside an 800x600 viewport.
List<FlowNode<String>> _subflowFixture() => [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(50, 60),
        size: const Size(160, 100),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
    ];

/// A provided [initialState] disables canvas auto-centering, so flow
/// coordinates equal screen coordinates in these tests.
FlowCanvasState _stateWith(List<FlowNode<String>> nodes) {
  return FlowCanvasState.initial().copyWith(
    nodes: {for (final n in nodes) n.id: n},
  );
}

Future<void> _pumpCanvas(
  WidgetTester tester, {
  required void Function(Set<String> nodeIds) onSelection,
  bool selectionOnDrag = false,
  SelectionMode selectionMode = SelectionMode.full,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialState: _stateWith(_subflowFixture()),
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              selectionOnDrag: selectionOnDrag,
              selectionMode: selectionMode,
            ),
          ),
          callbacks: FlowCanvasCallbacks(
            onSelectionChange: (selection) {
              onSelection(selection.nodeIds);
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Marquee drag from [start] to [end] (screen == flow coords here).
Future<void> _marqueeFrom(WidgetTester tester, Offset start, Offset end) async {
  final gesture = await tester.startGesture(start);
  await tester.pump();
  await gesture.moveBy(end - start);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets(
      'clicking a child selects only the child, not its parent (Lattice v12: '
      'no markParentAsSelected)', (tester) async {
    Set<String>? selection;
    await _pumpCanvas(tester, onSelection: (ids) => selection = ids);
    expect(selection, isNull);

    await tester.tapAt(_nodeCenter(tester, 'middle', 'node_a'));
    await tester.pump();

    expect(
      selection,
      {'node_a'},
      reason: 'v12 selection is plain id-based; the group must NOT be '
          'marked selected when a child is clicked',
    );
  });

  testWidgets(
      'marquee over child only (default full mode) selects the child only, '
      'group partially overlapped stays unselected', (tester) async {
    Set<String>? selection;
    await _pumpCanvas(tester, selectionOnDrag: true, onSelection: (ids) => selection = ids);

    // Rect (40,130)-(560,470): fully contains node_a (150,160)-(310,260),
    // only partially overlaps group_1 (100,100)-(500,400).
    await _marqueeFrom(tester, const Offset(40, 470), const Offset(560, 130));

    expect(selection, {'node_a'});
  });

  testWidgets(
      'marquee in partial mode over child + part of group selects both; '
      'dragging the child then moves the group (drag-set exclusion)', (
      tester) async {
    Set<String>? selection;
    await _pumpCanvas(
      tester,
      selectionOnDrag: true,
      selectionMode: SelectionMode.partial,
      onSelection: (ids) => selection = ids,
    );

    await _marqueeFrom(tester, const Offset(40, 470), const Offset(560, 130));

    expect(
      selection,
      {'group_1', 'node_a'},
      reason: 'partial mode selects any overlapped node',
    );

    final g0 = tester
        .widget<Positioned>(
          find.descendant(
            of: find.byKey(const ValueKey('background_group_1')),
            matching: find.byType(Positioned),
          ).first,
        )
        .left;
    final a0 = _nodeCenter(tester, 'middle', 'node_a');

    // Drag the child: its parent is selected, so Lattice `getDragItems` excludes
    // the child — the group itself must drag by the full delta.
    final gesture = await tester.startGesture(a0);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(90, 60));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    final g1 = tester
        .widget<Positioned>(
          find.descendant(
            of: find.byKey(const ValueKey('background_group_1')),
            matching: find.byType(Positioned),
          ).first,
        )
        .left;
    final a1 = _nodeCenter(tester, 'middle', 'node_a');

    expect(g1! - g0!, 90, reason: 'group moved — drag set was the parent');
    expect(a1 - a0, const Offset(90, 60),
        reason: 'child follows the dragged parent exactly once');
  });
}