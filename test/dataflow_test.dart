import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  List<FlowNode<Object>> nodes = const [
    FlowNode<Map<String, dynamic>>(
      id: 'r',
      type: 'number',
      position: Offset(40, 40),
      data: {'value': 200},
    ),
    FlowNode<Map<String, dynamic>>(
      id: 'color',
      type: 'color',
      position: Offset(320, 40),
      data: {'r': 0, 'g': 0, 'b': 0},
    ),
  ],
  List<FlowEdge> edges = const [
    FlowEdge(
      id: 'e1',
      sourceNodeId: 'r',
      targetNodeId: 'color',
      sourceHandleId: 'source',
      targetHandleId: 'red',
    ),
  ],
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
            initialNodes: nodes,
            initialEdges: edges,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('nodeConnectionsOf (useNodeConnections parity)', () {
    const edges = [
      FlowEdge(
        id: 'e1',
        sourceNodeId: 'r',
        targetNodeId: 'color',
        sourceHandleId: 'source',
        targetHandleId: 'red',
      ),
      FlowEdge(
        id: 'e2',
        sourceNodeId: 'g',
        targetNodeId: 'color',
        sourceHandleId: 'source',
        targetHandleId: 'green',
      ),
    ];

    test('filters by node + handleType + handleId', () {
      final all = nodeConnectionsOf(edges, 'color');
      expect(all.map((c) => c.edgeId), ['e1', 'e2']);

      final red = nodeConnectionsOf(
        edges,
        'color',
        handleType: HandleType.target,
        handleId: 'red',
      );
      expect(red.map((c) => c.edgeId), ['e1']);
      expect(red.single.sourceNodeId, 'r');

      expect(
        nodeConnectionsOf(edges, 'color', handleType: HandleType.source),
        isEmpty,
      );
      expect(
        nodeConnectionsOf(edges, 'r', handleType: HandleType.source)
            .map((c) => c.edgeId),
        ['e1'],
      );
    });

    test('FlowNodeConnection helpers', () {
      const c = FlowNodeConnection(
        edgeId: 'e1',
        sourceNodeId: 'r',
        targetNodeId: 'color',
        sourceHandleId: 'source',
        targetHandleId: 'red',
      );
      expect(c.oppositeOf('r'), 'color');
      expect(c.oppositeOf('color'), 'r');
      expect(c.oppositeOf('nope'), isNull);
      expect(
        FlowNodeConnection.fromEdge(edges.first),
        c,
      );
    });
  });

  group('incomers / outgoers (getIncomers / getOutgoers parity)', () {
    const edges = [
      FlowEdge(id: 'e1', sourceNodeId: 'r', targetNodeId: 'color'),
      FlowEdge(id: 'e2', sourceNodeId: 'color', targetNodeId: 'light'),
    ];

    test('pure helpers', () {
      expect(incomersOf(edges, 'color'), ['r']);
      expect(outgoersOf(edges, 'color'), ['light']);
      expect(incomersOf(edges, 'r'), isEmpty);
    });

    testWidgets('controller versions agree', (tester) async {
      final controller = FlowCanvasController();
      await _pump(
        tester,
        controller: controller,
        nodes: const [
          FlowNode<String>(id: 'r', type: 'input', position: Offset(40, 40)),
          FlowNode<String>(id: 'color', type: 'default', position: Offset(320, 40)),
          FlowNode<String>(id: 'light', type: 'output', position: Offset(560, 40)),
        ],
        edges: edges,
      );
      await tester.pump();

      expect(controller.edges.getIncomers('color'), ['r']);
      expect(controller.edges.getOutgoers('color'), ['light']);
      expect(
        controller.edges
            .getNodeConnections('color', handleType: HandleType.target)
            .map((c) => c.edgeId),
        ['e1'],
      );
    });
  });

  group('watchNodesData (useNodesData parity)', () {
    testWidgets('single + many rebuild on data change', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      Object? seenR;
      List<String> seenIds = const [];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                controller: controller,
                theme: FlowCanvasTheme.dark(),
                initialNodes: const [
                  FlowNode<Map<String, dynamic>>(
                    id: 'r',
                    type: 'number',
                    position: Offset(40, 40),
                    data: {'value': 200},
                  ),
                  FlowNode<Map<String, dynamic>>(
                    id: 'color',
                    type: 'color',
                    position: Offset(320, 40),
                    data: {'r': 0, 'g': 0, 'b': 0},
                  ),
                ],
                initialEdges: const [
                  FlowEdge(
                    id: 'e1',
                    sourceNodeId: 'r',
                    targetNodeId: 'color',
                    sourceHandleId: 'source',
                    targetHandleId: 'red',
                  ),
                ],
                overlays: [
                  Consumer(
                    builder: (context, ref, _) {
                      final slice = watchNodesData(ref, 'r');
                      seenR = slice?.dataAs<Map>()?['value'];
                      final many = watchNodesDataMany(ref, const ['r', 'color']);
                      seenIds = many.map((s) => s.id).toList();
                      final conns = watchNodeConnections(
                        ref,
                        'color',
                        handleType: HandleType.target,
                        handleId: 'red',
                      );
                      expect(conns.map((c) => c.edgeId), ['e1']);
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(seenR, 200);
      expect(seenIds, ['r', 'color']);

      controller.nodes.updateNodeData('r', {'value': 11});
      await tester.pump();
      expect(seenR, 11);

      expect(watchNodesDataMany, isNotNull);
    });
  });

  group('updateNodeData merge/fn + edge data (updateNodeData parity)', () {
    testWidgets('patch merges maps, replace swaps, With maps fn', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.nodes.patchNodeData('color', {'r': 10});
      expect(
        (controller.nodes.getNode('color')?.data as Map)['r'],
        10,
      );
      expect(
        (controller.nodes.getNode('color')?.data as Map)['g'],
        0,
      );

      controller.nodes.patchNodeData('color', {'only': 1}, replace: true);
      expect(
        (controller.nodes.getNode('color')?.data as Map).containsKey('r'),
        isFalse,
      );

      controller.nodes.updateNodeDataWith('color', (_) => {'r': 1});
      expect(
        (controller.nodes.getNode('color')?.data as Map)['r'],
        1,
      );
    });
  });

  group('luminance (guide formula)', () {
    test('black/white + threshold', () {
      expect(flowLuminance(r: 0, g: 0, b: 0), 0);
      expect(flowLuminance(r: 255, g: 255, b: 255), closeTo(255, 0.01));
      expect(isLightColor(r: 0, g: 0, b: 0), isFalse);
      expect(isLightColor(r: 255, g: 255, b: 255), isTrue);
      expect(isLightColor(r: 128, g: 128, b: 128), isTrue);
      expect(isLightColor(r: 127, g: 127, b: 127), isFalse);
    });
  });
}
