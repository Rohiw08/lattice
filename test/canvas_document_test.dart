import 'package:lattice/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CanvasDocument round-trip preserves nodes', () {
    final state = FlowCanvasState.initial().copyWith(
      nodes: {
        'a': FlowNode.create(
          id: 'a',
          type: 'default',
          position: const Offset(12, 34),
          data: const {},
        ),
      },
    );
    final doc = CanvasDocument.fromState(state);
    final json = doc.toJson();
    final decoded = CanvasDocument.fromJson(json);

    expect(decoded.version, CanvasDocument.currentVersion);
    expect(decoded.state.nodes['a']?.position, const Offset(12, 34));
  });
}
