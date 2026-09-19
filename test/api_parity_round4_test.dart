// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Final-pass parity: canvas-level capability flags actually gate behavior
/// (per-node wins, null inherits the global), onConnect reports the
/// attempted connection, prebuilt-edge guards, onInteractiveChange,
/// edgeIdForConnection, keyboard/global interplay, global expandParent.

class _Calls {
  final List<String> calls = [];
  final Map<String, Object?> payload = {};
}

FlowNode<String> _node(String id, Offset position, {bool? draggable}) =>
    FlowNode<String>(
      type: 'default',
      id: id,
      position: position,
      size: const Size(160, 100),
      data: id,
      draggable: draggable,
    );

Future<FlowCanvasController> _pump(
  WidgetTester tester,
  _Calls calls, {
  FlowCanvasOptions? options,
  FlowCanvasCallbacks? callbacks,
  List<Widget> overlays = const [],
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
          callbacks: callbacks ?? FlowCanvasCallbacks(),
          overlays: overlays,
          initialNodes: [
            _node('a', const Offset(-200, -100)),
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

Offset get _aCenter => const Offset(280, 250);

Offset _handleCenter(WidgetTester tester, String nodeId, String handleId) {
  final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
  return tester.getCenter(find.byWidget(handles.firstWhere(
    (h) => h.nodeId == nodeId && h.handleId == handleId,
  )));
}

void main() {
  testWidgets('global draggable:false pins nodes, per-node true wins',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(draggable: false),
      ),
    );

    Future<void> dragA() async {
      final gesture = await tester.startGesture(_aCenter);
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    await dragA();
    expect(controller.currentState.nodes['a']!.position,
        const Offset(-200, -100));

    // Per-node opt-out of the global wins (RF node-overrides-global).
    controller.nodes.updateNode(
      controller.currentState.nodes['a']!.copyWith(draggable: true),
    );
    await tester.pump();
    await dragA();
    expect(controller.currentState.nodes['a']!.position,
        isNot(const Offset(-200, -100)));
  });

  testWidgets('global selectable:false blocks tap-select', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(selectable: false),
      ),
    );

    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);
  });

  testWidgets('marquee skips unselectable nodes', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        viewportOptions: ViewportOptions(selectionOnDrag: true),
        nodeOptions: NodeOptions(selectable: false),
      ),
    );

    final gesture = await tester.startGesture(const Offset(150, 150));
    await tester.pump();
    await gesture.moveBy(const Offset(250, 200));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);
  });

  testWidgets('global connectable:false blocks rubber-bands', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(connectable: false),
      ),
    );

    final gesture = await tester
        .startGesture(_handleCenter(tester, 'a', 'source'));
    await tester.pump();
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(controller.currentState.activeConnection, isNull);
    await gesture.up();
    await tester.pump();
    expect(controller.currentState.edges.keys, ['e1']);
  });

  testWidgets('global deletable:false blocks deleteElements', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(deletable: false),
        edgeOptions: EdgeOptions(deletable: false),
      ),
    );

    final deleted = controller.deleteElements(
      nodeIds: const {'a'},
      edgeIds: const {'e1'},
    );
    expect(deleted.isEmpty, isTrue);
    expect(controller.currentState.nodes.keys, {'a', 'b', 'c'});
    expect(controller.currentState.edges.keys, ['e1']);

    // Explicit per-node opt-out still works when the global allows.
    final controller2 = FlowCanvasController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller2,
            initialNodes: [
              FlowNode<String>(
                type: 'default',
                id: 'x',
                position: Offset.zero,
                data: 'x',
                deletable: false,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(
        controller2.deleteElements(nodeIds: const {'x'}).isEmpty, isTrue);
  });

  testWidgets('global resizable:true enables overlay handles', (tester) async {
    final calls = _Calls();
    await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(resizable: true),
      ),
      overlays: [FlowNodeResizer(nodeId: 'a')],
    );

    final handles = tester
        .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
        .where((h) => h.nodeId == 'a')
        .toList();
    expect(handles, isNotEmpty);
    var sawEnabled = false;
    for (final handle in handles) {
      final found = find.descendant(
        of: find.byWidget(handle),
        matching: find.byType(AnimatedContainer),
      );
      if (found.evaluate().isEmpty) continue;
      final container = tester.widget<AnimatedContainer>(found);
      final color = (container.decoration as BoxDecoration?)?.color;
      // Enabled handles use the full-strength color, not the dimmed one.
      if (color != null && (color.a - 1.0).abs() < 0.001) sawEnabled = true;
    }
    expect(sawEnabled, isTrue);
  });

  testWidgets('observers report the attempted connection on rewrite',
      (tester) async {
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
        onConnection: (p) =>
            calls.payload['connection-target'] = p.targetNodeId,
      ),
    );

    final gesture = await tester
        .startGesture(_handleCenter(tester, 'a', 'source'));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveTo(_handleCenter(tester, 'b', 'target'));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    // Edge lands on the rewrite; observers saw the attempt (RF parity).
    final created = controller.currentState.edges.values
        .where((e) => e.id != 'e1')
        .single;
    expect(created.targetNodeId, 'c');
    expect(calls.payload['connection-target'], 'b');
  });

  testWidgets('prebuilt duplicate or dangling edges insert nothing',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      callbacks: FlowCanvasCallbacks(
        onBeforeConnect: (p) => FlowEdge(
          // Same connection as e1 under a new id (RF addEdge dedups).
          id: 'dupe',
          sourceNodeId: p.sourceNodeId,
          sourceHandleId: p.sourceHandleId,
          targetNodeId: p.targetNodeId,
          targetHandleId: p.targetHandleId,
        ),
        onConnectEnd: (e) => calls.calls.add('connect-end:${e?.id}'),
      ),
    );

    Future<void> clickAB() async {
      await tester.tapAt(_handleCenter(tester, 'a', 'source'));
      await tester.pump();
      await tester.tapAt(_handleCenter(tester, 'b', 'target'));
      await tester.pump();
    }

    await clickAB();
    expect(controller.currentState.edges.keys, ['e1']);
    expect(calls.calls, contains('connect-end:null'));
  });

  testWidgets('controls onInteractiveChange reports the flip',
      (tester) async {
    final calls = _Calls();
    await _pump(
      tester,
      calls,
      overlays: [
        FlowCanvasControls(
          onInteractiveChange: (v) => calls.calls.add('interactive:$v'),
        ),
      ],
    );

    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pump();
    expect(calls.calls, contains('interactive:false'));
    await tester.tap(find.byIcon(Icons.touch_app));
    await tester.pump();
    expect(calls.calls, contains('interactive:true'));
  });

  test('edgeIdForConnection is deterministic and RF-shaped', () {
    expect(
      edgeIdForConnection(const ConnectionParams(
        sourceNodeId: 'a',
        sourceHandleId: 'out',
        targetNodeId: 'b',
        targetHandleId: 'in',
      )),
      'flow-edge__aout-bin',
    );
    expect(
      edgeIdForConnection(
          const ConnectionParams(sourceNodeId: 'a', targetNodeId: 'b')),
      'flow-edge__a-b',
    );
  });

  testWidgets('keyboard honors global draggable/deletable', (tester) async {
    final calls = _Calls();
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(draggable: false, deletable: false),
      ),
    );
    controller.selection.selectNode('a');
    await tester.pump();

    controller.keyboard.handleKeyboardAction(
      KeyboardAction.moveRight,
      options: KeyboardOptions(),
      a11yOptions: A11yOptions(),
      minZoom: 0.2,
      maxZoom: 4.0,
      translateExtent: const CoordinateExtent(),
      nodeOptions: NodeOptions(draggable: false, deletable: false),
      edgeOptions: EdgeOptions(),
    );
    await tester.pump();
    expect(controller.currentState.nodes['a']!.position,
        const Offset(-200, -100));

    controller.keyboard.handleKeyboardAction(
      KeyboardAction.deleteSelection,
      options: KeyboardOptions(),
      a11yOptions: A11yOptions(),
      minZoom: 0.2,
      maxZoom: 4.0,
      translateExtent: const CoordinateExtent(),
      nodeOptions: NodeOptions(draggable: false, deletable: false),
      edgeOptions: EdgeOptions(),
    );
    await tester.pump();
    expect(controller.currentState.nodes.containsKey('a'), isTrue);
  });

  test('global expandParent grows parents without per-node flags', () {
    final service = NodeService();
    final parent = FlowNode<String>(
      type: 'default',
      id: 'p',
      position: Offset.zero,
      size: const Size(100, 100),
      data: 'p',
    );
    final child = FlowNode<String>(
      type: 'default',
      id: 'c',
      position: const Offset(80, 80),
      size: const Size(100, 100),
      data: 'c',
      parentId: 'p',
    );
    final base = FlowCanvasState.initial().copyWith(
      nodes: {'p': parent, 'c': child},
    );

    // Per-node unset: no growth by default.
    final plain = service.applyExpandParent(base, ['c']);
    expect(plain.nodes['p']!.size, const Size(100, 100));

    // Global default grows the parent to fit the child.
    final grown = service.applyExpandParent(base, ['c'],
        expandParentDefault: true);
    expect(grown.nodes['p']!.size.width, greaterThan(100));
    expect(grown.nodes['p']!.size.height, greaterThan(100));

    // The child-extent floor honors the same default.
    expect(
      NodeLayout.childExtentFloor('p', base.nodes),
      isNull,
    );
    expect(
      NodeLayout.childExtentFloor('p', base.nodes,
          expandParentDefault: true),
      isNotNull,
    );
  });
}
