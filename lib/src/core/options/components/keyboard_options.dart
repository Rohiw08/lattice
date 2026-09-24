import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// Configuration options for keyboard interactions in the flow canvas.
///
/// Controls keyboard shortcuts, navigation, and accessibility features
/// similar to React Flow's keyboard handling.
///
/// ## React Flow Compatibility
///
/// React Flow provides built-in keyboard support:
/// - Tab navigation through nodes/edges
/// - Enter/Space to select
/// - Escape to clear selection
/// - Arrow keys to move selected nodes
/// - Delete/Backspace to remove selection
///
/// This implementation extends that with additional shortcuts for:
/// - Select All (Ctrl/Cmd+A)
/// - Zoom controls (Ctrl/Cmd +/- and 0)
/// - Duplicate (Ctrl/Cmd+D)
/// - Undo/Redo (Ctrl/Cmd+Z and Ctrl/Cmd+Shift+Z)
///
/// ## Usage
///
/// Keyboard shortcuts are on by default (platform-aware):
/// ```
/// FlowCanvas() // arrows, delete, select-all, undo/redo, zoom, duplicate
/// ```
///
/// Disabled keyboard:
/// ```
/// FlowCanvas(
///   keyboardOptions: KeyboardOptions.disabled(),
/// )
/// ```
///
/// Custom shortcuts (replaces the defaults entirely):
/// ```
/// FlowCanvas(
///   keyboardOptions: KeyboardOptions(
///     enabled: true,
///     arrowKeyMoveSpeed: 20.0,
///     shortcuts: {
///       SingleActivator(LogicalKeyboardKey.keyD, control: true):
///         KeyboardAction.duplicateSelection,
///     },
///   ),
/// )
/// ```
///
/// ## Accessibility
///
/// Follows React Flow's accessibility patterns:
/// - Tab navigation between focusable elements
/// - Screen reader support via ARIA labels
/// - Keyboard operability for all interactive elements
///
/// See also:
///
///  * [KeyboardAction], for available actions
///  * React Flow Accessibility: accessible canvas patterns
@immutable
class KeyboardOptions with Diagnosticable {
  /// Whether keyboard interactions are enabled.
  ///
  /// When false, all keyboard shortcuts are disabled, similar to
  /// React Flow's `disableKeyboardA11y` prop.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Speed multiplier for arrow key node movement in logical pixels.
  ///
  /// Each arrow key press moves the selected node(s) by this distance.
  /// React Flow uses a default of ~10px with Shift increasing speed.
  ///
  /// Must be positive. Typical values: 5-20.
  /// Defaults to 10.0.
  final double arrowKeyMoveSpeed;

  /// Zoom increment/decrement per zoom action (0.0-1.0).
  ///
  /// Controls how much to zoom in/out when using zoom shortcuts.
  /// A value of 0.1 means zoom by 10% per action.
  ///
  /// Must be between 0.0 and 1.0. Typical values: 0.05-0.2.
  /// Defaults to 0.1 (10% per action).
  final double zoomStep;

  /// Custom keyboard shortcuts mapping keys to actions.
  ///
  /// Defaults to the platform-aware set from [_getDefaultShortcuts] (same as
  /// [KeyboardOptions.withDefaults]). Pass an explicit map to replace the
  /// defaults entirely, or [KeyboardOptions.disabled] for no keyboard input.
  ///
  /// Example:
  /// ```
  /// shortcuts: {
  ///   SingleActivator(LogicalKeyboardKey.keyF):
  ///     KeyboardAction.duplicateSelection,
  ///   SingleActivator(LogicalKeyboardKey.keyG):
  ///     KeyboardAction.zoomIn,
  /// }
  /// ```
  final Map<ShortcutActivator, KeyboardAction> shortcuts;

  /// Keys that enable multi-select via click (React Flow `multiSelectionKeyCode`).
  ///
  /// While any of these keys is held, clicking a node/edge **adds** it to the
  /// selection (or removes it if already selected) instead of replacing.
  ///
  /// - `null` → platform default (Meta on macOS, Control elsewhere)
  /// - empty set → multi-select click disabled
  final Set<LogicalKeyboardKey>? multiSelectionKeys;

