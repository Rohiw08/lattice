import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// xy-theme group fills (brightness-dependent since the xy adoption).
const _lightFill = Color(0x66CFB6FF);
const _darkFill = Color(0x387B6B94);
const _selectedBorder = Color(0xFF2196F3);

BoxDecoration? _groupDecoration(WidgetTester tester, Color fill) {
  for (final box
      in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final d = box.decoration;
    if (d is BoxDecoration && d.color == fill) return d;
  }
  return null;
}

Rect _groupRect(WidgetTester tester, Color fill) {
  final box =
      tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).firstWhere(
            (b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).color == fill,
          );
  return tester.getRect(find.byWidget(box));
}

Future<void> _pumpGroupCanvas(
  WidgetTester tester, {
  required FlowCanvasTheme theme,
  required Brightness brightness,
}) {
  return tester
      .pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: brightness),
          home: SizedBox(
            width: 800,
            height: 600,
            child: FlowCanvas(
              theme: theme,
              initialNodes: [
                FlowNode<String>(
                  type: 'group',
                  id: 'g1',
                  position: const Offset(100, 100),
                  size: const Size(200, 150),
                  data: 'Group',
                ),
              ],
              initialEdges: const [],
            ),
          ),
        ),
      )
      .then((_) => tester.pump());
}

Future<void> _hoverGroup(WidgetTester tester, Color fill) async {
  final center = _groupRect(tester, fill).center;
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(10, 10));
  await tester.pump();
  await gesture.moveTo(center);
  await tester.pump();
}

Color? _borderOf(BoxDecoration? d) {
  final border = d?.border;
  if (border is Border) return border.top.color;
  return null;
}

void main() {
  group('xy group chrome', () {
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
      testWidgets('${entry.name} group keeps bg, blues on selection',
          (tester) async {
        await _pumpGroupCanvas(
          tester,
          theme: entry.theme,
          brightness: entry.brightness,
        );

        final normal = _groupDecoration(tester, entry.fill);
        expect(normal, isNotNull);
        expect(normal!.color, entry.fill);
        expect(find.text('Group'), findsNothing,
            reason: 'Lattice v12 GroupNode renders no label by default');

        await _hoverGroup(tester, entry.fill);

        final hovered = _groupDecoration(tester, entry.fill);
        expect(hovered, isNotNull);
        expect(hovered!.color, entry.fill,
            reason: 'group hover must not change the background');

        await tester.tapAt(_groupRect(tester, entry.fill).center);
        await tester.pump();

        final selected = _groupDecoration(tester, entry.fill);
        expect(selected, isNotNull);
        expect(selected!.color, entry.fill);
        expect(_borderOf(selected), _selectedBorder,
            reason: 'selected group follows the blue selection language');
      });
    }
  });
}
