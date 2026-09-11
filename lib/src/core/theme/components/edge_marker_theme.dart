import 'dart:ui' show lerpDouble, Tangent;
import 'package:equatable/equatable.dart';
import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/theme/theme_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The type of marker to display at edge endpoints.
///
/// Markers are visual indicators (arrows, circles, etc.) that appear
/// at the start or end of edges in the flow canvas.
///
/// See also:
///
///  * [FlowEdgeMarkerStyle], which uses this enum to determine marker shape
enum EdgeMarkerType {
  /// No marker is displayed.
  none,

  /// An open arrow marker (outline only).
  ///
  /// Typically used for data flow or dependency relationships.
  arrow,

  /// A circular marker.
  ///
  /// Useful for indicating endpoints or connection points.
  circle,

  /// A closed (filled) arrow marker.
  ///
  /// Provides stronger visual weight than [arrow].
  arrowClosed,
}

/// A function that draws a custom marker at an edge endpoint.
///
/// This allows complete customization of marker appearance beyond
/// the predefined [EdgeMarkerType] options.
///
/// The [canvas] is the drawing surface, [tangent] provides the edge's
/// direction and position at the endpoint, and [style] contains the
/// resolved decoration (color, size, stroke width).
///
/// Example of creating a custom diamond marker:
///
/// ```
/// void drawDiamond(Canvas canvas, Tangent tangent, FlowMarkerDecoration style) {
///   final paint = Paint()
///     ..color = style.color
///     ..style = PaintingStyle.fill;
///
///   final path = Path()
///     ..moveTo(0, -style.size.height / 2)
///     ..lineTo(style.size.width / 2, 0)
///     ..lineTo(0, style.size.height / 2)
///     ..lineTo(-style.size.width / 2, 0)
///     ..close();
///
///   canvas.save();
///   canvas.translate(tangent.position.dx, tangent.position.dy);
///   canvas.rotate(tangent.angle);
///   canvas.drawPath(path, paint);
///   canvas.restore();
/// }
/// ```
///
/// See also:
///
///  * [FlowEdgeMarkerStyle.builder], where this function is used
///  * [CustomPainter], Flutter's custom painting API
typedef MarkerBuilder = void Function(
  Canvas canvas,
  Tangent tangent,
  FlowMarkerDecoration style,
);

/// The visual styling properties for a marker at a resolved state.
///
/// This is a lightweight data class that holds the resolved appearance
/// of a marker (color, size, stroke width) after state resolution.
///
/// Use [FlowEdgeMarkerStyle] for theme-aware styling with state support.
/// This class represents a single resolved state.
///
/// Example of creating a marker decoration:
///
/// ```
/// const decoration = FlowMarkerDecoration(
///   size: Size(16, 16),
///   color: Colors.blue,
///   strokeWidth: 2.0,
/// );
/// ```
///
/// See also:
///
///  * [FlowEdgeMarkerStyle], which contains decorations for different states
@immutable
class FlowMarkerDecoration extends Equatable with Diagnosticable {
  /// The size of the marker in logical pixels.
  ///
  /// For arrows: represents the arrow's bounding box.
  /// For circles: represents the circle's diameter.
  final Size size;

  /// The color of the marker.
  ///
  /// This color is used for both stroke and fill, depending on the marker type.
  final Color color;

  /// The width of strokes when drawing the marker.
  ///
  /// Only applies to markers with strokes (open arrows, circle outlines).
  /// Defaults to 2.0 logical pixels.
  final double strokeWidth;

  /// Creates a marker decoration.
  ///
  /// The [size] must have positive dimensions, and [strokeWidth] must be non-negative.
  const FlowMarkerDecoration({
    required this.size,
    required this.color,
    this.strokeWidth = 2.0,
  }) : assert(strokeWidth >= 0, 'Stroke width cannot be negative');

