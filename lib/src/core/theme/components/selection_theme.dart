import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visual styling for selection boxes in the flow canvas.
///
/// Selection boxes are drawn when users drag to select multiple nodes.
/// This style controls the fill color, border appearance, and dash pattern
/// for creating visually distinct selection indicators.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowSelectionStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowSelectionStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowSelectionStyle;
/// ```
///
/// ## Examples
///
/// ```
/// // Basic selection box
/// FlowSelectionStyle(
///   fillColor: Colors.blue.withValues(alpha: 0.1),
///   borderColor: Colors.blue,
///   borderWidth: 2.0,
///   borderRadius: BorderRadius.circular(8.0),
/// )
///
/// // Dashed border selection
/// FlowSelectionStyle(
///   fillColor: Colors.purple.withValues(alpha: 0.15),
///   borderColor: Colors.purple,
///   dashLength: 8.0,
///   gapLength: 4.0,
/// )
///
/// // Solid border selection
/// FlowSelectionStyle(
///   fillColor: Colors.green.withValues(alpha: 0.1),
///   borderColor: Colors.green,
///   dashLength: 0, // Solid border
/// )
///
/// // From Material 3 color scheme
/// FlowSelectionStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// )
/// ```
@immutable
class FlowSelectionStyle extends ThemeExtension<FlowSelectionStyle>
    with Diagnosticable {
  /// Fill color for the selection box interior.
  ///
  /// Typically semi-transparent to show underlying content.
  /// Set to null for no fill (transparent).
  final Color? fillColor;

  /// Border color for the selection box outline.
  ///
  /// Set to null for no border.
  final Color? borderColor;

  /// Width of the selection box border. Falls back to `1.0`.
  ///
  /// Null means "inherit from the layer below" on [merge]; resolved via
  /// [effectiveBorderWidth]. Same for the other geometry fields — so a partial
  /// override (e.g. `FlowSelectionStyle(borderColor: red)`) changes only what
  /// it sets. Only applies when [borderColor] is non-null.
  final double? borderWidth;

  /// Border radius for rounded corners on the selection box. Falls back to
  /// [BorderRadius.zero].
  final BorderRadius? borderRadius;

  /// Length of each dash in the border (if dashed). Falls back to `5.0`.
  ///
  /// Set to 0 for a solid border. Only applies when [borderColor] is non-null.
  final double? dashLength;

  /// Length of gaps between dashes in the border. Falls back to `5.0`.
  ///
  /// Ignored if [dashLength] is 0. Only applies when [borderColor] is non-null.
  final double? gapLength;

  const FlowSelectionStyle({
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.dashLength,
    this.gapLength,
  });

  // Resolved values (cascade fallback). Consumers read these, never the raw
  // nullable fields, so an unset field always resolves its documented default.
  double get effectiveBorderWidth => borderWidth ?? 1.0;
  BorderRadius get effectiveBorderRadius => borderRadius ?? BorderRadius.zero;
  double get effectiveDashLength => dashLength ?? 5.0;
  double get effectiveGapLength => gapLength ?? 5.0;

  /// Creates a selection style from simple color values.
  factory FlowSelectionStyle.colored({
    required Color fillColor,
    required Color borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? dashLength,
    double? gapLength,
  }) {
    // Only the colors are forced; unset geometry stays null so it inherits on
    // merge and falls back to defaults via the effectiveX getters.
    return FlowSelectionStyle(
      fillColor: fillColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      dashLength: dashLength,
      gapLength: gapLength,
    );
  }

  /// Creates a light theme selection style.
  ///
  /// RF default (`base.css`, which xy-theme does not override):
  /// `rgba(150,150,180,0.1)` fill, dotted `rgba(155,155,155,0.8)` outline.
  factory FlowSelectionStyle.light() {
    return const FlowSelectionStyle(
      fillColor: Color(0x1A9696B4),
      borderColor: Color(0xCC9B9B9B),
      borderWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 5.0,
      gapLength: 5.0,
    );
  }

  /// Creates a dark theme selection style.
  ///
  /// Same RF default both modes (no `.dark` override in either `base.css`
  /// or xy-theme).
  factory FlowSelectionStyle.dark() {
    return const FlowSelectionStyle(
      fillColor: Color(0x1A9696B4),
      borderColor: Color(0xCC9B9B9B),
      borderWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 5.0,
      gapLength: 5.0,
    );
  }

  /// Creates a selection style that adapts to the system brightness.
  ///
  /// Automatically selects [light] or [dark] based on the current theme.
  factory FlowSelectionStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowSelectionStyle.dark()
        : FlowSelectionStyle.light();
  }

  /// Creates a selection style from a Material 3 color scheme.
  ///
  /// Uses the primary color with Material 3 opacity guidelines.
  factory FlowSelectionStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowSelectionStyle(
      fillColor: colorScheme.primary.withValues(alpha: 0.15), // 15% opacity
      borderColor: colorScheme.primary,
      borderWidth: 1.0,
      borderRadius: const BorderRadius.all(Radius.circular(4.0)),
      dashLength: 5.0,
      gapLength: 5.0,
    );
  }

  /// Creates a selection style from a seed color using Material 3 guidelines.
  ///
  /// Generates a harmonious color scheme from a single seed color.
  factory FlowSelectionStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowSelectionStyle.fromColorScheme(colorScheme);
  }

  /// Creates a selection style from a Flutter [ThemeData].
  factory FlowSelectionStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowSelectionStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowSelectionStyle.dark()
        : FlowSelectionStyle.light();
  }

  /// Merges this (parent) style with [other] (child).
  ///
  /// "Other wins, nulls inherit": every field the child leaves null keeps the
  /// parent's value, so a partial override changes only what it sets. Fields
  /// both layers leave null resolve to their default via the `effectiveX`
  /// getters.
  ///
  /// Example:
  /// ```
  /// final baseStyle = FlowSelectionStyle.light();
  /// final customStyle = FlowSelectionStyle(borderColor: Colors.purple);
  /// final merged = baseStyle.merge(customStyle);
  /// // merged keeps baseStyle's fillColor/geometry, uses purple borderColor
  /// ```
  FlowSelectionStyle merge(FlowSelectionStyle? other) {
    if (other == null) return this;
    return FlowSelectionStyle(
      fillColor: other.fillColor ?? fillColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      dashLength: other.dashLength ?? dashLength,
      gapLength: other.gapLength ?? gapLength,
    );
  }

  @override
  FlowSelectionStyle copyWith({
    Color? fillColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    double? dashLength,
    double? gapLength,
  }) {
    return FlowSelectionStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      dashLength: dashLength ?? this.dashLength,
      gapLength: gapLength ?? this.gapLength,
    );
  }

  @override
  FlowSelectionStyle lerp(
    covariant ThemeExtension<FlowSelectionStyle>? other,
    double t,
  ) {
    if (other is! FlowSelectionStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowSelectionStyle(
      fillColor: Color.lerp(fillColor, other.fillColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
      // Interpolate resolved geometry so the animation runs between concrete
      // defaults rather than flashing through null.
      borderWidth:
          lerpDouble(effectiveBorderWidth, other.effectiveBorderWidth, t),
      borderRadius: BorderRadius.lerp(
          effectiveBorderRadius, other.effectiveBorderRadius, t),
      dashLength: lerpDouble(effectiveDashLength, other.effectiveDashLength, t),
      gapLength: lerpDouble(effectiveGapLength, other.effectiveGapLength, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowSelectionStyle &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.dashLength == dashLength &&
        other.gapLength == gapLength;
  }

  @override
  int get hashCode => Object.hash(
        fillColor,
        borderColor,
        borderWidth,
        borderRadius,
        dashLength,
        gapLength,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('fillColor', fillColor, defaultValue: null));
    properties
        .add(ColorProperty('borderColor', borderColor, defaultValue: null));
    properties
        .add(DoubleProperty('borderWidth', borderWidth, defaultValue: null));
    properties.add(DiagnosticsProperty<BorderRadius?>(
        'borderRadius', borderRadius,
        defaultValue: null));
    properties.add(DoubleProperty('dashLength', dashLength, defaultValue: null));
    properties.add(DoubleProperty('gapLength', gapLength, defaultValue: null));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowSelectionStyle('
        'fillColor: $fillColor, '
        'borderColor: $borderColor, '
        'borderWidth: $borderWidth, '
        'dashLength: $dashLength, '
        'gapLength: $gapLength'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowSelectionStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowSelectionStyle;
/// ```
extension FlowSelectionStyleExtension on ThemeData {
  /// Returns the [FlowSelectionStyle] from theme extensions.
  ///
  /// Falls back to [FlowSelectionStyle.light] if not registered.
  FlowSelectionStyle get flowSelectionStyle =>
      extension<FlowSelectionStyle>() ?? FlowSelectionStyle.light();
}
