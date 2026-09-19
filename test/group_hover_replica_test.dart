import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// xy-theme group fills (brightness-dependent).
const _darkFill = Color(0x387B6B94);
const _lightFill = Color(0x66CFB6FF);
void main() {
  group('xy group hover', () {
    for (final entry in [
      (
        theme: FlowCanvasTheme.dark(),
        brightness: Brightness.dark,
        fill: _darkFill,
        name: 'dark'
      ),
      (
        theme: FlowCanvasTheme.light(),
        brightness: Brightness.light,
        fill: _lightFill,
        name: 'light'
      ),
    ]) {
      testWidgets('${entry.name}: hover never changes group background',
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
            theme: ThemeData(brightness: entry.brightness),
            home: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                theme: entry.theme,
                initialNodes: nodes,
                initialEdges: const [],
                overlays: const [FlowBackground()],
              ),
            ),
          ),
        );
        await tester.pump();

        BoxDecoration? groupBox() {
          for (final box in tester
              .widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
            final d = box.decoration;
            if (d is BoxDecoration && d.color == entry.fill) return d;
          }
          return null;
        }

        expect(groupBox(), isNotNull);
        expect(find.text('Group'), findsNothing,
            reason: 'Lattice v12 GroupNode renders no label by default');

        final groupWidget = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .firstWhere((b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).color == entry.fill);
        final groupRect = tester.getRect(find.byWidget(groupWidget));
        final gesture =
            await tester.createGesture(kind: PointerDeviceKind.mouse);
        await gesture.addPointer(location: const Offset(10, 10));
        await tester.pump();
        // Bottom-right quarter of the group, away from the child node.
        await gesture.moveTo(Offset(
          groupRect.left + groupRect.width * 0.8,
          groupRect.top + groupRect.height * 0.85,
        ));
        await tester.pump();

        expect(groupBox()?.color, entry.fill,
            reason: 'group hover must not change the background');
      });
    }
  });
}
