import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_clipboard.dart';
import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_history.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'lattice_options.dart';
import 'lattice_selection.dart';
import 'lattice_spatial_index.dart';
import 'lattice_viewport_value.dart';
import 'session_providers.dart';

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
  /// Notifies listeners exactly once.
  void load(LatticeDocument document) {
    _container.read(latticeDocumentProvider.notifier).replace(document);
    _container.read(latticeSelectionProvider.notifier).clear();
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

  /// Removes nodes [ids] (edges untouched; cascade is Task 4).
  /// Notifies listeners exactly once. No-op (no push, no replace, no
  /// notify) when nothing is removed.
  void removeNodes(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withoutNodes(ids);
    if (next == current) return;
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
  }

  /// Removes edges [ids]. Notifies listeners exactly once. No-op (no
  /// push, no replace, no notify) when nothing is removed.
  void removeEdges(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    final LatticeDocument next = current.withoutEdges(ids);
    if (next == current) return;
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(next);
    notifyListeners();
  }

  /// Sets the session selection. Selection-only: never notifies
  /// controller listeners.
  void select(Set<String> nodeIds, [Set<String> edgeIds = const {}]) {
    _container.read(latticeSelectionProvider.notifier).setSelection(
          LatticeSelection(
            nodes: Set<String>.of(nodeIds),
            edges: Set<String>.of(edgeIds),
          ),
        );
  }

  /// Clears the session selection. Never notifies controller listeners.
  void deselectAll() {
    _container.read(latticeSelectionProvider.notifier).clear();
  }

  /// Selects all node + edge ids in the document. Never notifies
  /// controller listeners.
  void selectAll() {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _container.read(latticeSelectionProvider.notifier).setSelection(
          LatticeSelection(
            nodes: Set<String>.of(current.nodes.keys),
            edges: Set<String>.of(current.edges.keys),
          ),
        );
  }

  /// Returns the current document (same instance, no copy).
  LatticeDocument save() {
    return _container.read(latticeDocumentProvider);
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
  /// Selection-only: never notifies controller listeners.
  void tapAt(Offset screenPosition) {
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    _syncHitIndex(nodes);
    final String? hit = _hitNodeAt(nodes, screenToFlow(screenPosition));
    if (hit == null) {
      _container.read(latticeSelectionProvider.notifier).clear();
    } else {
      _container
          .read(latticeSelectionProvider.notifier)
          .setSelection(LatticeSelection(nodes: <String>{hit}));
    }
  }

  /// Starts a node drag for [id] with the live position at the current
  /// document flow position. Selects the node first when it is not
  /// selected (tap-then-drag in one gesture). Unknown ids are a no-op.
  /// Selection/drag state only: never notifies controller listeners.
  void beginNodeDrag(String id) {
    final Map<String, LatticeNode> nodes =
        _container.read(latticeDocumentProvider).nodes;
    _syncHitIndex(nodes);
    final LatticeNode? node = nodes[id];
    if (node == null) return;
    final LatticeSelection selection =
        _container.read(latticeSelectionProvider);
    if (!selection.nodes.contains(id)) {
      _container
          .read(latticeSelectionProvider.notifier)
          .setSelection(LatticeSelection(nodes: <String>{id}));
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
          LatticeDragState.node(ids: drag.ids, livePositions: live),
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

  /// Starts a marquee at [screenPosition], anchoring the selection rect
  /// in flow coordinates.
  void beginMarquee(Offset screenPosition) {
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
    _container
        .read(latticeSelectionProvider.notifier)
        .setSelection(LatticeSelection(nodes: next));
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
