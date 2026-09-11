import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/features/canvas/interaction_session.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_controller.dart';
import 'package:lattice/src/features/connections/application/connection_controller.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_controller.dart';
import 'package:lattice/src/features/edges/application/edges_controller.dart';
import 'package:lattice/src/features/handles/application/handles_controller.dart';
import 'package:lattice/src/features/history/application/history_controller.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_controller.dart';
import 'package:lattice/src/features/nodes/application/nodes_controller.dart';
import 'package:lattice/src/features/selection/application/selection_controller.dart';
import 'package:lattice/src/features/viewport/application/viewport_controller.dart';
import 'package:lattice/src/features/viewport/domain/live_viewport.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:lattice/src/features/viewport/domain/viewport_transform.dart';
import 'package:lattice/src/features/viewport/domain/visible_cull_cache.dart';
import 'package:lattice/src/features/z_index/application/z_index_controller.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_service.dart';
import 'package:lattice/src/features/connections/application/connection_service.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/history/application/history_service.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_action_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/spatial/application/spatial_index_service.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';
import 'package:lattice/src/features/z_index/application/z_index_service.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlowCanvasInternalController extends Notifier<FlowCanvasState>
    implements CanvasStateAccessor {
  final FlowCanvasState? initialState;

  final TransformationController transformationController =
      TransformationController();
  final GlobalKey canvasKey = GlobalKey();
  final GlobalKey viewportKey = GlobalKey();

  /// Live camera for overlays; updated every matrix tick without Freezed writes.
  final LiveViewport liveViewport = LiveViewport();

  /// Mutable drag buffer (positions / active edges).
  final InteractionSession interactionSession = InteractionSession();

  /// Hysteresis cache for visible-node culling.
  final VisibleCullCache visibleCullCache = VisibleCullCache();

  late final NodeService _nodeService;
  late final EdgeService _edgeService;
  late final SelectionService _selectionService;
  late final ViewportService _viewportService;
  late final ConnectionService _connectionService;
  late final ZIndexService _zIndexService;
  late final ClipboardService _clipboardService;
  late final HistoryService _history;
  late final KeyboardActionService _keyboardActionService;
  late final EdgeGeometryService edgeGeometryService;
  late final SpatialIndexService spatialIndex;

  late final NodesController nodes;
  late final EdgesController edges;
  late final SelectionController selection;
  late final ViewportController viewport;
  late final ConnectionController connection;
  late final ClipboardController clipboard;
  late final HistoryController history;
  late final HandleController handle;
  late final EdgeGeometryController edgeGeometry;
  late final ZIndexController zIndex;
  late final KeyboardController keyboard;

  FlowCanvasInternalController({
    this.initialState,
  });

  bool _viewportSyncFromState = false;
  bool _viewportCallbackScheduled = false;
  FlowViewport? _pendingLiveCallbackViewport;

  /// Spatial index generation; bumped on structural/geometry index changes.
  int spatialVersion = 0;

  final List<void Function(FlowCanvasState)> _listeners = [];

  void addListener(void Function(FlowCanvasState) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(FlowCanvasState) listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners(FlowCanvasState newState) {
    for (final listener in _listeners) {
      listener(newState);
    }
  }

  void bumpSpatialVersion() {
    spatialVersion++;
    visibleCullCache.invalidate();
  }

  @override
  FlowCanvasState build() {
    _nodeService = ref.read(nodeServiceProvider);
    _edgeService = ref.read(edgeServiceProvider);
    _selectionService = ref.read(selectionServiceProvider);
    _viewportService = ref.read(viewportServiceProvider);
    _connectionService = ref.read(connectionServiceProvider);
    _zIndexService = ref.read(zIndexServiceProvider);
    _clipboardService = ref.read(clipboardServiceProvider);
    _history = ref.read(historyServiceProvider);

    _keyboardActionService = ref.read(keyboardActionServiceProvider);
    edgeGeometryService = ref.read(edgeGeometryServiceProvider);
    spatialIndex = ref.read(spatialIndexServiceProvider);

    selection = SelectionController(
      controller: this,
      selectionService: _selectionService,
      spatialIndex: spatialIndex,
      ref: ref,
      viewportKey: viewportKey,
      transformationController: transformationController,
    );
    viewport = ViewportController(
      controller: this,
      viewportService: _viewportService,
      ref: ref,
      viewportHostKey: viewportKey,
    );
    nodes = NodesController(
      controller: this,
      nodeService: _nodeService,
      edgeService: _edgeService,
      selectionController: selection,
      spatialIndex: spatialIndex,
      edgeGeometryService: edgeGeometryService,
      viewportKey: viewportKey,
      interactionSession: interactionSession,
      ref: ref,
    );
    edges = EdgesController(
      controller: this,
      edgeService: _edgeService,
      edgeGeometryService: edgeGeometryService,
      selectionController: selection,
      ref: ref,
    );
    connection = ConnectionController(
      controller: this,
      connectionService: _connectionService,
      spatialIndex: spatialIndex,
      ref: ref,
      viewportKey: viewportKey,
    );
    clipboard = ClipboardController(
      controller: this,
      clipboardService: _clipboardService,
      nodeService: _nodeService,
      edgeService: _edgeService,
    );
    history = HistoryController(
      controller: this,
      history: _history,
      spatialIndex: spatialIndex,
    );
    handle = HandleController(controller: this);
    edgeGeometry = EdgeGeometryController(
      edgeGeometryService: edgeGeometryService,
      spatialIndex: spatialIndex,
    );
    zIndex = ZIndexController(controller: this, zIndexService: _zIndexService);
    keyboard = KeyboardController(
      controller: this,
      keyboardActionService: _keyboardActionService,
      historyController: history,
    );

    final initial = initialState ?? FlowCanvasState.initial();

    spatialIndex.rebuild(initial.nodes.values, initial.edges);
    bumpSpatialVersion();

    transformationController.addListener(_onTransformationChanged);

    ref.onDispose(() {
      transformationController.removeListener(_onTransformationChanged);
      transformationController.dispose();
      liveViewport.dispose();
      interactionSession.dispose();
    });

    final finalized = _commitGeometry(FlowCanvasState.initial(), initial);
    _history.init(finalized);
    _updateTransformationController(finalized);
    liveViewport.setViewport(finalized.viewport, force: true);

    return finalized;
  }

  /// Updates edge geometry caches when needed and bumps [geometryRevision]
  /// when paths actually change. Skips controller-driven geometry during
  /// [DragMode.node] because [NodesController] updates paths incrementally.
  FlowCanvasState _commitGeometry(
      FlowCanvasState oldState, FlowCanvasState candidate) {
    if (candidate.dragMode == DragMode.node) {
      return candidate;
    }
    final changed = edgeGeometry.updateGeometryIfNeeded(candidate);
    if (!changed) return candidate;
    return candidate.copyWith(
      geometryRevision: oldState.geometryRevision + 1,
    );
  }

  @override
  void mutate(FlowCanvasState Function(FlowCanvasState) mutation) {
    final oldState = state;
    final mutated = mutation(oldState);
    if (identical(mutated, oldState)) return;
    final newState = _commitGeometry(oldState, mutated);
    _history.record(newState);
    state = newState;
    _onStateChanged(oldState, newState);
  }

  @override
  void updateStateOnly(FlowCanvasState newState) {
    final oldState = state;
    if (identical(newState, oldState)) return;
    final finalized = _commitGeometry(oldState, newState);
    state = finalized;
    _onStateChanged(oldState, finalized);
  }

  @override
  void commitHistoryCheckpoint() {
    _history.record(state);
  }

  void _emitViewportAndSelectionCallbacks(
    FlowCanvasState oldState,
    FlowCanvasState newState,
  ) {
    final cbs = ref.read(flowCanvasCallbacksProvider);
    if (cbs.onViewportChange != null) {
      final vpChanged =
          !flowViewportNearEqual(oldState.viewport, newState.viewport);
      final sizeChanged = oldState.viewportSize != newState.viewportSize;
      if (vpChanged || sizeChanged) {
        cbs.onViewportChange!(CanvasViewportInfo(
          viewport: newState.viewport,
          viewportSize: newState.viewportSize,
        ));
      }
    }
    if (cbs.onSelectionChange != null) {
      final selChanged = oldState.selectedNodes != newState.selectedNodes ||
          oldState.selectedEdges != newState.selectedEdges;
      if (selChanged) {
        cbs.onSelectionChange!(CanvasSelection(
          nodeIds: Set<String>.from(newState.selectedNodes),
          edgeIds: Set<String>.from(newState.selectedEdges),
        ));
      }
    }
  }

  void _onStateChanged(FlowCanvasState oldState, FlowCanvasState newState) {
    _emitViewportAndSelectionCallbacks(oldState, newState);
    // Only push Freezed → matrix when viewport was intentionally updated in
    // state (fitView, commit, programmatic pan). Auto-pan keeps the matrix
    // ahead of Freezed; overwriting here on unrelated writes (e.g. node
    // drag-end) snaps the camera back to the pre-auto-pan position.
    if (!flowViewportNearEqual(oldState.viewport, newState.viewport)) {
      _updateTransformationController(newState);
      liveViewport.setViewport(newState.viewport);
    }
    _notifyListeners(newState);
  }

  void _updateTransformationController([FlowCanvasState? s]) {
    final viewport = (s ?? state).viewport;
    final stateMatrix = matrix4FromViewport(viewport);

    if (!matrix4NearEqual(transformationController.value, stateMatrix)) {
      _viewportSyncFromState = true;
      try {
        transformationController.value = stateMatrix;
      } finally {
        _viewportSyncFromState = false;
      }
    }
  }

  FlowViewport _viewportFromMatrix(Matrix4 matrix) {
    final parsed = flowViewportFromMatrix4(matrix);
    var newViewport = parsed ??
        FlowViewport(
          offset: Offset(matrix.getTranslation().x, matrix.getTranslation().y),
          zoom: matrix.getMaxScaleOnAxis(),
        );
    final extent =
        ref.read(flowOptionsProvider).viewportOptions.translateExtent;
    return _viewportService.clampViewport(newViewport, extent);
  }

  void _onTransformationChanged() {
    if (_viewportSyncFromState) return;

    final newViewport = _viewportFromMatrix(transformationController.value);
    liveViewport.setViewport(newViewport);

    final syncMode =
        ref.read(flowOptionsProvider).viewportOptions.syncViewportToState;

    if (syncMode == SyncViewportMode.live) {
      if (!flowViewportNearEqual(state.viewport, newViewport)) {
        updateStateOnly(state.copyWith(viewport: newViewport));
      }
    }

    // Throttled live callback (1/frame) without requiring Freezed writes.
    _scheduleLiveViewportCallback(newViewport);
  }

  void _scheduleLiveViewportCallback(FlowViewport vp) {
    if (ref.read(flowCanvasCallbacksProvider).onViewportChange == null) return;
    _pendingLiveCallbackViewport = vp;
    if (_viewportCallbackScheduled) return;
    _viewportCallbackScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _viewportCallbackScheduled = false;
      final pending = _pendingLiveCallbackViewport;
      final cb = ref.read(flowCanvasCallbacksProvider).onViewportChange;
      if (pending == null || cb == null) return;
      cb(CanvasViewportInfo(
        viewport: pending,
        viewportSize: state.viewportSize,
      ));
    });
    SchedulerBinding.instance.scheduleFrame();
  }

  /// Called from [InteractiveViewer.onInteractionStart].
  void onViewportInteractionStart() {}

  /// Called from [InteractiveViewer.onInteractionEnd] — commits Freezed viewport.
  void onViewportInteractionEnd() {
    commitLiveViewportToState();
  }

  /// Writes the current live/matrix viewport into Freezed state once.
  void commitLiveViewportToState() {
    final newViewport = _viewportFromMatrix(transformationController.value);
    liveViewport.setViewport(newViewport, force: true);
    if (!flowViewportNearEqual(state.viewport, newViewport)) {
      if (kDebugMode) FlowCanvasDebug.countPanCommit();
      updateStateOnly(state.copyWith(viewport: newViewport));
    }
  }

  /// Applies a pan delta to the live matrix without a Freezed write (auto-pan).
  void panLiveBy(Offset delta) {
    if (state.isPanZoomLocked) return;
    final current = liveViewport.viewport;
    final next = _viewportService.clampViewport(
      FlowViewport(offset: current.offset + delta, zoom: current.zoom),
      ref.read(flowOptionsProvider).viewportOptions.translateExtent,
    );
    liveViewport.setViewport(next);
    _viewportSyncFromState = true;
    try {
      transformationController.value = matrix4FromViewport(next);
    } finally {
      _viewportSyncFromState = false;
    }
  }

  @override
  FlowCanvasState get currentState => state;

  void load(FlowCanvasState newState) {
    final oldState = state;
    spatialIndex.rebuild(newState.nodes.values, newState.edges);
    bumpSpatialVersion();
    final finalized = _commitGeometry(oldState, newState);
    state = finalized;
    _history.init(finalized);
    _onStateChanged(oldState, finalized);
  }
}
