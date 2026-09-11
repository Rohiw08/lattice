import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FlowNode direct construction', () {
    test('generative constructor builds a connectable default node', () {
      final node = FlowNode<String>(
        id: 'node_a',
        type: 'default',
        position: const Offset(30, 60),
        data: 'hello',
        size: const Size(100, 100),
      );

      expect(node.id, 'node_a');
      expect(node.type, 'default');
      expect(node.position, const Offset(30, 60));
      expect(node.data, 'hello');
      expect(node.size, const Size(100, 100));
      expect(node.handles, isEmpty);

      final handles = node.effectiveHandles;
      expect(handles.keys, ['target', 'source']);
      expect(handles['target']!.type, HandleType.target);
      expect(handles['target']!.position, const Offset(50, 0));
      expect(handles['source']!.type, HandleType.source);
      expect(handles['source']!.position, const Offset(50, 100));
    });

    test('input and output types synthesize their single handle', () {
      final input = FlowNode<String>(
        id: 'in',
        type: 'input',
        position: Offset.zero,
        data: 'Input',
      );
      expect(input.effectiveHandles.keys, ['source']);
      expect(input.effectiveHandles['source']!.type, HandleType.source);

      final output = FlowNode<String>(
        id: 'out',
        type: 'output',
        position: Offset.zero,
        data: 'Output',
      );
      expect(output.effectiveHandles.keys, ['target']);
      expect(output.effectiveHandles['target']!.type, HandleType.target);
    });

    test('unknown types synthesize no handles', () {
      final node = FlowNode<String>(
        id: 'custom',
        type: 'custom',
        position: Offset.zero,
        data: 'x',
      );
      expect(node.effectiveHandles, isEmpty);
    });

    test('explicit handles win over synthesized ones', () {
      final node = FlowNode<String>(
        id: 'custom',
        type: 'default',
        position: Offset.zero,
        data: 'x',
        handles: {
          'side': const FlowHandle(
            id: 'side',
            type: HandleType.source,
            position: Offset(10, 20),
          ),
        },
      );
      expect(node.effectiveHandles.keys, ['side']);
    });

    test('data is optional (Lattice: defaults to empty object)', () {
      final node = FlowNode<String>(
        id: 'no_data',
        type: 'default',
        position: Offset.zero,
      );
      expect(node.data, isNull);

      final json = node.toJson((v) => v);
      expect(json['data'], isNull);
      final roundTrip = FlowNode<String>.fromJson(json, (v) => v as String);
      expect(roundTrip.data, isNull);
    });

    test('per-node style is carried and not serialized', () {
      final style = FlowNodeStyle.colored(color: Colors.teal);
      final node = FlowNode<String>(
        id: 'styled',
        type: 'default',
        position: Offset.zero,
        data: 'x',
        style: style,
      );
      expect(node.style, style);
      expect(node.copyWith().style, style);

      final json = node.toJson((v) => v);
      expect(json.containsKey('style'), isFalse);
      final roundTrip = FlowNode<String>.fromJson(json, (v) => v as String);
      expect(roundTrip.style, isNull);
    });
  });
}