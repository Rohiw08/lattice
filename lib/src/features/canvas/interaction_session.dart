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

  bool _frameScheduled = false;

  void beginDrag({
    required Set<String> nodeIds,
    required Map<String, Offset> startPositions,
    required Set<String> edgeIds,
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
    liveStamp++;
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
    liveStamp++;
    _frameScheduled = false;
    notifyListeners();
  }

  void _scheduleNotify() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameScheduled = false;
      notifyListeners();
    });
    SchedulerBinding.instance.scheduleFrame();
  }
}
