import 'package:lattice/src/features/viewport/domain/snap_grid.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/painting.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:lattice/src/core/options/components/fitview_options.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// Configuration options for viewport behavior and user interactions.
///
/// Controls panning, zooming, selection, and other viewport interactions.
/// These options closely match React Flow's interaction props.
///
/// ## React Flow Compatibility
///
/// This maps to React Flow's interaction props:
/// - Pan: `panOnDrag`, `panOnScroll`, `panOnScrollSpeed`, `panOnScrollMode`
/// - Zoom: `zoomOnScroll`, `zoomOnPinch`, `zoomOnDoubleClick`, `minZoom`, `maxZoom`
/// - Selection: `selectionOnDrag`, `selectionMode`, `elementsSelectable`
/// - Auto Pan: `autoPanOnConnect`, `autoPanOnNodeDrag`, `autoPanSpeed`
/// - Nodes: `nodesDraggable`, `nodesConnectable`, `nodesFocusable`
/// - Edges: `edgesFocusable`
/// - Other: `elevateNodesOnSelect`, `fitView`, `fitViewOptions`
///
/// ## Usage
///
/// Default interactive viewport:
/// ```
/// ViewportOptions()
/// ```
///
/// Read-only viewport (no interactions):
/// ```
/// ViewportOptions.readOnly()
/// ```
///
/// Custom configuration:
/// ```
/// ViewportOptions(
///   minZoom: 0.1,
///   maxZoom: 4.0,
///   panOnScroll: true,
///   zoomOnScroll: false,
/// )
/// ```
///
/// See also:
///
///  * [FitViewOptions], for fit view configuration
///  * [FlowViewport], for viewport state
@immutable
class ViewportOptions with Diagnosticable {
  // ==========================================================================
  // Viewport State
  // ==========================================================================

  /// The initial viewport position and zoom.
  ///
  /// If provided, sets the starting viewport state. Use `fitView` to
  /// automatically fit content instead.
  ///
  /// React Flow equivalent: `defaultViewport` prop.
  final FlowViewport? defaultViewport;

  /// Whether to fit the view to show all nodes on initial render.
  ///
  /// When true, automatically calculates viewport to fit all nodes.
  /// Use `fitViewOptions` to customize the fit behavior.
  ///
  /// React Flow equivalent: `fitView` prop.
  /// Defaults to false.
  final bool fitView;

  /// Options for how fitView should behave.
  ///
  /// Controls padding, zoom limits, and animation for fit operations.
  ///
  /// React Flow equivalent: `fitViewOptions` prop.
  final FitViewOptions fitViewOptions;

  // ==========================================================================
  // Zoom Constraints
  // ==========================================================================

  /// Minimum allowed zoom level.
  ///
  /// Users cannot zoom out beyond this level. Must be greater than 0.
  ///
  /// React Flow equivalent: `minZoom` prop.
  /// Defaults to 0.5.
  final double minZoom;

  /// Maximum allowed zoom level.
  ///
  /// Users cannot zoom in beyond this level. Must be greater than minZoom.
  ///
  /// Defaults to 2.0.
  final double maxZoom;

  // ==========================================================================
  // Pan Interactions
  // ==========================================================================

  /// Mouse buttons that pan the viewport when dragged (React Flow style).
  ///
  /// Uses React Flow button indices: `0` left, `1` middle, `2` right
  /// ([PanMouseButton]).
  ///
  /// - `{0}` — left-drag pans (default, same as React Flow `panOnDrag={true}`)
  /// - `{}` — no drag-pan (same as React Flow `panOnDrag={false}`)
  /// - `{1, 2}` — middle + right pan (Figma-style with [selectionOnDrag])
  ///
  /// Left-button pan uses [InteractiveViewer]. Middle/right use a custom
  /// pointer pan so they work alongside [selectionOnDrag].
  ///
  /// React Flow equivalent: `panOnDrag` (`boolean | number[]`).
  final Set<int> panOnDrag;

