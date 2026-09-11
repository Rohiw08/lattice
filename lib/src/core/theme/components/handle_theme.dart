import 'package:lattice/src/core/theme/theme_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents the possible states of a flow handle.
enum FlowHandleState {
  normal,
  hovered,
  selected,
  active,
  validTarget,
  invalidTarget,
  disabled,
}

/// Defines the visual styling for flow canvas handles.
///
/// This style defines the appearance of handles through decorations,
/// which can be simple colors, gradients, images, or custom decorations.
/// For completely custom handle widgets, pass a [child] to the [FlowHandle]
/// widget instead of using the theme.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowHandleStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowHandleStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowHandleStyle;
/// final decoration = style.resolveDecoration({FlowHandleState.hovered});
/// ```
///
/// ## Examples
///
/// ```
/// // Simple colored handle
/// FlowHandleStyle.colored(
///   color: Colors.grey,
///   activeColor: Colors.blue,
/// )
///
/// // Gradient handle
/// FlowHandleStyle(
///   decoration: BoxDecoration(
///     gradient: RadialGradient(
///       colors: [Colors.blue, Colors.purple],
///     ),
///     shape: BoxShape.circle,
///   ),
/// )
///
/// // From Material 3 color scheme
/// FlowHandleStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// )
/// ```
@immutable
class FlowHandleStyle extends ThemeExtension<FlowHandleStyle>
    with Diagnosticable {
  /// Decoration for the handle in its normal state.
  final Decoration decoration;

  /// Decoration for the handle in hovered state.
  ///
  /// Falls back to [decoration] if null.
  final Decoration? hoverDecoration;

  /// Decoration for the handle in selected state (e.g. click-connect source).
  ///
  /// Falls back through [activeDecoration] → [hoverDecoration] → [decoration].
  final Decoration? selectedDecoration;

  /// Decoration for the handle in active state (e.g. drag-connect source).
  ///
  /// Falls back to [hoverDecoration] or [decoration] if null.
  final Decoration? activeDecoration;

  /// Decoration for the handle when it's a valid target.
  ///
  /// Falls back through the state hierarchy if null.
  final Decoration? validTargetDecoration;

  /// Decoration for the handle when it's an invalid target.
  ///
  /// Falls back through [activeDecoration] → [decoration] if null.
  final Decoration? invalidTargetDecoration;

  /// Decoration for the handle when disabled (node not connectable).
  ///
  /// Falls back to a dimmed [decoration] when it is a [BoxDecoration].
  final Decoration? disabledDecoration;

  const FlowHandleStyle({
    required this.decoration,
    this.hoverDecoration,
    this.selectedDecoration,
    this.activeDecoration,
    this.validTargetDecoration,
    this.invalidTargetDecoration,
    this.disabledDecoration,
  });

  /// Creates a handle style from simple color values.
  ///
  /// This is the most common use case for basic colored handles.
  ///
  /// At minimum, provide [color] to create a valid style.
  ///
  /// Example:
  /// ```
  /// FlowHandleStyle.colored(
  ///   color: Colors.grey.shade400,
  ///   hoverColor: Colors.blue.shade400,
  ///   activeColor: Colors.blue.shade600,
  ///   validTargetColor: Colors.green.shade500,
  ///   borderColor: Colors.white,
  ///   borderWidth: 2.0,
  ///   shape: BoxShape.circle,
  ///   shadows: [
  ///     BoxShadow(
  ///       color: Colors.black26,
  ///       blurRadius: 4,
  ///       offset: Offset(0, 2),
  ///     ),
  ///   ],
  /// )
  /// ```
  factory FlowHandleStyle.colored({
    required Color color,
    Color? hoverColor,
    Color? selectedColor,
    Color? activeColor,
    Color? validTargetColor,
    Color? invalidTargetColor,
    Color? disabledColor,
    Color? borderColor,
    double borderWidth = 1.5,
    BoxShape shape = BoxShape.circle,
    List<BoxShadow>? shadows,
  }) {
    Decoration createDecoration(Color? fill) {
      return BoxDecoration(
        color: fill,
        shape: shape,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        boxShadow: shadows,
      );
    }

    return FlowHandleStyle(
      decoration: createDecoration(color),
      hoverDecoration: hoverColor != null ? createDecoration(hoverColor) : null,
      selectedDecoration:
          selectedColor != null ? createDecoration(selectedColor) : null,
      activeDecoration:
          activeColor != null ? createDecoration(activeColor) : null,
      validTargetDecoration:
          validTargetColor != null ? createDecoration(validTargetColor) : null,
      invalidTargetDecoration: invalidTargetColor != null
          ? createDecoration(invalidTargetColor)
          : null,
      disabledDecoration:
          disabledColor != null ? createDecoration(disabledColor) : null,
    );
  }

  /// Creates a light theme handle style.
  ///
  /// Suitable for light mode applications with a clean, minimal aesthetic.
  factory FlowHandleStyle.light() {
    // Lattice: `#1a192b` fill, `#fff` 1px border, valid `#ff0072`,
    // invalid `#ff6060` (classic connection feedback colors).
    const color = Color(0xFF1A192B);
    return FlowHandleStyle.colored(
      color: color,
      hoverColor: color,
      selectedColor: color,
      activeColor: color,
      validTargetColor: const Color(0xFFFF0072),
      invalidTargetColor: const Color(0xFFFF6060),
      disabledColor: FlowThemeDim.color(color),
      borderColor: Colors.white,
      borderWidth: 1,
    );
  }

  /// Creates a dark theme handle style.
  ///
  /// Suitable for dark mode applications with subtle contrast.
  factory FlowHandleStyle.dark() {
    // Lattice `.dark` handle: `#bebebe` / border `#1e1e1e`.
    // Valid/invalid are the same as light (classic Lattice colors).
    const color = Color(0xFFBEBEBE);
    return FlowHandleStyle.colored(
      color: color,
      hoverColor: color,
      selectedColor: color,
      activeColor: color,
      validTargetColor: const Color(0xFFFF0072),
      invalidTargetColor: const Color(0xFFFF6060),
      disabledColor: FlowThemeDim.color(color),
      borderColor: const Color(0xFF1E1E1E),
      borderWidth: 1,
    );
  }

  /// Creates a handle style that adapts to the system brightness.
  ///
  /// Automatically selects [light] or [dark] based on the current theme.
  factory FlowHandleStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowHandleStyle.dark()
        : FlowHandleStyle.light();
  }

  /// Creates a handle style from a Material 3 color scheme.
  ///
  /// Uses semantic colors from the color scheme for consistent theming.
  factory FlowHandleStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowHandleStyle.colored(
      color: colorScheme.outline,
      hoverColor: colorScheme.primary.withAlpha(200),
      // Lattice-ish: selected matches active.
      selectedColor: colorScheme.primary,
      activeColor: colorScheme.primary,
      validTargetColor: colorScheme.tertiary,
      invalidTargetColor: colorScheme.error,
      disabledColor: colorScheme.outline.withAlpha(100),
      borderColor: colorScheme.surface,
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withAlpha(50),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Creates a handle style from a seed color using Material 3 guidelines.
  ///
  /// Generates a harmonious color scheme from a single seed color.
  factory FlowHandleStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowHandleStyle.fromColorScheme(colorScheme);
  }

  /// Creates a handle style from a Flutter [ThemeData].
  factory FlowHandleStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowHandleStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowHandleStyle.dark()
        : FlowHandleStyle.light();
  }

  /// Resolves the appropriate decoration based on handle state.
  ///
  /// State priority (highest to lowest):
  /// 1. [FlowHandleState.disabled]
  /// 2. [FlowHandleState.invalidTarget]
  /// 3. [FlowHandleState.validTarget]
  /// 4. [FlowHandleState.selected]
  /// 5. [FlowHandleState.active]
  /// 6. [FlowHandleState.hovered]
  /// 7. [FlowHandleState.normal] — returns [decoration]
  ///
  /// Falls back through the hierarchy if a state-specific decoration is null.
  Decoration resolveDecoration(Set<FlowHandleState> states) {
    if (states.contains(FlowHandleState.disabled)) {
      if (disabledDecoration != null) return disabledDecoration!;
      return FlowThemeDim.decoration(decoration) ?? decoration;
    }
    if (states.contains(FlowHandleState.invalidTarget)) {
      return invalidTargetDecoration ?? activeDecoration ?? decoration;
    }
    if (states.contains(FlowHandleState.validTarget)) {
      return validTargetDecoration ??
          activeDecoration ??
          hoverDecoration ??
          decoration;
    }
    if (states.contains(FlowHandleState.selected)) {
      return selectedDecoration ??
          activeDecoration ??
          hoverDecoration ??
          decoration;
    }
    if (states.contains(FlowHandleState.active)) {
      return activeDecoration ?? hoverDecoration ?? decoration;
    }
    if (states.contains(FlowHandleState.hovered)) {
      return hoverDecoration ?? decoration;
    }
    return decoration;
  }

  /// Merges this style with another, preferring the other's values.
  ///
  /// Null values in [other] will fall back to this style's values.
  /// This is useful for creating style variants.
  ///
  /// Example:
  /// ```
  /// final baseStyle = FlowHandleStyle.light();
  /// final customStyle = FlowHandleStyle.colored(
  ///   color: Colors.grey,
  ///   activeColor: Colors.purple,
  /// );
  /// final merged = baseStyle.merge(customStyle);
  /// // merged will use baseStyle's normal/hover/validTarget colors
  /// // but customStyle's active color
  /// ```
  FlowHandleStyle merge(FlowHandleStyle? other) {
    if (other == null) return this;
    return FlowHandleStyle(
      decoration: other.decoration,
      hoverDecoration: other.hoverDecoration ?? hoverDecoration,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      activeDecoration: other.activeDecoration ?? activeDecoration,
      validTargetDecoration:
          other.validTargetDecoration ?? validTargetDecoration,
      invalidTargetDecoration:
          other.invalidTargetDecoration ?? invalidTargetDecoration,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
    );
  }

  @override
  FlowHandleStyle copyWith({
    Decoration? decoration,
    Decoration? hoverDecoration,
    Decoration? selectedDecoration,
    Decoration? activeDecoration,
    Decoration? validTargetDecoration,
    Decoration? invalidTargetDecoration,
    Decoration? disabledDecoration,
  }) {
    return FlowHandleStyle(
      decoration: decoration ?? this.decoration,
      hoverDecoration: hoverDecoration ?? this.hoverDecoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      activeDecoration: activeDecoration ?? this.activeDecoration,
      validTargetDecoration:
          validTargetDecoration ?? this.validTargetDecoration,
      invalidTargetDecoration:
          invalidTargetDecoration ?? this.invalidTargetDecoration,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
    );
  }

  @override
  FlowHandleStyle lerp(
    covariant ThemeExtension<FlowHandleStyle>? other,
    double t,
  ) {
    if (other is! FlowHandleStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowHandleStyle(
      decoration:
          Decoration.lerp(decoration, other.decoration, t) ?? decoration,
      hoverDecoration:
          Decoration.lerp(hoverDecoration, other.hoverDecoration, t) ??
              hoverDecoration,
      selectedDecoration:
          Decoration.lerp(selectedDecoration, other.selectedDecoration, t) ??
              selectedDecoration,
      activeDecoration:
          Decoration.lerp(activeDecoration, other.activeDecoration, t) ??
              activeDecoration,
      validTargetDecoration: Decoration.lerp(
              validTargetDecoration, other.validTargetDecoration, t) ??
          validTargetDecoration,
      invalidTargetDecoration: Decoration.lerp(
              invalidTargetDecoration, other.invalidTargetDecoration, t) ??
          invalidTargetDecoration,
      disabledDecoration:
          Decoration.lerp(disabledDecoration, other.disabledDecoration, t) ??
              disabledDecoration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowHandleStyle &&
        other.decoration == decoration &&
        other.hoverDecoration == hoverDecoration &&
        other.selectedDecoration == selectedDecoration &&
        other.activeDecoration == activeDecoration &&
        other.validTargetDecoration == validTargetDecoration &&
        other.invalidTargetDecoration == invalidTargetDecoration &&
        other.disabledDecoration == disabledDecoration;
  }

  @override
  int get hashCode => Object.hash(
        decoration,
        hoverDecoration,
        selectedDecoration,
        activeDecoration,
        validTargetDecoration,
        invalidTargetDecoration,
        disabledDecoration,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>(
      'decoration',
      decoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'hoverDecoration',
      hoverDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'activeDecoration',
      activeDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'validTargetDecoration',
      validTargetDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'invalidTargetDecoration',
      invalidTargetDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration>(
      'disabledDecoration',
      disabledDecoration,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowHandleStyle('
        'decoration: $decoration, '
        'hover: $hoverDecoration, '
        'selected: $selectedDecoration, '
        'active: $activeDecoration, '
        'validTarget: $validTargetDecoration, '
        'invalidTarget: $invalidTargetDecoration, '
        'disabled: $disabledDecoration'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowHandleStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowHandleStyle;
/// ```
extension FlowHandleStyleExtension on ThemeData {
  /// Returns the [FlowHandleStyle] from theme extensions.
  ///
  /// Falls back to [FlowHandleStyle.light] if not registered.
  FlowHandleStyle get flowHandleStyle =>
      extension<FlowHandleStyle>() ?? FlowHandleStyle.light();
}
