import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Mutable hot-path buffer for node drag (and similar gestures).
///
/// During drag, positions live here so Freezed [FlowCanvasState] is not
/// replaced every pointer sample. Painters/widgets listen to [liveStamp]
/// via [Listenable] notifications (frame-coalesced).
class InteractionSession extends ChangeNotifier {
  final Set<String> draggingNodeIds = {};
  final Set<String> activeEdgeIds = {};

  /// Live **stored** positions for dragged nodes, expandParent-grown parents,
  /// and shifted siblings (Lattice `handleExpandParent` keeps siblings in place).
  final Map<String, Offset> livePositions = {};

  /// Live sizes for nodes whose dimensions change mid-drag (expandParent
  /// parents grow while the child is dragged past their edge).
  final Map<String, Size> liveSizes = {};

  /// Bumped when live positions change; active edge/node layers watch this.
  int liveStamp = 0;

  bool get isActive => draggingNodeIds.isNotEmpty;

  bool isDragging(String nodeId) => draggingNodeIds.contains(nodeId);

  Offset? livePosition(String nodeId) => livePositions[nodeId];

  /// Nodes whose visuals can change during the active drag: dragged roots,
  /// their descendants (absolute position reads ancestor live data), plus any
  /// id present in [livePositions]/[liveSizes] (expandParent parents, shifted
  /// siblings). Fixed at [beginDrag] + live keys — the tree cannot restructure
  /// mid-drag, and live-only parent resizes with static children have no call
  /// path today.
  Set<String> _dragAffected = const {};

  /// Per-node scope stamps, bumped only for affected ids (see [_dragAffected]).
  /// Cleared on [endDrag], so entries never outlive a gesture.
  final Map<String, int> _nodeStamps = {};

  /// Last stamp seen for [nodeId] (0 when untouched this gesture).
  int scopeStamp(String nodeId) => _nodeStamps[nodeId] ?? 0;

  /// A [Listenable] that fires only while [nodeId]'s scope stamp changes.
  /// Single-node widgets (node shells) subscribe here instead of the whole
  /// session, so static nodes skip gesture ticks entirely — no builder runs,
  /// no element updates. Global listeners (edge layers, minimap, toolbars)
  /// keep watching the session itself.
  Listenable scopeFor(String nodeId) => _NodeScopeListenable(this, nodeId);

  bool _frameScheduled = false;

  void beginDrag({
    required Set<String> nodeIds,
    required Map<String, Offset> startPositions,
    required Set<String> edgeIds,
    Set<String> affectedNodeIds = const {},
  }) {
    draggingNodeIds
      ..clear()
      ..addAll(nodeIds);
    livePositions
      ..clear()
      ..addAll(startPositions);
    liveSizes.clear();
    activeEdgeIds
      ..clear()
      ..addAll(edgeIds);
    _dragAffected = affectedNodeIds;
    liveStamp++;
    _bumpScopes();
    notifyListeners();
  }

  /// Accumulates [delta] onto all dragging nodes; notifies at most once per frame.
  void updateDragBy(Offset delta) {
    if (!isActive || delta == Offset.zero) return;
    for (final id in draggingNodeIds) {
      final current = livePositions[id];
      if (current != null) {
        livePositions[id] = current + delta;
      }
    }
    liveStamp++;
    _scheduleNotify();
  }

  /// Sets live positions (dragged nodes, expandParent parents, shifted
  /// siblings). Notifies at most once per frame.
  void setLivePositions(Map<String, Offset> positions) {
    if (!isActive) return;
    var changed = false;
    for (final e in positions.entries) {
      if (livePositions[e.key] != e.value) {
        livePositions[e.key] = e.value;
        changed = true;
      }
    }
    if (!changed) return;
    liveStamp++;
    _scheduleNotify();
  }

  /// Sets a live size (expandParent parent growth during child drag).
  void setLiveSize(String nodeId, Size size) {
    if (!isActive) return;
    if (liveSizes[nodeId] == size) return;
    liveSizes[nodeId] = size;
    liveStamp++;
    _scheduleNotify();
  }

  void endDrag() {
    draggingNodeIds.clear();
    activeEdgeIds.clear();
    livePositions.clear();
    liveSizes.clear();
    _dragAffected = const {};
    _nodeStamps.clear();
    liveStamp++;
    _frameScheduled = false;
    // No scope bump: cleared stamps read as 0, which differs from any
    // gesture stamp, so every scope fires exactly once and resyncs to
    // committed state below.
    notifyListeners();
  }

  /// Bumps scope stamps for ids whose visuals may have changed. Called on
  /// every notification path (begin + each coalesced frame tick).
  void _bumpScopes() {
    if (_dragAffected.isEmpty &&
        livePositions.isEmpty &&
        liveSizes.isEmpty) {
      return;
    }
    final stamp = liveStamp;
    for (final id in _dragAffected) {
      _nodeStamps[id] = stamp;
    }
    for (final id in livePositions.keys) {
      _nodeStamps[id] = stamp;
    }
    for (final id in liveSizes.keys) {
      _nodeStamps[id] = stamp;
    }
  }

  void _scheduleNotify() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameScheduled = false;
      _bumpScopes();
      notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }
}

/// Per-node filtered view of an [InteractionSession] (see [InteractionSession.scopeFor]).
class _NodeScopeListenable extends Listenable {
  _NodeScopeListenable(this._session, this._nodeId);

  final InteractionSession _session;
  final String _nodeId;
  final Map<VoidCallback, VoidCallback> _wrappers = {};

  @override
  void addListener(VoidCallback listener) {
    var seen = _session.scopeStamp(_nodeId);
    late final VoidCallback wrapper;
    wrapper = () {
      final stamp = _session.scopeStamp(_nodeId);
      if (stamp == seen) return;
      seen = stamp;
      listener();
    };
    _wrappers[listener] = wrapper;
    _session.addListener(wrapper);
  }

  @override
  void removeListener(VoidCallback listener) {
    final wrapper = _wrappers.remove(listener);
    if (wrapper != null) _session.removeListener(wrapper);
  }
}
