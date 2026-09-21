import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the possible states of a node within the minimap.
enum MinimapNodeState { normal, selected, disabled }

/// Defines the visual styling for the flow canvas minimap.
///
/// The minimap provides a bird's-eye view of the entire canvas with:
/// - Background and mask styling for the container
/// - Node representation with normal and selected states
/// - Viewport indicator showing the current visible area
/// - Customizable borders, shadows, and glow effects
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowMinimapStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowMinimapStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowMinimapStyle;
/// final nodeColor = style.resolveNodeColor({MinimapNodeState.selected});
/// ```
///
/// ## Examples
///
/// ```
/// // Basic usage with defaults
/// FlowMinimapStyle()
///
/// // Custom colors
/// FlowMinimapStyle(
///   backgroundColor: Colors.white,
///   nodeColor: Colors.blue,
///   selectedNodeColor: Colors.orange,
///   viewportColor: Colors.blue.withValues(alpha: 0.2),
/// )
///
/// // From Material 3 color scheme
/// FlowMinimapStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// )
///
/// // Adaptive to system theme
/// FlowMinimapStyle.system(context)
/// ```
@immutable
class FlowMinimapStyle extends ThemeExtension<FlowMinimapStyle>
    with Diagnosticable {
  // ============================================================================
  // Overall minimap container styling
  // ============================================================================
  //
  // Every field is nullable: `null` means "inherit from the layer below"
  // (global theme) when merged, and falls back to the documented default via
  // the `effectiveX` getters when resolved. This lets a partial override
  // (e.g. `FlowMinimapStyle(nodeColor: red)`) change only what it sets instead
  // of resetting the whole style — matching React Flow's CSS-inheritance model
  // and the repo's "other wins, nulls inherit" merge contract.

  /// Padding inside the minimap container. Falls back to `0`.
  final double? padding;

  /// Background color of the minimap container. Falls back to white.
  final Color? backgroundColor;

  /// Color of the mask overlay (areas outside nodes).
  ///
  /// Typically semi-transparent to dim non-node areas. Falls back to
  /// `#99F0F2F5`.
  final Color? maskColor;

  /// Stroke color for the mask border. Falls back to `#9E9E9E`.
  final Color? maskStrokeColor;

  /// Width of the mask stroke. Falls back to `1.0`.
  final double? maskStrokeWidth;

  /// Border radius for the minimap container. Falls back to a 8px radius.
  final BorderRadius? borderRadius;

  /// Shadow effects for the minimap container.
  ///
  /// Provides depth and elevation to the minimap. Falls back to a single
  /// subtle drop shadow.
  final List<BoxShadow>? shadows;

  // ============================================================================
  // Node styling within the minimap
  // ============================================================================

  /// Color of nodes in their normal state. Falls back to `#2196F3`.
  final Color? nodeColor;

  /// Color of nodes when selected.
  ///
  /// Should contrast with [nodeColor] for clear visual distinction. Falls
  /// back to `#FF9800`.
  final Color? selectedNodeColor;

  /// Color of nodes when disabled (`selectable: false`). Falls back to
  /// `#BDBDBD`.
  final Color? disabledNodeColor;

  /// Stroke color for node borders. Falls back to `#1976D2`.
  final Color? nodeStrokeColor;

  /// Width of node strokes. Falls back to `1.0`.
  final double? nodeStrokeWidth;

  /// Border radius for nodes in the minimap. Falls back to a 2px radius.
  final BorderRadius? nodeBorderRadius;

  // ============================================================================
  // Viewport indicator styling
  // ============================================================================

  /// Fill color of the viewport rectangle.
  ///
  /// Typically semi-transparent to show underlying nodes. Falls back to
  /// `#332196F3`.
  final Color? viewportColor;

  /// Border color of the viewport rectangle. Falls back to `#2196F3`.
  final Color? viewportBorderColor;

  /// Width of the viewport border stroke. Falls back to `1.5`.
  final double? viewportBorderWidth;

  /// Glow color around the viewport (for emphasis).
  ///
  /// Set to transparent to disable glow effect. Falls back to transparent.
  final Color? viewportGlowColor;

  /// Blur radius of the viewport glow effect. Falls back to `4.0`.
  final double? viewportGlowBlur;

  /// Border radius for the viewport rectangle. Falls back to a 2px radius.
  final BorderRadius? viewportBorderRadius;

  const FlowMinimapStyle({
    this.padding,
    this.backgroundColor,
    this.maskColor,
    this.maskStrokeColor,
    this.maskStrokeWidth,
    this.borderRadius,
    this.shadows,
    this.nodeColor,
    this.selectedNodeColor,
    this.disabledNodeColor,
    this.nodeStrokeColor,
    this.nodeStrokeWidth,
    this.nodeBorderRadius,
    this.viewportColor,
    this.viewportBorderColor,
    this.viewportBorderWidth,
    this.viewportGlowColor,
    this.viewportGlowBlur,
    this.viewportBorderRadius,
  });

  // Resolved values (cascade fallback). Consumers read these, never the raw
  // nullable fields, so an unset field always paints its documented default.
  double get effectivePadding => padding ?? 0;
  Color get effectiveBackgroundColor => backgroundColor ?? Colors.white;
  Color get effectiveMaskColor => maskColor ?? const Color(0x99F0F2F5);
  Color get effectiveMaskStrokeColor =>
      maskStrokeColor ?? const Color(0xFF9E9E9E);
  double get effectiveMaskStrokeWidth => maskStrokeWidth ?? 1.0;
  BorderRadius get effectiveBorderRadius =>
      borderRadius ?? const BorderRadius.all(Radius.circular(8.0));
  List<BoxShadow> get effectiveShadows =>
      shadows ??
      const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))];
  Color get effectiveNodeColor => nodeColor ?? const Color(0xFF2196F3);
  Color get effectiveSelectedNodeColor =>
      selectedNodeColor ?? const Color(0xFFFF9800);
  Color get effectiveDisabledNodeColor =>
      disabledNodeColor ?? const Color(0xFFBDBDBD);
  Color get effectiveNodeStrokeColor =>
      nodeStrokeColor ?? const Color(0xFF1976D2);
  double get effectiveNodeStrokeWidth => nodeStrokeWidth ?? 1.0;
  BorderRadius get effectiveNodeBorderRadius =>
      nodeBorderRadius ?? const BorderRadius.all(Radius.circular(2.0));
  Color get effectiveViewportColor => viewportColor ?? const Color(0x332196F3);
  Color get effectiveViewportBorderColor =>
      viewportBorderColor ?? const Color(0xFF2196F3);
  double get effectiveViewportBorderWidth => viewportBorderWidth ?? 1.5;
  Color get effectiveViewportGlowColor =>
      viewportGlowColor ?? Colors.transparent;
  double get effectiveViewportGlowBlur => viewportGlowBlur ?? 4.0;
  BorderRadius get effectiveViewportBorderRadius =>
      viewportBorderRadius ?? const BorderRadius.all(Radius.circular(2.0));

  /// Creates a minimap style from simple color values.
  ///
  /// Node-related colors default to [nodeColor]; viewport colors derive
  /// from it (semi-transparent fill, full-opacity border).
  factory FlowMinimapStyle.colored({
    required Color nodeColor,
    Color? selectedNodeColor,
    Color? disabledNodeColor,
    Color? nodeStrokeColor,
    double? nodeStrokeWidth,
    Color? backgroundColor,
    Color? maskColor,
    Color? maskStrokeColor,
    double? maskStrokeWidth,
    Color? viewportColor,
    Color? viewportBorderColor,
    double? viewportBorderWidth,
    Color? viewportGlowColor,
    double? viewportGlowBlur,
    BorderRadius? borderRadius,
    BorderRadius? nodeBorderRadius,
    BorderRadius? viewportBorderRadius,
    List<BoxShadow>? shadows,
    double? padding,
  }) {
    // Only `nodeColor` (and the palette derived from it) is forced. Every
    // other unset field stays null so it inherits on merge and falls back to
    // its documented default via the `effectiveX` getters when standalone.
    return FlowMinimapStyle(
      padding: padding,
      backgroundColor: backgroundColor,
      maskColor: maskColor,
      maskStrokeColor: maskStrokeColor,
      maskStrokeWidth: maskStrokeWidth,
      borderRadius: borderRadius,
      shadows: shadows,
      nodeColor: nodeColor,
      selectedNodeColor: selectedNodeColor ?? nodeColor,
      disabledNodeColor: disabledNodeColor ?? nodeColor,
      nodeStrokeColor: nodeStrokeColor ?? nodeColor,
      nodeStrokeWidth: nodeStrokeWidth,
      nodeBorderRadius: nodeBorderRadius,
      viewportColor: viewportColor ?? nodeColor.withValues(alpha: 0.2),
      viewportBorderColor: viewportBorderColor ?? nodeColor,
      viewportBorderWidth: viewportBorderWidth,
      viewportGlowColor: viewportGlowColor,
      viewportGlowBlur: viewportGlowBlur,
      viewportBorderRadius: viewportBorderRadius,
    );
  }

  /// Creates a light theme minimap style.
  ///
  /// The area outside the viewport is masked with `#e2e2e2`-rendered gray
  /// (`rgba(207,207,207,0.6)` over white) so it stays distinct from the
  /// canvas; nodes are drawn lighter (`#f7f7f7`), selected `#b1b1b7`,
  /// disabled blends into the mask. Viewport: `#fff` fill with `#f0f0f0`
  /// 1px border, no shadows.
  factory FlowMinimapStyle.light() {
    return const FlowMinimapStyle(
      backgroundColor: Colors.white,
      maskColor: Color(0x99CFCFCF),
      maskStrokeColor: Colors.transparent,
      borderRadius: BorderRadius.zero,
      nodeColor: Color(0xFFF7F7F7),
      selectedNodeColor: Color(0xFFB1B1B7),
      disabledNodeColor: Color(0xFFE2E2E2),
      nodeStrokeColor: Colors.transparent,
      nodeStrokeWidth: 2.0,
      viewportColor: Colors.white,
      viewportBorderColor: Color(0xFFF0F0F0),
      viewportBorderWidth: 1.0,
      viewportGlowColor: Colors.transparent,
      viewportBorderRadius: BorderRadius.zero,
      shadows: [],
    );
  }

  /// Creates a dark theme minimap style.
  ///
  /// The area outside the viewport is masked with `#2b2b2b`-rendered gray
  /// (`rgba(58,58,58,0.6)` over `#141414`) so it stays distinct from the
  /// canvas; nodes are drawn lighter (`#4a4a4a`), selected `#5b5b5b`,
  /// disabled blends into the mask. Viewport: transparent fill with `#555`
  /// 1px border, no shadows.
  factory FlowMinimapStyle.dark() {
    return const FlowMinimapStyle(
      backgroundColor: Color(0xFF141414),
      maskColor: Color(0x993A3A3A),
      maskStrokeColor: Colors.transparent,
      borderRadius: BorderRadius.zero,
      nodeColor: Color(0xFF4A4A4A),
      selectedNodeColor: Color(0xFF5B5B5B),
      disabledNodeColor: Color(0xFF2B2B2B),
      nodeStrokeColor: Colors.transparent,
      nodeStrokeWidth: 2.0,
      viewportColor: Colors.transparent,
      viewportBorderColor: Color(0xFF555555),
      viewportBorderWidth: 1.0,
      viewportGlowColor: Colors.transparent,
      viewportBorderRadius: BorderRadius.zero,
      shadows: [],
    );
  }

  /// Creates a minimap style that adapts to the system brightness.
  ///
  /// Automatically selects [light] or [dark] based on the current theme.
  factory FlowMinimapStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowMinimapStyle.dark()
        : FlowMinimapStyle.light();
  }

  /// Creates a minimap style from a Material 3 color scheme.
  ///
  /// Uses semantic colors from the color scheme for consistent theming
  /// across your application.
  factory FlowMinimapStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowMinimapStyle(
      backgroundColor: colorScheme.surfaceContainerLow,
      maskColor: colorScheme.scrim.withValues(alpha: 0.6),
      maskStrokeColor: colorScheme.outline,
      nodeColor: colorScheme.primary,
      selectedNodeColor: colorScheme.tertiary,
      disabledNodeColor: colorScheme.onSurface.withValues(alpha: 0.38),
      nodeStrokeColor: colorScheme.primaryContainer,
      viewportColor: colorScheme.primary.withValues(alpha: 0.2),
      viewportBorderColor: colorScheme.primary,
      viewportGlowColor: colorScheme.primary.withValues(alpha: 0.15),
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Creates a minimap style from a seed color using Material 3 guidelines.
  ///
  /// Generates a harmonious color scheme from a single seed color.
  factory FlowMinimapStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowMinimapStyle.fromColorScheme(colorScheme);
  }

  /// Creates a minimap style from a Flutter [ThemeData].
  factory FlowMinimapStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowMinimapStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowMinimapStyle.dark()
        : FlowMinimapStyle.light();
  }

  /// Resolves the node color based on its state.
  ///
  /// Priority: disabled > selected > normal.
  Color resolveNodeColor(Set<MinimapNodeState> states) {
    if (states.contains(MinimapNodeState.disabled)) {
      return effectiveDisabledNodeColor;
    }
    if (states.contains(MinimapNodeState.selected)) {
      return effectiveSelectedNodeColor;
    }
    return effectiveNodeColor;
  }

  /// Merges this (parent) style with [other] (child).
  ///
  /// Each field follows "other wins, nulls inherit": a field the child leaves
  /// null keeps the parent's value, so a partial override
  /// (e.g. `FlowMinimapStyle(nodeColor: red)`) changes only what it sets.
  FlowMinimapStyle merge(FlowMinimapStyle? other) {
    if (other == null) return this;
    return FlowMinimapStyle(
      padding: other.padding ?? padding,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      maskColor: other.maskColor ?? maskColor,
      maskStrokeColor: other.maskStrokeColor ?? maskStrokeColor,
      maskStrokeWidth: other.maskStrokeWidth ?? maskStrokeWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadows: other.shadows ?? shadows,
      nodeColor: other.nodeColor ?? nodeColor,
      selectedNodeColor: other.selectedNodeColor ?? selectedNodeColor,
      disabledNodeColor: other.disabledNodeColor ?? disabledNodeColor,
      nodeStrokeColor: other.nodeStrokeColor ?? nodeStrokeColor,
      nodeStrokeWidth: other.nodeStrokeWidth ?? nodeStrokeWidth,
      nodeBorderRadius: other.nodeBorderRadius ?? nodeBorderRadius,
      viewportColor: other.viewportColor ?? viewportColor,
      viewportBorderColor: other.viewportBorderColor ?? viewportBorderColor,
      viewportBorderWidth: other.viewportBorderWidth ?? viewportBorderWidth,
      viewportGlowColor: other.viewportGlowColor ?? viewportGlowColor,
      viewportGlowBlur: other.viewportGlowBlur ?? viewportGlowBlur,
      viewportBorderRadius:
          other.viewportBorderRadius ?? viewportBorderRadius,
    );
  }

  @override
  FlowMinimapStyle copyWith({
    double? padding,
    Color? backgroundColor,
    Color? maskColor,
    Color? maskStrokeColor,
    double? maskStrokeWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
    Color? nodeColor,
    Color? selectedNodeColor,
    Color? disabledNodeColor,
    Color? nodeStrokeColor,
    double? nodeStrokeWidth,
    BorderRadius? nodeBorderRadius,
    Color? viewportColor,
    Color? viewportBorderColor,
    double? viewportBorderWidth,
    Color? viewportGlowColor,
    double? viewportGlowBlur,
    BorderRadius? viewportBorderRadius,
  }) {
    return FlowMinimapStyle(
      padding: padding ?? this.padding,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      maskColor: maskColor ?? this.maskColor,
      maskStrokeColor: maskStrokeColor ?? this.maskStrokeColor,
      maskStrokeWidth: maskStrokeWidth ?? this.maskStrokeWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadows: shadows ?? this.shadows,
      nodeColor: nodeColor ?? this.nodeColor,
      selectedNodeColor: selectedNodeColor ?? this.selectedNodeColor,
      disabledNodeColor: disabledNodeColor ?? this.disabledNodeColor,
      nodeStrokeColor: nodeStrokeColor ?? this.nodeStrokeColor,
      nodeStrokeWidth: nodeStrokeWidth ?? this.nodeStrokeWidth,
      nodeBorderRadius: nodeBorderRadius ?? this.nodeBorderRadius,
      viewportColor: viewportColor ?? this.viewportColor,
      viewportBorderColor: viewportBorderColor ?? this.viewportBorderColor,
      viewportBorderWidth: viewportBorderWidth ?? this.viewportBorderWidth,
      viewportGlowColor: viewportGlowColor ?? this.viewportGlowColor,
      viewportGlowBlur: viewportGlowBlur ?? this.viewportGlowBlur,
      viewportBorderRadius: viewportBorderRadius ?? this.viewportBorderRadius,
    );
  }

  @override
  FlowMinimapStyle lerp(
    covariant ThemeExtension<FlowMinimapStyle>? other,
    double t,
  ) {
    if (other is! FlowMinimapStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowMinimapStyle(
      padding: lerpDouble(padding, other.padding, t) ?? padding,
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t) ??
          backgroundColor,
      maskColor: Color.lerp(maskColor, other.maskColor, t) ?? maskColor,
      maskStrokeColor: Color.lerp(maskStrokeColor, other.maskStrokeColor, t) ??
          maskStrokeColor,
      maskStrokeWidth: lerpDouble(maskStrokeWidth, other.maskStrokeWidth, t) ??
          maskStrokeWidth,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
          borderRadius,
      shadows: BoxShadow.lerpList(shadows, other.shadows, t) ?? shadows,
      nodeColor: Color.lerp(nodeColor, other.nodeColor, t) ?? nodeColor,
      selectedNodeColor:
          Color.lerp(selectedNodeColor, other.selectedNodeColor, t) ??
              selectedNodeColor,
      disabledNodeColor:
          Color.lerp(disabledNodeColor, other.disabledNodeColor, t) ??
              disabledNodeColor,
      nodeStrokeColor: Color.lerp(nodeStrokeColor, other.nodeStrokeColor, t) ??
          nodeStrokeColor,
      nodeStrokeWidth: lerpDouble(nodeStrokeWidth, other.nodeStrokeWidth, t) ??
          nodeStrokeWidth,
      nodeBorderRadius:
          BorderRadius.lerp(nodeBorderRadius, other.nodeBorderRadius, t) ??
              nodeBorderRadius,
      viewportColor:
          Color.lerp(viewportColor, other.viewportColor, t) ?? viewportColor,
      viewportBorderColor:
          Color.lerp(viewportBorderColor, other.viewportBorderColor, t) ??
              viewportBorderColor,
      viewportBorderWidth:
          lerpDouble(viewportBorderWidth, other.viewportBorderWidth, t) ??
              viewportBorderWidth,
      viewportGlowColor:
          Color.lerp(viewportGlowColor, other.viewportGlowColor, t) ??
              viewportGlowColor,
      viewportGlowBlur:
          lerpDouble(viewportGlowBlur, other.viewportGlowBlur, t) ??
              viewportGlowBlur,
      viewportBorderRadius: BorderRadius.lerp(
              viewportBorderRadius, other.viewportBorderRadius, t) ??
          viewportBorderRadius,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowMinimapStyle &&
        other.padding == padding &&
        other.backgroundColor == backgroundColor &&
        other.maskColor == maskColor &&
        other.maskStrokeColor == maskStrokeColor &&
        other.maskStrokeWidth == maskStrokeWidth &&
        other.borderRadius == borderRadius &&
        listEquals(other.shadows, shadows) &&
        other.nodeColor == nodeColor &&
        other.selectedNodeColor == selectedNodeColor &&
        other.disabledNodeColor == disabledNodeColor &&
        other.nodeStrokeColor == nodeStrokeColor &&
        other.nodeStrokeWidth == nodeStrokeWidth &&
        other.nodeBorderRadius == nodeBorderRadius &&
        other.viewportColor == viewportColor &&
        other.viewportBorderColor == viewportBorderColor &&
        other.viewportBorderWidth == viewportBorderWidth &&
        other.viewportGlowColor == viewportGlowColor &&
        other.viewportGlowBlur == viewportGlowBlur &&
        other.viewportBorderRadius == viewportBorderRadius;
  }

  @override
  int get hashCode => Object.hash(
        padding,
        backgroundColor,
        maskColor,
        maskStrokeColor,
        maskStrokeWidth,
        borderRadius,
        shadows == null ? null : Object.hashAll(shadows!),
        nodeColor,
        selectedNodeColor,
        disabledNodeColor,
        nodeStrokeColor,
        nodeStrokeWidth,
        nodeBorderRadius,
        viewportColor,
        viewportBorderColor,
        viewportBorderWidth,
        Object.hash(
          viewportGlowColor,
          viewportGlowBlur,
          viewportBorderRadius,
        ),
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('padding', padding, defaultValue: 0));
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(ColorProperty('maskColor', maskColor));
    properties.add(ColorProperty('maskStrokeColor', maskStrokeColor));
    properties.add(
        DoubleProperty('maskStrokeWidth', maskStrokeWidth, defaultValue: 1.0));
    properties.add(DiagnosticsProperty<BorderRadius?>(
        'borderRadius', borderRadius,
        defaultValue: null));
    properties.add(IterableProperty<BoxShadow>('shadows', shadows));
    properties.add(ColorProperty('nodeColor', nodeColor));
    properties.add(ColorProperty('selectedNodeColor', selectedNodeColor));
    properties.add(ColorProperty('disabledNodeColor', disabledNodeColor));
    properties.add(ColorProperty('nodeStrokeColor', nodeStrokeColor));
    properties.add(
        DoubleProperty('nodeStrokeWidth', nodeStrokeWidth, defaultValue: 1.0));
    properties.add(DiagnosticsProperty<BorderRadius?>(
        'nodeBorderRadius', nodeBorderRadius,
        defaultValue: null));
    properties.add(ColorProperty('viewportColor', viewportColor));
    properties.add(ColorProperty('viewportBorderColor', viewportBorderColor));
    properties.add(DoubleProperty('viewportBorderWidth', viewportBorderWidth,
        defaultValue: 1.5));
    properties.add(ColorProperty('viewportGlowColor', viewportGlowColor));
    properties.add(DoubleProperty('viewportGlowBlur', viewportGlowBlur,
        defaultValue: 4.0));
    properties.add(DiagnosticsProperty<BorderRadius?>(
        'viewportBorderRadius', viewportBorderRadius,
        defaultValue: null));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowMinimapStyle('
        'backgroundColor: $backgroundColor, '
        'nodeColor: $nodeColor, '
        'selectedNodeColor: $selectedNodeColor, '
        'disabledNodeColor: $disabledNodeColor, '
        'viewportColor: $viewportColor'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowMinimapStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowMinimapStyle;
/// ```
extension FlowMinimapStyleExtension on ThemeData {
  /// Returns the [FlowMinimapStyle] from theme extensions.
  ///
  /// Falls back to [FlowMinimapStyle.light] if not registered.
  FlowMinimapStyle get flowMinimapStyle =>
      extension<FlowMinimapStyle>() ?? FlowMinimapStyle.light();
}
