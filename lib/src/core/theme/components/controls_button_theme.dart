import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Represents the possible states of a flow canvas button.
enum FlowControlState { normal, hovered, selected, disabled }

/// Defines the visual styling for flow canvas buttons.
///
/// Controls are interactive UI elements overlaid on the flow canvas, such as
/// zoom in/out buttons, fit-to-view buttons, minimap toggles, and other
/// canvas interaction controls. This style manages both their decoration
/// (background, border, shadows) and icon appearance across different states.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowControlsButtonStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowControlsButtonStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowControlsButtonStyle;
/// final decoration = style.resolveDecoration({FlowControlState.hovered});
/// final iconTheme = style.resolveIconTheme({FlowControlState.hovered});
/// ```
///
/// ## Examples
///
/// Creating a custom button style:
///
/// ```
/// FlowControlsButtonStyle(
///   decoration: BoxDecoration(
///     color: Colors.white,
///     boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
///   ),
///   iconTheme: IconThemeData(color: Colors.grey),
///   hoverDecoration: BoxDecoration(color: Colors.grey.shade50),
///   hoverIconTheme: IconThemeData(color: Colors.black),
/// )
/// ```
///
/// Using predefined styles:
///
/// ```
/// // Light theme
/// final light = FlowControlsButtonStyle.light();
///
/// // Dark theme
/// final dark = FlowControlsButtonStyle.dark();
///
/// // From Material 3 color scheme
/// final m3 = FlowControlsButtonStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// );
/// ```
///
/// ## State Resolution
///
/// Button appearance changes based on state:
/// - Normal: Uses [decoration] and [iconTheme]
/// - Hovered: Uses [hoverDecoration] and [hoverIconTheme] (falls back to base)
/// - Selected: Uses [selectedDecoration] and [selectedIconTheme] (falls back to base)
/// - Disabled: Uses [disabledDecoration] and [disabledIconTheme] (falls back to base)
///
/// See also:
///
///  * [FlowControlsStyle], for container styling around buttons
///  * [IconThemeData], for icon styling options
///  * [BoxDecoration], for decoration options
@immutable
class FlowControlsButtonStyle extends ThemeExtension<FlowControlsButtonStyle>
    with Diagnosticable {
  /// Decoration for a button in its normal state.
  ///
  /// Required and serves as the fallback for all states.
  final Decoration decoration;

  /// Decoration for a button when hovered.
  ///
  /// If null, uses [decoration] during hover.
  final Decoration? hoverDecoration;

  /// Decoration for a button when selected.
  ///
  /// If null, uses [hoverDecoration] or [decoration] when selected.
  final Decoration? selectedDecoration;

  /// Decoration for a button when disabled.
  ///
  /// If null, uses [decoration] when disabled.
  final Decoration? disabledDecoration;

  /// Icon theme for the normal state.
  ///
  /// Required and serves as the fallback for all icon states.
  final IconThemeData iconTheme;

  /// Icon theme for the hovered state.
  ///
  /// If null, uses [iconTheme] during hover.
  final IconThemeData? hoverIconTheme;

  /// Icon theme for the selected state.
  ///
  /// If null, uses [iconTheme] when selected.
  final IconThemeData? selectedIconTheme;

  /// Icon theme for the disabled state.
  ///
  /// If null, uses [iconTheme] when disabled.
  final IconThemeData? disabledIconTheme;

  /// Creates a flow controls button style.
  ///
  /// Both [decoration] and [iconTheme] are required as they provide the base styling.
  /// State-specific properties are optional and fall back to base styles.
  const FlowControlsButtonStyle({
    required this.decoration,
    required this.iconTheme,
    this.hoverDecoration,
    this.selectedDecoration,
    this.disabledDecoration,
    this.hoverIconTheme,
    this.selectedIconTheme,
    this.disabledIconTheme,
  });

  /// Creates a button style from simple color values.
  ///
  /// This is a convenience factory for common use cases where you want
  /// to specify colors for different states.
  ///
  /// Example:
  /// ```
  /// FlowControlsButtonStyle.colored(
  ///   buttonColor: Colors.white,
  ///   hoverColor: Colors.grey.shade50,
  ///   selectedColor: Colors.blue.shade50,
  ///   iconColor: Colors.grey.shade700,
  ///   hoverIconColor: Colors.black,
  ///   shadows: [BoxShadow(color: Colors.black12, blurRadius: 10)],
  /// )
  /// ```
  factory FlowControlsButtonStyle.colored({
    Color? buttonColor,
    Color? hoverColor,
    Color? selectedColor,
    Color? disabledColor,
    Color? iconColor,
    Color? hoverIconColor,
    Color? selectedIconColor,
    Color? disabledIconColor,
    List<BoxShadow>? shadows,
    Border? border,
  }) {
    assert(
      buttonColor != null || shadows != null || border != null,
      'At least one of buttonColor, shadows, or border must be provided',
    );

    BoxDecoration createDecoration(Color? color) {
      return BoxDecoration(
        color: color,
        boxShadow: shadows,
        border: border,
      );
    }

    return FlowControlsButtonStyle(
      decoration: createDecoration(buttonColor),
      hoverDecoration: hoverColor != null ? createDecoration(hoverColor) : null,
      selectedDecoration:
          selectedColor != null ? createDecoration(selectedColor) : null,
      disabledDecoration:
          disabledColor != null ? createDecoration(disabledColor) : null,
      iconTheme: IconThemeData(color: iconColor),
      hoverIconTheme:
          hoverIconColor != null ? IconThemeData(color: hoverIconColor) : null,
      selectedIconTheme: selectedIconColor != null
          ? IconThemeData(color: selectedIconColor)
          : null,
      disabledIconTheme: disabledIconColor != null
          ? IconThemeData(color: disabledIconColor)
          : null,
    );
  }

  /// Creates a light theme button style.
  ///
  /// React Flow: `#fefefe` button, `#f4f4f4` hover/selected,
  /// `#1a192b` icons (`#ababab` disabled), `#eee` bottom border,
  /// shadow `0 0 2px 1px rgba(0,0,0,0.08)`.
  factory FlowControlsButtonStyle.light() {
    return FlowControlsButtonStyle.colored(
      buttonColor: const Color(0xFFFEFEFE),
      hoverColor: const Color(0xFFF4F4F4),
      selectedColor: const Color(0xFFF4F4F4),
      disabledColor: const Color(0xFFF4F4F4),
      iconColor: const Color(0xFF1A192B),
      hoverIconColor: const Color(0xFF1A192B),
      selectedIconColor: const Color(0xFF1A192B),
      disabledIconColor: const Color(0xFFABABAB),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08), // rgba(0,0,0,0.08)
          blurRadius: 2,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ],
      border: const Border(
        bottom: BorderSide(color: Color(0xFFEEEEEE)),
      ),
    );
  }

  /// Creates a dark theme button style.
  ///
  /// React Flow `.dark`: `#2b2b2b` button, `#3e3e3e` hover/selected,
  /// `#f8f8f8` icons (`#555` disabled), `#5b5b5b` bottom border,
  /// same shadow as light.
  factory FlowControlsButtonStyle.dark() {
    return FlowControlsButtonStyle.colored(
      buttonColor: const Color(0xFF2B2B2B),
      hoverColor: const Color(0xFF3E3E3E),
      selectedColor: const Color(0xFF3E3E3E),
      disabledColor: const Color(0xFF2B2B2B),
      iconColor: const Color(0xFFF8F8F8),
      hoverIconColor: const Color(0xFFFFFFFF),
      selectedIconColor: const Color(0xFFFFFFFF),
      disabledIconColor: const Color(0xFF555555),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08), // rgba(0,0,0,0.08)
          blurRadius: 2,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ],
      border: const Border(
        bottom: BorderSide(color: Color(0xFF5B5B5B)),
      ),
    );
  }

  /// Creates a button style that adapts to the system brightness.
  ///
  /// Uses [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling.
  factory FlowControlsButtonStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowControlsButtonStyle.dark()
        : FlowControlsButtonStyle.light();
  }

  /// Creates a button style from Material 3 color scheme.
  ///
  /// Uses semantic colors for consistent theming:
  /// - Normal: surfaceContainerHigh with onSurfaceVariant icon
  /// - Hover: surfaceContainerHighest with onSurface icon
  /// - Selected: primaryContainer with onPrimaryContainer icon
  /// - Disabled: surfaceContainerLow with faded onSurfaceVariant icon
  factory FlowControlsButtonStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowControlsButtonStyle.colored(
      buttonColor: colorScheme.surfaceContainerHigh,
      hoverColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primaryContainer,
      disabledColor: colorScheme.surfaceContainerLow,
      iconColor: colorScheme.onSurfaceVariant,
      hoverIconColor: colorScheme.onSurface,
      selectedIconColor: colorScheme.onPrimaryContainer,
      disabledIconColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.39),
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Creates a button style from a seed color using Material 3 guidelines.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the button styling.
  factory FlowControlsButtonStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowControlsButtonStyle.fromColorScheme(colorScheme);
  }

  /// Creates a button style from a Flutter [ThemeData].
  factory FlowControlsButtonStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowControlsButtonStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowControlsButtonStyle.dark()
        : FlowControlsButtonStyle.light();
  }

  /// Resolves the appropriate decoration based on button state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledDecoration]
  /// 2. Selected - returns [selectedDecoration]
  /// 3. Hovered - returns [hoverDecoration]
  /// 4. Normal - returns [decoration]
  ///
  /// Falls back to [decoration] if state-specific decoration is not defined.
  Decoration resolveDecoration(Set<FlowControlState> states) {
    if (states.contains(FlowControlState.disabled)) {
      return disabledDecoration ?? decoration;
    }
    if (states.contains(FlowControlState.selected)) {
      return selectedDecoration ?? hoverDecoration ?? decoration;
    }
    if (states.contains(FlowControlState.hovered)) {
      return hoverDecoration ?? decoration;
    }
    return decoration;
  }

  /// Resolves the appropriate icon theme based on button state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledIconTheme]
  /// 2. Selected - returns [selectedIconTheme]
  /// 3. Hovered - returns [hoverIconTheme]
  /// 4. Normal - returns [iconTheme]
  ///
  /// Falls back to [iconTheme] if state-specific theme is not defined.
  IconThemeData resolveIconTheme(Set<FlowControlState> states) {
    if (states.contains(FlowControlState.disabled)) {
      return disabledIconTheme ?? iconTheme;
    }
    if (states.contains(FlowControlState.selected)) {
      return selectedIconTheme ?? iconTheme;
    }
    if (states.contains(FlowControlState.hovered)) {
      return hoverIconTheme ?? iconTheme;
    }
    return iconTheme;
  }

  /// Merges this style with another, preferring the other's values.
  ///
  /// Non-null values from [other] override values from this style.
  ///
  /// Example:
  /// ```
  /// final base = FlowControlsButtonStyle.light();
  /// final custom = FlowControlsButtonStyle.colored(
  ///   buttonColor: Colors.purple.shade50,
  ///   iconColor: Colors.purple,
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: custom's colors with base's state decorations
  /// ```
  FlowControlsButtonStyle merge(FlowControlsButtonStyle? other) {
    if (other == null) return this;
    return FlowControlsButtonStyle(
      decoration: other.decoration,
      hoverDecoration: other.hoverDecoration ?? hoverDecoration,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
      iconTheme: other.iconTheme,
      hoverIconTheme: other.hoverIconTheme ?? hoverIconTheme,
      selectedIconTheme: other.selectedIconTheme ?? selectedIconTheme,
      disabledIconTheme: other.disabledIconTheme ?? disabledIconTheme,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  @override
  FlowControlsButtonStyle copyWith({
    Decoration? decoration,
    Decoration? hoverDecoration,
    Decoration? selectedDecoration,
    Decoration? disabledDecoration,
    IconThemeData? iconTheme,
    IconThemeData? hoverIconTheme,
    IconThemeData? selectedIconTheme,
    IconThemeData? disabledIconTheme,
  }) {
    return FlowControlsButtonStyle(
      decoration: decoration ?? this.decoration,
      hoverDecoration: hoverDecoration ?? this.hoverDecoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
      iconTheme: iconTheme ?? this.iconTheme,
      hoverIconTheme: hoverIconTheme ?? this.hoverIconTheme,
      selectedIconTheme: selectedIconTheme ?? this.selectedIconTheme,
      disabledIconTheme: disabledIconTheme ?? this.disabledIconTheme,
    );
  }

  /// Linearly interpolates between this style and another.
  ///
  /// Used by Flutter's animation system for smooth theme transitions.
  /// The parameter [t] is the interpolation factor, from 0.0 to 1.0.
  @override
  FlowControlsButtonStyle lerp(
    covariant ThemeExtension<FlowControlsButtonStyle>? other,
    double t,
  ) {
    if (other is! FlowControlsButtonStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowControlsButtonStyle(
      decoration:
          Decoration.lerp(decoration, other.decoration, t) ?? decoration,
      hoverDecoration:
          Decoration.lerp(hoverDecoration, other.hoverDecoration, t),
      selectedDecoration:
          Decoration.lerp(selectedDecoration, other.selectedDecoration, t),
      disabledDecoration:
          Decoration.lerp(disabledDecoration, other.disabledDecoration, t),
      iconTheme: IconThemeData.lerp(iconTheme, other.iconTheme, t),
      hoverIconTheme:
          IconThemeData.lerp(hoverIconTheme, other.hoverIconTheme, t),
      selectedIconTheme:
          IconThemeData.lerp(selectedIconTheme, other.selectedIconTheme, t),
      disabledIconTheme:
          IconThemeData.lerp(disabledIconTheme, other.disabledIconTheme, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowControlsButtonStyle &&
        other.decoration == decoration &&
        other.hoverDecoration == hoverDecoration &&
        other.selectedDecoration == selectedDecoration &&
        other.disabledDecoration == disabledDecoration &&
        other.iconTheme == iconTheme &&
        other.hoverIconTheme == hoverIconTheme &&
        other.selectedIconTheme == selectedIconTheme &&
        other.disabledIconTheme == disabledIconTheme;
  }

  @override
  int get hashCode => Object.hash(
        decoration,
        hoverDecoration,
        selectedDecoration,
        disabledDecoration,
        iconTheme,
        hoverIconTheme,
        selectedIconTheme,
        disabledIconTheme,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<Decoration?>(
      'hoverDecoration',
      hoverDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'disabledDecoration',
      disabledDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<IconThemeData>('iconTheme', iconTheme));
    properties.add(DiagnosticsProperty<IconThemeData?>(
      'hoverIconTheme',
      hoverIconTheme,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<IconThemeData?>(
      'selectedIconTheme',
      selectedIconTheme,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<IconThemeData?>(
      'disabledIconTheme',
      disabledIconTheme,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowControlsButtonStyle('
        'decoration: $decoration, '
        'iconTheme: $iconTheme'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowControlsButtonStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowControlsButtonStyle;
/// ```
extension FlowControlsButtonStyleExtension on ThemeData {
  /// Returns the [FlowControlsButtonStyle] from theme extensions.
  ///
  /// Falls back to [FlowControlsButtonStyle.light] if not registered.
  FlowControlsButtonStyle get flowControlsButtonStyle =>
      extension<FlowControlsButtonStyle>() ?? FlowControlsButtonStyle.light();
}
