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
import 'package:lattice/src/features/viewport/application/viewport_animator.dart';
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
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/edges/domain/edge_state.dart';
import 'package:lattice/src/features/handles/domain/handle_state.dart';
import 'package:lattice/src/features/a11y/application/a11y_announcer.dart';
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
  @override
  final LiveViewport liveViewport = LiveViewport();

  /// Mutable drag buffer (positions / active edges).
  final InteractionSession interactionSession = InteractionSession();

  /// Per-canvas screen-reader announcement bus (no state, no history).
  final A11yAnnouncer a11yAnnouncer = A11yAnnouncer();

  /// Hysteresis cache for visible-node culling.
  final VisibleCullCache visibleCullCache = VisibleCullCache();

  /// Frame-driven camera animation (fitView / center / setViewport).
  final ViewportAnimator viewportAnimator = ViewportAnimator();

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
      spatialIndex: spatialIndex,
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
      announcer: a11yAnnouncer,
    );

    final initial = initialState ?? FlowCanvasState.initial();

    spatialIndex.rebuild(initial.nodes.values, initial.edges,
        defaultOrigin: ref.read(flowOptionsProvider).nodeOptions.nodeOrigin);
    bumpSpatialVersion();

    transformationController.addListener(_onTransformationChanged);

    ref.onDispose(() {
      transformationController.removeListener(_onTransformationChanged);
      transformationController.dispose();
      liveViewport.dispose();
      interactionSession.dispose();
      viewportAnimator.dispose();
      a11yAnnouncer.dispose();
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
    final changed = edgeGeometry.updateGeometryIfNeeded(candidate,
        defaultOrigin: ref.read(flowOptionsProvider).nodeOptions.nodeOrigin);
    if (!changed) return candidate;
    return candidate.copyWith(
      geometryRevision: oldState.geometryRevision + 1,
    );
  }

  /// Re-indexes space after a `NodeOptions.nodeOrigin` change.
  ///
  /// Cell placement and cached edge paths depend on the origin, so both are
  /// rebuilt/cleared. Called from `FlowCanvas.didUpdateWidget`; no-op when
  /// the origin did not actually change.
  void syncNodeOrigin() {
    final origin = ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;
    final before = spatialIndex.nodeIndex.defaultOrigin;
    spatialIndex.syncDefaultOrigin(origin, state.nodes.values, state.edges);
    if (spatialIndex.nodeIndex.defaultOrigin != before) {
      edgeGeometryService.clearCache();
      bumpSpatialVersion();
    }
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
  ///
  /// A user grab wins over programmatic camera flights: the animation stops
  /// and the live position commits so state never snaps back.
  void onViewportInteractionStart() {
    cancelViewportAnimation();
    ref.read(flowCanvasCallbacksProvider).onMoveStart?.call(
          CanvasViewportInfo(
              viewport: state.viewport, viewportSize: state.viewportSize),
        );
  }

  /// Called from [InteractiveViewer.onInteractionEnd] — commits Freezed viewport.
  void onViewportInteractionEnd() {
    commitLiveViewportToState();
    ref.read(flowCanvasCallbacksProvider).onMoveEnd?.call(
          CanvasViewportInfo(
              viewport: state.viewport, viewportSize: state.viewportSize),
        );
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

  /// Routes a secondary-button tap to node/edge/pane context callbacks
  /// (Lattice `onNodeContextMenu`/`onEdgeContextMenu`/`onPaneContextMenu`).
  ///
  /// Topmost visible node wins, then edge stroke, then empty pane. Called
  /// from the viewport surface when a secondary press releases without
  /// dragging (a drag becomes an aux-pan instead).
  void fireContextMenuAt(Offset globalPosition) {
    final flow = viewport.flowPositionFromGlobal(globalPosition);
    if (flow == null) return;
    final cbs = ref.read(flowCanvasCallbacksProvider);
    final nodeOrigin = ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;

    FlowNode? top;
    for (final id in spatialIndex.nodeIndex.queryNodesInRect(
      Rect.fromCenter(center: flow, width: 1, height: 1),
    )) {
      final candidate = state.nodes[id];
      if (candidate == null || (candidate.hidden ?? false)) continue;
      if (!NodeLayout.absoluteRect(candidate, state.nodes,
              defaultOrigin: nodeOrigin)
          .contains(flow)) {
        continue;
      }
      if (top == null || candidate.zIndex > top.zIndex) {
        top = candidate;
      }
    }
    if (top != null) {
      // Lattice `onSelectionContextMenu`: right-clicking a selected node
      // also notifies with the selection (alongside onNodeContextMenu).
      final selected = state.selectedNodes;
      if (selected.contains(top.id)) {
        final nodes = <FlowNode>[];
        for (final id in selected) {
          final n = state.nodes[id];
          if (n != null) nodes.add(n);
        }
        nodes.sort((a, b) => a.id.compareTo(b.id));
        cbs.onSelectionContextMenu?.call(flow, nodes);
      }
      cbs.onNodeContextMenu?.call(top, flow);
      return;
    }
    final edgeId = edgeGeometryService.hitTestEdgeAt(
        flow, state, state.viewport.zoom);
    final edge = edgeId == null ? null : state.edges[edgeId];
    if (edge != null) {
      cbs.onEdgeContextMenu?.call(edge, flow);
      return;
    }
    cbs.onPaneContextMenu?.call(flow);
  }

  /// Whether a programmatic camera flight is in progress.
  bool get isViewportAnimating => viewportAnimator.isAnimating;

  /// Animates the live camera to [target], committing once on landing.
  ///
  /// Frames write the matrix only (no Freezed churn, same hot path as
  /// auto-pan); the single state commit lands in [commitLiveViewportToState].
  /// Starting a new flight replaces the previous one from its live position.
  /// Returns true on landing, false when superseded, cancelled, or locked.
  Future<bool> animateViewportTo(
    FlowViewport target, {
    required Duration duration,
    required Curve ease,
    required FitViewInterpolation interpolate,
  }) {
    if (state.isPanZoomLocked) return Future.value(false);
    final clamped = _viewportService.clampViewport(
      target,
      ref.read(flowOptionsProvider).viewportOptions.translateExtent,
    );
    return viewportAnimator.start(
      from: liveViewport.viewport,
      to: clamped,
      duration: duration,
      ease: ease,
      interpolate: interpolate,
      onTick: setLiveViewport,
      onDone: commitLiveViewportToState,
    );
  }

  /// Stops a camera flight, committing the live position so state never
  /// snaps back. No-op when idle.
  void cancelViewportAnimation() {
    if (!viewportAnimator.isAnimating) return;
    viewportAnimator.cancel();
    commitLiveViewportToState();
  }

  /// Writes a viewport to the live matrix without a Freezed write.
  ///
  /// Shared by auto-pan deltas and camera-animation frames.
  void setLiveViewport(FlowViewport viewport) {
    if (state.isPanZoomLocked) return;
    final next = _viewportService.clampViewport(
      viewport,
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

  /// Applies a pan delta to the live matrix without a Freezed write (auto-pan).
  void panLiveBy(Offset delta) {
    if (state.isPanZoomLocked) return;
    final current = liveViewport.viewport;
    setLiveViewport(
      FlowViewport(offset: current.offset + delta, zoom: current.zoom),
    );
  }

  @override
  FlowCanvasState get currentState => state;

  /// Removes nodes (with descendants) and edges in a single undo step.
  ///
  /// Lattice `deleteElements` counterpart. Connected edges of removed nodes
  /// go away too; `deletable: false` nodes survive (and keep their edges
  /// unless explicitly listed). Explicitly listed edges with
  /// `deletable: false` are kept.
  ///
  /// Runs [FlowCanvasCallbacks.onBeforeDelete] (veto/transform), then fires
  /// [FlowCanvasCallbacks.onDelete]/`onNodesDelete`/`onEdgesDelete` plus the
  /// low-level remove changes. Returns the removed objects (RF returns
  /// `{nodes, edges}`).
  FlowDeletedElements deleteElements({
    Iterable<String> nodeIds = const {},
    Iterable<String> edgeIds = const {},
  }) {
    const empty = FlowDeletedElements(nodes: [], edges: []);
    final oldState = state;
    if (nodeIds.isEmpty && edgeIds.isEmpty) return empty;

    Set<String> wantedNodes = nodeIds.toSet();
    Set<String> wantedEdges = edgeIds.toSet();

    // Resolve one candidate set (shared with the veto gate).
    ({List<String> nodeIds, List<String> edgeIds, FlowCanvasState rest})
        resolve(Set<String> nodes, Set<String> edges) {
      final options = ref.read(flowOptionsProvider);
      final allRemoved = _nodeService.getDescendants(oldState, nodes);
      final stateWithoutNodes = _nodeService.removeNodes(
        oldState,
        allRemoved.toList(),
        nodesDeletable: options.nodeOptions.deletable,
      );
      final removedNodeIds = <String>[
        for (final id in allRemoved)
          if (oldState.nodes.containsKey(id) &&
              !stateWithoutNodes.nodes.containsKey(id))
            id,
      ];
      final connectedEdgeIds =
          _edgeService.getEdgesFromNodes(oldState, removedNodeIds);
      final removedEdgeIds = <String>{
        ...connectedEdgeIds,
        for (final id in edges)
          if (oldState.edges.containsKey(id) &&
              (oldState.edges[id]?.deletable ?? options.edgeOptions.deletable))
            id,
      };
      return (
        nodeIds: removedNodeIds,
        edgeIds: removedEdgeIds.toList(),
        rest: stateWithoutNodes
      );
    }

    var resolved = resolve(wantedNodes, wantedEdges);
    var removedNodeIds = resolved.nodeIds;
    var removedEdgeIds = resolved.edgeIds;
    var stateWithoutNodes = resolved.rest;
    if (removedNodeIds.isEmpty && removedEdgeIds.isEmpty) return empty;

    final cbs = ref.read(flowCanvasCallbacksProvider);
    if (cbs.onBeforeDelete != null) {
      final plan = cbs.onBeforeDelete!(FlowDeleteCandidates(
        nodes: [for (final id in removedNodeIds) oldState.nodes[id]!],
        edges: [for (final id in removedEdgeIds) oldState.edges[id]!],
      ));
      if (plan == null) {
        // proceed
      } else if (plan.veto) {
        return empty;
      } else {
        if (plan.nodeIds != null) {
          wantedNodes = plan.nodeIds!.toSet();
        }
        if (plan.edgeIds != null) {
          wantedEdges = plan.edgeIds!.toSet();
        }
        resolved = resolve(wantedNodes, wantedEdges);
        removedNodeIds = resolved.nodeIds;
        removedEdgeIds = resolved.edgeIds;
        stateWithoutNodes = resolved.rest;
        if (removedNodeIds.isEmpty && removedEdgeIds.isEmpty) return empty;
      }
    }

    var newState =
        _edgeService.removeEdges(stateWithoutNodes, removedEdgeIds);
    final staleEdges =
        newState.selectedEdges.intersection(removedEdgeIds.toSet());
    if (staleEdges.isNotEmpty) {
      newState = newState.copyWith(
        selectedEdges: Set<String>.from(newState.selectedEdges)
          ..removeAll(staleEdges),
      );
    }
    mutate((_) => newState);

    for (final edgeId in removedEdgeIds) {
      final edge = oldState.edges[edgeId];
      if (edge != null) spatialIndex.edgeIndex.removeEdge(edgeId, edge);
    }
    edgeGeometryService.removeEdges(removedEdgeIds.toSet());
    for (final nodeId in removedNodeIds) {
      final node = oldState.nodes[nodeId];
      if (node != null) spatialIndex.nodeIndex.removeNode(node);
    }
    bumpSpatialVersion();

    final deleted = FlowDeletedElements(
      nodes: [for (final id in removedNodeIds) oldState.nodes[id]!],
      edges: [for (final id in removedEdgeIds) oldState.edges[id]!],
    );
    if (removedEdgeIds.isNotEmpty) {
      cbs.onEdgesChange
          ?.call(removedEdgeIds.map((e) => EdgeRemoveChange(id: e)).toList());
      cbs.onEdgesDelete?.call(deleted.edges);
    }
    if (removedNodeIds.isNotEmpty) {
      cbs.onNodesChange
          ?.call(removedNodeIds.map((id) => NodeRemoveChange(id: id)).toList());
      cbs.onNodesDelete?.call(deleted.nodes);
    }
    if (deleted.isNotEmpty) {
      cbs.onDelete?.call(deleted);
    }
    return deleted;
  }

  void load(FlowCanvasState newState) {
    final oldState = state;
    spatialIndex.rebuild(newState.nodes.values, newState.edges);
    bumpSpatialVersion();
    final finalized = _commitGeometry(oldState, newState);
    state = finalized;
    _history.init(finalized);
    _onStateChanged(oldState, finalized);
  }

  /// Flips the master element-interaction switch (Lattice `setInteractive`
  /// / Controls `showInteractive`). Transient write (no history entry):
  /// node drag/select, edge select, connection starts, and marquees stop
  /// while false; viewport, observations, and programmatic APIs keep
  /// working.
  void setInteractive(bool interactive) {
    if (state.interactive == interactive) return;
    updateStateOnly(state.copyWith(interactive: interactive));
  }

  /// Applies a remote collaborator's graph without touching local UI state
  /// or undo history.
  ///
  /// Multiplayer counterpart to [load]: takes the durable graph
  /// (nodes/edges/z-range) from [remote] — typically decoded from a peer's
  /// `toSyncJson()` — while selection, viewport, sizes, locks, and all
  /// transient interaction state stay local. Runtime states are preserved
  /// for surviving ids (so hover/drag flags don't flicker) and defaulted
  /// for new ones.
  ///
  /// History is rebased, not reset: stored snapshots absorb the remote
  /// graph, so Ctrl+Z undoes YOUR op on top of the shared graph instead of
  /// time-traveling away a peer's work (remote wins on conflict).
  ///
  /// Deliberately emits no `onNodesChange`/`onEdgesChange` (like [load]):
  /// the sync layer already knows about these ops, and echoing them back
  /// would loop. Observe everything (including remote applies) via
  /// `controller.addListener` instead.
  ///
  /// Durable commits only — do not stream per-frame drags through here
  /// (snail-mail, not a firehose); live drags belong on the ephemeral
  /// presence channel.
  void applyRemote(FlowCanvasState remote) {
    final oldState = state;

    final nodeStates =
        Map<String, NodeRuntimeState>.of(oldState.nodeStates)
          ..removeWhere((id, _) => !remote.nodes.containsKey(id));
    for (final id in remote.nodes.keys) {
      nodeStates.putIfAbsent(id, () => const NodeRuntimeState());
    }
    final edgeStates =
        Map<String, EdgeRuntimeState>.of(oldState.edgeStates)
          ..removeWhere((id, _) => !remote.edges.containsKey(id));
    for (final id in remote.edges.keys) {
      edgeStates.putIfAbsent(id, () => const EdgeRuntimeState());
    }
    final handleStates =
        Map<String, HandleRuntimeState>.of(oldState.handleStates)
          ..removeWhere(
            // Keys are `nodeId/handleId`: drop entries whose node is gone.
            (key, _) => !remote.nodes.containsKey(key.split('/').first),
          );

    final next = remote.copyWith(
      selectedNodes: oldState.selectedNodes,
      selectedEdges: oldState.selectedEdges,
      viewport: oldState.viewport,
      viewportSize: oldState.viewportSize,
      isPanZoomLocked: oldState.isPanZoomLocked,
      interactive: oldState.interactive,
      dragMode: oldState.dragMode,
      activeConnection: oldState.activeConnection,
      connectionState: oldState.connectionState,
      selectionRect: oldState.selectionRect,
      hoveredEdgeId: oldState.hoveredEdgeId,
      lastClickedEdgeId: oldState.lastClickedEdgeId,
      geometryRevision: oldState.geometryRevision,
      edgeLiveStamp: oldState.edgeLiveStamp,
      nodeStates: nodeStates,
      edgeStates: edgeStates,
      handleStates: handleStates,
    );

    spatialIndex.rebuild(next.nodes.values, next.edges);
    bumpSpatialVersion();
    // Delta only (not the full graph): overlaying everything would bake my
    // own uncommitted work into every history entry, making it un-undoable.
    final upsertedNodes = <String, FlowNode>{};
    for (final entry in next.nodes.entries) {
      if (oldState.nodes[entry.key] != entry.value) {
        upsertedNodes[entry.key] = entry.value;
      }
    }
    final upsertedEdges = <String, FlowEdge>{};
    for (final entry in next.edges.entries) {
      if (oldState.edges[entry.key] != entry.value) {
        upsertedEdges[entry.key] = entry.value;
      }
    }
    _history.rebaseRemote(
      removedNodeIds:
          oldState.nodes.keys.toSet().difference(next.nodes.keys.toSet()),
      remoteNodes: upsertedNodes,
      removedEdgeIds:
          oldState.edges.keys.toSet().difference(next.edges.keys.toSet()),
      remoteEdges: upsertedEdges,
    );
    final finalized = _commitGeometry(oldState, next);
    state = finalized;
    _onStateChanged(oldState, finalized);
  }
}
