// ignore_for_file: prefer_const_constructors

import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FlowCanvasState base;

  setUp(() {
    base = NodeService().addNodes(const FlowCanvasState(), [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(60, 40),
        size: const Size(360, 260),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'input',
        id: 'node_in',
        parentId: 'group_1',
        position: const Offset(30, 60),
        size: const Size(160, 44),
        data: 'Input',
        extent: FlowNodeExtent.parent,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(180, 50),
        size: const Size(160, 44),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
    ]);
  });

  group('removeNodes cascade (Lattice deleteElements parentHit)', () {
    test('removing a parent removes its descendants too', () {
      final next = NodeService().removeNodes(base, ['group_1']);
      expect(next.nodes.keys, isNot(contains('group_1')));
      expect(next.nodes.keys, isNot(contains('node_in')));
      expect(next.nodes.keys, isNot(contains('node_a')));
    });

    test('removing a child keeps the parent', () {
      final next = NodeService().removeNodes(base, ['node_a']);
      expect(next.nodes.keys, contains('group_1'));
      expect(next.nodes.keys, contains('node_in'));
      expect(next.nodes.keys, isNot(contains('node_a')));
    });

    test('cascade removes deeply nested descendants', () {
      final withGrandchild = NodeService().addNodes(base, [
        FlowNode<String>(
          type: 'default',
          id: 'node_b',
          parentId: 'node_a',
          position: const Offset(10, 10),
          size: const Size(100, 40),
          data: 'B',
          extent: FlowNodeExtent.parent,
        ),
      ]);
      final next = NodeService().removeNodes(withGrandchild, ['group_1']);
      expect(next.nodes.keys, isNot(contains('node_a')));
      expect(next.nodes.keys, isNot(contains('node_b')));
    });

    test('deletable:false nodes survive explicit removal', () {
      final withProtected = NodeService().addNodes(base, [
        FlowNode<String>(
          type: 'default',
          id: 'node_b',
          parentId: 'group_1',
          position: const Offset(20, 20),
          size: const Size(100, 40),
          data: 'B',
          deletable: false,
        ),
      ]);
      final next = NodeService().removeNodes(withProtected, ['node_b']);
      expect(next.nodes.keys, contains('node_b'));
      expect(next.nodes.keys, contains('group_1'));
    });

    test('deletable:false descendants survive a parent cascade (Lattice)', () {
      final withProtected = NodeService().addNodes(base, [
        FlowNode<String>(
          type: 'default',
          id: 'node_b',
          parentId: 'node_a',
          position: const Offset(10, 10),
          size: const Size(100, 40),
          data: 'B',
          deletable: false,
        ),
      ]);
      final next = NodeService().removeNodes(withProtected, ['group_1']);
      expect(next.nodes.keys, isNot(contains('group_1')));
      expect(next.nodes.keys, isNot(contains('node_a')));
      expect(next.nodes.keys, contains('node_b'),
          reason: 'parent cascade must not remove deletable:false nodes');
    });

    test('selectedNodes cleans up removed ids', () {
      final selected = base.copyWith(selectedNodes: {'group_1', 'node_a'});
      final next = NodeService().removeNodes(selected, ['group_1']);
      expect(next.selectedNodes, isEmpty);
    });

    test('empty request is a no-op', () {
      expect(identical(NodeService().removeNodes(base, []), base), isTrue);
    });
  });
}