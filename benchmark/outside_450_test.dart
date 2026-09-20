// ignore_for_file: prefer_const_constructors, avoid_print
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Outside-in 450-node benchmark: BLACK-BOX only.
///
/// Same fixture, same scenarios, same harness as the VNF counterpart
/// (`bench_outside_450_test.dart` in vyuh_node_flow). Everything here goes
/// through public API: [FlowCanvas] + [FlowCanvasController] facade +
/// tester gestures. No `src/` imports, no services, no providers.
///
/// Fixture: 30x15 grid (x*100, y*50), RF-exact 50x30 nodes (no overlaps),
/// 449 chain edges, 800x600 canvas, minZoom 0.2, default theme.
/// Keyed remounts every iteration so each mount is a true fresh inflate.
///
/// Run explicitly: `flutter test benchmark/outside_450_test.dart`
/// Run ALONE on a quiet machine (no concurrent flutter/chrome/vite).

const int cols = 30;
const int rows = 15;
const int nodeCount = cols * rows;
const int runs = 3;

/// Capability variant: `--dart-define=LATTICE_BENCH_CULL=true` mounts with
/// viewport culling on (same flag RF users opt into for large graphs).
const bool benchCull = bool.fromEnvironment('LATTICE_BENCH_CULL');

/// Node chrome variant, selected via `--dart-define=LATTICE_BENCH_NODE=...`:
///
/// - `fair` (default): `BaseNode` + decoration + 2 handles + centered text.
///   Matches VNF's benchmark node (decoration + 2 ports + text) element-for-
///   element — the only apples-to-apples comparison.
/// - `bare`: builder returns just the `SizedBox+Text` body (no decoration, no
///   handles). Isolates the cost of lattice's gesture shell + a11y proxy.
/// - `chrome`: `BaseNode` + text but ZERO handles. Subtracted from `fair`,
///   isolates the per-node handle-widget cost from the BaseNode chrome cost.
/// - `default`: the built-in `default` node type (BaseNode + auto-handles, no
///   text) — what a user gets if they don't supply a custom node.
const String benchNodeVariant =
    String.fromEnvironment('LATTICE_BENCH_NODE', defaultValue: 'fair');

/// Shared 50x30 centered id label at fontSize 8 — byte-identical to the VNF
/// counterpart's `nodeBuilder` body.
Widget benchLabel(String id) =>
    Center(child: Text(id, style: const TextStyle(fontSize: 8)));

/// Two handles matching VNF's 2 ports (left target, right source), so the
/// `fair` node renders the same handle count VNF renders port count.
Map<String, FlowHandle> benchHandles() => const {
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

NodeRegistry buildRegistry() {
  final registry = NodeRegistry();
  switch (benchNodeVariant) {
    case 'bare':
      registry.register(
        'bench',
        (node) => SizedBox(width: 50, height: 30, child: benchLabel(node.id)),
      );
    case 'fair':
    case 'chrome':
      registry.register(
        'bench',
        (node) => BaseNode(node: node, child: benchLabel(node.id)),
      );
    // 'default' uses the built-in type; no custom registration needed.
  }
  return registry;
}

Map<String, FlowNode<String>> buildNodes() {
  final useDefault = benchNodeVariant == 'default';
  final nodes = <String, FlowNode<String>>{};
  for (var i = 0; i < nodeCount; i++) {
    nodes['node-$i'] = FlowNode<String>(
      type: useDefault ? 'default' : 'bench',
      id: 'node-$i',
      position: Offset((i % cols) * 100.0, (i ~/ cols) * 50.0),
      size: const Size(50, 30),
      data: 'node-$i',
      // 'fair' attaches the 2 handles explicitly; 'default' synthesizes its
      // own; 'bare' gets none.
      handles: benchNodeVariant == 'fair' ? benchHandles() : const {},
    );
  }
  return nodes;
}

Map<String, FlowEdge> buildEdges() {
  final edges = <String, FlowEdge>{};
  for (var i = 1; i < nodeCount; i++) {
    edges['conn-$i'] = FlowEdge(
      id: 'conn-$i',
      sourceNodeId: 'node-${i - 1}',
      targetNodeId: 'node-$i',
    );
  }
  return edges;
}

Map<String, dynamic> stats(String name, List<double> values) {
  final sorted = [...values]..sort();
  final sum = sorted.fold(0.0, (a, b) => a + b);
  double q(double p) =>
      sorted[(p * sorted.length).floor().clamp(0, sorted.length - 1)];
  String f(double v) => v.toStringAsFixed(3);
  return {
    'scenario': name,
    'n': sorted.length,
    'mean': double.parse(f(sum / sorted.length)),
    'p50': double.parse(f(q(0.5))),
    'p95': double.parse(f(q(0.95))),
    'max': double.parse(f(sorted.last)),
  };
}

Future<FlowCanvasController> pumpCanvas(
    WidgetTester tester, int run) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          key: ValueKey('canvas-$run'),
          controller: controller,
          nodeRegistry: buildRegistry(),
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: benchCull,
            ),
          ),
          initialNodes: buildNodes().values.toList(),
          initialEdges: buildEdges().values.toList(),
        ),
      ),
    ),
  );
  return controller;
}

