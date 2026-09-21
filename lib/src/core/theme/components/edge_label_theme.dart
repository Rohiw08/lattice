import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/theme/theme_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visual styling for edge labels in a flow diagram.
///
/// This class controls the appearance of text labels that appear along edges
/// between nodes, including their typography, background decoration, and padding.
///
/// Uses a state-based theming pattern where [textStyle] and [decoration] provide
/// the base styling, with optional state-specific overrides for hover and selection.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowEdgeLabelStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowEdgeLabelStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowEdgeLabelStyle;
/// final textStyle = style.resolveTextStyle({FlowEdgeState.selected});
/// final decoration = style.resolveDecoration({FlowEdgeState.selected});
/// ```
///
/// ## Examples
///
/// Creating a custom label style:
///
/// ```
/// FlowEdgeLabelStyle(
///   textStyle: TextStyle(
///     color: Colors.black,
///     fontSize: 12,
///     fontWeight: FontWeight.w500,
///   ),
///   decoration: BoxDecoration(
///     color: Colors.white,
///     borderRadius: BorderRadius.circular(4.0),
///     border: Border.all(color: Colors.grey.shade300),
///   ),
///   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
/// )
/// ```
///
/// Using predefined styles:
///
/// ```
/// // Light theme
/// final light = FlowEdgeLabelStyle.light();
///
/// // Dark theme
/// final dark = FlowEdgeLabelStyle.dark();
///
/// // Match app theme
/// final themed = FlowEdgeLabelStyle.fromTheme(Theme.of(context));
/// ```
///
/// ## State Resolution
///
/// The label appearance changes based on edge state:
/// - Disabled: Uses [disabledTextStyle] / [disabledDecoration] (dim fallback)
/// - Selected: Uses [selectedTextStyle] and [selectedDecoration] (falls back to base)
/// - Hovered: Uses [hoveredTextStyle] and [hoveredDecoration] (falls back to base)
/// - Normal: Uses [textStyle] and [decoration]
///
/// Use [resolveTextStyle] and [resolveDecoration] to get the appropriate
/// styling for a given state set.
///
/// See also:
///
///  * [FlowEdgeStyle], which contains this label style
///  * [TextStyle], for text styling options
///  * [BoxDecoration], for background decoration options
@immutable
class FlowEdgeLabelStyle extends ThemeExtension<FlowEdgeLabelStyle>
    with Diagnosticable {
  /// The base text style applied to the label content.
  ///
  /// Controls font size, weight, color, and other typographic properties
  /// in the normal state. Serves as fallback for other states.
  final TextStyle textStyle;

  /// The text style applied when the edge is hovered.
  ///
  /// If null, uses [textStyle] as fallback.
  final TextStyle? hoveredTextStyle;

  /// The text style applied when the edge is selected.
  ///
  /// If null, uses [textStyle] as fallback.
  final TextStyle? selectedTextStyle;

  /// The text style applied when the edge is disabled.
  ///
  /// If null, uses a dimmed version of [textStyle].
  final TextStyle? disabledTextStyle;

  /// The base decoration applied around the label.
  ///
  /// Typically includes background color, border, and corner radius.
  /// Serves as the required decoration for the normal state and
  /// fallback for other states.
  final Decoration decoration;

  /// The decoration applied when the edge is hovered.
  ///
  /// If null, uses [decoration] as fallback.
  final Decoration? hoveredDecoration;

  /// The decoration applied when the edge is selected.
  ///
  /// If null, uses [decoration] as fallback.
  final Decoration? selectedDecoration;

  /// The decoration applied when the edge is disabled.
  ///
  /// If null, uses a dimmed version of [decoration] when possible.
  final Decoration? disabledDecoration;

  /// The padding inside the label container.
  ///
  /// This space is added between the text and the label's border.
  ///
  /// If null, inherits from the layer below (global theme) when merged, and
  /// falls back to 8 pixels horizontal / 4 pixels vertical when resolved.
  final EdgeInsetsGeometry? padding;

  /// Creates a new [FlowEdgeLabelStyle].
  ///
  /// [textStyle] and [decoration] are required as they provide the base styling.
  /// State-specific styles are optional and fall back to base styles when null.
  const FlowEdgeLabelStyle({
    required this.textStyle,
    required this.decoration,
    this.hoveredTextStyle,
    this.hoveredDecoration,
    this.selectedTextStyle,
    this.selectedDecoration,
    this.disabledTextStyle,
    this.disabledDecoration,
    this.padding,
  });

  /// The default label padding used when no [padding] is set in the cascade.
  static const EdgeInsetsGeometry defaultPadding =
      EdgeInsets.symmetric(horizontal: 8, vertical: 4);

  /// The resolved [padding], falling back to [defaultPadding] when unset.
  EdgeInsetsGeometry get effectivePadding => padding ?? defaultPadding;

  /// Creates a transparent label style with just text.
  ///
  /// Useful for simple labels without background decoration.
  ///
  /// Example:
  /// ```
  /// FlowEdgeLabelStyle.text(
  ///   color: Colors.black,
  ///   fontSize: 12,
  /// )
  /// ```
  factory FlowEdgeLabelStyle.text({
    Color color = Colors.black,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w500,
    Color? hoverColor,
    Color? selectedColor,
    EdgeInsetsGeometry? padding,
  }) {
    return FlowEdgeLabelStyle(
      textStyle: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
      decoration: const BoxDecoration(color: Colors.transparent),
      hoveredTextStyle: hoverColor != null
          ? TextStyle(
              color: hoverColor,
              fontSize: fontSize,
              fontWeight: fontWeight,
            )
          : null,
      selectedTextStyle: selectedColor != null
          ? TextStyle(
              color: selectedColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            )
          : null,
      padding: padding,
    );
  }

  /// Creates a minimal label style with subtle background.
  ///
  /// Uses semi-transparent backgrounds without borders.
  ///
  /// Example:
  /// ```
  /// FlowEdgeLabelStyle.minimal(
  ///   backgroundColor: Colors.white.withValues(alpha: 0.9),
  ///   textColor: Colors.black87,
  /// )
  /// ```
  factory FlowEdgeLabelStyle.minimal({
    Color backgroundColor = Colors.white,
    Color textColor = Colors.black87,
    double fontSize = 12,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4)),
    EdgeInsetsGeometry? padding,
  }) {
    return FlowEdgeLabelStyle(
      textStyle: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.88), // ~88% opacity
        borderRadius: borderRadius,
      ),
      padding: padding,
    );
  }

  /// Creates a light theme label style.
  ///
  /// Lattice: black 12px/600 text on white, `#f2f2f2` 5px-radius
  /// border; hover `#fff` border with `0 0 10px 5px rgba(0,0,0,0.08)`
  /// shadow. No selected state in Lattice — mirrors hover.
  factory FlowEdgeLabelStyle.light() {
    return FlowEdgeLabelStyle(
      textStyle: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF2F2F2)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
      ),
      hoveredTextStyle: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hoveredDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFFFFF)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // rgba(0,0,0,0.08)
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      selectedTextStyle: const TextStyle(
        color: Color(0xFF000000),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedDecoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFFFFFFF)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // rgba(0,0,0,0.08)
            blurRadius: 10,
            spreadRadius: 5,
          ),
        ],
      ),
      padding: defaultPadding,
    );
  }

  /// Creates a dark theme label style.
  ///
  /// Lattice `.dark`: `#f8f8f8` text on `#141414` with `#444`
  /// 5px-radius border. No selected state in Lattice — mirrors hover.
  factory FlowEdgeLabelStyle.dark() {
    return FlowEdgeLabelStyle(
      textStyle: const TextStyle(
        color: Color(0xFFF8F8F8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
      ),
      hoveredTextStyle: const TextStyle(
        color: Color(0xFFF8F8F8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hoveredDecoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
      ),
      selectedTextStyle: const TextStyle(
        color: Color(0xFFF8F8F8),
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedDecoration: BoxDecoration(
        color: const Color(0xFF141414),
        border: Border.all(color: const Color(0xFF444444)),
        borderRadius: const BorderRadius.all(Radius.circular(5.0)),
      ),
      padding: defaultPadding,
    );
  }

  /// Creates a label style that adapts to the system brightness.
  ///
  /// Uses [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling.
  factory FlowEdgeLabelStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowEdgeLabelStyle.dark()
        : FlowEdgeLabelStyle.light();
  }

  /// Creates a label style from a Flutter [ThemeData].
  ///
  /// This is the recommended way to match your app's theme.
  /// Uses [ColorScheme] from the theme if using Material 3,
  /// otherwise falls back to brightness-based styling.
  factory FlowEdgeLabelStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowEdgeLabelStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowEdgeLabelStyle.dark()
        : FlowEdgeLabelStyle.light();
  }

  /// Creates a label style from a Material 3 [ColorScheme].
  ///
  /// This factory adapts the text and background colors based on the
  /// Material 3 color system for consistent theming.
  ///
  /// Uses semantic colors:
  /// - Normal: surface container with onSurface text
  /// - Hover: surface container highest with outline border
  /// - Selected: primary container with primary text
  factory FlowEdgeLabelStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowEdgeLabelStyle(
      textStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      hoveredTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hoveredDecoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(color: colorScheme.outline),
      ),
      selectedTextStyle: TextStyle(
        color: colorScheme.primary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      selectedDecoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        border: Border.all(color: colorScheme.primary),
      ),
    );
  }

  /// Creates a label style from a seed color using Material 3 color generation.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the label styling.
  ///
  /// Example:
  /// ```
  /// FlowEdgeLabelStyle.fromSeed(
  ///   Colors.purple,
  ///   brightness: Brightness.light,
  /// )
  /// ```
  factory FlowEdgeLabelStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowEdgeLabelStyle.fromColorScheme(colorScheme);
  }

  /// Merges this style with [other], applying [other]'s values as overrides.
  ///
  /// Uses [TextStyle.merge] for proper text style merging.
  /// Non-null values from [other] override values from this style.
  ///
  /// Example:
  /// ```
  /// final base = FlowEdgeLabelStyle.light();
  /// final custom = FlowEdgeLabelStyle(
  ///   textStyle: TextStyle(fontSize: 14),
  ///   decoration: BoxDecoration(color: Colors.blue.shade50),
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: light theme with custom fontSize and background
  /// ```
  FlowEdgeLabelStyle merge(FlowEdgeLabelStyle? other) {
    if (other == null) return this;

    return FlowEdgeLabelStyle(
      // TextStyle.merge properly handles partial overrides
      textStyle: textStyle.merge(other.textStyle),
      decoration: other.decoration,
      hoveredTextStyle: other.hoveredTextStyle ?? hoveredTextStyle,
      hoveredDecoration: other.hoveredDecoration ?? hoveredDecoration,
      selectedTextStyle: other.selectedTextStyle ?? selectedTextStyle,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      disabledTextStyle: other.disabledTextStyle ?? disabledTextStyle,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
      padding: other.padding ?? padding,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  @override
  FlowEdgeLabelStyle copyWith({
    TextStyle? textStyle,
    Decoration? decoration,
    TextStyle? hoveredTextStyle,
    Decoration? hoveredDecoration,
    TextStyle? selectedTextStyle,
    Decoration? selectedDecoration,
    TextStyle? disabledTextStyle,
    Decoration? disabledDecoration,
    EdgeInsetsGeometry? padding,
  }) {
    return FlowEdgeLabelStyle(
      textStyle: textStyle ?? this.textStyle,
      decoration: decoration ?? this.decoration,
      hoveredTextStyle: hoveredTextStyle ?? this.hoveredTextStyle,
      hoveredDecoration: hoveredDecoration ?? this.hoveredDecoration,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      disabledTextStyle: disabledTextStyle ?? this.disabledTextStyle,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
      padding: padding ?? this.padding,
    );
  }

  /// Linearly interpolates between this label style and [other].
  ///
  /// Used by Flutter's theme animation system when transitioning between themes.
  /// The [t] parameter is the interpolation factor, from 0.0 to 1.0.
  ///
  /// At t=0.0, returns this style. At t=1.0, returns [other].
  @override
  FlowEdgeLabelStyle lerp(
    covariant ThemeExtension<FlowEdgeLabelStyle>? other,
    double t,
  ) {
    if (other is! FlowEdgeLabelStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowEdgeLabelStyle(
      textStyle: TextStyle.lerp(textStyle, other.textStyle, t) ?? textStyle,
      decoration:
          Decoration.lerp(decoration, other.decoration, t) ?? decoration,
      hoveredTextStyle:
          TextStyle.lerp(hoveredTextStyle, other.hoveredTextStyle, t),
      hoveredDecoration:
          Decoration.lerp(hoveredDecoration, other.hoveredDecoration, t),
      selectedTextStyle:
          TextStyle.lerp(selectedTextStyle, other.selectedTextStyle, t),
      selectedDecoration:
          Decoration.lerp(selectedDecoration, other.selectedDecoration, t),
      disabledTextStyle:
          TextStyle.lerp(disabledTextStyle, other.disabledTextStyle, t),
      disabledDecoration:
          Decoration.lerp(disabledDecoration, other.disabledDecoration, t),
      padding: EdgeInsetsGeometry.lerp(padding, other.padding, t) ?? padding,
    );
  }

  /// Resolves the appropriate text style based on the edge's state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledTextStyle] (or dimmed [textStyle])
  /// 2. Selected - returns [selectedTextStyle]
  /// 3. Hovered - returns [hoveredTextStyle]
  /// 4. Normal - returns [textStyle]
  ///
  /// Falls back to [textStyle] if state-specific style is not defined.
  ///
  /// Example:
  /// ```
  /// final states = {FlowEdgeState.selected};
  /// final style = labelStyle.resolveTextStyle(states);
  /// // Returns selectedTextStyle or textStyle if null
  /// ```
  TextStyle resolveTextStyle(Set<FlowEdgeState> states) {
    if (states.contains(FlowEdgeState.disabled)) {
      return disabledTextStyle ??
          textStyle.copyWith(
            color: textStyle.color != null
                ? FlowThemeDim.color(textStyle.color!)
                : null,
          );
    }
    if (states.contains(FlowEdgeState.selected)) {
      return selectedTextStyle ?? textStyle;
    }
    if (states.contains(FlowEdgeState.hovered)) {
      return hoveredTextStyle ?? textStyle;
    }
    return textStyle;
  }

  /// Resolves the appropriate decoration based on the edge's state.
  ///
  /// State priority (highest to lowest):
  /// 1. Disabled - returns [disabledDecoration] (or dimmed [decoration])
  /// 2. Selected - returns [selectedDecoration]
  /// 3. Hovered - returns [hoveredDecoration]
  /// 4. Normal - returns [decoration]
  ///
  /// Falls back to [decoration] if state-specific decoration is not defined.
  /// Always returns a non-null decoration.
  ///
  /// Example:
  /// ```
  /// final states = {FlowEdgeState.hovered};
  /// final decoration = labelStyle.resolveDecoration(states);
  /// // Returns hoveredDecoration or decoration if null
  /// ```
  Decoration resolveDecoration(Set<FlowEdgeState> states) {
    if (states.contains(FlowEdgeState.disabled)) {
      if (disabledDecoration != null) return disabledDecoration!;
      return FlowThemeDim.decoration(decoration) ?? decoration;
    }
    if (states.contains(FlowEdgeState.selected)) {
      return selectedDecoration ?? decoration;
    }
    if (states.contains(FlowEdgeState.hovered)) {
      return hoveredDecoration ?? decoration;
    }
    return decoration;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowEdgeLabelStyle &&
        other.textStyle == textStyle &&
        other.decoration == decoration &&
        other.hoveredTextStyle == hoveredTextStyle &&
        other.hoveredDecoration == hoveredDecoration &&
        other.selectedTextStyle == selectedTextStyle &&
        other.selectedDecoration == selectedDecoration &&
        other.disabledTextStyle == disabledTextStyle &&
        other.disabledDecoration == disabledDecoration &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
        textStyle,
        decoration,
        hoveredTextStyle,
        hoveredDecoration,
        selectedTextStyle,
        selectedDecoration,
        disabledTextStyle,
        disabledDecoration,
        padding,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<TextStyle>('textStyle', textStyle));
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<TextStyle?>(
      'hoveredTextStyle',
      hoveredTextStyle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'hoveredDecoration',
      hoveredDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<TextStyle?>(
      'selectedTextStyle',
      selectedTextStyle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<TextStyle?>(
      'disabledTextStyle',
      disabledTextStyle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'disabledDecoration',
      disabledDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<EdgeInsetsGeometry?>(
      'padding',
      padding,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowEdgeLabelStyle('
        'textStyle: $textStyle, '
        'decoration: $decoration, '
        'padding: $padding'
        ')';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowEdgeLabelStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowEdgeLabelStyle;
/// ```
extension FlowEdgeLabelStyleExtension on ThemeData {
  /// Returns the [FlowEdgeLabelStyle] from theme extensions.
  ///
  /// Falls back to [FlowEdgeLabelStyle.light] if not registered.
  FlowEdgeLabelStyle get flowEdgeLabelStyle =>
      extension<FlowEdgeLabelStyle>() ?? FlowEdgeLabelStyle.light();
}
