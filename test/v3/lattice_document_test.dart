import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

void main() {
  group('LatticeViewportValue', () {
    test('defaults are zero offset and zoom 1', () {
      const viewport = LatticeViewportValue();
      expect(viewport.offset, equals(Offset.zero));
      expect(viewport.zoom, equals(1.0));
    });

    test('const construction and ==', () {
      const a = LatticeViewportValue(offset: Offset(3, 4), zoom: 2.0);
      const b = LatticeViewportValue(offset: Offset(3, 4), zoom: 2.0);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(const LatticeViewportValue())));
    });

    test('copyWith changes one field', () {
      const a = LatticeViewportValue(offset: Offset(3, 4), zoom: 2.0);
      final b = a.copyWith(zoom: 3.0);
      expect(b.offset, equals(const Offset(3, 4)));
      expect(b.zoom, equals(3.0));
    });

    test('toJson/fromJson round-trip', () {
      const a = LatticeViewportValue(offset: Offset(3, 4), zoom: 2.0);
      expect(LatticeViewportValue.fromJson(a.toJson()), equals(a));
    });

    test('matrix round-trip fromMatrix(toMatrix()) == value', () {
      const values = <LatticeViewportValue>[
        LatticeViewportValue(),
        LatticeViewportValue(offset: Offset(10, -20), zoom: 1.0),
        LatticeViewportValue(offset: Offset(30, 40), zoom: 2.5),
        LatticeViewportValue(offset: Offset(-7, 9), zoom: 0.5),
      ];
      for (final value in values) {
        expect(LatticeViewportValue.fromMatrix(value.toMatrix()), equals(value));
      }
    });

    test('toMatrix maps flow point to offset + zoom * flow', () {
      const value = LatticeViewportValue(offset: Offset(30, 40), zoom: 2.5);
      final Matrix4 matrix = value.toMatrix();
      const flow = Offset(4, 6);
      // Matrix4 storage is column-major: storage[0] is m00 (scale-x),
      // storage[5] is m11 (scale-y), storage[12]/[13] hold translation.
      final Offset mapped = Offset(
        matrix.storage[0] * flow.dx + matrix.storage[12],
        matrix.storage[5] * flow.dy + matrix.storage[13],
      );
      expect(mapped.dx, equals(value.offset.dx + value.zoom * flow.dx));
      expect(mapped.dy, equals(value.offset.dy + value.zoom * flow.dy));
    });
  });

  group('LatticeDocument', () {
    test('empty() has empty maps and default viewport', () {
      final doc = LatticeDocument.empty();
      expect(doc.nodes, isEmpty);
      expect(doc.edges, isEmpty);
      expect(doc.viewport, equals(const LatticeViewportValue()));
    });

    test('withNode adds and withoutNodes removes', () {
      LatticeDocument doc = LatticeDocument.empty();
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(1, 2),
      );
      doc = doc.withNode(node);
      expect(doc.nodes['n1'], equals(node));

      const node2 = LatticeNode(
        id: 'n2',
        type: 'default',
        position: Offset(3, 4),
      );
      doc = doc.withNode(node2);
      expect(doc.nodes.length, equals(2));

      doc = doc.withoutNodes(const {'n1'});
      expect(doc.nodes.containsKey('n1'), isFalse);
      expect(doc.nodes.containsKey('n2'), isTrue);
    });

    test('withEdge adds and withoutEdges removes', () {
      LatticeDocument doc = LatticeDocument.empty();
      const edge = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1'),
        target: LatticeEndpoint(nodeId: 'n2'),
      );
      doc = doc.withEdge(edge);
      expect(doc.edges['e1'], equals(edge));

      doc = doc.withoutEdges(const {'e1'});
      expect(doc.edges, isEmpty);
    });

    test('withViewport replaces the viewport', () {
      const doc = LatticeDocument();
      const viewport = LatticeViewportValue(offset: Offset(5, 6), zoom: 2.0);
      final next = doc.withViewport(viewport);
      expect(next.viewport, equals(viewport));
      expect(doc.viewport, equals(const LatticeViewportValue()));
    });

    test('copyWith() with no args reuses identical map instances', () {
      const doc = LatticeDocument(
        nodes: <String, LatticeNode>{
          'n1': LatticeNode(
            id: 'n1',
            type: 'default',
            position: Offset(0, 0),
          ),
        },
        edges: <String, LatticeEdge>{
          'e1': LatticeEdge(
            id: 'e1',
            source: LatticeEndpoint(nodeId: 'n1'),
            target: LatticeEndpoint(nodeId: 'n1'),
          ),
        },
      );
      final copy = doc.copyWith();
      expect(identical(doc.nodes, copy.nodes), isTrue);
      expect(identical(doc.edges, copy.edges), isTrue);
      expect(copy.viewport, equals(doc.viewport));
    });

    test('toJson/fromJson round-trip incl. viewport', () {
      const doc = LatticeDocument(
        nodes: <String, LatticeNode>{
          'n1': LatticeNode(
            id: 'n1',
            type: 'default',
            position: Offset(7, 8),
            data: 'hello',
          ),
          'n2': LatticeNode(
            id: 'n2',
            type: 'input',
            position: Offset(1, 2),
          ),
        },
        edges: <String, LatticeEdge>{
          'e1': LatticeEdge(
            id: 'e1',
            source: LatticeEndpoint(nodeId: 'n1'),
            target: LatticeEndpoint(nodeId: 'n2'),
          ),
        },
        viewport: LatticeViewportValue(offset: Offset(30, 40), zoom: 2.5),
      );
      final back = LatticeDocument.fromJson(doc.toJson());
      expect(back, equals(doc));
    });

    test('fromJson duplicate node ids keeps last', () {
      final json = <String, Object?>{
        'nodes': <Object?>[
          const LatticeNode(
            id: 'dup',
            type: 'default',
            position: Offset(1, 1),
          ).toJson(),
          const LatticeNode(
            id: 'dup',
            type: 'default',
            position: Offset(2, 2),
          ).toJson(),
        ],
        'edges': <Object?>[],
        'viewport': const LatticeViewportValue().toJson(),
      };
      final doc = LatticeDocument.fromJson(json);
      expect(doc.nodes.length, equals(1));
      expect(doc.nodes['dup']!.position, equals(const Offset(2, 2)));
    });

    test('NaN/Infinity doubles decode to 0.0', () {
      final json = <String, Object?>{
        'nodes': <Object?>[
          <String, Object?>{
            'id': 'n1',
            'type': 'default',
            'position': <String, Object?>{
              'dx': double.nan,
              'dy': double.infinity,
            },
            'size': <String, Object?>{
              'width': double.negativeInfinity,
              'height': 44.0,
            },
          },
        ],
        'edges': <Object?>[],
        'viewport': <String, Object?>{
          'offset': <String, Object?>{
            'dx': double.nan,
            'dy': double.negativeInfinity,
          },
          'zoom': double.infinity,
        },
      };
      final doc = LatticeDocument.fromJson(json);
      expect(
        doc.nodes['n1']!.position,
        equals(const Offset(0.0, 0.0)),
      );
      expect(doc.nodes['n1']!.size.width, equals(0.0));
      expect(doc.viewport.offset, equals(const Offset(0.0, 0.0)));
      expect(doc.viewport.zoom, equals(0.0));
    });

    test('2500-node copyWith() with no args reuses identical map instances',
        () {
      final Map<String, LatticeNode> nodes = <String, LatticeNode>{
        for (int i = 0; i < 2500; i++)
          'n$i': LatticeNode(
            id: 'n$i',
            type: 'default',
            position: Offset(i.toDouble(), i.toDouble()),
          ),
      };
      final doc = LatticeDocument(nodes: nodes);
      final copy = doc.copyWith();
      expect(identical(doc.nodes, copy.nodes), isTrue);
      expect(identical(doc.edges, copy.edges), isTrue);
    });
  });
}
