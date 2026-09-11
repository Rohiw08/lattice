import 'dart:ui' show lerpDouble;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// A function that defines a custom drawing routine for a connection path.
///
/// Use this to create custom shapes (e.g., arcs, custom curves) for the
/// interactive connection line drawn from a source to the cursor.
///
/// The [canvas] is the drawing surface, [start] is the source position,
/// [end] is the cursor position, and [style] contains the resolved stroke styling.
///
/// Example:
/// ```
/// void drawCustomCurve(
///   Canvas canvas,
///   Offset start,
///   Offset end,
///   FlowConnectionStrokeStyle style,
/// ) {
///   final paint = Paint()
///     ..color = style.color
///     ..strokeWidth = style.strokeWidth
///     ..style = PaintingStyle.stroke;
///
///   final path = Path()
///     ..moveTo(start.dx, start.dy)
///     ..quadraticBezierTo(
///       (start.dx + end.dx) / 2,
///       start.dy,
///       end.dx,
///       end.dy,
///     );
///
///   canvas.drawPath(path, paint);
/// }
/// ```
///
/// See also:
///
///  * [CustomPainter], Flutter's custom painting API
///  * [Path], for creating complex shapes
typedef ConnectionBuilder = void Function(
  Canvas canvas,
  Offset start,
  Offset end,
  FlowConnectionStrokeStyle style,
);

/// Defines the stroke style for a connection line.
///
/// Encapsulates properties like [strokeWidth] and [color] for a consistent
/// and reusable line style definition.
///
/// Example:
/// ```
/// const style = FlowConnectionStrokeStyle(
///   strokeWidth: 2.0,
///   color: Colors.blue,
/// );
/// ```
class FlowConnectionStrokeStyle extends Equatable with Diagnosticable {
  /// The thickness of the line in logical pixels.
  final double strokeWidth;

  /// The color of the line.
  final Color color;

  /// Creates a stroke style for a connection.
  const FlowConnectionStrokeStyle({
    required this.strokeWidth,
    required this.color,
  });

  /// Returns a new instance with the given fields replaced with the new values.
  FlowConnectionStrokeStyle copyWith({
    double? strokeWidth,
    Color? color,
  }) {
    return FlowConnectionStrokeStyle(
      strokeWidth: strokeWidth ?? this.strokeWidth,
      color: color ?? this.color,
    );
  }

  /// Linearly interpolates between two stroke styles.
  ///
  /// Returns null if both [a] and [b] are null.
  /// Returns the non-null style if only one is null.
  /// Otherwise interpolates all properties using [t].
  static FlowConnectionStrokeStyle? lerp(
    FlowConnectionStrokeStyle? a,
    FlowConnectionStrokeStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    if (identical(a, b)) return a;
    if (t == 0.0) return a;
    if (t == 1.0) return b;

    return FlowConnectionStrokeStyle(
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? a.strokeWidth,
      color: Color.lerp(a.color, b.color, t) ?? a.color,
    );
  }

  @override
  List<Object?> get props => [strokeWidth, color];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('strokeWidth', strokeWidth));
    properties.add(ColorProperty('color', color));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowConnectionStrokeStyle(width: $strokeWidth, color: $color)';
  }
}

