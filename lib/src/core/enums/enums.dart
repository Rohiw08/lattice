enum DragMode {
  none,
  canvas,
  node,
  edge,
  selection,
  connection,
}

/// Lattice `panOnDrag` mouse button indices.
///
/// Lattice: `0` left, `1` middle, `2` right. Use with [ViewportOptions.panOnDrag].
abstract final class PanMouseButton {
  static const int left = 0;
  static const int middle = 1;
  static const int right = 2;
}

enum HandlePosition {
  top,
  right,
  bottom,
  left,
}

enum HandleType {
  both,
  source,
  target,
}

enum EdgePathType {
  bezier,
  step,
  straight,
  smoothStep,

  /// Midpoint-control cubic (Lattice `simplebezier`).
  simpleBezier,
}

/// Lattice node `extent` values we support on [FlowNode].
///
/// `null` on the node means unbounded (Lattice default — child may leave parent).
/// [parent] clamps the child inside its parent’s bounds.
enum FlowNodeExtent {
  parent,
}

// never change this enum
enum BackgroundVariant {
  dots,
  grid,
  cross,
  none,
}

/// Lattice [`PanelPosition`](panel position presets).
///
/// Used by [FlowPanel] (and optionally MiniMap / Controls) to pin UI above the
/// viewport without transforming with pan/zoom.
enum PanelPosition {
  /// Lattice `top-left`
  topLeft,

  /// Lattice `top-center`
  topCenter,

  /// Lattice `top-right`
  topRight,

  /// Lattice `bottom-left`
  bottomLeft,

  /// Lattice `bottom-center`
  bottomCenter,

  /// Lattice `bottom-right`
  bottomRight,

  /// Lattice `center-left`
  centerLeft,

  /// Lattice `center-right`
  centerRight;

  /// Lattice string form (`top-left`, …).
  String get kebabName => switch (this) {
        PanelPosition.topLeft => 'top-left',
        PanelPosition.topCenter => 'top-center',
        PanelPosition.topRight => 'top-right',
        PanelPosition.bottomLeft => 'bottom-left',
        PanelPosition.bottomCenter => 'bottom-center',
        PanelPosition.bottomRight => 'bottom-right',
        PanelPosition.centerLeft => 'center-left',
        PanelPosition.centerRight => 'center-right',
      };

  /// Parse Lattice / kebab-case names (`top-left`, `topLeft`).
  static PanelPosition? tryParse(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', '-');
    return switch (normalized) {
      'top-left' || 'topleft' => PanelPosition.topLeft,
      'top-center' || 'topcenter' => PanelPosition.topCenter,
      'top-right' || 'topright' => PanelPosition.topRight,
      'bottom-left' || 'bottomleft' => PanelPosition.bottomLeft,
      'bottom-center' || 'bottomcenter' => PanelPosition.bottomCenter,
      'bottom-right' || 'bottomright' => PanelPosition.bottomRight,
      'center-left' || 'centerleft' => PanelPosition.centerLeft,
      'center-right' || 'centerright' => PanelPosition.centerRight,
      _ => null,
    };
  }
}

enum ControlPanelAlignment {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center
}

enum ThemeCategory {
  professional,
  creative,
  accessibility,
  technical,
  gaming,
  custom,
}

enum NodeEventType {
  click,
  doubleClick,
  dragStart,
  drag,
  dragStop,
  mouseEnter,
  mouseMove,
  mouseLeave,
  contextMenu,
  delete,
  change,
}

enum ConnectionLineType {
  bezier,
  straight,
  step,
  smoothStep,
  simpleBezier,
}

enum FitViewInterpolation {
  smooth,
  linear,
}

enum PanOnScrollMode {
  free,
  vertical,
  horizontal,
}

enum SelectionMode {
  partial,
  full,
}

/// How the canvas manages z-order automatically (Lattice `zIndexMode`).
///
/// - [auto] (default): selection elevation ([NodeOptions.elevateNodesOnSelected])
///   plus the subflow rule (children render strictly above their parent).
/// - [basic]: selection elevation only; no automatic child-above-parent
///   bumping on add/update — you own subflow z-order.
/// - [manual]: no automatic z management at all; [FlowNode.zIndex] rules.
enum ZIndexMode {
  auto,
  basic,
  manual,
}

enum ConnectionMode {
  strict,
  loose,
}

enum KeyboardAction {
  selectAll,
  deselectAll,
  deleteSelection,
  moveUp,
  moveDown,
  moveLeft,
  moveRight,
  zoomIn,
  zoomOut,
  resetZoom,
  duplicateSelection,
  undo,
  redo,
}

enum DefaultNodeType {
  defaultNode,
  inputNode,
  outputNode,
}

enum ConnectionValidity {
  valid,
  invalid,
  none,
}

enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  bottom,
  left,
  right,
}

/// When Freezed [FlowCanvasState.viewport] is updated relative to pan/zoom gestures.
///
/// - [end]: commit on interaction end (default, best performance).
/// - [live]: write Freezed state every matrix tick (escape hatch for apps that
///   read `state.viewport` every frame).
enum SyncViewportMode {
  end,
  live,
}
