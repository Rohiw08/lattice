// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pointer-event parity (RF onNodeClick/DoubleClick/Mouse*/ContextMenu,
/// onEdge*, onPaneClick/ContextMenu, selection marquee + multi-drag trios,
/// click-connect Start/End, onInit, selectNodesOnDrag, elementsSelectable).
///
/// Tap-down semantics: click callbacks fire on pointer-down, the same tick
/// selection changes (unlike RF's click-complete, which needs DOM events).

class _Events {
  final List<String> calls = [];
  final Map<String, Object?> payload = {};
}

FlowNode<String> _node(String id, Offset position) => FlowNode<String>(
      type: 'default',
      id: id,
      position: position,
      size: const Size(160, 100),
      data: id,
    );

Future<FlowCanvasController> _pump(
  WidgetTester tester,
  _Events events, {
  FlowCanvasOptions? options,
}) async {
  final controller = FlowCanvasController();
  String name(Object? o) => (o as dynamic).id as String;
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: options ?? FlowCanvasOptions(),
          callbacks: FlowCanvasCallbacks(
            onInit: (c) {
              events.calls.add('init');
              events.payload['init-same'] = identical(c, controller);
            },
            onNodeClick: (n, p) {
              events.calls.add('node-click:${name(n)}');
              events.payload['node-click-pos'] = p;
            },
            onNodeDoubleClick: (n, _) =>
                events.calls.add('node-double:${name(n)}'),
            onNodeContextMenu: (n, _) =>
                events.calls.add('node-menu:${name(n)}'),
            onNodeMouseEnter: (n, _) =>
                events.calls.add('node-enter:${name(n)}'),
            onNodeMouseMove: (n, _) => events.calls.add('node-move:${name(n)}'),
            onNodeMouseLeave: (n, _) =>
                events.calls.add('node-leave:${name(n)}'),
            onNodeDragStart: (c) =>
                events.calls.add('drag-start:${c.length}'),
            onNodeDragStop: (c) =>
                events.calls.add('drag-stop:${c.length}'),
            onEdgeClick: (e, _) => events.calls.add('edge-click:${e.id}'),
            onEdgeDoubleClick: (e, _) =>
                events.calls.add('edge-double:${e.id}'),
            onEdgeContextMenu: (e, _) =>
                events.calls.add('edge-menu:${e.id}'),
            onEdgeMouseEnter: (e, _) =>
                events.calls.add('edge-enter:${e.id}'),
            onEdgeMouseMove: (e, _) => events.calls.add('edge-move:${e.id}'),
            onEdgeMouseLeave: (e, _) =>
                events.calls.add('edge-leave:${e.id}'),
            onPaneClick: (p) {
              events.calls.add('pane-click');
              events.payload['pane-click-pos'] = p;
            },
            onPaneContextMenu: (_) => events.calls.add('pane-menu'),
            onSelectionStart: (_) => events.calls.add('sel-start'),
            onSelectionEnd: (_) => events.calls.add('sel-end'),
            onSelectionDragStart: (c) =>
                events.calls.add('seldrag-start:${c.length}'),
            onSelectionDrag: (c) =>
                events.calls.add('seldrag:${c.length}'),
            onSelectionDragStop: (c) =>
                events.calls.add('seldrag-stop:${c.length}'),
            onClickConnectStart: (n, h) =>
                events.calls.add('click-start:$n/$h'),
            onClickConnectEnd: (e) =>
                events.calls.add('click-end:${e?.id}'),
          ),
          initialNodes: [
            _node('a', const Offset(-200, -100)),
            _node('b', const Offset(100, -100)),
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

/// Node 'a' occupies flow (-200..-40, -100..0); the canvas centers the
/// origin, so screen = flow + (400, 300).
Offset get _aCenter => const Offset(280, 250);

/// Straight edge midpoint between a-right (360, 250) and b-left (500, 250).
Offset get _edgeMid => const Offset(430, 250);

Future<void> _secondaryTap(WidgetTester tester, Offset pos) async {
  tester.binding.handlePointerEvent(PointerDownEvent(
    pointer: 1,
    kind: PointerDeviceKind.mouse,
    position: pos,
    buttons: kSecondaryMouseButton,
  ));
  await tester.pump();
  tester.binding.handlePointerEvent(PointerUpEvent(
    pointer: 1,
    kind: PointerDeviceKind.mouse,
    position: pos,
  ));
  await tester.pump();
}

void main() {
  testWidgets('onInit fires once with the live controller', (tester) async {
    final events = _Events();
    final controller = await _pump(tester, events);
    expect(events.calls.where((c) => c == 'init'), hasLength(1));
    expect(events.payload['init-same'], isTrue);
    expect(controller, isNotNull);
  });

  testWidgets('node click + double-click', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(events.calls, contains('node-click:a'));

    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(events.calls.where((c) => c == 'node-click:a'), hasLength(2));
    expect(events.calls, contains('node-double:a'));
  });

  testWidgets('node hover trio', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    await tester.pump();
    await mouse.moveTo(_aCenter);
    await tester.pump();
    expect(events.calls, contains('node-enter:a'));

    await mouse.moveTo(_aCenter + const Offset(10, 0));
    await tester.pump();
    expect(events.calls, contains('node-move:a'));

    await mouse.moveTo(const Offset(700, 500));
    await tester.pump();
    expect(events.calls, contains('node-leave:a'));
    await mouse.removePointer();
  });

  testWidgets('node + edge + pane context menus route by target',
      (tester) async {
    final events = _Events();
    await _pump(tester, events);

    await _secondaryTap(tester, _aCenter);
    expect(events.calls, contains('node-menu:a'));

    await _secondaryTap(tester, _edgeMid);
    expect(events.calls, contains('edge-menu:e1'));

    await _secondaryTap(tester, const Offset(700, 500));
    expect(events.calls, contains('pane-menu'));
  });

  testWidgets('edge click + double-click', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    await tester.tapAt(_edgeMid);
    await tester.pump();
    expect(events.calls, contains('edge-click:e1'));

    await tester.tapAt(_edgeMid);
    await tester.pump();
    expect(events.calls.where((c) => c == 'edge-click:e1'), hasLength(2));
    expect(events.calls, contains('edge-double:e1'));
  });

  testWidgets('edge hover trio', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    await tester.pump();
    await mouse.moveTo(_edgeMid);
    await tester.pump();
    expect(events.calls, contains('edge-enter:e1'));

    await mouse.moveTo(const Offset(700, 500));
    await tester.pump();
    expect(events.calls, contains('edge-leave:e1'));
    await mouse.removePointer();
  });

  testWidgets('pane click fires (and not during a marquee)', (tester) async {
    final events = _Events();
    final controller = await _pump(tester, events);

    await tester.tapAt(const Offset(700, 500));
    await tester.pump();
    expect(events.calls, contains('pane-click'));
    expect(events.payload['pane-click-pos'],
        controller.viewport.viewportToFlow(const Offset(700, 500)));
  });

  testWidgets('marquee fires start/end, suppresses pane click',
      (tester) async {
    final events = _Events();
    await _pump(
      tester,
      events,
      options: FlowCanvasOptions(
        viewportOptions: ViewportOptions(selectionOnDrag: true),
      ),
    );

    final gesture = await tester.startGesture(const Offset(600, 450));
    await tester.pump();
    await gesture.moveBy(const Offset(100, 100));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(events.calls, contains('sel-start'));
    expect(events.calls, contains('sel-end'));
    expect(events.calls, isNot(contains('pane-click')));
  });

  testWidgets('node drag start/stop surround the drag', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    final gesture = await tester.startGesture(_aCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(events.calls, contains('drag-start:1'));
    expect(events.calls, contains('drag-stop:1'));
    expect(
        events.calls.indexOf('drag-start:1') <
            events.calls.indexOf('drag-stop:1'),
        isTrue);
  });

  testWidgets('multi-drag fires the selection-drag trio', (tester) async {
    final events = _Events();
    final controller = await _pump(tester, events);
    controller.selection.selectNode('a');
    controller.selection.selectNode('b', addToSelection: true);
    await tester.pump();

    final gesture = await tester.startGesture(_aCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(events.calls, contains('seldrag-start:2'));
    expect(events.calls, contains('seldrag-stop:2'));
    expect(events.calls.any((c) => c.startsWith('seldrag:2')), isTrue);
    // The node trio still fires alongside.
    expect(events.calls, contains('drag-start:2'));
    expect(events.calls, contains('drag-stop:2'));
  });

  testWidgets('click-connect fires distinct start/end', (tester) async {
    final events = _Events();
    await _pump(tester, events);

    final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
    final source = tester.getCenter(find.byWidget(handles.firstWhere(
      (h) => h.nodeId == 'a' && h.handleId == 'source',
    )));
    final target = tester.getCenter(find.byWidget(handles.firstWhere(
      (h) => h.nodeId == 'b' && h.handleId == 'target',
    )));

    await tester.tapAt(source);
    await tester.pump();
    expect(events.calls, contains('click-start:a/source'));

    await tester.tapAt(target);
    await tester.pump();
    expect(
        events.calls.any((c) => c.startsWith('click-end:') && c != 'click-end:null'),
        isTrue);
  });

  testWidgets('selectNodesOnDrag false drags without selecting',
      (tester) async {
    final events = _Events();
    final controller = await _pump(
      tester,
      events,
      options: FlowCanvasOptions(
        nodeOptions: NodeOptions(selectNodesOnDrag: false),
      ),
    );

    // Taps still select.
    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(controller.currentState.selectedNodes, contains('a'));

    await tester.tapAt(const Offset(700, 500));
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);

    // ...but drags do not.
    final gesture = await tester.startGesture(_aCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);
    expect(controller.currentState.nodes['a']!.position,
        isNot(const Offset(-200, -100)));
  });

  testWidgets('elementsSelectable false disables user selection',
      (tester) async {
    final events = _Events();
    final controller = await _pump(
      tester,
      events,
      options: FlowCanvasOptions(elementsSelectable: false),
    );

    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);

    controller.selection.selectNode('a');
    await tester.pump();
    expect(controller.currentState.selectedNodes, isEmpty);
  });
}
