import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Color? _decorationColor(Decoration? d) => d is BoxDecoration ? d.color : null;

void main() {
  group('FlowCanvasTheme completeness', () {
    test('light() defines all 15 components', () {
      final theme = FlowCanvasTheme.light();
      expect(theme.background, isNotNull);
      expect(theme.node, isNotNull);
      expect(theme.edge, isNotNull);
      expect(theme.handle, isNotNull);
      expect(theme.selection, isNotNull);
      expect(theme.controls, isNotNull);
      expect(theme.button, isNotNull);
      expect(theme.minimap, isNotNull);
      expect(theme.connection, isNotNull);
      expect(theme.edgeLabel, isNotNull);
      expect(theme.edgeMarker, isNotNull);
      expect(theme.nodeResizer, isNotNull);
      expect(theme.panel, isNotNull);
      expect(theme.cursor, isNotNull);
      expect(theme.edgeReconnect, isNotNull);
    });

    test('dark() defines all 15 components', () {
      final theme = FlowCanvasTheme.dark();
      expect(theme.background, isNotNull);
      expect(theme.node, isNotNull);
      expect(theme.edge, isNotNull);
      expect(theme.handle, isNotNull);
      expect(theme.selection, isNotNull);
      expect(theme.controls, isNotNull);
      expect(theme.button, isNotNull);
      expect(theme.minimap, isNotNull);
      expect(theme.connection, isNotNull);
      expect(theme.edgeLabel, isNotNull);
      expect(theme.edgeMarker, isNotNull);
      expect(theme.nodeResizer, isNotNull);
      expect(theme.panel, isNotNull);
      expect(theme.cursor, isNotNull);
      expect(theme.edgeReconnect, isNotNull);
    });

    test('dark() differs from light()', () {
      final light = FlowCanvasTheme.light();
      final dark = FlowCanvasTheme.dark();
      expect(dark, isNot(light));
      expect(
        _decorationColor(dark.node?.decoration),
        isNot(_decorationColor(light.node?.decoration)),
      );
      expect(
        dark.background?.backgroundColor,
        isNot(light.background?.backgroundColor),
      );
    });

    test('light() and dark() are stable across instantiations', () {
      expect(FlowCanvasTheme.light(), FlowCanvasTheme.light());
      expect(FlowCanvasTheme.dark(), FlowCanvasTheme.dark());
    });
  });

  group('resolve', () {
    test('keeps provided components and fills nulls from fallback', () {
      final partial = FlowCanvasTheme(node: FlowNodeStyle.colored(color: Colors.red));
      final resolved = partial.resolve(FlowCanvasTheme.dark());

      expect(resolved.node?.decoration, partial.node?.decoration);
      expect(resolved.background, FlowCanvasTheme.dark().background);
      expect(resolved.edge, FlowCanvasTheme.dark().edge);
      expect(resolved.handle, FlowCanvasTheme.dark().handle);
    });

    test('defaults to light when no fallback is given', () {
      final resolved = FlowCanvasTheme(node: FlowNodeStyle.colored(color: Colors.red))
          .resolve();
      expect(resolved.background, FlowCanvasTheme.light().background);
      expect(resolved.node?.decoration, isNotNull);
    });

    test('resolve on a complete theme is a no-op', () {
      final dark = FlowCanvasTheme.dark();
      expect(dark.resolve(FlowCanvasTheme.light()), dark);
    });
  });

  group('merge', () {
    test('other wins, nulls inherit from this', () {
      final base = FlowCanvasTheme.dark();
      final variant = FlowCanvasTheme(node: FlowNodeStyle.colored(color: Colors.purple));
      final merged = base.merge(variant);

      expect(merged.node?.decoration, variant.node?.decoration);
      expect(merged.edge, base.edge);
      expect(merged.background, base.background);
      expect(merged.handle, base.handle);
    });

    test('merge(null) returns this', () {
      final theme = FlowCanvasTheme.light();
      expect(identical(theme.merge(null), theme), isTrue);
    });
  });

  group('copyWith', () {
    test('null params keep current values', () {
      final theme = FlowCanvasTheme.dark();
      final copy = theme.copyWith();
      expect(copy, theme);
    });

    test('non-null params replace', () {
      final theme = FlowCanvasTheme.light();
      final node = FlowNodeStyle.colored(color: Colors.blue);
      final copy = theme.copyWith(node: node);
      expect(copy.node?.decoration, node.decoration);
      expect(copy.background, theme.background);
    });
  });

  group('lerp', () {
    test('t=0 returns this and t=1 returns other', () {
      final light = FlowCanvasTheme.light();
      final dark = FlowCanvasTheme.dark();
      expect(light.lerp(dark, 0), light);
      expect(light.lerp(dark, 1), dark);
    });

    test('t=0.5 interpolates component colors', () {
      final light = FlowCanvasTheme.light();
      final dark = FlowCanvasTheme.dark();
      final mid = light.lerp(dark, 0.5);

      final lightColor = _decorationColor(light.node?.decoration);
      final darkColor = _decorationColor(dark.node?.decoration);
      final midColor = _decorationColor(mid.node?.decoration);
      expect(midColor, isNotNull);
      expect(midColor, isNot(lightColor));
      expect(midColor, isNot(darkColor));
    });

    test('lerp with non-FlowCanvasTheme returns this', () {
      final light = FlowCanvasTheme.light();
      expect(light.lerp(null, 0.5), light);
    });
  });

  group('factories', () {
    test('adaptive picks by brightness', () {
      expect(FlowCanvasTheme.adaptive(Brightness.dark), FlowCanvasTheme.dark());
      expect(
        FlowCanvasTheme.adaptive(Brightness.light),
        FlowCanvasTheme.light(),
      );
    });

    test('fromSeed produces a complete theme', () {
      final theme = FlowCanvasTheme.fromSeed(seedColor: Colors.purple);
      expect(theme.node, isNotNull);
      expect(theme.background, isNotNull);
      expect(theme.edge, isNotNull);
      expect(theme.connection, isNotNull);
      expect(theme.cursor, isNotNull);
      expect(theme.edgeReconnect, isNotNull);
    });

    test('fromColorScheme produces a complete theme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.teal);
      final theme = FlowCanvasTheme.fromColorScheme(scheme);
      expect(theme.node, isNotNull);
      expect(theme.minimap, isNotNull);
      expect(theme.selection, isNotNull);
      expect(theme.panel, isNotNull);
      expect(theme.controls, isNotNull);
      expect(theme.button, isNotNull);
      expect(theme.nodeResizer, isNotNull);
      expect(theme.edgeLabel, isNotNull);
      expect(theme.edgeMarker, isNotNull);
    });

    test('toThemeData embeds the theme and brightness', () {
      final data = FlowCanvasTheme.dark().toThemeData();
      expect(data.brightness, Brightness.dark);
      expect(data.extension<FlowCanvasTheme>(), FlowCanvasTheme.dark());
    });

    test('materialPair produces light and dark ThemeData', () {
      final pair = FlowCanvasTheme.materialPair();
      expect(pair.light.brightness, Brightness.light);
      expect(pair.dark.brightness, Brightness.dark);
      expect(
        pair.light.extension<FlowCanvasTheme>(),
        FlowCanvasTheme.light(),
      );
      expect(pair.dark.extension<FlowCanvasTheme>(), FlowCanvasTheme.dark());
    });
  });

  group('colored() factories', () {
    test('FlowNodeStyle.colored sets base, hover and selected', () {
      const red = Colors.red;
      const green = Colors.green;
      const blue = Colors.blue;
      final style = FlowNodeStyle.colored(
        color: red,
        hoverColor: green,
        selectedColor: blue,
      );

      expect(_decorationColor(style.decoration), red);
      expect(
        _decorationColor(style.resolveDecoration({FlowNodeState.hovered})),
        green,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowNodeState.selected})),
        blue,
      );
      expect(
        _decorationColor(style.resolveDecoration({})),
        red,
      );
    });

    test('FlowSelectionStyle.colored sets all fields', () {
      const c1 = Color(0x3300B8D9);
      const c2 = Color(0xFF00B8D9);
      final style = FlowSelectionStyle.colored(
        fillColor: c1,
        borderColor: c2,
        borderWidth: 3,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        dashLength: 8,
        gapLength: 5,
      );
      expect(style.fillColor, c1);
      expect(style.borderColor, c2);
      expect(style.borderWidth, 3);
      expect(style.borderRadius, const BorderRadius.all(Radius.circular(12)));
      expect(style.dashLength, 8);
      expect(style.gapLength, 5);
    });

    test('FlowMinimapStyle.colored derives viewport colors from node color', () {
      const nodeColor = Colors.purple;
      final style = FlowMinimapStyle.colored(nodeColor: nodeColor);
      expect(style.nodeColor, nodeColor);
      expect(style.selectedNodeColor, nodeColor);
      expect(style.disabledNodeColor, nodeColor);
      expect(style.viewportColor, nodeColor.withValues(alpha: 0.2));
    });

    test('FlowConnectionStyle.colored falls back to color for validity', () {
      const color = Colors.orange;
      final style = FlowConnectionStyle.colored(color: color, strokeWidth: 2.5);
      expect(style.activeDecoration.color, color);
      expect(style.validTargetDecoration?.color, color);
      expect(style.invalidTargetDecoration?.color, color);
      expect(style.activeDecoration.strokeWidth, 2.5);
      final valid = style.resolveStroke(ConnectionValidity.valid);
      final invalid = style.resolveStroke(ConnectionValidity.invalid);
      final none = style.resolveStroke(ConnectionValidity.none);
      expect(valid.color, color);
      expect(invalid.color, color);
      expect(none.color, color);
      expect(valid.strokeWidth, 2.5);
    });

    test('FlowEdgeReconnectStyle.colored sets all fields', () {
      const color = Colors.red;
      const borderColor = Colors.white;
      final style = FlowEdgeReconnectStyle.colored(
        color: color,
        borderColor: borderColor,
        borderWidth: 2,
      );
      expect(style.color, color);
      expect(style.borderColor, borderColor);
      expect(style.borderWidth, 2);
    });

    test('FlowEdgeStyle.colored + dashed produce resolved strokes', () {
      const color = Colors.teal;
      const selectedColor = Colors.amber;
      final style = FlowEdgeStyle.dashed(color: color, selectedColor: selectedColor);

      final normal = style.resolveDecoration({FlowEdgeState.normal});
      final selected = style.resolveDecoration({FlowEdgeState.selected});
      expect(normal.color, color);
      expect(selected.color, selectedColor);
      expect(selected.strokeWidth, greaterThanOrEqualTo(normal.strokeWidth));
    });

    test('FlowPanelStyle.colored resolves per state', () {
      const color = Colors.grey;
      const selectedColor = Colors.blue;
      final style = FlowPanelStyle.colored(color: color, selectedColor: selectedColor);
      expect(_decorationColor(style.resolveDecoration({FlowPanelState.normal})), color);
      expect(
        _decorationColor(style.resolveDecoration({FlowPanelState.selected})),
        selectedColor,
      );
    });
  });

  group('state resolvers', () {
    test('node: disabled > selected > hovered > normal', () {
      const normal = Colors.red;
      const hovered = Colors.green;
      const selected = Colors.blue;
      const disabled = Colors.grey;
      final style = FlowNodeStyle.colored(
        color: normal,
        hoverColor: hovered,
        selectedColor: selected,
        disabledColor: disabled,
      );

      expect(_decorationColor(style.resolveDecoration({FlowNodeState.disabled})), disabled);
      expect(
        _decorationColor(style.resolveDecoration({
          FlowNodeState.selected,
          FlowNodeState.disabled,
        })),
        disabled,
      );
      expect(
        _decorationColor(style.resolveDecoration({
          FlowNodeState.selected,
          FlowNodeState.hovered,
        })),
        selected,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowNodeState.hovered})),
        hovered,
      );
    });

    test('node: missing state decorations fall through', () {
      final style = FlowNodeStyle.colored(color: Colors.red);
      expect(
        _decorationColor(style.resolveDecoration({FlowNodeState.hovered})),
        Colors.red,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowNodeState.selected})),
        Colors.red,
      );
    });

    test('handle: invalidTarget beats validTarget beats selected', () {
      const normal = Colors.red;
      const hovered = Colors.green;
      const selected = Colors.blue;
      const valid = Colors.teal;
      const invalid = Colors.orange;
      final style = FlowHandleStyle.colored(
        color: normal,
        hoverColor: hovered,
        selectedColor: selected,
        validTargetColor: valid,
        invalidTargetColor: invalid,
      );

      expect(
        _decorationColor(style.resolveDecoration({FlowHandleState.invalidTarget})),
        invalid,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowHandleState.validTarget})),
        valid,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowHandleState.selected})),
        selected,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowHandleState.hovered})),
        hovered,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowHandleState.active})),
        hovered,
      );
    });

    test('controls button: disabled dims, selected wins', () {
      const normal = Colors.white;
      const hovered = Colors.grey;
      const selected = Colors.blue;
      const disabled = Colors.black;
      final style = FlowControlsButtonStyle.colored(
        buttonColor: normal,
        hoverColor: hovered,
        selectedColor: selected,
        disabledColor: disabled,
        iconColor: Colors.black,
        disabledIconColor: Colors.grey,
      );

      final disabledDecoration = style.resolveDecoration({FlowControlState.disabled});
      expect(_decorationColor(disabledDecoration), disabled);
      expect(
        _decorationColor(style.resolveDecoration({FlowControlState.selected})),
        selected,
      );
      expect(
        _decorationColor(style.resolveDecoration({FlowControlState.hovered})),
        hovered,
      );

      final normalIcon = style.resolveIconTheme({FlowControlState.normal});
      final disabledIcon = style.resolveIconTheme({FlowControlState.disabled});
      expect(normalIcon.color, isNotNull);
      expect(disabledIcon.color, isNot(normalIcon.color));
    });

    test('minimap: resolveNodeColor by state', () {
      const nodeColor = Colors.red;
      const selectedNodeColor = Colors.blue;
      const disabledNodeColor = Colors.grey;
      final style = FlowMinimapStyle.colored(
        nodeColor: nodeColor,
        selectedNodeColor: selectedNodeColor,
        disabledNodeColor: disabledNodeColor,
      );

      expect(style.resolveNodeColor({MinimapNodeState.normal}), nodeColor);
      expect(
        style.resolveNodeColor({MinimapNodeState.selected}),
        selectedNodeColor,
      );
      expect(
        style.resolveNodeColor({MinimapNodeState.disabled}),
        disabledNodeColor,
      );
    });

    test('node resizer: active wins over hovered', () {
      const color = Colors.red;
      const hovered = Colors.green;
      const active = Colors.blue;
      final style = FlowNodeResizerStyle.colored(
        color: color,
        hoverColor: hovered,
        activeColor: active,
      );

      expect(style.resolveColor({FlowNodeResizerState.normal}), color);
      expect(style.resolveColor({FlowNodeResizerState.hovered}), hovered);
      expect(style.resolveColor({FlowNodeResizerState.active}), active);
      expect(
        style.resolveColor({FlowNodeResizerState.active, FlowNodeResizerState.hovered}),
        active,
      );
    });

    test('edge label: resolveTextStyle and resolveDecoration', () {
      const color = Colors.red;
      const selectedColor = Colors.blue;
      final style = FlowEdgeLabelStyle.text(
        color: color,
        selectedColor: selectedColor,
      );

      expect(
        style.resolveTextStyle({FlowEdgeState.selected}).color,
        selectedColor,
      );
      expect(style.resolveTextStyle({FlowEdgeState.normal}).color, color);
      expect(
        _decorationColor(style.resolveDecoration({FlowEdgeState.selected})),
        Colors.transparent,
      );
      expect(
        style.resolveTextStyle({
          FlowEdgeState.selected,
          FlowEdgeState.hovered,
        }).color,
        selectedColor,
      );
    });

    test('edge marker: resolve produces decoration', () {
      final style = FlowEdgeMarkerStyle.colored(color: Colors.red);
      final resolved = style.resolve({FlowEdgeState.normal});
      expect(resolved, isA<FlowMarkerDecoration>());
      expect(resolved.color, Colors.red);
      expect(resolved.strokeWidth, greaterThan(0));
    });

    test('edge reconnect: resolves to base color', () {
      final style = FlowEdgeReconnectStyle.colored(
        color: Colors.orange,
        borderColor: Colors.white,
      );
      expect(style.color, Colors.orange);
    });

    test('cursor: resolves all interaction zones', () {
      const style = FlowCursorStyle();
      expect(style.resolvePane(), isA<MouseCursor>());
      expect(
        style.resolveNode(selectable: true, draggable: true),
        isA<MouseCursor>(),
      );
      expect(
        style.resolveResizer(Alignment.topRight),
        isA<MouseCursor>(),
      );
      expect(style.resolveControl(enabled: true), isA<MouseCursor>());
      expect(style.resolveControl(enabled: false), isA<MouseCursor>());
    });

    test('connection: invalid and valid validity produce different colors', () {
      const color = Colors.red;
      const valid = Colors.green;
      const invalid = Colors.orange;
      final style = FlowConnectionStyle.colored(
        color: color,
        validColor: valid,
        invalidColor: invalid,
      );

      expect(style.resolveStroke(ConnectionValidity.valid).color, valid);
      expect(style.resolveStroke(ConnectionValidity.invalid).color, invalid);
      expect(style.resolveStroke(ConnectionValidity.none).color, color);
    });
  });

  group('component merge', () {
    test('node merge: other wins, nulls inherit', () {
      const red = Colors.red;
      const blue = Colors.blue;
      const green = Colors.green;
      final base = FlowNodeStyle.colored(color: red, hoverColor: green);
      final variant = FlowNodeStyle.colored(color: blue);

      final merged = base.merge(variant);
      expect(_decorationColor(merged.decoration), blue);
      expect(
        _decorationColor(merged.resolveDecoration({FlowNodeState.hovered})),
        green,
      );
    });

    test('edge merge: other wins, nulls inherit', () {
      const red = Colors.red;
      const blue = Colors.blue;
      final base = FlowEdgeStyle.colored(color: red);
      final variant = FlowEdgeStyle.colored(color: blue);
      final merged = base.merge(variant);
      expect(merged.resolveDecoration({FlowEdgeState.normal}).color, blue);
    });
  });
}