import 'package:flutter/widgets.dart';

import 'edge_layer.dart';

/// Paint-ready style for default node bodies.
///
/// Plain const value class: paint values only, no behavior.
@immutable
class LatticeNodeStyle {
  const LatticeNodeStyle({
    required this.background,
    required this.border,
    this.borderWidth = 1,
    this.borderRadius = 4,
    required this.selectedBorder,
    this.selectedBorderWidth = 2,
  });

  final Color background;
  final Color border;
  final double borderWidth;
  final double borderRadius;
  final Color selectedBorder;
  final double selectedBorderWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeNodeStyle &&
        other.background == background &&
        other.border == border &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.selectedBorder == selectedBorder &&
        other.selectedBorderWidth == selectedBorderWidth;
  }

  @override
  int get hashCode => Object.hash(
        background,
        border,
        borderWidth,
        borderRadius,
        selectedBorder,
        selectedBorderWidth,
      );
}

/// Paint-ready style for connection handle dots.
@immutable
class LatticeHandleStyle {
  const LatticeHandleStyle({
    required this.fill,
    required this.border,
    this.size = 8,
  });

  /// Dot fill.
  final Color fill;

  /// Dot ring (border) color.
  final Color border;

  /// Dot diameter in logical px.
  final double size;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeHandleStyle &&
        other.fill == fill &&
        other.border == border &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(fill, border, size);
}

/// Paint-ready style for the canvas background pattern.
@immutable
class LatticeBackgroundStyle {
  const LatticeBackgroundStyle({
    required this.dotColor,
    required this.lineColor,
    required this.dotRadius,
  });

  final Color dotColor;
  final Color lineColor;
  final double dotRadius;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeBackgroundStyle &&
        other.dotColor == dotColor &&
        other.lineColor == lineColor &&
        other.dotRadius == dotRadius;
  }

  @override
  int get hashCode => Object.hash(dotColor, lineColor, dotRadius);
}

/// Paint-ready style for the [LatticeMinimap] overlay.
@immutable
class LatticeMinimapStyle {
  const LatticeMinimapStyle({
    required this.background,
    required this.node,
    required this.viewport,
    required this.viewportWidth,
  });

  /// Minimap surface fill; a transparent value paints nothing visible.
  final Color background;

  /// Node rect fill.
  final Color node;

  /// Viewport outline color.
  final Color viewport;

  /// Viewport outline stroke width.
  final double viewportWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeMinimapStyle &&
        other.background == background &&
        other.node == node &&
        other.viewport == viewport &&
        other.viewportWidth == viewportWidth;
  }

  @override
  int get hashCode => Object.hash(background, node, viewport, viewportWidth);
}

/// Paint-ready style for the selection chrome (marquee + resize handles).
///
/// The marquee rect painter is not shipped yet; the resizer overlay consumes
/// the node-accent colors, so this value class currently carries the marquee
/// paint values for the future overlay.
@immutable
class LatticeSelectionStyle {
  const LatticeSelectionStyle({
    required this.fill,
    required this.stroke,
    required this.strokeWidth,
    required this.dashLength,
    required this.gapLength,
  });

  final Color fill;
  final Color stroke;
  final double strokeWidth;
  final double dashLength;
  final double gapLength;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeSelectionStyle &&
        other.fill == fill &&
        other.stroke == stroke &&
        other.strokeWidth == strokeWidth &&
        other.dashLength == dashLength &&
        other.gapLength == gapLength;
  }

  @override
  int get hashCode =>
      Object.hash(fill, stroke, strokeWidth, dashLength, gapLength);
}

/// Paint-ready style for the in-progress connection preview line.
///
/// Minimal by design: the preview line itself ships later.
@immutable
class LatticeConnectionStyle {
  const LatticeConnectionStyle({
    required this.color,
    required this.width,
  });

  final Color color;
  final double width;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeConnectionStyle &&
        other.color == color &&
        other.width == width;
  }

  @override
  int get hashCode => Object.hash(color, width);
}

