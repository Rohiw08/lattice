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
  /// The base background color of the canvas.
  ///
  /// This color fills the entire canvas area before the pattern is drawn.
  final Color backgroundColor;

  /// The type of pattern to render (e.g., dots, grid, crosses).
  ///
  /// Use [BackgroundVariant.none] for a solid color background.
  final BackgroundVariant variant;

  /// The color of the pattern (grid lines, dots, etc.).
  ///
  /// This color is used to draw the pattern elements on top of [backgroundColor].
  final Color patternColor;

  /// The distance between pattern elements in logical pixels.
  ///
  /// For dots: distance between dot centers.
  /// For grid: distance between grid lines.
  /// For crosses: distance between cross centers.
  final double gap;

  /// The width of lines for grid or cross variants in logical pixels.
  ///
  /// Only applies when [variant] is [BackgroundVariant.grid] or
  /// [BackgroundVariant.crosses].
  final double lineWidth;

  /// The radius of dots for the dot variant in logical pixels.
  ///
  /// Only applies when [variant] is [BackgroundVariant.dots].
  final double dotRadius;

  /// The size of cross elements for the cross variant in logical pixels.
  ///
  /// Only applies when [variant] is [BackgroundVariant.crosses].
  final double crossSize;

  /// Whether the background pattern should fade when zooming.
  ///
  /// When true, the pattern opacity decreases at high zoom levels
  /// to reduce visual clutter.
  final bool fadeOnZoom;

  /// The gradient overlay applied to the background, if any.
  ///
  /// When provided, this gradient is drawn on top of [backgroundColor]
  /// and below the pattern. Set to null for no gradient.
  final Gradient? gradient;

  /// The offset to shift the pattern drawing position.
  ///
  /// Useful for creating animated or scrolling patterns.
  /// Defaults to [Offset.zero].
  final Offset patternOffset;

  /// The blend mode used when painting the pattern.
  ///
  /// Controls how the pattern color blends with the background.
  /// Defaults to [BlendMode.srcOver].
  final BlendMode blendMode;

  /// Creates a flow canvas background style.
  ///
  /// All parameters have sensible defaults for a light-themed
  /// dotted background pattern.
  const FlowBackgroundStyle({
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.variant = BackgroundVariant.dots,
    this.patternColor = const Color(0xFF91919A),
    this.gap = 20.0,
    this.lineWidth = 1.0,
    this.dotRadius = 0.5,
    this.crossSize = 8.0,
    this.fadeOnZoom = true,
    this.gradient,
    this.patternOffset = Offset.zero,
    this.blendMode = BlendMode.srcOver,
  })  : assert(gap > 0, 'Gap must be positive'),
        assert(lineWidth >= 0, 'Line width cannot be negative'),
        assert(dotRadius >= 0, 'Dot radius cannot be negative'),
        assert(crossSize >= 0, 'Cross size cannot be negative');

  /// Creates a light mode background style with a dotted pattern.
  ///
  /// Lattice v12: white canvas with `#91919A` dots (size 1px, gap 20px).
  factory FlowBackgroundStyle.light() => const FlowBackgroundStyle();

  /// Creates a dark mode background style with a dotted pattern.
  ///
  /// Lattice v12 `.dark`: `#141414` canvas with `#555` dots.
  factory FlowBackgroundStyle.dark() => const FlowBackgroundStyle(
        backgroundColor: Color(0xFF141414),
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

  /// Merges this style with another [FlowBackgroundStyle].
  ///
  /// Only non-null properties from [other] are applied.
  /// This follows Flutter's standard merge pattern (like [TextStyle.merge]).
  ///
  /// {@tool snippet}
  /// ```dart
  /// final base = FlowBackgroundStyle.light();
  /// final custom = FlowBackgroundStyle(
  ///   backgroundColor: Colors.blue.shade50,
  /// );
  /// final merged = base.merge(custom);
  /// // Result: light theme with blue background
  /// ```
  /// {@end-tool}
  ///
  /// Note: This method cannot distinguish between explicitly set null values
  /// and omitted properties. For explicit null support, use [copyWith].
  FlowBackgroundStyle merge(FlowBackgroundStyle? other) {
    if (other == null) return this;

    // Only override if the value is different from defaults
    // This mimics Flutter's TextStyle.merge behavior
    return copyWith(
      backgroundColor: other.backgroundColor != const Color(0xFFFAFAFA)
          ? other.backgroundColor
          : null,
      variant: other.variant != BackgroundVariant.dots ? other.variant : null,
      patternColor: other.patternColor != const Color(0xFF9D9D9D)
          ? other.patternColor
          : null,
      gap: other.gap != 25.0 ? other.gap : null,
      lineWidth: other.lineWidth != 1.0 ? other.lineWidth : null,
      dotRadius: other.dotRadius != 0.75 ? other.dotRadius : null,
      crossSize: other.crossSize != 8.0 ? other.crossSize : null,
      fadeOnZoom: other.fadeOnZoom != true ? other.fadeOnZoom : null,
      gradient: other.gradient,
      patternOffset:
          other.patternOffset != Offset.zero ? other.patternOffset : null,
      blendMode: other.blendMode != BlendMode.srcOver ? other.blendMode : null,
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

    return FlowBackgroundStyle(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t)!,
      variant: t < 0.5 ? variant : other.variant,
      patternColor: Color.lerp(patternColor, other.patternColor, t)!,
      gap: lerpDouble(gap, other.gap, t)!,
      lineWidth: lerpDouble(lineWidth, other.lineWidth, t)!,
      dotRadius: lerpDouble(dotRadius, other.dotRadius, t)!,
      crossSize: lerpDouble(crossSize, other.crossSize, t)!,
      fadeOnZoom: t < 0.5 ? fadeOnZoom : other.fadeOnZoom,
      gradient: Gradient.lerp(gradient, other.gradient, t),
      patternOffset: Offset.lerp(patternOffset, other.patternOffset, t)!,
      blendMode: t < 0.5 ? blendMode : other.blendMode,
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
    properties.add(EnumProperty<BackgroundVariant>('variant', variant));
    properties.add(ColorProperty('patternColor', patternColor));
    properties.add(DoubleProperty('gap', gap, defaultValue: 25.0));
    properties.add(DoubleProperty('lineWidth', lineWidth, defaultValue: 1.0));
    properties.add(DoubleProperty('dotRadius', dotRadius, defaultValue: 0.75));
    properties.add(DoubleProperty('crossSize', crossSize, defaultValue: 8.0));
    properties.add(
      FlagProperty(
        'fadeOnZoom',
        value: fadeOnZoom,
        ifTrue: 'fades on zoom',
        ifFalse: 'no fade',
        defaultValue: true,
      ),
    );
    properties.add(DiagnosticsProperty<Gradient?>('gradient', gradient,
        defaultValue: null));
    properties.add(DiagnosticsProperty<Offset>('patternOffset', patternOffset,
        defaultValue: Offset.zero));
    properties.add(EnumProperty<BlendMode>('blendMode', blendMode,
        defaultValue: BlendMode.srcOver));
  }
}
