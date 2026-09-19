// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `dragHandle` parity (React Flow `dragHandle` selector), Flutter-idiomatic:
///
/// instead of naming a CSS class, the node opts in with
/// [FlowNode.dragHandle] and wraps the grab area in a [FlowDragHandle]
/// widget. Drags starting outside the handle still select the node but never
/// move it.

double _nodeLeft(WidgetTester tester, String nodeId) {
  final stack = find.byKey(ValueKey('middle_$nodeId'));
  return tester
      .widget<Positioned>(
        find.descendant(of: stack, matching: find.byType(Positioned)).first,
      )
      .left!;
}

Future<void> _pump(WidgetTester tester) async {
  final registry = NodeRegistry()
    ..register('grip', (node) => Row(
          children: [
            FlowDragHandle(
              child: Container(
                  width: 30, height: 100, color: const Color(0xFF888888)),
            ),
            Expanded(child: Text('body-${node.id}')),
          ],
        ));
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          nodeRegistry: registry,
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {
              'gated': FlowNode<String>(
                type: 'grip',
                id: 'gated',
                position: const Offset(100, 100),
                size: const Size(200, 100),
                dragHandle: true,
                data: 'G',
              ),
              'free': FlowNode<String>(
                type: 'grip',
                id: 'free',
                position: const Offset(100, 300),
                size: const Size(200, 100),
                data: 'F',
              ),
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('drag starts from the handle region', (tester) async {
    await _pump(tester);
    expect(_nodeLeft(tester, 'gated'), moreOrLessEquals(100.0));

    // Node 'gated' occupies flow x 100..300, y 100..200; the surface centers
    // the flow origin, so screen x is +400. Handle strip: screen x 500..530.
    final handleCenter =
        tester.getRect(find.byKey(ValueKey('middle_gated'))).topLeft +
            const Offset(15, 50);
    final gesture = await tester.startGesture(handleCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_nodeLeft(tester, 'gated'), greaterThan(150.0),
        reason: 'drag from the FlowDragHandle region must move the node');
  });

  testWidgets('press outside the handle selects but never drags',
      (tester) async {
    await _pump(tester);

    final bodyCenter =
        tester.getRect(find.byKey(ValueKey('middle_gated'))).centerRight +
            const Offset(-20, 0);
    final gesture = await tester.startGesture(bodyCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_nodeLeft(tester, 'gated'), moreOrLessEquals(100.0),
        reason: 'press outside the handle must not move a dragHandle node');
  });

  testWidgets('nodes without dragHandle drag from anywhere', (tester) async {
    await _pump(tester);

    final start = tester.getRect(find.byKey(ValueKey('middle_free'))).center;
    final gesture = await tester.startGesture(start);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(_nodeLeft(tester, 'free'), greaterThan(150.0),
        reason: 'default nodes keep whole-surface dragging');
  });

  test('dragHandle defaults to false and serializes', () {
    expect(const FlowNode<String>(
      type: 'default',
      id: 'a',
      position: Offset.zero,
    ).dragHandle, isFalse);
    const node = FlowNode<String>(
      type: 'default',
      id: 'a',
      position: Offset.zero,
      dragHandle: true,
    );
    final restored =
        FlowNode<String>.fromJson(node.toJson((d) => d), (o) => o! as String);
    expect(restored.dragHandle, isTrue);
  });
}
