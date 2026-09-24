import 'dart:ui' show lerpDouble;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/components/edge_label_theme.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/theme/theme_utils.dart';

/// Represents the possible states of a flow edge.
///
/// Edges transition between these states based on user interaction:
/// - [normal]: Default state when not interacted with
/// - [hovered]: When the cursor is over the edge
/// - [selected]: When the edge is actively selected
///
/// See also:
///
///  * [FlowEdgeStyle.resolveDecoration], which uses these states
enum FlowEdgeState {
  /// The edge is in its default, non-interactive state.
  normal,

  /// The edge is currently selected by the user.
  selected,

  /// The cursor is hovering over the edge.
  hovered,

  /// The edge is locked / non-interactive (`selectable: false`).
  disabled,
}

/// Defines the stroke styling properties for a flow edge.
///
/// This is a lightweight data class that holds the visual properties
/// for drawing edge lines: width, color, and line caps/joins.
///
/// Example:
///
/// ```
/// const stroke = FlowEdgeStrokeStyle(
///   strokeWidth: 2.0,
///   color: Colors.blue,
///   strokeCap: StrokeCap.round,
/// );
/// ```
///
/// See also:
///
///  * [FlowEdgeStyle], which contains stroke styles for different states
///  * [Paint], Flutter's painting API which uses similar properties
@immutable
class FlowEdgeStrokeStyle extends Equatable with Diagnosticable {
  /// The width of the edge line in logical pixels.
  ///
  /// Must be positive. Typical values range from 1.0 to 5.0.
  final double strokeWidth;

  /// The color of the edge line.
  final Color color;

  /// The style of line endings.
  ///
  /// [StrokeCap.round] creates rounded ends (default).
  /// [StrokeCap.square] creates square ends.
  /// [StrokeCap.butt] creates flat ends.
  final StrokeCap strokeCap;

  /// The style of line joins at vertices.
  ///
  /// [StrokeJoin.round] creates rounded corners (default).
  /// [StrokeJoin.miter] creates sharp corners.
  /// [StrokeJoin.bevel] creates beveled corners.
  final StrokeJoin strokeJoin;

  /// Optional dash pattern for the line.
  ///
  /// A list of alternating on/off lengths in logical pixels.
  /// For example, `[5, 3]` creates 5px dashes with 3px gaps.
  ///
  /// If null or empty, draws a solid line.
  ///
  /// Example of a dashed line:
  /// ```
  /// FlowEdgeStrokeStyle(
  ///   strokeWidth: 2.0,
  ///   color: Colors.grey,
  ///   dashPattern: , // 8px dash, 4px gap[16][4]
  /// )
  /// ```
  final List<double>? dashPattern;

  /// Creates an edge stroke style.
  ///
  /// The [strokeWidth] must be positive.
  const FlowEdgeStrokeStyle({
    required this.strokeWidth,
    required this.color,
    this.strokeCap = StrokeCap.round,
    this.strokeJoin = StrokeJoin.round,
    this.dashPattern,
  }) : assert(strokeWidth > 0, 'Stroke width must be positive');

  /// Creates a copy of this style with the given fields replaced.
  FlowEdgeStrokeStyle copyWith({
    double? strokeWidth,
    Color? color,
    StrokeCap? strokeCap,
    StrokeJoin? strokeJoin,
    List<double>? dashPattern,
  }) {
    return FlowEdgeStrokeStyle(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
      strokeCap: strokeCap ?? this.strokeCap,
      strokeJoin: strokeJoin ?? this.strokeJoin,
      dashPattern: dashPattern ?? this.dashPattern,
    );
  }

  /// Linearly interpolates between two stroke styles.
  ///
  /// Returns null if both [a] and [b] are null.
  /// Returns the non-null style if only one is null.
  /// Otherwise interpolates all properties using [t].
  static FlowEdgeStrokeStyle? lerp(
    FlowEdgeStrokeStyle? a,
    FlowEdgeStrokeStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    if (identical(a, b)) return a;
    if (t == 0.0) return a;
    if (t == 1.0) return b;

    return FlowEdgeStrokeStyle(
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? a.strokeWidth,
      color: Color.lerp(a.color, b.color, t) ?? a.color,
      strokeCap: t < 0.5 ? a.strokeCap : b.strokeCap,
      strokeJoin: t < 0.5 ? a.strokeJoin : b.strokeJoin,
      dashPattern: t < 0.5 ? a.dashPattern : b.dashPattern,
    );
  }