  /// Keys that enable drag-box selection (React Flow `selectionKeyCode`).
  ///
  /// While held, dragging on the pane draws a selection rectangle instead of
  /// panning. Default is Shift (React Flow default).
  ///
  /// - `null` → [defaultSelectionKeys] (Shift)
  /// - empty set → key-gated box select disabled (use [ViewportOptions.selectionOnDrag])
  final Set<LogicalKeyboardKey>? selectionKeys;

  /// Keys that turn pointer drags into viewport pans (React Flow
  /// `panActivationKeyCode`).
  ///
  /// While held, left-drag pans the viewport instead of dragging nodes,
  /// drawing marquees, or (dis)connecting — Figma-style space-pan. A plain
  /// tap still selects, and keyboard Space on a focused node still selects
  /// (only drags are rerouted).
  ///
  /// - `null` → [defaultPanActivationKeys] (Space)
  /// - empty set → space-pan disabled
  final Set<LogicalKeyboardKey>? panActivationKeys;

  /// Keys that gate mouse-wheel zoom (React Flow `zoomActivationKeyCode`).
  ///
  /// - `null` (default) → platform default (Meta on macOS, Control
  ///   elsewhere), matching React Flow: wheel zooms only while held,
  ///   otherwise the wheel falls back to [ViewportOptions.panOnScroll]
  ///   behavior or is ignored
  /// - non-empty → wheel zooms only while one of these is held
  /// - empty set → wheel zoom disabled entirely
  final Set<LogicalKeyboardKey>? zoomActivationKeys;

  /// Creates keyboard options with the specified parameters.
  ///
  /// The [enabled] flag controls whether keyboard interactions work at all.
  /// [shortcuts] defaults to the platform-aware set; pass an explicit
  /// (possibly empty) map to override it.
  const KeyboardOptions._withShortcuts({
    this.enabled = true,
    this.arrowKeyMoveSpeed = 10.0,
    this.zoomStep = 0.1,
    required this.shortcuts,
    this.multiSelectionKeys,
    this.selectionKeys,
    this.panActivationKeys,
    this.zoomActivationKeys,
  })  : assert(arrowKeyMoveSpeed > 0, 'arrowKeyMoveSpeed must be positive'),
        assert(zoomStep > 0 && zoomStep <= 1.0,
            'zoomStep must be between 0.0 and 1.0');

  /// Creates keyboard options with platform-aware default shortcuts.
  ///
  /// This is also what the default constructor does — use this factory to
  /// state the intent explicitly or to tweak speed/zoom while keeping the
  /// default bindings.
  factory KeyboardOptions({
    bool enabled = true,
    double arrowKeyMoveSpeed = 10.0,
    double zoomStep = 0.1,
    Map<ShortcutActivator, KeyboardAction>? shortcuts,
    Set<LogicalKeyboardKey>? multiSelectionKeys,
    Set<LogicalKeyboardKey>? selectionKeys,
    Set<LogicalKeyboardKey>? panActivationKeys,
    Set<LogicalKeyboardKey>? zoomActivationKeys,
  }) {
    assert(arrowKeyMoveSpeed > 0, 'arrowKeyMoveSpeed must be positive');
    assert(
        zoomStep > 0 && zoomStep <= 1.0, 'zoomStep must be between 0.0 and 1.0');
    return KeyboardOptions._withShortcuts(
      enabled: enabled,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed,
      zoomStep: zoomStep,
      shortcuts: shortcuts ?? _getDefaultShortcuts(),
      multiSelectionKeys: multiSelectionKeys,
      selectionKeys: selectionKeys,
      panActivationKeys: panActivationKeys,
      zoomActivationKeys: zoomActivationKeys,
    );
  }

