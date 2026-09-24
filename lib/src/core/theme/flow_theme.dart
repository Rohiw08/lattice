import 'package:lattice/src/core/theme/components/controls_button_theme.dart';
import 'package:lattice/src/core/theme/components/controls_theme.dart';
import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/edge_label_theme.dart';
import 'package:lattice/src/core/theme/components/edge_marker_theme.dart';
import 'package:lattice/src/core/theme/components/edge_reconnect_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:lattice/src/core/theme/components/connection_theme.dart';
import 'package:lattice/src/core/theme/components/edge_theme.dart';
import 'package:lattice/src/core/theme/components/handle_theme.dart';
import 'package:lattice/src/core/theme/components/minimap_theme.dart';
import 'package:lattice/src/core/theme/components/node_resizer_theme.dart';
import 'package:lattice/src/core/theme/components/node_theme.dart';
import 'package:lattice/src/core/theme/components/panel_theme.dart';
import 'package:lattice/src/core/theme/components/selection_theme.dart';

/// Defines the visual theme for the entire flow canvas.
///
/// A [FlowCanvasTheme] bundles together all the individual component themes
/// (background, nodes, edges, etc.) to create a cohesive visual style for
/// the flow canvas editor.
///
/// ## Registration
///
/// Register the theme extension in your [MaterialApp]:
///
/// ```
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [FlowCanvasTheme.light()],
///   ),
///   darkTheme: ThemeData(
///     extensions: [FlowCanvasTheme.dark()],
///   ),
/// )
/// ```
///
/// ## Usage
///
/// Access the theme using the extension method:
///
/// ```
/// final theme = Theme.of(context).flowCanvasTheme;
/// ```
///
/// ## Examples
///
/// Using predefined themes:
/// ```
/// // Light theme
/// final theme = FlowCanvasTheme.light();
///
/// // Dark theme
/// final theme = FlowCanvasTheme.dark();
///
/// // System adaptive theme
/// final theme = FlowCanvasTheme.adaptive(Brightness.dark);
/// ```
///
/// Creating from Material Design color scheme:
/// ```
/// final theme = FlowCanvasTheme.fromColorScheme(
///   ColorScheme.fromSeed(seedColor: Colors.purple),
/// );
/// ```
///
/// Customizing specific components:
/// ```
/// final theme = FlowCanvasTheme.light().copyWith(
///   node: FlowNodeStyle.colored(
///     color: Colors.purple.shade50,
///     selectedBorderColor: Colors.purple,
///   ),
///   edge: FlowEdgeStyle.dark(),
/// );
/// ```
///
/// Hierarchical theme merging:
/// ```
/// final baseTheme = FlowCanvasTheme.light();
///
/// // Override only nodes, keep everything else from base
/// final customTheme = baseTheme.merge(
///   FlowCanvasTheme(
///     node: FlowNodeStyle.colored(color: Colors.purple),
///     // All other fields null - will inherit from baseTheme
///   ),
/// );
/// ```
///
/// ## Component Themes
///
/// The theme consists of these component styles:
///
///  * [background] - Canvas background pattern and colors
///  * [node] - Node container styling and states
///  * [edge] - Connection lines between nodes
///  * [handle] - Port/handle styling on nodes
///  * [selection] - Multi-select box appearance
///  * [controls] - Canvas control panel container
///  * [button] - Individual control buttons
///  * [minimap] - Overview minimap styling
///  * [connection] - Interactive connection line (during drag)
///  * [edgeLabel] - Text labels on edges
///  * [edgeMarker] - Arrow markers on edges
///
/// ## Theme Inheritance
///
/// This theme system supports hierarchical merging similar to Flutter's
/// [ThemeData]. When merging themes, null values in the child theme will
/// inherit from the parent theme:
///
/// ```
/// final parent = FlowCanvasTheme.light();
/// final child = FlowCanvasTheme(node: customNode); // Only node specified
/// final merged = parent.merge(child); // child.node overrides, rest from parent
/// ```
///
/// See also:
///
///  * [ThemeExtension], the Flutter base class this extends
///  * [ThemeData], Flutter's core theming system
@immutable
class FlowCanvasTheme extends ThemeExtension<FlowCanvasTheme>
    with DiagnosticableTreeMixin {
  /// The background pattern and color styling.
  final FlowBackgroundStyle? background;

  /// The node container styling.
  final FlowNodeStyle? node;

  /// The edge (connection line) styling.
  final FlowEdgeStyle? edge;

  /// The handle (port) styling.
  final FlowHandleStyle? handle;

  /// The selection box styling.
  final FlowSelectionStyle? selection;

  /// The controls panel container styling.
  final FlowControlsStyle? controls;

  /// The control button styling.
  final FlowControlsButtonStyle? button;

  /// The minimap overview styling.
  final FlowMinimapStyle? minimap;

  /// The interactive connection line styling (during drag).
  final FlowConnectionStyle? connection;

  /// The edge label text styling.
  final FlowEdgeLabelStyle? edgeLabel;

  /// The edge marker (arrow) styling.
  final FlowEdgeMarkerStyle? edgeMarker;

  /// Styling for node resizer handles and surrounding line.
  final FlowNodeResizerStyle? nodeResizer;

  /// Optional [FlowPanel] chrome (default unstyled, like React Flow `<Panel />`).
  final FlowPanelStyle? panel;

  /// Mouse cursors for pane, nodes, edges, handles, resizers, controls.
  final FlowCursorStyle? cursor;

  /// Edge reconnect / updater endpoint chrome (thin; no interaction states).
  final FlowEdgeReconnectStyle? edgeReconnect;

  /// Creates a flow canvas theme.
  ///
  /// All parameters are optional to support partial theme definitions
  /// that can be merged with parent themes.
  const FlowCanvasTheme({
    this.background,
    this.node,
    this.edge,
    this.handle,
    this.selection,
    this.controls,
    this.button,
    this.minimap,
    this.connection,
    this.edgeLabel,
    this.edgeMarker,
    this.nodeResizer,
    this.panel,
    this.cursor,
    this.edgeReconnect,
  });

  /// Creates a complete light theme with all components defined.
  ///
  /// This theme uses light colors suitable for bright backgrounds:
  /// - White/light gray surfaces
  /// - Dark text and borders
  /// - Blue accents for selection and interaction
  factory FlowCanvasTheme.light() {
    return FlowCanvasTheme(
      background: FlowBackgroundStyle.light(),
      node: FlowNodeStyle.light(),
      edge: FlowEdgeStyle.light(),
      handle: FlowHandleStyle.light(),
      selection: FlowSelectionStyle.light(),
      controls: FlowControlsStyle.light(),
      button: FlowControlsButtonStyle.light(),
      minimap: FlowMinimapStyle.light(),
      connection: FlowConnectionStyle.light(),
      edgeLabel: FlowEdgeLabelStyle.light(),
      edgeMarker: FlowEdgeMarkerStyle.light(),
      nodeResizer: FlowNodeResizerStyle.light(),
      panel: FlowPanelStyle.unstyled(),
      cursor: FlowCursorStyle.light(),
      edgeReconnect: FlowEdgeReconnectStyle.light(),
    );
  }

  /// Creates a complete dark theme with all components defined.
  ///
  /// This theme uses dark colors suitable for low-light environments:
  /// - Dark gray/charcoal surfaces
  /// - Light text and borders
  /// - Lighter blue accents for selection and interaction
  factory FlowCanvasTheme.dark() {
    return FlowCanvasTheme(
      background: FlowBackgroundStyle.dark(),
      node: FlowNodeStyle.dark(),
      edge: FlowEdgeStyle.dark(),
      handle: FlowHandleStyle.dark(),
      selection: FlowSelectionStyle.dark(),
      controls: FlowControlsStyle.dark(),
      button: FlowControlsButtonStyle.dark(),
      minimap: FlowMinimapStyle.dark(),
      connection: FlowConnectionStyle.dark(),
      edgeLabel: FlowEdgeLabelStyle.dark(),
      edgeMarker: FlowEdgeMarkerStyle.dark(),
      nodeResizer: FlowNodeResizerStyle.dark(),
      panel: FlowPanelStyle.unstyled(),
      cursor: FlowCursorStyle.dark(),
      edgeReconnect: FlowEdgeReconnectStyle.dark(),
    );
  }

  /// Creates a theme that adapts to the given [brightness].
  ///
  /// This is useful when you need to determine the theme based on brightness
  /// without access to a [BuildContext] (e.g., during initialization or in
  /// business logic).
  ///
  /// Use [Brightness.light] for light themes and [Brightness.dark] for dark themes.
  ///
  /// Example:
  /// ```
  /// // In a ViewModel or business logic
  /// final brightness = systemBrightness; // From platform
  /// final theme = FlowCanvasTheme.adaptive(brightness);
  /// ```
  factory FlowCanvasTheme.adaptive(Brightness brightness) {
    return brightness == Brightness.dark
        ? FlowCanvasTheme.dark()
        : FlowCanvasTheme.light();
  }

  /// Creates a theme that adapts to the system brightness from [context].
  ///
  /// This factory requires a [BuildContext] and reads the brightness from
  /// [Theme.of(context).brightness]. For context-free scenarios, use
  /// [adaptive] instead.
  ///
  /// Example:
  /// ```
  /// @override
  /// Widget build(BuildContext context) {
  ///   return MaterialApp(
  ///     theme: ThemeData(
  ///       extensions: [FlowCanvasTheme.system(context)],
  ///     ),
  ///     child: FlowCanvas(...),
  ///   );
  /// }
  /// ```
  factory FlowCanvasTheme.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return FlowCanvasTheme.adaptive(brightness);
  }

  /// Creates a theme from a Material Design [ColorScheme].
  ///
  /// All component themes will be derived from the color scheme's semantic
  /// colors (primary, secondary, surface, etc.) following Material 3 guidelines.
  ///
  /// This is the recommended way to create themes that match your app's
  /// Material Design theme.
  ///
  /// Example:
  /// ```
  /// final materialTheme = Theme.of(context);
  /// final flowTheme = FlowCanvasTheme.fromColorScheme(
  ///   materialTheme.colorScheme,
  /// );
  /// ```
  factory FlowCanvasTheme.fromColorScheme(ColorScheme colorScheme) {
    return FlowCanvasTheme(
      background: FlowBackgroundStyle.fromColorScheme(colorScheme),
      node: FlowNodeStyle.fromColorScheme(colorScheme),
      edge: FlowEdgeStyle.fromColorScheme(colorScheme),
      handle: FlowHandleStyle.fromColorScheme(colorScheme),
      selection: FlowSelectionStyle.fromColorScheme(colorScheme),
      controls: FlowControlsStyle.fromColorScheme(colorScheme),
      button: FlowControlsButtonStyle.fromColorScheme(colorScheme),
      minimap: FlowMinimapStyle.fromColorScheme(colorScheme),
      connection: FlowConnectionStyle.fromColorScheme(colorScheme),
      edgeLabel: FlowEdgeLabelStyle.fromColorScheme(colorScheme),
      edgeMarker: FlowEdgeMarkerStyle.fromColorScheme(colorScheme),
      nodeResizer: FlowNodeResizerStyle.fromColorScheme(colorScheme),
      panel: FlowPanelStyle.fromColorScheme(colorScheme),
      cursor: const FlowCursorStyle(),
      edgeReconnect: FlowEdgeReconnectStyle.fromColorScheme(colorScheme),
    );
  }

  /// Creates a theme from a seed color using Material 3 color generation.
  ///
  /// This generates a complete color scheme from a single seed color and
  /// creates all component themes from that scheme.
  ///
  /// Example:
  /// ```
  /// final purpleTheme = FlowCanvasTheme.fromSeed(
  ///   seedColor: Colors.purple,
  ///   brightness: Brightness.light,
  /// );
  /// ```
  factory FlowCanvasTheme.fromSeed({
    required Color seedColor,
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowCanvasTheme.fromColorScheme(colorScheme);
  }

  /// Wraps this theme as a [ThemeData] extension for [MaterialApp].
  ///
  /// ```dart
  /// MaterialApp(
  ///   theme: FlowCanvasTheme.light().toThemeData(),
  ///   darkTheme: FlowCanvasTheme.dark().toThemeData(),
  /// )
  /// ```
  ThemeData toThemeData({
    Brightness? brightness,
    ColorScheme? colorScheme,
    bool useMaterial3 = true,
  }) {
    // Infer brightness from this theme's background when not specified, so
    // `FlowCanvasTheme.dark().toThemeData()` yields a dark ThemeData.
    final effectiveBrightness = brightness ?? _inferBrightness();
    final scheme = colorScheme ??
        ColorScheme.fromSeed(
          seedColor: (node?.decoration is BoxDecoration
                  ? (node!.decoration as BoxDecoration).color
                  : null) ??
              (effectiveBrightness == Brightness.dark
                  ? const Color(0xFFBEBEBE)
                  : const Color(0xFF1A192B)),
          brightness: effectiveBrightness,
        );
    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: effectiveBrightness,
      colorScheme: scheme,
      extensions: <ThemeExtension<dynamic>>[resolve()],
    );
  }

  Brightness _inferBrightness() {
    final bg = background?.backgroundColor;
    if (bg != null) {
      return bg.computeLuminance() < 0.5
          ? Brightness.dark
          : Brightness.light;
    }
    return Brightness.light;
  }

  /// Light + dark [ThemeData] pair for [MaterialApp] (React Flow `colorMode: 'system'`).
  static ({ThemeData light, ThemeData dark}) materialPair() {
    return (
      light: FlowCanvasTheme.light().toThemeData(brightness: Brightness.light),
      dark: FlowCanvasTheme.dark().toThemeData(brightness: Brightness.dark),
    );
  }

  /// Merges this theme with [other], with [other] taking precedence.
  ///
  /// This implements hierarchical theme inheritance similar to Flutter's
  /// [ThemeData.copyWith]. Any non-null values in [other] will override
  /// the corresponding values in this theme. Null values in [other] will
  /// be inherited from this theme.
  ///
  /// This enables powerful theme composition:
  ///
  /// ```
  /// final baseTheme = FlowCanvasTheme.light();
  ///
  /// // Create a variant with just custom nodes
  /// final purpleNodes = FlowCanvasTheme(
  ///   node: FlowNodeStyle.colored(color: Colors.purple),
  /// );
  ///
  /// // Merge: baseTheme provides all defaults, purpleNodes overrides node only
  /// final customTheme = baseTheme.merge(purpleNodes);
  /// // Result: light theme everywhere except purple nodes
  /// ```
  FlowCanvasTheme merge(FlowCanvasTheme? other) {
    if (other == null) return this;

    return FlowCanvasTheme(
      background: other.background ?? background,
      node: other.node ?? node,
      edge: other.edge ?? edge,
      handle: other.handle ?? handle,
      selection: other.selection ?? selection,
      controls: other.controls ?? controls,
      button: other.button ?? button,
      minimap: other.minimap ?? minimap,
      connection: other.connection ?? connection,
      edgeLabel: other.edgeLabel ?? edgeLabel,
      edgeMarker: other.edgeMarker ?? edgeMarker,
      nodeResizer: other.nodeResizer ?? nodeResizer,
      panel: other.panel ?? panel,
      cursor: other.cursor ?? cursor,
      edgeReconnect: other.edgeReconnect ?? edgeReconnect,
    );
  }

  /// Returns a copy of this theme with the given fields replaced.
  ///
  /// All parameters are optional. Any parameter that is null will keep
  /// its current value from this theme.
  ///
  /// Example:
  /// ```
  /// final newTheme = oldTheme.copyWith(
  ///   node: FlowNodeStyle.colored(color: Colors.blue),
  ///   edge: FlowEdgeStyle.dark(),
  /// );
  /// ```
  @override
  FlowCanvasTheme copyWith({
    FlowBackgroundStyle? background,
    FlowNodeStyle? node,
    FlowEdgeStyle? edge,
    FlowHandleStyle? handle,
    FlowSelectionStyle? selection,
    FlowControlsStyle? controls,
    FlowControlsButtonStyle? button,
    FlowMinimapStyle? minimap,
    FlowConnectionStyle? connection,
    FlowEdgeLabelStyle? edgeLabel,
    FlowEdgeMarkerStyle? edgeMarker,
    FlowNodeResizerStyle? nodeResizer,
    FlowPanelStyle? panel,
    FlowCursorStyle? cursor,
    FlowEdgeReconnectStyle? edgeReconnect,
  }) {
    return FlowCanvasTheme(
      background: background ?? this.background,
      node: node ?? this.node,
      edge: edge ?? this.edge,
      handle: handle ?? this.handle,
      selection: selection ?? this.selection,
      controls: controls ?? this.controls,
      button: button ?? this.button,
      minimap: minimap ?? this.minimap,
      connection: connection ?? this.connection,
      edgeLabel: edgeLabel ?? this.edgeLabel,
      edgeMarker: edgeMarker ?? this.edgeMarker,
      nodeResizer: nodeResizer ?? this.nodeResizer,
      panel: panel ?? this.panel,
      cursor: cursor ?? this.cursor,
      edgeReconnect: edgeReconnect ?? this.edgeReconnect,
    );
  }

  /// Linearly interpolates between two themes.
  ///
  /// This is used by Flutter's animation system to smoothly transition
  /// between themes. At t=0.0, this theme is returned. At t=1.0, [other]
  /// is returned. Values between 0.0 and 1.0 return interpolated values.
  ///
  /// All component themes implement their own lerp methods to interpolate
  /// colors, sizes, and other animatable properties.
  @override
  FlowCanvasTheme lerp(
    covariant ThemeExtension<FlowCanvasTheme>? other,
    double t,
  ) {
    if (other is! FlowCanvasTheme) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowCanvasTheme(
      background: background?.lerp(other.background, t) ?? other.background,
      node: node?.lerp(other.node, t) ?? other.node,
      edge: edge?.lerp(other.edge, t) ?? other.edge,
      handle: handle?.lerp(other.handle, t) ?? other.handle,
      selection: selection?.lerp(other.selection, t) ?? other.selection,
      controls: controls?.lerp(other.controls, t) ?? other.controls,
      button: button?.lerp(other.button, t) ?? other.button,
      minimap: minimap?.lerp(other.minimap, t) ?? other.minimap,
      connection: connection?.lerp(other.connection, t) ?? other.connection,
      edgeLabel: edgeLabel?.lerp(other.edgeLabel, t) ?? other.edgeLabel,
      edgeMarker: edgeMarker?.lerp(other.edgeMarker, t) ?? other.edgeMarker,
      nodeResizer: nodeResizer?.lerp(other.nodeResizer, t) ?? other.nodeResizer,
      panel: panel?.lerp(other.panel, t) ?? other.panel,
      cursor: cursor?.lerp(other.cursor, t) ?? other.cursor,
      edgeReconnect:
          edgeReconnect?.lerp(other.edgeReconnect, t) ?? other.edgeReconnect,
    );
  }

  /// Resolves this theme to a complete theme with no null values.
  ///
  /// Any null component in this theme will be filled with the corresponding
  /// component from [fallback]. If [fallback] is not provided, uses
  /// [FlowCanvasTheme.light] as the default.
  ///
  /// This is useful when you have a partial theme and need to ensure all
  /// components are defined:
  ///
  /// ```
  /// final partial = FlowCanvasTheme(node: customNode);
  /// final complete = partial.resolve(); // All other components from light theme
  /// ```
  FlowCanvasTheme resolve([FlowCanvasTheme? fallback]) {
    final defaults = fallback ?? FlowCanvasTheme.light();
    return FlowCanvasTheme(
      background: background ?? defaults.background,
      node: node ?? defaults.node,
      edge: edge ?? defaults.edge,
      handle: handle ?? defaults.handle,
      selection: selection ?? defaults.selection,
      controls: controls ?? defaults.controls,
      button: button ?? defaults.button,
      minimap: minimap ?? defaults.minimap,
      connection: connection ?? defaults.connection,
      edgeLabel: edgeLabel ?? defaults.edgeLabel,
      edgeMarker: edgeMarker ?? defaults.edgeMarker,
      nodeResizer: nodeResizer ?? defaults.nodeResizer,
      panel: panel ?? defaults.panel,
      cursor: cursor ?? defaults.cursor,
      edgeReconnect: edgeReconnect ?? defaults.edgeReconnect,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowCanvasTheme &&
        other.background == background &&
        other.node == node &&
        other.edge == edge &&
        other.handle == handle &&
        other.selection == selection &&
        other.controls == controls &&
        other.button == button &&
        other.minimap == minimap &&
        other.connection == connection &&
        other.edgeLabel == edgeLabel &&
        other.edgeMarker == edgeMarker &&
        other.nodeResizer == nodeResizer &&
        other.panel == panel &&
        other.cursor == cursor &&
        other.edgeReconnect == edgeReconnect;
  }

  @override
  int get hashCode => Object.hash(
        background,
        node,
        edge,
        handle,
        selection,
        controls,
        button,
        minimap,
        connection,
        edgeLabel,
        edgeMarker,
        nodeResizer,
        panel,
        cursor,
        edgeReconnect,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlowBackgroundStyle>(
      'background',
      background,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowNodeStyle>(
      'node',
      node,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeStyle>(
      'edge',
      edge,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowHandleStyle>(
      'handle',
      handle,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowSelectionStyle>(
      'selection',
      selection,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowControlsStyle>(
      'controls',
      controls,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowControlsButtonStyle>(
      'button',
      button,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowMinimapStyle>(
      'minimap',
      minimap,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowConnectionStyle>(
      'connection',
      connection,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeLabelStyle>(
      'edgeLabel',
      edgeLabel,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeMarkerStyle>(
      'edgeMarker',
      edgeMarker,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowNodeResizerStyle>(
      'nodeResizer',
      nodeResizer,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowPanelStyle>(
      'panel',
      panel,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowCursorStyle>(
      'cursor',
      cursor,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<FlowEdgeReconnectStyle>(
      'edgeReconnect',
      edgeReconnect,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowCanvasTheme(${_describeComponents()})';
  }

  /// Generates a human-readable description of which components are defined.
  String _describeComponents() {
    final components = <String>[];
    if (background != null) components.add('background');
    if (node != null) components.add('node');
    if (edge != null) components.add('edge');
    if (handle != null) components.add('handle');
    if (selection != null) components.add('selection');
    if (controls != null) components.add('controls');
    if (button != null) components.add('button');
    if (minimap != null) components.add('minimap');
    if (connection != null) components.add('connection');
    if (edgeLabel != null) components.add('edgeLabel');
    if (edgeMarker != null) components.add('edgeMarker');
    if (nodeResizer != null) components.add('nodeResizer');
    if (panel != null) components.add('panel');
    if (cursor != null) components.add('cursor');
    if (edgeReconnect != null) components.add('edgeReconnect');

    if (components.isEmpty) {
      return 'empty';
    }

    return components.join(', ');
  }
}

/// Extension on [ThemeData] for convenient access to [FlowCanvasTheme].
///
/// Usage:
/// ```
/// final theme = Theme.of(context).flowCanvasTheme;
/// ```
extension FlowCanvasThemeExtension on ThemeData {
  /// Returns the [FlowCanvasTheme] from theme extensions.
  ///
  /// Falls back to an adaptive [FlowCanvasTheme] based on this theme's
  /// brightness if not registered.
  FlowCanvasTheme get flowCanvasTheme =>
      extension<FlowCanvasTheme>() ?? FlowCanvasTheme.adaptive(brightness);
}
