import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Mouse cursors for canvas interactions (React Flow CSS cursor map).
///
/// Defaults match canvas `init.css` / `node-resizer.css`:
/// pane grab/grabbing, node grab/grabbing, handle crosshair, edge pointer, etc.
@immutable
class FlowCursorStyle extends ThemeExtension<FlowCursorStyle>
    with Diagnosticable {
  /// Empty pannable pane (`\.xy-flow__pane.draggable`).
  final MouseCursor pane;

  /// Pane while panning (`\.xy-flow__pane.dragging`).
  final MouseCursor paneDragging;

  /// Pane in marquee / selection mode (`\.xy-flow__pane.selection`).
  final MouseCursor paneSelection;

  /// Non-selectable, non-draggable node.
  final MouseCursor node;

  /// Selectable but not draggable node.
  final MouseCursor nodeSelectable;

  /// Draggable node at rest.
  final MouseCursor nodeDraggable;

  /// Node while dragging.
  final MouseCursor nodeDragging;

  /// Selectable edge stroke.
  final MouseCursor edge;

  /// Connectable handle (`crosshair`).
  final MouseCursor handle;

  /// Edge reconnect / updater endpoint (`move`).
  final MouseCursor edgeUpdater;

  /// Multi-node selection rect (`grab`).
  final MouseCursor selection;

  /// Enabled control / panel button.
  final MouseCursor control;

  /// Disabled control / panel button.
  final MouseCursor controlDisabled;

  /// Horizontal resize handles.
  final MouseCursor resizeHorizontal;

  /// Vertical resize handles.
  final MouseCursor resizeVertical;

  /// NW–SE diagonal resize (top-left / bottom-right).
  final MouseCursor resizeDiagonalNwse;

  /// NE–SW diagonal resize (top-right / bottom-left).
  final MouseCursor resizeDiagonalNesw;

  /// Generic move / line resize fallback.
  final MouseCursor resizeMove;

  /// Generic disabled / locked surface.
  final MouseCursor disabled;

  const FlowCursorStyle({
    this.pane = SystemMouseCursors.grab,
    this.paneDragging = SystemMouseCursors.grabbing,
    this.paneSelection = SystemMouseCursors.click,
    this.node = SystemMouseCursors.basic,
    this.nodeSelectable = SystemMouseCursors.click,
    this.nodeDraggable = SystemMouseCursors.grab,
    this.nodeDragging = SystemMouseCursors.grabbing,
    this.edge = SystemMouseCursors.click,
    this.handle = SystemMouseCursors.precise,
    this.edgeUpdater = SystemMouseCursors.move,
    this.selection = SystemMouseCursors.grab,
    this.control = SystemMouseCursors.click,
    this.controlDisabled = SystemMouseCursors.basic,
    this.resizeHorizontal = SystemMouseCursors.resizeLeftRight,
    this.resizeVertical = SystemMouseCursors.resizeUpDown,
    this.resizeDiagonalNwse = SystemMouseCursors.resizeUpLeftDownRight,
    this.resizeDiagonalNesw = SystemMouseCursors.resizeUpRightDownLeft,
    this.resizeMove = SystemMouseCursors.move,
    this.disabled = SystemMouseCursors.basic,
  });

  /// React Flow default cursors (same for light and dark).
  factory FlowCursorStyle.light() => const FlowCursorStyle();

  /// Same as [light] — system cursors are not brightness-dependent.
  factory FlowCursorStyle.dark() => const FlowCursorStyle();

  factory FlowCursorStyle.system(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? FlowCursorStyle.dark()
        : FlowCursorStyle.light();
  }

  /// Pane cursor from React Flow modes: selection → dragging → pan / basic.
  MouseCursor resolvePane({
    bool selection = false,
    bool dragging = false,
    bool panEnabled = true,
  }) {
    if (selection) return paneSelection;
    if (dragging) return paneDragging;
    if (!panEnabled) return disabled;
    return pane;
  }

  /// Node cursor: dragging → draggable → selectable → default.
  MouseCursor resolveNode({
    required bool selectable,
    required bool draggable,
    bool dragging = false,
  }) {
    if (dragging && draggable) return nodeDragging;
    if (draggable) return nodeDraggable;
    if (selectable) return nodeSelectable;
    return node;
  }

  /// Resize handle cursor for an [Alignment] corner / edge.
  MouseCursor resolveResizer(
    Alignment direction, {
    bool isDisabled = false,
  }) {
    if (isDisabled) return disabled;
    if (direction == Alignment.topLeft ||
        direction == Alignment.bottomRight) {
      return resizeDiagonalNwse;
    }
    if (direction == Alignment.topRight ||
        direction == Alignment.bottomLeft) {
      return resizeDiagonalNesw;
    }
    if (direction == Alignment.centerLeft ||
        direction == Alignment.centerRight) {
      return resizeHorizontal;
    }
    if (direction == Alignment.topCenter ||
        direction == Alignment.bottomCenter) {
      return resizeVertical;
    }
    return resizeMove;
  }

  MouseCursor resolveControl({required bool enabled}) {
    return enabled ? control : controlDisabled;
  }

  FlowCursorStyle merge(FlowCursorStyle? other) {
    if (other == null) return this;
    return FlowCursorStyle(
      pane: other.pane,
      paneDragging: other.paneDragging,
      paneSelection: other.paneSelection,
      node: other.node,
      nodeSelectable: other.nodeSelectable,
      nodeDraggable: other.nodeDraggable,
      nodeDragging: other.nodeDragging,
      edge: other.edge,
      handle: other.handle,
      edgeUpdater: other.edgeUpdater,
      selection: other.selection,
      control: other.control,
      controlDisabled: other.controlDisabled,
      resizeHorizontal: other.resizeHorizontal,
      resizeVertical: other.resizeVertical,
      resizeDiagonalNwse: other.resizeDiagonalNwse,
      resizeDiagonalNesw: other.resizeDiagonalNesw,
      resizeMove: other.resizeMove,
      disabled: other.disabled,
    );
  }

  @override
  FlowCursorStyle copyWith({
    MouseCursor? pane,
    MouseCursor? paneDragging,
    MouseCursor? paneSelection,
    MouseCursor? node,
    MouseCursor? nodeSelectable,
    MouseCursor? nodeDraggable,
    MouseCursor? nodeDragging,
    MouseCursor? edge,
    MouseCursor? handle,
    MouseCursor? edgeUpdater,
    MouseCursor? selection,
    MouseCursor? control,
    MouseCursor? controlDisabled,
    MouseCursor? resizeHorizontal,
    MouseCursor? resizeVertical,
    MouseCursor? resizeDiagonalNwse,
    MouseCursor? resizeDiagonalNesw,
    MouseCursor? resizeMove,
    MouseCursor? disabled,
  }) {
    return FlowCursorStyle(
      pane: pane ?? this.pane,
      paneDragging: paneDragging ?? this.paneDragging,
      paneSelection: paneSelection ?? this.paneSelection,
      node: node ?? this.node,
      nodeSelectable: nodeSelectable ?? this.nodeSelectable,
      nodeDraggable: nodeDraggable ?? this.nodeDraggable,
      nodeDragging: nodeDragging ?? this.nodeDragging,
      edge: edge ?? this.edge,
      handle: handle ?? this.handle,
      edgeUpdater: edgeUpdater ?? this.edgeUpdater,
      selection: selection ?? this.selection,
      control: control ?? this.control,
      controlDisabled: controlDisabled ?? this.controlDisabled,
      resizeHorizontal: resizeHorizontal ?? this.resizeHorizontal,
      resizeVertical: resizeVertical ?? this.resizeVertical,
      resizeDiagonalNwse: resizeDiagonalNwse ?? this.resizeDiagonalNwse,
      resizeDiagonalNesw: resizeDiagonalNesw ?? this.resizeDiagonalNesw,
      resizeMove: resizeMove ?? this.resizeMove,
      disabled: disabled ?? this.disabled,
    );
  }

  @override
  FlowCursorStyle lerp(
    covariant ThemeExtension<FlowCursorStyle>? other,
    double t,
  ) {
    if (other is! FlowCursorStyle) return this;
    if (identical(this, other)) return this;
    if (t < 0.5) return this;
    return other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowCursorStyle &&
        other.pane == pane &&
        other.paneDragging == paneDragging &&
        other.paneSelection == paneSelection &&
        other.node == node &&
        other.nodeSelectable == nodeSelectable &&
        other.nodeDraggable == nodeDraggable &&
        other.nodeDragging == nodeDragging &&
        other.edge == edge &&
        other.handle == handle &&
        other.edgeUpdater == edgeUpdater &&
        other.selection == selection &&
        other.control == control &&
        other.controlDisabled == controlDisabled &&
        other.resizeHorizontal == resizeHorizontal &&
        other.resizeVertical == resizeVertical &&
        other.resizeDiagonalNwse == resizeDiagonalNwse &&
        other.resizeDiagonalNesw == resizeDiagonalNesw &&
        other.resizeMove == resizeMove &&
        other.disabled == disabled;
  }

  @override
  int get hashCode => Object.hashAll([
        pane,
        paneDragging,
        paneSelection,
        node,
        nodeSelectable,
        nodeDraggable,
        nodeDragging,
        edge,
        handle,
        edgeUpdater,
        selection,
        control,
        controlDisabled,
        resizeHorizontal,
        resizeVertical,
        resizeDiagonalNwse,
        resizeDiagonalNesw,
        resizeMove,
        disabled,
      ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('pane', pane))
      ..add(DiagnosticsProperty('paneDragging', paneDragging))
      ..add(DiagnosticsProperty('paneSelection', paneSelection))
      ..add(DiagnosticsProperty('node', node))
      ..add(DiagnosticsProperty('nodeSelectable', nodeSelectable))
      ..add(DiagnosticsProperty('nodeDraggable', nodeDraggable))
      ..add(DiagnosticsProperty('nodeDragging', nodeDragging))
      ..add(DiagnosticsProperty('edge', edge))
      ..add(DiagnosticsProperty('handle', handle))
      ..add(DiagnosticsProperty('edgeUpdater', edgeUpdater))
      ..add(DiagnosticsProperty('selection', selection))
      ..add(DiagnosticsProperty('control', control))
      ..add(DiagnosticsProperty('controlDisabled', controlDisabled))
      ..add(DiagnosticsProperty('resizeHorizontal', resizeHorizontal))
      ..add(DiagnosticsProperty('resizeVertical', resizeVertical))
      ..add(DiagnosticsProperty('resizeDiagonalNwse', resizeDiagonalNwse))
      ..add(DiagnosticsProperty('resizeDiagonalNesw', resizeDiagonalNesw))
      ..add(DiagnosticsProperty('resizeMove', resizeMove))
      ..add(DiagnosticsProperty('disabled', disabled));
  }
}

extension FlowCursorStyleExtension on ThemeData {
  FlowCursorStyle get flowCursorStyle =>
      extension<FlowCursorStyle>() ?? FlowCursorStyle.light();
}
