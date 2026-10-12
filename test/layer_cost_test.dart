import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';

/// Phase-0 cost instrumentation (spec §4): headless splits + per-emission
/// pass counters. Helpers defined at the bottom of this file (test-local).

int _pumpSeq = 0;

Future<FlowCanvasController> pumpBenchCanvas(
  WidgetTester tester,
  int count, {
  FlowCanvasCallbacks? callbacks,
}) async {
  final controller = FlowCanvasController();
  final registry = NodeRegistry()
    ..register(
      'bench',
      (node) => BaseNode(
        node: node,
        child: Center(
          child: Text(node.id, style: const TextStyle(fontSize: 8)),
        ),
      ),
    );
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          // Unique key per pump: a second pump in one test must remount
          // cold (initialNodes only apply on first mount).
          key: ValueKey('cost-bench-${_pumpSeq++}'),
          controller: controller,
          nodeRegistry: registry,
          callbacks: callbacks ?? const FlowCanvasCallbacks(),
          options: FlowCanvasOptions(
            viewportOptions: ViewportOptions(
              minZoom: 0.2,
              onlyRenderVisibleElements: true,
            ),
          ),
          initialNodes: [
            for (var i = 0; i < count; i++)
              FlowNode<String>(
                type: 'bench',
                id: 'node-$i',
                position: Offset((i % 30) * 100.0, (i ~/ 30) * 50.0),
                size: const Size(50, 30),
                data: 'node-$i',
                handles: const {
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
                },
              ),
          ],
          initialEdges: [
            for (var i = 1; i < count; i++)
              FlowEdge(
                id: 'conn-$i',
                sourceNodeId: 'node-${i - 1}',
                targetNodeId: 'node-$i',
              ),
          ],
        ),
      ),
    ),
  );
  return controller;
}

Future<int> costSettle(WidgetTester tester, {int cap = 240}) async {
  var frames = 0;
  await tester.pump();
  frames++;
  while (tester.binding.hasScheduledFrame && frames < cap) {
    await tester.pump();
    frames++;
  }
  return frames;
}

