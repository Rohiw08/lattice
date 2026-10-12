import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

void main() {
  group('LatticeHandle', () {
    test('const construction and ==', () {
      const a = LatticeHandle(
        id: 'h1',
        type: LatticeHandleType.source,
        position: Offset(10, 20),
      );
      const b = LatticeHandle(
        id: 'h1',
        type: LatticeHandleType.source,
        position: Offset(10, 20),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.size, equals(const Size(6, 6)));

      const different = LatticeHandle(
        id: 'h1',
        type: LatticeHandleType.target,
        position: Offset(10, 20),
      );
      expect(a, isNot(equals(different)));
    });

    test('copyWith changes one field', () {
      const a = LatticeHandle(
        id: 'h1',
        type: LatticeHandleType.source,
        position: Offset(10, 20),
      );
      final b = a.copyWith(position: const Offset(1, 2));
      expect(b.id, equals('h1'));
      expect(b.type, equals(LatticeHandleType.source));
      expect(b.position, equals(const Offset(1, 2)));
      expect(b.size, equals(const Size(6, 6)));
    });

    test('toJson/fromJson round-trip', () {
      const a = LatticeHandle(
        id: 'h1',
        type: LatticeHandleType.target,
        position: Offset(3, 4),
        size: Size(8, 8),
      );
      final json = a.toJson();
      final back = LatticeHandle.fromJson(json);
      expect(back, equals(a));
    });
  });

  group('LatticeEndpoint', () {
    test('const construction and ==', () {
      const a = LatticeEndpoint(nodeId: 'n1', handleId: 'h1');
      const b = LatticeEndpoint(nodeId: 'n1', handleId: 'h1');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      const noHandle = LatticeEndpoint(nodeId: 'n1');
      expect(noHandle.handleId, isNull);
      expect(a, isNot(equals(noHandle)));
    });

    test('toJson/fromJson round-trip', () {
      const a = LatticeEndpoint(nodeId: 'n1', handleId: 'h1');
      expect(LatticeEndpoint.fromJson(a.toJson()), equals(a));

      const b = LatticeEndpoint(nodeId: 'n1');
      expect(LatticeEndpoint.fromJson(b.toJson()), equals(b));
    });
  });

  group('LatticeNode', () {
    test('const construction and ==', () {
      const a = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
      );
      const b = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.size, equals(const Size(160, 44)));
      expect(a.zIndex, equals(0));
    });

    test('copyWith changes one field', () {
      const a = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
      );
      final b = a.copyWith(position: const Offset(5, 6));
      expect(b.id, equals('n1'));
      expect(b.position, equals(const Offset(5, 6)));
      expect(b.type, equals('default'));
    });

    test('resolveHandles for default yields source + target', () {
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
      );
      final handles = node.resolveHandles();
      expect(handles.keys, containsAll(<String>['source', 'target']));
      expect(handles['source']!.type, equals(LatticeHandleType.source));
      expect(handles['target']!.type, equals(LatticeHandleType.target));
      expect(handles['source']!.size, equals(const Size(6, 6)));
      expect(handles['target']!.size, equals(const Size(6, 6)));
    });

    test('resolveHandles returns explicit handles when provided', () {
      const explicit = LatticeHandle(
        id: 'custom',
        type: LatticeHandleType.source,
        position: Offset(1, 1),
      );
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(0, 0),
        handles: <String, LatticeHandle>{'custom': explicit},
      );
      final handles = node.resolveHandles();
      expect(handles.length, equals(1));
      expect(handles['custom'], equals(explicit));
    });

    test('round-trip toJson/fromJson with data passthrough when codecs null',
        () {
      const data = <String, Object?>{'label': 'hello', 'count': 3};
      const node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: Offset(7, 8),
        data: data,
      );
      final json = node.toJson();
      final back = LatticeNode.fromJson(json);
      expect(back.id, equals('n1'));
      expect(back.data, equals(data));
    });

    test('custom codecs called with (type, data)', () {
      String? seenEncodeType;
      Object? seenEncodeData;
      Object? seenDecodeJson;
      String? seenDecodeType;

      Object? encode(String type, Object? data) {
        seenEncodeType = type;
        seenEncodeData = data;
        return <String, Object?>{'wrapped': data};
      }

      Object? decode(String type, Object? json) {
        seenDecodeType = type;
        seenDecodeJson = json;
        return (json as Map<String, Object?>)['wrapped'];
      }

      const node = LatticeNode(
        id: 'n1',
        type: 'custom',
        position: Offset(0, 0),
        data: 42,
      );
      final json = node.toJson(encode);
      expect(seenEncodeType, equals('custom'));
      expect(seenEncodeData, equals(42));

      final back = LatticeNode.fromJson(json, decode);
      expect(seenDecodeType, equals('custom'));
      expect(seenDecodeJson, equals(<String, Object?>{'wrapped': 42}));
      expect(back.data, equals(42));
    });

    test('non-JSON-safe data round-trips by reference with null codecs', () {
      final data = _NonJsonSafe('payload');
      final node = LatticeNode(
        id: 'n1',
        type: 'default',
        position: const Offset(0, 0),
        data: data,
      );
      // Must not throw even though data is not JSON-encodable.
      final json = node.toJson();
      final back = LatticeNode.fromJson(json);
      expect(identical(back.data, data), isTrue);
    });
  });

  group('LatticeEdge', () {
    test('const construction and ==', () {
      const a = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1'),
        target: LatticeEndpoint(nodeId: 'n2'),
      );
      const b = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1'),
        target: LatticeEndpoint(nodeId: 'n2'),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.type, equals('default'));
    });

    test('copyWith changes one field', () {
      const a = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1'),
        target: LatticeEndpoint(nodeId: 'n2'),
      );
      final b = a.copyWith(label: 'hello');
      expect(b.id, equals('e1'));
      expect(b.label, equals('hello'));
      expect(b.source, equals(a.source));
    });

    test('toJson/fromJson round-trip', () {
      const a = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1', handleId: 'source'),
        target: LatticeEndpoint(nodeId: 'n2', handleId: 'target'),
        label: 'edge',
        animated: true,
      );
      final back = LatticeEdge.fromJson(a.toJson());
      expect(back, equals(a));
    });
  });
}

class _NonJsonSafe {
  _NonJsonSafe(this.value);
  final String value;
}
