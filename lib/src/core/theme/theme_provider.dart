import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/flow_theme.dart';

/// Provides a [FlowCanvasTheme] to descendant widgets.
///
/// This widget makes a [FlowCanvasTheme] available to all descendant widgets
/// through Flutter's [Theme] mechanism. Access the theme using
/// [FlowCanvasThemeProvider.of], [FlowCanvasThemeProvider.maybeOf], or
/// the convenience extension `context.flowCanvasTheme`.
///
/// {@tool snippet}
/// Basic usage with custom theme:
/// ```dart
/// FlowCanvasThemeProvider(
///   theme: FlowCanvasTheme.light(),
///   child: FlowCanvas(...),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Using predefined theme constructors:
/// ```dart
/// // Light theme
/// FlowCanvasThemeProvider.light(
///   child: FlowCanvas(...),
/// )
///
/// // Dark theme
/// FlowCanvasThemeProvider.dark(
///   child: FlowCanvas(...),
/// )
///
/// // System-adaptive theme
/// FlowCanvasThemeProvider.adaptive(
///   brightness: MediaQuery.of(context).platformBrightness,
///   child: FlowCanvas(...),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Automatic theme from Material theme:
/// ```dart
/// // Adapts to Material theme's brightness and colors
/// FlowCanvasThemeProvider.auto(
///   child: FlowCanvas(...),
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// Accessing the theme in descendant widgets:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   // Method 1: Static accessor
///   final theme = FlowCanvasThemeProvider.of(context);
///
///   // Method 2: Extension (recommended)
///   final theme = context.flowCanvasTheme;
///
///   // Method 3: Null-safe variant
///   final theme = FlowCanvasThemeProvider.maybeOf(context);
///   if (theme == null) {
///     return Text('No theme found');
///   }
///
///   return Container(
///     color: theme.background?.backgroundColor,
///     child: FlowCanvas(...),
///   );
/// }
/// ```
/// {@end-tool}
///
/// ## Theme Resolution
///
/// If [theme] is null, the provider will automatically create a theme based
/// on the current [ThemeData] brightness. This ensures descendants always
/// have access to a valid theme.
///
/// ## Theme Merging
///
/// The theme is inserted into Flutter's [ThemeData.extensions], which means:
/// - It can be accessed alongside other theme extensions
/// - It participates in inherited theme updates
/// - It works with Flutter's theme animation system
///
/// ## Performance
///
/// The theme provider is efficient and only rebuilds when the theme changes.
/// It reuses the parent [ThemeData] and only updates the extensions list.
///
/// See also:
///
///  * [FlowCanvasTheme], the theme being provided
///  * [FlowCanvasThemeContextExtension], for convenient theme access
class FlowCanvasThemeProvider extends StatelessWidget {
  /// The theme to provide to descendant widgets.
  ///
  /// If null, a default theme will be created based on the current
  /// [ThemeData] brightness (light or dark).
  final FlowCanvasTheme? theme;

  /// The widget below this widget in the tree.
  ///
  /// This widget and its descendants will have access to the theme.
  final Widget child;

  /// Creates a theme provider.
  ///
  /// If [theme] is null, a default theme based on the current [ThemeData]
  /// brightness will be used.
  ///
  /// The provided theme is always resolved (via [FlowCanvasTheme.resolve])
  /// against a fallback matching the parent theme's brightness, so
  /// descendants always receive a complete theme with all components defined.
  const FlowCanvasThemeProvider({
    super.key,
    this.theme,
    required this.child,
  });

  /// Creates a provider with a light theme.
  ///
  /// This is equivalent to:
  /// ```dart
  /// FlowCanvasThemeProvider(
  ///   theme: FlowCanvasTheme.light(),
  ///   child: child,
  /// )
  /// ```
  const FlowCanvasThemeProvider.light({
    super.key,
    required this.child,
  }) : theme = const _LightThemeMarker();

  /// Creates a provider with a dark theme.
  ///
  /// This is equivalent to:
  /// ```dart
  /// FlowCanvasThemeProvider(
  ///   theme: FlowCanvasTheme.dark(),
  ///   child: child,
  /// )
  /// ```
  const FlowCanvasThemeProvider.dark({
    super.key,
    required this.child,
  }) : theme = const _DarkThemeMarker();

  /// Creates a provider that adapts to the given [brightness].
  ///
  /// This is useful when you need to determine the theme based on brightness
  /// without access to a [BuildContext] yet.
  ///
  /// Example:
  /// ```dart
  /// FlowCanvasThemeProvider.adaptive(
  ///   brightness: MediaQuery.of(context).platformBrightness,
  ///   child: FlowCanvas(...),
  /// )
  /// ```
  FlowCanvasThemeProvider.adaptive({
    super.key,
    required Brightness brightness,
    required this.child,
  }) : theme = _AdaptiveThemeMarker(brightness);

  /// Creates a provider that automatically adapts to the Material theme.
  ///
  /// This factory creates a theme based on the current [ThemeData]:
  /// - Uses [ThemeData.brightness] to determine light or dark
  /// - If [useMaterial3] is true, generates from [ColorScheme]
  /// - Otherwise, uses predefined light/dark theme
  ///
  /// This is the recommended constructor when you want your flow canvas
  /// to match your app's Material theme.
  ///
  /// Example:
  /// ```dart
  /// FlowCanvasThemeProvider.auto(
  ///   child: FlowCanvas(...),
  /// )
  /// ```
  const FlowCanvasThemeProvider.auto({
    super.key,
    required this.child,
  }) : theme = const _AutoThemeMarker();

