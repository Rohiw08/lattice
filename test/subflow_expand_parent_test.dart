// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds the [Positioned] that places a node at its absolute flow position.
Positioned _nodePosition(WidgetTester tester, String layerName, String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester.widget<Positioned>(
    find.descendant(of: stack, matching: find.byType(Positioned)).first,
  );
}

/// The [UnboundedSizedBox] that sizes a node's render box.
UnboundedSizedBox _nodeSizedBox(WidgetTester tester, String layerName,
    String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester.widget<UnboundedSizedBox>(
    find.descendant(of: stack, matching: find.byType(UnboundedSizedBox)).first,
  );
}

/// On-screen center of a node's stack (Positioned gives no width/height).
Offset _nodeCenter(WidgetTester tester, String layerName, String nodeId) {
  return tester
      .getRect(find.byKey(ValueKey('${layerName}_$nodeId')))
      .center;
}

List<FlowNode<String>> _fixture() => [
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
        size: const Size(160, 44),
        data: 'Input',
        extent: FlowNodeExtent.parent,
        expandParent: true,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(180, 50),
        size: const Size(160, 44),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
    ];

Future<void> _pumpCanvas(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialNodes: _fixture(),
        ),
      ),
    ),
  );
  await tester.pump();
}

/// Drags node_in by [delta]. The first move crosses the drag slop and is
/// consumed by the recognizer, so the second move carries the full delta.
Future<void> _dragChild(WidgetTester tester, Offset delta) async {
  final gesture = await tester.startGesture(
      _nodeCenter(tester, 'middle', 'node_in'));
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
      'expandParent: dragging a child past the edge grows the parent live and '
      'keeps siblings put', (tester) async {
    await _pumpCanvas(tester);

    // Raw target: (30,60) + (230,260) = (260,320) -> past right AND bottom.
    final gesture = await tester.startGesture(
        _nodeCenter(tester, 'middle', 'node_in'));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(230, 260));
    await tester.pump();

    // MID-DRAG: parent stays at its origin (no negative child) and grows live.
    final gLive = _nodePosition(tester, 'background', 'group_1');
    final cLive = _nodePosition(tester, 'middle', 'node_in');
    expect(gLive.left!, 60, reason: 'no origin shift (child not negative)');
    expect(gLive.top!, 40);
    expect(Offset(cLive.left! - 60, cLive.top! - 40), const Offset(260, 320),
        reason: 'expandParent child is NOT clamped to the parent box');
    expect(_nodeSizedBox(tester, 'background', 'group_1').width, 420,
        reason: 'parent grows live to fit the dragged child');
    expect(_nodeSizedBox(tester, 'background', 'group_1').height, 364);

    await gesture.up();
    await tester.pump();

    // COMMITTED: same values, sibling absolute position untouched.
    final g1 = _nodePosition(tester, 'background', 'group_1');
    final c1 = _nodePosition(tester, 'middle', 'node_in');
    final a1 = _nodePosition(tester, 'middle', 'node_a');
    expect(g1.left!, 60);
    expect(g1.top!, 40);
    expect(Offset(c1.left! - 60, c1.top! - 40), const Offset(260, 320));
    expect(_nodeSizedBox(tester, 'background', 'group_1').width, 420);
    expect(_nodeSizedBox(tester, 'background', 'group_1').height, 364);
    expect(Offset(a1.left!, a1.top!), const Offset(240, 90),
        reason: 'sibling keeps its absolute position when parent only grows');
  });

  testWidgets(
      'expandParent: negative child drag shifts the parent origin and '
      'compensates siblings (Lattice handleExpandParent)', (tester) async {
    await _pumpCanvas(tester);

    // Raw target: (30,60) + (-100,-80) = (-70,-20) -> negative on both axes.
    await _dragChild(tester, const Offset(-100, -80));

    final g1 = _nodePosition(tester, 'background', 'group_1');
    final c1 = _nodePosition(tester, 'middle', 'node_in');
    final a1 = _nodePosition(tester, 'middle', 'node_a');
    expect(Offset(g1.left!, g1.top!), const Offset(-10, 20),
        reason: 'parent origin shifts by the negative child offset');
    expect(_nodeSizedBox(tester, 'background', 'group_1').width, 430);
    expect(_nodeSizedBox(tester, 'background', 'group_1').height, 280);
    expect(Offset(c1.left!, c1.top!), const Offset(-10, 20),
        reason: 'child clamps to the new parent origin (>= 0 relative)');
    expect(Offset(a1.left!, a1.top!), const Offset(240, 90),
        reason:
            'sibling shifts by the origin delta so its absolute position '
            'stays put');
  });

  group('applyExpandParent (service, Lattice handleExpandParent)', () {
    test('grows the parent when a moved child sits outside the box', () {
      final state = NodeService().addNodes(const FlowCanvasState(), [
        FlowNode<String>(
          type: 'group',
          id: 'p',
          position: const Offset(100, 100),
          size: const Size(300, 200),
          data: 'P',
        ),
        FlowNode<String>(
          type: 'default',
          id: 'c',
          parentId: 'p',
          position: const Offset(280, 60),
          size: const Size(100, 40),
          data: 'C',
          extent: FlowNodeExtent.parent,
          expandParent: true,
        ),
        FlowNode<String>(
          type: 'default',
          id: 's',
          parentId: 'p',
          position: const Offset(50, 40),
          size: const Size(100, 40),
          data: 'S',
          extent: FlowNodeExtent.parent,
        ),
      ]);

      final next = NodeService().applyExpandParent(state, ['c']);
      expect(next.nodes['p']!.position, const Offset(100, 100));
      expect(next.nodes['p']!.size, const Size(380, 200),
          reason: 'parent grows to contain the child right edge');
      expect(next.nodes['c']!.position, const Offset(280, 60));
      expect(next.nodes['s']!.position, const Offset(50, 40),
          reason: 'no origin delta -> siblings untouched');
    });

    test('negative child shifts the parent origin and compensates siblings',
        () {
      final state = NodeService().addNodes(const FlowCanvasState(), [
        FlowNode<String>(
          type: 'group',
          id: 'p',
          position: const Offset(100, 100),
          size: const Size(300, 200),
          data: 'P',
        ),
        FlowNode<String>(
          type: 'default',
          id: 'c',
          parentId: 'p',
          position: const Offset(-30, 60),
          size: const Size(100, 40),
          data: 'C',
          extent: FlowNodeExtent.parent,
          expandParent: true,
        ),
        FlowNode<String>(
          type: 'default',
          id: 's',
          parentId: 'p',
          position: const Offset(50, 40),
          size: const Size(100, 40),
          data: 'S',
          extent: FlowNodeExtent.parent,
        ),
      ]);

      final next = NodeService().applyExpandParent(state, ['c']);
      expect(next.nodes['p']!.position, const Offset(70, 100));
      expect(next.nodes['p']!.size, const Size(330, 200));
      expect(next.nodes['c']!.position, const Offset(0, 60),
          reason: 'child clamps to >= 0 relative');
      expect(next.nodes['s']!.position, const Offset(80, 40),
          reason: 'sibling shifts by origin delta (-30, 0)');
    });
  });
}