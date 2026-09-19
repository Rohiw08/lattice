// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';

/// CI perf budgets for the 450-node service path (no widgets).
///
/// These ceilings are deliberately generous (>50x the measured debug numbers)
/// so they NEVER flake on a busy runner: they catch algorithmic regressions
/// (accidental O(n^2), unbounded recompute, infinite loops), not 2x noise.
/// Widget-frame timings are inherently noisy in debug builds and are therefore
/// tracked as artifacts by `benchmark/outside_450_test.dart`, not gated here.
/// The deterministic widget-side contracts (repaint skipping, zero steady-state
/// rebuilds) are pinned by unit tests instead — see
/// `test/edge_painter_test.dart`.
///
/// Run explicitly: `flutter test benchmark/budget_test.dart`

FlowNode<String> _node(int i) => FlowNode<String>(
      type: 'default',
      id: 'node-$i',
      position: Offset((i % 30) * 100.0, (i ~/ 30) * 50.0),
      size: const Size(150, 80),
      data: 'Node $i',
    );

FlowEdge _edge(int i) => FlowEdge(
      id: 'conn-$i',
      sourceNodeId: 'node-${i - 1}',
      sourceHandleId: 'output-1',
      targetNodeId: 'node-$i',
      targetHandleId: 'input-1',
    );

FlowCanvasState _mount(NodeService nodes, EdgeService edges) {
  var state = FlowCanvasState.initial();
  for (var i = 0; i < 450; i++) {
    state = nodes.addNode(state, _node(i));
  }
  for (var i = 1; i < 450; i++) {
    state = edges.addEdge(state, _edge(i));
  }
  return state;
}

/// Fails with the measured time when a ceiling is breached, so the log shows
/// how far off the regression is.
void _withinBudget(String name, Stopwatch sw, int budgetMs) {
  sw.stop();
  print('BUDGET $name: ${sw.elapsedMilliseconds}ms (ceiling ${budgetMs}ms)');
  expect(sw.elapsedMilliseconds, lessThan(budgetMs), reason: name);
}

void main() {
  final nodes = NodeService();
  final edges = EdgeService();
  final selection = SelectionService();
  final viewport = ViewportService();

  test('budget: mount 450 nodes + 449 edges', () {
    final sw = Stopwatch()..start();
    final state = _mount(nodes, edges);
    _withinBudget('mount', sw, 3000);
    expect(state.nodes.length, 450);
    expect(state.edges.length, 449);
  });

  test('budget: 20 drag moves on one node', () {
    var state = _mount(nodes, edges);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      state = nodes.moveNodes(state, const ['node-200'], const Offset(-5, 0));
    }
    _withinBudget('drag-20', sw, 2000);
    expect(
      state.nodes['node-200']!.position.dx,
      _node(200).position.dx - 100,
    );
  });

  test('budget: select + deselect cycle', () {
    var state = _mount(nodes, edges);
    final sw = Stopwatch()..start();
    state = selection.toggleNodeSelection(state, 'node-200');
    state = selection.deselectAll(state);
    _withinBudget('select', sw, 1000);
    expect(state.selectedNodes, isEmpty);
  });

  test('budget: move all 450 + bounds', () {
    var state = _mount(nodes, edges);
    final sw = Stopwatch()..start();
    for (var i = 0; i < 450; i++) {
      state = nodes.moveNodes(
        state,
        ['node-$i'],
        Offset((i % 30) * 100.0, (i ~/ 30) * 50.0),
      );
    }
    final bounds = viewport.getNodeBounds(
      nodes: state.nodes.values.toList(),
    );
    _withinBudget('change-pos', sw, 5000);
    expect(bounds.rect.width, greaterThan(0));
  });

  test('budget: remount from scratch', () {
    _mount(nodes, edges);
    final sw = Stopwatch()..start();
    final state = _mount(nodes, edges);
    _withinBudget('remount', sw, 3000);
    expect(state.nodes.length, 450);
  });
}
