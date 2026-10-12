import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
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
  /// Notifies listeners exactly once.
  void setNodes(Iterable<LatticeNode> nodes) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
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
  /// Notifies listeners exactly once.
  void setEdges(Iterable<LatticeEdge> edges) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
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
  /// Notifies listeners exactly once.
  void addNode(LatticeNode n) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.withNode(n));
    notifyListeners();
  }

  /// Inserts (or overwrites, on duplicate id) edge [e].
  /// Notifies listeners exactly once.
  void addEdge(LatticeEdge e) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.withEdge(e));
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
  /// Notifies listeners exactly once.
  void removeNodes(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.withoutNodes(ids));
    notifyListeners();
  }

  /// Removes edges [ids]. Notifies listeners exactly once.
  void removeEdges(Set<String> ids) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _history.push(current);
    _container
        .read(latticeDocumentProvider.notifier)
        .replace(current.withoutEdges(ids));
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
  /// document and notifies exactly once. No-op (no replace, no notify)
  /// when the undo stack is empty.
  void undo() {
    final LatticeDocument? previous =
        _history.undo(_container.read(latticeDocumentProvider));
    if (previous == null) return;
    _container.read(latticeDocumentProvider.notifier).replace(previous);
    notifyListeners();
  }

  /// Reapplies the document undone by [undo]. Replaces the document
  /// and notifies exactly once. No-op (no replace, no notify) when the
  /// redo stack is empty.
  void redo() {
    final LatticeDocument? next =
        _history.redo(_container.read(latticeDocumentProvider));
    if (next == null) return;
    _container.read(latticeDocumentProvider.notifier).replace(next);
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
