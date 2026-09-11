// ignore_for_file: prefer_const_constructors

import 'dart:ui' as ui;

import 'package:lattice/lattice.dart';
import 'package:lattice/src/features/minimap/presentation/painters/minimap_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds the [Positioned] that places a node at its absolute flow position.
Positioned _nodePosition(WidgetTester tester, String layerName, String nodeId) {
  final stack = find.byKey(ValueKey('${layerName}_$nodeId'));
  return tester.widget<Positioned>(
    find.descendant(of: stack, matching: find.byType(Positioned)).first,
  );
}

MiniMapPainter _minimapPainter(WidgetTester tester) {
  return tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((w) => w.painter)
      .whereType<MiniMapPainter>()
      .single;
}

/// Rasterizes the minimap's [RepaintBoundary] so paint-level changes during
/// drag are observable (not just painter field changes).
Future<List<int>> _minimapPixels(WidgetTester tester) async {
  final customPaint =
      tester.widgetList<CustomPaint>(find.byType(CustomPaint)).firstWhere(
            (w) => w.painter is MiniMapPainter,
          );
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find
        .ancestor(
          of: find.byWidget(customPaint),
          matching: find.byType(RepaintBoundary),
        )
        .first,
  );
  final image = await tester.runAsync(() => boundary.toImage());
  final data = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  return data!.buffer.asUint8List();
}

void main() {
  testWidgets('group drag moves group and children in realtime (pre-commit)',
      (tester) async {
    final nodes = [
      FlowNode<String>(
        type: 'group',
        id: 'group_1',
        position: const Offset(60, 40),
        size: const Size(360, 260),
        data: 'Group',
      ),
      FlowNode<String>(
        type: 'input',
        id: 'node_in',
        parentId: 'group_1',
        position: const Offset(30, 60),
        data: 'Input',
        extent: FlowNodeExtent.parent,
      ),
      FlowNode<String>(
        type: 'default',
        id: 'node_a',
        parentId: 'group_1',
        position: const Offset(180, 50),
        data: 'A',
        extent: FlowNodeExtent.parent,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            initialNodes: nodes,
            overlays: const [FlowMiniMap()],
          ),
        ),
      ),
    );
    await tester.pump();

    final g0 = _nodePosition(tester, 'background', 'group_1');
    final c0 = _nodePosition(tester, 'middle', 'node_a');
    expect(g0.left, 60);
    expect(g0.top, 40);
    expect(c0.left, 60 + 180);
    expect(c0.top, 40 + 50);
    expect(_minimapPainter(tester).livePositions, isEmpty);

    // Grab the group in empty area, resolved from its actual on-screen rect
    // (canvas transform may offset flow coords from screen coords).
    final groupRect = tester.getRect(find.byType(GroupNode));
    final grab = Offset(
      groupRect.left + groupRect.width * 0.27,
      groupRect.top + groupRect.height * 0.84,
    );
    final gesture = await tester.startGesture(grab);
    await tester.pump();

    // Cross the drag slop so the node pan recognizer accepts.
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();

    final g1 = _nodePosition(tester, 'background', 'group_1');
    final c1 = _nodePosition(tester, 'middle', 'node_a');
    final live1 = Map<String, Offset>.of(_minimapPainter(tester).livePositions);
    expect(live1['group_1'], isNotNull,
        reason: 'minimap must see live position mid-drag');
    expect(live1, isNotEmpty);

    // Move again — everything must follow BEFORE the gesture ends.
    await gesture.moveBy(const Offset(60, 40));
    await tester.pump();

    final g2 = _nodePosition(tester, 'background', 'group_1');
    final c2 = _nodePosition(tester, 'middle', 'node_a');
    final live2 = Map<String, Offset>.of(_minimapPainter(tester).livePositions);

    expect(g2.left, g1.left! + 60, reason: 'group moves in realtime');
    expect(g2.top, g1.top! + 40);
    expect(c2.left, c1.left! + 60,
        reason: 'child moves with the group in realtime, pre-commit');
    expect(c2.top, c1.top! + 40);
    expect(live2['group_1'], live1['group_1']! + const Offset(60, 40),
        reason: 'minimap live position follows mid-drag');
    expect(live2['group_1']!.dx, g2.left);
    expect(live2['group_1']!.dy, g2.top);

    // Paint-level check: the minimap must actually REPAINT with the live
    // position mid-drag, not just hold the data.
    final pixelsBefore = await _minimapPixels(tester);
    await gesture.moveBy(const Offset(20, 15));
    await tester.pump();
    final pixelsAfter = await _minimapPixels(tester);
    expect(pixelsAfter, isNot(equals(pixelsBefore)),
        reason: 'minimap must repaint nodes while the drag is still active');

    // Release — commit must keep the same position, minimap clears live map.
    await gesture.up();
    await tester.pump();

    final g3 = _nodePosition(tester, 'background', 'group_1');
    expect(g3.left, g2.left! + 20,
        reason: 'commit keeps the final live position (incl. paint move)');
    expect(g3.top, g2.top! + 15);
    expect(_minimapPainter(tester).livePositions, isEmpty);
  });
}
