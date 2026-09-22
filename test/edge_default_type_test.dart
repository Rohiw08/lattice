// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `EdgeOptions.type` is the global default path type for connection-created
/// edges (RF `defaultEdgeOptions.type`). Previously declared but unwired.
Future<ProviderContainer> _connect(
  WidgetTester tester, {
  required FlowCanvasOptions options,
}) async {
  final nodes = [
    FlowNode<String>(id: 'node_a', type: 'default', position: Offset.zero),
    FlowNode<String>(
        id: 'node_b', type: 'default', position: const Offset(300, 0)),
  ];
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          options: options,
          initialNodes: nodes,
          overlays: const [FlowMiniMap()],
        ),
      ),
    ),
  );
  await tester.pump();

  final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
  final sourceGlobal = tester.getCenter(find.byWidget(handles
      .firstWhere((h) => h.nodeId == 'node_a' && h.handleId == 'source')));
  final targetGlobal = tester.getCenter(find.byWidget(handles
      .firstWhere((h) => h.nodeId == 'node_b' && h.handleId == 'target')));

  final gesture = await tester.startGesture(sourceGlobal);
  await tester.pump();
  await gesture.moveBy(const Offset(30, 20));
  await tester.pump();
  await gesture.moveTo(targetGlobal);
  await tester.pump();
  await gesture.up();
  await tester.pump();

  return ProviderScope.containerOf(tester.element(find.byType(FlowMiniMap)));
}

FlowEdge _createdEdge(ProviderContainer c) => c
    .read(internalControllerProvider)
    .edges
    .values
    .firstWhere((e) => e.sourceNodeId == 'node_a' && e.targetNodeId == 'node_b');

void main() {
  testWidgets('connection adopts EdgeOptions.type as its default path type',
      (tester) async {
    final c = await _connect(tester,
        options: FlowCanvasOptions(
          edgeOptions: EdgeOptions(type: EdgePathType.step),
        ));
    expect(_createdEdge(c).type, EdgePathType.step);
  });

  testWidgets('connection defaults to bezier when EdgeOptions.type is null',
      (tester) async {
    final c = await _connect(tester, options: FlowCanvasOptions());
    expect(_createdEdge(c).type, EdgePathType.bezier);
  });
}
