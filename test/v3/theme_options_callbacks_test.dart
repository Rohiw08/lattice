import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

const Color _red = Color(0xFFFF0000);
const Color _green = Color(0xFF00AA00);
const Color _blue = Color(0xFF0000FF);
const Color _gold = Color(0xFFFFD700);

LatticeNode _node(
  String id, [
  Offset position = Offset.zero,
  bool resizable = false,
]) {
  return LatticeNode(
    id: id,
    type: 'default',
    position: position,
    resizable: resizable,
  );
}

LatticeEdge _edge(String id, String source, String target) {
  return LatticeEdge(
    id: id,
    source: LatticeEndpoint(nodeId: source),
    target: LatticeEndpoint(nodeId: target),
  );
}

/// Records every callback fire with its argument for count/arg parity.
class _Recorder {
  final List<LatticeNode> addedNodes = <LatticeNode>[];
  final List<LatticeNode> removedNodes = <LatticeNode>[];
  final List<LatticeEdge> addedEdges = <LatticeEdge>[];
  final List<LatticeEdge> removedEdges = <LatticeEdge>[];
  final List<LatticeSelection> selections = <LatticeSelection>[];
  final List<LatticeViewportValue> viewports = <LatticeViewportValue>[];
  final List<LatticeEdge> connects = <LatticeEdge>[];
  final List<LatticeController> inits = <LatticeController>[];

  LatticeCallbacks get callbacks => LatticeCallbacks(
        onNodesAdded: addedNodes.addAll,
        onNodesRemoved: removedNodes.addAll,
        onEdgesAdded: addedEdges.addAll,
        onEdgesRemoved: removedEdges.addAll,
        onSelectionChange: selections.add,
        onViewportChange: viewports.add,
        onConnect: connects.add,
        onInit: inits.add,
      );

  int get total =>
      addedNodes.length +
      removedNodes.length +
      addedEdges.length +
      removedEdges.length +
      selections.length +
      viewports.length +
      connects.length +
      inits.length;

  /// Clears every recorded fire (keeps the recorder attached).
  void clear() {
    addedNodes.clear();
    removedNodes.clear();
    addedEdges.clear();
    removedEdges.clear();
    selections.clear();
    viewports.clear();
    connects.clear();
    inits.clear();
  }
}

bool _hasBodyColor(WidgetTester tester, Color color) {
  return tester.widgetList<Container>(find.byType(Container)).any(
        (Container container) {
          final Decoration? decoration = container.decoration;
          return decoration is BoxDecoration && decoration.color == color;
        },
      );
}

Future<void> _pumpCanvas(
  WidgetTester tester,
  LatticeController controller, {
  LatticeTheme? theme,
  LatticeCallbacks? callbacks,
  List<Widget> overlays = const <Widget>[],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeCanvas(
        controller: controller,
        theme: theme,
        callbacks: callbacks,
        overlays: overlays,
      ),
    ),
  );
  // Flush post-frame callbacks (pane-size publish + forced cull refresh).
  await tester.pump();
}

