import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Camera animation: `lerpViewport` math plus animated fitView / center /
/// setViewport with cancel semantics.
///
/// Mid-flight assertions read on-screen node rects (the live matrix), never
/// committed state — state lands once, on completion or cancel.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          // Unique key per mount: swapping controllers on one element
          // reuses the internal controller by design, which would leak
          // state (and flights) across tests.
          child: FlowCanvas(
            key: UniqueKey(),
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            initialNodes: const [
              FlowNode<String>(
                id: 'a',
                type: 'input',
                position: Offset(0, 0),
                size: Size(160, 100),
                data: 'A',
              ),
              FlowNode<String>(
                id: 'b',
                type: 'output',
                position: Offset(2000, 1200),
                size: Size(160, 100),
                data: 'B',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Offset _nodeACenter(WidgetTester tester) {
  // Default registry renders no label; locate via the middle-layer key.
  return tester
      .getRect(find.byKey(const ValueKey('middle_a')))
      .center;
}

void main() {
  group('lerpViewport', () {
    test('endpoints and linear midpoint', () {
      const a = FlowViewport(offset: Offset.zero, zoom: 1);
      const b = FlowViewport(offset: Offset(100, 50), zoom: 2);
      expect(lerpViewport(a, b, 0), a);
      expect(lerpViewport(a, b, 1), b);
      final mid = lerpViewport(a, b, 0.5,
          interpolate: FitViewInterpolation.linear);
      expect(mid.offset, const Offset(50, 25));
      expect(mid.zoom, 1.5);
    });

    test('smooth zoom travels in log space', () {
      const a = FlowViewport(offset: Offset.zero, zoom: 1);
      const b = FlowViewport(offset: Offset.zero, zoom: 4);
      final mid = lerpViewport(a, b, 0.5);
      // sqrt(1*4) = 2, not the linear 2.5.
      expect(mid.zoom, moreOrLessEquals(2.0));
      expect(mid.offset, Offset.zero);
    });

    test('progress clamps outside [0, 1]', () {
      const a = FlowViewport(offset: Offset.zero, zoom: 1);
      const b = FlowViewport(offset: Offset(100, 0), zoom: 1);
      expect(lerpViewport(a, b, -1).offset.dx, 0.0);
      expect(lerpViewport(a, b, 2).offset.dx, 100.0);
    });
  });

  group('fitView', () {
    testWidgets('zero duration lands instantly', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.fitView(
        fitviewOptions: const FitViewOptions(duration: Duration.zero),
        viewportOptions: const ViewportOptions(minZoom: 0.1),
      );
      await tester.pump();

      expect(controller.viewport.isAnimating, isFalse);
      // Fitted: both far-apart nodes map inside the viewport.
      final topLeft = controller.viewport.flowToViewport(Offset.zero);
      final bottomRight =
          controller.viewport.flowToViewport(const Offset(2160, 1300));
      expect(topLeft.dx, greaterThanOrEqualTo(-1));
      expect(topLeft.dy, greaterThanOrEqualTo(-1));
      expect(bottomRight.dx, lessThanOrEqualTo(801));
      expect(bottomRight.dy, lessThanOrEqualTo(601));
    });

    testWidgets('nonzero duration glides and lands', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final startCenter = _nodeACenter(tester);
      controller.viewport.fitView(
        fitviewOptions: const FitViewOptions(
          duration: Duration(milliseconds: 300),
        ),
        viewportOptions: const ViewportOptions(minZoom: 0.1),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);

      // Mid-flight: on screen the node has moved, state hasn't landed.
      await tester.pump(const Duration(milliseconds: 100));
      expect(_nodeACenter(tester), isNot(equals(startCenter)));
      expect(controller.viewport.isAnimating, isTrue);

      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(controller.viewport.isAnimating, isFalse);
      final done = controller.currentState.viewport;
      expect(done.zoom, lessThan(1.0));
      final topLeft = controller.viewport.flowToViewport(Offset.zero);
      expect(topLeft.dx, greaterThanOrEqualTo(-1));
    });

    testWidgets('ease shapes the flight', (tester) async {
      Future<Offset> travelAfter(
          FlowCanvasController c, Curve ease) async {
        await _pump(tester, controller: c);
        await tester.pump();
        final start = _nodeACenter(tester);
        c.viewport.fitView(
          fitviewOptions: FitViewOptions(
            duration: const Duration(milliseconds: 400),
            ease: ease,
          ),
          viewportOptions: const ViewportOptions(minZoom: 0.1),
        );
        expect(c.viewport.isAnimating, isTrue);
        // Two frames: the first tick establishes the epoch, progress
        // shows from the second tick on (standard Ticker behavior).
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        return _nodeACenter(tester) - start;
      }

      final linearTravel = await travelAfter(
          FlowCanvasController(), Curves.linear);
      final easedTravel = await travelAfter(
          FlowCanvasController(), Curves.easeInOut);

      // easeInOut(0.25) < 0.25: eased flight lags the linear one early.
      expect(easedTravel.distance, lessThan(linearTravel.distance));
      expect(linearTravel.distance, greaterThan(0));
    });

    testWidgets('user grab cancels the flight without snapping back',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.fitView(
        fitviewOptions: const FitViewOptions(
          duration: Duration(seconds: 5),
        ),
        viewportOptions: const ViewportOptions(minZoom: 0.1),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(controller.viewport.isAnimating, isTrue);

      // Grab empty canvas (bottom-right corner is empty) and pan.
      final canvas = tester.getRect(find.byType(FlowCanvas));
      final gesture =
          await tester.startGesture(canvas.bottomRight.translate(-30, -30));
      await tester.pump();
      await gesture.moveBy(const Offset(-60, -40));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(controller.viewport.isAnimating, isFalse);
      final held = controller.currentState.viewport;
      // Settles: no drift back toward the abandoned target afterwards.
      await tester.pump(const Duration(seconds: 6));
      expect(controller.currentState.viewport.offset, held.offset);
      expect(controller.currentState.viewport.zoom, held.zoom);
    });
  });

  group('centerOnPosition / setViewport', () {
    testWidgets('duration animates, default is instant', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.centerOnPosition(const Offset(500, 500));
      await tester.pump();
      expect(
        controller.viewport.flowToViewport(const Offset(500, 500)),
        offsetMoreOrLessEquals(const Offset(400, 300)),
      );
      final landedCenter = _nodeACenter(tester);

      controller.viewport.centerOnPosition(
        const Offset(100, 100),
        duration: const Duration(milliseconds: 300),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);
      // Mid-flight: moving, but not landed.
      await tester.pump(const Duration(milliseconds: 100));
      final midCenter = _nodeACenter(tester);
      expect(midCenter, isNot(equals(landedCenter)));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
      expect(controller.viewport.isAnimating, isFalse);
      expect(
        controller.viewport.flowToViewport(const Offset(100, 100)),
        offsetMoreOrLessEquals(const Offset(400, 300)),
      );
    });

    testWidgets('setViewport honors duration', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final landed = controller.viewport.setViewport(
        const FlowViewport(offset: Offset(111, 222), zoom: 1.5),
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(controller.viewport.isAnimating, isFalse);
      expect(await landed, isTrue);
      expect(controller.currentState.viewport.offset,
          offsetMoreOrLessEquals(const Offset(111, 222)));
      expect(controller.currentState.viewport.zoom, 1.5);
    });

    testWidgets('futures resolve false on cancel and lock', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      // Cancelled flight completes false.
      final flight = controller.viewport.fitView(
        fitviewOptions: const FitViewOptions(
          duration: Duration(seconds: 5),
        ),
        viewportOptions: const ViewportOptions(minZoom: 0.1),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);
      controller.viewport.cancelAnimation();
      expect(await flight, isFalse);
      expect(controller.viewport.isAnimating, isFalse);

      // Locked canvas refuses flights.
      controller.viewport.toggleLock();
      expect(
        await controller.viewport.centerOnPosition(const Offset(1, 1)),
        isFalse,
      );
      expect(
        await controller.viewport.setViewport(
          const FlowViewport(offset: Offset(1, 1), zoom: 1),
        ),
        isFalse,
      );
      expect(
        await controller.viewport.fitView(
          fitviewOptions:
              const FitViewOptions(duration: Duration.zero),
        ),
        isFalse,
      );
    });
  });

  group('zoomTo / fitBounds / zoom', () {
    testWidgets('zoomTo lands on the requested level', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      expect(
        await controller.viewport.zoomTo(2.0),
        isTrue,
      );
      expect(controller.currentState.viewport.zoom, 2.0);

      // Animated variant glides (live matrix moves mid-flight; state
      // lands once).
      final beforeCenter = _nodeACenter(tester);
      final zoomed = controller.viewport.zoomTo(
        1.0,
        duration: const Duration(milliseconds: 300),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(_nodeACenter(tester), isNot(equals(beforeCenter)));
      // Pump past the landing before awaiting: futures resolve on ticks.
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(await zoomed, isTrue);
      expect(controller.currentState.viewport.zoom, 1.0);
    });

    testWidgets('fitBounds fits an explicit rect', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      expect(
        await controller.viewport.fitBounds(
          const Rect.fromLTWH(0, 0, 160, 100),
        ),
        isTrue,
      );
      final mapped = controller.viewport.flowToViewport(const Offset(80, 50));
      expect(mapped.dx, greaterThan(0));
      expect(mapped.dx, lessThan(800));
      expect(mapped.dy, greaterThan(0));
      expect(mapped.dy, lessThan(600));
    });

    testWidgets('zoom honors duration', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final done = controller.viewport.zoom(
        focalPoint: const Offset(400, 300),
        minZoom: 0.1,
        maxZoom: 4.0,
        zoomFactor: 1.0,
        duration: const Duration(milliseconds: 200),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(await done, isTrue);
      expect(controller.currentState.viewport.zoom, 2.0);
    });

    testWidgets('linear interpolate on center', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final done = controller.viewport.centerOnPosition(
        const Offset(1000, 1000),
        duration: const Duration(milliseconds: 200),
        interpolate: FitViewInterpolation.linear,
      );
      // Epoch pump first: the first tick only establishes Ticker time,
      // progress shows from the next timed pump on.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(await done, isTrue);
      expect(
        controller.viewport.flowToViewport(const Offset(1000, 1000)),
        offsetMoreOrLessEquals(const Offset(400, 300)),
      );
    });

    testWidgets('unmount cancels the flight', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      final flight = controller.viewport.fitView(
        fitviewOptions: const FitViewOptions(
          duration: Duration(milliseconds: 400),
        ),
        viewportOptions: const ViewportOptions(minZoom: 0.1),
      );
      await tester.pump();
      expect(controller.viewport.isAnimating, isTrue);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      bool? result;
      flight.then((v) => result = v);
      await tester.pump(); // flush microtasks (no timers involved)
      expect(result, isFalse);
    });
  });
}
