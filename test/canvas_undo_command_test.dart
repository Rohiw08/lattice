import 'package:lattice/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('NodePositionUndoCommand moves nodes to target positions', () {
    final base = FlowCanvasState.initial().copyWith(
      nodes: {
        'a': FlowNode.create(
          id: 'a',
          type: 'default',
          position: const Offset(0, 0),
          data: const {},
        ),
      },
    );
    final cmd = NodePositionUndoCommand({'a': const Offset(5, 7)});
    final next = cmd.applyUndo(base);
    expect(next.nodes['a']?.position, const Offset(5, 7));
  });
}