void main() {
  group('LatticeTheme value class', () {
    test('partial merge keeps base values for every unset component', () {
      final LatticeTheme base = LatticeTheme.light();
      final LatticeTheme merged = base.merge(
        LatticeTheme(
          node: const LatticeNodeStyle(
            background: _red,
            border: _green,
            selectedBorder: _blue,
          ),
        ),
      );

      expect(merged.node!.background, equals(_red));
      expect(merged.node!.border, equals(_green));
      expect(merged.node!.selectedBorder, equals(_blue));
      // Unset overlay components never reset the base.
      expect(merged.edge, equals(base.edge));
      expect(merged.handle, equals(base.handle));
      expect(merged.background, equals(base.background));
      expect(merged.minimap, equals(base.minimap));
      expect(merged.selection, equals(base.selection));
      expect(merged.connection, equals(base.connection));

      // A second layer over the merged theme still keeps untouched fields.
      final LatticeTheme twice = merged.merge(
        LatticeTheme(edge: const LatticeEdgeStyle(color: _gold)),
      );
      expect(twice.node!.background, equals(_red));
      expect(twice.edge!.color, equals(_gold));
      expect(twice.edge!.selectedColor, equals(base.edge!.selectedColor));

      // Null overlay is a no-op.
      expect(base.merge(null), equals(base));
    });

    test('light and dark define every component; unset resolves to light', () {
      for (final LatticeTheme theme in <LatticeTheme>[
        LatticeTheme.light(),
        LatticeTheme.dark(),
      ]) {
        expect(theme.node, isNotNull);
        expect(theme.edge, isNotNull);
        expect(theme.handle, isNotNull);
        expect(theme.background, isNotNull);
        expect(theme.minimap, isNotNull);
        expect(theme.selection, isNotNull);
        expect(theme.connection, isNotNull);
      }
      expect(LatticeTheme.light() == LatticeTheme.dark(), isFalse);

      final LatticeTheme empty = const LatticeTheme();
      expect(
        empty.resolvedNode.background,
        equals(LatticeTheme.light().node!.background),
      );
      expect(
        empty.resolvedEdge.color,
        equals(LatticeTheme.light().edge!.color),
      );
      expect(
        empty.resolvedBackground.dotColor,
        equals(LatticeTheme.light().background!.dotColor),
      );
    });

    test('component styles are value classes', () {
      expect(
        const LatticeNodeStyle(
          background: _red,
          border: _green,
          selectedBorder: _blue,
        ),
        equals(
          const LatticeNodeStyle(
            background: _red,
            border: _green,
            selectedBorder: _blue,
          ),
        ),
      );
      expect(
        const LatticeHandleStyle(fill: _red, border: _green),
        isNot(equals(const LatticeHandleStyle(fill: _green, border: _red))),
      );
      expect(
        const LatticeBackgroundStyle(
          dotColor: _red,
          lineColor: _green,
          dotRadius: 2,
        ).hashCode,
        equals(
          const LatticeBackgroundStyle(
            dotColor: _red,
            lineColor: _green,
            dotRadius: 2,
          ).hashCode,
        ),
      );
    });
  });

  group('theme reaches widgets', () {
    testWidgets('canvas theme paints the default node body', (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[_node('a')],
      );
      addTearDown(controller.dispose);

      const LatticeTheme theme = LatticeTheme(
        node: LatticeNodeStyle(
          background: _red,
          border: _green,
          selectedBorder: _blue,
        ),
      );
      await _pumpCanvas(tester, controller, theme: theme);

      expect(_hasBodyColor(tester, _red), isTrue);
      expect(_hasBodyColor(tester, Colors.white), isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('standalone node layer without a scope falls back to light',
        (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[_node('a')],
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: UncontrolledProviderScope(
            container: controller.container,
            child: const SizedBox(
              width: 800,
              height: 600,
              child: LatticeNodeLayer(),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(_hasBodyColor(tester, Colors.white), isTrue);
      expect(_hasBodyColor(tester, _red), isFalse);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('theme scope exposes the canvas theme and asks when missing',
        (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      LatticeTheme? seen;
      LatticeTheme? missing;
      await _pumpCanvas(
        tester,
        controller,
        theme: const LatticeTheme(),
        overlays: <Widget>[
          Builder(
            builder: (BuildContext context) {
              seen = LatticeThemeScope.of(context);
              missing = LatticeThemeScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ],
      );
      expect(seen, equals(const LatticeTheme()));
      expect(missing, equals(const LatticeTheme()));

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (BuildContext context) {
              missing = LatticeThemeScope.maybeOf(context);
              LatticeThemeScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(missing, isNull);
      expect(tester.takeException(), isA<AssertionError>());
    });

    testWidgets('custom edge style from the theme reaches the painter',
        (tester) async {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[_node('a'), _node('b', const Offset(300, 0))],
        initialEdges: <LatticeEdge>[_edge('e1', 'a', 'b')],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(
        tester,
        controller,
        theme: const LatticeTheme(
          edge: LatticeEdgeStyle(color: _green, selectedColor: _gold),
        ),
      );

      final LatticeEdgePainter painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere(
            (CustomPaint w) => w.painter is LatticeEdgePainter,
          )
          .painter! as LatticeEdgePainter;
      expect(painter.style.color, equals(_green));
      expect(painter.style.selectedColor, equals(_gold));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('explicit edge layer style wins over the theme', (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: UncontrolledProviderScope(
            container: controller.container,
            child: const LatticeThemeScope(
              theme: LatticeTheme(
                edge: LatticeEdgeStyle(color: _green),
              ),
              child: SizedBox.expand(
                child: LatticeEdgeLayer(
                  style: LatticeEdgeStyle(color: _gold),
                ),
              ),
            ),
          ),
        ),
      );

      final LatticeEdgePainter painter = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere(
            (CustomPaint w) => w.painter is LatticeEdgePainter,
          )
          .painter! as LatticeEdgePainter;
      expect(painter.style.color, equals(_gold));
    });

    testWidgets('handle dots and background neutrals come from the theme',
        (tester) async {
      const LatticeNode nodeWithHandle = LatticeNode(
        id: 'a',
        type: 'custom',
        position: Offset(100, 100),
        handles: <String, LatticeHandle>{
          'out': LatticeHandle(
            id: 'out',
            type: LatticeHandleType.source,
            position: Offset(77, 38),
          ),
        },
      );
      final controller = LatticeController(
        initialNodes: <LatticeNode>[nodeWithHandle],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(
        tester,
        controller,
        theme: const LatticeTheme(
          handle: LatticeHandleStyle(
            fill: _green,
            border: _gold,
            size: 12,
          ),
          background: LatticeBackgroundStyle(
            dotColor: _red,
            lineColor: _blue,
            dotRadius: 3,
          ),
        ),
        overlays: const <Widget>[LatticeBackground()],
      );

      expect(_hasBodyColor(tester, _green), isTrue);

      final CustomPaint background = tester
          .widgetList<CustomPaint>(find.byType(CustomPaint))
          .firstWhere(
            (CustomPaint w) => w.painter is LatticeBackgroundPainter,
          );
      final LatticeBackgroundPainter painter =
          background.painter! as LatticeBackgroundPainter;
      expect(painter.dotColor, equals(_red));
      expect(painter.lineColor, equals(_blue));
      expect(painter.dotRadius, equals(3));
      expect(painter.style, equals(LatticeBackgroundPattern.dots));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('LatticeOptions additions', () {
    test('new fields round-trip through copyWith and equality', () {
      const LatticeOptions base = LatticeOptions();
      expect(base.resizeMinSize, equals(40));
      expect(base.resizeMaxSize, equals(2000));
      expect(base.interactive, isTrue);
      expect(base.fitViewOnInit, isFalse);

      final LatticeOptions tuned = base.copyWith(
        resizeMinSize: 80,
        resizeMaxSize: 900,
        interactive: false,
        fitViewOnInit: true,
      );
      expect(tuned.resizeMinSize, equals(80));
      expect(tuned.resizeMaxSize, equals(900));
      expect(tuned.interactive, isFalse);
      expect(tuned.fitViewOnInit, isTrue);
      expect(tuned, isNot(equals(base)));
      expect(
        tuned,
        equals(
          const LatticeOptions(
            resizeMinSize: 80,
            resizeMaxSize: 900,
            interactive: false,
            fitViewOnInit: true,
          ),
        ),
      );
    });

    testWidgets('resize clamps to options.resizeMinSize/resizeMaxSize',
        (tester) async {
      final controller = LatticeController(
        options: const LatticeOptions(resizeMinSize: 100, resizeMaxSize: 300),
        initialNodes: <LatticeNode>[_node('a', Offset.zero, true)],
      );
      addTearDown(controller.dispose);

      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      controller.updateResize(const Offset(1000, 1000));
      controller.endResize();

      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(300, 300)),
      );

      controller.beginResize('a', LatticeResizeHandle.bottomRight);
      controller.updateResize(const Offset(-1000, -1000));
      controller.endResize();

      expect(
        controller.document.nodes['a']!.size,
        equals(const Size(100, 100)),
      );
    });

    testWidgets('fitViewOnInit fits content after the first layout',
        (tester) async {
      final controller = LatticeController(
        options: const LatticeOptions(fitViewOnInit: true),
        initialNodes: <LatticeNode>[
          _node('a', const Offset(200, 150)),
          _node('b', const Offset(400, 300)),
        ],
      );
      addTearDown(controller.dispose);

      final Matrix4 before =
          controller.container.read(latticeCameraProvider);
      await _pumpCanvas(tester, controller);
      await tester.pump();

      final Matrix4 after = controller.container.read(latticeCameraProvider);
      expect(after, isNot(equals(before)));
      expect(
        LatticeViewportValue.fromMatrix(after).zoom,
        greaterThan(0),
      );
      // The document viewport is untouched: fit writes the camera only.
      expect(controller.document.viewport, equals(const LatticeViewportValue()));

      // Flush the camera settle timer so no fake-async timer is pending
      // at teardown.
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('fitViewOnInit never runs when a defaultViewport is set',
        (tester) async {
      final controller = LatticeController(
        options: const LatticeOptions(
          fitViewOnInit: true,
          defaultViewport: LatticeViewportValue(
            offset: Offset(11, 22),
            zoom: 2,
          ),
        ),
        initialNodes: <LatticeNode>[_node('a', const Offset(300, 200))],
      );
      addTearDown(controller.dispose);

      await _pumpCanvas(tester, controller);
      await tester.pump();

      // No defaultViewport sync happens at mount: the camera stays at
      // identity and fitViewOnInit is skipped because a default viewport
      // was provided.
      expect(
        controller.container.read(latticeCameraProvider),
        equals(Matrix4.identity()),
      );

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });

    testWidgets('interactive:false blocks drags and camera verbs, keeps taps',
        (tester) async {
      final controller = LatticeController(
        options: const LatticeOptions(interactive: false),
        initialNodes: <LatticeNode>[
          _node('a', const Offset(100, 100)),
          _node('b', const Offset(400, 300)),
        ],
      );
      addTearDown(controller.dispose);

      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);

      await _pumpCanvas(tester, controller);

      final Matrix4 cameraBefore =
          controller.container.read(latticeCameraProvider);
      controller.zoomIn();
      controller.zoomOut();
      controller.fitView();
      expect(
        controller.container.read(latticeCameraProvider),
        equals(cameraBefore),
      );

      final gesture = await tester.startGesture(const Offset(150, 120));
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      expect(
        controller.container.read(latticeDragProvider).isActive,
        isFalse,
      );
      await gesture.up();
      await tester.pump();

      expect(
        controller.document.nodes['a']!.position,
        equals(const Offset(100, 100)),
      );
      // Nothing fired for the blocked drag (the canvas' onInit is the only
      // fire allowed for a controller whose callbacks were pre-attached).
      expect(recorder.addedNodes, isEmpty);
      expect(recorder.removedNodes, isEmpty);
      expect(recorder.addedEdges, isEmpty);
      expect(recorder.removedEdges, isEmpty);
      expect(recorder.selections, isEmpty);
      expect(recorder.viewports, isEmpty);
      expect(recorder.connects, isEmpty);

      await tester.tapAt(const Offset(150, 120));
      await tester.pump();
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        equals(<String>{'a'}),
      );
      expect(recorder.selections, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });

  group('LatticeCallbacks', () {
    test('add/remove verbs fire once with the committed objects', () {
      final controller = LatticeController();
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      final LatticeNode a = _node('a');
      controller.addNode(a);
      expect(recorder.addedNodes, equals(<LatticeNode>[a]));
      expect(notifications, equals(1));

      // No-op verb (equal document): no notify, no callback.
      controller.addNode(a);
      expect(recorder.addedNodes, hasLength(1));
      expect(notifications, equals(1));

      final LatticeEdge e = _edge('e1', 'a', 'a');
      controller.addEdge(e);
      expect(recorder.addedEdges, equals(<LatticeEdge>[e]));
      expect(notifications, equals(2));

      controller.removeNodes(<String>{'a'});
      expect(recorder.removedNodes, equals(<LatticeNode>[a]));
      expect(notifications, equals(3));
      // No-op remove: no callback.
      controller.removeNodes(<String>{'a'});
      expect(recorder.removedNodes, hasLength(1));

      controller.addEdge(e);
      controller.removeEdges(<String>{'e1'});
      expect(recorder.removedEdges, equals(<LatticeEdge>[e]));

      // deleteElements reports the cascade-removed objects.
      final LatticeNode parent = _node('p');
      final LatticeNode child = _node('c').copyWith(parentId: 'p');
      controller.addNode(parent);
      controller.addNode(child);
      controller.addEdge(_edge('e2', 'p', 'c'));
      recorder.addedNodes.clear();
      recorder.addedEdges.clear();
      recorder.removedNodes.clear();
      recorder.removedEdges.clear();
      controller.deleteElements(nodeIds: <String>{'p'});
      expect(
        recorder.removedNodes.map((LatticeNode n) => n.id).toSet(),
        equals(<String>{'p', 'c'}),
      );
      expect(
        recorder.removedEdges.map((LatticeEdge edge) => edge.id),
        equals(<String>['e2']),
      );
    });

    test('selection verbs fire once per actual change and never twice', () {
      final controller = LatticeController(initialNodes: <LatticeNode>[_node('a'), _node('b')]);
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.select(<String>{'a'});
      expect(recorder.selections, hasLength(1));
      expect(recorder.selections.single.nodes, equals(<String>{'a'}));

      controller.select(<String>{'a'});
      expect(recorder.selections, hasLength(1));

      controller.selectAll();
      expect(recorder.selections, hasLength(2));
      expect(recorder.selections.last.nodes, equals(<String>{'a', 'b'}));

      controller.deselectAll();
      expect(recorder.selections, hasLength(3));
      expect(recorder.selections.last.isEmpty, isTrue);

      controller.deselectAll();
      expect(recorder.selections, hasLength(3));

      // Selection is session-only: controller listeners never fired.
      expect(notifications, equals(0));
    });

    test('taps and marquees route through the selection callback', () {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[_node('a', const Offset(100, 100))],
      );
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      controller.tapAt(const Offset(150, 120));
      expect(recorder.selections, hasLength(1));
      expect(recorder.selections.single.nodes, equals(<String>{'a'}));

      controller.tapAt(const Offset(700, 500));
      expect(recorder.selections, hasLength(2));
      expect(recorder.selections.last.isEmpty, isTrue);

      controller.beginMarquee(const Offset(0, 0));
      controller.updateMarquee(const Offset(400, 400));
      controller.endMarquee();
      expect(recorder.selections, hasLength(3));
      expect(recorder.selections.last.nodes, equals(<String>{'a'}));
    });

    test('connect fires onEdgesAdded then onConnect exactly once', () {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[
          const LatticeNode(
            id: 'a',
            type: 'custom',
            position: Offset(100, 100),
            handles: <String, LatticeHandle>{
              'out': LatticeHandle(
                id: 'out',
                type: LatticeHandleType.source,
                position: Offset(77, 38),
              ),
            },
          ),
          const LatticeNode(
            id: 'b',
            type: 'custom',
            position: Offset(400, 300),
            handles: <String, LatticeHandle>{
              'in': LatticeHandle(
                id: 'in',
                type: LatticeHandleType.target,
                position: Offset(77, -3),
              ),
            },
          ),
        ],
      );
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      controller.beginConnect(const LatticeEndpoint(nodeId: 'a', handleId: 'out'));
      controller.endConnect(const LatticeEndpoint(nodeId: 'b', handleId: 'in'));

      expect(recorder.addedEdges, hasLength(1));
      expect(recorder.connects, hasLength(1));
      expect(recorder.connects.single, same(recorder.addedEdges.single));
      expect(recorder.addedEdges.single.id, startsWith('edge_'));

      // Cancel/invalid sessions fire nothing.
      controller.beginConnect(const LatticeEndpoint(nodeId: 'a', handleId: 'out'));
      controller.endConnect(null);
      expect(recorder.connects, hasLength(1));
      expect(recorder.addedEdges, hasLength(1));
    });

    test('viewport callback fires on saveViewport only', () {
      final controller = LatticeController();
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      final LatticeCameraController camera =
          controller.container.read(latticeCameraProvider.notifier);
      camera.panBy(const Offset(30, 40));
      camera.zoomBy(1.5);
      expect(recorder.viewports, isEmpty);

      controller.saveViewport();
      expect(recorder.viewports, hasLength(1));
      expect(recorder.viewports.single, equals(camera.viewport));
      expect(controller.document.viewport, equals(camera.viewport));

      // No document change: no callback.
      controller.saveViewport();
      expect(recorder.viewports, hasLength(1));
    });

    test('session-only ticks and move commits fire no callbacks', () {
      final controller = LatticeController(
        initialNodes: <LatticeNode>[_node('a', const Offset(100, 100))],
      );
      final _Recorder recorder = _Recorder();
      controller.attachCallbacks(recorder.callbacks);
      addTearDown(controller.dispose);

      var notifications = 0;
      controller.addListener(() => notifications++);

      // Seed the selection so drag start does not auto-select (which IS a
      // selection change) and inflate the count.
      controller.select(<String>{'a'});
      recorder.clear();

      controller.beginNodeDrag('a');
      controller.updateNodeDrag(const Offset(50, 0));
      expect(recorder.total, equals(0));

      controller.endNodeDrag();
      // The move committed (one document notification) but no hook covers
      // moves: LatticeCallbacks has no changed/moved callback.
      expect(notifications, equals(1));
      expect(recorder.total, equals(0));
    });

    testWidgets('canvas attaches callbacks and fires onInit once post-frame',
        (tester) async {
      final controller = LatticeController();
      addTearDown(controller.dispose);

      final _Recorder recorder = _Recorder();
      await _pumpCanvas(tester, controller, callbacks: recorder.callbacks);
      await tester.pump();

      expect(recorder.inits, hasLength(1));
      expect(recorder.inits.single, same(controller));

      await tester.pump();
      expect(recorder.inits, hasLength(1));

      controller.addNode(_node('a'));
      expect(recorder.addedNodes, hasLength(1));
      expect(recorder.total, equals(2));

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    });
  });
}
