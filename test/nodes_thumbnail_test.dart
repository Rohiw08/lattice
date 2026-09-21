import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Thumbnail LOD: below `lodThumbnailBelowZoom` nodes paint as rects instead
/// of mounting widgets.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  double? thumbnailBelowZoom,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            options: FlowCanvasOptions(
              viewportOptions: ViewportOptions(
                minZoom: 0.1,
                lodThumbnailBelowZoom: thumbnailBelowZoom,
              ),
            ),
            initialNodes: const [
              FlowNode<String>(
                id: 'a',
                type: 'input',
                position: Offset(80, 120),
                data: 'A',
              ),
              FlowNode<String>(
                id: 'b',
                type: 'output',
                position: Offset(320, 120),
                data: 'B',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Number of node rects the thumbnail painter currently holds. Reads the live
/// `items` off the mounted painter (via `dynamic`, the painter is internal),
/// so it reflects what is actually painted — not just that the layer exists.
int _thumbItemCount(WidgetTester tester) {
  final painter = tester
      .widget<CustomPaint>(find.byKey(const ValueKey('nodes-thumbnail')))
      .painter;
  return ((painter as dynamic).items as List).length;
}

/// Number of node rects the thumbnail paints with a selection outline.
int _thumbSelectedCount(WidgetTester tester) {
  final painter = tester
      .widget<CustomPaint>(find.byKey(const ValueKey('nodes-thumbnail')))
      .painter;
  final items = (painter as dynamic).items as List;
  return items.where((e) => (e as dynamic).selectedBorder != null).length;
}

void main() {
  group('thumbnail LOD', () {
    testWidgets('zoomed out past threshold paints instead of mounting',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, thumbnailBelowZoom: 0.4);
      await tester.pump();
      expect(find.byType(BaseNode), findsNWidgets(2));
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsNothing);

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.2),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsOneWidget);
      expect(find.byType(BaseNode), findsNothing);
    });

    testWidgets('zooming back in restores widgets', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, thumbnailBelowZoom: 0.4);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.2),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsOneWidget);

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 1.0),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsNothing);
      expect(find.byType(BaseNode), findsNWidgets(2));
    });

    testWidgets('null threshold never thumbnails', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.1),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsNothing);
      expect(find.byType(BaseNode), findsNWidgets(2));
    });

    testWidgets('graph edits while zoomed out repaint the thumbnail',
        (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, thumbnailBelowZoom: 0.4);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.2),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsOneWidget);
      // Two seeded nodes, none selected.
      expect(_thumbItemCount(tester), 2);
      expect(_thumbSelectedCount(tester), 0);

      // Adding a node while zoomed out must repaint the thumbnail — the layer
      // reads the graph reactively, not once at mount.
      controller.nodes.addNode(
        const FlowNode<String>(
          id: 'c',
          type: 'default',
          position: Offset(500, 400),
          data: 'C',
        ),
      );
      await tester.pump();
      expect(_thumbItemCount(tester), 3);

      // Selecting a node while zoomed out must repaint its outline.
      controller.selection.selectNode('a');
      await tester.pump();
      expect(_thumbSelectedCount(tester), 1);
    });

    testWidgets('pan/zoom while zoomed out does not rebuild the painter',
        (tester) async {
      // The LOD cache invariant: below the threshold the cached layer moves via
      // the canvas matrix, it must NOT repaint on every pan/zoom frame. If the
      // layer watched the whole viewport (instead of just nodes + selection),
      // it would rebuild each frame and defeat the optimization.
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, thumbnailBelowZoom: 0.4);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.2),
      );
      await tester.pump();
      final painterBefore = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('nodes-thumbnail')))
          .painter;

      // Pan and zoom (still below the threshold) — the graph is unchanged.
      controller.viewport.setViewport(
        const FlowViewport(offset: Offset(120, 90), zoom: 0.25),
      );
      await tester.pump();
      final painterAfter = tester
          .widget<CustomPaint>(find.byKey(const ValueKey('nodes-thumbnail')))
          .painter;

      // Same painter instance → no rebuild → the cache did its job.
      expect(identical(painterBefore, painterAfter), isTrue);
    });
  });
}
