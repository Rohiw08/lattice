import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

/// Two nodes with explicit single-port handles:
/// `a` has source `out`, `b` has target `in`.
LatticeDocument _twoNodeDoc({Map<String, LatticeEdge> edges = const {}}) {
  const outHandle = LatticeHandle(
    id: 'out',
    type: LatticeHandleType.source,
    position: Offset(0, 0),
  );
  const inHandle = LatticeHandle(
    id: 'in',
    type: LatticeHandleType.target,
    position: Offset(0, 0),
  );
  return LatticeDocument(
    nodes: const <String, LatticeNode>{
      'a': LatticeNode(
        id: 'a',
        type: 'custom',
        position: Offset(0, 0),
        handles: <String, LatticeHandle>{'out': outHandle},
      ),
      'b': LatticeNode(
        id: 'b',
        type: 'custom',
        position: Offset(100, 100),
        handles: <String, LatticeHandle>{'in': inHandle},
      ),
    },
    edges: edges,
  );
}

/// Single node carrying both a source and a target port.
LatticeDocument _selfDoc() {
  const outHandle = LatticeHandle(
    id: 'out',
    type: LatticeHandleType.source,
    position: Offset(0, 0),
  );
  const inHandle = LatticeHandle(
    id: 'in',
    type: LatticeHandleType.target,
    position: Offset(0, 0),
  );
  return const LatticeDocument(
    nodes: <String, LatticeNode>{
      'n': LatticeNode(
        id: 'n',
        type: 'custom',
        position: Offset(0, 0),
        handles: <String, LatticeHandle>{'out': outHandle, 'in': inHandle},
      ),
    },
  );
}

/// Nodes with synthesized default ports (null-handle endpoints).
LatticeDocument _defaultPortDoc() {
  return const LatticeDocument(
    nodes: <String, LatticeNode>{
      'a': LatticeNode(id: 'a', type: 'default', position: Offset(0, 0)),
      'b': LatticeNode(id: 'b', type: 'default', position: Offset(100, 100)),
    },
  );
}

void main() {
  group('latticeValidateConnection', () {
    test('valid source->target passes', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          target: const LatticeEndpoint(nodeId: 'b', handleId: 'in'),
          doc: _twoNodeDoc(),
        ),
        isTrue,
      );
    });

    test('reversed direction (target->source) rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'b', handleId: 'in'),
          target: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });

    test('source handle with target type rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'b', handleId: 'in'),
          target: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });

    test('self-connection rejected by default, allowed with flag', () {
      const source = LatticeEndpoint(nodeId: 'n', handleId: 'out');
      const target = LatticeEndpoint(nodeId: 'n', handleId: 'in');
      expect(
        latticeValidateConnection(source: source, target: target, doc: _selfDoc()),
        isFalse,
      );
      expect(
        latticeValidateConnection(
          source: source,
          target: target,
          doc: _selfDoc(),
          allowSelfConnections: true,
        ),
        isTrue,
      );
    });

    test('duplicate rejected by default, allowed with flag', () {
      const source = LatticeEndpoint(nodeId: 'a', handleId: 'out');
      const target = LatticeEndpoint(nodeId: 'b', handleId: 'in');
      final doc = _twoNodeDoc(
        edges: const <String, LatticeEdge>{
          'e1': LatticeEdge(id: 'e1', source: source, target: target),
        },
      );
      expect(
        latticeValidateConnection(source: source, target: target, doc: doc),
        isFalse,
      );
      expect(
        latticeValidateConnection(
          source: source,
          target: target,
          doc: doc,
          allowDuplicates: true,
        ),
        isTrue,
      );
    });

    test('missing source node rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'nope', handleId: 'out'),
          target: const LatticeEndpoint(nodeId: 'b', handleId: 'in'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });

    test('missing target node rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          target: const LatticeEndpoint(nodeId: 'nope', handleId: 'in'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });

    test('unknown handle id rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a', handleId: 'nope'),
          target: const LatticeEndpoint(nodeId: 'b', handleId: 'in'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });

    test('null-handleId endpoints valid when ports exist', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a'),
          target: const LatticeEndpoint(nodeId: 'b'),
          doc: _defaultPortDoc(),
        ),
        isTrue,
      );
    });

    test('null-handleId rejected when implied port type missing', () {
      // `input` nodes synthesize only a target handle: no source port.
      const doc = LatticeDocument(
        nodes: <String, LatticeNode>{
          'a': LatticeNode(id: 'a', type: 'input', position: Offset(0, 0)),
          'b': LatticeNode(id: 'b', type: 'default', position: Offset(0, 0)),
        },
      );
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a'),
          target: const LatticeEndpoint(nodeId: 'b'),
          doc: doc,
        ),
        isFalse,
      );
    });

    test('same (nodeId, handleId) on both ends rejected', () {
      expect(
        latticeValidateConnection(
          source: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          target: const LatticeEndpoint(nodeId: 'a', handleId: 'out'),
          doc: _twoNodeDoc(),
        ),
        isFalse,
      );
    });
  });

  group('LatticeDragState.connect', () {
    test('isActive true, reconnectEdgeId null by default', () {
      const state = LatticeDragState.connect(
        from: LatticeEndpoint(nodeId: 'a', handleId: 'out'),
        liveEnd: Offset(10, 20),
      );
      expect(state.isActive, isTrue);
      expect(state.from, equals(const LatticeEndpoint(nodeId: 'a', handleId: 'out')));
      expect(state.liveEnd, equals(const Offset(10, 20)));
      expect(state.reconnectEdgeId, isNull);
    });

    test('stores reconnectEdgeId', () {
      const state = LatticeDragState.connect(
        from: LatticeEndpoint(nodeId: 'a'),
        liveEnd: Offset(1, 2),
        reconnectEdgeId: 'e1',
      );
      expect(state.isActive, isTrue);
      expect(state.reconnectEdgeId, equals('e1'));
    });

    test('idle stays inactive', () {
      const state = LatticeDragState.idle();
      expect(state.isActive, isFalse);
      expect(state.from, isNull);
      expect(state.liveEnd, isNull);
      expect(state.reconnectEdgeId, isNull);
    });
  });
}
