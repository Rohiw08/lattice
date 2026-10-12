// ignore_for_file: prefer_const_constructors, avoid_print
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

import 'bench_helpers.dart';

/// Fair sweep harness (lattice side): identical custom `bench` node everywhere.
///
/// Fixture per `sweep_spec.json`: cols=30, rows=ceil(N/30), 100x50 spacing,
/// 50x30 nodes, 800x600 box, minZoom 0.2, bezier, no labels/dashes.
/// Node: BaseNode + 2 FlowHandles (6x6) + centered 8px label. Never `default`.
const List<int> sweepSizes = [100, 500, 1000, 2500];

int sweepRuns(int n) => n >= 1000 ? 2 : 3;

Widget sweepLabel(String id) =>
    Center(child: Text(id, style: const TextStyle(fontSize: 8)));

Map<String, FlowHandle> sweepHandles() => const {
      'target': FlowHandle(
        id: 'target',
        type: HandleType.target,
        position: Offset(0, 15),
        size: Size(6, 6),
      ),
      'source': FlowHandle(
        id: 'source',
        type: HandleType.source,
        position: Offset(50, 15),
        size: Size(6, 6),
      ),
    };

NodeRegistry sweepRegistry() {
  final registry = NodeRegistry();
  registry.register(
    'bench',
    (node) => BaseNode(node: node, child: sweepLabel(node.id)),
  );
  return registry;
}

Map<String, FlowNode<String>> sweepNodes(int count) {
  final nodes = <String, FlowNode<String>>{};
  for (var i = 0; i < count; i++) {
    nodes['node-$i'] = FlowNode<String>(
      type: 'bench',
      id: 'node-$i',
      position: sweepGridPos(i),
      size: const Size(50, 30),
      data: 'node-$i',
      handles: sweepHandles(),
    );
  }
  return nodes;
}

Map<String, FlowEdge> sweepEdges(int count, bool dense) =>
    dense ? benchDenseEdges(count) : benchChainEdges(count);

Future<FlowCanvasController> pumpSweepCanvas(
  WidgetTester tester,
  int run,
  int count,
  bool dense,
  bool cull,
) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          key: ValueKey('sweep-$run-$count-${dense ? 'dense' : 'chain'}-$cull'),
          controller: controller,
          nodeRegistry: sweepRegistry(),
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: cull,
            ),
          ),
          initialNodes: sweepNodes(count).values.toList(),
          initialEdges: sweepEdges(count, dense).values.toList(),
        ),
      ),
    ),
  );
  return controller;
}

String sweepTag(int n, bool dense, bool cull) =>
    'N=$n edges=${dense ? 'dense' : 'chain'} cull=${cull ? 'on' : 'off'}';

void main() {
  testWidgets('sweep mount 100 chain cull-on', (tester) async {
    final warm = await pumpSweepCanvas(tester, -1, 100, false, true);
    await benchSettle(tester);
    expect(warm.currentState.nodes.length, 100);

    final mounts = <double>[];
    for (var i = 0; i < sweepRuns(100); i++) {
      final sw = Stopwatch()..start();
      final c = await pumpSweepCanvas(tester, i, 100, false, true);
      final frames = await benchSettle(tester);
      sw.stop();
      expect(c.currentState.nodes.length, 100);
      expect(frames, greaterThan(0));
      mounts.add(sw.elapsedMicroseconds / 1000.0);
    }
    benchReport('LATTICE', 'sweep mount ${sweepTag(100, false, true)}',
        benchStats('mount ms', mounts));
  });

  testWidgets('sweep drag 100 chain cull-on', (tester) async {
    final perPump = <double>[];
    for (var i = 0; i < sweepRuns(100); i++) {
      final c = await pumpSweepCanvas(tester, 100 + i, 100, false, true);
      await benchSettle(tester);
      final beforeX = c.currentState.nodes['node-0']!.position.dx;
      final gesture =
          await tester.startGesture(benchNodeCenter(c, 'node-0'));
      await tester.pump();
      for (var step = 0; step < 10; step++) {
        final sw = Stopwatch()..start();
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
        sw.stop();
        perPump.add(sw.elapsedMicroseconds / 1000.0);
      }
      await gesture.up();
      await tester.pump();
      expect(c.currentState.nodes['node-0']!.position.dx,
          greaterThan(beforeX + 5));
    }
    benchReport('LATTICE', 'sweep drag ${sweepTag(100, false, true)}',
        benchStats('drag per-pump ms', perPump));
  });

  testWidgets('sweep select 100 chain cull-on', (tester) async {
    final taps = <double>[];
    for (var i = 0; i < sweepRuns(100); i++) {
      final c = await pumpSweepCanvas(tester, 200 + i, 100, false, true);
      await benchSettle(tester);
      final sw = Stopwatch()..start();
      await tester.tapAt(benchNodeCenter(c, 'node-0'));
      await tester.pump();
      sw.stop();
      expect(c.currentState.selectedNodes.contains('node-0'), isTrue);
      taps.add(sw.elapsedMicroseconds / 1000.0);
    }
    benchReport('LATTICE', 'sweep select ${sweepTag(100, false, true)}',
        benchStats('select ms', taps));
  });

  testWidgets('sweep relocate 100 chain cull-on', (tester) async {
    final totals = <double>[];
    for (var i = 0; i < sweepRuns(100); i++) {
      final c = await pumpSweepCanvas(tester, 300 + i, 100, false, true);
      await benchSettle(tester);
      final rng = math.Random(42 + i);
      final moved = <String, FlowNode>{};
      for (final e in c.currentState.nodes.entries) {
        moved[e.key] = e.value.copyWith(
          position:
              Offset(rng.nextDouble() * 3200, rng.nextDouble() * 2400),
        );
      }
      final sw = Stopwatch()..start();
      c.load(c.currentState.copyWith(nodes: moved));
      await c.viewport.fitView();
      await benchSettle(tester);
      sw.stop();
      totals.add(sw.elapsedMicroseconds / 1000.0);
    }
    benchReport('LATTICE', 'sweep relocate ${sweepTag(100, false, true)}',
        benchStats('relocate+fit total ms', totals));
  });

  testWidgets('sweep remount 100 chain cull-on', (tester) async {
    final remounts = <double>[];
    for (var i = 0; i < sweepRuns(100); i++) {
      final sw = Stopwatch()..start();
      final c = await pumpSweepCanvas(tester, 400 + i, 100, false, true);
      await benchSettle(tester);
      sw.stop();
      expect(c.currentState.nodes.length, 100);
      remounts.add(sw.elapsedMicroseconds / 1000.0);
    }
    benchReport('LATTICE', 'sweep remount ${sweepTag(100, false, true)}',
        benchStats('remount total ms', remounts));
  });
}
