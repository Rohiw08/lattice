// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/connections/domain/connection_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Regression: reconnect-drop must keep the auto-panned viewport. Auto-pan
/// moves only the live matrix; `endConnection` commits it into state, so
/// cancelling from a pre-commit snapshot resurrects the old viewport and
/// snaps the camera back. Normal connect doesn't hit this because it
/// cancels from the current state.
void main() {
  testWidgets('reconnect drop keeps the auto-panned viewport', (tester) async {
    final nodes = [
      FlowNode<String>(id: 'node_a', type: 'default', position: Offset.zero),
      FlowNode<String>(
        id: 'node_b',
        type: 'default',
        position: const Offset(400, 0),
      ),
    ];
    final edges = [
      FlowEdge(
        id: 'ab',
        sourceNodeId: 'node_a',
        targetNodeId: 'node_b',
        sourceHandleId: 'source',
        targetHandleId: 'target',
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
            initialEdges: edges,
            options: FlowCanvasOptions(
              connectionOptions: ConnectionOptions(
                edgesReconnectable: true,
                autoCreateEdge: true,
              ),
            ),
            overlays: const [FlowMiniMap()],
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FlowMiniMap)),
    );
    final notifier = container.read(flowControllerProvider.notifier);

    // Reconnect `ab` from its source end (rubber-band anchored at node_a).
    notifier.connection.startReconnect(
      edgeId: 'ab',
      end: HandleTypeEnd.target,
      cursorFlow: const Offset(80, 44),
    );

    // Move the cursor onto node_b's target handle -> hover-valid.
    notifier.connection.updateConnection(
      const Offset(400 + 80, 0),
      globalPosition: null,
    );
    final hovering = container.read(internalControllerProvider);
    expect(
      hovering.connectionState is HoveringConnectionState &&
          (hovering.connectionState as HoveringConnectionState).isValid,
      isTrue,
      reason: 'cursor must hover-valid on the target handle',
    );

    // Auto-pan equivalent: pan the live matrix (never the Freezed state).
    final panBefore = container.read(internalControllerProvider).viewport;
    notifier.panLiveBy(const Offset(150, 0));

    // Drop — commits the panned matrix, then must NOT snap back.
    notifier.connection.endConnection();
    await tester.pump();

    final after = container.read(internalControllerProvider);
    expect(after.activeConnection, isNull);
    expect(after.viewport.offset.dx, closeTo(panBefore.offset.dx + 150, 0.001),
        reason: 'auto-panned viewport must survive the reconnect drop');
    expect(after.edges['ab'], isNotNull);
  });

  testWidgets('reconnect cancel (invalid drop) keeps the panned viewport',
      (tester) async {
    final nodes = [
      FlowNode<String>(id: 'node_a', type: 'default', position: Offset.zero),
      FlowNode<String>(
        id: 'node_b',
        type: 'default',
        position: const Offset(400, 0),
      ),
    ];
    final edges = [
      FlowEdge(
        id: 'ab',
        sourceNodeId: 'node_a',
        targetNodeId: 'node_b',
        sourceHandleId: 'source',
        targetHandleId: 'target',
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
            initialEdges: edges,
            options: FlowCanvasOptions(
              connectionOptions: ConnectionOptions(
                edgesReconnectable: true,
                autoCreateEdge: true,
              ),
            ),
            overlays: const [FlowMiniMap()],
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(FlowMiniMap)),
    );
    final notifier = container.read(flowControllerProvider.notifier);

    notifier.connection.startReconnect(
      edgeId: 'ab',
      end: HandleTypeEnd.target,
      cursorFlow: const Offset(80, 44),
    );

    // Auto-pan equivalent: pan the live matrix (never the Freezed state).
    final panBefore = container.read(internalControllerProvider).viewport;
    notifier.panLiveBy(const Offset(150, 0));

    // Drop on empty space -> reconnect aborts.
    notifier.connection.endConnection();
    await tester.pump();

    final after = container.read(internalControllerProvider);
    expect(after.activeConnection, isNull);
    expect(after.viewport.offset.dx, closeTo(panBefore.offset.dx + 150, 0.001),
        reason: 'auto-panned viewport must survive the reconnect cancel');
    expect(after.edges['ab'], isNotNull,
        reason: 'failed reconnect must not delete the edge');
  });
}