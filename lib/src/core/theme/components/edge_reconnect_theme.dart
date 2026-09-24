import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Chrome for edge reconnect / updater endpoints (React Flow `.xy-flow__edgeupdater`).
///
/// Thin style — fill + border only, no interaction states (like
/// [FlowSelectionStyle] / [FlowBackgroundStyle]).
@immutable
class FlowEdgeReconnectStyle extends ThemeExtension<FlowEdgeReconnectStyle>
    with Diagnosticable {
  /// Fill color of the reconnect handle.
  final Color color;

  /// Border color.
  final Color borderColor;

  /// Border width.
  final double borderWidth;

  const FlowEdgeReconnectStyle({
    required this.color,
    required this.borderColor,
    this.borderWidth = 2.0,
  });

  /// Creates a reconnect style from simple color values.
  factory FlowEdgeReconnectStyle.colored({
    required Color color,
    required Color borderColor,
    double borderWidth = 2.0,
  }) {
    return FlowEdgeReconnectStyle(
      color: color,
      borderColor: borderColor,
      borderWidth: borderWidth,
    );
  }

  /// Light: React Flow handle greys (`#1a192b` fill, white border).
  factory FlowEdgeReconnectStyle.light() {
    return const FlowEdgeReconnectStyle(
      color: Color(0xFF1A192B),
      borderColor: Color(0xFFFFFFFF),
      borderWidth: 2.0,
    );
  }

  /// Dark: inverted React Flow handle greys.
  factory FlowEdgeReconnectStyle.dark() {
    return const FlowEdgeReconnectStyle(
      color: Color(0xFFBEBEBE),
      borderColor: Color(0xFF1E1E1E),
      borderWidth: 2.0,
    );
  }

  factory FlowEdgeReconnectStyle.system(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? FlowEdgeReconnectStyle.dark()
        : FlowEdgeReconnectStyle.light();
  }

  factory FlowEdgeReconnectStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowEdgeReconnectStyle(
      color: colorScheme.onSurface,
      borderColor: colorScheme.surface,
      borderWidth: 2.0,
    );
  }

  factory FlowEdgeReconnectStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    return FlowEdgeReconnectStyle.fromColorScheme(
      ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness),
    );
  }

  factory FlowEdgeReconnectStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowEdgeReconnectStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowEdgeReconnectStyle.dark()
        : FlowEdgeReconnectStyle.light();
  }

  FlowEdgeReconnectStyle merge(FlowEdgeReconnectStyle? other) {
    if (other == null) return this;
    return FlowEdgeReconnectStyle(
      color: other.color,
      borderColor: other.borderColor,
      borderWidth: other.borderWidth,
    );
  }

  @override
  FlowEdgeReconnectStyle copyWith({
    Color? color,
    Color? borderColor,
    double? borderWidth,
  }) {
    return FlowEdgeReconnectStyle(
      color: color ?? this.color,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  FlowEdgeReconnectStyle lerp(
    covariant ThemeExtension<FlowEdgeReconnectStyle>? other,
    double t,
  ) {
    if (other is! FlowEdgeReconnectStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowEdgeReconnectStyle(
      color: Color.lerp(color, other.color, t) ?? color,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      borderWidth:
          lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowEdgeReconnectStyle &&
        other.color == color &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth;
  }

  @override
  int get hashCode => Object.hash(color, borderColor, borderWidth);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(DoubleProperty('borderWidth', borderWidth));
  }
}

extension FlowEdgeReconnectStyleExtension on ThemeData {
  FlowEdgeReconnectStyle get flowEdgeReconnectStyle =>
      extension<FlowEdgeReconnectStyle>() ?? FlowEdgeReconnectStyle.light();
}