  /// Whether scrolling pans the viewport instead of zooming.
  ///
  /// When true, scrolling moves the canvas. Set `zoomOnScroll` to false
  /// to prevent scroll from zooming.
  ///
  /// React Flow equivalent: `panOnScroll` prop.
  /// Defaults to false.
  final bool panOnScroll;

  /// Speed multiplier for pan-on-scroll.
  ///
  /// Higher values pan faster. Only applies when `panOnScroll` is true.
  /// React Flow default: 0.5
  ///
  /// React Flow equivalent: `panOnScrollSpeed` prop.
  /// Defaults to 0.5.
  final double panOnScrollSpeed;

  /// Direction constraint for pan-on-scroll.
  ///
  /// Controls which directions are allowed when panning via scroll.
  /// - `free`: Pan in any direction
  /// - `horizontal`: Only pan left/right
  /// - `vertical`: Only pan up/down
  ///
  /// Defaults to `free`.
  final PanOnScrollMode panOnScrollMode;

  // ==========================================================================
  // Zoom Interactions
  // ==========================================================================

  /// Whether scrolling zooms the viewport.
  ///
  /// When true, scrolling zooms in/out. Disable this if using `panOnScroll`.
  ///
  /// React Flow equivalent: `zoomOnScroll` prop.
  /// Defaults to true.
  final bool zoomOnScroll;

  /// Whether pinch gestures zoom on touch screens.
  ///
  /// When true, two-finger pinch gestures control zoom on mobile/tablet.
  ///
  /// React Flow equivalent: `zoomOnPinch` prop.
  /// Defaults to true.
  final bool zoomOnPinch;

  /// Whether double-clicking zooms the viewport.
  ///
  /// When true, double-clicking zooms in at the click position.
  ///
  /// React Flow equivalent: `zoomOnDoubleClick` prop.
  /// Defaults to true.
  final bool zoomOnDoubleClick;

  // ==========================================================================
  // Selection Interactions
  // ==========================================================================

  /// Whether dragging creates a selection box without modifier keys.
  ///
  /// When true, click-and-drag creates a selection box immediately.
  /// When false, requires a modifier key (typically Shift) to select.
  ///
  /// React Flow equivalent: `selectionOnDrag` prop.
  /// Defaults to false.
  final bool selectionOnDrag;

  /// How nodes are selected within the selection box.
  ///
  /// - `full`: Node must be fully inside the box
  /// - `partial`: Node partially inside is selected
  ///
  /// React Flow equivalent: `selectionMode` prop.
  /// Defaults to `full` (React Flow default).
  final SelectionMode selectionMode;

  // ==========================================================================
  // Auto-Pan
  // ==========================================================================

  /// Whether viewport auto-pans during connection creation.
  ///
  /// When true, viewport automatically pans when dragging a connection
  /// near the edge of the canvas.
  ///
  /// React Flow equivalent: `autoPanOnConnect` prop.
  /// Defaults to true.
  final bool autoPanOnConnect;

  /// Whether viewport auto-pans while dragging nodes.
  ///
  /// When true, viewport automatically pans when dragging nodes
  /// near the edge of the canvas.
  ///
  /// React Flow equivalent: `autoPanOnNodeDrag` prop.
  /// Defaults to true.
  final bool autoPanOnNodeDrag;

  /// Whether viewport auto-pans during box/marquee selection.
  ///
  /// When true, dragging a selection marquee past the viewport edge pans
  /// the canvas and extends the selection into the revealed area.
  ///
  /// React Flow equivalent: `autoPanOnSelection` prop.
  /// Defaults to true.
  final bool autoPanOnSelection;

  /// Speed of auto-panning in pixels per frame.
  ///
  /// Higher values pan faster during auto-pan operations.
  /// React Flow default: 15
  ///
  /// React Flow equivalent: `autoPanSpeed` prop.
  /// Defaults to 15.0.
  final double autoPanSpeed;