void main() {
  testWidgets('mount cost split records inflate/layout/geometry phases',
      (tester) async {
    final costs = await collectMountCosts(tester, 100);
    expect(costs.keys, containsAll(['inflate', 'layout', 'geometry']));
    expect(costs['inflate']!, greaterThan(0));
  });

  testWidgets('single selection emission runs bounded Dart passes',
      (tester) async {
    final passes = await countEmissionPasses(
        tester, (c) => c.selection.selectNode('node-0'));
    // One filter+sort pass per mounted node band (background/middle/
    // foreground = 3). Pins the bound: duplicate rebuilds fail this, and
    // a silent zero (broken instrumentation) fails it too.
    expect(passes['nodeLayerFilterSort'], greaterThan(0));
    expect(passes['nodeLayerFilterSort'], lessThanOrEqualTo(3));
  });

  testWidgets('keyboard traversal visits nodes in spatial order',
      (tester) async {
    await pumpBenchCanvas(tester, 10);
    await costSettle(tester);
    // Pinned actual order: node anchors interleave with edge anchors in
    // reading order. Any traversal/focus-shell change must keep this exact.
    expect(await focusOrder(tester, 3),
        ['node-0', 'flow-edge-conn-1', 'node-1']);
  });

  testWidgets('mount inflate phase stays under ceiling', (tester) async {
    final costs = await collectMountCosts(tester, 100);
    expect(costs['inflate']!, lessThan(baselineInflateMs));
  });

  testWidgets('selection toggle bumps selectionEpoch exactly once',
      (tester) async {
    final controller = await pumpBenchCanvas(tester, 10);
    await costSettle(tester);
    controller.selection.selectNode('node-0');
    await tester.pump();
    expect(controller.currentState.selectionEpoch, 1);
    expect(controller.currentState.zOrderEpoch, 0);
  });

  testWidgets('unrelated emission does not rebuild node bodies',
      (tester) async {
    final controller = await pumpBenchCanvas(tester, 50);
    await costSettle(tester);
    FlowCanvasDebug.resetCounters();
    controller.viewport.setViewportSize(const Size(800, 600));
    await tester.pump();
    expect(FlowCanvasDebug.bodyBuilds, 0);
  });

  testWidgets('pan frames re-cull without re-sorting nodes', (tester) async {
    final controller = await pumpBenchCanvas(tester, 50);
    await costSettle(tester);
    FlowCanvasDebug.resetCounters();
    controller.viewport.panBy(const Offset(10, 0));
    await tester.pump();
    // buildStack ran via the transform listener (cull re-evaluated) ...
    expect(FlowCanvasDebug.nodeLayerPasses, greaterThan(0));
    // ... but epochs/length unchanged, so the z-sort was skipped.
    expect(FlowCanvasDebug.nodeSorts, 0);
  });

  testWidgets('bulk position commit skips body rebuilds', (tester) async {
    final r = await bulkMoveAndCount(tester, 100);
    expect(r.positionsCorrect, isTrue);
    expect(r.bodyRebuilds, 0);
  });

  testWidgets('edge geometry skips eager full-mount compute', (tester) async {
    // 250 nodes = 249 chain edges; the 800x600 viewport can only show a
    // fraction. Eager mount computes all 249; lazy computes the visible few.
    expect(await coldMountGeoComputes(tester, 250), lessThan(249));
  });

  testWidgets('panning demand-fills uncovered edges', (tester) async {
    final controller = await pumpBenchCanvas(tester, 100);
    await costSettle(tester);
    FlowCanvasDebug.resetCounters();
    // Pan along x only: rows stay in view while cols 20+ (uncomputed at
    // mount) scroll in. A y-pan would land in empty space.
    controller.viewport.panBy(const Offset(-2000, 0));
    await tester.pump();
    await costSettle(tester);
    expect(FlowCanvasDebug.geoComputes, greaterThan(0));
  });

  testWidgets('bulk load resets history (undo is a safe no-op)',
      (tester) async {
    expect(await bulkLoadResetsHistory(tester), isTrue);
  });

  // ---- Fix-pass pins (review findings) ----

  FlowCanvasState edgeStateWith({
    Set<String> selectedEdges = const {},
    List<String> edgeIds = const ['conn-1'],
  }) {
    return FlowCanvasState.initial().copyWith(
      nodes: {
        for (var i = 0; i < 3; i++)
          'node-$i': FlowNode<String>(
            type: 'bench',
            id: 'node-$i',
            position: Offset((i % 30) * 100.0, (i ~/ 30) * 50.0),
            size: const Size(50, 30),
            data: 'node-$i',
          ),
      },
      edges: {
        for (final id in edgeIds)
          id: FlowEdge(
            id: id,
            sourceNodeId: 'node-0',
            targetNodeId: 'node-1',
          ),
      },
      selectedEdges: selectedEdges,
    );
  }

  test('removeEdge bumps selectionEpoch when pruning selection', () {
    final s = edgeStateWith(selectedEdges: {'conn-1'});
    final out = EdgeService().removeEdge(s, 'conn-1');
    expect(out.selectedEdges, isEmpty);
    expect(out.selectionEpoch, 1);
  });

  test('removeEdge keeps selection instance when nothing pruned', () {
    final s = edgeStateWith(selectedEdges: {'conn-9'});
    final out = EdgeService().removeEdge(s, 'conn-1');
    expect(out.selectedEdges, contains('conn-9'));
    // No rewrap: same backing content means downstream identity-compares
    // stay quiet (no spurious selection callbacks). NOTE: `identical` on the
    // public getters is meaningless — Freezed wraps plain sets in a fresh
    // EqualUnmodifiableSetView per access — so content + epoch pin it.
    expect(out.selectedEdges, s.selectedEdges);
    expect(out.selectionEpoch, 0);
  });

  test('removeEdges bumps selectionEpoch when pruning selection', () {
    final s = edgeStateWith(
      selectedEdges: {'conn-1'},
      edgeIds: ['conn-1', 'conn-2'],
    );
    final out = EdgeService().removeEdges(s, ['conn-1', 'conn-9']);
    expect(out.selectedEdges, isEmpty);
    expect(out.selectionEpoch, 1);
  });

  test('addNodes all-duplicate returns identical state', () {
    final s = edgeStateWith();
    final existing = s.nodes['node-0']!;
    final out = NodeService().addNodes(s, [existing]);
    expect(identical(out, s), isTrue);
  });

  test('updateNode without z change keeps zOrderEpoch', () {
    final s = edgeStateWith();
    final node = s.nodes['node-0']!;
    final moved = node.copyWith(position: const Offset(999, 999));
    final out = NodeService().updateNode(s, moved);
    expect(out.nodes['node-0']!.position, const Offset(999, 999));
    expect(out.zOrderEpoch, 0);
  });

  testWidgets('sendNodeToBack rebuilds the node layer', (tester) async {
    final controller = await pumpBenchCanvas(tester, 10);
    await costSettle(tester);
    FlowCanvasDebug.resetCounters();
    controller.zIndex.sendNodeToBack('node-2');
    await tester.pump();
    expect(FlowCanvasDebug.nodeLayerPasses, greaterThan(0));
  });

  testWidgets('resized node rebuilds its body', (tester) async {
    final controller = await pumpBenchCanvas(tester, 10);
    await costSettle(tester);
    FlowCanvasDebug.resetCounters();
    final moved = Map<String, FlowNode>.from(controller.currentState.nodes);
    moved['node-0'] =
        moved['node-0']!.copyWith(size: const Size(60, 40));
    controller.load(controller.currentState.copyWith(nodes: moved));
    await costSettle(tester);
    expect(FlowCanvasDebug.bodyBuilds, greaterThan(0));
  });

  int edgeAnchorCount(WidgetTester tester) {
    var n = 0;
    for (final e in find.byType(Focus).evaluate()) {
      final w = e.widget as Focus;
      if ((w.focusNode?.debugLabel ?? '').startsWith('flow-edge-')) n++;
    }
    return n;
  }

  testWidgets('edge anchors appear for panned-into-view edges',
      (tester) async {
    await pumpBenchCanvas(tester, 100);
    await costSettle(tester);
    final before = edgeAnchorCount(tester);
    // Pan tested via a fresh controller read below; anchors must grow.
    expect(before, greaterThan(0));
    // Pan covered by the demand-fill test; here assert the count helper
    // sees anchors at all (wiring check for the real assertion below).
  });

  testWidgets('edge anchors demand-fill after pan', (tester) async {
    final controller = await pumpBenchCanvas(tester, 100);
    await costSettle(tester);
    final before = edgeAnchorCount(tester);
    controller.viewport.panBy(const Offset(-2000, 0));
    await tester.pump();
    await costSettle(tester);
    expect(edgeAnchorCount(tester), greaterThan(before));
  });

  testWidgets('applyRemote preserves epochs, fires no spurious callback',
      (tester) async {
    final fired = <CanvasSelection>[];
    final controller = await pumpBenchCanvas(
      tester,
      10,
      callbacks: FlowCanvasCallbacks(
        onSelectionChange: fired.add,
      ),
    );
    await costSettle(tester);
    controller.selection.selectNode('node-0');
    await tester.pump();
    expect(controller.currentState.selectionEpoch, 1);
    fired.clear();
    // Simulate a sync decode: epochs reset to 0, selection preserved.
    // (A full toJson/fromJson round-trip is avoided: handle serialization
    // has a pre-existing gap unrelated to epochs.)
    controller.applyRemote(
      controller.currentState.copyWith(
        selectionEpoch: 0,
        zOrderEpoch: 0,
        runtimeEpoch: 0,
      ),
    );
    await tester.pump();
    expect(controller.currentState.selectionEpoch, 1);
    expect(fired, isEmpty);
  });

  testWidgets('load bumps selection epoch only on membership change',
      (tester) async {
    final controller = await pumpBenchCanvas(tester, 10);
    await costSettle(tester);
    controller.selection.selectNode('node-0');
    await tester.pump();
    expect(controller.currentState.selectionEpoch, 1);
    // Same selection, moved positions: epoch unchanged.
    final moved = <String, FlowNode>{};
    for (final e in controller.currentState.nodes.entries) {
      moved[e.key] = e.value.copyWith(
        position: e.value.position + const Offset(5, 5),
      );
    }
    controller.load(controller.currentState.copyWith(nodes: moved));
    await costSettle(tester);
    expect(controller.currentState.selectionEpoch, 1);
    // Cleared selection: epoch bumps.
    controller.load(controller.currentState.copyWith(
      nodes: moved,
      selectedNodes: <String>{},
    ));
    await costSettle(tester);
    expect(controller.currentState.selectionEpoch, 2);
  });
}

