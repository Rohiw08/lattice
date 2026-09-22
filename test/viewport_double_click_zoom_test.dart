// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parity coverage for `zoomOnDoubleClick`, previously declared but unwired.
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

/// Two primary-button taps at [pos], 100ms apart — inside the double-tap
/// window and zero slop.
Future<void> _doubleClick(WidgetTester tester, Offset pos) async {
  tester.binding.handlePointerEvent(PointerDownEvent(
      pointer: 1,
      position: pos,
      buttons: kPrimaryButton,
      timeStamp: const Duration(milliseconds: 100)));
  tester.binding.handlePointerEvent(PointerUpEvent(
      pointer: 1, position: pos, timeStamp: const Duration(milliseconds: 140)));
  tester.binding.handlePointerEvent(PointerDownEvent(
      pointer: 2,
      position: pos,
      buttons: kPrimaryButton,
      timeStamp: const Duration(milliseconds: 200)));
  tester.binding.handlePointerEvent(PointerUpEvent(
      pointer: 2, position: pos, timeStamp: const Duration(milliseconds: 240)));
  await tester.pump();
}

void main() {
  testWidgets('double-click zooms in when zoomOnDoubleClick is true',
      (tester) async {
    final controller = await _pump(tester, options: FlowCanvasOptions());
    final before = controller.currentState.viewport.zoom;
    await _doubleClick(tester, const Offset(700, 520));
    expect(controller.currentState.viewport.zoom, greaterThan(before));
  });

  testWidgets('double-click is inert when zoomOnDoubleClick is false',
      (tester) async {
    final controller = await _pump(tester,
        options: FlowCanvasOptions(
          viewportOptions: ViewportOptions(zoomOnDoubleClick: false),
        ));
    final before = controller.currentState.viewport.zoom;
    await _doubleClick(tester, const Offset(700, 520));
    expect(controller.currentState.viewport.zoom, moreOrLessEquals(before));
  });

  testWidgets('two slow taps (beyond the window) do not zoom', (tester) async {
    final controller = await _pump(tester, options: FlowCanvasOptions());
    final before = controller.currentState.viewport.zoom;
    // 500ms apart — past kDoubleTapTimeout (300ms).
    tester.binding.handlePointerEvent(PointerDownEvent(
        pointer: 1,
        position: const Offset(700, 520),
        buttons: kPrimaryButton,
        timeStamp: const Duration(milliseconds: 100)));
    tester.binding.handlePointerEvent(PointerUpEvent(
        pointer: 1,
        position: const Offset(700, 520),
        timeStamp: const Duration(milliseconds: 140)));
    tester.binding.handlePointerEvent(PointerDownEvent(
        pointer: 2,
        position: const Offset(700, 520),
        buttons: kPrimaryButton,
        timeStamp: const Duration(milliseconds: 600)));
    await tester.pump();
    expect(controller.currentState.viewport.zoom, moreOrLessEquals(before));
  });
}
