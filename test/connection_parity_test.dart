import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/connection_options.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/connections/application/connection_service.dart';
import 'package:lattice/src/features/connections/domain/models/connection_params.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ConnectionService service;
  late FlowCanvasState base;
  late NodeIndex index;

  setUp(() {
    service = ConnectionService();
    base = NodeService().addNodes(const FlowCanvasState(), [
      FlowNode<String>(
        id: 'a',
        type: 'input',
        position: Offset.zero,
        data: 'A',
        resizable: false,
      ),
      FlowNode<String>(
        id: 'b',
        type: 'output',
        position: const Offset(300, 0),
        data: 'B',
        resizable: false,
      ),
    ]);
    index = NodeIndex.fromNodes(base.nodes.values);
  });

  test('strict mode creates edge source → target', () {
    final a = base.nodes['a']!;
    final start = a.position + a.effectiveHandles['source']!.position;
    var state = service.startConnection(
      base,
      fromNodeId: 'a',
      fromHandleId: 'source',
      startPosition: start,
    );

    final b = state.nodes['b']!;
    final end = b.position + b.effectiveHandles['target']!.position;
    state = service.updateConnection(
      state,
      end,
      index,
      snapRadius: 40,
      mode: ConnectionMode.strict,
    );
    expect(
      (state.connectionState as dynamic).isValid,
      isTrue,
    );

    state = service.endConnection(state, mode: ConnectionMode.strict);
    expect(state.edges.length, 1);
    final edge = state.edges.values.first;
    expect(edge.sourceNodeId, 'a');
    expect(edge.targetNodeId, 'b');
  });

  test('isValidConnection callback can reject', () {
    final a = base.nodes['a']!;
    final start = a.position + a.effectiveHandles['source']!.position;
    var state = service.startConnection(
      base,
      fromNodeId: 'a',
      fromHandleId: 'source',
      startPosition: start,
    );

    final b = state.nodes['b']!;
    final end = b.position + b.effectiveHandles['target']!.position;
    state = service.updateConnection(
      state,
      end,
      index,
      snapRadius: 40,
      isValidConnection: (_) => false,
    );
    expect((state.connectionState as dynamic).isValid, isFalse);

    state = service.endConnection(
      state,
      isValidConnection: (_) => false,
    );
    expect(state.edges, isEmpty);
  });

  test('autoCreateEdge false leaves graph unchanged', () {
    final a = base.nodes['a']!;
    final start = a.position + a.effectiveHandles['source']!.position;
    var state = service.startConnection(
      base,
      fromNodeId: 'a',
      fromHandleId: 'source',
      startPosition: start,
    );
    final b = state.nodes['b']!;
    final end = b.position + b.effectiveHandles['target']!.position;
    state = service.updateConnection(state, end, index, snapRadius: 40);
    state = service.endConnection(state, autoCreateEdge: false);
    expect(state.edges, isEmpty);
    expect(state.activeConnection, isNull);
  });

  test('ConnectionOptions defaults match Lattice', () {
    const opts = ConnectionOptions();
    expect(opts.connectionMode, ConnectionMode.strict);
    expect(opts.connectionRadius, 20);
    expect(opts.connectOnClick, isFalse);
    expect(opts.autoCreateEdge, isTrue);
    expect(opts.edgesReconnectable, isTrue);
  });

  test('ConnectionParams equality', () {
    const a = ConnectionParams(
      sourceNodeId: '1',
      targetNodeId: '2',
      sourceHandleId: 's',
      targetHandleId: 't',
    );
    const b = ConnectionParams(
      sourceNodeId: '1',
      targetNodeId: '2',
      sourceHandleId: 's',
      targetHandleId: 't',
    );
    expect(a, b);
  });
}
