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

  /// Width of the selection box border.
  ///
  /// Only applies when [borderColor] is non-null.
  final double borderWidth;

  /// Border radius for rounded corners on the selection box.
  ///
  /// Use [BorderRadius.zero] for sharp corners.
  final BorderRadius borderRadius;

  /// Length of each dash in the border (if dashed).
  ///
  /// Set to 0 for a solid border. Only applies when [borderColor] is non-null.
  final double dashLength;

  /// Length of gaps between dashes in the border.
  ///
  /// Ignored if [dashLength] is 0. Only applies when [borderColor] is non-null.
  final double gapLength;

  const FlowSelectionStyle({
    this.fillColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.borderRadius = BorderRadius.zero,
    this.dashLength = 5.0,
    this.gapLength = 5.0,
  });

  /// Creates a selection style from simple color values.
  factory FlowSelectionStyle.colored({
    required Color fillColor,
    required Color borderColor,
    double borderWidth = 1.0,
    BorderRadius borderRadius = BorderRadius.zero,
    double dashLength = 5.0,
    double gapLength = 5.0,
  }) {
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
  /// Uses blue colors with subtle transparency for clean visibility.
  factory FlowSelectionStyle.light() {
    // Lattice: `selection-*` → rgba(0, 89, 220, 0.08 / 0.8), dotted.
    return const FlowSelectionStyle(
      fillColor: Color(0x140059DC),
      borderColor: Color(0xCC0059DC),
      borderWidth: 1.0,
      borderRadius: BorderRadius.zero,
      dashLength: 5.0,
      gapLength: 5.0,
    );
  }

  /// Creates a dark theme selection style.
  ///
  /// Lattice `.dark` selection: `rgba(200, 200, 220, 0.08)` fill,
  /// dotted `rgba(200, 200, 220, 0.8)` outline.
  factory FlowSelectionStyle.dark() {
    return const FlowSelectionStyle(
      fillColor: Color(0x14C8C8DC),
      borderColor: Color(0xCCC8C8DC),
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

  /// Merges this style with another, preferring the other's non-null values.
  ///
  /// Only non-null values from [other] will override this style's values.
  /// Primitive types (double) always override from [other].
  ///
  /// Example:
  /// ```
  /// final baseStyle = FlowSelectionStyle.light();
  /// final customStyle = FlowSelectionStyle(
  ///   fillColor: null,
  ///   borderColor: Colors.purple,
  /// );
  /// final merged = baseStyle.merge(customStyle);
  /// // merged keeps baseStyle's fillColor but uses customStyle's borderColor
  /// ```
  FlowSelectionStyle merge(FlowSelectionStyle? other) {
    if (other == null) return this;
    return FlowSelectionStyle(
      fillColor: other.fillColor ?? fillColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth,
      borderRadius: other.borderRadius,
      dashLength: other.dashLength,
      gapLength: other.gapLength,
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
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      borderRadius: BorderRadius.lerp(borderRadius, other.borderRadius, t) ??
          borderRadius,
      dashLength: lerpDouble(dashLength, other.dashLength, t) ?? dashLength,
      gapLength: lerpDouble(gapLength, other.gapLength, t) ?? gapLength,
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
        .add(DoubleProperty('borderWidth', borderWidth, defaultValue: 1.0));
    properties.add(DiagnosticsProperty<BorderRadius>(
        'borderRadius', borderRadius,
        defaultValue: BorderRadius.zero));
    properties.add(DoubleProperty('dashLength', dashLength, defaultValue: 5.0));
    properties.add(DoubleProperty('gapLength', gapLength, defaultValue: 5.0));
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
