// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Small-parity batch: pure getViewportForBounds, onMoveStart/onMoveEnd,
/// and the zoom-activation gate (zoomActivationKeyCode).

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  FlowCanvasOptions? options,
  FlowCanvasCallbacks? callbacks,
}) async {
  final controller = FlowCanvasController();
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          controller: controller,
          options: options ?? FlowCanvasOptions(),
          callbacks: callbacks ?? const FlowCanvasCallbacks(),
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

void main() {
  testWidgets('getViewportForBounds matches an applied fitBounds',
      (tester) async {
    final controller = await _pump(tester);
    const bounds = Rect.fromLTWH(0, 0, 200, 100);

    final pure = controller.viewport.getViewportForBounds(bounds);
    expect(pure, isNotNull);

    await controller.viewport.fitBounds(bounds);
    await tester.pump();
    final applied = controller.currentState.viewport;
    expect(applied.zoom, moreOrLessEquals(pure!.zoom));
    expect(applied.offset.dx, moreOrLessEquals(pure.offset.dx));
    expect(applied.offset.dy, moreOrLessEquals(pure.offset.dy));
  });

  testWidgets('onMoveStart/onMoveEnd bracket a user pan', (tester) async {
    var starts = 0;
    var ends = 0;
    await _pump(tester,
        callbacks: FlowCanvasCallbacks(
          onMoveStart: (_) => starts++,
          onMoveEnd: (_) => ends++,
        ));

    // Drag empty canvas space (bottom-right corner is empty).
    final gesture = await tester.startGesture(const Offset(750, 550));
    await tester.pump();
    await gesture.moveBy(const Offset(-60, -40));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(starts, 1);
    expect(ends, 1);
  });

  testWidgets('zoom gate blocks wheel zoom until the key is held',
      (tester) async {
    final controller = await _pump(tester,
        options: FlowCanvasOptions(
          keyboardOptions: KeyboardOptions(
            zoomActivationKeys: {LogicalKeyboardKey.control},
          ),
        ));

    Future<void> scroll() async {
      tester.binding.handlePointerEvent(
        PointerScrollEvent(
          position: const Offset(400, 300),
          scrollDelta: const Offset(0, 120),
        ),
      );
      await tester.pump();
    }

    final before = controller.currentState.viewport.zoom;
    await scroll();
    expect(controller.currentState.viewport.zoom, before,
        reason: 'gated wheel must not zoom without the key');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
    await scroll();
    expect(controller.currentState.viewport.zoom, lessThan(before),
        reason: 'held key must allow wheel zoom');
    await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
  });

  test('zoom gate defaults to the platform gate (Meta/Ctrl)', () {
    // React Flow parity: wheel zoom needs Meta (macOS) or Control held.
    expect(KeyboardOptions().isZoomActivationHeld, isFalse);
    expect(
        KeyboardOptions(zoomActivationKeys: {LogicalKeyboardKey.control})
            .isZoomActivationHeld,
        isFalse);
  });
}