  /// Platform default for [multiSelectionKeys] (React Flow: Meta on macOS, Control else).
  static Set<LogicalKeyboardKey> defaultMultiSelectionKeys() {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? {LogicalKeyboardKey.meta}
        : {LogicalKeyboardKey.control};
  }

  /// Default for [selectionKeys] (React Flow: Shift).
  static Set<LogicalKeyboardKey> defaultSelectionKeys() =>
      {LogicalKeyboardKey.shift};

  /// Default for [panActivationKeys] (React Flow: Space).
  static Set<LogicalKeyboardKey> defaultPanActivationKeys() =>
      {LogicalKeyboardKey.space};

  /// Platform default for [zoomActivationKeys] (React Flow
  /// `zoomActivationKeyCode`: Meta on macOS, Control elsewhere).
  static Set<LogicalKeyboardKey> defaultZoomActivationKeys() {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? {LogicalKeyboardKey.meta}
        : {LogicalKeyboardKey.control};
  }

  /// Resolved multi-select keys (`null` option → [defaultMultiSelectionKeys]).
  Set<LogicalKeyboardKey> get effectiveMultiSelectionKeys =>
      multiSelectionKeys ?? defaultMultiSelectionKeys();

  /// Resolved box-selection keys (`null` option → [defaultSelectionKeys]).
  Set<LogicalKeyboardKey> get effectiveSelectionKeys =>
      selectionKeys ?? defaultSelectionKeys();

  /// Whether a multi-selection modifier is currently held (React Flow `multiSelectionActive`).
  bool get isMultiSelectionActive =>
      isAnyMultiSelectionKeyPressed(effectiveMultiSelectionKeys);

  /// Whether the box-selection key is held (React Flow `selectionKeyPressed`).
  bool get isSelectionKeyActive =>
      isAnyMultiSelectionKeyPressed(effectiveSelectionKeys);

  /// Resolved pan-activation keys (`null` option → [defaultPanActivationKeys]).
  Set<LogicalKeyboardKey> get effectivePanActivationKeys =>
      panActivationKeys ?? defaultPanActivationKeys();

  /// Whether a pan-activation key is held. Read live (no rebuild needed).
  bool get isPanActivationKeyActive =>
      isAnyMultiSelectionKeyPressed(effectivePanActivationKeys);

  /// Whether pointer drags are currently rerouted to viewport pan: keyboard
  /// on and a pan-activation key held. Single check shared by gesture
  /// routing (recognizers, tap/marquee guards, viewer pan).
  bool get isPanActivationHeld =>
      enabled && isPanActivationKeyActive;

  /// Whether mouse-wheel zoom is currently allowed (React Flow
  /// `zoomActivationKeyCode`). Null option means the platform default;
  /// an empty set never allows it. Read live (no rebuild needed), like
  /// the other key checks.
  bool get isZoomActivationHeld =>
      isAnyMultiSelectionKeyPressed(effectiveZoomActivationKeys);

  /// Resolved zoom-activation keys (`null` option → platform default).
  Set<LogicalKeyboardKey> get effectiveZoomActivationKeys =>
      zoomActivationKeys ?? defaultZoomActivationKeys();

  /// Returns true if any key in [keys] is pressed on [HardwareKeyboard.instance].
  ///
  /// Synonym modifiers ([LogicalKeyboardKey.control], `.meta`, `.shift`, `.alt`)
  /// are resolved via Flutter's side-agnostic helpers — a bare
  /// `isLogicalKeyPressed(control)` is always false because only
  /// `controlLeft` / `controlRight` appear in the pressed set.
  static bool isAnyMultiSelectionKeyPressed(Set<LogicalKeyboardKey> keys) {
    if (keys.isEmpty) return false;
    final keyboard = HardwareKeyboard.instance;
    for (final key in keys) {
      if (_modifierPressed(keyboard, key)) return true;
    }
    return false;
  }

