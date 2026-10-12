import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_callbacks.dart';
import 'lattice_camera.dart';
import 'lattice_clipboard.dart';
import 'lattice_codecs.dart';
import 'lattice_connection.dart';
import 'lattice_cull.dart';
import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_handle.dart';
import 'lattice_history.dart';
import 'lattice_layout.dart';
import 'lattice_lock.dart';
import 'lattice_node.dart';
import 'lattice_options.dart';
import 'lattice_selection.dart';
import 'lattice_spatial_index.dart';
import 'lattice_viewport_value.dart';
import 'node_resizer.dart';
import 'session_providers.dart';

/// Elements removed by [LatticeController.deleteElements] (or
/// [LatticeController.deleteSelection]): the pre-image objects, in document
/// iteration order. Empty when nothing was removed.
class LatticeDeletedElements {
  const LatticeDeletedElements({
    this.nodes = const [],
    this.edges = const [],
  });

  final List<LatticeNode> nodes;
  final List<LatticeEdge> edges;

  bool get isEmpty => nodes.isEmpty && edges.isEmpty;
}

/// User-owned controller for a lattice canvas session.
///
/// Creates its own [ProviderContainer] at construction, so graph verbs are
/// legal before any canvas mounts. The owning widget (or user code) must call
/// [dispose]; disposing twice is a no-op and never throws.
class LatticeController extends ChangeNotifier {
  LatticeController({
    List<LatticeNode> initialNodes = const [],
    List<LatticeEdge> initialEdges = const [],
    LatticeOptions options = const LatticeOptions(),
  })  : _options = options,
        _container = ProviderContainer() {
    _container.read(latticeDocumentProvider.notifier).replace(
          LatticeDocument(
            nodes: <String, LatticeNode>{
              for (final LatticeNode node in initialNodes) node.id: node,
            },
            edges: <String, LatticeEdge>{
              for (final LatticeEdge edge in initialEdges) edge.id: edge,
            },
            viewport:
                options.defaultViewport ?? const LatticeViewportValue(),
          ),
        );
  }

  final ProviderContainer _container;
  LatticeOptions _options;
  LatticeCallbacks? _callbacks;
  bool _attached = false;
  bool _disposed = false;

  /// Undo/redo history (plain field, not a provider). Every document
  /// verb records its pre-image here before replacing.
  final LatticeHistoryController _history = LatticeHistoryController();

  /// Session clipboard payload (copy/paste/duplicate source).
  final LatticeClipboard _clipboard = LatticeClipboard();

  /// Monotonic fresh-id counter for pasted copies (`node_copy_<n>` /
  /// `edge_copy_<n>`). Skips ids already present in the target document.
  int _copyCounter = 0;

  /// Monotonic fresh-id counter for connect-minted edges (`edge_<n>`).
  /// Separate from [_copyCounter]: the `edge_` prefix can never collide
  /// with pasted `edge_copy_<n>` ids.
  int _edgeCounter = 0;

  /// Top-left of the copied node bounds at [copySelection] time; the
  /// anchor `paste`/`duplicateSelection` measure deltas against. Null
  /// when the clipboard payload is empty.
  Offset? _clipboardAnchor;

  /// Number of edges in the copied payload; sizes the per-node fresh-id
  /// sets so the clipboard pool always covers retained edges.
  int _clipboardEdgeCount = 0;

  /// Controller-owned hit-test index, synced lazily on every verb that
  /// queries it: full `rebuild` when the key set changed, `moveNode`
  /// deltas otherwise (same pattern as the cull controller).
  final LatticeSpatialIndex _hitIndex = LatticeSpatialIndex();
  Map<String, LatticeNode>? _lastHitSynced;
  Map<String, LatticeNode> _hitSnapshot = const <String, LatticeNode>{};

  /// Drag-start document positions (flow `position` values), keyed by id.
  /// Accumulated deltas apply to these — never to re-read mutated state.
  Map<String, Offset> _dragStartPositions = const <String, Offset>{};
  Offset _dragAccumulated = Offset.zero;

  /// Resize session: the node + handle from [beginResize], the drag-start
  /// document size/position, and the accumulated flow delta. Deltas
  /// accumulate onto the start values — never onto re-read live state.
  String? _resizeNodeId;
  LatticeResizeHandle? _resizeHandle;
  Size? _resizeStartSize;
  Offset? _resizeStartPosition;
  Offset _resizeAccumulated = Offset.zero;

  /// Marquee anchor in flow coordinates, set by [beginMarquee].
  Offset? _marqueeAnchor;

  /// The session container owned by this controller.
  ProviderContainer get container => _container;

  /// The current session document.
  LatticeDocument get document =>
      _container.read(latticeDocumentProvider);

  /// Canvas options, read at build time. Setting this never notifies.
  LatticeOptions get options => _options;
  set options(LatticeOptions value) {
    _options = value;
  }

  /// Observation hooks attached by the owning canvas (or directly by user
  /// code). Null until [attachCallbacks] runs.
  LatticeCallbacks? get callbacks => _callbacks;

  /// Attaches [callbacks] to this session. Canvas use only: called once in
  /// [LatticeCanvas.initState]; later attachments overwrite earlier ones.
  @internal
  void attachCallbacks(LatticeCallbacks callbacks) {
    _callbacks = callbacks;
  }

  /// Whether a [LatticeCanvas] is currently mounted on this controller.
  bool get isAttached => _attached;