/// Pumps until no frames are scheduled (cap). Returns frame count.
Future<int> settle(WidgetTester tester, {int cap = 240}) async {
  var frames = 0;
  await tester.pump();
  frames++;
  while (tester.binding.hasScheduledFrame && frames < cap) {
    await tester.pump();
    frames++;
  }
  return frames;
}

Offset nodeCenter(FlowCanvasController controller, String id) {
  final node = controller.currentState.nodes[id]!;
  return controller.viewport.flowToViewport(
    node.position + Offset(node.size.width / 2, node.size.height / 2),
  );
}

void report(String label, Map<String, dynamic> payload) {
  print('LATTICE $label: ${const JsonEncoder().convert(payload)}');
}

void main() {
  testWidgets('bench mount', (tester) async {
    // Warmup (untimed): first-frame JIT + first inflate.
    final warm = await pumpCanvas(tester, -1);
    await settle(tester);
    expect(warm.currentState.nodes.length, nodeCount);

    final mounts = <double>[];
    final settleFrames = <int>[];
    for (var i = 0; i < runs; i++) {
      final sw = Stopwatch()..start();
      final controller = await pumpCanvas(tester, i);
      final frames = await settle(tester);
      sw.stop();
      expect(controller.currentState.nodes.length, nodeCount);
      mounts.add(sw.elapsedMicroseconds / 1000.0);
      settleFrames.add(frames);
    }
    report('mount', stats('mount (pumpWidget + settle, ms)', mounts));
    print('LATTICE mount settleFrames=$settleFrames');
  });

  testWidgets('bench drag', (tester) async {
    final dragFrames = <double>[];
    for (var i = 0; i < runs; i++) {
      final controller = await pumpCanvas(tester, 100 + i);
      await settle(tester);
      final beforeX =
          controller.currentState.nodes['node-0']!.position.dx;
      final gesture =
          await tester.startGesture(nodeCenter(controller, 'node-0'));
      await tester.pump();
      // NOTE: 10px steps (same 100px total as RF's 20x5px), dragging RIGHT:
      // node-0 sits at the screen's top-left corner, so leftward moves
      // exit the view immediately. Identical treatment on both sides.
      for (var step = 0; step < 10; step++) {
        final sw = Stopwatch()..start();
        await gesture.moveBy(const Offset(10, 0));
        await tester.pump();
        sw.stop();
        dragFrames.add(sw.elapsedMicroseconds / 1000.0);
      }
      await gesture.up();
      await tester.pump();
      // The drag must actually move the node (guards no-op measurements).
      expect(
        controller.currentState.nodes['node-0']!.position.dx,
        greaterThan(beforeX + 5),
      );
    }
    report('drag',
        stats('node drag (10 x 10px moves), per-pump ms', dragFrames));
  });

  testWidgets('bench select', (tester) async {
    final selectFrames = <double>[];
    for (var i = 0; i < runs; i++) {
      final controller = await pumpCanvas(tester, 200 + i);
      await settle(tester);
      final sw = Stopwatch()..start();
      await tester.tapAt(nodeCenter(controller, 'node-0'));
      await tester.pump();
      sw.stop();
      expect(
        controller.currentState.selectedNodes.contains('node-0'),
        isTrue,
      );
      selectFrames.add(sw.elapsedMicroseconds / 1000.0);
    }
    report('select', stats('node tap-select, per-pump ms', selectFrames));
  });

  testWidgets('bench changePos', (tester) async {
    final changeTotals = <double>[];
    final changePumps = <int>[];
    for (var i = 0; i < runs; i++) {
      final controller = await pumpCanvas(tester, 300 + i);
      await settle(tester);
      // Seeded Random: identical targets on both libraries (same VM).
      final rng = math.Random(42 + i);
      final moved = <String, FlowNode>{};
      for (final entry in controller.currentState.nodes.entries) {
        moved[entry.key] = entry.value.copyWith(
          position: Offset(
              rng.nextDouble() * 800 * 4, rng.nextDouble() * 600 * 4),
        );
      }
      final sw = Stopwatch()..start();
      controller.load(controller.currentState.copyWith(nodes: moved));
      await controller.viewport.fitView();
      final frames = await settle(tester);
      sw.stop();
      changeTotals.add(sw.elapsedMicroseconds / 1000.0);
      changePumps.add(frames);
    }
    report('changePos',
        stats('move 450 to seeded targets + fitView, total ms', changeTotals));
    print('LATTICE changePos meanPumps='
        '${changePumps.fold(0, (a, b) => a + b) / changePumps.length}');
  });

  testWidgets('bench remount', (tester) async {
    final remounts = <double>[];
    for (var i = 0; i < runs; i++) {
      final sw = Stopwatch()..start();
      final controller = await pumpCanvas(tester, 400 + i);
      await settle(tester);
      sw.stop();
      expect(controller.currentState.nodes.length, nodeCount);
      remounts.add(sw.elapsedMicroseconds / 1000.0);
    }
    report('remount', stats('full remount, total ms', remounts));
  });
}