  static bool _modifierPressed(
    HardwareKeyboard keyboard,
    LogicalKeyboardKey key,
  ) {
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) {
      return keyboard.isControlPressed;
    }
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) {
      return keyboard.isMetaPressed;
    }
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      return keyboard.isShiftPressed;
    }
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) {
      return keyboard.isAltPressed;
    }
    return keyboard.isLogicalKeyPressed(key);
  }

  /// Creates keyboard options with platform-aware default shortcuts.
  ///
  /// Identical to the default constructor — use it to state the intent
  /// explicitly or to tweak speed/zoom while keeping the default bindings.
  ///
  /// Automatically uses:
  /// - Cmd key for macOS (detected via [defaultTargetPlatform])
  /// - Ctrl key for other platforms
  ///
  /// Default shortcuts include:
  /// - **Selection**: Ctrl/Cmd+A (select all), Esc (deselect)
  /// - **Deletion**: Delete, Backspace
  /// - **Navigation**: Arrow keys
  /// - **Zoom**: Ctrl/Cmd +/- (zoom in/out), Ctrl/Cmd+0 (reset)
  /// - **Duplication**: Ctrl/Cmd+D
  /// - **Undo/Redo**: Ctrl/Cmd+Z, Ctrl/Cmd+Shift+Z, Ctrl/Cmd+Y
  ///
  /// Example:
  /// ```
  /// KeyboardOptions.withDefaults(
  ///   arrowKeyMoveSpeed: 15.0,
  ///   zoomStep: 0.15,
  /// )
  /// ```
  factory KeyboardOptions.withDefaults({
    bool enabled = true,
    double arrowKeyMoveSpeed = 10.0,
    double zoomStep = 0.1,
    Set<LogicalKeyboardKey>? multiSelectionKeys,
    Set<LogicalKeyboardKey>? selectionKeys,
    Set<LogicalKeyboardKey>? panActivationKeys,
    Set<LogicalKeyboardKey>? zoomActivationKeys,
  }) {
    return KeyboardOptions(
      enabled: enabled,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed,
      zoomStep: zoomStep,
      shortcuts: _getDefaultShortcuts(),
      multiSelectionKeys: multiSelectionKeys,
      selectionKeys: selectionKeys,
      panActivationKeys: panActivationKeys,
      zoomActivationKeys: zoomActivationKeys,
    );
  }

  /// Creates keyboard options with all features disabled.
  ///
  /// Similar to React Flow's `disableKeyboardA11y={true}`.
  /// Use this for read-only diagrams or when implementing custom
  /// keyboard handling.
  ///
  /// Example:
  /// ```
  /// FlowCanvas(
  ///   keyboardOptions: KeyboardOptions.disabled(),
  /// )
  /// ```
  const KeyboardOptions.disabled()
      : enabled = false,
        arrowKeyMoveSpeed = 10.0,
        zoomStep = 0.1,
        shortcuts = const {},
        multiSelectionKeys = null,
        selectionKeys = null,
        // Empty (not null): space-pan must stay dead when keyboard is off.
        panActivationKeys = const {},
        // Null (not empty): wheel zoom is not a keyboard shortcut.
        zoomActivationKeys = null;

  /// Creates keyboard options with only basic navigation.
  ///
  /// Enables arrow keys and selection shortcuts but disables
  /// editing features (delete, duplicate, undo/redo).
  ///
  /// Useful for navigation-only or presentation modes.
  factory KeyboardOptions.navigationOnly({
    double arrowKeyMoveSpeed = 10.0,
    double zoomStep = 0.1,
    Set<LogicalKeyboardKey>? multiSelectionKeys,
    Set<LogicalKeyboardKey>? selectionKeys,
    Set<LogicalKeyboardKey>? panActivationKeys,
    Set<LogicalKeyboardKey>? zoomActivationKeys,
  }) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return KeyboardOptions(
      enabled: true,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed,
      zoomStep: zoomStep,
      multiSelectionKeys: multiSelectionKeys,
      selectionKeys: selectionKeys,
      panActivationKeys: panActivationKeys,
      zoomActivationKeys: zoomActivationKeys,
      shortcuts: {
        // Selection only
        SingleActivator(LogicalKeyboardKey.keyA, control: !isMac, meta: isMac):
            KeyboardAction.selectAll,
        const SingleActivator(LogicalKeyboardKey.escape):
            KeyboardAction.deselectAll,

        // Navigation (plain arrows; Shift variants move 5x — see
        // KeyboardController.shiftMoveBoost).
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            KeyboardAction.moveUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            KeyboardAction.moveDown,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            KeyboardAction.moveLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight):
            KeyboardAction.moveRight,
        const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
            KeyboardAction.moveUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
            KeyboardAction.moveDown,
        const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
            KeyboardAction.moveLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
            KeyboardAction.moveRight,

        // Zoom
        SingleActivator(LogicalKeyboardKey.equal, control: !isMac, meta: isMac):
            KeyboardAction.zoomIn,
        SingleActivator(LogicalKeyboardKey.minus, control: !isMac, meta: isMac):
            KeyboardAction.zoomOut,
        SingleActivator(LogicalKeyboardKey.digit0,
            control: !isMac, meta: isMac): KeyboardAction.resetZoom,
      },
    );
  }

  /// Helper method to create default, platform-aware shortcuts.
  static Map<ShortcutActivator, KeyboardAction> _getDefaultShortcuts() {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return {
      // Selection
      SingleActivator(LogicalKeyboardKey.keyA, control: !isMac, meta: isMac):
          KeyboardAction.selectAll,
      const SingleActivator(LogicalKeyboardKey.escape):
          KeyboardAction.deselectAll,

      // Deletion
      const SingleActivator(LogicalKeyboardKey.delete):
          KeyboardAction.deleteSelection,
      const SingleActivator(LogicalKeyboardKey.backspace):
          KeyboardAction.deleteSelection,

      // Navigation (plain arrows; Shift variants move 5x — see
      // KeyboardController.shiftMoveBoost).
      const SingleActivator(LogicalKeyboardKey.arrowUp): KeyboardAction.moveUp,
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          KeyboardAction.moveDown,
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          KeyboardAction.moveLeft,
      const SingleActivator(LogicalKeyboardKey.arrowRight):
          KeyboardAction.moveRight,
      const SingleActivator(LogicalKeyboardKey.arrowUp, shift: true):
          KeyboardAction.moveUp,
      const SingleActivator(LogicalKeyboardKey.arrowDown, shift: true):
          KeyboardAction.moveDown,
      const SingleActivator(LogicalKeyboardKey.arrowLeft, shift: true):
          KeyboardAction.moveLeft,
      const SingleActivator(LogicalKeyboardKey.arrowRight, shift: true):
          KeyboardAction.moveRight,

      // Zoom
      SingleActivator(LogicalKeyboardKey.equal, control: !isMac, meta: isMac):
          KeyboardAction.zoomIn,
      SingleActivator(LogicalKeyboardKey.minus, control: !isMac, meta: isMac):
          KeyboardAction.zoomOut,
      SingleActivator(LogicalKeyboardKey.digit0, control: !isMac, meta: isMac):
          KeyboardAction.resetZoom,

      // Duplication
      SingleActivator(LogicalKeyboardKey.keyD, control: !isMac, meta: isMac):
          KeyboardAction.duplicateSelection,

      // Undo/Redo
      SingleActivator(LogicalKeyboardKey.keyZ, control: !isMac, meta: isMac):
          KeyboardAction.undo,
      SingleActivator(LogicalKeyboardKey.keyZ,
          control: !isMac, meta: isMac, shift: true): KeyboardAction.redo,
      // Common alternative for redo (Ctrl/Cmd+Y)
      SingleActivator(LogicalKeyboardKey.keyY, control: !isMac, meta: isMac):
          KeyboardAction.redo,
    };
  }

  /// Returns a copy of these options with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  ///
  /// Example:
  /// ```
  /// final newOptions = options.copyWith(
  ///   arrowKeyMoveSpeed: 20.0,
  ///   enabled: false,
  /// );
  /// ```
  KeyboardOptions copyWith({
    bool? enabled,
    double? arrowKeyMoveSpeed,
    double? zoomStep,
    Map<ShortcutActivator, KeyboardAction>? shortcuts,
    Set<LogicalKeyboardKey>? multiSelectionKeys,
    bool clearMultiSelectionKeys = false,
    Set<LogicalKeyboardKey>? selectionKeys,
    bool clearSelectionKeys = false,
    Set<LogicalKeyboardKey>? panActivationKeys,
    bool clearPanActivationKeys = false,
    Set<LogicalKeyboardKey>? zoomActivationKeys,
    bool clearZoomActivationKeys = false,
  }) {
    return KeyboardOptions(
      enabled: enabled ?? this.enabled,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed ?? this.arrowKeyMoveSpeed,
      zoomStep: zoomStep ?? this.zoomStep,
      shortcuts: shortcuts ?? this.shortcuts,
      multiSelectionKeys: clearMultiSelectionKeys
          ? null
          : (multiSelectionKeys ?? this.multiSelectionKeys),
      selectionKeys: clearSelectionKeys
          ? null
          : (selectionKeys ?? this.selectionKeys),
      panActivationKeys: clearPanActivationKeys
          ? null
          : (panActivationKeys ?? this.panActivationKeys),
      zoomActivationKeys: clearZoomActivationKeys
          ? null
          : (zoomActivationKeys ?? this.zoomActivationKeys),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is KeyboardOptions &&
        other.enabled == enabled &&
        other.arrowKeyMoveSpeed == arrowKeyMoveSpeed &&
        other.zoomStep == zoomStep &&
        mapEquals(other.shortcuts, shortcuts) &&
        setEquals(other.multiSelectionKeys, multiSelectionKeys) &&
        setEquals(other.selectionKeys, selectionKeys) &&
        setEquals(other.panActivationKeys, panActivationKeys) &&
        setEquals(other.zoomActivationKeys, zoomActivationKeys);
  }

  @override
  int get hashCode => Object.hash(
        enabled,
        arrowKeyMoveSpeed,
        zoomStep,
        Object.hashAllUnordered(
          shortcuts.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        multiSelectionKeys == null
            ? null
            : Object.hashAllUnordered(multiSelectionKeys!),
        selectionKeys == null
            ? null
            : Object.hashAllUnordered(selectionKeys!),
        panActivationKeys == null
            ? null
            : Object.hashAllUnordered(panActivationKeys!),
        zoomActivationKeys == null
            ? null
            : Object.hashAllUnordered(zoomActivationKeys!),
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('enabled',
        value: enabled, defaultValue: true, ifFalse: 'DISABLED'));
    properties.add(DoubleProperty('arrowKeyMoveSpeed', arrowKeyMoveSpeed,
        defaultValue: 10.0));
    properties.add(
        DoubleProperty('zoomStep', zoomStep, defaultValue: 0.1, unit: 'zoom'));
    properties.add(DiagnosticsProperty<int>('shortcuts', shortcuts.length,
        description: '${shortcuts.length} custom shortcuts'));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>(
      'multiSelectionKeys',
      effectiveMultiSelectionKeys,
    ));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>(
      'selectionKeys',
      effectiveSelectionKeys,
    ));
    properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>(
      'panActivationKeys',
      effectivePanActivationKeys,
    ));
    if (zoomActivationKeys != null) {
      properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>(
        'zoomActivationKeys',
        zoomActivationKeys!,
      ));
    } else {
      properties.add(DiagnosticsProperty<Set<LogicalKeyboardKey>>(
        'zoomActivationKeys(default)',
        effectiveZoomActivationKeys,
      ));
    }
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (!enabled) return 'KeyboardOptions(DISABLED)';
    return 'KeyboardOptions(${shortcuts.length} shortcuts, move: $arrowKeyMoveSpeed, zoom: $zoomStep)';
  }
}