  /// Replaces the document's nodes, keeping edges and viewport.
  /// Bulk setter with `load` semantics: resets history (no push).
  /// Notifies listeners exactly once.
  void setNodes(Iterable<LatticeNode> nodes) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.reset();
    _container.read(latticeDocumentProvider.notifier).replace(
          current.copyWith(
            nodes: <String, LatticeNode>{
              for (final LatticeNode node in nodes) node.id: node,
            },
          ),
        );
    notifyListeners();
  }

  /// Replaces the document's edges, keeping nodes and viewport.
  /// Bulk setter with `load` semantics: resets history (no push).
  /// Notifies listeners exactly once.
  void setEdges(Iterable<LatticeEdge> edges) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.reset();
    _container.read(latticeDocumentProvider.notifier).replace(
          current.copyWith(
            edges: <String, LatticeEdge>{
              for (final LatticeEdge edge in edges) edge.id: edge,
            },
          ),
        );
    notifyListeners();
  }

  /// Replaces the whole document and clears the selection.
  /// Notifies listeners exactly once. `onSelectionChange` fires when the
  /// clear actually changed a non-empty selection.
  void load(LatticeDocument document) {
    _container.read(latticeDocumentProvider.notifier).replace(document);
    deselectAll();
    _history.reset();
    notifyListeners();
  }

  /// Inserts (or overwrites, on duplicate id) node [n].
  /// Notifies listeners exactly once. No-op (no push, no replace, no
  /// notify) when the document is already equal.
  void addNode(LatticeNode n) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withNode(n);
    if (next == current) return;
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
    _callbacks?.onNodesAdded?.call(<LatticeNode>[n]);
  }

  /// Inserts (or overwrites, on duplicate id) edge [e].
  /// Notifies listeners exactly once. No-op (no push, no replace, no
  /// notify) when the document is already equal.
  void addEdge(LatticeEdge e) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withEdge(e);
    if (next == current) return;
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
    _callbacks?.onEdgesAdded?.call(<LatticeEdge>[e]);
  }

  /// Applies [positions] to existing nodes only (unknown ids ignored) with
  /// a single `replace` + notify once. No-op (no replace, no notify) when
  /// nothing effectively changes.
  void moveNodes(Map<String, Offset> positions) {
    if (positions.isEmpty) return;
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    Map<String, LatticeNode>? next;
    positions.forEach((String id, Offset position) {
      final LatticeNode? node = (next ?? current.nodes)[id];
      if (node == null || node.position == position) return;
      next ??= Map<String, LatticeNode>.of(current.nodes);
      next![id] = node.copyWith(position: position);
    });
    if (next == null) return;
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.copyWith(nodes: next));
    notifyListeners();
  }

  /// Replaces the `data` payload of node [nodeId] via `copyWith` with a
  /// single history `push`, one `replace`, and one notification. No-op
  /// (no history, no replace, no notify) for unknown ids or when the
  /// payload is already equal.
  void updateNodeData(String nodeId, Object? data) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeNode? node = current.nodes[nodeId];
    if (node == null) return;
    final LatticeNode updated = node.copyWith(data: data);
    if (updated == node) return;
    _history.push(current);
    final Map<String, LatticeNode> nodes =
        Map<String, LatticeNode>.of(current.nodes);
    nodes[nodeId] = updated;
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.copyWith(nodes: nodes));
    notifyListeners();
  }

  /// Removes nodes [ids] (edges untouched; cascade is Task 4).
  /// Notifies listeners exactly once. No-op (no push, no replace, no
  /// notify) when nothing is removed.
  void removeNodes(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withoutNodes(ids);
    if (next == current) return;
    final List<LatticeNode> removed = <LatticeNode>[
      for (final String id in current.nodes.keys)
        if (ids.contains(id)) current.nodes[id]!,
    ];
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
    _callbacks?.onNodesRemoved?.call(removed);
  }

  /// Removes edges [ids]. Notifies listeners exactly once. No-op (no
  /// push, no replace, no notify) when nothing is removed.
  void removeEdges(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withoutEdges(ids);
    if (next == current) return;
    final List<LatticeEdge> removed = <LatticeEdge>[
      for (final String id in current.edges.keys)
        if (ids.contains(id)) current.edges[id]!,
    ];
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
    _callbacks?.onEdgesRemoved?.call(removed);
  }

  /// Deletes nodes [nodeIds] plus ALL descendants (walked downward via
  /// `parentId` chains from the requested set, cycle-safe through a visited
  /// set), all edges connected to any removed node, and explicitly listed
  /// edges [edgeIds]. Nodes with `deletable: false` survive — even when
  /// listed — and so do their connected edges unless those edges are
  /// explicitly listed; explicitly listed edges with `deletable: false`
  /// survive as well. Cascade-connected edges are always pruned (their
  /// endpoints would otherwise dangle), whatever their flag.
  ///
  /// One history `push`, one `replace`, one notification, then the
  /// selection is coerced to surviving ids. Empty result → no push,
  /// no replace, no notify at all. Returns the removed objects.
  LatticeDeletedElements deleteElements({
    Set<String> nodeIds = const {},
    Set<String> edgeIds = const {},
  }) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    if (nodeIds.isEmpty && edgeIds.isEmpty) {
      return const LatticeDeletedElements();
    }
    final Map<String, List<String>> children = <String, List<String>>{};
    for (final LatticeNode node in current.nodes.values) {
      final String? parentId = node.parentId;
      if (parentId != null) {
        (children[parentId] ??= <String>[]).add(node.id);
      }
    }
    final Set<String> closure = Set<String>.of(nodeIds);
    final List<String> queue = List<String>.of(nodeIds);
    while (queue.isNotEmpty) {
      final String id = queue.removeLast();
      for (final String child in children[id] ?? const <String>[]) {
        if (closure.add(child)) queue.add(child);
      }
    }
    final Set<String> removedNodeIds = <String>{};
    for (final String id in closure) {
      final LatticeNode? node = current.nodes[id];
      if (node != null && node.deletable != false) {
        removedNodeIds.add(id);
      }
    }
    final Set<String> removedEdgeIds = <String>{};
    for (final LatticeEdge edge in current.edges.values) {
      if (removedNodeIds.contains(edge.source.nodeId) ||
          removedNodeIds.contains(edge.target.nodeId)) {
        removedEdgeIds.add(edge.id);
      } else if (edgeIds.contains(edge.id) && edge.deletable != false) {
        removedEdgeIds.add(edge.id);
      }
    }
    if (removedNodeIds.isEmpty && removedEdgeIds.isEmpty) {
      return const LatticeDeletedElements();
    }
    final List<LatticeNode> removedNodes = <LatticeNode>[
      for (final String id in current.nodes.keys)
        if (removedNodeIds.contains(id)) current.nodes[id]!,
    ];
    final List<LatticeEdge> removedEdges = <LatticeEdge>[
      for (final String id in current.edges.keys)
        if (removedEdgeIds.contains(id)) current.edges[id]!,
    ];
    final Map<String, LatticeNode> nodes =
        Map<String, LatticeNode>.of(current.nodes)
          ..removeWhere(
            (String id, LatticeNode _) => removedNodeIds.contains(id),
          );
    final Map<String, LatticeEdge> edges =
        Map<String, LatticeEdge>.of(current.edges)
          ..removeWhere(
            (String id, LatticeEdge _) => removedEdgeIds.contains(id),
          );
    final LatticeDocument next = current.copyWith(nodes: nodes, edges: edges);
    _history.push(current);
    _container.read(latticeDocumentProvider.notifier).replace(next);
    _coerceSelection(next);
    notifyListeners();
    if (removedNodes.isNotEmpty) {
      _callbacks?.onNodesRemoved?.call(removedNodes);
    }
    if (removedEdges.isNotEmpty) {
      _callbacks?.onEdgesRemoved?.call(removedEdges);
    }
    return LatticeDeletedElements(
      nodes: removedNodes,
      edges: removedEdges,
    );
  }

  /// Deletes the current selection via [deleteElements]. Empty selection
  /// (or an undeletable one) → empty result, no history, no notify.
  LatticeDeletedElements deleteSelection() {
    final LatticeSelection selection =
        _container.read(latticeSelectionProvider);
    return deleteElements(
      nodeIds: selection.nodes,
      edgeIds: selection.edges,
    );
  }

  /// Sets the session selection. Selection-only: never notifies
  /// controller listeners. [callbacks]' `onSelectionChange` fires once,
  /// after the provider write, only when the selection actually changed.
  void select(Set<String> nodeIds, [Set<String> edgeIds = const {}]) {
    final LatticeSelection next = LatticeSelection(
      nodes: Set<String>.of(nodeIds),
      edges: Set<String>.of(edgeIds),
    );
    final LatticeSelection current =
        _container.read(latticeSelectionProvider);
    _container.read(latticeSelectionProvider.notifier).setSelection(next);
    if (next != current) {
      _callbacks?.onSelectionChange?.call(next);
    }
  }

  /// Clears the session selection. Never notifies controller listeners.
  /// `onSelectionChange` fires once when the selection was non-empty.
  void deselectAll() {
    final LatticeSelection current =
        _container.read(latticeSelectionProvider);
    _container.read(latticeSelectionProvider.notifier).clear();
    if (!current.isEmpty) {
      _callbacks?.onSelectionChange?.call(
        _container.read(latticeSelectionProvider),
      );
    }
  }

  /// Selects all node + edge ids in the document. Never notifies
  /// controller listeners. `onSelectionChange` fires once when the
  /// selection actually changed.
  void selectAll() {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeSelection next = LatticeSelection(
      nodes: Set<String>.of(current.nodes.keys),
      edges: Set<String>.of(current.edges.keys),
    );
    final LatticeSelection previous =
        _container.read(latticeSelectionProvider);
    _container.read(latticeSelectionProvider.notifier).setSelection(next);
    if (next != previous) {
      _callbacks?.onSelectionChange?.call(next);
    }
  }

  /// Returns the current document (same instance, no copy).
  LatticeDocument save() {
    return _container.read(latticeDocumentProvider);
  }

  /// Serializes the current document (`document.toJson(encode)`).
  Map<String, Object?> toJson([EncodeNodeData? encode]) {
    return document.toJson(encode);
  }

  /// Replaces the document from [json] via [load] (hence resets history
  /// and clears the selection, with exactly one notification).
  void loadJson(Map<String, Object?> json, [DecodeNodeData? decode]) {
    load(LatticeDocument.fromJson(json, decode));
  }

  /// Whether [undo] would restore a document.
  bool get canUndo => _history.canUndo;

  /// Whether [redo] would reapply a document.
  bool get canRedo => _history.canRedo;

  /// Restores the pre-image of the last document verb. Replaces the
  /// document and notifies exactly once. Coerces the selection to ids
  /// present in the restored document. No-op (no replace, no notify)
  /// when the undo stack is empty.
  void undo() {
    final LatticeDocument? previous =
        _history.undo(_container.read(latticeDocumentProvider));
    if (previous == null) return;
    _container.read(latticeDocumentProvider.notifier).replace(previous);
    _coerceSelection(previous);
    notifyListeners();
  }

  /// Reapplies the document undone by [undo]. Replaces the document
  /// and notifies exactly once. Coerces the selection to ids present
  /// in the restored document. No-op (no replace, no notify) when the
  /// redo stack is empty.
  void redo() {
    final LatticeDocument? next =
        _history.redo(_container.read(latticeDocumentProvider));
    if (next == null) return;
    _container.read(latticeDocumentProvider.notifier).replace(next);
    _coerceSelection(next);
    notifyListeners();
  }

  /// Camera/document viewport split: the camera matrix (session-side) is
  /// the live pan/zoom; the document's `viewport` is the SAVED viewport,
  /// written only by [saveViewport] (persistence needs it) and `load`.
  /// [zoomIn], [zoomOut], and [fitView] write the CAMERA only: zero
  /// document emissions, zero history, no controller notification.

  /// Whether the session is locked (reads [latticeLockProvider]). When
  /// locked, gesture starts (node drag, marquee, connect, reconnect,
  /// resize) and the camera verbs below no-op; selection taps still work.
  bool get isLocked => _container.read(latticeLockProvider);

  /// Whether gesture starts and the camera verbs are enabled: the session is
  /// unlocked AND `options.interactive` is true. Distinct from [isLocked]
  /// (a session toggle): `interactive: false` is a render-only canvas.
  /// Controller/router use only.
  @internal
  bool get gesturesEnabled => !isLocked && _options.interactive;

  /// Flips the session lock. Session-only: never notifies controller
  /// listeners (controls rebuild by watching [latticeLockProvider]).
  void toggleLock() {
    _container.read(latticeLockProvider.notifier).toggle();
  }

  /// Zooms the camera in by 1.25x about the pane center (or [Offset.zero]
  /// before first layout publishes a pane size). No-op when locked or when
  /// `options.interactive` is false. Camera-only: never touches the
  /// document, never notifies.
  void zoomIn() {
    if (!gesturesEnabled) return;
    _container.read(latticeCameraProvider.notifier).zoomBy(
          1.25,
          focal: _paneCenter(),
        );
  }

  /// Zooms the camera out by 1/1.25x about the pane center (or
  /// [Offset.zero] before first layout publishes a pane size). No-op
  /// when locked or when `options.interactive` is false. Camera-only:
  /// never touches the document, never notifies.
  void zoomOut() {
    if (!gesturesEnabled) return;
    _container.read(latticeCameraProvider.notifier).zoomBy(
          1 / 1.25,
          focal: _paneCenter(),
        );
  }

  /// Frames the document content in the pane: computes the union of the
  /// document absolute rects (via [latticeAbsoluteRect] with an
  /// [Offset.zero] origin assumption — the same documented assumption as
  /// the minimap) and sets the camera viewport so the union fits the pane
  /// with [padding] logical px on each side, zoomed no higher than
  /// [maxZoom]. Empty document, unpublished pane size, fully padded-out
  /// pane, or non-finite result: silent no-op (no camera write, no
  /// notify). No-op when locked or when `options.interactive` is false.
  /// Camera-only: never touches the document, never notifies controller
  /// listeners.
  void fitView({double padding = 48, double maxZoom = 1.0}) {
    if (!gesturesEnabled) return;
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    if (nodes.isEmpty) return;
    final Size? pane = _container.read(latticePaneSizeProvider);
    if (pane == null) return;
    Rect? bounds;
    for (final String id in nodes.keys) {
      final Rect rect = latticeAbsoluteRect(
        nodes,
        id,
        defaultOrigin: Offset.zero,
      );
      bounds = bounds == null ? rect : bounds.expandToInclude(rect);
    }
    final Rect content = bounds!;
    final double contentWidth = content.width == 0 ? 1 : content.width;
    final double contentHeight = content.height == 0 ? 1 : content.height;
    final double availableWidth = pane.width - padding * 2;
    final double availableHeight = pane.height - padding * 2;
    if (availableWidth <= 0 || availableHeight <= 0) return;
    final double zoom = math.min(
      math.min(
        availableWidth / contentWidth,
        availableHeight / contentHeight,
      ),
      maxZoom,
    );
    if (zoom <= 0 || !zoom.isFinite) return;
    final Offset paneCenter = Offset(pane.width / 2, pane.height / 2);
    _container.read(latticeCameraProvider.notifier).setViewport(
          LatticeViewportValue(
            offset: paneCenter - content.center * zoom,
            zoom: zoom,
          ),
        );
  }

  /// Copies the live camera viewport into the document with one
  /// history-free `replace` + notify. No-op (no replace, no notify) when
  /// the document viewport already equals the camera viewport.
  /// `onViewportChange` fires once with the committed viewport.
  void saveViewport() {
    final LatticeViewportValue viewport =
        _container.read(latticeCameraProvider.notifier).viewport;
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    if (current.viewport == viewport) return;
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.copyWith(viewport: viewport));
    notifyListeners();
    _callbacks?.onViewportChange?.call(viewport);
  }

  /// Pane center in screen px, or [Offset.zero] before [LatticeCanvas]
  /// publishes its first layout size.
  Offset _paneCenter() {
    final Size? pane = _container.read(latticePaneSizeProvider);
    if (pane == null) return Offset.zero;
    return Offset(pane.width / 2, pane.height / 2);
  }

  /// Drops selected node/edge ids absent from [document] via
  /// [select] (which skips emission when nothing changes).
  void _coerceSelection(LatticeDocument document) {
    final LatticeSelection selection =
        _container.read(latticeSelectionProvider);
    if (selection.isEmpty) return;
    final Set<String> nodes = <String>{
      for (final String id in selection.nodes)
        if (document.nodes.containsKey(id)) id,
    };
    final Set<String> edges = <String>{
      for (final String id in selection.edges)
        if (document.edges.containsKey(id)) id,
    };
    select(nodes, edges);
  }

  /// Stores the selected nodes plus the edges fully inside the selection
  /// (both endpoints selected) into the clipboard. An empty selection
  /// clears the payload. Never touches history, never notifies.
  void copySelection() {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeSelection selection =
        _container.read(latticeSelectionProvider);
    if (selection.isEmpty) {
      _clipboard.store(nodes: const [], edges: const []);
      _clipboardAnchor = null;
      _clipboardEdgeCount = 0;
      return;
    }
    final List<LatticeNode> nodes = <LatticeNode>[
      for (final String id in selection.nodes)
        if (current.nodes[id] case final LatticeNode node) node,
    ];
    if (nodes.isEmpty) {
      _clipboard.store(nodes: const [], edges: const []);
      _clipboardAnchor = null;
      _clipboardEdgeCount = 0;
      return;
    }
    final Set<String> nodeIds = <String>{
      for (final LatticeNode node in nodes) node.id,
    };
    final List<LatticeEdge> edges = <LatticeEdge>[
      for (final LatticeEdge edge in current.edges.values)
        if (nodeIds.contains(edge.source.nodeId) &&
            nodeIds.contains(edge.target.nodeId))
          edge,
    ];
    _clipboard.store(nodes: nodes, edges: edges);
    var left = double.infinity;
    var top = double.infinity;
    for (final LatticeNode node in nodes) {
      if (node.position.dx < left) left = node.position.dx;
      if (node.position.dy < top) top = node.position.dy;
    }
    _clipboardAnchor = Offset(left, top);
    _clipboardEdgeCount = edges.length;
  }

  /// Pastes the clipboard payload with its anchor at [at] (delta =
  /// `at - payloadAnchor`) as ONE history entry, then selects the new
  /// nodes. No-op (no history, no notify) when the clipboard is empty.
  /// Notifies listeners exactly once.
  void paste({required Offset at}) {
    final Offset? anchor = _clipboardAnchor;
    if (!_clipboard.hasPayload || anchor == null) return;
    _pasteAt(at - anchor);
  }

  /// Copies the selection then pastes it at +40,+40 as ONE history entry.
  /// No-op (no history, no notify) on an empty selection.
  void duplicateSelection() {
    copySelection();
    final Offset? anchor = _clipboardAnchor;
    if (!_clipboard.hasPayload || anchor == null) return;
    _pasteAt(const Offset(40, 40));
  }

  /// Pastes the clipboard payload shifted by [delta]: one history push,
  /// one replace, one notification, then selects the new nodes. Fresh ids
  /// (`node_copy_<n>` / `edge_copy_<n>`) come from the monotonic counter,
  /// skipping ids already present in the target document.
  void _pasteAt(Offset delta) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final Set<String> taken = <String>{
      ...current.nodes.keys,
      ...current.edges.keys,
    };
    String freshNodeId() {
      while (true) {
        final String id = 'node_copy_${++_copyCounter}';
        if (taken.add(id)) return id;
      }
    }

    String freshEdgeId() {
      while (true) {
        final String id = 'edge_copy_${++_copyCounter}';
        if (taken.add(id)) return id;
      }
    }

    final int edgeCount = _clipboardEdgeCount;
    // The clipboard protocol takes the first set element as the node id
    // and pools leftovers for edges: mint the full edge pool on the first
    // call only, singletons thereafter, so a paste of N nodes + E edges
    // advances the counter by exactly N + E (no per-node burn).
    var firstFreshCall = true;
    final pasted = _clipboard.paste(
      delta: delta,
      freshIds: () {
        final Set<String> ids = <String>{freshNodeId()};
        if (firstFreshCall) {
          firstFreshCall = false;
          for (var i = 0; i < edgeCount; i++) {
            ids.add(freshEdgeId());
          }
        }
        return ids;
      },
    );
    final Map<String, LatticeNode> nodes =
        Map<String, LatticeNode>.of(current.nodes);
    for (final LatticeNode node in pasted.nodes) {
      nodes[node.id] = node;
    }
    final Map<String, LatticeEdge> edges =
        Map<String, LatticeEdge>.of(current.edges);
    for (final LatticeEdge edge in pasted.edges) {
      edges[edge.id] = edge;
    }
    final LatticeDocument next =
        current.copyWith(nodes: nodes, edges: edges);
    if (next == current) return;
    _history.push(current);
    _container.read(latticeDocumentProvider.notifier).replace(next);
    select(<String>{for (final LatticeNode node in pasted.nodes) node.id});
    notifyListeners();
  }

  /// Marks the controller as mounted. Canvas use only.
  @internal
  void attach() {
    if (_attached) return;
    _attached = true;
    notifyListeners();
  }

  /// Marks the controller as unmounted. Canvas use only.
  @internal
  void detach() {
    if (!_attached) return;
    _attached = false;
    notifyListeners();
  }

  /// Converts a screen-space point to flow coordinates via the inverse
  /// camera matrix. Canvas/router use only.
  @internal
  Offset screenToFlow(Offset screen) {
    final Matrix4 matrix = _container.read(latticeCameraProvider);
    if (matrix.determinant() == 0.0) return screen;
    return MatrixUtils.transformPoint(
      Matrix4.inverted(matrix),
      screen,
    );
  }

  /// Hit-tests [screenPosition]: the topmost node (highest `zIndex`,
  /// ties broken by smallest id) whose absolute rect contains the flow
  /// point, or `null` on empty space. Selects exactly the hit node;
  /// clears the selection otherwise (single emission; no-op when empty).
  /// Selection-only: never notifies controller listeners; goes through
  /// [select]/[deselectAll], so `onSelectionChange` fires on a real change.
  void tapAt(Offset screenPosition) {
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    _syncHitIndex(nodes);
    final String? hit = _hitNodeAt(nodes, screenToFlow(screenPosition));
    if (hit == null) {
      deselectAll();
    } else {
      select(<String>{hit});
    }
  }

  /// Starts a node drag for [id] with the live position at the current
  /// document flow position. Selects the node first when it is not
  /// selected (tap-then-drag in one gesture). Unknown ids are a no-op.
  /// Selection/drag state only: never notifies controller listeners.
  void beginNodeDrag(String id) {
    if (!gesturesEnabled) return;
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    _syncHitIndex(nodes);
    final LatticeNode? node = nodes[id];
    if (node == null) return;
    final LatticeSelection selection =
        _container.read(latticeSelectionProvider);
    if (!selection.nodes.contains(id)) {
      select(<String>{id});
    }
    _dragStartPositions = <String, Offset>{id: node.position};
    _dragAccumulated = Offset.zero;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.node(
            ids: <String>{id},
            livePositions: <String, Offset>{id: node.position},
          ),
        );
  }

  /// Advances the active node drag by [screenDelta], converted to a flow
  /// delta via the current zoom (`flowDelta = screenDelta / zoom`).
  /// Deltas accumulate onto the drag-start document positions stored by
  /// [beginNodeDrag]. No-op unless a node drag is active.
  void updateNodeDrag(Offset screenDelta) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    if (!drag.isActive || drag.ids.isEmpty) return;
    final Matrix4 matrix = _container.read(latticeCameraProvider);
    final double zoom =
        LatticeViewportValue.fromMatrix(matrix).zoom;
    final double scale = zoom == 0.0 ? 1.0 : zoom;
    _dragAccumulated += screenDelta / scale;
    final Map<String, Offset> live = <String, Offset>{
      for (final String id in drag.ids)
        id: (_dragStartPositions[id] ??
                drag.livePositions[id] ??
                _container
                    .read(latticeDocumentProvider)
                    .nodes[id]
                    ?.position ??
                Offset.zero) +
            _dragAccumulated,
    };
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.node(
            ids: drag.ids,
            livePositions: live,
            liveSizes: drag.liveSizes,
          ),
        );
  }

  /// Commits the active node drag to the document via `replace` (one
  /// notification) and resets the drag to idle. Skips the commit — and
  /// the notification — when nothing moved. No-op unless a node drag
  /// is active.
  void endNodeDrag() {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    if (!drag.isActive || drag.ids.isEmpty) return;
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    bool moved = false;
    final Map<String, LatticeNode> next = Map<String, LatticeNode>.of(nodes);
    for (final String id in drag.ids) {
      final Offset? live = drag.livePositions[id];
      final LatticeNode? current = next[id];
      if (live == null || current == null) continue;
      if (live != current.position) {
        moved = true;
        next[id] = current.copyWith(position: live);
      }
    }
    _dragStartPositions = const <String, Offset>{};
    _dragAccumulated = Offset.zero;
    if (moved) {
      final LatticeDocument current =
          _container.read(latticeDocumentProvider);
      _history.coalescePush(current);
      _container
          .read(latticeDocumentProvider.notifier)
          .replace(current.copyWith(nodes: next));
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      notifyListeners();
    } else {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
    }
  }

  /// Starts a resize session for node [id] via [handle], recording the
  /// drag-start document size/position and seeding the drag state with
  /// both the live position and the live size. Requires the node to
  /// exist and be resizable (`resizable ?? false` — default off);
  /// otherwise a silent no-op (no drag state, no history, no notify).
  /// Session-only: never notifies controller listeners.
  void beginResize(String id, LatticeResizeHandle handle) {
    if (!gesturesEnabled) return;
    final LatticeNode? node =
        _container.read(latticeDocumentProvider).nodes[id];
    if (node == null || node.resizable != true) return;
    _resizeNodeId = id;
    _resizeHandle = handle;
    _resizeStartSize = node.size;
    _resizeStartPosition = node.position;
    _resizeAccumulated = Offset.zero;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.node(
            ids: <String>{id},
            livePositions: <String, Offset>{id: node.position},
            liveSizes: <String, Size>{id: node.size},
          ),
        );
  }

  /// Advances the active resize session by [screenDelta], converted to a
  /// flow delta via the current zoom (`flowDelta = screenDelta / zoom`).
  /// The new size is the drag-start size plus the signed accumulated
  /// delta per handle direction (right/bottom grow with +, left/top grow
  /// with − and shift the position so the opposite edge stays fixed),
  /// clamped to `minSize` / `maxSize` / the canvas max; `keepAspectRatio`
  /// locks the drag-start ratio, scaling by the dominant axis. Position
  /// shifts only for left/top handles. Writes go to the drag session
  /// (live) only: zero document emissions, zero history, no notify.
  /// No-op unless a resize session is active.
  void updateResize(Offset screenDelta) {
    final String? id = _resizeNodeId;
    final LatticeResizeHandle? handle = _resizeHandle;
    final Size? startSize = _resizeStartSize;
    final Offset? startPosition = _resizeStartPosition;
    if (id == null ||
        handle == null ||
        startSize == null ||
        startPosition == null) {
      return;
    }
    final LatticeDragState drag = _container.read(latticeDragProvider);
    if (!drag.isActive || !drag.ids.contains(id)) return;
    final LatticeNode? node =
        _container.read(latticeDocumentProvider).nodes[id];
    if (node == null) return;
    final Matrix4 matrix = _container.read(latticeCameraProvider);
    final double zoom = LatticeViewportValue.fromMatrix(matrix).zoom;
    final double scale = zoom == 0.0 ? 1.0 : zoom;
    _resizeAccumulated += screenDelta / scale;
    final double dx = _resizeAccumulated.dx;
    final double dy = _resizeAccumulated.dy;
    double deltaWidth = 0;
    double deltaHeight = 0;
    var west = false;
    var north = false;
    switch (handle) {
      case LatticeResizeHandle.topLeft:
        deltaWidth = -dx;
        deltaHeight = -dy;
        west = true;
        north = true;
      case LatticeResizeHandle.top:
        deltaHeight = -dy;
        north = true;
      case LatticeResizeHandle.topRight:
        deltaWidth = dx;
        deltaHeight = -dy;
        north = true;
      case LatticeResizeHandle.right:
        deltaWidth = dx;
      case LatticeResizeHandle.bottomRight:
        deltaWidth = dx;
        deltaHeight = dy;
      case LatticeResizeHandle.bottom:
        deltaHeight = dy;
      case LatticeResizeHandle.bottomLeft:
        deltaWidth = -dx;
        deltaHeight = dy;
        west = true;
      case LatticeResizeHandle.left:
        deltaWidth = -dx;
        west = true;
    }
    double width = startSize.width + deltaWidth;
    double height = startSize.height + deltaHeight;
    if (node.keepAspectRatio &&
        startSize.width > 0 &&
        startSize.height > 0) {
      final double ratio = startSize.width / startSize.height;
      if (deltaWidth.abs() >= deltaHeight.abs()) {
        height = width / ratio;
      } else {
        width = height * ratio;
      }
    }
    // Floors/ceilings come from LatticeOptions: per-node minSize/maxSize
    // win, with the options bounds as the canvas-wide fallback.
    final Size minFallback =
        Size(_options.resizeMinSize, _options.resizeMinSize);
    final Size canvasMax =
        Size(_options.resizeMaxSize, _options.resizeMaxSize);
    final Size minSize = node.minSize ?? minFallback;
    final double maxWidth = math.min(
      node.maxSize?.width ?? canvasMax.width,
      canvasMax.width,
    );
    final double maxHeight = math.min(
      node.maxSize?.height ?? canvasMax.height,
      canvasMax.height,
    );
    width = width.clamp(
      minSize.width,
      math.max(maxWidth, minSize.width),
    );
    height = height.clamp(
      minSize.height,
      math.max(maxHeight, minSize.height),
    );
    var left = startPosition.dx;
    var top = startPosition.dy;
    if (west) left += startSize.width - width;
    if (north) top += startSize.height - height;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.node(
            ids: <String>{id},
            livePositions: <String, Offset>{id: Offset(left, top)},
            liveSizes: <String, Size>{id: Size(width, height)},
          ),
        );
  }

  /// Commits the active resize session to the document (size, plus the
  /// shifted position for left/top handles) via one history `push`, one
  /// `replace`, one notification, then resets the drag to idle. A
  /// session with no effective change is silent: no history, no notify
  /// (still resets the drag). No-op unless a resize session started via
  /// [beginResize]; never steals a plain node-drag session.
  void endResize() {
    final String? id = _resizeNodeId;
    _resizeNodeId = null;
    _resizeHandle = null;
    _resizeStartSize = null;
    _resizeStartPosition = null;
    _resizeAccumulated = Offset.zero;
    if (id == null) return;
    final LatticeDragState drag = _container.read(latticeDragProvider);
    if (!drag.isActive || !drag.ids.contains(id)) return;
    final Size? liveSize = drag.liveSizes[id];
    if (liveSize == null) return;
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    final LatticeNode? current = nodes[id];
    if (current == null) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final Offset livePosition = drag.livePositions[id] ?? current.position;
    if (liveSize == current.size && livePosition == current.position) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeDocument document =
        _container.read(latticeDocumentProvider);
    _history.push(document);
    final Map<String, LatticeNode> next = Map<String, LatticeNode>.of(nodes);
    next[id] = current.copyWith(position: livePosition, size: liveSize);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(document.copyWith(nodes: next));
    _container.read(latticeDragProvider.notifier).set(
          const LatticeDragState.idle(),
        );
    notifyListeners();
  }

  /// Starts a connect session from [from], seeding `liveEnd` at the
  /// handle's flow center ([_handleFlowCenter]). Session-only: no
  /// document replace, no history, no controller notification.
  void beginConnect(LatticeEndpoint from) {
    if (!gesturesEnabled) return;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.connect(
            from: from,
            liveEnd: _handleFlowCenter(from),
          ),
        );
  }

  /// Advances the active connect session's `liveEnd` to [screenEnd]
  /// converted to flow coordinates. Session-only (no document, no
  /// history, no notification). No-op unless a connect is active.
  void updateConnect(Offset screenEnd) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    final LatticeEndpoint? from = drag.from;
    if (!drag.isActive || from == null || drag.liveEnd == null) return;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.connect(
            from: from,
            liveEnd: screenToFlow(screenEnd),
            reconnectEdgeId: drag.reconnectEdgeId,
          ),
        );
  }

  /// Ends the active connect session. A `null` target (or an inactive /
  /// non-connect session) cancels silently: no history, no notify.
  /// Otherwise validates via [latticeValidateConnection] (defaults: no
  /// self-connections, no duplicates) — invalid cancels silently; valid
  /// mints `edge_<n>` via [addEdge] (one history entry, one `onEdgesAdded`)
  /// then resets the drag to idle and fires `onConnect` with the created
  /// edge.
  void endConnect(LatticeEndpoint? target) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    final LatticeEndpoint? from = drag.from;
    if (!drag.isActive || from == null || drag.liveEnd == null) return;
    if (target == null) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    if (!latticeValidateConnection(
      source: from,
      target: target,
      doc: current,
    )) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeEdge edge = LatticeEdge(
      id: _freshEdgeId(current),
      source: from,
      target: target,
    );
    addEdge(edge);
    _container.read(latticeDragProvider.notifier).set(
          const LatticeDragState.idle(),
        );
    _callbacks?.onConnect?.call(edge);
  }

  /// Starts a reconnect session for edge [edgeId]: the end flagged by
  /// [sourceEnd] is the moving end; `from` is the NON-moving end and
  /// `liveEnd` seeds at the moving end's handle flow center
  /// ([_handleFlowCenter]). Unknown ids are a no-op: no drag state, no
  /// history, no notification. Session-only: never notifies controller
  /// listeners.
  void beginReconnect(String edgeId, {required bool sourceEnd}) {
    if (!gesturesEnabled) return;
    final LatticeEdge? edge = _container
        .read(latticeDocumentProvider)
        .edges[edgeId];
    if (edge == null) return;
    final LatticeEndpoint fixed = sourceEnd ? edge.target : edge.source;
    final LatticeEndpoint moving = sourceEnd ? edge.source : edge.target;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.connect(
            from: fixed,
            liveEnd: _handleFlowCenter(moving),
            reconnectEdgeId: edgeId,
          ),
        );
  }

  /// Advances the active reconnect session's `liveEnd` to [screenEnd]
  /// converted to flow coordinates. Same as [updateConnect]. Session-only
  /// (no document, no history, no notification). No-op unless a connect
  /// is active.
  void updateReconnect(Offset screenEnd) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    final LatticeEndpoint? from = drag.from;
    if (!drag.isActive || from == null || drag.liveEnd == null) return;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.connect(
            from: from,
            liveEnd: screenToFlow(screenEnd),
            reconnectEdgeId: drag.reconnectEdgeId,
          ),
        );
  }

  /// Ends the active reconnect session. A `null` target (or an inactive /
  /// non-connect session, a non-reconnect session, or a session whose
  /// edge vanished) cancels silently: no history, no notify (a null
  /// target still resets the drag to idle; a non-reconnect session is
  /// left untouched). Otherwise the moving end — the end opposite `from`
  /// — is replaced by [target] and the NEW edge's (source, target)
  /// validates via [latticeValidateConnection] (defaults): invalid
  /// cancels silently, and a target equal to the old moving end
  /// (same-as-old) cancels with no history entry. A valid change commits
  /// as ONE undoable unit (one history push, one replace, one
  /// notification) then resets the drag to idle.
  void endReconnect(LatticeEndpoint? target) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    final LatticeEndpoint? from = drag.from;
    final String? edgeId = drag.reconnectEdgeId;
    if (!drag.isActive || from == null || drag.liveEnd == null) return;
    if (edgeId == null) return;
    if (target == null) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeEdge? old = current.edges[edgeId];
    if (old == null) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final bool targetMoving;
    if (from == old.source && from != old.target) {
      targetMoving = true;
    } else if (from == old.target && from != old.source) {
      targetMoving = false;
    } else if (from == old.source && from == old.target) {
      // Self-loop edge: `from` matches both ends; keep the
      // from-as-source convention and move the target end.
      targetMoving = true;
    } else {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeEndpoint oldMoving = targetMoving ? old.target : old.source;
    if (target == oldMoving) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeEdge nextEdge = targetMoving
        ? old.copyWith(target: target)
        : old.copyWith(source: target);
    if (!latticeValidateConnection(
      source: nextEdge.source,
      target: nextEdge.target,
      doc: current,
    )) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    final LatticeDocument next = current.copyWith(
      edges: <String, LatticeEdge>{...current.edges, nextEdge.id: nextEdge},
    );
    if (next == current) {
      _container.read(latticeDragProvider.notifier).set(
            const LatticeDragState.idle(),
          );
      return;
    }
    _history.push(current);
    _container.read(latticeDocumentProvider.notifier).replace(next);
    _container.read(latticeDragProvider.notifier).set(
          const LatticeDragState.idle(),
        );
    notifyListeners();
  }

  /// Flow-space center of [endpoint]'s handle: node absolute top-left +
  /// handle rect center. A null `handleId` (default port) resolves to the
  /// first source-type handle's center, else the node rect center.
  Offset _handleFlowCenter(LatticeEndpoint endpoint) {
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    final LatticeNode? node = nodes[endpoint.nodeId];
    if (node == null) return Offset.zero;
    final Offset topLeft = latticeAbsoluteTopLeft(
      nodes,
      endpoint.nodeId,
      defaultOrigin: Offset.zero,
    );
    LatticeHandle? handle = endpoint.handleId == null
        ? null
        : node.resolveHandles()[endpoint.handleId];
    handle ??= _firstSourceHandle(node);
    if (handle == null) {
      return latticeAbsoluteRect(
        nodes,
        endpoint.nodeId,
        defaultOrigin: Offset.zero,
      ).center;
    }
    final LatticeHandle resolved = handle;
    return topLeft +
        resolved.position +
        Offset(
          resolved.size.width / 2,
          resolved.size.height / 2,
        );
  }

  /// First source-type handle in [node]'s resolved handles, or null.
  LatticeHandle? _firstSourceHandle(LatticeNode node) {
    for (final LatticeHandle handle in node.resolveHandles().values) {
      if (handle.type == LatticeHandleType.source) return handle;
    }
    return null;
  }

  /// Next `edge_<n>` id absent from [doc]. Skips ids already present so
  /// a loaded document can never be overwritten by a minted edge.
  String _freshEdgeId(LatticeDocument doc) {
    while (true) {
      final String id = 'edge_${++_edgeCounter}';
      if (!doc.edges.containsKey(id) && !doc.nodes.containsKey(id)) {
        return id;
      }
    }
  }

  /// Starts a marquee at [screenPosition], anchoring the selection rect
  /// in flow coordinates.
  void beginMarquee(Offset screenPosition) {
    if (!gesturesEnabled) return;
    _marqueeAnchor = screenToFlow(screenPosition);
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.marquee(
            rect: Rect.fromPoints(_marqueeAnchor!, _marqueeAnchor!),
          ),
        );
  }

  /// Grows the active marquee to [screenPosition] (normalized rect).
  /// No-op unless a marquee is active.
  void updateMarquee(Offset screenPosition) {
    final Offset? anchor = _marqueeAnchor;
    if (anchor == null) return;
    final LatticeDragState drag = _container.read(latticeDragProvider);
    if (!drag.isActive || drag.rect == null) return;
    _container.read(latticeDragProvider.notifier).set(
          LatticeDragState.marquee(
            rect: Rect.fromPoints(anchor, screenToFlow(screenPosition)),
          ),
        );
  }

  /// Selects the nodes whose absolute rects overlap the marquee rect
  /// (via the index query — no per-candidate map copies) and resets the
  /// drag to idle. `append: true` unions with the existing selection.
  /// Selection-only: never notifies controller listeners.
  void endMarquee({bool append = false}) {
    final LatticeDragState drag = _container.read(latticeDragProvider);
    _marqueeAnchor = null;
    if (!drag.isActive || drag.rect == null) return;
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    _syncHitIndex(nodes);
    final Set<String> hits = _hitIndex.queryNodes(drag.rect!);
    final Set<String> next = append
        ? <String>{
            ..._container.read(latticeSelectionProvider).nodes,
            ...hits,
          }
        : hits;
    select(next);
    _container.read(latticeDragProvider.notifier).set(
          const LatticeDragState.idle(),
        );
  }

  /// Index probe + [latticeAbsoluteRect] refine. Returns the topmost hit
  /// (highest `zIndex`, ties broken by smallest id), or `null`.
  String? _hitNodeAt(Map<String, LatticeNode> nodes, Offset flow) {
    final Rect probe = Rect.fromCenter(center: flow, width: 1, height: 1);
    final Set<String> candidates = _hitIndex.queryNodes(probe);
    String? best;
    int bestZ = 0;
    bool found = false;
    for (final String id in candidates) {
      final LatticeNode? node = nodes[id];
      if (node == null) continue;
      if (!latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero)
          .contains(flow)) {
        continue;
      }
      if (!found || node.zIndex > bestZ || (node.zIndex == bestZ && id.compareTo(best!) < 0)) {
        best = id;
        bestZ = node.zIndex;
        found = true;
      }
    }
    return best;
  }

  void _syncHitIndex(Map<String, LatticeNode> nodes) {
    if (identical(nodes, _lastHitSynced)) return;
    if (nodes.length != _hitSnapshot.length ||
        !_hitSnapshotContainsAll(nodes)) {
      _hitIndex.rebuild(nodes, defaultOrigin: Offset.zero);
      _hitSnapshot = Map<String, LatticeNode>.of(nodes);
    } else {
      nodes.forEach((String id, LatticeNode node) {
        final LatticeNode? before = _hitSnapshot[id];
        if (before != null && before != node) {
          _hitIndex.moveNode(before, node);
          _hitSnapshot[id] = node;
        }
      });
    }
    _lastHitSynced = nodes;
  }

  bool _hitSnapshotContainsAll(Map<String, LatticeNode> nodes) {
    for (final String id in nodes.keys) {
      if (!_hitSnapshot.containsKey(id)) return false;
    }
    return true;
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _container.dispose();
    super.dispose();
  }
}
