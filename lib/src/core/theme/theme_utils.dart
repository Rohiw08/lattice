import 'package:flutter/material.dart';

/// Shared helpers for dimming theme colors/decorations in disabled states.
class FlowThemeDim {
  FlowThemeDim._();

  /// Opacity applied when a disabled style fallback is synthesized.
  static const double disabledOpacity = 0.45;

  /// Returns [c] with [disabledOpacity].
  static Color color(Color c) => c.withValues(alpha: disabledOpacity);

  /// Dims the fill color of a [BoxDecoration]; other decorations are unchanged.
  static Decoration? decoration(Decoration? d) {
    if (d == null) return null;
    if (d is! BoxDecoration) return d;
    final fill = d.color;
    if (fill == null) return d;
    return d.copyWith(color: color(fill));
  }
}
