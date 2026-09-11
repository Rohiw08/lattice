import 'package:lattice/lattice.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _groupFill = Color(0x40F0F0F0);

BoxDecoration? _groupDecoration(WidgetTester tester) {
  for (final box
      in tester.widgetList<DecoratedBox>(find.byType(DecoratedBox))) {
    final d = box.decoration;
    if (d is BoxDecoration && d.color == _groupFill) return d;
  }
  return null;
}

Rect _groupRect(WidgetTester tester) {
  final box =
      tester.widgetList<DecoratedBox>(find.byType(DecoratedBox)).firstWhere(
            (b) =>
                b.decoration is BoxDecoration &&
                (b.decoration as BoxDecoration).color == _groupFill,
          );
  return tester.getRect(find.byWidget(box));
}

Future<void> _pumpGroupCanvas(
  WidgetTester tester, {
  required FlowCanvasTheme theme,
}) {
  return tester
      .pumpWidget(
        MaterialApp(
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

Future<void> _hoverGroup(WidgetTester tester) async {
  final center = _groupRect(tester).center;
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: const Offset(10, 10));
  await tester.pump();
  await gesture.moveTo(center);
  await tester.pump();
}

void main() {
  testWidgets('dark group keeps its background color on hover and selection',
      (tester) async {
    await _pumpGroupCanvas(tester, theme: FlowCanvasTheme.dark());

    final normal = _groupDecoration(tester);
    expect(normal, isNotNull);
    expect(normal!.color, _groupFill);
    expect(normal.boxShadow, isEmpty);
    expect(find.text('Group'), findsNothing,
        reason: 'Lattice v12 GroupNode renders no label by default');

    await _hoverGroup(tester);

    final hovered = _groupDecoration(tester);
    expect(hovered, isNotNull);
    expect(hovered!.color, _groupFill,
        reason: 'Lattice group hover is shadow-only; bg must not change');
    expect(hovered.boxShadow, const [
      BoxShadow(
        color: Color(0x14FFFFFF),
        blurRadius: 4,
        spreadRadius: 1,
        offset: Offset(0, 1),
      ),
    ]);

    await tester.tapAt(_groupRect(tester).center);
    await tester.pump();

    final selected = _groupDecoration(tester);
    expect(selected, isNotNull);
    expect(selected!.color, _groupFill,
        reason:
            'Lattice group selection is shadow-only; bg must not change');
    expect(selected.boxShadow, const [
      BoxShadow(
        color: Color(0xFF999999),
        spreadRadius: 0.5,
      ),
    ]);
  });

  testWidgets('light group keeps its background color on hover and selection',
      (tester) async {
    await _pumpGroupCanvas(tester, theme: FlowCanvasTheme.light());

    final normal = _groupDecoration(tester);
    expect(normal, isNotNull);
    expect(normal!.color, _groupFill);
    expect(normal.boxShadow, isEmpty);

    await _hoverGroup(tester);

    final hovered = _groupDecoration(tester);
    expect(hovered, isNotNull);
    expect(hovered!.color, _groupFill);
    expect(hovered.boxShadow, const [
      BoxShadow(
        color: Color(0x14000000),
        blurRadius: 4,
        spreadRadius: 1,
        offset: Offset(0, 1),
      ),
    ]);

    await tester.tapAt(_groupRect(tester).center);
    await tester.pump();

    final selected = _groupDecoration(tester);
    expect(selected, isNotNull);
    expect(selected!.color, _groupFill);
    expect(selected.boxShadow, const [
      BoxShadow(
        color: Color(0xFF1A192B),
        spreadRadius: 0.5,
      ),
    ]);
  });
}
