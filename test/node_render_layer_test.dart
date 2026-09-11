import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/nodes/domain/node_render_layer.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('built-in group resolves to background layer', () {
    final group = FlowNode<String>(
      type: 'group',
      id: 'g',
      position: Offset.zero,
      data: 'G',
    );
    expect(group.renderLayer, NodeRenderLayer.background);
  });

  test('built-in default resolves to middle layer', () {
    final node = FlowNode<String>(
      type: 'default',
      id: 'n',
      position: Offset.zero,
      data: 'N',
    );
    expect(node.renderLayer, NodeRenderLayer.middle);
  });

  test('data renderLayer override wins', () {
    final node = FlowNode.create(
      id: 'custom',
      type: 'custom',
      position: Offset.zero,
      size: const Size(10, 10),
      data: {'renderLayer': 'background'},
      handles: const {},
    );
    expect(node.renderLayer, NodeRenderLayer.background);
  });

  test('addNodes keeps child zIndex above parent', () {
    final service = NodeService();
    final state = service.addNodes(
      const FlowCanvasState(),
      [
        FlowNode<String>(
          type: 'group',
          id: 'g',
          position: Offset.zero,
          data: 'G',
          zIndex: 0,
        ),
        FlowNode<String>(
          type: 'input',
          id: 'c',
          parentId: 'g',
          position: const Offset(10, 10),
          data: 'C',
          zIndex: 0,
        ),
      ],
    );

    expect(state.nodes['c']!.zIndex, greaterThan(state.nodes['g']!.zIndex));
  });

  test('absolutePosition sums parent-relative offsets (Lattice)', () {
    final nodes = <String, FlowNode>{
      'g': FlowNode<String>(
        type: 'group',
        id: 'g',
        position: const Offset(100, 50),
        data: 'G',
      ),
      'c': FlowNode<String>(
        type: 'input',
        id: 'c',
        parentId: 'g',
        position: const Offset(20, 30),
        data: 'C',
      ),
    };
    expect(
      NodeLayout.absolutePosition('c', nodes),
      const Offset(120, 80),
    );
  });

  test('resize parent from top-left keeps child absolute (Lattice)', () {
    final service = NodeService();
    var state = service.addNodes(
      const FlowCanvasState(),
      [
        FlowNode<String>(
          type: 'group',
          id: 'g',
          position: const Offset(100, 100),
          size: const Size(300, 200),
          data: 'G',
        ),
        FlowNode<String>(
          type: 'input',
          id: 'c',
          parentId: 'g',
          position: const Offset(40, 50),
          data: 'C',
        ),
      ],
    );

    final absBefore = NodeLayout.absolutePosition('c', state.nodes); // 140, 150

    // Drag top-left handle down-right by 10 → origin moves +10,+10, size shrinks
    state = service.resizeNode(
      state,
      'g',
      ResizeDirection.topLeft,
      const Offset(10, 10),
    );

    expect(state.nodes['g']!.position, const Offset(110, 110));
    // Child relative compensated so absolute is unchanged.
    expect(state.nodes['c']!.position, const Offset(30, 40));
    expect(
      NodeLayout.absolutePosition('c', state.nodes),
      absBefore,
    );
  });

  test('resize parent cannot shrink past extent:parent children (Lattice)', () {
    final service = NodeService();
    var state = service.addNodes(
      const FlowCanvasState(),
      [
        FlowNode<String>(
          type: 'group',
          id: 'g',
          position: const Offset(0, 0),
          size: const Size(400, 300),
          data: 'G',
        ),
        FlowNode<String>(
          type: 'input',
          id: 'c',
          parentId: 'g',
          position: const Offset(50, 40),
          size: const Size(100, 40),
          data: 'C',
          extent: FlowNodeExtent.parent,
        ),
      ],
    );

    // Child occupies [50,40]→[150,80] in parent space.
    // Shrink from right by a huge amount — must stop at child right (150).
    state = service.resizeNode(
      state,
      'g',
      ResizeDirection.right,
      const Offset(-500, 0),
      minSize: const Size(10, 10),
    );

    expect(state.nodes['g']!.size.width, 150);
    expect(state.nodes['g']!.size.height, 300);

    // Shrink from bottom — stop at child bottom (80).
    state = service.resizeNode(
      state,
      'g',
      ResizeDirection.bottom,
      const Offset(0, -500),
      minSize: const Size(10, 10),
    );
    expect(state.nodes['g']!.size.height, 80);

    // Shrink from top-left — stop at child top-left absolute (50, 40).
    state = service.resizeNode(
      state,
      'g',
      ResizeDirection.topLeft,
      const Offset(200, 200),
      minSize: const Size(10, 10),
    );
    expect(state.nodes['g']!.position, const Offset(50, 40));
    expect(state.nodes['g']!.size, const Size(100, 40));
  });

  test('unbounded child does not floor parent resize', () {
    final service = NodeService();
    var state = service.addNodes(
      const FlowCanvasState(),
      [
        FlowNode<String>(
          type: 'group',
          id: 'g',
          position: Offset.zero,
          size: const Size(400, 300),
          data: 'G',
        ),
        FlowNode<String>(
          type: 'input',
          id: 'c',
          parentId: 'g',
          position: const Offset(50, 40),
          size: const Size(100, 40),
          data: 'C',
          // no extent
        ),
      ],
    );

    state = service.resizeNode(
      state,
      'g',
      ResizeDirection.right,
      const Offset(-350, 0),
      minSize: const Size(40, 40),
    );

    // Only minSize applies — can shrink under the unbounded child.
    expect(state.nodes['g']!.size.width, 50);
  });
}