  /// Creates a copy of this decoration with the given fields replaced.
  FlowMarkerDecoration copyWith({
    Size? size,
    Color? color,
    double? strokeWidth,
  }) {
    return FlowMarkerDecoration(
      size: size ?? this.size,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  /// Linearly interpolates between two decorations.
  ///
  /// Returns null if both [a] and [b] are null.
  /// Returns the non-null decoration if only one is null.
  /// Otherwise interpolates all properties using [t].
  static FlowMarkerDecoration? lerp(
    FlowMarkerDecoration? a,
    FlowMarkerDecoration? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    if (identical(a, b)) return a;
    if (t == 0.0) return a;
    if (t == 1.0) return b;

    return FlowMarkerDecoration(
      size: Size.lerp(a.size, b.size, t) ?? a.size,
      color: Color.lerp(a.color, b.color, t) ?? a.color,
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? a.strokeWidth,
    );
  }

  @override
  List<Object?> get props => [size, color, strokeWidth];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Size>('size', size));
    properties.add(ColorProperty('color', color));
    properties
        .add(DoubleProperty('strokeWidth', strokeWidth, defaultValue: 2.0));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowMarkerDecoration(size: $size, color: $color, strokeWidth: $strokeWidth)';
  }
}

/// Defines the visual styling for markers at edge endpoints.
///
/// Markers are visual indicators (arrows, circles, etc.) that appear
/// at the start or end of edges connecting nodes. This style supports
/// state-based theming (normal, hover, selected) and custom marker shapes.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowEdgeMarkerStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowEdgeMarkerStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowEdgeMarkerStyle;
/// final decoration = style.resolve({FlowEdgeState.selected});
/// ```
///
/// ## Examples
///
/// Using a predefined marker style:
///
/// ```
/// FlowEdge(
///   endMarkerStyle: FlowEdgeMarkerStyle.light(),
/// )
/// ```
///
/// Creating a custom colored marker:
///
/// ```
/// FlowEdgeMarkerStyle.colored(
///   markerType: EdgeMarkerType.arrowClosed,
///   color: Colors.blue,
///   hoverColor: Colors.blue.shade700,
///   selectedColor: Colors.orange,
/// )
/// ```
///
/// Using a custom marker builder:
///
/// ```
/// FlowEdgeMarkerStyle(
///   decoration: FlowMarkerDecoration(
///     size: Size(16, 16),
///     color: Colors.blue,
///   ),
///   builder: (canvas, tangent, style) {
///     // Custom drawing code
///     final paint = Paint()..color = style.color;
///     canvas.drawCircle(tangent.position, style.size.width / 2, paint);
///   },
/// )
/// ```
///
/// ## State Resolution
///
/// The marker appearance changes based on edge state:
/// - Disabled: Uses [disabledDecoration] (falls back to dimmed [decoration])
/// - Selected: Uses [selectedDecoration] (falls back to [decoration])
/// - Hovered: Uses [hoverDecoration] (falls back to [decoration])
/// - Normal: Uses [decoration]
///
/// ## Custom Markers
///
/// For complete control over marker rendering, provide a [builder] function.
/// When provided, [markerType] is ignored and your custom drawing code is used instead.
///
/// See also:
///
///  * [FlowEdgeStyle], which contains marker styles for edges
///  * [EdgeMarkerType], for predefined marker shapes
///  * [MarkerBuilder], for custom marker drawing
@immutable
class FlowEdgeMarkerStyle extends ThemeExtension<FlowEdgeMarkerStyle>
    with Diagnosticable {
  /// The type of marker to display.
  ///
  /// This determines the default rendering when [builder] is not provided.
  /// Set to [EdgeMarkerType.none] to hide markers.
  final EdgeMarkerType markerType;

  /// The marker decoration in its normal state.
  ///
  /// This is the base styling and serves as a fallback for other states.
  final FlowMarkerDecoration decoration;

  /// The marker decoration when the edge is hovered.
  ///
  /// If null, uses [decoration] during hover.
  final FlowMarkerDecoration? hoverDecoration;

  /// The marker decoration when the edge is selected.
  ///
  /// If null, uses [decoration] when selected.
  final FlowMarkerDecoration? selectedDecoration;

  /// The marker decoration when the edge is disabled.
  ///
  /// If null, uses a lower-opacity version of [decoration].
  final FlowMarkerDecoration? disabledDecoration;

  /// A custom function to draw the marker.
  ///
  /// When provided, this overrides the default rendering based on [markerType].
  /// Use this for completely custom marker shapes.
  ///
  /// The function receives the canvas, edge tangent (position and angle),
  /// and resolved decoration for the current state.
  final MarkerBuilder? builder;

  /// Creates an edge marker style.
  ///
  /// The [decoration] is required as it provides the base styling.
  /// State-specific decorations are optional and fall back to [decoration].
  const FlowEdgeMarkerStyle({
    required this.decoration,
    this.markerType = EdgeMarkerType.arrow,
    this.builder,
    this.hoverDecoration,
    this.selectedDecoration,
    this.disabledDecoration,
  });

  /// Creates a marker style with no marker displayed.
  ///
  /// Convenient for edges that shouldn't show endpoint indicators.
  ///
  /// Example:
  /// ```
  /// FlowEdge(
  ///   endMarkerStyle: FlowEdgeMarkerStyle.none(),
  /// )
  /// ```
  factory FlowEdgeMarkerStyle.none() {
    return const FlowEdgeMarkerStyle(
      markerType: EdgeMarkerType.none,
      decoration: FlowMarkerDecoration(
        size: Size.zero,
        color: Colors.transparent,
        strokeWidth: 0,
      ),
    );
  }

  /// Creates a light theme marker style.
  ///
  /// Lattice default: closed arrow (20x20) colored like the edge
  /// stroke (`#b1b1b7`); hover `#999`, selected `#555`.
  factory FlowEdgeMarkerStyle.light() {
    return const FlowEdgeMarkerStyle(
      markerType: EdgeMarkerType.arrowClosed,
      decoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFFB1B1B7),
        strokeWidth: 2.0,
      ),
      hoverDecoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFF999999),
        strokeWidth: 2.0,
      ),
      selectedDecoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFF555555),
        strokeWidth: 2.0,
      ),
    );
  }

  /// Creates a dark theme marker style.
  ///
  /// Lattice `.dark`: closed arrow (20x20) colored like the edge
  /// stroke (`#3e3e3e`); hover `#aaa`, selected `#727272`.
  factory FlowEdgeMarkerStyle.dark() {
    return const FlowEdgeMarkerStyle(
      markerType: EdgeMarkerType.arrowClosed,
      decoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFF3E3E3E),
        strokeWidth: 2.0,
      ),
      hoverDecoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFFAAAAAA),
        strokeWidth: 2.0,
      ),
      selectedDecoration: FlowMarkerDecoration(
        size: Size(20, 20),
        color: Color(0xFF727272),
        strokeWidth: 2.0,
      ),
    );
  }

  /// Creates a marker style that adapts to the system theme.
  ///
  /// Uses [Theme.of(context).brightness] to determine light or dark styling.
  factory FlowEdgeMarkerStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowEdgeMarkerStyle.dark()
        : FlowEdgeMarkerStyle.light();
  }

  /// Creates a marker style from a Flutter [ThemeData].
  ///
  /// This is the recommended way to match your app's theme.
  /// Uses [ColorScheme] from the theme if using Material 3,
  /// otherwise falls back to brightness-based styling.
  factory FlowEdgeMarkerStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowEdgeMarkerStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowEdgeMarkerStyle.dark()
        : FlowEdgeMarkerStyle.light();
  }

  /// Creates a marker style from a Flutter [ColorScheme].
  ///
  /// Uses Material 3 semantic colors for consistent theming:
  /// - Normal: outline color
  /// - Hover: onSurfaceVariant color
  /// - Selected: primary color
  factory FlowEdgeMarkerStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowEdgeMarkerStyle(
      markerType: EdgeMarkerType.arrowClosed,
      decoration: FlowMarkerDecoration(
        size: const Size(12, 12),
        color: colorScheme.outline,
        strokeWidth: 1.5,
      ),
      hoverDecoration: FlowMarkerDecoration(
        size: const Size(12, 12),
        color: colorScheme.onSurfaceVariant,
        strokeWidth: 1.5,
      ),
      selectedDecoration: FlowMarkerDecoration(
        size: const Size(14, 14),
        color: colorScheme.primary,
        strokeWidth: 2.0,
      ),
    );
  }

  /// Creates a marker style from a seed color using Material 3 guidelines.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the marker styling.
  factory FlowEdgeMarkerStyle.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowEdgeMarkerStyle.fromColorScheme(colorScheme);
  }

  /// Creates a marker style with simple color customization.
  ///
  /// This is a convenience factory for common use cases where you just
  /// want to specify colors for different states.
  ///
  /// Example:
  /// ```
  /// FlowEdgeMarkerStyle.colored(
  ///   markerType: EdgeMarkerType.arrowClosed,
  ///   color: Colors.grey,
  ///   hoverColor: Colors.black,
  ///   selectedColor: Colors.blue,
  /// )
  /// ```
  factory FlowEdgeMarkerStyle.colored({
    EdgeMarkerType markerType = EdgeMarkerType.arrow,
    Size size = const Size(12, 12),
    double strokeWidth = 2.0,
    Color? color,
    Color? hoverColor,
    Color? selectedColor,
    Size? hoverSize,
    Size? selectedSize,
    double? hoverStrokeWidth,
    double? selectedStrokeWidth,
  }) {
    final baseColor = color ?? Colors.grey;
    final base = FlowMarkerDecoration(
      size: size,
      color: baseColor,
      strokeWidth: strokeWidth,
    );

    return FlowEdgeMarkerStyle(
      markerType: markerType,
      decoration: base,
      hoverDecoration:
          hoverColor != null || hoverSize != null || hoverStrokeWidth != null
              ? base.copyWith(
                  color: hoverColor,
                  size: hoverSize,
                  strokeWidth: hoverStrokeWidth,
                )
              : null,
      selectedDecoration: selectedColor != null ||
              selectedSize != null ||
              selectedStrokeWidth != null
          ? base.copyWith(
              color: selectedColor,
              size: selectedSize,
              strokeWidth: selectedStrokeWidth,
            )
          : null,
    );
  }

  /// Resolves the appropriate decoration based on edge state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledDecoration] (or dimmed [decoration])
  /// 2. Selected - returns [selectedDecoration]
  /// 3. Hovered - returns [hoverDecoration]
  /// 4. Normal - returns [decoration]
  ///
  /// Falls back to [decoration] if state-specific decoration is not defined.
  FlowMarkerDecoration resolve(Set<FlowEdgeState> states) {
    if (states.contains(FlowEdgeState.disabled)) {
      return disabledDecoration ??
          decoration.copyWith(
            color: FlowThemeDim.color(decoration.color),
          );
    }
    if (states.contains(FlowEdgeState.selected)) {
      return selectedDecoration ?? decoration;
    }
    if (states.contains(FlowEdgeState.hovered)) {
      return hoverDecoration ?? decoration;
    }
    return decoration;
  }

  /// Merges this style with another [FlowEdgeMarkerStyle].
  ///
  /// Non-null values from [other] override values from this style.
  /// This follows Flutter's standard merge pattern.
  ///
  /// Example:
  /// ```
  /// final base = FlowEdgeMarkerStyle.light();
  /// final custom = FlowEdgeMarkerStyle.colored(
  ///   markerType: EdgeMarkerType.circle,
  ///   color: Colors.purple,
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: custom's marker type and color with base's state decorations
  /// ```
  FlowEdgeMarkerStyle merge(FlowEdgeMarkerStyle? other) {
    if (other == null) return this;

    return FlowEdgeMarkerStyle(
      markerType: other.markerType != EdgeMarkerType.arrow
          ? other.markerType
          : markerType,
      builder: other.builder ?? builder,
      decoration: other.decoration,
      hoverDecoration: other.hoverDecoration ?? hoverDecoration,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  @override
  FlowEdgeMarkerStyle copyWith({
    EdgeMarkerType? markerType,
    MarkerBuilder? builder,
    FlowMarkerDecoration? decoration,
    FlowMarkerDecoration? hoverDecoration,
    FlowMarkerDecoration? selectedDecoration,
    FlowMarkerDecoration? disabledDecoration,
  }) {
    return FlowEdgeMarkerStyle(
      markerType: markerType ?? this.markerType,
      builder: builder ?? this.builder,
      decoration: decoration ?? this.decoration,
      hoverDecoration: hoverDecoration ?? this.hoverDecoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
    );
  }

  /// Linearly interpolates between this style and another.
  ///
  /// Used by Flutter's animation system for smooth theme transitions.
  /// The parameter [t] is the interpolation factor, from 0.0 to 1.0.
  @override
  FlowEdgeMarkerStyle lerp(
    covariant ThemeExtension<FlowEdgeMarkerStyle>? other,
    double t,
  ) {
    if (other is! FlowEdgeMarkerStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowEdgeMarkerStyle(
      markerType: t < 0.5 ? markerType : other.markerType,
      builder: t < 0.5 ? builder : other.builder,
      decoration: FlowMarkerDecoration.lerp(decoration, other.decoration, t) ??
          decoration,
      hoverDecoration:
          FlowMarkerDecoration.lerp(hoverDecoration, other.hoverDecoration, t),
      selectedDecoration: FlowMarkerDecoration.lerp(
          selectedDecoration, other.selectedDecoration, t),
      disabledDecoration: FlowMarkerDecoration.lerp(
          disabledDecoration, other.disabledDecoration, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowEdgeMarkerStyle &&
        other.markerType == markerType &&
        other.builder == builder &&
        other.decoration == decoration &&
        other.hoverDecoration == hoverDecoration &&
        other.selectedDecoration == selectedDecoration &&
        other.disabledDecoration == disabledDecoration;
  }

  @override
  int get hashCode => Object.hash(
        markerType,
        decoration,
        hoverDecoration,
        selectedDecoration,
        disabledDecoration,
        // Note: builder is intentionally excluded from hashCode
        // Function equality is reference-based and unreliable for hashing
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<EdgeMarkerType>('markerType', markerType));
    properties.add(ObjectFlagProperty<MarkerBuilder?>.has('builder', builder));
    properties.add(DiagnosticsProperty<FlowMarkerDecoration>(
      'decoration',
      decoration,
    ));
    properties.add(DiagnosticsProperty<FlowMarkerDecoration?>(
      'hoverDecoration',
      hoverDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowMarkerDecoration?>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowMarkerDecoration?>(
      'disabledDecoration',
      disabledDecoration,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowEdgeMarkerStyle('
        'type: $markerType, '
        'decoration: $decoration, '
        'hasBuilder: ${builder != null}'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowEdgeMarkerStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowEdgeMarkerStyle;
/// ```
extension FlowEdgeMarkerStyleExtension on ThemeData {
  /// Returns the [FlowEdgeMarkerStyle] from theme extensions.
  ///
  /// Falls back to [FlowEdgeMarkerStyle.light] if not registered.
  FlowEdgeMarkerStyle get flowEdgeMarkerStyle =>
      extension<FlowEdgeMarkerStyle>() ?? FlowEdgeMarkerStyle.light();
}