  /// Margin from the edge of the viewport where auto-panning starts.
  ///
  /// When the mouse cursor is within this margin, the viewport will auto-pan.
  ///
  /// Defaults to 50.0.
  final double autoPanMargin;

  // ==========================================================================
  // Advanced Options
  // ==========================================================================

  /// Whether to snap node positions to a grid.
  ///
  /// When true, node positions snap to grid points defined by `snapGrid`.
  final bool snapToGrid;

  /// Grid configuration for snapping.
  ///
  /// Defines the grid spacing when `snapToGrid` is enabled.
  final SnapGrid snapGrid;

  /// Performance optimization: only render visible elements.
  ///
  /// When true, node widgets outside the viewport (plus a
  /// [renderCullingPadding] + [nodeMountExtraPadding] margin) are not mounted,
  /// so the first frame and every rebuild touch only the on-screen band
  /// instead of the whole graph. Keyboard traversal, screen-reader access, and
  /// focus-into-view for off-screen nodes are preserved by an always-mounted
  /// lightweight proxy layer, so culling never costs accessibility. Edges are
  /// painted (not one widget each) and are unaffected.
  ///
  /// Defaults to true.
  final bool onlyRenderVisibleElements;

  /// Extra flow-space margin around the visible rect when [onlyRenderVisibleElements]
  /// is true (reduces pop-in at pane edges).
  final double renderCullingPadding;

  /// Additional padding (**nodes layer only**) added on top of [renderCullingPadding].
  ///
  /// Keeps widgets mounted slightly beyond the edge-cull rect so partially visible
  /// nodes remain draggable and gestures do not fall through after pan/zoom.
  final double nodeMountExtraPadding;

  /// When Freezed graph state receives viewport updates during pan/zoom.
  ///
  /// Defaults to [SyncViewportMode.end] (matrix-first camera). Use
  /// [SyncViewportMode.live] only if your app must read committed
  /// `state.viewport` every frame.
  final SyncViewportMode syncViewportToState;

  /// When zoom is below this value, node handles are hidden (simple LOD).
  ///
  /// `null` disables LOD. Typical value: `0.4`.
  final double? lodHideHandlesBelowZoom;

  /// When zoom is below this value, nodes render as painted thumbnails
  /// instead of full widgets (strong LOD for very large graphs).
  ///
  /// `null` (default) disables thumbnail mode. Typical value: `0.35`.
  /// Below the threshold the canvas is view-only for nodes: drag, resize,
  /// handles, and node focus are unavailable until zooming back in (tap
  /// empty canvas still deselects). Edges, background, and controls are
  /// unaffected.
  final double? lodThumbnailBelowZoom;

  /// Extent to which the viewport can be moved.
  ///
  /// Constrains how far users can pan the canvas.
  /// Unbounded by default.
  final CoordinateExtent translateExtent;

  /// Extent to which nodes can be moved.
  ///
  /// Constrains where nodes can be dragged.
  /// Unbounded by default.
  final CoordinateExtent nodeExtent;

  /// Minimum size allowed for nodes when resizing.
  final Size? minNodeSize;

  /// Maximum size allowed for nodes when resizing.
  final Size? maxNodeSize;

  /// Whether to prevent native browser scrolling.
  ///
  /// When true, prevents page scroll when interacting with the canvas.
  /// Recommended for full-page canvas applications.
  ///
  /// Defaults to true.
  final bool preventScrolling;

