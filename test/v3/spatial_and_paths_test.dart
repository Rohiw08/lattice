import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, Offset position) {
  return LatticeNode(
    id: id,
    type: 'custom',
    position: position,
    size: const Size(100, 100),
  );
}

void main() {
  group('LatticeSpatialIndex', () {
    test('query returns overlapping ids only', () {
      final index = LatticeSpatialIndex();
      index.rebuild(<String, LatticeNode>{
        'n1': _node('n1', const Offset(0, 0)),
        'n2': _node('n2', const Offset(500, 500)),
        'n3': _node('n3', const Offset(1000, 0)),
      }, defaultOrigin: Offset.zero);

      expect(
        index.queryNodes(const Rect.fromLTWH(10, 10, 50, 50)),
        equals(<String>{'n1'}),
      );
    });

    test('moveNode updates query results', () {
      final before = _node('n1', const Offset(0, 0));
      final index = LatticeSpatialIndex();
      index.rebuild(<String, LatticeNode>{
        'n1': before,
        'n2': _node('n2', const Offset(500, 500)),
      }, defaultOrigin: Offset.zero);

      const oldRect = Rect.fromLTWH(10, 10, 50, 50);
      expect(index.queryNodes(oldRect), equals(<String>{'n1'}));

      final after = LatticeNode(
        id: 'n1',
        type: 'custom',
        position: const Offset(2000, 2000),
        size: const Size(100, 100),
      );
      index.moveNode(before, after);

      expect(index.queryNodes(oldRect), isEmpty);
      expect(
        index.queryNodes(const Rect.fromLTWH(2010, 2010, 50, 50)),
        equals(<String>{'n1'}),
      );
    });

    test('removeNodes drops ids from query results', () {
      final index = LatticeSpatialIndex();
      index.rebuild(<String, LatticeNode>{
        'n1': _node('n1', const Offset(0, 0)),
        'n2': _node('n2', const Offset(500, 500)),
      }, defaultOrigin: Offset.zero);

      index.removeNodes(<String>{'n1'});

      expect(
        index.queryNodes(const Rect.fromLTWH(10, 10, 50, 50)),
        isEmpty,
      );
      expect(
        index.queryNodes(const Rect.fromLTWH(510, 510, 50, 50)),
        equals(<String>{'n2'}),
      );
    });

    test('rebuild honors defaultOrigin', () {
      final index = LatticeSpatialIndex();
      index.rebuild(<String, LatticeNode>{
        'n1': _node('n1', const Offset(100, 100)),
      }, defaultOrigin: const Offset(0.5, 0.5));

      // Absolute rect is (50,50,100,100) with a center origin.
      expect(
        index.queryNodes(const Rect.fromLTWH(0, 0, 60, 60)),
        equals(<String>{'n1'}),
      );
    });
  });

  group('latticeEdgePath', () {
    test('bezier starts at source anchor and ends at target anchor', () {
      const source = Offset(0, 0);
      const target = Offset(200, 100);
      final path = latticeEdgePath(
        sourceRect: const Offset(0, 0) & const Size(100, 50),
        sourceAnchor: source,
        targetRect: const Offset(200, 100) & const Size(100, 50),
        targetAnchor: target,
      );

      final metrics = path.computeMetrics().toList();
      expect(metrics, hasLength(1));
      final metric = metrics.single;
      expect(metric.length, greaterThan(0));
      expect(
        metric.getTangentForOffset(0)!.position,
        offsetMoreOrLessEquals(source),
      );
      expect(
        metric.getTangentForOffset(metric.length)!.position,
        offsetMoreOrLessEquals(target),
      );
      // Rect.contains excludes the right/bottom edges, so inflate slightly
      // before asserting both anchors are covered.
      final Rect bounds = path.getBounds().inflate(0.5);
      expect(bounds.contains(source), isTrue);
      expect(bounds.contains(target), isTrue);
    });

    test('straight bounds equal the anchor segment bounds', () {
      const source = Offset(10, 20);
      const target = Offset(200, 100);
      final path = latticeEdgePath(
        sourceRect: const Offset(0, 0) & const Size(100, 50),
        sourceAnchor: source,
        targetRect: const Offset(200, 100) & const Size(100, 50),
        targetAnchor: target,
        type: 'straight',
      );

      expect(path.getBounds(), equals(Rect.fromPoints(source, target)));
    });

    test('unknown type falls back to bezier', () {
      const source = Offset(0, 0);
      const target = Offset(200, 100);
      Offset bezierLength(String type) {
        final path = latticeEdgePath(
          sourceRect: const Offset(0, 0) & const Size(100, 50),
          sourceAnchor: source,
          targetRect: const Offset(200, 100) & const Size(100, 50),
          targetAnchor: target,
          type: type,
        );
        return Offset(path.computeMetrics().single.length, 0);
      }

      expect(bezierLength('nope').dx, bezierLength('bezier').dx);
    });
  });

  group('EdgePathCache', () {
    LatticeDocument buildDoc() {
      return LatticeDocument(
        nodes: <String, LatticeNode>{
          'a': _node('a', const Offset(0, 0)),
          'b': _node('b', const Offset(300, 0)),
          'c': _node('c', const Offset(600, 0)),
        },
        edges: <String, LatticeEdge>{
          'e1': const LatticeEdge(
            id: 'e1',
            source: LatticeEndpoint(nodeId: 'a'),
            target: LatticeEndpoint(nodeId: 'b'),
          ),
          'e2': const LatticeEdge(
            id: 'e2',
            source: LatticeEndpoint(nodeId: 'b'),
            target: LatticeEndpoint(nodeId: 'c'),
          ),
          'e3': const LatticeEdge(
            id: 'e3',
            source: LatticeEndpoint(nodeId: 'a'),
            target: LatticeEndpoint(nodeId: 'c'),
          ),
        },
      );
    }

    test('syncTo computes paths with default center ports', () {
      final cache = EdgePathCache();
      cache.syncTo(buildDoc(), defaultOrigin: Offset.zero);

      expect(cache.recomputeCount, equals(3));
      final path = cache.pathFor('e1')!;
      final metrics = path.computeMetrics().toList();
      expect(metrics, hasLength(1));
      final metric = metrics.single;
      // a: rect (0,0,100,100) center-right = (100,50);
      // b: rect (300,0,100,100) center-left = (300,50).
      expect(
        metric.getTangentForOffset(0)!.position,
        offsetMoreOrLessEquals(const Offset(100, 50)),
      );
      expect(
        metric.getTangentForOffset(metric.length)!.position,
        offsetMoreOrLessEquals(const Offset(300, 50)),
      );
      expect(cache.boundsFor('e1'), equals(path.getBounds()));
    });

    test('syncTo resolves handle anchors when handleIds resolve', () {
      const a = LatticeNode(
        id: 'a',
        type: 'default',
        position: Offset(0, 0),
      );
      const b = LatticeNode(
        id: 'b',
        type: 'default',
        position: Offset(300, 0),
      );
      final doc = LatticeDocument(
        nodes: const <String, LatticeNode>{'a': a, 'b': b},
        edges: const <String, LatticeEdge>{
          'e1': LatticeEdge(
            id: 'e1',
            source: LatticeEndpoint(nodeId: 'a', handleId: 'source'),
            target: LatticeEndpoint(nodeId: 'b', handleId: 'target'),
          ),
        },
      );
      final cache = EdgePathCache();
      cache.syncTo(doc, defaultOrigin: Offset.zero);

      final metric = cache.pathFor('e1')!.computeMetrics().single;
      // Default node size (160,44): source handle at (80-3,44-3)=(77,41);
      // target handle at (80-3,-3)=(77,-3) offset by b position.
      expect(
        metric.getTangentForOffset(0)!.position,
        offsetMoreOrLessEquals(const Offset(77, 41)),
      );
      expect(
        metric.getTangentForOffset(metric.length)!.position,
        offsetMoreOrLessEquals(const Offset(377, -3)),
      );
    });

    test('moving one node recomputes only connected edges', () {
      final cache = EdgePathCache();
      final doc = buildDoc();
      cache.syncTo(doc, defaultOrigin: Offset.zero);
      expect(cache.recomputeCount, equals(3));

      // Move c: only e2 (b->c) and e3 (a->c) change anchors.
      final moved = doc.withNode(_node('c', const Offset(600, 500)));
      cache.syncTo(moved, defaultOrigin: Offset.zero);

      expect(cache.recomputeCount, equals(5));
    });

    test('syncTo with no changes recomputes nothing', () {
      final cache = EdgePathCache();
      final doc = buildDoc();
      cache.syncTo(doc, defaultOrigin: Offset.zero);
      cache.syncTo(doc, defaultOrigin: Offset.zero);

      expect(cache.recomputeCount, equals(3));
    });

    test('invalidateEdges forces recompute on next syncTo', () {
      final cache = EdgePathCache();
      final doc = buildDoc();
      cache.syncTo(doc, defaultOrigin: Offset.zero);

      cache.invalidateEdges(<String>{'e1'});
      cache.syncTo(doc, defaultOrigin: Offset.zero);

      expect(cache.recomputeCount, equals(4));
    });

    test('removed edge drops path', () {
      final cache = EdgePathCache();
      final doc = buildDoc();
      cache.syncTo(doc, defaultOrigin: Offset.zero);
      expect(cache.pathFor('e3'), isNotNull);

      cache.syncTo(doc.withoutEdges(<String>{'e3'}),
          defaultOrigin: Offset.zero);

      expect(cache.pathFor('e3'), isNull);
      expect(cache.boundsFor('e3'), isNull);
    });
  });
}
