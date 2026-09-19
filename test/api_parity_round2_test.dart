// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Round-2 API parity: resize trio, pane scroll/hover, selection context
/// menu, controls callbacks + labels, toObject, queryNodesInRect, minimap
/// semantics switch, Viewport x/y, label defaults.

class _Calls {
  final List<String> calls = [];
  final Map<String, Object?> payload = {};
}

FlowNode<String> _node(String id, Offset position,
        {bool resizable = false}) =>
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
  List<Widget> overlays = const [],
  List<FlowNode<String>>? nodes,
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
          callbacks: FlowCanvasCallbacks(
            onNodeResizeStart: (n) => calls.calls.add('resize-start:${n.id}'),
            onNodeResize: (n) => calls.calls.add('resize:${n.id}'),
            onNodeResizeEnd: (n) => calls.calls.add('resize-end:${n.id}'),
            onNodeContextMenu: (n, _) => calls.calls.add('node-menu:${n.id}'),
            onSelectionContextMenu: (flow, selected) {
              calls.calls.add(
                  'sel-menu:${selected.map((n) => n.id).join(',')}');
              calls.payload['sel-menu-pos'] = flow;
            },
            onPaneScroll: (flow) {
              calls.calls.add('pane-scroll');
              calls.payload['pane-scroll-pos'] = flow;
            },
            onPaneMouseEnter: (flow) {
              calls.calls.add('pane-enter');
              calls.payload['pane-enter-pos'] = flow;
            },
            onPaneMouseMove: (flow) => calls.calls.add('pane-move'),
            onPaneMouseLeave: () => calls.calls.add('pane-leave'),
          ),
          overlays: overlays,
          initialNodes: nodes ??
              [
                _node('a', const Offset(-200, -100), resizable: true),
                _node('b', const Offset(100, -100)),
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

Future<Offset> _resizeHandleCenter(
    WidgetTester tester, String nodeId, Alignment direction) async {
  final handle = tester
      .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
      .firstWhere((h) => h.nodeId == nodeId && h.direction == direction);
  final rect = tester.getRect(
    find.descendant(
      of: find.byWidget(handle),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return rect.center;
}

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
  testWidgets('resize trio brackets a handle drag', (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    await tester.tapAt(_aCenter);
    await tester.pump();
    expect(controller.currentState.selectedNodes, contains('a'));

    final gesture = await tester
        .startGesture(await _resizeHandleCenter(tester, 'a', Alignment.bottomRight));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(40, 30));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(calls.calls, contains('resize-start:a'));
    expect(calls.calls.any((c) => c == 'resize:a'), isTrue);
    expect(calls.calls, contains('resize-end:a'));
    expect(
        calls.calls.indexOf('resize-start:a') <
            calls.calls.indexOf('resize-end:a'),
        isTrue);
    expect(controller.currentState.nodes['a']!.size.width,
        greaterThan(160.0));
  });

  testWidgets('pane scroll fires with the flow position', (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: const Offset(700, 500),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump();

    expect(calls.calls, contains('pane-scroll'));
    expect(calls.payload['pane-scroll-pos'],
        controller.viewport.viewportToFlow(const Offset(700, 500)));
  });

  testWidgets('pane scroll stays silent while locked', (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);
    controller.viewport.toggleLock();
    await tester.pump();

    tester.binding.handlePointerEvent(
      PointerScrollEvent(
        position: const Offset(700, 500),
        scrollDelta: const Offset(0, 120),
      ),
    );
    await tester.pump();

    expect(calls.calls, isNot(contains('pane-scroll')));
  });

  testWidgets('pane hover trio', (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(700, 500));
    await tester.pump();
    expect(calls.calls, contains('pane-enter'));
    expect(calls.payload['pane-enter-pos'],
        controller.viewport.viewportToFlow(const Offset(700, 500)));

    await mouse.moveTo(const Offset(710, 510));
    await tester.pump();
    expect(calls.calls, contains('pane-move'));

    await mouse.removePointer();
    await tester.pump();
    expect(calls.calls, contains('pane-leave'));
  });

  testWidgets('selection context menu fires for selected nodes only',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);
    controller.selection.selectNode('a');
    await tester.pump();

    await _secondaryTap(tester, _aCenter);
    expect(calls.calls, contains('node-menu:a'));
    expect(calls.calls, contains('sel-menu:a'));
    expect(calls.payload['sel-menu-pos'],
        controller.viewport.viewportToFlow(_aCenter));

    calls.calls.clear();
    controller.selection.deselectAll();
    await tester.pump();

    await _secondaryTap(tester, _aCenter);
    expect(calls.calls, contains('node-menu:a'));
    expect(calls.calls, isNot(contains('sel-menu:a')));
  });

  testWidgets('controls fire zoom/fit callbacks and honor labels',
      (tester) async {
    final calls = _Calls();
    var zoomIns = 0;
    var zoomOuts = 0;
    var fitViews = 0;
    final controller = await _pump(
      tester,
      calls,
      options: FlowCanvasOptions(
        a11yOptions: A11yOptions(
          labels: FlowA11yLabels(controlsZoomIn: 'Nagyítás'),
        ),
      ),
      overlays: [
        FlowCanvasControls(
          onZoomIn: () => zoomIns++,
          onZoomOut: () => zoomOuts++,
          onFitView: () => fitViews++,
          fitViewOptions: FitViewOptions(padding: EdgeInsets.all(24)),
        ),
      ],
    );

    // Localized tooltip replaces the default.
    expect(find.byTooltip('Nagyítás'), findsOneWidget);
    expect(find.byTooltip('Zoom in'), findsNothing);
    expect(find.byTooltip('Zoom out'), findsOneWidget);
    expect(find.byTooltip('Fit view'), findsOneWidget);

    final before = controller.currentState.viewport.zoom;
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(zoomIns, 1);
    expect(controller.currentState.viewport.zoom, greaterThan(before));

    await tester.tap(find.byIcon(Icons.remove));
    await tester.pump();
    expect(zoomOuts, 1);

    await tester.tap(find.byIcon(Icons.fit_screen));
    await tester.pump();
    expect(fitViews, 1);
  });

  testWidgets('toObject snapshots nodes, edges and viewport',
      (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    final snapshot = controller.toObject();
    expect(snapshot.nodes.map((n) => n.id).toSet(), {'a', 'b'});
    expect(snapshot.edges, isEmpty);
    expect(snapshot.viewport, controller.currentState.viewport);

    final a = controller.currentState.nodes['a']!;

    controller.nodes.updateNode(a.copyWith(position: const Offset(-150, -100)));
    await tester.pump();
    final moved = controller.toObject();
    expect(
        moved.nodes.firstWhere((n) => n.id == 'a').position,
        const Offset(-150, -100));
  });

  testWidgets('queryNodesInRect is spatially filtered', (tester) async {
    final calls = _Calls();
    final controller = await _pump(tester, calls);

    final both = controller.nodes
        .queryNodesInRect(const Rect.fromLTWH(-300, -200, 700, 400));
    expect(both.map((n) => n.id).toSet(), {'a', 'b'});

    final justA = controller.nodes
        .queryNodesInRect(const Rect.fromLTWH(-250, -150, 100, 100));
    expect(justA.map((n) => n.id).toList(), ['a']);

    final none = controller.nodes
        .queryNodesInRect(const Rect.fromLTWH(1000, 1000, 50, 50));
    expect(none, isEmpty);
  });

  testWidgets('minimap semantics switch excludes the tree label',
      (tester) async {
    final calls = _Calls();
    await _pump(tester, calls, overlays: [
      FlowMiniMap(includeInSemantics: false),
    ]);
    expect(find.bySemanticsLabel('Minimap'), findsNothing);
  });

  test('FlowA11yLabels ships RF control/minimap defaults', () {
    const labels = FlowA11yLabels();
    expect(labels.controlsZoomIn, 'Zoom in');
    expect(labels.controlsZoomOut, 'Zoom out');
    expect(labels.controlsFitView, 'Fit view');
    expect(labels.controlsLock, 'Lock canvas');
    expect(labels.controlsUnlock, 'Unlock canvas');
    expect(labels.controlsUndo, 'Undo');
    expect(labels.controlsRedo, 'Redo');
    expect(labels.minimapLabel, 'Minimap');
  });

  test('FlowViewport exposes RF x/y aliases', () {
    const viewport =
        FlowViewport(offset: Offset(3, 4), zoom: 2);
    expect(viewport.x, 3);
    expect(viewport.y, 4);
  });
}