  @override
  List<Object?> get props => [
        strokeWidth,
        color,
        strokeCap,
        strokeJoin,
        dashPattern,
      ];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('strokeWidth', strokeWidth));
    properties.add(ColorProperty('color', color));
    properties.add(EnumProperty<StrokeCap>('strokeCap', strokeCap));
    properties.add(EnumProperty<StrokeJoin>('strokeJoin', strokeJoin));
    properties.add(IterableProperty<double>('dashPattern', dashPattern,
        defaultValue: null));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowEdgeStrokeStyle(width: $strokeWidth, color: $color${dashPattern != null ? ', dashed' : ''})';
  }
}

/// Defines the visual styling for flow canvas edges (connections between nodes).
///
/// Edges are the lines connecting nodes in a flow diagram. This style controls
/// their appearance through stroke styling, labels, and endpoint markers.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowEdgeStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowEdgeStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowEdgeStyle;
/// final stroke = style.resolveDecoration({FlowEdgeState.selected});
/// ```
///
/// ## Examples
///
/// Creating a custom edge style:
///
/// ```
/// FlowEdgeStyle(
///   decoration: FlowEdgeStrokeStyle(
///     strokeWidth: 2.0,
///     color: Colors.grey,
///   ),
///   selectedDecoration: FlowEdgeStrokeStyle(
///     strokeWidth: 3.0,
///     color: Colors.blue,
///   ),
///   labelStyle: FlowEdgeLabelStyle.light(),
///   endMarkerStyle: FlowEdgeMarkerStyle.light(),
/// )
/// ```
///
/// Using predefined styles:
///
/// ```
/// // Light theme
/// final light = FlowEdgeStyle.light();
///
/// // Dark theme
/// final dark = FlowEdgeStyle.dark();
///
/// // Match app theme
/// final themed = FlowEdgeStyle.fromTheme(Theme.of(context));
/// ```
///
/// ## State Resolution
///
/// Edge appearance changes based on state:
/// - Normal: Uses [decoration]
/// - Hovered: Uses [hoverDecoration] (falls back to [decoration])
/// - Selected: Uses [selectedDecoration] (falls back to [decoration])
///
/// ## Components
///
/// An edge style combines multiple sub-styles:
/// - **Stroke**: The line connecting nodes ([decoration])
/// - **Labels**: Text displayed on the edge ([labelStyle])
/// - **Markers**: Arrow/shapes at endpoints ([startMarkerStyle], [endMarkerStyle])
///
/// See also:
///
///  * [FlowEdgeStrokeStyle], for line styling
///  * [FlowEdgeLabelStyle], for text labels on edges
///  * [FlowEdgeMarkerStyle], for endpoint markers
@immutable
class FlowEdgeStyle extends ThemeExtension<FlowEdgeStyle> with Diagnosticable {
  /// Base stroke decoration for the edge in its normal state.
  ///
  /// This is required and serves as the fallback for all states.
  final FlowEdgeStrokeStyle decoration;

  /// Optional stroke decoration override when the edge is selected.
  ///
  /// If null, uses [decoration] during selection.
  final FlowEdgeStrokeStyle? selectedDecoration;

  /// Optional stroke decoration override when the edge is hovered.
  ///
  /// If null, uses [decoration] during hover.
  final FlowEdgeStrokeStyle? hoverDecoration;

  /// Optional stroke when the edge is disabled (`selectable: false`).
  ///
  /// If null, uses a dimmed [decoration].
  final FlowEdgeStrokeStyle? disabledDecoration;

  /// Optional style for edge labels (text on the edge).
  ///
  /// If null, labels can still be displayed using default styling,
  /// but won't have theme-aware appearance.
  final FlowEdgeLabelStyle? labelStyle;

  /// Optional style for the marker at the start of the edge.
  ///
  /// If null, no start marker is rendered.
  final FlowEdgeMarkerStyle? startMarkerStyle;

  /// Optional style for the marker at the end of the edge.
  ///
  /// If null, no end marker is rendered. This is typically where
  /// arrows are drawn to indicate direction.
  final FlowEdgeMarkerStyle? endMarkerStyle;

  /// Creates a flow edge style.
  ///
  /// The [decoration] is required as it provides base stroke styling.
  /// All other properties are optional and provide enhanced functionality.
  const FlowEdgeStyle({
    required this.decoration,
    this.selectedDecoration,
    this.hoverDecoration,
    this.disabledDecoration,
    this.labelStyle,
    this.startMarkerStyle,
    this.endMarkerStyle,
  });

