import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines the visual styling for flow canvas control widgets.
///
/// This style controls the appearance of UI controls overlaid on the flow canvas,
/// such as zoom controls, fit-to-view buttons, minimap toggles, and other
/// canvas interaction controls.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowControlsStyle.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowControlsStyle.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the style using the extension method:
///
/// ```
/// final style = Theme.of(context).flowControlsStyle;
/// ```
///
/// ## Examples
///
/// Creating a custom control style:
///
/// ```
/// FlowControlsStyle(
///   decoration: BoxDecoration(
///     color: Colors.white,
///     borderRadius: BorderRadius.circular(8),
///     border: Border.all(color: Colors.grey.shade300),
///     boxShadow: [
///       BoxShadow(
///         color: Colors.black12,
///         blurRadius: 10,
///         offset: Offset(0, 4),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// Using predefined styles:
///
/// ```
/// // Light theme
/// final light = FlowControlsStyle.light();
///
/// // Dark theme
/// final dark = FlowControlsStyle.dark();
///
/// // From Material 3 color scheme
/// final m3 = FlowControlsStyle.fromColorScheme(
///   Theme.of(context).colorScheme,
/// );
/// ```
///
/// See also:
///
///  * [FlowNodeStyle], for styling flow nodes
///  * [FlowEdgeStyle], for styling edges between nodes
///  * [BoxDecoration], for decoration options
@immutable
class FlowControlsStyle extends ThemeExtension<FlowControlsStyle>
    with Diagnosticable {
  /// The decoration applied to control containers.
  ///
  /// Typically includes background color, border, border radius, and shadows
  /// to make controls visually distinct from the canvas background.
  final Decoration decoration;

  /// Creates a flow controls style.
  ///
  /// The [decoration] defines the visual appearance of control containers.
  const FlowControlsStyle({
    required this.decoration,
  });

  /// Creates a style from simple property values.
  ///
  /// This is a convenience factory for common use cases where you want
  /// to specify basic styling properties.
  ///
  /// Example:
  /// ```
  /// FlowControlsStyle.colored(
  ///   color: Colors.white,
  ///   borderColor: Colors.grey.shade300,
  ///   borderWidth: 1.0,
  ///   borderRadius: BorderRadius.circular(8),
  ///   shadows: [
  ///     BoxShadow(
  ///       color: Colors.black12,
  ///       blurRadius: 10,
  ///       offset: Offset(0, 4),
  ///     ),
  ///   ],
  /// )
  /// ```
  factory FlowControlsStyle.colored({
    required Color color,
    Color? borderColor,
    double borderWidth = 1.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
    List<BoxShadow>? shadows,
  }) {
    return FlowControlsStyle(
      decoration: BoxDecoration(
        color: color,
        border: borderColor != null
            ? Border.all(color: borderColor, width: borderWidth)
            : null,
        borderRadius: borderRadius,
        boxShadow: shadows,
      ),
    );
  }

  /// Creates a light theme control style.
  ///
  /// Lattice: `#fefefe` background, `#eee` 1px border, no radius,
  /// shadow `0 0 2px 1px rgba(0,0,0,0.08)`.
  factory FlowControlsStyle.light() {
    return FlowControlsStyle.colored(
      color: const Color(0xFFFEFEFE),
      borderColor: const Color(0xFFEEEEEE),
      borderRadius: BorderRadius.zero,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08), // rgba(0,0,0,0.08)
          blurRadius: 2,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ],
    );
  }

  /// Creates a dark theme control style.
  ///
  /// Lattice `.dark`: `#2b2b2b` background, `#5b5b5b` 1px border,
  /// no radius, same shadow as light.
  factory FlowControlsStyle.dark() {
    return FlowControlsStyle.colored(
      color: const Color(0xFF2B2B2B),
      borderColor: const Color(0xFF5B5B5B),
      borderRadius: BorderRadius.zero,
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08), // rgba(0,0,0,0.08)
          blurRadius: 2,
          spreadRadius: 1,
          offset: Offset.zero,
        ),
      ],
    );
  }

  /// Creates a control style that adapts to the system brightness.
  ///
  /// Uses [Theme.of(context).brightness] to determine whether
  /// to use light or dark styling.
  factory FlowControlsStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowControlsStyle.dark()
        : FlowControlsStyle.light();
  }

  /// Creates a control style from a Material 3 [ColorScheme].
  ///
  /// Uses semantic colors for consistent theming:
  /// - Background: surfaceContainer
  /// - Border: outlineVariant
  factory FlowControlsStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowControlsStyle.colored(
      color: colorScheme.surfaceContainer,
      borderColor: colorScheme.outlineVariant,
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Creates a control style from a seed color using Material 3 guidelines.
  ///
  /// Generates a complete color scheme from the seed color and applies it
  /// to the control styling.
  ///
  /// Example:
  /// ```
  /// FlowControlsStyle.fromSeed(
  ///   Colors.purple,
  ///   brightness: Brightness.light,
  /// )
  /// ```
  factory FlowControlsStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowControlsStyle.fromColorScheme(colorScheme);
  }

  /// Creates a controls style from a Flutter [ThemeData].
  factory FlowControlsStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowControlsStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowControlsStyle.dark()
        : FlowControlsStyle.light();
  }

  /// Merges this style with another, preferring the other's values.
  ///
  /// Non-null values from [other] override values from this style.
  ///
  /// Example:
  /// ```
  /// final base = FlowControlsStyle.light();
  /// final custom = FlowControlsStyle.colored(
  ///   color: Colors.blue.shade50,
  ///   borderColor: Colors.blue,
  /// );
  ///
  /// final merged = base.merge(custom);
  /// // Result: custom's decoration
  /// ```
  FlowControlsStyle merge(FlowControlsStyle? other) {
    if (other == null) return this;
    return FlowControlsStyle(
      decoration: other.decoration,
    );
  }

  /// Creates a copy of this style with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  @override
  FlowControlsStyle copyWith({
    Decoration? decoration,
  }) {
    return FlowControlsStyle(
      decoration: decoration ?? this.decoration,
    );
  }

  /// Linearly interpolates between this style and another.
  ///
  /// Used by Flutter's animation system for smooth theme transitions.
  /// The parameter [t] is the interpolation factor, from 0.0 to 1.0.
  @override
  FlowControlsStyle lerp(
    covariant ThemeExtension<FlowControlsStyle>? other,
    double t,
  ) {
    if (other is! FlowControlsStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowControlsStyle(
      decoration:
          Decoration.lerp(decoration, other.decoration, t) ?? decoration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowControlsStyle && other.decoration == decoration;
  }

  @override
  int get hashCode => decoration.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>(
      'decoration',
      decoration,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowControlsStyle(decoration: $decoration)';
  }
}

/// Extension on [ThemeData] for convenient access to [FlowControlsStyle].
///
/// Usage:
/// ```
/// final style = Theme.of(context).flowControlsStyle;
/// ```
extension FlowControlsStyleExtension on ThemeData {
  /// Returns the [FlowControlsStyle] from theme extensions.
  ///
  /// Falls back to [FlowControlsStyle.light] if not registered.
  FlowControlsStyle get flowControlsStyle =>
      extension<FlowControlsStyle>() ?? FlowControlsStyle.light();
}
