// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Drag-feedback parity fixes:
/// - reconnect dots track live positions during drags (Lattice edge-updater)
/// - `autoPanOnNodeDrag: false` disables auto-pan (Lattice autoPanOnNodeDrag gate)
/// - `snapToGrid` snaps live every frame, not just at drag end (Lattice
///   XYDrag.updateNodes + calculateSnapOffset)

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

double _dotTop(WidgetTester tester, String key) {
  return tester
      .widget<Positioned>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Positioned),
        ).first,
      )
      .top!;
}

double _dotLeft(WidgetTester tester, String key) {
  return tester
      .widget<Positioned>(
        find.descendant(
          of: find.byKey(ValueKey(key)),
          matching: find.byType(Positioned),
        ).first,
      )
      .left!;
}

Future<void> _pumpCanvas(
  WidgetTester tester, {
  required List<FlowNode<String>> nodes,
  List<FlowEdge> edges = const [],
  ViewportOptions? viewportOptions,
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
            edges: {for (final e in edges) e.id: e},
          ),
          options: FlowCanvasOptions(
            viewportOptions: viewportOptions ?? const ViewportOptions(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
      'reconnect dots track a node drag live (Lattice edge-updater follows the '
      'dragged node)', (tester) async {
    await _pumpCanvas(
      tester,
      nodes: [
        FlowNode<String>(
          type: 'default',
          id: 'node_a',
          position: const Offset(100, 100),
          size: const Size(160, 100),
          data: 'A',
        ),
        FlowNode<String>(
          type: 'default',
          id: 'node_b',
          position: const Offset(400, 300),
          size: const Size(160, 100),
          data: 'B',
        ),
      ],
      edges: [
        FlowEdge(
          id: 'edge_1',
          sourceNodeId: 'node_a',
          targetNodeId: 'node_b',
          sourceHandleId: 'source',
          targetHandleId: 'target',
          reconnectable: true,
        ),
      ],
      viewportOptions: const ViewportOptions(selectionOnDrag: true),
    );

    // Marquee over both nodes + the edge so the edge stays selected while
    // node_a is dragged (dragging an unselected node would replace the
    // selection and hide the dots, as in Lattice).
    final marquee = await tester.startGesture(const Offset(50, 50));
    await tester.pump();
    await marquee.moveBy(const Offset(700, 500));
    await tester.pump();
    await marquee.up();
    await tester.pump();

    expect(find.byKey(const ValueKey('reconnect_edge_1_source')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('reconnect_edge_1_target')),
        findsOneWidget);

    final dotLeft0 = _dotLeft(tester, 'reconnect_edge_1_source');
    final dotTop0 = _dotTop(tester, 'reconnect_edge_1_source');

    final gesture = await tester.startGesture(const Offset(180, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(90, 60));
    await tester.pump();

    final dotLeft1 = _dotLeft(tester, 'reconnect_edge_1_source');
    final dotTop1 = _dotTop(tester, 'reconnect_edge_1_source');

    expect(dotLeft1 - dotLeft0, 90,
        reason: 'reconnect dot must move with the dragged node mid-drag');
    expect(dotTop1 - dotTop0, 60);

    await gesture.up();
    await tester.pump();
    expect(_nodeLeft(tester, 'middle', 'node_a'), 190,
        reason: 'node committed at its live position');
  });

  testWidgets('autoPanOnNodeDrag: false stops auto-pan entirely',
      (tester) async {
    await _pumpCanvas(
      tester,
      nodes: [
        FlowNode<String>(
          type: 'default',
          id: 'node_a',
          position: const Offset(100, 100),
          size: const Size(160, 100),
          data: 'A',
        ),
      ],
      viewportOptions: const ViewportOptions(
        autoPanOnNodeDrag: false,
        autoPanMargin: 50,
      ),
    );

    final gesture = await tester.startGesture(const Offset(180, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(-30, -150));
    await tester.pump();

    final topBefore = _nodeTop(tester, 'middle', 'node_a');

    await tester.pump(const Duration(milliseconds: 200));

    expect(_nodeTop(tester, 'middle', 'node_a'), topBefore,
        reason: 'cursor is inside the 50px margin but auto-pan is disabled');

    await gesture.up();
    await tester.pump();
  });

  testWidgets('snapToGrid snaps live while dragging and commits snapped '
      '(Lattice XYDrag.updateNodes)', (tester) async {
    await _pumpCanvas(
      tester,
      nodes: [
        FlowNode<String>(
          type: 'default',
          id: 'node_a',
          position: const Offset(100, 100),
          size: const Size(160, 100),
          data: 'A',
        ),
      ],
      viewportOptions: const ViewportOptions(
        snapToGrid: true,
        snapGrid: SnapGrid(width: 20, height: 20),
      ),
    );

    // Drag by (33,41): raw (133,141) → snapped (140,140).
    final gesture = await tester.startGesture(const Offset(180, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(33, 41));
    await tester.pump();

    expect(_nodeLeft(tester, 'middle', 'node_a'), 140,
        reason: 'node must snap to the 20px grid while dragging');
    expect(_nodeTop(tester, 'middle', 'node_a'), 140);

    await gesture.up();
    await tester.pump();

    expect(_nodeLeft(tester, 'middle', 'node_a'), 140,
        reason: 'committed position is the snapped live position');
    expect(_nodeTop(tester, 'middle', 'node_a'), 140);
  });

  testWidgets('multi-drag snap shares one offset so the selection moves as '
      'a unit (Lattice calculateSnapOffset)', (tester) async {
    await _pumpCanvas(
      tester,
      nodes: [
        FlowNode<String>(
          type: 'default',
          id: 'node_a',
          position: const Offset(100, 100),
          size: const Size(160, 100),
          data: 'A',
        ),
        FlowNode<String>(
          type: 'default',
          id: 'node_b',
          position: const Offset(250, 120),
          size: const Size(160, 100),
          data: 'B',
        ),
      ],
      viewportOptions: const ViewportOptions(
        selectionOnDrag: true,
        snapToGrid: true,
        snapGrid: SnapGrid(width: 20, height: 20),
      ),
    );

    final marquee = await tester.startGesture(const Offset(50, 50));
    await tester.pump();
    await marquee.moveBy(const Offset(500, 400));
    await tester.pump();
    await marquee.up();
    await tester.pump();

    // Drag node_a by (33,41): raw (133,141) → snap ref (140,140),
    // shared offset (7,-1); node_b raw (283,161) → (290,160).
    final gesture = await tester.startGesture(const Offset(180, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(33, 41));
    await tester.pump();

    await gesture.up();
    await tester.pump();

    expect(_nodeLeft(tester, 'middle', 'node_a'), 140);
    expect(_nodeTop(tester, 'middle', 'node_a'), 140);
    expect(_nodeLeft(tester, 'middle', 'node_b'), 290);
    expect(_nodeTop(tester, 'middle', 'node_b'), 160);
    expect(
      Offset(
        _nodeLeft(tester, 'middle', 'node_b') -
            _nodeLeft(tester, 'middle', 'node_a'),
        _nodeTop(tester, 'middle', 'node_b') -
            _nodeTop(tester, 'middle', 'node_a'),
      ),
      const Offset(150, 20),
      reason: 'relative shape of the selection must be preserved',
    );
  });
}