// ignore_for_file: prefer_const_constructors, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';

/// Headless 450-node logic benchmark — the fair counterpart to VNF's
/// `test/performance/vnf_450_benchmark.dart`.
///
/// Same harness (`flutter test`, debug JIT), same workload shape, NO widget
/// tree on either side: pure controller/service calls timed with Stopwatch.
/// (Widget-pump numbers measure Flutter's rendering pipeline, not library
/// logic — those live in `benchmark/stress_450_test.dart`.)
///
/// Run explicitly: `flutter test benchmark/headless_450_test.dart`

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

FlowCanvasState _mount() {
  final nodes = NodeService();
  final edges = EdgeService();
  var state = FlowCanvasState.initial();
  for (var i = 0; i < 450; i++) {
    state = nodes.addNode(state, _node(i));
  }
  for (var i = 1; i < 450; i++) {
    state = edges.addEdge(state, _edge(i));
  }
  return state;
}

void main() {
  final nodes = NodeService();
  final selection = SelectionService();
  final viewport = ViewportService();

  test('mount 450 nodes + 449 edges', () {
    final sw = Stopwatch()..start();
    final state = _mount();
    sw.stop();
    print('MOUNT: ${sw.elapsedMilliseconds}ms');
    expect(state.nodes.length, 450);
    expect(state.edges.length, 449);
  });

  test('drag node 200 left 20 steps', () {
    var state = _mount();
    final sw = Stopwatch()..start();
    for (var i = 0; i < 20; i++) {
      state = nodes.moveNodes(state, const ['node-200'], const Offset(-5, 0));
    }
    sw.stop();
    print('DRAG (20 moves): ${sw.elapsedMilliseconds}ms');
    expect(
      state.nodes['node-200']!.position.dx,
      _node(200).position.dx - 100,
    );
  });

  test('click-select node 200', () {
    var state = _mount();
    final sw = Stopwatch()..start();
    state = selection.toggleNodeSelection(state, 'node-200');
    state = selection.deselectAll(state);
    sw.stop();
    print('SELECT: ${sw.elapsedMilliseconds}ms');
    expect(state.selectedNodes, isEmpty);
  });

  test('changePos (move 450 + bounds)', () {
    var state = _mount();
    final sw = Stopwatch()..start();
    for (var i = 0; i < 450; i++) {
      state = nodes.moveNodes(
        state,
        ['node-$i'],
        Offset((i % 30) * 100.0, (i ~/ 30) * 50.0),
      );
    }
    final bounds = viewport.getNodesBounds(
      nodes: state.nodes.values.toList(),
    );
    sw.stop();
    print(
        'CHANGE_POS (move 450 + bounds): ${sw.elapsedMilliseconds}ms (${bounds.rect.width.toStringAsFixed(0)}x${bounds.rect.height.toStringAsFixed(0)})');
    expect(bounds.rect.width, greaterThan(0));
  });

  test('remount (fresh state + re-add all)', () {
    _mount();
    final sw = Stopwatch()..start();
    final state = _mount();
    sw.stop();
    print('REMOUNT: ${sw.elapsedMilliseconds}ms');
    expect(state.nodes.length, 450);
  });
}
