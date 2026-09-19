// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/minimap/presentation/painters/minimap_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimap-pan dead-zone parity (same absolute-mapping semantics as node
/// drag / resize):
///
/// The minimap drives [ViewportController] per gesture delta while
/// [ViewportService.pan] clamps the offset to `translateExtent`. Pushing
/// into the bound and coming back must pin while the pointer is still
/// inside the clamped-away region (dead zone) and restore the origin —
/// never a permanent camera gap (the old incremental `panBy` path ended a
/// mirrored out-and-back hundreds of px off origin).

void main() {
  testWidgets('minimap pan into translateExtent dead-zones and restores',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            options: FlowCanvasOptions(
              viewportOptions: ViewportOptions(
                // Setup guard below pins these to the observed default
                // offset (flow origin centered in the 800x600 pane).
                translateExtent: CoordinateExtent(
                  minX: 400,
                  maxX: 450,
                  minY: double.negativeInfinity,
                  maxY: double.infinity,
                ),
              ),
            ),
            initialNodes: [
              FlowNode<String>(
                type: 'default',
                id: 'node_a',
                position: const Offset(100, 100),
                size: const Size(160, 100),
                data: 'A',
              ),
            ],
            overlays: const [FlowMiniMap()],
          ),
        ),
      ),
    );
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BaseNode).first),
    );
    double offsetX() =>
        container.read(internalControllerProvider).viewport.offset.dx;
    double offsetY() =>
        container.read(internalControllerProvider).viewport.offset.dy;

    final startX = offsetX();
    expect(startX, moreOrLessEquals(400.0),
        reason:
            'test setup: default offset must match the extent (fix numbers '
            'if the centering default ever changes)');
    final startY = offsetY();

    // The FlowMiniMap widget itself fills the overlay; the pannable panel
    // is the minimap CustomPaint — press its center (viewport-agnostic).
    final mapRect = tester.getRect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is MiniMapPainter,
      ),
    );
    final press = mapRect.center;
    expect(
        Rect.fromLTWH(0, 0, 800, 600).contains(press), isTrue,
        reason: 'test setup: minimap press point must be on the surface');

    // Drag LEFT on the minimap = +X main travel (inversePan false negates).
    // 800x600 content in a 200x150 minimap => scale 0.25 => x4 travel, so
    // this pushes ~1000px into a bound 50px away: pins hard regardless of
    // the slop prefix the framework absorbs.
    final gesture = await tester.startGesture(press);
    await tester.pump();
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(-40, 0));
      await tester.pump();
    }
    expect(offsetX(), moreOrLessEquals(450.0),
        reason: 'camera must pin at the translateExtent maxX');

    // Come back a little — still inside the clamped-away region.
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();
    expect(offsetX(), moreOrLessEquals(450.0),
        reason: 'dead zone: camera stays pinned while the pointer is still '
            'inside clamped-away travel');

    // Mirror the whole push back.
    for (var i = 0; i < 6; i++) {
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
    }
    expect(offsetX(), greaterThanOrEqualTo(startX - 10),
        reason: 'no camera gap: the mirrored return must not undershoot '
            'origin (the incremental path ends ~800px short)');
    expect(offsetX(), lessThanOrEqualTo(450.0));

    await gesture.up();
    await tester.pump();
    expect(offsetY(), moreOrLessEquals(startY),
        reason: 'pure-horizontal pan must not drift Y');
  });
}
