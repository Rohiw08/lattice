// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Regression: drag-connect must work on nodes whose handles come from
/// [FlowNode.effectiveHandles] (built-in type synthesis) — the raw `handles`
/// map is empty for `FlowNode(id: ..., type: 'default')`.
void main() {
  testWidgets('synthesized handles can start a connection', (tester) async {
    final nodes = [
      FlowNode<String>(id: 'node_a', type: 'default', position: Offset.zero),
      FlowNode<String>(
        id: 'node_b',
        type: 'default',
        position: const Offset(300, 0),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            initialNodes: nodes,
            overlays: const [FlowMiniMap()],
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FlowMiniMap)),
    );
    final state = container.read(internalControllerProvider);
    expect(state.nodes['node_a']!.handles, isEmpty,
        reason: 'fixture relies on synthesized handles');
    expect(state.nodes['node_a']!.effectiveHandles['source'], isNotNull);

    final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
    final sourceGlobal = tester.getCenter(
      find.byWidget(handles.firstWhere(
        (h) => h.nodeId == 'node_a' && h.handleId == 'source',
      )),
    );
    final targetGlobal = tester.getCenter(
      find.byWidget(handles.firstWhere(
        (h) => h.nodeId == 'node_b' && h.handleId == 'target',
      )),
    );

    final gesture = await tester.startGesture(sourceGlobal);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();

    final midDrag = container.read(internalControllerProvider);
    expect(midDrag.activeConnection, isNotNull,
        reason: 'rubber-band must start from a synthesized source handle');
    expect(midDrag.activeConnection!.fromNodeId, 'node_a');

    await gesture.moveTo(targetGlobal);
    await tester.pump();

    final hovering = container.read(internalControllerProvider);
    expect(
      hovering.connectionState is HoveringConnectionState &&
          (hovering.connectionState as HoveringConnectionState).isValid,
      isTrue,
      reason: 'target handle must hover-valid',
    );

    await gesture.up();
    await tester.pump();

    final after = container.read(internalControllerProvider);
    expect(
      after.edges.values.any(
        (e) => e.sourceNodeId == 'node_a' && e.targetNodeId == 'node_b',
      ),
      isTrue,
      reason: 'edge must be created on drop',
    );
  });
}
