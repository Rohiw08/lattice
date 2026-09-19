// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resize-constraint parity (React Flow min/max size, keepAspectRatio,
/// shouldResize, and the NodeResizeControl single handle).
///
/// Note on gestures: like the existing resize tests, the first moves only
/// break touch slop (absorbed, anchoring the gesture); assertions target the
/// applied portion.

ProviderContainer _containerOf(WidgetTester tester, Finder scope) =>
    ProviderScope.containerOf(tester.element(scope));

Size _sizeOf(WidgetTester tester, String nodeId) =>
    _containerOf(tester, find.byKey(ValueKey('middle_$nodeId')))
        .read(internalControllerProvider)
        .nodes[nodeId]!
        .size;

Future<void> _pump(WidgetTester tester, List<FlowNode<String>> nodes,
    {NodeRegistry? registry}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          nodeRegistry: registry,
          initialNodes: nodes,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _select(WidgetTester tester, String nodeId) async {
  await tester.tap(find.byKey(ValueKey('middle_$nodeId')));
  await tester.pump();
}

Future<Offset> _handleCenter(
    WidgetTester tester, String nodeId, Alignment direction) async {
  final matches = tester
      .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
      .where((h) => h.nodeId == nodeId && h.direction == direction)
      .toList();
  final handle = matches.first;
  final rect = tester.getRect(
    find.descendant(
      of: find.byWidget(handle),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return rect.center;
}

/// Drives a resize from [direction]; the first move breaks slop (absorbed).
Future<void> _dragHandle(
  WidgetTester tester,
  String nodeId,
  Alignment direction,
  List<Offset> moves,
) async {
  final gesture =
      await tester.startGesture(await _handleCenter(tester, nodeId, direction));
  await tester.pump();
  for (final move in moves) {
    await gesture.moveBy(move);
    await tester.pump();
  }
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('per-node maxSize caps growth', (tester) async {
    await _pump(tester, [
      FlowNode<String>(
        type: 'default',
        id: 'r',
        position: const Offset(-200, -100),
        size: const Size(160, 100),
        data: 'R',
        resizable: true,
        maxSize: const Size(200, 120),
      ),
    ]);
    await _select(tester, 'r');
    await _dragHandle(tester, 'r', Alignment.bottomRight, [
      const Offset(30, 20),
      for (var i = 0; i < 10; i++) const Offset(30, 30),
    ]);

    final size = _sizeOf(tester, 'r');
    expect(size.width, moreOrLessEquals(200.0));
    expect(size.height, moreOrLessEquals(120.0));
  });

  testWidgets('per-node minSize overrides the canvas default',
      (tester) async {
    await _pump(tester, [
      FlowNode<String>(
        type: 'default',
        id: 'r',
        position: const Offset(-200, -100),
        size: const Size(160, 100),
        data: 'R',
        resizable: true,
        minSize: const Size(100, 80),
      ),
    ]);
    await _select(tester, 'r');
    await _dragHandle(tester, 'r', Alignment.topLeft, [
      const Offset(20, 20),
      for (var i = 0; i < 10; i++) const Offset(20, 20),
    ]);

    final size = _sizeOf(tester, 'r');
    // Canvas default is 50x50: 100x80 proves the per-node floor applied.
    expect(size.width, moreOrLessEquals(100.0));
    expect(size.height, moreOrLessEquals(80.0));
  });

  testWidgets('keepAspectRatio locks proportions from the start size',
      (tester) async {
    await _pump(tester, [
      FlowNode<String>(
        type: 'default',
        id: 'r',
        position: const Offset(-200, -100),
        size: const Size(160, 100),
        data: 'R',
        resizable: true,
        keepAspectRatio: true,
      ),
    ]);
    await _select(tester, 'r');
    await _dragHandle(tester, 'r', Alignment.centerRight, [
      const Offset(30, 0),
      const Offset(50, 0),
      const Offset(50, 0),
    ]);

    final size = _sizeOf(tester, 'r');
    expect(size.width, greaterThan(160.0));
    expect(size.height / size.width, moreOrLessEquals(100.0 / 160.0));
  });

  testWidgets('shouldResize veto blocks oversized proposals', (tester) async {
    bool allow(FlowResizeProposal p) => p.size.width <= 200.0;
    await _pump(tester, [
      FlowNode<String>(
        type: 'default',
        id: 'vetoed',
        position: const Offset(-200, -160),
        size: const Size(160, 100),
        data: 'V',
        resizable: true,
        shouldResize: allow,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'open',
        position: const Offset(-200, 60),
        size: const Size(160, 100),
        data: 'O',
        resizable: true,
      ),
    ]);

    Future<void> dragRight(String nodeId) async {
      await _select(tester, nodeId);
      await _dragHandle(tester, nodeId, Alignment.centerRight, [
        const Offset(30, 0),
        for (var i = 0; i < 12; i++) const Offset(20, 0),
      ]);
    }

    await dragRight('vetoed');
    final vetoed = _sizeOf(tester, 'vetoed');
    expect(vetoed.width, lessThanOrEqualTo(200.0));
    expect(vetoed.width, greaterThan(160.0));

    await dragRight('open');
    expect(_sizeOf(tester, 'open').width, greaterThan(200.0));
  });

  testWidgets('FlowNodeResizeControl drives one direction', (tester) async {
    // NOTE: edge-straddling chrome must live under an ungated container.
    // A stock Stack gates hit tests on size.contains (exclusive edges), so a
    // handle centered exactly on the node edge is unreachable inside one —
    // use InfiniteHitTestStack (RF's visible-overflow equivalent) as the
    // custom root when chrome overflows the node box.
    final registry = NodeRegistry()
      ..register('tall', (node) => InfiniteHitTestStack(
            clipBehavior: Clip.none,
            children: [
              Text('t-${node.id}'),
              FlowNodeResizeControl(
                nodeId: node.id,
                direction: ResizeDirection.bottom,
              ),
            ],
          ));
    await _pump(tester,
        [
          FlowNode<String>(
            type: 'tall',
            id: 'c',
            position: const Offset(-200, -100),
            size: const Size(160, 100),
            data: 'C',
          ),
        ],
        registry: registry);
    await tester.tapAt(
        await _handleCenter(tester, 'c', Alignment.bottomCenter));
    await tester.pump();
    final sel = _containerOf(tester, find.byKey(ValueKey('middle_c')))
        .read(internalControllerProvider)
        .selectedNodes;
    debugPrint('probe control tap selected=$sel');
    await _dragHandle(tester, 'c', Alignment.bottomCenter, [
      const Offset(0, 30),
      for (var i = 0; i < 4; i++) const Offset(0, 50),
    ]);

    final size = _sizeOf(tester, 'c');
    expect(size.height, greaterThan(100.0));
    expect(size.width, moreOrLessEquals(160.0));
  });
}
