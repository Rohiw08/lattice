// ignore_for_file: prefer_const_constructors

import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlowNode<String> _node(
  String id,
  Offset position, {
  String? parentId,
  bool expandParent = false,
}) {
  return FlowNode<String>(
    type: 'default',
    id: id,
    parentId: parentId,
    position: position,
    size: const Size(100, 40),
    data: id,
    expandParent: expandParent,
  );
}

void main() {
  group('clipboard paste parent remapping (Lattice copy/paste)', () {
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
        _node('node_in', const Offset(30, 60), parentId: 'group_1'),
        _node('node_a', const Offset(180, 50), parentId: 'group_1'),
      ]);
    });

    test('pasted child points at the pasted parent (parent copied together)',
        () {
      final state =
          base.copyWith(selectedNodes: {'group_1', 'node_in', 'node_a'});
      final payload = ClipboardService().copy(state);
      final pasted = ClipboardService().paste(
        state,
        payload,
        nodeService: NodeService(),
        edgeService: EdgeService(),
      );

      expect(pasted.nodes.length, 6);
      final originals = {'group_1', 'node_in', 'node_a'};
      final newNodes =
          pasted.nodes.values.where((n) => !originals.contains(n.id)).toList();

      final newChild =
          newNodes.firstWhere((n) => n.data == 'node_in' && n.id != 'node_in');
      final newParent = newNodes.firstWhere((n) => n.data == 'Group');
      expect(newChild.parentId, newParent.id,
          reason: 'parentId remaps to the copied parent');
      expect(newParent.parentId, isNull);
      expect(newParent.position, const Offset(100, 80),
          reason: 'positions offset on paste (Lattice example behavior)');
      expect(newChild.position, const Offset(70, 100));

      // Original nodes untouched.
      expect(pasted.nodes['node_in']!.parentId, 'group_1');
    });

    test('pasted child detaches when its parent was not copied', () {
      final state = base.copyWith(selectedNodes: {'node_in'});
      final payload = ClipboardService().copy(state);
      final pasted = ClipboardService().paste(
        state,
        payload,
        nodeService: NodeService(),
        edgeService: EdgeService(),
      );

      expect(pasted.nodes.length, 4);
      final newChild = pasted.nodes.values
          .firstWhere((n) => n.id != 'node_in' && n.data == 'node_in');
      expect(newChild.parentId, isNull,
          reason: 'child pasted without its parent becomes a root node');
    });

    test('deep nesting: grandchild remaps to the pasted child', () {
      final withGrandchild = NodeService().addNodes(base, [
        _node('node_b', const Offset(10, 10), parentId: 'node_in'),
      ]);
      final state = withGrandchild
          .copyWith(selectedNodes: {'group_1', 'node_in', 'node_b'});
      final payload = ClipboardService().copy(state);
      final pasted = ClipboardService().paste(
        state,
        payload,
        nodeService: NodeService(),
        edgeService: EdgeService(),
      );

      final originals = {'group_1', 'node_in', 'node_b'};
      final newNodes = pasted.nodes.values
          .where((n) => !originals.contains(n.id))
          .toList();
      final newChild =
          newNodes.firstWhere((n) => n.data == 'node_in' && n.id != 'node_in');
      final newGrandchild =
          newNodes.firstWhere((n) => n.data == 'node_b' && n.id != 'node_b');
      expect(newGrandchild.parentId, newChild.id);
    });

    test('edges are remapped when both endpoints are copied', () {
      final withEdge = base.copyWith(
        edges: {
          'e1': const FlowEdge(
            id: 'e1',
            sourceNodeId: 'node_in',
            targetNodeId: 'node_a',
            type: EdgePathType.bezier,
          ),
        },
      );
      final state = withEdge
          .copyWith(selectedNodes: {'node_in', 'node_a'});
      final payload = ClipboardService().copy(state);
      final pasted = ClipboardService().paste(
        state,
        payload,
        nodeService: NodeService(),
        edgeService: EdgeService(),
      );

      expect(pasted.edges.length, 2);
      final newEdge = pasted.edges.values
          .firstWhere((e) => e.id != 'e1');
      final newChild = pasted.nodes.values
          .firstWhere((n) => n.id != 'node_in' && n.data == 'node_in');
      final newSibling = pasted.nodes.values
          .firstWhere((n) => n.id != 'node_a' && n.data == 'node_a');
      expect(newEdge.sourceNodeId, newChild.id);
      expect(newEdge.targetNodeId, newSibling.id);
      expect(pasted.edges['e1']!.sourceNodeId, 'node_in',
          reason: 'original edge untouched');
    });
  });
}