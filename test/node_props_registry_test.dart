import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LabelData {
  const _LabelData(this.label);
  final String label;
}

void main() {
  test('NodeProps.fromNode and cast preserve fields', () {
    final node = FlowNode<_LabelData>(
      type: 'default',
      id: 'n1',
      position: const Offset(10, 20),
      data: const _LabelData('hi'),
    );
    final props = NodeProps.fromNode(
      node,
      selected: true,
      dragging: true,
      hovered: false,
    );

    expect(props.id, 'n1');
    expect(props.type, BuiltInNodeType.defaultType);
    expect(props.selected, isTrue);
    expect(props.dragging, isTrue);
    expect(props.hovered, isFalse);
    expect(props.node, same(node));

    final typed = props.cast<_LabelData>();
    expect(typed.data?.label, 'hi');
  });

  test('NodeRegistry.registerTyped builds with typed data', () {
    final registry = NodeRegistry.empty()
      ..registerTyped<_LabelData>('label', (props) {
        return Text(props.data?.label ?? '');
      });

    final node = FlowNode.create(
      id: 'a',
      type: 'label',
      position: Offset.zero,
      data: const _LabelData('typed'),
    );
    final widget = registry.buildWidget(NodeProps.fromNode(node));
    expect(widget, isA<Text>());
    expect((widget as Text).data, 'typed');
  });

  test('NodeRegistry.register still receives FlowNode', () {
    final registry = NodeRegistry.empty()
      ..register('legacy', (node) => Text(node.id));

    final node = FlowNode.create(
      id: 'legacy-id',
      type: 'legacy',
      position: Offset.zero,
      data: 'x',
    );
    final widget = registry.buildWidget(NodeProps.fromNode(node));
    expect((widget as Text).data, 'legacy-id');
  });
}
