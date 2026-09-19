// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';

/// `nodeOrigin` parity (React Flow `nodeOrigin` / per-node `origin`):
///
/// The stored [FlowNode.position] is the node's **anchor point** — the point
/// inside the node at its origin. Rendering, hit-testing, bounds, and edge
/// geometry resolve the visual rect (anchor minus origin shift); drag math,
/// snapping, and clamps stay in anchor space, exactly like RF `XYDrag`.

double _nodeLeft(WidgetTester tester, String nodeId) {
  final stack = find.byKey(ValueKey('middle_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .left!;
}

Widget _canvas({
  required Map<String, FlowNode<String>> nodes,
  NodeOptions nodeOptions = const NodeOptions(),
}) {
  return MaterialApp(
    home: SizedBox(
      width: 800,
      height: 600,
      child: FlowCanvas(
        options: FlowCanvasOptions(nodeOptions: nodeOptions),
        initialState: FlowCanvasState.initial().copyWith(nodes: nodes),
      ),
    ),
  );
}

void main() {
  testWidgets('center canvas origin shifts the rendered rect by half size',
      (tester) async {
    await tester.pumpWidget(_canvas(
      nodeOptions: NodeOptions(nodeOrigin: const Offset(0.5, 0.5)),
      nodes: {
        'a': FlowNode<String>(
          type: 'default',
          id: 'a',
          position: const Offset(100, 100),
          size: const Size(160, 44),
          data: 'A',
        ),
      },
    ));
    await tester.pump();

    // Anchor (100,100) minus half size (80,22).
    expect(_nodeLeft(tester, 'a'), moreOrLessEquals(20.0));
  });

  testWidgets('per-node origin overrides the canvas default', (tester) async {
    await tester.pumpWidget(_canvas(
      nodes: {
        'centered': FlowNode<String>(
          type: 'default',
          id: 'centered',
          position: const Offset(100, 100),
          size: const Size(160, 44),
          origin: const Offset(0.5, 0.5),
          data: 'C',
        ),
        'plain': FlowNode<String>(
          type: 'default',
          id: 'plain',
          position: const Offset(100, 200),
          size: const Size(160, 44),
          data: 'P',
        ),
      },
    ));
    await tester.pump();

    expect(_nodeLeft(tester, 'centered'), moreOrLessEquals(20.0));
    expect(_nodeLeft(tester, 'plain'), moreOrLessEquals(100.0));
  });

  testWidgets('extent parent clamp respects a center origin', (tester) async {
    await tester.pumpWidget(_canvas(
      nodeOptions: NodeOptions(nodeOrigin: const Offset(0.5, 0.5)),
      nodes: {
        'group_1': FlowNode<String>(
          type: 'group',
          id: 'group_1',
          position: const Offset(100, 100),
          size: const Size(400, 300),
          data: 'Group',
        ),
        'node_a': FlowNode<String>(
          type: 'default',
          id: 'node_a',
          parentId: 'group_1',
          position: const Offset(0, 0),
          size: const Size(100, 100),
          data: 'A',
          extent: FlowNodeExtent.parent,
        ),
      },
    ));
    await tester.pump();

    // Anchor abs starts at (100,100); visual left at 50.
    expect(_nodeLeft(tester, 'node_a'), moreOrLessEquals(50.0));

    final start =
        tester.getRect(find.byKey(ValueKey('middle_node_a'))).center;
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();

    // Drag far right: anchor pins at parent-relative 350 (400 - 50), so the
    // visual left pins at the parent's right edge minus child width (400).
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(100, 0));
      await tester.pump();
    }
    expect(_nodeLeft(tester, 'node_a'), moreOrLessEquals(400.0),
        reason: 'visual rect must pin inside the parent with center origin');

    await gesture.up();
    await tester.pump();
    expect(_nodeLeft(tester, 'node_a'), moreOrLessEquals(400.0),
        reason: 'commit must preserve the pinned position');
  });

  test('origin survives a JSON round trip', () {
    const node = FlowNode<String>(
      type: 'default',
      id: 'a',
      position: Offset(10, 20),
      origin: Offset(0.5, 0.5),
      data: 'A',
    );
    final json = node.toJson((data) => data);
    final restored = FlowNode<String>.fromJson(json, (o) => o! as String);
    expect(restored.origin, const Offset(0.5, 0.5));
    expect(restored.position, const Offset(10, 20));
  });

  test('getNodeBounds resolves the visual rect with an origin', () {
    const nodes = [
      FlowNode<String>(
        type: 'default',
        id: 'a',
        position: Offset(100, 100),
        data: 'A',
      ),
    ];
    final service = ViewportService();
    final topLeft =
        service.getNodeBounds(nodes: nodes, defaultOrigin: Offset.zero);
    final centered = service.getNodeBounds(
        nodes: nodes, defaultOrigin: const Offset(0.5, 0.5));
    // Default node size is 160x44: center origin shifts by (80, 22).
    expect(topLeft.rect.left, 100.0);
    expect(centered.rect.left, 20.0);
    expect(centered.rect.top, 78.0);
  });
}
