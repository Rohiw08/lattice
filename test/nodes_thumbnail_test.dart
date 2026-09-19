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

    testWidgets('graph edits while zoomed out keep painting', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller, thumbnailBelowZoom: 0.4);
      await tester.pump();

      controller.viewport.setViewport(
        const FlowViewport(offset: Offset.zero, zoom: 0.2),
      );
      await tester.pump();

      controller.nodes.addNode(
        const FlowNode<String>(
          id: 'c',
          type: 'default',
          position: Offset(500, 400),
          data: 'C',
        ),
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsOneWidget);

      controller.selection.selectNode('a');
      await tester.pump();
      expect(find.byKey(const ValueKey('nodes-thumbnail')), findsOneWidget);
    });
  });
}
