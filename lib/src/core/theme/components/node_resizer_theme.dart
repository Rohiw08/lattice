import 'package:lattice/src/core/theme/theme_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents the possible states of a resize handle.
enum FlowNodeResizerState { normal, hovered, active, selected, disabled }

/// Defines the visual styling for node resize handles.
@immutable
class FlowNodeResizerStyle extends ThemeExtension<FlowNodeResizerStyle>
    with Diagnosticable {
  /// Color of the handle in its normal state.
  final Color color;

  /// Color of the handle when hovered.
  final Color? hoverColor;

  /// Color of the handle when actively being dragged.
  final Color? activeColor;

  /// Color of the handle when the parent node is selected.
  final Color? selectedColor;

  /// Color of the handle when resizing is disabled.
  final Color? disabledColor;

  /// Size (diameter) of the handle. Falls back to `10.0`.
  ///
  /// Null means "inherit from the layer below" on [merge]; resolved via
  /// [effectiveSize] at read time. Same for the other geometry fields — so a
  /// partial override (e.g. `FlowNodeResizerStyle(color: red)`) changes only
  /// what it sets instead of resetting size/shape/border to defaults.
  final double? size;

  /// Width of the handle's border. Falls back to `1.2`.
  final double? borderWidth;

  /// Color of the handle's border. Falls back to white.
  final Color? borderColor;

  /// Shape of the handle. Falls back to [BoxShape.circle].
  final BoxShape? shape;

  /// Decoration for the box outlining the node being resized.
  ///
  /// Falls back to a transparent box with a faint [color]-tinted border.
  final BoxDecoration? lineDecoration;

  const FlowNodeResizerStyle({
    required this.color,
    this.hoverColor,
    this.activeColor,
    this.selectedColor,
    this.disabledColor,
    this.size,
    this.borderWidth,
    this.borderColor,
    this.shape,
    this.lineDecoration,
  });

  // Resolved values (cascade fallback). Consumers read these, never the raw
  // nullable fields, so an unset field always paints its documented default.
  double get effectiveSize => size ?? 10.0;
  double get effectiveBorderWidth => borderWidth ?? 1.2;
  Color get effectiveBorderColor => borderColor ?? Colors.white;
  BoxShape get effectiveShape => shape ?? BoxShape.circle;
  BoxDecoration get effectiveLineDecoration =>
      lineDecoration ??
      BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color.withAlpha(100), width: 1.0),
      );

  /// Creates a resizer style from simple color values.
  factory FlowNodeResizerStyle.colored({
    required Color color,
    Color? hoverColor,
    Color? activeColor,
    Color? selectedColor,
    Color? disabledColor,
    double? size,
    double? borderWidth,
    Color? borderColor,
    BoxShape? shape,
    BoxDecoration? lineDecoration,
  }) {
    // Only the color palette is forced; unset geometry stays null so it
    // inherits on merge and falls back to defaults via the effectiveX getters.
    return FlowNodeResizerStyle(
      color: color,
      hoverColor: hoverColor,
      activeColor: activeColor,
      selectedColor: selectedColor,
      disabledColor: disabledColor ?? FlowThemeDim.color(color),
      size: size,
      borderWidth: borderWidth,
      borderColor: borderColor,
      shape: shape,
      lineDecoration: lineDecoration,
    );
  }

  factory FlowNodeResizerStyle.light() {
    // xy-theme: 5px handles, `#ffffff` fill, 1px `#9e86ed` border + lines.
    // Lattice has no state variants.
    const color = Color(0xFFFFFFFF);
    const accent = Color(0xFF9E86ED);
    return FlowNodeResizerStyle(
      color: color,
      hoverColor: color,
      activeColor: color,
      selectedColor: color,
      disabledColor: Colors.grey.shade400,
      size: 5.0,
      borderWidth: 1.0,
      borderColor: accent,
      shape: BoxShape.rectangle,
      lineDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: accent,
          width: 1.0,
        ),
      ),
    );
  }

  factory FlowNodeResizerStyle.dark() {
    // xy-theme `.dark`: `#141519` fill, same `#9e86ed` accents.
    const color = Color(0xFF141519);
    const accent = Color(0xFF9E86ED);
    return FlowNodeResizerStyle(
      color: color,
      hoverColor: color,
      activeColor: color,
      selectedColor: color,
      disabledColor: Colors.grey.shade700,
      size: 5.0,
      borderWidth: 1.0,
      borderColor: accent,
      shape: BoxShape.rectangle,
      lineDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: accent,
          width: 1.0,
        ),
      ),
    );
  }

  factory FlowNodeResizerStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowNodeResizerStyle.dark()
        : FlowNodeResizerStyle.light();
  }

  factory FlowNodeResizerStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowNodeResizerStyle(
      color: colorScheme.primary,
      hoverColor: colorScheme.primary.withAlpha(200),
      activeColor: colorScheme.primary.withAlpha(150),
      selectedColor: colorScheme.primary,
      disabledColor: colorScheme.onSurface.withValues(alpha: 0.38),
      borderColor: colorScheme.surface,
      lineDecoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(
          color: colorScheme.primary.withAlpha(100),
          width: 1.0,
        ),
      ),
    );
  }

  /// Creates a resizer style from a Flutter [ThemeData].
  ///
  /// Uses [ThemeData.colorScheme] when Material 3 is enabled,
  /// otherwise falls back to brightness-based styling.
  factory FlowNodeResizerStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowNodeResizerStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowNodeResizerStyle.dark()
        : FlowNodeResizerStyle.light();
  }

  /// Creates a resizer style from a seed color using Material 3 guidelines.
  factory FlowNodeResizerStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowNodeResizerStyle.fromColorScheme(colorScheme);
  }

  /// Resolves the handle color based on its current state.
  ///
  /// Priority: disabled > selected > active > hovered > normal.
  Color resolveColor(Set<FlowNodeResizerState> states) {
    if (states.contains(FlowNodeResizerState.disabled)) {
      return disabledColor ?? FlowThemeDim.color(color);
    }
    if (states.contains(FlowNodeResizerState.selected)) {
      return selectedColor ?? color;
    }
    if (states.contains(FlowNodeResizerState.active)) {
      return activeColor ?? hoverColor ?? color;
    }
    if (states.contains(FlowNodeResizerState.hovered)) {
      return hoverColor ?? color;
    }
    return color;
  }

  /// Merges this (parent) style with [other] (child).
  ///
  /// "Other wins, nulls inherit": a field the child leaves null keeps the
  /// parent's value, so a partial override changes only what it sets.
  /// [color] is required, so the child always provides it.
  FlowNodeResizerStyle merge(FlowNodeResizerStyle? other) {
    if (other == null) return this;
    return FlowNodeResizerStyle(
      color: other.color,
      hoverColor: other.hoverColor ?? hoverColor,
      activeColor: other.activeColor ?? activeColor,
      selectedColor: other.selectedColor ?? selectedColor,
      disabledColor: other.disabledColor ?? disabledColor,
      size: other.size ?? size,
      borderWidth: other.borderWidth ?? borderWidth,
      borderColor: other.borderColor ?? borderColor,
      shape: other.shape ?? shape,
      lineDecoration: other.lineDecoration ?? lineDecoration,
    );
  }

  @override
  FlowNodeResizerStyle copyWith({
    Color? color,
    Color? hoverColor,
    Color? activeColor,
    Color? selectedColor,
    Color? disabledColor,
    double? size,
    double? borderWidth,
    Color? borderColor,
    BoxShape? shape,
    BoxDecoration? lineDecoration,
  }) {
    return FlowNodeResizerStyle(
      color: color ?? this.color,
      hoverColor: hoverColor ?? this.hoverColor,
      activeColor: activeColor ?? this.activeColor,
      selectedColor: selectedColor ?? this.selectedColor,
      disabledColor: disabledColor ?? this.disabledColor,
      size: size ?? this.size,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      shape: shape ?? this.shape,
      lineDecoration: lineDecoration ?? this.lineDecoration,
    );
  }

  @override
  FlowNodeResizerStyle lerp(
    covariant ThemeExtension<FlowNodeResizerStyle>? other,
    double t,
  ) {
    if (other is! FlowNodeResizerStyle) return this;
    return FlowNodeResizerStyle(
      color: Color.lerp(color, other.color, t)!,
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t),
      activeColor: Color.lerp(activeColor, other.activeColor, t),
      selectedColor: Color.lerp(selectedColor, other.selectedColor, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      size: lerpDouble(size, other.size, t) ?? size,
      borderWidth: lerpDouble(borderWidth, other.borderWidth, t) ?? borderWidth,
      borderColor: Color.lerp(borderColor, other.borderColor, t) ?? borderColor,
      shape: t < 0.5 ? shape : other.shape,
      lineDecoration:
          BoxDecoration.lerp(lineDecoration, other.lineDecoration, t) ??
              lineDecoration,
    );
  }

  double? lerpDouble(num? a, num? b, double t) {
    if (a == null && b == null) return null;
    return (a ?? 0) * (1.0 - t) + (b ?? 0) * t;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowNodeResizerStyle &&
        other.color == color &&
        other.hoverColor == hoverColor &&
        other.activeColor == activeColor &&
        other.selectedColor == selectedColor &&
        other.disabledColor == disabledColor &&
        other.size == size &&
        other.borderWidth == borderWidth &&
        other.borderColor == borderColor &&
        other.shape == shape &&
        other.lineDecoration == lineDecoration;
  }

  @override
  int get hashCode => Object.hash(
        color,
        hoverColor,
        activeColor,
        selectedColor,
        disabledColor,
        size,
        borderWidth,
        borderColor,
        shape,
        lineDecoration,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('color', color));
    properties.add(ColorProperty('hoverColor', hoverColor));
    properties.add(ColorProperty('activeColor', activeColor));
    properties.add(ColorProperty('selectedColor', selectedColor));
    properties.add(ColorProperty('disabledColor', disabledColor));
    properties.add(DoubleProperty('size', size));
    properties.add(DoubleProperty('borderWidth', borderWidth));
    properties.add(ColorProperty('borderColor', borderColor));
    properties.add(EnumProperty<BoxShape?>('shape', shape));
    properties.add(
        DiagnosticsProperty<BoxDecoration?>('lineDecoration', lineDecoration));
  }
}

extension FlowNodeResizerStyleExtension on ThemeData {
  FlowNodeResizerStyle get flowNodeResizerStyle =>
      extension<FlowNodeResizerStyle>() ?? FlowNodeResizerStyle.light();
}
