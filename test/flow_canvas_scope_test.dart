import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Tests for [FlowCanvasScope] (context access to the enclosing canvas) and
/// the public selector providers (`useNodes` / `useEdges` / `useViewport`
/// counterparts). Public API only — no `src/` imports.
List<FlowNode<Object>> _nodes([String prefix = '']) => <FlowNode<Object>>[
      FlowNode<String>(
        id: '${prefix}a',
        type: 'input',
        position: const Offset(80, 120),
        data: 'A',
      ),
      FlowNode<String>(
        id: '${prefix}b',
        type: 'output',
        position: const Offset(320, 120),
        data: 'B',
      ),
    ];

Future<void> _pumpCanvas(
  WidgetTester tester, {
  required FlowCanvasController controller,
  List<Widget> overlays = const <Widget>[],
  String prefix = '',
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            initialNodes: _nodes(prefix),
            overlays: overlays,
          ),
        ),
      ),
    ),
  );
}

/// Consumer watchdog: displays the length of the watched slice under [label].
class _WatchText extends ConsumerWidget {
  const _WatchText(this.label, this.value);

  final String label;
  final int Function(WidgetRef ref) value;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text('$label:${value(ref)}', key: ValueKey(label));
  }
}

String _shown(WidgetTester tester, String label) {
  final text = tester.widget<Text>(find.byKey(ValueKey(label)));
  return text.data!;
}

void main() {
  group('FlowCanvasScope', () {
    testWidgets('of returns the attached controller inside the canvas',
        (tester) async {
      final controller = FlowCanvasController();
      FlowCanvasController? captured;
      FlowCanvasController? capturedViaExtension;
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          Builder(
            builder: (context) {
              captured = FlowCanvasScope.of(context);
              capturedViaExtension = context.flowCanvas;
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      expect(captured, isNotNull);
      expect(identical(captured, controller), isTrue);
      expect(identical(capturedViaExtension, controller), isTrue);
      expect(controller.isAttached, isTrue);
    });

    testWidgets('maybeOf returns the controller; extension maybe too',
        (tester) async {
      final controller = FlowCanvasController();
      FlowCanvasController? captured;
      FlowCanvasController? capturedViaExtension;
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          Builder(
            builder: (context) {
              captured = FlowCanvasScope.maybeOf(context);
              capturedViaExtension = context.flowCanvasMaybe;
              return const SizedBox.shrink();
            },
          ),
        ],
      );

      expect(identical(captured, controller), isTrue);
      expect(identical(capturedViaExtension, controller), isTrue);
    });

    testWidgets('maybeOf is null and of throws outside a canvas',
        (tester) async {
      FlowCanvasController? captured;
      Object? thrown;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              captured = FlowCanvasScope.maybeOf(context);
              try {
                FlowCanvasScope.of(context);
              } catch (e) {
                thrown = e;
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(captured, isNull);
      // AssertionError in debug/test, StateError in release.
      expect(thrown, anyOf([isA<AssertionError>(), isA<StateError>()]));
    });
  });

  group('selector providers', () {
    testWidgets('flowNodesProvider rebuilds when a node is added',
        (tester) async {
      final controller = FlowCanvasController();
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          _WatchText(
              'nodes', (ref) => ref.watch(flowNodesProvider).length),
        ],
      );

      expect(_shown(tester, 'nodes'), 'nodes:2');
      controller.nodes.addNode(
        const FlowNode<String>(
          id: 'c',
          type: 'default',
          position: Offset(560, 120),
          data: 'C',
        ),
      );
      await tester.pump();

      expect(_shown(tester, 'nodes'), 'nodes:3');
    });

    testWidgets('flowEdgesProvider rebuilds when an edge is added',
        (tester) async {
      final controller = FlowCanvasController();
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          _WatchText(
              'edges', (ref) => ref.watch(flowEdgesProvider).length),
        ],
      );

      expect(_shown(tester, 'edges'), 'edges:0');
      controller.edges.addEdge(
        const FlowEdge(
          id: 'e1',
          sourceNodeId: 'a',
          targetNodeId: 'b',
          sourceHandleId: 'source',
          targetHandleId: 'target',
        ),
      );
      await tester.pump();

      expect(_shown(tester, 'edges'), 'edges:1');
    });

    testWidgets('flowViewportProvider rebuilds on programmatic pan',
        (tester) async {
      final controller = FlowCanvasController();
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          _WatchText(
            'zoom',
            (ref) => (ref.watch(flowViewportProvider).zoom * 10).round(),
          ),
        ],
      );

      expect(_shown(tester, 'zoom'), isNotEmpty);
      final before = controller.viewport
          .flowToViewport(const Offset(100, 100));
      controller.viewport.panBy(const Offset(50, 25));
      await tester.pump();
      final after = controller.viewport
          .flowToViewport(const Offset(100, 100));

      // Pan moves content by the delta in viewport space.
      expect((after - before).dx, moreOrLessEquals(50.0));
      expect((after - before).dy, moreOrLessEquals(25.0));
    });

    testWidgets('flowSelectedNodeIdsProvider rebuilds on selectNode',
        (tester) async {
      final controller = FlowCanvasController();
      await _pumpCanvas(
        tester,
        controller: controller,
        overlays: [
          _WatchText(
            'sel',
            (ref) => ref.watch(flowSelectedNodeIdsProvider).length,
          ),
        ],
      );

      expect(_shown(tester, 'sel'), 'sel:0');
      controller.selection.selectNode('a');
      await tester.pump();

      expect(_shown(tester, 'sel'), 'sel:1');
    });

    testWidgets('two canvases stay isolated', (tester) async {
      final first = FlowCanvasController();
      final second = FlowCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SizedBox(
                  width: 400,
                  height: 600,
                  child: FlowCanvas(
                    controller: first,
                    theme: FlowCanvasTheme.dark(),
                    initialNodes: _nodes('one_'),
                    overlays: const [
                      _WatchText(
                        'one',
                        _oneCount,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 400,
                  height: 600,
                  child: FlowCanvas(
                    controller: second,
                    theme: FlowCanvasTheme.dark(),
                    initialNodes: _nodes('two_'),
                    overlays: const [
                      _WatchText(
                        'two',
                        _twoCount,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(_shown(tester, 'one'), 'one:2');
      expect(_shown(tester, 'two'), 'two:2');

      first.nodes.addNode(
        const FlowNode<String>(
          id: 'one_c',
          type: 'default',
          position: Offset(560, 120),
          data: 'C',
        ),
      );
      await tester.pump();

      // Only the first canvas observes the change.
      expect(_shown(tester, 'one'), 'one:3');
      expect(_shown(tester, 'two'), 'two:2');
    });
  });
}

int _oneCount(WidgetRef ref) => ref.watch(flowNodesProvider).length;
int _twoCount(WidgetRef ref) => ref.watch(flowNodesProvider).length;