/// Complete or partial paint theme for a lattice canvas.
///
/// Every component is optional: a theme with only some components set is a
/// PARTIAL theme. [merge] applies the overlay's set components and keeps the
/// base values for every component the overlay leaves null — a partial
/// overlay never resets unset fields.
///
/// Widgets read the theme from the nearest [LatticeThemeScope]; components a
/// theme leaves unset resolve to their light values via the `resolved*`
/// getters (also the fallback when no scope is present).
@immutable
class LatticeTheme {
  const LatticeTheme({
    this.node,
    this.edge,
    this.handle,
    this.background,
    this.minimap,
    this.selection,
    this.connection,
  });

  final LatticeNodeStyle? node;
  final LatticeEdgeStyle? edge;
  final LatticeHandleStyle? handle;
  final LatticeBackgroundStyle? background;
  final LatticeMinimapStyle? minimap;
  final LatticeSelectionStyle? selection;
  final LatticeConnectionStyle? connection;

  /// The default light theme. Every component is defined and matches the
  /// widget fallback visuals.
  static LatticeTheme light() => _light;

  /// The dark theme. Every component is defined.
  static LatticeTheme dark() => _dark;

  static const LatticeNodeStyle _lightNode = LatticeNodeStyle(
    background: Color(0xFFFFFFFF),
    border: Color(0xFF94A3B8),
    borderRadius: 8,
    selectedBorder: Color(0xFF2563EB),
  );
  static const LatticeEdgeStyle _lightEdge = LatticeEdgeStyle();
  static const LatticeHandleStyle _lightHandle = LatticeHandleStyle(
    fill: Color(0xFF64748B),
    border: Color(0xFFFFFFFF),
  );
  static const LatticeBackgroundStyle _lightBackground = LatticeBackgroundStyle(
    dotColor: Color(0xFFE2E8F0),
    lineColor: Color(0xFFF1F5F9),
    dotRadius: 1.5,
  );
  static const LatticeMinimapStyle _lightMinimap = LatticeMinimapStyle(
    background: Color(0x00000000),
    node: Color(0xFFCBD5E1),
    viewport: Color(0xFF64748B),
    viewportWidth: 1.5,
  );
  static const LatticeSelectionStyle _lightSelection = LatticeSelectionStyle(
    fill: Color(0x1A2563EB),
    stroke: Color(0xFF2563EB),
    strokeWidth: 1.0,
    dashLength: 6.0,
    gapLength: 4.0,
  );
  static const LatticeConnectionStyle _lightConnection = LatticeConnectionStyle(
    color: Color(0xFF2563EB),
    width: 2.0,
  );

  static const LatticeNodeStyle _darkNode = LatticeNodeStyle(
    background: Color(0xFF1E293B),
    border: Color(0xFF475569),
    borderRadius: 8,
    selectedBorder: Color(0xFF60A5FA),
  );
  static const LatticeEdgeStyle _darkEdge = LatticeEdgeStyle(
    color: Color(0xFF94A3B8),
    selectedColor: Color(0xFF60A5FA),
  );
  static const LatticeHandleStyle _darkHandle = LatticeHandleStyle(
    fill: Color(0xFF94A3B8),
    border: Color(0xFF1E293B),
  );
  static const LatticeBackgroundStyle _darkBackground = LatticeBackgroundStyle(
    dotColor: Color(0xFF334155),
    lineColor: Color(0xFF1E293B),
    dotRadius: 1.5,
  );
  static const LatticeMinimapStyle _darkMinimap = LatticeMinimapStyle(
    background: Color(0xFF0F172A),
    node: Color(0xFF475569),
    viewport: Color(0xFF94A3B8),
    viewportWidth: 1.5,
  );
  static const LatticeSelectionStyle _darkSelection = LatticeSelectionStyle(
    fill: Color(0x3360A5FA),
    stroke: Color(0xFF60A5FA),
    strokeWidth: 1.0,
    dashLength: 6.0,
    gapLength: 4.0,
  );
  static const LatticeConnectionStyle _darkConnection = LatticeConnectionStyle(
    color: Color(0xFF60A5FA),
    width: 2.0,
  );

