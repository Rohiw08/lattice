// ignore_for_file: prefer_const_constructors, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/nodes/presentation/flow_focusable_node.dart';

import 'bench_helpers.dart';

/// Culling crossover sweep: at what node count does viewport culling
/// (`onlyRenderVisibleElements: true`) stop being a net cost and start
/// being a net win?
///
/// For each (nodeCount, cull) pair this measures:
///   - mount wall time (pumpWidget + settle)
///   - MOUNTED node count (live `FlowFocusableNode`s in the tree — the number
///     culling actually reduces; wall time alone hides what's happening)
///   - drag per-pump ms (p50 / p95 / max — culling injects a one-time
///     spatial-query stall at drag-start, so the tail is what matters)
///
/// Grid is 30 columns wide; rows grow with nodeCount so the graph extends
/// well past the 800x600 viewport — that off-screen bulk is exactly what
/// culling can skip. A near-viewport-sized graph (like the 450 fixture) has
/// little to cull, which is why culling looked flat there.
///
/// Debug JIT inflates absolute numbers ~50x; the RELATIVE on-vs-off gap at
/// each scale is the signal, not the milliseconds.
///
/// Run ALONE on a quiet machine:
///   flutter test benchmark/cull_crossover_test.dart

const int cols = 30;
const int runs = 2;

/// Node counts to sweep. Kept modest at the top end because debug-mode mount
/// is ~linear and expensive (450 nodes ≈ 16s/mount here).
const List<int> sweep = [450, 1000, 2000, 4000];

Map<String, FlowNode<String>> buildNodes(int n) =>
    benchGridNodes(count: n, cols: cols);

Map<String, FlowEdge> buildEdges(int n) => benchChainEdges(n);

Future<FlowCanvasController> pumpCanvas(
  WidgetTester tester,
  int run,
  int nodeCount,
  bool cull,
) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          key: ValueKey('canvas-$nodeCount-$cull-$run'),
          controller: controller,
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: cull,
            ),
          ),
          initialNodes: buildNodes(nodeCount).values.toList(),
          initialEdges: buildEdges(nodeCount).values.toList(),
        ),
      ),
    ),
  );
  return controller;
}

int mountedNodes(WidgetTester tester) =>
    tester.widgetList(find.byType(FlowFocusableNode)).length;

void report(String label, Map<String, dynamic> payload) {
  benchReport('CULLSWEEP', label, payload);
}

void main() {
  testWidgets('cull crossover sweep', (tester) async {
    // Warmup (untimed): pay first-frame JIT once so it doesn't skew run 0.
    final warm = await pumpCanvas(tester, -1, 450, false);
    await benchSettle(tester);
    expect(warm.currentState.nodes.length, 450);

    for (final nodeCount in sweep) {
      for (final cull in [false, true]) {
        final mounts = <double>[];
        final mountedCounts = <int>[];
        final dragFrames = <double>[];

        for (var i = 0; i < runs; i++) {
          // ── mount ──
          final sw = Stopwatch()..start();
          final controller = await pumpCanvas(tester, i, nodeCount, cull);
          await benchSettle(tester);
          sw.stop();
          mounts.add(sw.elapsedMicroseconds / 1000.0);
          mountedCounts.add(mountedNodes(tester));

          // ── drag node-0 (top-left corner), 10 x 10px right ──
          final gesture =
              await tester.startGesture(benchNodeCenter(controller, 'node-0'));
          await tester.pump();
          for (var step = 0; step < 10; step++) {
            final d = Stopwatch()..start();
            await gesture.moveBy(const Offset(10, 0));
            await tester.pump();
            d.stop();
            dragFrames.add(d.elapsedMicroseconds / 1000.0);
          }
          await gesture.up();
          await tester.pump();
        }

        final tag = 'N=$nodeCount cull=$cull';
        report('$tag mount(ms)', benchStats('mount', mounts));
        report('$tag drag(ms)', benchStats('drag', dragFrames));
        print('CULLSWEEP $tag mountedNodes=$mountedCounts '
            '(of $nodeCount)');
      }
    }
  });
}