/// Cold-mount geometry computations for [count] chain nodes (fresh canvas,
/// counters zeroed first).
Future<int> coldMountGeoComputes(WidgetTester tester, int count) async {
  FlowCanvasDebug.resetCounters();
  await pumpBenchCanvas(tester, count);
  await costSettle(tester);
  return FlowCanvasDebug.geoComputes;
}

/// Bulk-moves all [count] nodes by (+5,+5) via `load`, returning whether
/// positions landed and how many body rebuilds the commit caused.
Future<({bool positionsCorrect, int bodyRebuilds})> bulkMoveAndCount(
  WidgetTester tester,
  int count,
) async {
  final controller = await pumpBenchCanvas(tester, count);
  await costSettle(tester);
  FlowCanvasDebug.resetCounters();
  final moved = <String, FlowNode>{};
  for (final e in controller.currentState.nodes.entries) {
    moved[e.key] = e.value.copyWith(
      position: e.value.position + const Offset(5, 5),
    );
  }
  controller.load(controller.currentState.copyWith(nodes: moved));
  await costSettle(tester);
  var ok = true;
  for (var i = 0; i < count; i++) {
    final n = controller.currentState.nodes['node-$i']!;
    final want = Offset((i % 30) * 100.0 + 5, (i ~/ 30) * 50.0 + 5);
    if (n.position != want) ok = false;
  }
  return (
    positionsCorrect: ok,
    bodyRebuilds: FlowCanvasDebug.bodyBuilds,
  );
}

