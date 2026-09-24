// ignore_for_file: prefer_const_constructors, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

import 'bench_helpers.dart';

class CountingRegistry extends NodeRegistry {
  int builds = 0;

  @override
  Widget buildWidget(NodeProps props) {
    builds++;
    return super.buildWidget(props);
  }
}

/// Node count override: --dart-define=PROBE_N=45
const int probeN = int.fromEnvironment('PROBE_N', defaultValue: 450);

/// Culling variant: --dart-define=CULL=true (bool.fromEnvironment only
/// accepts "true"; "=1" silently parses to false).
const bool probeCull = bool.fromEnvironment('CULL');

Map<String, FlowNode<String>> buildNodes() =>
    benchGridNodes(count: probeN, cols: 30);

Map<String, FlowEdge> buildEdges() => benchChainEdges(probeN);

void main() {
  /// Set via --dart-define: NOSEM=true (wrap in ExcludeSemantics), TINY=true
  /// (trivial node widgets instead of DefaultNode). NOTE: bool.fromEnvironment
  /// only accepts "true"; "=1" silently parses to false.
  const noSem = bool.fromEnvironment('NOSEM');
  const tiny = bool.fromEnvironment('TINY');

  testWidgets('bisect select cost', (tester) async {
    var dragUpdates = 0;
    var dragStarts = 0;
    var dragStops = 0;
    final registry = CountingRegistry();
    if (tiny) {
      registry.register(
          'default', (node) => const SizedBox(width: 50, height: 30));
    }
    final controller = FlowCanvasController();
    Widget canvas = SizedBox(
      width: 800,
      height: 600,
      child: FlowCanvas(
        key: const ValueKey('bisect'),
        controller: controller,
        nodeRegistry: registry,
        callbacks: FlowCanvasCallbacks(
          onNodeDrag: (_) => dragUpdates++,
          onNodeDragStart: (_) => dragStarts++,
          onNodeDragStop: (_) => dragStops++,
        ),
        options: FlowCanvasOptions(
          viewportOptions: ViewportOptions(
            minZoom: 0.2,
            onlyRenderVisibleElements: probeCull,
          ),
        ),
        initialNodes: buildNodes().values.toList(),
        initialEdges: buildEdges().values.toList(),
      ),
    );
    if (noSem) canvas = ExcludeSemantics(child: canvas);
    await tester.pumpWidget(MaterialApp(home: canvas));
    await benchSettle(tester);
    print('SEL settled builds=${registry.builds} cull=$probeCull');
    FlowCanvasDebug.resetCounters();

    // Fresh-canvas drag of node-0 (bench drag fails under culling with 0.0).
    FlowCanvasDebug.logInteraction = probeCull;
    final freshDx0 =
        controller.currentState.nodes['node-0']!.position.dx;
    final freshGesture =
        await tester.startGesture(benchNodeCenter(controller, 'node-0'));
    await tester.pump();
    for (var i = 0; i < 10; i++) {
      await freshGesture.moveBy(const Offset(10, 0));
      await tester.pump();
      if (probeCull) {
        print('SEL fresh-drag i=$i '
            'mode=${controller.currentState.dragMode} '
            'sel=${controller.currentState.selectedNodes}');
      }
    }
    await freshGesture.up();
    await tester.pump();
    FlowCanvasDebug.logInteraction = false;
    print('SEL fresh-drag-node0 '
        'starts=$dragStarts updates=$dragUpdates stops=$dragStops '
        'commits=${FlowCanvasDebug.dragCommits}');
    print('SEL fresh-drag-node0 '
        'dx=${controller.currentState.nodes['node-0']!.position.dx - freshDx0} '
        'mode=${controller.currentState.dragMode} '
        'sel=${controller.currentState.selectedNodes}');

    var sw = Stopwatch()..start();
    final before = registry.builds;
    controller.selection.selectNode('node-0');
    await tester.pump();
    sw.stop();
    print('SEL direct-select=${sw.elapsedMilliseconds}ms '
        'bodies=${registry.builds - before} '
        'mounted=${FlowCanvasDebug.nodesBuilt} '
        'selected=${controller.currentState.selectedNodes.contains('node-0')}');

    sw = Stopwatch()..start();
    final before2 = registry.builds;
    controller.selection.deselectAll();
    await tester.pump();
    sw.stop();
    print('SEL direct-deselect=${sw.elapsedMilliseconds}ms '
        'bodies=${registry.builds - before2}');

    sw = Stopwatch()..start();
    final before3 = registry.builds;
    await tester.tapAt(benchNodeCenter(controller, 'node-0'));
    await tester.pump();
    sw.stop();
    print('SEL tap-select=${sw.elapsedMilliseconds}ms '
        'bodies=${registry.builds - before3} '
        'selected=${controller.currentState.selectedNodes.contains('node-0')}');

    expect(controller.currentState.selectedNodes.contains('node-0'), isTrue);

    // Drag repro (bench drag failed with displacement 0.0 under culling).
    final startDx =
        controller.currentState.nodes['node-1']!.position.dx;
    final gesture =
        await tester.startGesture(benchNodeCenter(controller, 'node-1'));
    for (var i = 0; i < 10; i++) {
      await gesture.moveBy(const Offset(10, 0));
      await tester.pump();
      if (i % 3 == 2) {
        print('SEL drag i=$i '
            'dx=${controller.currentState.nodes['node-1']!.position.dx - startDx} '
            'mode=${controller.currentState.dragMode}');
      }
    }
    await gesture.up();
    await tester.pump();
    print('SEL drag-final '
        'dx=${controller.currentState.nodes['node-1']!.position.dx - startDx} '
        'mode=${controller.currentState.dragMode} '
        'drags=${FlowCanvasDebug.dragCommits}');
  });
}
