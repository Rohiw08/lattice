// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-3 API parity: onBeforeConnect/Reconnect, collection utils,
/// getEdgeCenter, updateEdge, watch hooks, interactive flag, connection-line
/// builder/style, resizer style/color, minimap onClick, zoom conveniences,
/// remaining aria defaults.

class _Calls {
  final List<String> calls = [];
  final Map<String, Object?> payload = {};
}

FlowNode<String> _node(String id, Offset position, {bool resizable = false}) =>
    FlowNode<String>(
      type: 'default',
      id: id,
      position: position,
      size: const Size(160, 100),
      data: id,
      resizable: resizable,
    );

Future<FlowCanvasController> _pump(
  WidgetTester tester,
  _Calls calls, {
  FlowCanvasOptions? options,
  FlowCanvasCallbacks? callbacks,
  List<Widget> overlays = const [],
  bool resizableA = false,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: options ?? FlowCanvasOptions(),
          callbacks: callbacks ??
              FlowCanvasCallbacks(
                onConnectEnd: (e) => calls.calls.add('connect-end:${e?.id}'),
                onClickConnectEnd: (e) =>
                    calls.calls.add('click-end:${e?.id}'),
                onReconnectEnd: (e) =>
                    calls.calls.add('reconnect-end:${e?.id}'),
              ),
          overlays: overlays,
          initialNodes: [
            _node('a', const Offset(-200, -100), resizable: resizableA),
            _node('b', const Offset(100, -100)),
            _node('c', const Offset(100, 150)),
          ],
          initialEdges: [
            FlowEdge(
              id: 'e1',
              sourceNodeId: 'a',
              targetNodeId: 'b',
              sourceHandleId: 'source',
              targetHandleId: 'target',
              type: EdgePathType.straight,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

Offset _handleCenter(WidgetTester tester, String nodeId, String handleId) {
  final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
  return tester.getCenter(find.byWidget(handles.firstWhere(
    (h) => h.nodeId == nodeId && h.handleId == handleId,
  )));
}

Future<void> _dragConnect(
  WidgetTester tester,
  Offset from,
  Offset to,
) async {
  final gesture = await tester.startGesture(from);
  await tester.pump();
  await gesture.moveBy(const Offset(30, 20));
  await tester.pump();
  await gesture.moveTo(to);
  await tester.pump();
  await gesture.up();
  await tester.pump();
}

void main() {
  testWidgets('onBeforeConnect false cancels a drag connect', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeConnect: (_) => false,
        onConnectEnd: (e) => calls.calls.add('connect-end:${e?.id}'),
      ),
    );

    await _dragConnect(tester, _handleCenter(tester, 'a', 'source'),
        _handleCenter(tester, 'c', 'target'));

    expect(controller.currentState.edges.keys, ['e1']);
    expect(calls.calls, contains('connect-end:null'));
  });

  testWidgets('onBeforeConnect rewrites endpoints (drag)', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeConnect: (p) => ConnectionParams(
          sourceNodeId: p.sourceNodeId,
          sourceHandleId: p.sourceHandleId,
          targetNodeId: 'c',
          targetHandleId: 'target',
        ),
      ),
    );

    await _dragConnect(tester, _handleCenter(tester, 'a', 'source'),
        _handleCenter(tester, 'b', 'target'));

    final created = controller.currentState.edges.values
        .where((e) => e.id != 'e1')
        .toList();
    expect(created, hasLength(1));
    expect(created.single.targetNodeId, 'c');
  });

  testWidgets('onBeforeConnect inserts a returned edge as-is (click)',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeConnect: (p) => FlowEdge(
          id: 'custom-1',
          sourceNodeId: p.sourceNodeId,
          sourceHandleId: p.sourceHandleId,
          targetNodeId: p.targetNodeId,
          targetHandleId: p.targetHandleId,
        ),
        onClickConnectEnd: (e) => calls.calls.add('click-end:${e?.id}'),
      ),
    );

    await tester.tapAt(_handleCenter(tester, 'a', 'source'));
    await tester.pump();
    await tester.tapAt(_handleCenter(tester, 'c', 'target'));
    await tester.pump();

    expect(controller.currentState.edges['custom-1'], isNotNull);
    expect(calls.calls, contains('click-end:custom-1'));
  });

  testWidgets('onBeforeConnect false cancels a click connect',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeConnect: (_) => false,
        onClickConnectEnd: (e) => calls.calls.add('click-end:${e?.id}'),
      ),
    );

    await tester.tapAt(_handleCenter(tester, 'a', 'source'));
    await tester.pump();
    await tester.tapAt(_handleCenter(tester, 'c', 'target'));
    await tester.pump();

    expect(controller.currentState.edges.keys, ['e1']);
    expect(calls.calls, contains('click-end:null'));
  });

  testWidgets('onBeforeReconnect cancels, then proceeds', (tester) async {
    final calls = _Calls();
    var allow = false;
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeReconnect: (next, old) {
          calls.calls.add('before-reconnect:${old.id}');
          return allow ? next : false;
        },
        onReconnectEnd: (e) => calls.calls.add('reconnect-end:${e?.id}'),
      ),
    );

    Future<void> dropOnC() async {
      final targetFlow = controller.viewport
          .viewportToFlow(_handleCenter(tester, 'c', 'target'));
      controller.connection.startReconnect(
        edgeId: 'e1',
        end: HandleTypeEnd.target,
        cursorFlow: targetFlow,
      );
      await tester.pump();
      controller.connection.updateConnection(targetFlow);
      await tester.pump();
      controller.connection.endConnection();
      await tester.pump();
    }

    await dropOnC();
    expect(calls.calls, contains('before-reconnect:e1'));
    expect(calls.calls, contains('reconnect-end:null'));
    expect(controller.currentState.edges['e1']!.targetNodeId, 'b');

    allow = true;
    await dropOnC();
    expect(controller.currentState.edges['e1']!.targetNodeId, 'c');
    expect(calls.calls, contains('reconnect-end:e1'));
  });

  test('addEdge dedups, reconnectEdge rewrites, apply*Changes fold', () {
    const params = ConnectionParams(
      sourceNodeId: 'a',
      targetNodeId: 'b',
      sourceHandleId: 'source',
      targetHandleId: 'target',
    );
    final e1 = FlowEdge.fromConnection(params, id: 'e1');
    var edges = addEdge(<String, FlowEdge>{}, e1);
    expect(edges.keys, ['e1']);

    // Same connection under another id is a no-op (RF connectionExists).
    final dup = FlowEdge.fromConnection(params, id: 'e2');
    expect(identical(addEdge(edges, dup), edges), isTrue);

    // Reconnect keeps the id when asked, mints one by default.
    final kept = reconnectEdge(edges,
        oldEdgeId: 'e1',
        connection: const ConnectionParams(
          sourceNodeId: 'a',
          targetNodeId: 'c',
          sourceHandleId: 'source',
          targetHandleId: 'target',
        ),
        shouldReplaceId: false);
    expect(kept.keys, ['e1']);
    expect(kept['e1']!.targetNodeId, 'c');
    final minted = reconnectEdge(edges,
        oldEdgeId: 'e1',
        connection: const ConnectionParams(
            sourceNodeId: 'a', targetNodeId: 'c'));
    expect(minted.keys, hasLength(1));
    expect(minted.keys.single, isNot('e1'));

    // Missing edge: unchanged.
    expect(
        identical(
            reconnectEdge(edges,
                oldEdgeId: 'nope', connection: params),
            edges),
        isTrue);

    // applyNodeChanges folds add/position/dimensions/remove.
    var nodes = <String, FlowNode>{
      'a': _node('a', Offset.zero),
    };
    nodes = applyNodeChanges(nodes, [
      NodePositionChange(id: 'a', position: const Offset(5, 5)),
      NodeDimensionsChange(id: 'a', size: const Size(10, 10)),
      NodeAddChange(node: _node('b', const Offset(9, 9))),
    ]);
    expect(nodes['a']!.position, const Offset(5, 5));
    expect(nodes['a']!.size, const Size(10, 10));
    expect(nodes.keys, {'a', 'b'});
    nodes = applyNodeChanges(nodes, [NodeRemoveChange(id: 'a')]);
    expect(nodes.keys, ['b']);

    // applyEdgeChanges folds add/remove.
    var applied =
        applyEdgeChanges(<String, FlowEdge>{}, [EdgeAddChange(edge: e1)]);
    expect(applied.keys, ['e1']);
    applied = applyEdgeChanges(applied, [EdgeRemoveChange(id: 'e1')]);
    expect(applied, isEmpty);
  });

  test('getEdgeCenter matches RF math in both directions', () {
    final fwd = EdgePathCreator.getEdgeCenter(
      source: Offset.zero,
      target: const Offset(100, 50),
    );
    expect(fwd.center, const Offset(50, 25));
    expect(fwd.offset, const Offset(50, 25));

    final rev = EdgePathCreator.getEdgeCenter(
      source: const Offset(100, 50),
      target: Offset.zero,
    );
    expect(rev.center, const Offset(50, 25));
    expect(rev.offset, const Offset(50, 25));
  });

  testWidgets('updateEdge replaces the edge, missing id is a no-op',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    controller.edges.updateEdge('e1', (e) => e.copyWith(selectable: false));
    await tester.pump();
    expect(controller.currentState.edges['e1']!.selectable, isFalse);

    controller.edges.updateEdge('nope', (e) => e);
    await tester.pump();
    expect(controller.currentState.edges.keys, ['e1']);
  });

  testWidgets('watch hooks fire on viewport and selection commits',
      (tester) async {
    final calls = _Calls();
    FlowViewport? seenViewport;
    CanvasSelection? seenSelection;
    final controller = await _pump(
      tester,
      calls,
      overlays: [
        Builder(builder: (context) {
          return Consumer(builder: (context, ref, _) {
            watchViewportChange(ref, (vp) {
              seenViewport = vp;
              calls.calls.add('vp-change');
            });
            watchSelectionChange(ref, (selection) {
              seenSelection = selection;
              calls.calls.add('sel-change');
            });
            return const SizedBox.shrink();
          });
        }),
      ],
    );

    // Attach + viewport commit.
    await controller.viewport.centerOnPosition(const Offset(10, 10));
    await tester.pump();
    expect(calls.calls, contains('vp-change'));
    expect(seenViewport!.offset, isNot(Offset.zero));

    controller.selection.selectNode('a');
    await tester.pump();
    expect(calls.calls, contains('sel-change'));
    expect(seenSelection!.nodeIds, {'a'});
    expect(seenSelection!.edgeIds, isEmpty);
  });

  testWidgets('non-interactive blocks gestures but keeps observations',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onNodeClick: (n, _) => calls.calls.add('node-click:${n.id}'),
      ),
    );

    controller.setInteractive(false);
    await tester.pump();
    expect(controller.currentState.interactive, isFalse);

    // Tap: observes, does not select.
    await tester.tapAt(const Offset(280, 250));
    await tester.pump();
    expect(calls.calls, contains('node-click:a'));
    expect(controller.currentState.selectedNodes, isEmpty);

    // Drag: node does not move.
    final gesture = await tester.startGesture(const Offset(280, 250));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(controller.currentState.nodes['a']!.position,
        const Offset(-200, -100));

    // Programmatic selection is gated too (like elementsSelectable).
    controller.selection.selectNode('a');
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);

    controller.setInteractive(true);
    await tester.pump();
    await tester.tapAt(const Offset(280, 250));
    await tester.pump();
    expect(controller.currentState.selectedNodes, contains('a'));
  });

  testWidgets('controls interactive button toggles the flag',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      overlays: [FlowCanvasControls()],
    );

    expect(find.byTooltip('Toggle interactivity'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pump();
    expect(controller.currentState.interactive, isFalse);
    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pump();
    expect(controller.currentState.interactive, isTrue);
  });

  testWidgets('connection-line builder replaces the painted line',
      (tester) async {
    final calls = _Calls();
    await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        connectionOptions: ConnectionOptions(
          connectionLineBuilder: (context, info) =>
              Text('line-valid:${info.isValid}'),
        ),
      ),
    );

    final gesture = await tester
        .startGesture(_handleCenter(tester, 'a', 'source'));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    expect(find.text('line-valid:false', findRichText: true), findsOneWidget);

    await gesture.moveTo(_handleCenter(tester, 'b', 'target'));
    await tester.pump();
    expect(find.text('line-valid:true', findRichText: true), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.textContaining('line-valid', findRichText: true), findsNothing);
  });

  testWidgets('resizer color tints handles, minimap onClick reports flow',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      resizableA: true,
      overlays: [
        FlowNodeResizer(nodeId: 'a', color: Colors.red),
        FlowMiniMap(
          onClick: (flow) {
            calls.calls.add('minimap-click');
            calls.payload['minimap-click-pos'] = flow;
          },
        ),
      ],
    );

    final handles = tester
        .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
        .where((h) => h.nodeId == 'a')
        .toList();
    expect(handles, isNotEmpty);
    var sawRed = false;
    for (final handle in handles) {
      final found = find.descendant(
        of: find.byWidget(handle),
        matching: find.byType(AnimatedContainer),
      );
      if (found.evaluate().isEmpty) continue;
      final container = tester.widget<AnimatedContainer>(found);
      if ((container.decoration as BoxDecoration?)?.color == Colors.red) {
        sawRed = true;
      }
    }
    expect(sawRed, isTrue,
        reason: 'the color-tinted resizer must paint a red handle');

    await tester.tapAt(const Offset(700, 500));
    await tester.pump();
    expect(calls.calls, contains('minimap-click'));
    // The minimap maps through its own fit-bounds transform (not the main
    // viewport): tapping centers the camera on the reported flow position.
    final reported = calls.payload['minimap-click-pos'] as Offset;
    final centered = controller.viewport.viewportToFlow(
      const Offset(400, 300),
    );
    expect((reported - centered).distance, lessThan(0.001));
  });

  testWidgets('zoom conveniences and screen/flow aliases agree',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    final before = controller.currentState.viewport.zoom;
    await controller.viewport.zoomIn();
    final zoomed = controller.currentState.viewport.zoom;
    expect(zoomed, greaterThan(before));
    await controller.viewport.zoomOut();
    expect(controller.currentState.viewport.zoom, lessThan(zoomed));

    const probe = Offset(400, 300);
    expect(controller.viewport.screenToFlowPosition(probe),
        controller.viewport.viewportToFlow(probe));
    expect(controller.viewport.flowToScreenPosition(Offset.zero),
        controller.viewport.flowToViewport(Offset.zero));
  });

  test('remaining aria defaults match RF keys', () {
    const labels = FlowA11yLabels();
    expect(labels.handleLabel, 'Handle');
    expect(labels.controlsLabel, 'Control Panel');
    expect(labels.controlsInteractive, 'Toggle interactivity');
  });

  testWidgets('handle and panel semantics labels exist', (tester) async {
    final semantics = tester.ensureSemantics();
    final calls = _Calls();
    await _pump(
      tester,
      calls,
      overlays: [FlowCanvasControls()],
    );

    expect(find.bySemanticsLabel('Handle'), findsWidgets);
    expect(find.bySemanticsLabel('Control Panel'), findsOneWidget);
    semantics.dispose();
  });
}