  @override
  Widget build(BuildContext context) {
    final parentTheme = Theme.of(context);

    // Resolve the effective theme
    FlowCanvasTheme effectiveTheme;

    if (theme is _LightThemeMarker) {
      effectiveTheme = FlowCanvasTheme.light();
    } else if (theme is _DarkThemeMarker) {
      effectiveTheme = FlowCanvasTheme.dark();
    } else if (theme is _AdaptiveThemeMarker) {
      effectiveTheme = FlowCanvasTheme.adaptive(
        (theme as _AdaptiveThemeMarker).brightness,
      );
    } else if (theme is _AutoThemeMarker) {
      effectiveTheme = _createAutoTheme(parentTheme);
    } else {
      // Prefer MaterialApp / parent [FlowCanvasTheme] (e.g. toThemeData()),
      // then merge an explicit [FlowCanvas.theme] override on top.
      final parentFlow = parentTheme.extension<FlowCanvasTheme>();
      final base = parentFlow ?? _getDefaultTheme(parentTheme);
      effectiveTheme = theme != null ? base.merge(theme) : base;
    }

    // Resolve against a fallback that matches the parent theme's brightness,
    // ensuring every component is defined for descendants.
    final fallbackTheme = (parentTheme.brightness == Brightness.dark)
        ? FlowCanvasTheme.dark()
        : FlowCanvasTheme.light();
    effectiveTheme = effectiveTheme.resolve(fallbackTheme);

    return Theme(
      data: parentTheme.copyWith(
        extensions: [
          // Preserve all other theme extensions
          ...parentTheme.extensions.values.where((e) => e is! FlowCanvasTheme),
          // Add our flow canvas theme
          effectiveTheme,
        ],
      ),
      child: child,
    );
  }

  /// Creates a theme automatically from the Material theme.
  ///
  /// This method intelligently determines the best theme based on:
  /// 1. Material 3 usage (generates from color scheme)
  /// 2. Brightness (light vs dark)
  static FlowCanvasTheme _createAutoTheme(ThemeData materialTheme) {
    // If Material 3 is being used, generate from color scheme
    if (materialTheme.useMaterial3) {
      return FlowCanvasTheme.fromColorScheme(materialTheme.colorScheme);
    }

    // Otherwise, use predefined light/dark theme
    return materialTheme.brightness == Brightness.dark
        ? FlowCanvasTheme.dark()
        : FlowCanvasTheme.light();
  }

  /// Creates a default theme based on the given Material theme.
  ///
  /// Prefers an existing [FlowCanvasTheme] extension (e.g. from
  /// [FlowCanvasTheme.toThemeData]), otherwise light/dark from brightness.
  static FlowCanvasTheme _getDefaultTheme(ThemeData materialTheme) {
    final existing = materialTheme.extension<FlowCanvasTheme>();
    if (existing != null) return existing;
    return materialTheme.brightness == Brightness.dark
        ? FlowCanvasTheme.dark()
        : FlowCanvasTheme.light();
  }

  /// Returns the [FlowCanvasTheme] from the closest [FlowCanvasThemeProvider].
  ///
  /// If no theme is found, returns a default theme based on the current
  /// [ThemeData] brightness.
  ///
  /// This method never returns null. For nullable access, use [maybeOf].
  ///
  /// Example:
  /// ```dart
  /// final theme = FlowCanvasThemeProvider.of(context);
  /// final nodeStyle = theme.node;
  /// ```
  ///
  /// Typical usage is through the extension:
  /// ```dart
  /// final theme = context.flowCanvasTheme;
  /// ```
  static FlowCanvasTheme of(BuildContext context) {
    return maybeOf(context) ?? _getDefaultTheme(Theme.of(context));
  }

  /// Returns the [FlowCanvasTheme] from the closest [FlowCanvasThemeProvider],
  /// or null if none is found.
  ///
  /// This is the null-safe variant of [of]. Use this when you need to check
  /// if a theme exists or want to provide a custom fallback.
  ///
  /// Example:
  /// ```dart
  /// final theme = FlowCanvasThemeProvider.maybeOf(context);
  /// if (theme == null) {
  ///   return Text('No theme configured');
  /// }
  /// ```
  static FlowCanvasTheme? maybeOf(BuildContext context) {
    return Theme.of(context).extension<FlowCanvasTheme>();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlowCanvasTheme>(
      'theme',
      theme,
      defaultValue: null,
    ));

    // Show theme type for convenience
    if (theme is _LightThemeMarker) {
      properties.add(MessageProperty('themeType', 'light'));
    } else if (theme is _DarkThemeMarker) {
      properties.add(MessageProperty('themeType', 'dark'));
    } else if (theme is _AdaptiveThemeMarker) {
      properties.add(MessageProperty('themeType', 'adaptive'));
    } else if (theme is _AutoThemeMarker) {
      properties.add(MessageProperty('themeType', 'auto'));
    }
  }
}

// ============================================================================
// Theme Markers for Const Constructors
// ============================================================================
// These marker classes allow const constructors while deferring theme
// creation until build time when we have access to BuildContext.

/// Marker class for light theme in const constructor.
@immutable
class _LightThemeMarker extends FlowCanvasTheme {
  const _LightThemeMarker() : super();
}

/// Marker class for dark theme in const constructor.
@immutable
class _DarkThemeMarker extends FlowCanvasTheme {
  const _DarkThemeMarker() : super();
}

/// Marker class for adaptive theme in const constructor.
@immutable
class _AdaptiveThemeMarker extends FlowCanvasTheme {
  final Brightness brightness;
  const _AdaptiveThemeMarker(this.brightness) : super();
}

/// Marker class for auto theme in const constructor.
@immutable
class _AutoThemeMarker extends FlowCanvasTheme {
  const _AutoThemeMarker() : super();
}
