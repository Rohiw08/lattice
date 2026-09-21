import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/connections/application/connection_service.dart';
import 'package:lattice/src/features/handles/domain/handle.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Typed-port parity: a handle's [FlowHandle.connectionGroup] must gate
/// connections. Both RF and the Lattice docs promise "handles can only connect
/// if their groups are compatible", and [FlowHandle.isCompatibleWithGroup]
/// already implements the rule — but `_isValidConnection` never called it, so a
/// 'number' port would happily connect to a 'string' port. These tests pin the
/// enforcement so it can't silently regress.
void main() {
  final service = ConnectionService();

  FlowNode<String> nodeWith(String id, FlowHandle handle) => FlowNode<String>(
        id: id,
        type: 'custom',
        position: Offset.zero,
        data: id,
        handles: {handle.id: handle},
      );

  FlowHandle source(String? group) => FlowHandle(
        id: 'source',
        type: HandleType.source,
        position: Offset.zero,
        connectionGroup: group,
      );

  FlowHandle target(String? group) => FlowHandle(
        id: 'target',
        type: HandleType.target,
        position: Offset.zero,
        connectionGroup: group,
      );

  bool canConnect(FlowNode<String> a, FlowNode<String> b) =>
      service.isValidConnectionPair(
        a,
        a.effectiveHandles['source']!,
        b,
        b.effectiveHandles['target']!,
      );

  test('mismatched connection groups are rejected', () {
    final a = nodeWith('a', source('number'));
    final b = nodeWith('b', target('string'));
    expect(
      canConnect(a, b),
      isFalse,
      reason: "a 'number' port must not connect to a 'string' port",
    );
  });

  test('matching connection groups are allowed', () {
    final a = nodeWith('a', source('number'));
    final b = nodeWith('b', target('number'));
    expect(canConnect(a, b), isTrue);
  });

  test('a null group is a wildcard compatible with any group', () {
    // Wildcard source → typed target.
    expect(
      canConnect(nodeWith('a', source(null)), nodeWith('b', target('string'))),
      isTrue,
    );
    // Typed source → wildcard target (symmetric).
    expect(
      canConnect(nodeWith('c', source('number')), nodeWith('d', target(null))),
      isTrue,
    );
  });
}