/// Defines the visual style for the interactive connection line (edge)
/// drawn between a source port and the cursor during a connection gesture.
///
/// This style controls the appearance of the temporary connection line shown
/// when dragging from a port to create a new edge. It supports different visual
/// states (active, valid target) and customizable path rendering.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowConnectionStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowConnectionStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowConnectionStyle;
/// ```
///
/// ## Examples
///
/// Using predefined styles:
///
/// ```
/// // Light theme
/// final light = FlowConnectionStyle.light();
///
/// // Dark theme
/// final dark = FlowConnectionStyle.dark();
///
/// // From Material 3 color scheme
/// final m3 = FlowConnectionStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// );
/// ```
///
/// Custom connection with markers:
///
/// ```
/// FlowConnectionStyle(
///   activeDecoration: FlowConnectionStrokeStyle(
///     strokeWidth: 2.0,
///     color: Colors.blue,
///   ),
///   validTargetDecoration: FlowConnectionStrokeStyle(
///     strokeWidth: 2.5,
///     color: Colors.green,
///   ),
///   pathType: EdgePathType.bezier,
///   endMarkerStyle: FlowEdgeMarkerStyle.colored(
///     markerType: EdgeMarkerType.arrow,
///     color: Colors.blue,
///   ),
/// )
/// ```
///
/// ## Visual States
///
/// - Active: The connection is being drawn (uses [activeDecoration])
/// - Valid Target: Hovering over a valid connection target (uses [validTargetDecoration])
/// - Invalid Target: Hovering over an invalid connection target (uses [invalidTargetDecoration])
///
/// See also:
///
///  * [FlowEdgeStyle], for styling permanent edges
///  * [FlowEdgeMarkerStyle], for endpoint marker styling
///  * [EdgePathType], for available path shapes
@immutable
class FlowConnectionStyle extends ThemeExtension<FlowConnectionStyle>
    with Diagnosticable {
  /// The stroke style of the connection line in its default, active state.
  ///
  /// This is the base styling shown when drawing a connection.
  final FlowConnectionStrokeStyle activeDecoration;

  /// The stroke style of the connection line when hovering over a valid target port.
  ///
  /// If null, uses [activeDecoration] when over a valid target.
  final FlowConnectionStrokeStyle? validTargetDecoration;

  /// The stroke style of the connection line when hovering over an invalid target port.
  ///
  /// If null, uses [activeDecoration] when over an invalid target.
  final FlowConnectionStrokeStyle? invalidTargetDecoration;

  /// The shape of the connection line's path.
  ///
  /// Defaults to [EdgePathType.bezier] for smooth curves.
  final EdgePathType pathType;

  /// The marker style for the start of the connection line (the source port).
  ///
  /// If null, no start marker is rendered.
  final FlowEdgeMarkerStyle? startMarkerStyle;

  /// The marker style for the end of the connection line (the cursor position).
  ///
  /// If null, no end marker is rendered. Typically shows an arrow
  /// indicating the connection direction.
  final FlowEdgeMarkerStyle? endMarkerStyle;

  /// An optional builder to render a custom path for the connection line.
  ///
  /// When provided, this overrides the default path drawing based on [pathType].
  /// Use this for completely custom connection line shapes.
  final ConnectionBuilder? connectionBuilder;

  /// Creates a flow connection style.
  ///
  /// The [activeDecoration] is required as it provides the base styling.
  /// All other properties are optional.
  const FlowConnectionStyle({
    this.pathType = EdgePathType.bezier,
    // Lattice defaults: `connectionline-stroke-default: #b1b1b7`
    // and `connectionline-stroke-width-default: 1` (no end marker).
    this.activeDecoration = const FlowConnectionStrokeStyle(
      strokeWidth: 1.0,
      color: Color(0xFFB1B1B7),
    ),
    this.validTargetDecoration,
    this.invalidTargetDecoration,
    this.startMarkerStyle,
    this.endMarkerStyle,
    this.connectionBuilder,
  });

  /// Creates a connection style from simple color values.
  ///
  /// [validColor] colors the line over a valid target; [invalidColor] over
  /// an invalid one. Both fall back to [color].
  factory FlowConnectionStyle.colored({
    required Color color,
    Color? validColor,
    Color? invalidColor,
    double strokeWidth = 1.0,
    EdgePathType pathType = EdgePathType.bezier,
  }) {
    FlowConnectionStrokeStyle stroke(Color c) =>
        FlowConnectionStrokeStyle(strokeWidth: strokeWidth, color: c);
    return FlowConnectionStyle(
      pathType: pathType,
      activeDecoration: stroke(color),
      validTargetDecoration: stroke(validColor ?? color),
      invalidTargetDecoration: stroke(invalidColor ?? color),
    );
  }

  /// Creates a light theme connection style matching Lattice.
  ///
  /// Active `#b1b1b7` w1; valid `#555` w1.5; invalid `#ff6060` w1.5.
  factory FlowConnectionStyle.light() {
    return const FlowConnectionStyle(
      activeDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFFB1B1B7),
      ),
      validTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.5,
        color: Color(0xFF555555),
      ),
      invalidTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.5,
        color: Color(0xFFFF6060),
      ),
    );
  }

  /// Creates a dark theme connection style matching Lattice `.dark`.
  ///
  /// Active stays `#b1b1b7` w1 (no dark override in v12);
  /// valid `#bbb` w1.5; invalid `#ff6060` w1.5.
  factory FlowConnectionStyle.dark() {
    return const FlowConnectionStyle(
      activeDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.0,
        color: Color(0xFFB1B1B7),
      ),
      validTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.5,
        color: Color(0xFFBBBBBB),
      ),
      invalidTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.5,
        color: Color(0xFFFF6060),
      ),
    );
  }

  /// Creates a connection style that adapts to the system theme.
  ///
  /// Uses [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling (both match Lattice connection greys).
  factory FlowConnectionStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowConnectionStyle.dark()
        : FlowConnectionStyle.light();
  }

  /// Creates a style based on a Material 3 [ColorScheme].
  ///
  /// Prefer [light]/[dark]/[system] for Lattice visual parity.
  factory FlowConnectionStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowConnectionStyle(
      activeDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.outline,
      ),
      validTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.outline,
      ),
      invalidTargetDecoration: FlowConnectionStrokeStyle(
        strokeWidth: 1.0,
        color: colorScheme.error,
      ),
      pathType: EdgePathType.bezier,
    );
  }

  /// Creates a style based on a single seed color using Material 3 color generation.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the connection styling.
  factory FlowConnectionStyle.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowConnectionStyle.fromColorScheme(colorScheme);
  }

  /// Creates a connection style from a Flutter [ThemeData].
  factory FlowConnectionStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowConnectionStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowConnectionStyle.dark()
        : FlowConnectionStyle.light();
  }

  /// Resolves the stroke style for the given connection [validity].
  ///
  /// - [ConnectionValidity.valid] → [validTargetDecoration] ?? [activeDecoration]
  /// - [ConnectionValidity.invalid] → [invalidTargetDecoration] ?? [activeDecoration]
  /// - [ConnectionValidity.none] → [activeDecoration]
  FlowConnectionStrokeStyle resolveStroke(ConnectionValidity validity) {
    return switch (validity) {
      ConnectionValidity.valid =>
        validTargetDecoration ?? activeDecoration,
      ConnectionValidity.invalid =>
        invalidTargetDecoration ?? activeDecoration,
      ConnectionValidity.none => activeDecoration,
    };
  }

  /// Returns a new style that merges this style with another.
  ///
  /// Non-null values in [other] override values in this instance.
  ///
  /// Example:
  /// ```
  /// final base = FlowConnectionStyle.light();
  /// final custom = FlowConnectionStyle(
  ///   activeDecoration: FlowConnectionStrokeStyle(
  ///     strokeWidth: 3.0,
  ///     color: Colors.purple,
  ///   ),
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: custom's active decoration with base's other properties
  /// ```
  FlowConnectionStyle merge(FlowConnectionStyle? other) {
    if (other == null) return this;
    return FlowConnectionStyle(
      activeDecoration: other.activeDecoration,
      validTargetDecoration:
          other.validTargetDecoration ?? validTargetDecoration,
      invalidTargetDecoration:
          other.invalidTargetDecoration ?? invalidTargetDecoration,
      pathType: other.pathType,
      startMarkerStyle: other.startMarkerStyle ?? startMarkerStyle,
      endMarkerStyle: other.endMarkerStyle ?? endMarkerStyle,
      connectionBuilder: other.connectionBuilder ?? connectionBuilder,
    );
  }

  @override
  FlowConnectionStyle copyWith({
    FlowConnectionStrokeStyle? activeDecoration,
    FlowConnectionStrokeStyle? validTargetDecoration,
    FlowConnectionStrokeStyle? invalidTargetDecoration,
    EdgePathType? pathType,
    FlowEdgeMarkerStyle? startMarkerStyle,
    FlowEdgeMarkerStyle? endMarkerStyle,
    ConnectionBuilder? connectionBuilder,
  }) {
    return FlowConnectionStyle(
      activeDecoration: activeDecoration ?? this.activeDecoration,
      validTargetDecoration:
          validTargetDecoration ?? this.validTargetDecoration,
      invalidTargetDecoration:
          invalidTargetDecoration ?? this.invalidTargetDecoration,
      pathType: pathType ?? this.pathType,
      startMarkerStyle: startMarkerStyle ?? this.startMarkerStyle,
      endMarkerStyle: endMarkerStyle ?? this.endMarkerStyle,
      connectionBuilder: connectionBuilder ?? this.connectionBuilder,
    );
  }

  @override
  FlowConnectionStyle lerp(
    covariant ThemeExtension<FlowConnectionStyle>? other,
    double t,
  ) {
    if (other is! FlowConnectionStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowConnectionStyle(
      activeDecoration: FlowConnectionStrokeStyle.lerp(
              activeDecoration, other.activeDecoration, t) ??
          activeDecoration,
      validTargetDecoration: FlowConnectionStrokeStyle.lerp(
          validTargetDecoration, other.validTargetDecoration, t),
      invalidTargetDecoration: FlowConnectionStrokeStyle.lerp(
          invalidTargetDecoration, other.invalidTargetDecoration, t),
      pathType: t < 0.5 ? pathType : other.pathType,
      startMarkerStyle:
          _lerpMarker(startMarkerStyle, other.startMarkerStyle, t),
      endMarkerStyle: _lerpMarker(endMarkerStyle, other.endMarkerStyle, t),
      connectionBuilder: t < 0.5 ? connectionBuilder : other.connectionBuilder,
    );
  }

  /// Safely interpolates between two [FlowEdgeMarkerStyle] objects.
  static FlowEdgeMarkerStyle? _lerpMarker(
    FlowEdgeMarkerStyle? a,
    FlowEdgeMarkerStyle? b,
    double t,
  ) {
    if (a == null && b == null) return null;
    if (a == null) return b;
    if (b == null) return a;
    return a.lerp(b, t) as FlowEdgeMarkerStyle?;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowConnectionStyle &&
        other.activeDecoration == activeDecoration &&
        other.validTargetDecoration == validTargetDecoration &&
        other.invalidTargetDecoration == invalidTargetDecoration &&
        other.pathType == pathType &&
        other.startMarkerStyle == startMarkerStyle &&
        other.endMarkerStyle == endMarkerStyle &&
        other.connectionBuilder == connectionBuilder;
  }

  @override
  int get hashCode => Object.hash(
        activeDecoration,
        validTargetDecoration,
        invalidTargetDecoration,
        pathType,
        startMarkerStyle,
        endMarkerStyle,
        // Note: connectionBuilder is intentionally excluded from hashCode
        // Function equality is reference-based and unreliable for hashing
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlowConnectionStrokeStyle>(
      'activeDecoration',
      activeDecoration,
    ));
    properties.add(DiagnosticsProperty<FlowConnectionStrokeStyle?>(
      'validTargetDecoration',
      validTargetDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowConnectionStrokeStyle?>(
      'invalidTargetDecoration',
      invalidTargetDecoration,
      defaultValue: null,
    ));
    properties.add(EnumProperty<EdgePathType>('pathType', pathType));
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
    properties.add(ObjectFlagProperty<ConnectionBuilder?>.has(
      'connectionBuilder',
      connectionBuilder,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowConnectionStyle('
        'pathType: $pathType, '
        'activeDecoration: $activeDecoration, '
        'hasBuilder: ${connectionBuilder != null}'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowConnectionStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowConnectionStyle;
/// ```
extension FlowConnectionStyleExtension on ThemeData {
  /// Returns the [FlowConnectionStyle] from theme extensions.
  ///
  /// Falls back to [FlowConnectionStyle.light] if not registered.
  FlowConnectionStyle get flowConnectionStyle =>
      extension<FlowConnectionStyle>() ?? FlowConnectionStyle.light();
}
