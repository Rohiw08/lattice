// ignore_for_file: prefer_const_constructors

import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('updateNode z-normalization (Lattice child-above-parent rule)', () {
    late FlowCanvasState base;

    setUp(() {
      base = const FlowCanvasState().copyWith(
        nodes: {
          'a': FlowNode<String>(
            type: 'default',
            id: 'a',
            position: Offset.zero,
            size: const Size(100, 40),
            data: 'A',
            zIndex: 3,
          ),
          'b': FlowNode<String>(
            type: 'default',
            id: 'b',
            position: const Offset(200, 0),
            size: const Size(100, 40),
            data: 'B',
            zIndex: 1,
          ),
          'c': FlowNode<String>(
            type: 'default',
            id: 'c',
            position: const Offset(200, 100),
            size: const Size(100, 40),
            data: 'C',
            zIndex: 0,
          ),
        },
        maxZIndex: 3,
        minZIndex: 0,
      );
    });

    test('child reparented below its parent is bumped above it', () {
      final next = NodeService().updateNode(
        base,
        base.nodes['b']!.copyWith(parentId: 'a', zIndex: 2),
      );
      expect(next.nodes['b']!.zIndex, 4,
          reason: 'z becomes max(parentZ + 1, requested z)');
      expect(next.maxZIndex, 4, reason: 'maxZIndex recomputed');
      expect(next.minZIndex, 0);
    });

    test('existing below-parent child normalizes on update', () {
      final withViolation = base.copyWith(
        nodes: {
          ...base.nodes,
          'c': base.nodes['c']!.copyWith(parentId: 'a', zIndex: 2),
        },
      );
      final next = NodeService().updateNode(
        withViolation,
        withViolation.nodes['c']!,
      );
      expect(next.nodes['c']!.zIndex, 4, reason: 'child must sit above parent');
    });

    test('grandchildren are normalized relative to their parent', () {
      final withGrandchild = base.copyWith(
        nodes: {
          ...base.nodes,
          'd': FlowNode<String>(
            type: 'default',
            id: 'd',
            parentId: 'b',
            position: const Offset(220, 20),
            size: const Size(100, 40),
            data: 'D',
            zIndex: 1,
          ),
        },
      );
      final next = NodeService().updateNode(
        withGrandchild,
        withGrandchild.nodes['b']!.copyWith(parentId: 'a', zIndex: 2),
      );
      // b -> 4; d must rise above its parent b.
      expect(next.nodes['b']!.zIndex, 4);
      expect(next.nodes['d']!.zIndex, 5,
          reason: 'descendants stay above their reparented ancestor');
    });

    test('detaching a node keeps its z untouched', () {
      final next = NodeService().updateNode(
        base,
        base.nodes['b']!.copyWith(parentId: null),
      );
      expect(next.nodes['b']!.zIndex, 1);
      expect(next.maxZIndex, 3);
    });
  });
}