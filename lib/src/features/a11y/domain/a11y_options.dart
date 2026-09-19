import 'package:flutter/foundation.dart';

/// Localizable screen-reader strings (≈ Lattice `ariaLabelConfig`).
///
/// Pass custom text (or localized strings) via [A11yOptions]:
///
/// ```dart
/// FlowCanvasOptions(
///   a11yOptions: A11yOptions(
///     labels: FlowA11yLabels(
///       nodeSelectHint: 'Entrée pour sélectionner ce nœud',
///     ),
///   ),
/// )
/// ```
@immutable
class FlowA11yLabels {
  /// Hint announced for a focusable node (selection + movement help).
  final String nodeSelectHint;

  /// Hint announced for a focusable edge.
  final String edgeSelectHint;

  /// Keyboard-move announcement. RF default shape:
  /// `Moved selected node {direction}. New position, x: {x}, y: {y}`.
  final String Function(String direction, double x, double y) nodeMoved;

  /// Deletion announcement, parameterized by removed element count.
  final String Function(int count) selectionDeleted;

  /// Controls tooltip/labels (RF `controls.*.ariaLabel` + canvas additions).
  final String controlsZoomIn;
  final String controlsZoomOut;
  final String controlsFitView;
  final String controlsLock;
  final String controlsUnlock;
  final String controlsUndo;
  final String controlsRedo;

  /// Minimap screen-reader label (RF `minimap.ariaLabel`).
  final String minimapLabel;

  /// Handle screen-reader label (RF `handle.ariaLabel`).
  final String handleLabel;

  /// Control-panel grouping label (RF `controls.ariaLabel`).
  final String controlsLabel;

  /// Interactivity toggle label (RF `controls.interactive.ariaLabel`).
  final String controlsInteractive;

  const FlowA11yLabels({
    this.nodeSelectHint =
        'Press enter or space to select. Arrow keys move selected nodes. '
        'Press delete to remove.',
    this.edgeSelectHint =
        'Press enter or space to select. Press delete to remove.',
    this.nodeMoved = _defaultNodeMoved,
    this.selectionDeleted = _defaultSelectionDeleted,
    this.controlsZoomIn = 'Zoom in',
    this.controlsZoomOut = 'Zoom out',
    this.controlsFitView = 'Fit view',
    this.controlsLock = 'Lock canvas',
    this.controlsUnlock = 'Unlock canvas',
    this.controlsUndo = 'Undo',
    this.controlsRedo = 'Redo',
    this.minimapLabel = 'Minimap',
    this.handleLabel = 'Handle',
    this.controlsLabel = 'Control Panel',
    this.controlsInteractive = 'Toggle interactivity',
  });

  static String _defaultNodeMoved(String direction, double x, double y) =>
      'Moved selection $direction. New position, '
      'x: ${x.toStringAsFixed(0)}, y: ${y.toStringAsFixed(0)}';

  static String _defaultSelectionDeleted(int count) => count == 1
      ? 'Deleted 1 selected element'
      : 'Deleted $count selected elements';
}

/// Accessibility behavior for the canvas (≈ Lattice a11y props).
///
/// - [announcements]: live-region announcements for keyboard moves and
///   deletions (default on).
/// - [autoPanOnNodeFocus]: pan the focused node into view, RF
///   `autoPanOnNodeFocus` parity (default on).
/// - [labels]: localizable strings, RF `ariaLabelConfig` parity.
@immutable
class A11yOptions with Diagnosticable {
  final bool announcements;
  final bool autoPanOnNodeFocus;
  final FlowA11yLabels labels;

  const A11yOptions({
    this.announcements = true,
    this.autoPanOnNodeFocus = true,
    this.labels = const FlowA11yLabels(),
  });

  A11yOptions copyWith({
    bool? announcements,
    bool? autoPanOnNodeFocus,
    FlowA11yLabels? labels,
  }) {
    return A11yOptions(
      announcements: announcements ?? this.announcements,
      autoPanOnNodeFocus: autoPanOnNodeFocus ?? this.autoPanOnNodeFocus,
      labels: labels ?? this.labels,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is A11yOptions &&
        other.announcements == announcements &&
        other.autoPanOnNodeFocus == autoPanOnNodeFocus &&
        other.labels == labels;
  }

  @override
  int get hashCode =>
      Object.hash(announcements, autoPanOnNodeFocus, labels);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(FlagProperty('announcements',
        value: announcements, defaultValue: true, ifFalse: 'OFF'));
    properties.add(FlagProperty('autoPanOnNodeFocus',
        value: autoPanOnNodeFocus, defaultValue: true, ifFalse: 'OFF'));
  }
}