  /// Creates an edge style with simple color customization.
  ///
  /// This is a convenience factory for common use cases where you just
  /// want to specify colors and widths for different states.
  ///
  /// Example:
  /// ```
  /// FlowEdgeStyle.colored(
  ///   color: Colors.grey,
  ///   selectedColor: Colors.blue,
  ///   strokeWidth: 2.0,
  ///   selectedStrokeWidth: 3.0,
  /// )
  /// ```
  factory FlowEdgeStyle.colored({
    required Color color,
    double strokeWidth = 2.0,
    Color? selectedColor,
    double? selectedStrokeWidth,
    Color? hoverColor,
    double? hoverStrokeWidth,
    StrokeCap strokeCap = StrokeCap.round,
    StrokeJoin strokeJoin = StrokeJoin.round,
    List<double>? dashPattern,
    bool showLabels = true,
    bool showEndMarker = true,
    bool showStartMarker = false,
  }) {
    final base = FlowEdgeStrokeStyle(
      strokeWidth: strokeWidth,
      color: color,
      strokeCap: strokeCap,
      strokeJoin: strokeJoin,
      dashPattern: dashPattern,
    );

    return FlowEdgeStyle(
      decoration: base,
      selectedDecoration: selectedColor != null || selectedStrokeWidth != null
          ? base.copyWith(
              color: selectedColor,
              strokeWidth: selectedStrokeWidth,
            )
          : null,
      hoverDecoration: hoverColor != null || hoverStrokeWidth != null
          ? base.copyWith(
              color: hoverColor,
              strokeWidth: hoverStrokeWidth,
            )
          : null,
      labelStyle: showLabels ? FlowEdgeLabelStyle.text(color: color) : null,
      startMarkerStyle:
          showStartMarker ? FlowEdgeMarkerStyle.colored(color: color) : null,
      endMarkerStyle:
          showEndMarker ? FlowEdgeMarkerStyle.colored(color: color) : null,
    );
  }

  /// Creates a dashed edge style.
  ///
  /// Useful for representing tentative, optional, or secondary connections.
  ///
  /// Example:
  /// ```
  /// FlowEdgeStyle.dashed(
  ///   color: Colors.grey,
  ///   dashPattern: , // 8px dash, 4px gap[4][16]
  /// )
  /// ```
  factory FlowEdgeStyle.dashed({
    Color color = Colors.grey,
    double strokeWidth = 2.0,
    List<double> dashPattern = const [8, 4],
    Color? selectedColor,
    bool showEndMarker = true,
  }) {
    return FlowEdgeStyle.colored(
      color: color,
      strokeWidth: strokeWidth,
      selectedColor: selectedColor ?? color,
      dashPattern: dashPattern,
      showEndMarker: showEndMarker,
    );
  }

