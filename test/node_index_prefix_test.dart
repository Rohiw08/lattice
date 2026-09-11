import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updating node_1 must not remove node_10 from spatial grid', () {
    final index = NodeIndex.empty(cellSize: 250);
    final n1 = FlowNode.create(
      id: 'node_1',
      type: 'custom',
      position: const Offset(10, 10),
      size: const Size(100, 50),
      data: null,
    );
    final n10 = FlowNode.create(
      id: 'node_10',
      type: 'custom',
      position: const Offset(20, 20),
      size: const Size(100, 50),
      data: null,
    );
    index.addNode(n1);
    index.addNode(n10);

    final n1Moved = n1.copyWith(position: const Offset(300, 10));
    index.updateNode(n1, n1Moved);

    final hits = index.queryNodesInRect(const Rect.fromLTWH(0, 0, 200, 200));
    expect(hits.contains('node_10'), isTrue);
    expect(hits.contains('node_1'), isFalse);
  });
}
