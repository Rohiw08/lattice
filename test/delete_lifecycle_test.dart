// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Delete-lifecycle parity (React Flow onBeforeDelete / onDelete /
/// onNodesDelete / onEdgesDelete + deleteElements returning the removed
/// elements).

FlowCanvasState _graph() => FlowCanvasState.initial().copyWith(
      nodes: {
        'a': FlowNode<String>(
          type: 'default',
          id: 'a',
          position: const Offset(100, 100),
          data: 'A',
        ),
        'b': FlowNode<String>(
          type: 'default',
          id: 'b',
          position: const Offset(400, 100),
          data: 'B',
        ),
      },
      edges: {
        'e1': FlowEdge(
          id: 'e1',
          sourceNodeId: 'a',
          targetNodeId: 'b',
          sourceHandleId: 'source',
          targetHandleId: 'target',
        ),
      },
    );

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  FlowDeletePlan? Function(FlowDeleteCandidates)? onBeforeDelete,
  void Function(FlowDeletedElements)? onDelete,
  void Function(List<FlowNode>)? onNodesDelete,
  void Function(List<FlowEdge>)? onEdgesDelete,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          callbacks: FlowCanvasCallbacks(
            onBeforeDelete: onBeforeDelete,
            onDelete: onDelete,
            onNodesDelete: onNodesDelete,
            onEdgesDelete: onEdgesDelete,
          ),
          initialState: _graph(),
        ),
      ),
    ),
  );
  await tester.pump();
  return controller;
}

void main() {
  testWidgets('deleteElements returns removed objects and notifies',
      (tester) async {
    FlowDeletedElements? deleted;
    List<FlowNode>? nodesDeleted;
    List<FlowEdge>? edgesDeleted;
    final controller = await _pump(tester,
        onDelete: (d) => deleted = d,
        onNodesDelete: (n) => nodesDeleted = n,
        onEdgesDelete: (e) => edgesDeleted = e);

    final result = controller.deleteElements(nodeIds: const ['a']);

    // Node 'a' + its connected edge go away; 'b' survives.
    expect(result.nodes.map((n) => n.id), ['a']);
    expect(result.edges.map((e) => e.id), ['e1']);
    expect(controller.currentState.nodes.keys, ['b']);
    expect(controller.currentState.edges, isEmpty);
    expect(deleted?.nodes.map((n) => n.id), ['a']);
    expect(deleted?.edges.map((e) => e.id), ['e1']);
    expect(nodesDeleted?.map((n) => n.id), ['a']);
    expect(edgesDeleted?.map((e) => e.id), ['e1']);
  });

  testWidgets('onBeforeDelete veto cancels everything', (tester) async {
    var vetoCalls = 0;
    var deleteCalls = 0;
    final controller = await _pump(tester,
        onBeforeDelete: (candidates) {
          vetoCalls++;
          expect(candidates.nodes.map((n) => n.id), ['a']);
          expect(candidates.edges.map((e) => e.id), ['e1']);
          return const FlowDeletePlan.veto();
        },
        onDelete: (_) => deleteCalls++);

    final result = controller.deleteElements(nodeIds: const ['a']);

    expect(vetoCalls, 1);
    expect(deleteCalls, 0);
    expect(result.isEmpty, isTrue);
    expect(controller.currentState.nodes.length, 2);
    expect(controller.currentState.edges.length, 1);
  });

  testWidgets('onBeforeDelete can narrow the deletion set', (tester) async {
    final controller = await _pump(tester,
        onBeforeDelete: (candidates) {
          // Keep the edge even though its source node goes away... but the
          // cascade reprunes connected edges, so only node filtering applies.
          // Here: delete only 'b' (drop 'a' from the plan).
          return FlowDeletePlan(
              nodeIds: candidates.nodes
                  .map((n) => n.id)
                  .where((id) => id == 'b'));
        });

    final result =
        controller.deleteElements(nodeIds: const ['a', 'b']);

    expect(result.nodes.map((n) => n.id), ['b']);
    expect(controller.currentState.nodes.keys, ['a']);
  });

  testWidgets('keyboard Delete runs the veto gate', (tester) async {
    final controller = await _pump(tester,
        onBeforeDelete: (_) => const FlowDeletePlan.veto());

    controller.selection.selectNode('a');
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(controller.currentState.nodes.length, 2,
        reason: 'vetoed keyboard delete must keep the node');
  });
}
