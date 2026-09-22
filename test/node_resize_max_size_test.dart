import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// `ViewportOptions.maxNodeSize` is threaded into `NodeService.resizeNode` as
/// the global resize ceiling (per-node `maxSize` still wins). Mirrors the
/// long-standing `minNodeSize` floor.
void main() {
  final service = NodeService();

  FlowCanvasState seeded() {
    const node = FlowNode<String>(
      id: 'n',
      type: 'default',
      position: Offset(100, 100),
      size: Size(100, 100),
      data: 'N',
    );
    return const FlowCanvasState().copyWith(nodes: {'n': node});
  }

  test('global maxSize clamps a bottom-right resize', () {
    final next = service.resizeNode(
      seeded(),
      'n',
      ResizeDirection.bottomRight,
      const Offset(500, 500), // way past the ceiling
      maxSize: const Size(150, 150),
    );
    final size = next.nodes['n']!.size;
    expect(size.width, lessThanOrEqualTo(150));
    expect(size.height, lessThanOrEqualTo(150));
  });

  test('per-node maxSize overrides the global ceiling', () {
    const node = FlowNode<String>(
      id: 'n',
      type: 'default',
      position: Offset(100, 100),
      size: Size(100, 100),
      maxSize: Size(120, 120),
      data: 'N',
    );
    final state = const FlowCanvasState().copyWith(nodes: {'n': node});
    final next = service.resizeNode(
      state,
      'n',
      ResizeDirection.bottomRight,
      const Offset(500, 500),
      maxSize: const Size(300, 300), // looser global, per-node should win
    );
    final size = next.nodes['n']!.size;
    expect(size.width, lessThanOrEqualTo(120));
    expect(size.height, lessThanOrEqualTo(120));
  });

  test('no maxSize leaves the resize unbounded above the min', () {
    final next = service.resizeNode(
      seeded(),
      'n',
      ResizeDirection.bottomRight,
      const Offset(500, 500),
    );
    final size = next.nodes['n']!.size;
    expect(size.width, greaterThan(150));
    expect(size.height, greaterThan(150));
  });
}
