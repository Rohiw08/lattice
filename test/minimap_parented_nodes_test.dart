// ignore_for_file: prefer_const_constructors

import 'dart:ui';

import 'package:lattice/src/features/minimap/presentation/painters/minimap_painter.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MiniMapPainter.getCombinedBounds with parented nodes', () {
    final parent = FlowNode(
      id: 'parent',
      type: 'group',
      position: const Offset(100, 100),
      size: const Size(300, 300),
    );
    final child = FlowNode(
      id: 'child',
      type: 'default',
      position: const Offset(10, 10),
      size: const Size(50, 50),
      parentId: 'parent',
    );

    test('covers the child at its absolute position, not its local one', () {
      final bounds = MiniMapPainter.getCombinedBounds([parent, child], Rect.zero);

      expect(bounds.contains(const Offset(110, 110)), isTrue,
          reason: 'child absolute top-left (parent.pos + child.pos)');
      expect(bounds.contains(const Offset(10, 10)), isFalse,
          reason: 'child local position is not inside the graph bounds');
    });

    test('follows the parent when it is dragged (live position)', () {
      final bounds = MiniMapPainter.getCombinedBounds(
        [parent, child],
        Rect.zero,
        livePositions: {
          'parent': const Offset(200, 200),
        },
      );

      expect(bounds.contains(const Offset(210, 210)), isTrue,
          reason: 'child absolute top-left moves with the dragged parent');
      expect(bounds.contains(const Offset(110, 110)), isFalse,
          reason: 'stale absolute position is no longer covered');
    });

    test('deeply nested children resolve through every ancestor', () {
      final grandchild = FlowNode(
        id: 'grandchild',
        type: 'default',
        position: const Offset(5, 5),
        size: const Size(20, 20),
        parentId: 'child',
      );

      final bounds = MiniMapPainter.getCombinedBounds(
        [parent, child, grandchild],
        Rect.zero,
        livePositions: {
          'child': const Offset(20, 20),
        },
      );

      expect(bounds.contains(const Offset(100 + 20 + 5, 100 + 20 + 5)), isTrue,
          reason: 'grandchild absolute = parent.pos + child live pos + local');
    });
  });
}
