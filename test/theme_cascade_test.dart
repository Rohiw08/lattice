import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression guard for the theme cascade: global → local override → defaults.
///
/// The contract (matching React Flow's CSS-inheritance model and the repo's
/// own `FlowCanvasTheme.merge` — "other wins, nulls inherit"): a PARTIAL local
/// override must only change the fields it explicitly sets. Every field it does
/// not set must inherit from the global (base) layer, never silently snap back
/// to a component default.
///
/// Before the nullable-field fix, value-typed fields with constructor defaults
/// (e.g. `FlowConnectionStyle.pathType`) could not distinguish "unset" from
/// "set to the default", so `merge()` copied the default over the global value.
void main() {
  group('FlowConnectionStyle cascade', () {
    test('partial color override inherits the global pathType', () {
      final global =
          FlowConnectionStyle.light().copyWith(pathType: EdgePathType.step);
      // Override that only intends to change the stroke color.
      final override = FlowConnectionStyle.colored(color: Colors.red);

      final merged = global.merge(override);

      // pathType was never set by the override → must stay `step`.
      expect(merged.pathType, EdgePathType.step);
      // color WAS set by the override → must win.
      expect(
        merged.resolveStroke(ConnectionValidity.none).color,
        Colors.red,
      );
    });

    test('partial pathType override inherits the global stroke', () {
      final global = FlowConnectionStyle.colored(color: Colors.red);
      // Override that only intends to change the path shape.
      const override = FlowConnectionStyle(pathType: EdgePathType.step);

      final merged = global.merge(override);

      // activeDecoration was never set by the override → must stay red.
      expect(merged.resolveStroke(ConnectionValidity.none).color, Colors.red);
      // pathType WAS set → must win.
      expect(merged.pathType, EdgePathType.step);
    });
  });

  group('FlowEdgeLabelStyle cascade', () {
    test('partial override inherits the global padding', () {
      const globalPadding = EdgeInsets.all(16);
      final global = FlowEdgeLabelStyle.light().copyWith(padding: globalPadding);
      // Override that only intends to change the text color.
      final override = FlowEdgeLabelStyle.text(color: Colors.red);

      final merged = global.merge(override);

      // padding was never set by the override → must stay 16.
      expect(merged.padding, globalPadding);
    });

    testWidgets('FlowEdgeLabel applies theme padding (not just widget.padding)',
        (tester) async {
      const themePadding = EdgeInsets.all(20);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlowEdgeLabel(
                id: 'l1',
                position: Offset.zero,
                // No widget.padding → must fall back to the theme's padding,
                // not the hardcoded (8,4).
                style: const FlowEdgeLabelStyle(
                  textStyle: TextStyle(),
                  decoration: BoxDecoration(),
                  padding: themePadding,
                ),
                text: 'hi',
              ),
            ),
          ),
        ),
      );

      final container = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(container.padding, themePadding);
    });
  });
}