  /// Creates viewport options with the specified parameters.
  ///
  /// All parameters have sensible defaults matching React Flow's behavior.
  const ViewportOptions({
    this.defaultViewport,
    this.fitView = false,
    this.fitViewOptions = const FitViewOptions(),
    this.minZoom = 0.5,
    this.maxZoom = 2.0,
    this.panOnDrag = const {PanMouseButton.left},
    this.panOnScroll = false,
    this.panOnScrollSpeed = 0.5,
    this.panOnScrollMode = PanOnScrollMode.free,
    this.zoomOnScroll = true,
    this.zoomOnPinch = true,
    this.zoomOnDoubleClick = true,
    this.selectionOnDrag = false,
    this.selectionMode = SelectionMode.full,
    this.autoPanOnConnect = true,
    this.autoPanOnNodeDrag = true,
    this.autoPanOnSelection = true,
    this.autoPanSpeed = 15.0,
    this.autoPanMargin = 50.0,
    this.snapToGrid = false,
    this.snapGrid = const SnapGrid(),
    this.onlyRenderVisibleElements = true,
    this.renderCullingPadding = 200.0,
    this.nodeMountExtraPadding = 400.0,
    this.syncViewportToState = SyncViewportMode.end,
    this.lodHideHandlesBelowZoom,
    this.lodThumbnailBelowZoom,
    this.translateExtent = const CoordinateExtent(),
    this.nodeExtent = const CoordinateExtent(),
    this.minNodeSize,
    this.maxNodeSize,
    this.preventScrolling = true,
  })  : assert(minZoom > 0, 'minZoom must be greater than 0'),
        assert(maxZoom > 0, 'maxZoom must be greater than 0'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom'),
        assert(autoPanSpeed > 0, 'autoPanSpeed must be positive'),
        assert(autoPanMargin >= 0, 'autoPanMargin must be non-negative'),
        assert(panOnScrollSpeed > 0, 'panOnScrollSpeed must be positive');

  /// Creates viewport options for read-only viewing.
  ///
  /// Disables all user interactions except viewing and zooming with controls.
  /// Users cannot pan, select, or modify the diagram.
  ///
  /// Example:
  /// ```
  /// FlowCanvas(
  ///   viewportOptions: ViewportOptions.readOnly(),
  /// )
  /// ```
  const ViewportOptions.readOnly({
    this.defaultViewport,
    this.fitView = false,
    this.minZoom = 0.5,
    this.maxZoom = 2.0,
  })  : fitViewOptions = const FitViewOptions(),
        panOnDrag = const {},
        panOnScroll = false,
        panOnScrollSpeed = 0.5,
        panOnScrollMode = PanOnScrollMode.free,
        zoomOnScroll = false,
        zoomOnPinch = false,
        zoomOnDoubleClick = false,
        selectionOnDrag = false,
        selectionMode = SelectionMode.full,
        autoPanOnConnect = false,
        autoPanOnNodeDrag = false,
        autoPanOnSelection = false,
        autoPanSpeed = 15.0,
        autoPanMargin = 50.0,
        snapToGrid = false,
        snapGrid = const SnapGrid(),
        onlyRenderVisibleElements = true,
        renderCullingPadding = 200.0,
        nodeMountExtraPadding = 400.0,
        syncViewportToState = SyncViewportMode.end,
        lodHideHandlesBelowZoom = null,
        lodThumbnailBelowZoom = null,
        translateExtent = const CoordinateExtent(),
        nodeExtent = const CoordinateExtent(),
        minNodeSize = null,
        maxNodeSize = null,
        preventScrolling = true,
        assert(minZoom > 0, 'minZoom must be greater than 0'),
        assert(maxZoom > 0, 'maxZoom must be greater than 0'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom');

  /// Returns a copy of these options with the given fields replaced.
  ViewportOptions copyWith({
    FlowViewport? defaultViewport,
    bool? fitView,
    FitViewOptions? fitViewOptions,
    double? minZoom,
    double? maxZoom,
    Set<int>? panOnDrag,
    bool? panOnScroll,
    double? panOnScrollSpeed,
    PanOnScrollMode? panOnScrollMode,
    bool? zoomOnScroll,
    bool? zoomOnPinch,
    bool? zoomOnDoubleClick,
    bool? selectionOnDrag,
    SelectionMode? selectionMode,
    bool? autoPanOnConnect,
    bool? autoPanOnNodeDrag,
    bool? autoPanOnSelection,
    double? autoPanSpeed,
    double? autoPanMargin,
    bool? snapToGrid,
    SnapGrid? snapGrid,
    bool? onlyRenderVisibleElements,
    double? renderCullingPadding,
    double? nodeMountExtraPadding,
    SyncViewportMode? syncViewportToState,
    double? lodHideHandlesBelowZoom,
    double? lodThumbnailBelowZoom,
    CoordinateExtent? translateExtent,
    CoordinateExtent? nodeExtent,
    Size? minNodeSize,
    Size? maxNodeSize,
    bool? preventScrolling,
  }) {
    return ViewportOptions(
      defaultViewport: defaultViewport ?? this.defaultViewport,
      fitView: fitView ?? this.fitView,
      fitViewOptions: fitViewOptions ?? this.fitViewOptions,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      panOnDrag: panOnDrag ?? this.panOnDrag,
      panOnScroll: panOnScroll ?? this.panOnScroll,
      panOnScrollSpeed: panOnScrollSpeed ?? this.panOnScrollSpeed,
      panOnScrollMode: panOnScrollMode ?? this.panOnScrollMode,
      zoomOnScroll: zoomOnScroll ?? this.zoomOnScroll,
      zoomOnPinch: zoomOnPinch ?? this.zoomOnPinch,
      zoomOnDoubleClick: zoomOnDoubleClick ?? this.zoomOnDoubleClick,
      selectionOnDrag: selectionOnDrag ?? this.selectionOnDrag,
      selectionMode: selectionMode ?? this.selectionMode,
      autoPanOnConnect: autoPanOnConnect ?? this.autoPanOnConnect,
      autoPanOnNodeDrag: autoPanOnNodeDrag ?? this.autoPanOnNodeDrag,
      autoPanOnSelection: autoPanOnSelection ?? this.autoPanOnSelection,
      autoPanSpeed: autoPanSpeed ?? this.autoPanSpeed,
      autoPanMargin: autoPanMargin ?? this.autoPanMargin,
      snapToGrid: snapToGrid ?? this.snapToGrid,
      snapGrid: snapGrid ?? this.snapGrid,
      onlyRenderVisibleElements:
          onlyRenderVisibleElements ?? this.onlyRenderVisibleElements,
      renderCullingPadding:
          renderCullingPadding ?? this.renderCullingPadding,
      nodeMountExtraPadding:
          nodeMountExtraPadding ?? this.nodeMountExtraPadding,
      syncViewportToState: syncViewportToState ?? this.syncViewportToState,
      lodHideHandlesBelowZoom:
          lodHideHandlesBelowZoom ?? this.lodHideHandlesBelowZoom,
      lodThumbnailBelowZoom:
          lodThumbnailBelowZoom ?? this.lodThumbnailBelowZoom,
      translateExtent: translateExtent ?? this.translateExtent,
      nodeExtent: nodeExtent ?? this.nodeExtent,
      minNodeSize: minNodeSize ?? this.minNodeSize,
      maxNodeSize: maxNodeSize ?? this.maxNodeSize,
      preventScrolling: preventScrolling ?? this.preventScrolling,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ViewportOptions &&
        other.defaultViewport == defaultViewport &&
        other.fitView == fitView &&
        other.fitViewOptions == fitViewOptions &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        setEquals(other.panOnDrag, panOnDrag) &&
        other.panOnScroll == panOnScroll &&
        other.panOnScrollSpeed == panOnScrollSpeed &&
        other.panOnScrollMode == panOnScrollMode &&
        other.zoomOnScroll == zoomOnScroll &&
        other.zoomOnPinch == zoomOnPinch &&
        other.zoomOnDoubleClick == zoomOnDoubleClick &&
        other.selectionOnDrag == selectionOnDrag &&
        other.selectionMode == selectionMode &&
        other.autoPanOnConnect == autoPanOnConnect &&
        other.autoPanOnNodeDrag == autoPanOnNodeDrag &&
        other.autoPanOnSelection == autoPanOnSelection &&
        other.autoPanSpeed == autoPanSpeed &&
        other.autoPanMargin == autoPanMargin &&
        other.snapToGrid == snapToGrid &&
        other.snapGrid == snapGrid &&
        other.onlyRenderVisibleElements == onlyRenderVisibleElements &&
        other.renderCullingPadding == renderCullingPadding &&
        other.nodeMountExtraPadding == nodeMountExtraPadding &&
        other.syncViewportToState == syncViewportToState &&
        other.lodHideHandlesBelowZoom == lodHideHandlesBelowZoom &&
        other.lodThumbnailBelowZoom == lodThumbnailBelowZoom &&
        other.translateExtent == translateExtent &&
        other.nodeExtent == nodeExtent &&
        other.minNodeSize == minNodeSize &&
        other.maxNodeSize == maxNodeSize &&
        other.preventScrolling == preventScrolling;
  }

  @override
  int get hashCode => Object.hashAll([
        defaultViewport,
        fitView,
        fitViewOptions,
        minZoom,
        maxZoom,
        Object.hashAll(panOnDrag),
        panOnScroll,
        panOnScrollSpeed,
        panOnScrollMode,
        zoomOnScroll,
        zoomOnPinch,
        zoomOnDoubleClick,
        selectionOnDrag,
        selectionMode,
        autoPanOnConnect,
        autoPanOnNodeDrag,
        autoPanOnSelection,
        autoPanSpeed,
        autoPanMargin,
        snapToGrid,
        snapGrid,
        onlyRenderVisibleElements,
        renderCullingPadding,
        nodeMountExtraPadding,
        syncViewportToState,
        lodHideHandlesBelowZoom,
        lodThumbnailBelowZoom,
        translateExtent,
        nodeExtent,
        minNodeSize,
        maxNodeSize,
        preventScrolling,
      ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
        DiagnosticsProperty<FlowViewport?>('defaultViewport', defaultViewport));
    properties
        .add(FlagProperty('fitView', value: fitView, ifTrue: 'fit on init'));
    properties.add(DoubleProperty('minZoom', minZoom, defaultValue: 0.5));
    properties.add(DoubleProperty('maxZoom', maxZoom, defaultValue: 2.0));
    properties.add(DiagnosticsProperty<Set<int>>('panOnDrag', panOnDrag,
        defaultValue: const {PanMouseButton.left}));
    properties.add(FlagProperty('panOnScroll',
        value: panOnScroll, defaultValue: false, ifTrue: 'pan on scroll'));
    properties.add(FlagProperty('zoomOnScroll',
        value: zoomOnScroll, defaultValue: true, ifFalse: 'no zoom on scroll'));
    properties.add(FlagProperty('selectionOnDrag',
        value: selectionOnDrag,
        defaultValue: false,
        ifTrue: 'selection on drag'));
    properties.add(EnumProperty<SelectionMode>('selectionMode', selectionMode));
    properties
        .add(DoubleProperty('autoPanSpeed', autoPanSpeed, defaultValue: 15.0));
    properties.add(
        DoubleProperty('autoPanMargin', autoPanMargin, defaultValue: 50.0));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'ViewportOptions(zoom: $minZoom-$maxZoom, panOnDrag: $panOnDrag, scroll: ${zoomOnScroll ? "zoom" : panOnScroll ? "pan" : "disabled"})';
  }

  /// Whether left-button drag should drive [InteractiveViewer] pan.
  bool get panOnDragLeft => panOnDrag.contains(PanMouseButton.left);

  /// Whether [buttons] bitmask (Flutter pointer) matches a configured pan button
  /// other than left (middle/right custom pan).
  bool isAuxiliaryPanButton(int buttons) {
    if (panOnDrag.contains(PanMouseButton.middle) &&
        (buttons & kMiddleMouseButton) != 0) {
      return true;
    }
    if (panOnDrag.contains(PanMouseButton.right) &&
        (buttons & kSecondaryButton) != 0) {
      return true;
    }
    return false;
  }
}
