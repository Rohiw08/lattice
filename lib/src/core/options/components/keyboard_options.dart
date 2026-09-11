import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../enums/enums.dart';

/// Configuration options for keyboard interactions in the flow canvas.
///
/// Controls keyboard shortcuts, navigation, and accessibility features
/// similar to Lattice's keyboard handling.
///
/// ## Lattice Compatibility
///
/// Lattice provides built-in keyboard support [web:302]:
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
/// Default keyboard handling:
/// ```
/// FlowCanvas(
///   keyboardOptions: KeyboardOptions.withDefaults(),
/// )
/// ```
///
/// Disabled keyboard:
/// ```
/// FlowCanvas(
///   keyboardOptions: KeyboardOptions.disabled(),
/// )
/// ```
///
/// Custom shortcuts:
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
/// Follows Lattice's accessibility patterns [web:302]:
/// - Tab navigation between focusable elements
/// - Screen reader support via ARIA labels
/// - Keyboard operability for all interactive elements
///
/// See also:
///
///  * [KeyboardAction], for available actions
///  * Lattice Accessibility: accessible canvas patterns
@immutable
class KeyboardOptions with Diagnosticable {
  /// Whether keyboard interactions are enabled.
  ///
  /// When false, all keyboard shortcuts are disabled, similar to
  /// Lattice's `disableKeyboardA11y` prop.
  ///
  /// Defaults to true.
  final bool enabled;

  /// Speed multiplier for arrow key node movement in logical pixels.
  ///
  /// Each arrow key press moves the selected node(s) by this distance.
  /// Lattice uses a default of ~10px with Shift increasing speed.
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
  /// Maps [ShortcutActivator] (key combinations) to [KeyboardAction].
  /// Use [KeyboardOptions.withDefaults] to get platform-aware defaults,
  /// or provide your own custom mappings.
  ///
  /// Example:
  /// ```
  /// shortcuts: {
  ///   SingleActivator(LogicalKeyboardKey.keyF):
  ///     KeyboardAction.fitView,
  ///   SingleActivator(LogicalKeyboardKey.keyH):
  ///     KeyboardAction.centerView,
  /// }
  /// ```
  final Map<ShortcutActivator, KeyboardAction> shortcuts;

  /// Keys that enable multi-select via click (Lattice `multiSelectionKeyCode`).
  ///
  /// While any of these keys is held, clicking a node/edge **adds** it to the
  /// selection (or removes it if already selected) instead of replacing.
  ///
  /// - `null` → platform default (Meta on macOS, Control elsewhere)
  /// - empty set → multi-select click disabled
  final Set<LogicalKeyboardKey>? multiSelectionKeys;

  /// Keys that enable drag-box selection (Lattice `selectionKeyCode`).
  ///
  /// While held, dragging on the pane draws a selection rectangle instead of
  /// panning. Default is Shift (Lattice default).
  ///
  /// - `null` → [defaultSelectionKeys] (Shift)
  /// - empty set → key-gated box select disabled (use [ViewportOptions.selectionOnDrag])
  final Set<LogicalKeyboardKey>? selectionKeys;

  /// Creates keyboard options with the specified parameters.
  ///
  /// The [enabled] flag controls whether keyboard interactions work at all.
  /// Use an empty [shortcuts] map to disable shortcuts while keeping
  /// basic keyboard navigation.
  const KeyboardOptions({
    this.enabled = true,
    this.arrowKeyMoveSpeed = 10.0,
    this.zoomStep = 0.1,
    this.shortcuts = const {},
    this.multiSelectionKeys,
    this.selectionKeys,
  })  : assert(arrowKeyMoveSpeed > 0, 'arrowKeyMoveSpeed must be positive'),
        assert(zoomStep > 0 && zoomStep <= 1.0,
            'zoomStep must be between 0.0 and 1.0');

  /// Platform default for [multiSelectionKeys] (Lattice: Meta on macOS, Control else).
  static Set<LogicalKeyboardKey> defaultMultiSelectionKeys() {
    return defaultTargetPlatform == TargetPlatform.macOS
        ? {LogicalKeyboardKey.meta}
        : {LogicalKeyboardKey.control};
  }

  /// Default for [selectionKeys] (Lattice: Shift).
  static Set<LogicalKeyboardKey> defaultSelectionKeys() =>
      {LogicalKeyboardKey.shift};

  /// Resolved multi-select keys (`null` option → [defaultMultiSelectionKeys]).
  Set<LogicalKeyboardKey> get effectiveMultiSelectionKeys =>
      multiSelectionKeys ?? defaultMultiSelectionKeys();

  /// Resolved box-selection keys (`null` option → [defaultSelectionKeys]).
  Set<LogicalKeyboardKey> get effectiveSelectionKeys =>
      selectionKeys ?? defaultSelectionKeys();

  /// Whether a multi-selection modifier is currently held (Lattice `multiSelectionActive`).
  bool get isMultiSelectionActive =>
      isAnyMultiSelectionKeyPressed(effectiveMultiSelectionKeys);

  /// Whether the box-selection key is held (Lattice `selectionKeyPressed`).
  bool get isSelectionKeyActive =>
      isAnyMultiSelectionKeyPressed(effectiveSelectionKeys);

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
  }) {
    return KeyboardOptions(
      enabled: enabled,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed,
      zoomStep: zoomStep,
      shortcuts: _getDefaultShortcuts(),
      multiSelectionKeys: multiSelectionKeys,
      selectionKeys: selectionKeys,
    );
  }

  /// Creates keyboard options with all features disabled.
  ///
  /// Similar to Lattice's `disableKeyboardA11y={true}`.
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
        selectionKeys = null;

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
  }) {
    final isMac = defaultTargetPlatform == TargetPlatform.macOS;

    return KeyboardOptions(
      enabled: true,
      arrowKeyMoveSpeed: arrowKeyMoveSpeed,
      zoomStep: zoomStep,
      multiSelectionKeys: multiSelectionKeys,
      selectionKeys: selectionKeys,
      shortcuts: {
        // Selection only
        SingleActivator(LogicalKeyboardKey.keyA, control: !isMac, meta: isMac):
            KeyboardAction.selectAll,
        const SingleActivator(LogicalKeyboardKey.escape):
            KeyboardAction.deselectAll,

        // Navigation
        const SingleActivator(LogicalKeyboardKey.arrowUp):
            KeyboardAction.moveUp,
        const SingleActivator(LogicalKeyboardKey.arrowDown):
            KeyboardAction.moveDown,
        const SingleActivator(LogicalKeyboardKey.arrowLeft):
            KeyboardAction.moveLeft,
        const SingleActivator(LogicalKeyboardKey.arrowRight):
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

      // Navigation
      const SingleActivator(LogicalKeyboardKey.arrowUp): KeyboardAction.moveUp,
      const SingleActivator(LogicalKeyboardKey.arrowDown):
          KeyboardAction.moveDown,
      const SingleActivator(LogicalKeyboardKey.arrowLeft):
          KeyboardAction.moveLeft,
      const SingleActivator(LogicalKeyboardKey.arrowRight):
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
        setEquals(other.selectionKeys, selectionKeys);
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
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    if (!enabled) return 'KeyboardOptions(DISABLED)';
    return 'KeyboardOptions(${shortcuts.length} shortcuts, move: $arrowKeyMoveSpeed, zoom: $zoomStep)';
  }
}