  static const LatticeTheme _light = LatticeTheme(
    node: _lightNode,
    edge: _lightEdge,
    handle: _lightHandle,
    background: _lightBackground,
    minimap: _lightMinimap,
    selection: _lightSelection,
    connection: _lightConnection,
  );

  static const LatticeTheme _dark = LatticeTheme(
    node: _darkNode,
    edge: _darkEdge,
    handle: _darkHandle,
    background: _darkBackground,
    minimap: _darkMinimap,
    selection: _darkSelection,
    connection: _darkConnection,
  );

  /// This theme with [overlay]'s set components applied. Null [overlay]
  /// returns this theme; null overlay fields keep the base value.
  LatticeTheme merge(LatticeTheme? overlay) {
    if (overlay == null) return this;
    return LatticeTheme(
      node: overlay.node ?? node,
      edge: overlay.edge ?? edge,
      handle: overlay.handle ?? handle,
      background: overlay.background ?? background,
      minimap: overlay.minimap ?? minimap,
      selection: overlay.selection ?? selection,
      connection: overlay.connection ?? connection,
    );
  }

  /// [node] resolved against the light default when unset.
  LatticeNodeStyle get resolvedNode => node ?? _lightNode;

  /// [edge] resolved against the light default when unset.
  LatticeEdgeStyle get resolvedEdge => edge ?? _lightEdge;

  /// [handle] resolved against the light default when unset.
  LatticeHandleStyle get resolvedHandle => handle ?? _lightHandle;

  /// [background] resolved against the light default when unset.
  LatticeBackgroundStyle get resolvedBackground => background ?? _lightBackground;

  /// [minimap] resolved against the light default when unset.
  LatticeMinimapStyle get resolvedMinimap => minimap ?? _lightMinimap;

  /// [selection] resolved against the light default when unset.
  LatticeSelectionStyle get resolvedSelection => selection ?? _lightSelection;

  /// [connection] resolved against the light default when unset.
  LatticeConnectionStyle get resolvedConnection =>
      connection ?? _lightConnection;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeTheme &&
        other.node == node &&
        other.edge == edge &&
        other.handle == handle &&
        other.background == background &&
        other.minimap == minimap &&
        other.selection == selection &&
        other.connection == connection;
  }

  @override
  int get hashCode => Object.hash(
        node,
        edge,
        handle,
        background,
        minimap,
        selection,
        connection,
      );
}

/// Exposes a [LatticeTheme] to the canvas subtree.
///
/// [LatticeCanvas] provides the scope around every layer; widgets read it
/// through [maybeOf] so they can be mounted standalone (tests, custom hosts)
/// with a light-theme fallback.
class LatticeThemeScope extends InheritedWidget {
  const LatticeThemeScope({
    super.key,
    required this.theme,
    required super.child,
  });

  final LatticeTheme theme;

  /// Returns the nearest theme, asserting in debug builds when no
  /// [LatticeThemeScope] is present. Prefer [maybeOf] for fallback support.
  static LatticeTheme of(BuildContext context) {
    final LatticeThemeScope? scope =
        context.dependOnInheritedWidgetOfExactType<LatticeThemeScope>();
    assert(
      scope != null,
      'LatticeThemeScope.of() called outside a LatticeThemeScope subtree. '
      'Place the caller under a LatticeCanvas or use maybeOf() for the '
      'light-theme fallback.',
    );
    return scope!.theme;
  }

  /// Returns the nearest theme, or null when no scope is present.
  static LatticeTheme? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<LatticeThemeScope>()
        ?.theme;
  }

  @override
  bool updateShouldNotify(LatticeThemeScope oldWidget) =>
      theme != oldWidget.theme;
}