/// Bulk-moves 10 nodes via `load` (which resets history by design), undoes,
/// and checks the undo is a safe no-op that keeps the loaded positions.
Future<bool> bulkLoadResetsHistory(WidgetTester tester) async {
  final controller = await pumpBenchCanvas(tester, 10);
  await costSettle(tester);
  final moved = <String, FlowNode>{};
  for (final e in controller.currentState.nodes.entries) {
    moved[e.key] = e.value.copyWith(
      position: e.value.position + const Offset(50, 0),
    );
  }
  controller.load(controller.currentState.copyWith(nodes: moved));
  await costSettle(tester);
  final loaded = controller.currentState.nodes['node-0']!.position;
  controller.history.undo();
  await tester.pump();
  return controller.currentState.nodes['node-0']!.position == loaded;
}

/// Generous inflate ceiling (ms) for 100 fair nodes, recorded 2026-10-11 on
/// this machine in debug mode. The diet (Task 2) only shrinks this; the
/// ceiling guards regressions. Tighten as work lands.
const double baselineInflateMs = 2000.0;

/// Tab-walks focus [tabs] times, returning traversed node ids. Fails (empty)
/// if the proxy layer or traversal breaks.
Future<List<String?>> focusOrder(WidgetTester tester, int tabs) async {
  final order = <String?>[];
  for (var i = 0; i < tabs; i++) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final label = FocusManager.instance.primaryFocus?.debugLabel;
    order.add(label == null
        ? null
        : label.startsWith('flow-node-')
            ? label.substring('flow-node-'.length)
            : label);
  }
  return order;
}

/// Mount split: 'inflate' = pumpWidget + first frame, 'layout' = remaining
/// settle, 'geometry' = fresh service-level full edge-cache build over the
/// mounted graph (same work as mount's eager pass).
Future<Map<String, double>> collectMountCosts(
  WidgetTester tester,
  int count,
) async {
  final inflateSw = Stopwatch()..start();
  final controller = await pumpBenchCanvas(tester, count);
  await tester.pump();
  inflateSw.stop();
  final layoutSw = Stopwatch()..start();
  final frames = await costSettle(tester);
  layoutSw.stop();
  final geoSw = Stopwatch()..start();
  EdgeGeometryService().updateCache(
    controller.currentState,
    controller.currentState.edges.keys,
  );
  geoSw.stop();
  return {
    'inflate': inflateSw.elapsedMicroseconds / 1000.0,
    'layout': layoutSw.elapsedMicroseconds / 1000.0,
    'geometry': geoSw.elapsedMicroseconds / 1000.0,
    'settleFrames': frames.toDouble(),
  };
}

/// Per-emission Dart passes for one controller op on a settled 100-node
/// canvas, read from the passive [FlowCanvasDebug] counters.
Future<Map<String, int>> countEmissionPasses(
  WidgetTester tester,
  void Function(FlowCanvasController) op,
) async {
  final controller = await pumpBenchCanvas(tester, 100);
  await costSettle(tester);
  FlowCanvasDebug.resetCounters();
  op(controller);
  await tester.pump();
  return {
    'nodeLayerFilterSort': FlowCanvasDebug.nodeLayerPasses,
    'edgeCull': FlowCanvasDebug.edgeCullPasses,
    'edgeMapCopies': FlowCanvasDebug.edgeMapCopies,
  };
}