  /// Creates a light theme edge style matching React Flow defaults.
  ///
  /// React Flow: `edge-stroke-default: #b1b1b7` / width `1`,
  /// selected `edge-stroke-selected-default: #555`. No default markers.
  factory FlowEdgeStyle.light() {
    return const FlowEdgeStyle(
      decoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFFB1B1B7),
      ),
      selectedDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFF555555),
      ),
      hoverDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFF555555),
      ),
    );
  }

  /// Creates a dark theme edge style matching React Flow `.dark`.
  ///
  /// React Flow dark: stroke `#3e3e3e`, selected `#727272`, width `1`.
  factory FlowEdgeStyle.dark() {
    return const FlowEdgeStyle(
      decoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFF3E3E3E),
      ),
      selectedDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFF727272),
      ),
      hoverDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFF727272),
      ),
    );
  }

  /// Creates an edge style that adapts to the system brightness.
  ///
  /// Uses [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling.
  factory FlowEdgeStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowEdgeStyle.dark()
        : FlowEdgeStyle.light();
  }

  /// Creates an edge style from a Flutter [ThemeData].
  ///
  /// This is the recommended way to match your app's theme.
  /// Uses [ColorScheme] from the theme if using Material 3,
  /// otherwise falls back to brightness-based styling.
  factory FlowEdgeStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowEdgeStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowEdgeStyle.dark()
        : FlowEdgeStyle.light();
  }

  /// Creates an edge style from a Material 3 [ColorScheme].
  ///
  /// Uses semantic colors:
  /// - Normal: outline color
  /// - Hover: onSurfaceVariant color
  /// - Selected: primary color
  factory FlowEdgeStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowEdgeStyle(
      decoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.outline,
      ),
      selectedDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.onSurface,
      ),
      hoverDecoration: FlowEdgeStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }

  /// Creates an edge style from a seed color using Material 3 guidelines.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the edge styling.
  factory FlowEdgeStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowEdgeStyle.fromColorScheme(colorScheme);
  }

  /// Resolves the appropriate stroke decoration based on edge state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledDecoration]
  /// 2. Selected - returns [selectedDecoration]
  /// 3. Hovered - returns [hoverDecoration]
  /// 4. Normal - returns [decoration]
  FlowEdgeStrokeStyle resolveDecoration(Set<FlowEdgeState> states) {
    if (states.contains(FlowEdgeState.disabled)) {
      return disabledDecoration ??
          decoration.copyWith(color: FlowThemeDim.color(decoration.color));
    }
    if (states.contains(FlowEdgeState.selected)) {
      return selectedDecoration ?? decoration;
    }
    if (states.contains(FlowEdgeState.hovered)) {
      return hoverDecoration ?? decoration;
    }
    return decoration;
  }

  /// Merges this style with another, applying [other]'s values as overrides.
  ///
  /// Non-null values from [other] override values from this style.
  /// Nested styles (labels, markers) are merged recursively.
  ///
  /// Example:
  /// ```
  /// final base = FlowEdgeStyle.light();
  /// final custom = FlowEdgeStyle.colored(
  ///   color: Colors.purple,
  ///   strokeWidth: 3.0,
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: custom's decoration with base's labels/markers
  /// ```
  FlowEdgeStyle merge(FlowEdgeStyle? other) {
    if (other == null) return this;

    return FlowEdgeStyle(
      decoration: other.decoration,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      hoverDecoration: other.hoverDecoration ?? hoverDecoration,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
      labelStyle: other.labelStyle ?? labelStyle,
      startMarkerStyle: other.startMarkerStyle ?? startMarkerStyle,
      endMarkerStyle: other.endMarkerStyle ?? endMarkerStyle,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  @override
  FlowEdgeStyle copyWith({
    FlowEdgeStrokeStyle? decoration,
    FlowEdgeStrokeStyle? selectedDecoration,
    FlowEdgeStrokeStyle? hoverDecoration,
    FlowEdgeStrokeStyle? disabledDecoration,
    FlowEdgeLabelStyle? labelStyle,
    FlowEdgeMarkerStyle? startMarkerStyle,
    FlowEdgeMarkerStyle? endMarkerStyle,
  }) {
    return FlowEdgeStyle(
      decoration: decoration ?? this.decoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      hoverDecoration: hoverDecoration ?? this.hoverDecoration,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
      labelStyle: labelStyle ?? this.labelStyle,
      startMarkerStyle: startMarkerStyle ?? this.startMarkerStyle,
      endMarkerStyle: endMarkerStyle ?? this.endMarkerStyle,
    );
  }

  /// Linearly interpolates between this style and another.
  ///
  /// Used by Flutter's animation system for smooth theme transitions.
  /// The parameter [t] is the interpolation factor, from 0.0 to 1.0.
  @override
  FlowEdgeStyle lerp(
    covariant ThemeExtension<FlowEdgeStyle>? other,
    double t,
  ) {
    if (other is! FlowEdgeStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowEdgeStyle(
      decoration: FlowEdgeStrokeStyle.lerp(decoration, other.decoration, t) ??
          decoration,
      selectedDecoration: FlowEdgeStrokeStyle.lerp(
          selectedDecoration, other.selectedDecoration, t),
      hoverDecoration:
          FlowEdgeStrokeStyle.lerp(hoverDecoration, other.hoverDecoration, t),
      disabledDecoration: FlowEdgeStrokeStyle.lerp(
          disabledDecoration, other.disabledDecoration, t),
      labelStyle: labelStyle?.lerp(other.labelStyle, t),
      startMarkerStyle: startMarkerStyle?.lerp(other.startMarkerStyle, t),
      endMarkerStyle: endMarkerStyle?.lerp(other.endMarkerStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowEdgeStyle &&
        other.decoration == decoration &&
        other.selectedDecoration == selectedDecoration &&
        other.hoverDecoration == hoverDecoration &&
        other.disabledDecoration == disabledDecoration &&
        other.labelStyle == labelStyle &&
        other.startMarkerStyle == startMarkerStyle &&
        other.endMarkerStyle == endMarkerStyle;
  }

  @override
  int get hashCode => Object.hash(
        decoration,
        selectedDecoration,
        hoverDecoration,
        disabledDecoration,
        labelStyle,
        startMarkerStyle,
        endMarkerStyle,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlowEdgeStrokeStyle>(
      'decoration',
      decoration,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeStrokeStyle?>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeStrokeStyle?>(
      'hoverDecoration',
      hoverDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeLabelStyle?>(
      'labelStyle',
      labelStyle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeMarkerStyle?>(
      'startMarkerStyle',
      startMarkerStyle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeMarkerStyle?>(
      'endMarkerStyle',
      endMarkerStyle,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowEdgeStyle('
        'decoration: $decoration, '
        'selectedDecoration: $selectedDecoration, '
        'hoverDecoration: $hoverDecoration'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowEdgeStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowEdgeStyle;
/// ```
extension FlowEdgeStyleExtension on ThemeData {
  /// Returns the [FlowEdgeStyle] from theme extensions.
  ///
  /// Falls back to [FlowEdgeStyle.light] if not registered.
  FlowEdgeStyle get flowEdgeStyle =>
      extension<FlowEdgeStyle>() ?? FlowEdgeStyle.light();
}
