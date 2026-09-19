// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// API-parity utils: getZoom, snapshotted coordinates, type guards,
/// simpleBezier/straight publics, default edge globals, ZIndexMode.

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  FlowCanvasOptions? options,
  List<FlowNode<String>>? nodes,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: options ?? FlowCanvasOptions(),
          initialNodes: nodes ??
              [
                FlowNode<String>(
                  type: 'default',
                  id: 'a',
                  position: const Offset(-200, -100),
                  size: const Size(160, 100),
                  data: 'A',
                ),
              ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('getZoom tracks programmatic zoom', (tester) async {
    final controller = await _pump(tester);
    expect(controller.viewport.getZoom(), moreOrLessEquals(1.0));
    await controller.viewport.zoomTo(2.0);
    await tester.pump();
    expect(controller.viewport.getZoom(), moreOrLessEquals(2.0));
  });

  testWidgets('viewportToFlow snap flag snaps to the grid', (tester) async {
    final controller = await _pump(tester);
    const point = Offset(17, 33);
    final raw = controller.viewport.viewportToFlow(point);
    final snapped =
        controller.viewport.viewportToFlow(point, snapToGrid: true);
    expect(raw, isNot(snapped));
    expect(snapped.dx % 15, moreOrLessEquals(0.0));
    expect(snapped.dy % 15, moreOrLessEquals(0.0));

    final viaGlobal = controller.viewport.flowPositionFromGlobal(
      tester.getCenter(find.byKey(ValueKey('middle_a'))),
      snapToGrid: true,
    );
    expect(viaGlobal, isNotNull);
    expect(viaGlobal!.dx % 15, moreOrLessEquals(0.0));
  });

  test('isEdge / isNode guards', () {
    const node = FlowNode<String>(
        type: 'default', id: 'a', position: Offset.zero);
    final edge = FlowEdge(id: 'e', sourceNodeId: 'a', targetNodeId: 'b');
    expect(isNode(node), isTrue);
    expect(isNode(edge), isFalse);
    expect(isNode(null), isFalse);
    expect(isEdge(edge), isTrue);
    expect(isEdge(node), isFalse);
    expect(isEdge('e1'), isFalse);
  });

  test('FlowNodeHandle key packs node/handle ids', () {
    const handle = FlowNodeHandle(nodeId: 'a', handleId: 'out');
    expect(handle.key, 'a/out');
    expect(handle.toString(), contains('a/out'));
  });

  test('getStraightPath spans its endpoints', () {
    final path = EdgePathCreator.getStraightPath(
      source: const Offset(5, 5),
      target: const Offset(15, 25),
    );
    expect(path.getBounds(), const Rect.fromLTWH(5, 5, 10, 20));
  });

  test('getSimpleBezierPath matches the RF control-point math', () {
    // Bottom→top: controls (x1, midY) and (x2, midY).
    final path = EdgePathCreator.getSimpleBezierPath(
      source: const Offset(0, 0),
      target: const Offset(0, 100),
    );
    final bounds = path.getBounds();
    expect(bounds.left, moreOrLessEquals(0.0));
    expect(bounds.top, moreOrLessEquals(0.0));
    expect(bounds.bottom, moreOrLessEquals(100.0));

    // Left→right: controls share y1/y2 (flat S-curve through midX).
    final across = EdgePathCreator.getSimpleBezierPath(
      source: const Offset(0, 50),
      target: const Offset(100, 50),
      sourcePosition: HandlePosition.left,
      targetPosition: HandlePosition.right,
    );
    expect(across.getBounds().top, moreOrLessEquals(50.0));
    expect(across.getBounds().bottom, moreOrLessEquals(50.0));
  });

  testWidgets('default edge label applies, per-edge wins', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            options: FlowCanvasOptions(
              edgeOptions: EdgeOptions(label: Text('G')),
            ),
            initialNodes: const [
              FlowNode<String>(
                  type: 'default', id: 'a', position: Offset(100, 100)),
              FlowNode<String>(
                  type: 'default', id: 'b', position: Offset(400, 100)),
            ],
            initialEdges: [
              FlowEdge(id: 'e1', sourceNodeId: 'a', targetNodeId: 'b'),
              FlowEdge(
                  id: 'e2',
                  sourceNodeId: 'a',
                  targetNodeId: 'b',
                  label: Text('Mine')),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('G'), findsOneWidget);
    expect(find.text('Mine'), findsOneWidget);
  });

  testWidgets('zIndexMode manual keeps z, basic skips child bumps',
      (tester) async {
    // Manual: no allocation, no bumps.
    final manual = await _pump(tester,
        options: FlowCanvasOptions(zIndexMode: ZIndexMode.manual),
        nodes: const []);
    manual.nodes.addNode(FlowNode<String>(
        type: 'default', id: 'ma', position: Offset.zero));
    manual.nodes.addNode(FlowNode<String>(
        type: 'default', id: 'mb', position: Offset.zero));
    await tester.pump();
    var state = manual.currentState;
    expect(state.nodes['ma']!.zIndex, 0);
    expect(state.nodes['mb']!.zIndex, 0);

    // Auto (default): allocation order.
    final auto = await _pump(tester, nodes: const []);
    auto.nodes.addNode(FlowNode<String>(
        type: 'default', id: 'aa', position: Offset.zero));
    auto.nodes.addNode(FlowNode<String>(
        type: 'default', id: 'ab', position: Offset.zero));
    await tester.pump();
    state = auto.currentState;
    expect(state.nodes['ab']!.zIndex,
        greaterThan(state.nodes['aa']!.zIndex));
  });

  testWidgets('zIndexMode basic skips the child-above-parent bump',
      (tester) async {
    Future<int> childZ(
        WidgetTester tester, ZIndexMode mode, String tag) async {
      // Fresh canvas State per mode: pumpWidget reuses State for the same
      // tree shape (and maxZIndex would leak across sections).
      await tester.pumpWidget(MaterialApp(home: SizedBox()));
      await tester.pump();
      final controller = await _pump(
        tester,
        options: FlowCanvasOptions(zIndexMode: mode),
        nodes: const [],
      );
      // One batch, child first: auto's second pass bumps C above P.
      controller.nodes.addNodes([
        FlowNode<String>(
            type: 'default',
            id: 'c$tag',
            position: const Offset(-190, -190),
            zIndex: 5,
            data: 'C'),
        FlowNode<String>(
            type: 'group',
            id: 'p$tag',
            position: const Offset(-200, -200),
            size: const Size(300, 300),
            zIndex: 7,
            data: 'P'),
      ]);
      await tester.pump();
      // Attach afterwards too: exercises the updateNode path.
      controller.nodes.updateNode(controller.currentState.nodes['c$tag']!
          .copyWith(parentId: 'p$tag'));
      await tester.pump();
      return controller.currentState.nodes['c$tag']!.zIndex;
    }

    expect(await childZ(tester, ZIndexMode.auto, 'x'), 8);
    expect(await childZ(tester, ZIndexMode.basic, 'y'), 5);
  });
}
