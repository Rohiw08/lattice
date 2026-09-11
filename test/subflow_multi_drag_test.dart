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

Future<void> _pumpCanvas(
  WidgetTester tester,
  FlowCanvasState state, {
  ViewportOptions viewport = const ViewportOptions(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialState: state,
          options: FlowCanvasOptions(viewportOptions: viewport),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Drags a node by [delta]. The first move crosses the drag slop and is
/// consumed by the recognizer, so the second move carries the full delta.
Future<void> _dragBy(WidgetTester tester, String nodeId, Offset delta) async {
  final gesture = await tester.startGesture(_nodeCenter(tester, 'middle', nodeId));
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
      'multi-drag: the whole selection stays inside nodeExtent (Lattice adjusted '
      'extent), relative layout preserved', (tester) async {
    final state = _stateWith([
      FlowNode<String>(
        type: 'default',
        id: 'node_1',
        position: const Offset(300, 200),
        size: const Size(160, 44),
        data: '1',
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_2',
        position: const Offset(310, 210),
        size: const Size(160, 44),
        data: '2',
      ),
    ], {'node_1', 'node_2'});
    await _pumpCanvas(
      tester,
      state,
      viewport: const ViewportOptions(
        nodeExtent: CoordinateExtent(minX: 0, minY: 0, maxX: 600, maxY: 500),
      ),
    );

    // Drag by (400,400): the selection box (300,200)-(470,254) would leave
    // the extent, so the unit must slide back as a group.
    await _dragBy(tester, 'node_1', const Offset(400, 400));

    final n1 = _nodePosition(tester, 'middle', 'node_1');
    final n2 = _nodePosition(tester, 'middle', 'node_2');

    expect(Offset(n1.left!, n1.top!), const Offset(430, 446),
        reason: 'selection clamped as a group against nodeExtent');
    expect(Offset(n2.left!, n2.top!), const Offset(440, 456));

    // Lattice: individual clamp would collapse nodes; adjusted extent keeps the
    // relative layout intact and the whole selection inside the extent.
    expect(Offset(n2.left! - n1.left!, n2.top! - n1.top!), const Offset(10, 10),
        reason: 'relative layout preserved by adjusted multi-drag extents');
    expect(n1.left! + 160, lessThanOrEqualTo(600));
    expect(n2.left! + 160, lessThanOrEqualTo(600));
    expect(n1.top! + 44, lessThanOrEqualTo(500));
    expect(n2.top! + 44, lessThanOrEqualTo(500));
  });

  testWidgets(
      'multi-drag: uniform snap on drop keeps the selection as a unit '
      '(Lattice calculateSnapOffset)', (tester) async {
    final state = _stateWith([
      FlowNode<String>(
        type: 'default',
        id: 'node_1',
        position: const Offset(100, 100),
        size: const Size(160, 44),
        data: '1',
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_2',
        position: const Offset(110, 110),
        size: const Size(160, 44),
        data: '2',
      ),
    ], {'node_1', 'node_2'});
    await _pumpCanvas(
      tester,
      state,
      viewport: const ViewportOptions(
        snapToGrid: true,
        snapGrid: SnapGrid(width: 10, height: 10),
      ),
    );

    // Off-grid drag: raw (166,144); the shared snap offset (4,-4) must apply
    // to BOTH nodes so the unit stays aligned on the grid.
    await _dragBy(tester, 'node_1', const Offset(66, 44));

    final n1 = _nodePosition(tester, 'middle', 'node_1');
    final n2 = _nodePosition(tester, 'middle', 'node_2');
    expect(Offset(n1.left!, n1.top!), const Offset(170, 140),
        reason: 'selection snaps as a unit to the grid');
    expect(Offset(n2.left!, n2.top!), const Offset(180, 150));
    expect(Offset(n2.left! - n1.left!, n2.top! - n1.top!), const Offset(10, 10),
        reason: 'uniform offset keeps the relative layout');
  });
}