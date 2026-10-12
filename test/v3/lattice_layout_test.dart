import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

void main() {
  group('latticeAnchorTopLeft', () {
    test('top-left origin passes position through as-is', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(10, 20),
        size: Size(100, 50),
      );
      expect(
        latticeAnchorTopLeft(node, Offset.zero),
        equals(const Offset(10, 20)),
      );
    });

    test('center origin shifts by half size', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(10, 20),
        size: Size(100, 50),
      );
      expect(
        latticeAnchorTopLeft(node, const Offset(0.5, 0.5)),
        equals(const Offset(-40, -5)),
      );
    });

    test('per-node origin override wins over default', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(100, 100),
        origin: Offset(0.5, 0.5),
        size: Size(20, 20),
      );
      expect(
        latticeAnchorTopLeft(node, Offset.zero),
        equals(const Offset(90, 90)),
      );
    });
  });

  group('latticeAbsoluteTopLeft', () {
    test('nested child resolves through parent', () {
      const parent = LatticeNode(
        id: 'parent',
        type: 'default',
        position: Offset(100, 50),
      );
      const child = LatticeNode(
        id: 'child',
        type: 'default',
        position: Offset(10, 10),
        parentId: 'parent',
      );
      final nodes = <String, LatticeNode>{
        'parent': parent,
        'child': child,
      };
      expect(
        latticeAbsoluteTopLeft(nodes, 'child', defaultOrigin: Offset.zero),
        equals(const Offset(110, 60)),
      );
    });

    test('unknown id returns Offset.zero', () {
      expect(
        latticeAbsoluteTopLeft(
          const <String, LatticeNode>{},
          'ghost',
          defaultOrigin: Offset.zero,
        ),
        equals(Offset.zero),
      );
    });

    test('missing parent id stops gracefully', () {
      const orphan = LatticeNode(
        id: 'orphan',
        type: 'default',
        position: Offset(7, 8),
        parentId: 'ghost',
      );
      final nodes = <String, LatticeNode>{'orphan': orphan};
      expect(
        latticeAbsoluteTopLeft(nodes, 'orphan', defaultOrigin: Offset.zero),
        equals(const Offset(7, 8)),
      );
    });

    test('parent cycle terminates with a finite offset', () {
      const a = LatticeNode(
        id: 'a',
        type: 'default',
        position: Offset(10, 10),
        parentId: 'b',
      );
      const b = LatticeNode(
        id: 'b',
        type: 'default',
        position: Offset(5, 5),
        parentId: 'a',
      );
      final nodes = <String, LatticeNode>{'a': a, 'b': b};
      final result = latticeAbsoluteTopLeft(
        nodes,
        'a',
        defaultOrigin: Offset.zero,
      );
      expect(result.dx.isFinite, isTrue);
      expect(result.dy.isFinite, isTrue);
    });
  });

  group('latticeAbsoluteRect', () {
    test('returns topLeft & size', () {
      const parent = LatticeNode(
        id: 'parent',
        type: 'default',
        position: Offset(100, 50),
      );
      const child = LatticeNode(
        id: 'child',
        type: 'default',
        position: Offset(10, 10),
        size: Size(20, 30),
        parentId: 'parent',
      );
      final nodes = <String, LatticeNode>{
        'parent': parent,
        'child': child,
      };
      expect(
        latticeAbsoluteRect(nodes, 'child', defaultOrigin: Offset.zero),
        equals(const Offset(110, 60) & const Size(20, 30)),
      );
    });
  });

  group('latticeOverlapsRect', () {
    test('true when absolute rect overlaps', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
        size: Size(10, 10),
      );
      final nodes = <String, LatticeNode>{'n1': node};
      expect(
        latticeOverlapsRect(
          nodes,
          node,
          const Rect.fromLTWH(5, 5, 15, 15),
          defaultOrigin: Offset.zero,
        ),
        isTrue,
      );
    });

    test('false when absolute rect is disjoint', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
        size: Size(10, 10),
      );
      final nodes = <String, LatticeNode>{'n1': node};
      expect(
        latticeOverlapsRect(
          nodes,
          node,
          const Rect.fromLTWH(50, 50, 10, 10),
          defaultOrigin: Offset.zero,
        ),
        isFalse,
      );
    });
  });
}
