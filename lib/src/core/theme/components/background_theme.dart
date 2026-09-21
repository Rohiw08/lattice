import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// Defines the visual styling of the flow canvas background,
/// including color, pattern type, gradients, and grid spacing.
///
/// This theme extension allows customizing the background of the
/// flow editor area while maintaining support for light, dark,
/// and dynamic system-based themes.
///
/// {@tool snippet}
/// Creating a custom background style:
///
/// ```dart
/// FlowBackgroundStyle(
///   backgroundColor: Colors.white,
///   variant: BackgroundVariant.dots,
///   patternColor: Colors.grey.shade300,
///   gap: 20.0,
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Using predefined styles:
///
/// ```dart
/// // Light theme
/// final light = FlowBackgroundStyle.light();
///
/// // Dark theme
/// final dark = FlowBackgroundStyle.dark();
///
/// // From Material theme
/// final themed = FlowBackgroundStyle.fromTheme(Theme.of(context));
/// ```
/// {@end-tool}
///
/// See also:
///
///  * [ThemeExtension], which this class extends
///  * [ColorScheme], for Material Design color schemes
@immutable
class FlowBackgroundStyle extends ThemeExtension<FlowBackgroundStyle>
    with Diagnosticable {
  // Every field is nullable: `null` means "inherit from the layer below"
  // (global theme) on [merge], and falls back to the documented default via
  // the `effectiveX` getters when resolved. This lets a partial override
  // (e.g. `FlowBackgroundStyle(variant: BackgroundVariant.grid)`) change only
  // what it sets instead of resetting the whole style — matching React Flow's
  // CSS-inheritance model and the repo's "other wins, nulls inherit" contract.
  //
  // The defaults below encode the light-theme values, so `.light()`
  // (all-null) resolves to exactly the same appearance as before.

  /// The base background color of the canvas. Falls back to `#F7F9FB`.
  ///
  /// This color fills the entire canvas area before the pattern is drawn.
  final Color? backgroundColor;

  /// The type of pattern to render (e.g., dots, grid, crosses).
  ///
  /// Use [BackgroundVariant.none] for a solid color background. Falls back to
  /// [BackgroundVariant.dots].
  final BackgroundVariant? variant;

  /// The color of the pattern (grid lines, dots, etc.). Falls back to
  /// `#91919A`.
  ///
  /// This color is used to draw the pattern elements on top of [backgroundColor].
  final Color? patternColor;

  /// The distance between pattern elements in logical pixels. Falls back to
  /// `20.0`.
  ///
  /// For dots: distance between dot centers.
  /// For grid: distance between grid lines.
  /// For crosses: distance between cross centers.
  final double? gap;

  /// The width of lines for grid or cross variants in logical pixels. Falls
  /// back to `1.0`.
  ///
  /// Only applies when [variant] is [BackgroundVariant.grid] or
  /// [BackgroundVariant.crosses].
  final double? lineWidth;

  /// The radius of dots for the dot variant in logical pixels. Falls back to
  /// `0.5`.
  ///
  /// Only applies when [variant] is [BackgroundVariant.dots].
  final double? dotRadius;

  /// The size of cross elements for the cross variant in logical pixels. Falls
  /// back to `8.0`.
  ///
  /// Only applies when [variant] is [BackgroundVariant.crosses].
  final double? crossSize;

  /// Whether the background pattern should fade when zooming. Falls back to
  /// `true`.
  ///
  /// When true, the pattern opacity decreases at high zoom levels
  /// to reduce visual clutter.
  final bool? fadeOnZoom;

  /// The gradient overlay applied to the background, if any.
  ///
  /// When provided, this gradient is drawn on top of [backgroundColor]
  /// and below the pattern. Set to null for no gradient.
  final Gradient? gradient;

  /// The offset to shift the pattern drawing position. Falls back to
  /// [Offset.zero].
  ///
  /// Useful for creating animated or scrolling patterns.
  final Offset? patternOffset;

  /// The blend mode used when painting the pattern. Falls back to
  /// [BlendMode.srcOver].
  ///
  /// Controls how the pattern color blends with the background.
  final BlendMode? blendMode;

  /// Creates a flow canvas background style.
  ///
  /// Every field is optional; unset fields inherit on [merge] and otherwise
  /// resolve to the light-themed dotted defaults via the `effectiveX` getters.
  const FlowBackgroundStyle({
    this.backgroundColor,
    this.variant,
    this.patternColor,
    this.gap,
    this.lineWidth,
    this.dotRadius,
    this.crossSize,
    this.fadeOnZoom,
    this.gradient,
    this.patternOffset,
    this.blendMode,
  })  : assert(gap == null || gap > 0, 'Gap must be positive'),
        assert(lineWidth == null || lineWidth >= 0,
            'Line width cannot be negative'),
        assert(
            dotRadius == null || dotRadius >= 0, 'Dot radius cannot be negative'),
        assert(crossSize == null || crossSize >= 0,
            'Cross size cannot be negative');

  // Resolved values (cascade fallback). Consumers read these, never the raw
  // nullable fields, so an unset field always paints its documented default.
  Color get effectiveBackgroundColor =>
      backgroundColor ?? const Color(0xFFF7F9FB);
  BackgroundVariant get effectiveVariant => variant ?? BackgroundVariant.dots;
  Color get effectivePatternColor => patternColor ?? const Color(0xFF91919A);
  double get effectiveGap => gap ?? 20.0;
  double get effectiveLineWidth => lineWidth ?? 1.0;
  double get effectiveDotRadius => dotRadius ?? 0.5;
  double get effectiveCrossSize => crossSize ?? 8.0;
  bool get effectiveFadeOnZoom => fadeOnZoom ?? true;
  Offset get effectivePatternOffset => patternOffset ?? Offset.zero;
  BlendMode get effectiveBlendMode => blendMode ?? BlendMode.srcOver;

  /// Creates a light mode background style with a dotted pattern.
  ///
  /// xy-theme: `#f7f9fb` canvas.
  factory FlowBackgroundStyle.light() => const FlowBackgroundStyle();

  /// Creates a dark mode background style with a dotted pattern.
  ///
  /// xy-theme `.dark`: `#101012` canvas.
  factory FlowBackgroundStyle.dark() => const FlowBackgroundStyle(
        backgroundColor: Color(0xFF101012),
        patternColor: Color(0xFF555555),
      );

  /// Creates a background style that adapts to the system theme.
  ///
  /// Reads [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling.
  ///
  /// {@tool snippet}
  /// ```dart
  /// @override
  /// Widget build(BuildContext context) {
  ///   return FlowCanvas(
  ///     backgroundStyle: FlowBackgroundStyle.system(context),
  ///   );
  /// }
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowBackgroundStyle.dark()
        : FlowBackgroundStyle.light();
  }

  /// Creates a background style from a Flutter [ThemeData].
  ///
  /// This is the recommended way to match your app's theme.
  /// Uses [ColorScheme] from the theme if using Material 3,
  /// otherwise falls back to brightness-based styling.
  ///
  /// {@tool snippet}
  /// ```dart
  /// FlowBackgroundStyle.fromTheme(Theme.of(context))
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowBackgroundStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowBackgroundStyle.dark()
        : FlowBackgroundStyle.light();
  }

  /// Creates a background style from a Flutter [ColorScheme].
  ///
  /// Uses [ColorScheme.surface] for the background and
  /// a semi-transparent [ColorScheme.onSurface] for the pattern.
  ///
  /// {@tool snippet}
  /// ```dart
  /// final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);
  /// final background = FlowBackgroundStyle.fromColorScheme(colorScheme);
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowBackgroundStyle(
      backgroundColor: colorScheme.surface,
      patternColor: colorScheme.onSurface.withAlpha(40),
    );
  }

  /// Creates a background style derived from a seed color.
  ///
  /// Uses [ColorScheme.fromSeed] to generate a harmonious color palette
  /// and applies it to the background. This ensures the background
  /// coordinates with Material 3 color systems.
  ///
  /// {@tool snippet}
  /// ```dart
  /// FlowBackgroundStyle.fromSeed(
  ///   seedColor: Colors.purple,
  ///   brightness: Brightness.light,
  ///   variant: BackgroundVariant.grid,
  /// )
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
    BackgroundVariant variant = BackgroundVariant.dots,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowBackgroundStyle.fromColorScheme(colorScheme).copyWith(
      variant: variant,
    );
  }

  /// Creates a solid color background style without a pattern.
  ///
  /// Convenient for simple, solid-colored backgrounds.
  ///
  /// {@tool snippet}
  /// ```dart
  /// FlowBackgroundStyle.solid(Colors.white)
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.solid(Color color) {
    return FlowBackgroundStyle(
      backgroundColor: color,
      variant: BackgroundVariant.none,
    );
  }

  /// Creates a gradient-based background style.
  ///
  /// The [colors] list must contain at least one color.
  /// If multiple colors are provided, a linear gradient is created.
  ///
  /// {@tool snippet}
  /// ```dart
  /// FlowBackgroundStyle.gradient(
  ///   colors: [Colors.blue.shade100, Colors.purple.shade100],
  ///   begin: Alignment.topLeft,
  ///   end: Alignment.bottomRight,
  ///   variant: BackgroundVariant.dots,
  /// )
  /// ```
  /// {@end-tool}
  factory FlowBackgroundStyle.gradient({
    required List<Color> colors,
    List<double>? stops,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    TileMode tileMode = TileMode.clamp,
    GradientTransform? transform,
    BackgroundVariant variant = BackgroundVariant.dots,
  }) {
    assert(colors.isNotEmpty, 'Colors list cannot be empty');

    return FlowBackgroundStyle(
      backgroundColor: colors.first,
      variant: variant,
      patternColor: colors.length > 1
          ? colors[1].withAlpha(75)
          : colors.first.withAlpha(75),
      gradient: LinearGradient(
        colors: colors,
        stops: stops,
        begin: begin,
        end: end,
        tileMode: tileMode,
        transform: transform,
      ),
    );
  }

  /// Merges this (parent) style with [other] (child).
  ///
  /// "Other wins, nulls inherit": each field the child leaves null keeps the
  /// parent's value, so a partial override changes only what it explicitly
  /// sets. Fields both layers leave null resolve to their documented default
  /// via the `effectiveX` getters.
  ///
  /// {@tool snippet}
  /// ```dart
  /// final base = FlowBackgroundStyle.light();
  /// final custom = FlowBackgroundStyle(
  ///   backgroundColor: Colors.blue.shade50,
  /// );
  /// final merged = base.merge(custom);
  /// // Result: light theme with blue background; gap/variant/etc. inherited.
  /// ```
  /// {@end-tool}
  FlowBackgroundStyle merge(FlowBackgroundStyle? other) {
    if (other == null) return this;

    return FlowBackgroundStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      variant: other.variant ?? variant,
      patternColor: other.patternColor ?? patternColor,
      gap: other.gap ?? gap,
      lineWidth: other.lineWidth ?? lineWidth,
      dotRadius: other.dotRadius ?? dotRadius,
      crossSize: other.crossSize ?? crossSize,
      fadeOnZoom: other.fadeOnZoom ?? fadeOnZoom,
      gradient: other.gradient ?? gradient,
      patternOffset: other.patternOffset ?? patternOffset,
      blendMode: other.blendMode ?? blendMode,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  ///
  /// {@tool snippet}
  /// ```dart
  /// final original = FlowBackgroundStyle.light();
  /// final modified = original.copyWith(
  ///   backgroundColor: Colors.blue.shade50,
  ///   gap: 30.0,
  /// );
  /// ```
  /// {@end-tool}
  @override
  FlowBackgroundStyle copyWith({
    Color? backgroundColor,
    BackgroundVariant? variant,
    Color? patternColor,
    double? gap,
    double? lineWidth,
    double? dotRadius,
    double? crossSize,
    bool? fadeOnZoom,
    Gradient? gradient,
    Offset? patternOffset,
    BlendMode? blendMode,
  }) {
    return FlowBackgroundStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      variant: variant ?? this.variant,
      patternColor: patternColor ?? this.patternColor,
      gap: gap ?? this.gap,
      lineWidth: lineWidth ?? this.lineWidth,
      dotRadius: dotRadius ?? this.dotRadius,
      crossSize: crossSize ?? this.crossSize,
      fadeOnZoom: fadeOnZoom ?? this.fadeOnZoom,
      gradient: gradient ?? this.gradient,
      patternOffset: patternOffset ?? this.patternOffset,
      blendMode: blendMode ?? this.blendMode,
    );
  }

  /// Linearly interpolates between this style and another.
  ///
  /// Used by Flutter's animation system to smoothly transition between themes.
  /// The parameter [t] is the interpolation factor, from 0.0 to 1.0.
  ///
  /// At t=0.0, returns this style. At t=1.0, returns [other].
  @override
  FlowBackgroundStyle lerp(
    covariant ThemeExtension<FlowBackgroundStyle>? other,
    double t,
  ) {
    if (other is! FlowBackgroundStyle) return this;

    // Interpolate the resolved (effective) values so the animation runs
    // between concrete defaults rather than flashing through null.
    return FlowBackgroundStyle(
      backgroundColor: Color.lerp(
          effectiveBackgroundColor, other.effectiveBackgroundColor, t),
      variant: t < 0.5 ? effectiveVariant : other.effectiveVariant,
      patternColor:
          Color.lerp(effectivePatternColor, other.effectivePatternColor, t),
      gap: lerpDouble(effectiveGap, other.effectiveGap, t),
      lineWidth: lerpDouble(effectiveLineWidth, other.effectiveLineWidth, t),
      dotRadius: lerpDouble(effectiveDotRadius, other.effectiveDotRadius, t),
      crossSize: lerpDouble(effectiveCrossSize, other.effectiveCrossSize, t),
      fadeOnZoom: t < 0.5 ? effectiveFadeOnZoom : other.effectiveFadeOnZoom,
      gradient: Gradient.lerp(gradient, other.gradient, t),
      patternOffset:
          Offset.lerp(effectivePatternOffset, other.effectivePatternOffset, t),
      blendMode: t < 0.5 ? effectiveBlendMode : other.effectiveBlendMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowBackgroundStyle &&
        other.backgroundColor == backgroundColor &&
        other.variant == variant &&
        other.patternColor == patternColor &&
        other.gap == gap &&
        other.lineWidth == lineWidth &&
        other.dotRadius == dotRadius &&
        other.crossSize == crossSize &&
        other.fadeOnZoom == fadeOnZoom &&
        other.gradient == gradient &&
        other.patternOffset == patternOffset &&
        other.blendMode == blendMode;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        variant,
        patternColor,
        gap,
        lineWidth,
        dotRadius,
        crossSize,
        fadeOnZoom,
        gradient,
        patternOffset,
        blendMode,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('backgroundColor', backgroundColor));
    properties.add(EnumProperty<BackgroundVariant?>('variant', variant,
        defaultValue: null));
    properties.add(ColorProperty('patternColor', patternColor));
    properties.add(DoubleProperty('gap', gap, defaultValue: null));
    properties.add(DoubleProperty('lineWidth', lineWidth, defaultValue: null));
    properties.add(DoubleProperty('dotRadius', dotRadius, defaultValue: null));
    properties.add(DoubleProperty('crossSize', crossSize, defaultValue: null));
    properties.add(
      FlagProperty(
        'fadeOnZoom',
        value: fadeOnZoom,
        ifTrue: 'fades on zoom',
        ifFalse: 'no fade',
        defaultValue: null,
      ),
    );
    properties.add(DiagnosticsProperty<Gradient?>('gradient', gradient,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Offset?>('patternOffset', patternOffset,
        defaultValue: null));
    properties.add(EnumProperty<BlendMode?>('blendMode', blendMode,
        defaultValue: null));
  }
}
