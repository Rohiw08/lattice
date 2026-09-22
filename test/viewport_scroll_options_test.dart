// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parity coverage for the pan-on-scroll options that were previously
/// declared but unwired: `panOnScrollMode` (axis lock) and `preventScrolling`
/// (whether the wheel is captured at all).
Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  required FlowCanvasOptions options,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: options,
          initialState: FlowCanvasState.initial().copyWith(
            nodes: {
              'a': FlowNode<String>(
                type: 'default',
                id: 'a',
                position: const Offset(100, 100),
                size: const Size(160, 44),
                data: 'A',
              ),
            },
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

Future<void> _wheel(WidgetTester tester) async {
  // A plain vertical mouse wheel (no zoom-activation key held).
  tester.binding.handlePointerEvent(
    PointerScrollEvent(
      position: const Offset(400, 300),
      scrollDelta: const Offset(0, 120),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('panOnScrollMode.vertical pans the Y axis from a vertical wheel',
      (tester) async {
    final controller = await _pump(tester,
        options: FlowCanvasOptions(
          viewportOptions: ViewportOptions(
            panOnScroll: true,
            panOnScrollMode: PanOnScrollMode.vertical,
          ),
        ));
    final before = controller.currentState.viewport.offset;
    await _wheel(tester);
    final after = controller.currentState.viewport.offset;
    expect(after.dy, isNot(moreOrLessEquals(before.dy)),
        reason: 'vertical mode must move Y');
    // Off-axis stays put (tolerate sub-pixel matrix rounding).
    expect(after.dx, moreOrLessEquals(before.dx, epsilon: 0.01),
        reason: 'vertical mode must not move X');
  });

  testWidgets(
      'panOnScrollMode.horizontal maps a vertical wheel to the X axis',
      (tester) async {
    final controller = await _pump(tester,
        options: FlowCanvasOptions(
          viewportOptions: ViewportOptions(
            panOnScroll: true,
            panOnScrollMode: PanOnScrollMode.horizontal,
          ),
        ));
    final before = controller.currentState.viewport.offset;
    await _wheel(tester);
    final after = controller.currentState.viewport.offset;
    expect(after.dx, isNot(moreOrLessEquals(before.dx)),
        reason: 'horizontal mode must move X even from a vertical wheel');
    // Off-axis stays put (tolerate sub-pixel matrix rounding).
    expect(after.dy, moreOrLessEquals(before.dy, epsilon: 0.01),
        reason: 'horizontal mode must not move Y');
  });

  testWidgets('preventScrolling:false leaves the wheel uncaptured (no pan)',
      (tester) async {
    final controller = await _pump(tester,
        options: FlowCanvasOptions(
          viewportOptions: ViewportOptions(
            panOnScroll: true,
            preventScrolling: false,
          ),
        ));
    final before = controller.currentState.viewport.offset;
    await _wheel(tester);
    final after = controller.currentState.viewport.offset;
    expect(after.dx, moreOrLessEquals(before.dx));
    expect(after.dy, moreOrLessEquals(before.dy));
  });
}
