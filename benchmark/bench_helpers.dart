// ignore_for_file: avoid_print
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Shared harness bits for the widget-level benchmarks.
///
/// Black-box like the benches themselves: `package:lattice/lattice.dart`
/// only (plus flutter_test types). Keeps `outside_450`, `cull_crossover`,
/// and `probe_sel` from copy-pasting fixture/stats/pump helpers.

/// Flow-space grid position: [cols] columns, 100x50 spacing.
Offset benchGridPos(int i, {int cols = 30}) =>
    Offset((i % cols) * 100.0, (i ~/ cols) * 50.0);

/// 50x30 grid nodes with chain-friendly ids.
Map<String, FlowNode<String>> benchGridNodes({
  required int count,
  int cols = 30,
  String type = 'default',
  Size size = const Size(50, 30),
  Map<String, FlowHandle> handles = const {},
}) {
  final nodes = <String, FlowNode<String>>{};
  for (var i = 0; i < count; i++) {
    nodes['node-$i'] = FlowNode<String>(
      type: type,
      id: 'node-$i',
      position: benchGridPos(i, cols: cols),
      size: size,
      data: 'node-$i',
      handles: handles,
    );
  }
  return nodes;
}

/// Chain edges node-0 -> node-1 -> … (portless; VNF bench resolves ports).
Map<String, FlowEdge> benchChainEdges(int count) {
  final edges = <String, FlowEdge>{};
  for (var i = 1; i < count; i++) {
    edges['conn-$i'] = FlowEdge(
      id: 'conn-$i',
      sourceNodeId: 'node-${i - 1}',
      targetNodeId: 'node-$i',
    );
  }
  return edges;
}

/// p50/mean/max summary for a sample list.
Map<String, dynamic> benchStats(String name, List<double> values) {
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

/// Pumps until no frames are scheduled (cap). Returns frame count.
Future<int> benchSettle(WidgetTester tester, {int cap = 240}) async {
  var frames = 0;
  await tester.pump();
  frames++;
  while (tester.binding.hasScheduledFrame && frames < cap) {
    await tester.pump();
    frames++;
  }
  return frames;
}

/// Screen-space center of [id] through the committed viewport.
Offset benchNodeCenter(FlowCanvasController controller, String id) {
  final node = controller.currentState.nodes[id]!;
  return controller.viewport.flowToViewport(
    node.position + Offset(node.size.width / 2, node.size.height / 2),
  );
}

/// Single-line JSON result: `<PREFIX> <label>: {...}`.
void benchReport(String prefix, String label, Map<String, dynamic> payload) {
  print('$prefix $label: ${const JsonEncoder().convert(payload)}');
}
