import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Dev-only metrics and DevTools timeline helpers for the canvas.
///
/// All flags and counters are **process-global**: multiple canvases on one
/// page share them. That is deliberate — this is a debugging aid, not
/// per-canvas telemetry. Everything here is a no-op outside debug builds
/// (call sites additionally gate on `kDebugMode` so release trees shake the
/// calls out entirely).
class FlowCanvasDebug {
  /// When true, logs node layer mounts and gesture/drag pipeline.
  static bool logInteraction = false;

  /// When true, spatial features may log to the console (opt-in per call site).
  static bool logSpatialQueries = false;

  /// When true, subsystems may log edge paint timing (opt-in per call site).
  static bool logEdgePaint = false;

  /// When true, logs coarse perf counters (pan/drag/cull/paint).
  static bool logPerf = false;

  static int _edgePaintCount = 0;
  static int _nodesBuilt = 0;
  static int _panCommits = 0;
  static int _dragCommits = 0;
  static int _nodeLayerPasses = 0;
  static int _nodeSorts = 0;
  static int _geoComputes = 0;
  static int _edgeCullPasses = 0;
  static int _edgeMapCopies = 0;
  static int _bodyBuilds = 0;

  /// Painted edge paths since the last [resetCounters].
  static int get edgePaintCount => _edgePaintCount;

  /// Node widgets built since the last [resetCounters].
  static int get nodesBuilt => _nodesBuilt;

  /// Committed viewport pans since the last [resetCounters].
  static int get panCommits => _panCommits;

  /// Committed node drags since the last [resetCounters].
  static int get dragCommits => _dragCommits;

  /// Node-layer filter+sort passes since the last [resetCounters].
  static int get nodeLayerPasses => _nodeLayerPasses;

  /// Node z-sort executions since the last [resetCounters].
  static int get nodeSorts => _nodeSorts;

  /// Edge geometry computations since the last [resetCounters].
  static int get geoComputes => _geoComputes;

  /// Edge-layer cull evaluations since the last [resetCounters].
  static int get edgeCullPasses => _edgeCullPasses;

  /// Edge map-copy constructions since the last [resetCounters].
  static int get edgeMapCopies => _edgeMapCopies;

  /// Node body builds since the last [resetCounters].
  static int get bodyBuilds => _bodyBuilds;

  /// Zeros all counters. Call before the interaction you want to measure
  /// (tests use this plus [snapshot] to assert commit counts).
  static void resetCounters() {
    _edgePaintCount = 0;
    _nodesBuilt = 0;
    _panCommits = 0;
    _dragCommits = 0;
    _nodeLayerPasses = 0;
    _nodeSorts = 0;
    _geoComputes = 0;
    _edgeCullPasses = 0;
    _edgeMapCopies = 0;
    _bodyBuilds = 0;
  }

  /// Current counter values as a record (for assertions and log lines).
  static ({int edgePaints, int nodesBuilt, int panCommits, int dragCommits})
      snapshot() => (
            edgePaints: _edgePaintCount,
            nodesBuilt: _nodesBuilt,
            panCommits: _panCommits,
            dragCommits: _dragCommits,
          );

  /// Adds [n] to [edgePaintCount]. No-op outside debug builds.
  static void countEdgePaint([int n = 1]) {
    if (!kDebugMode) return;
    _edgePaintCount += n;
  }

  /// Adds [n] to [nodesBuilt]. No-op outside debug builds.
  static void countNodesBuilt([int n = 1]) {
    if (!kDebugMode) return;
    _nodesBuilt += n;
  }

  /// Adds one to [panCommits]. No-op outside debug builds.
  static void countPanCommit() {
    if (!kDebugMode) return;
    _panCommits++;
  }

  /// Adds one to [dragCommits]. No-op outside debug builds.
  static void countDragCommit() {
    if (!kDebugMode) return;
    _dragCommits++;
  }

  /// Adds one to [nodeLayerPasses]. No-op outside debug builds.
  static void countNodeLayerPass() {
    if (!kDebugMode) return;
    _nodeLayerPasses++;
  }

  /// Adds one to [nodeSorts]. No-op outside debug builds.
  static void countNodeSort() {
    if (!kDebugMode) return;
    _nodeSorts++;
  }

  /// Adds one to [geoComputes]. No-op outside debug builds.
  static void countGeoCompute() {
    if (!kDebugMode) return;
    _geoComputes++;
  }

  /// Adds one to [edgeCullPasses]. No-op outside debug builds.
  static void countEdgeCullPass() {
    if (!kDebugMode) return;
    _edgeCullPasses++;
  }

  /// Adds one to [edgeMapCopies]. No-op outside debug builds.
  static void countEdgeMapCopy() {
    if (!kDebugMode) return;
    _edgeMapCopies++;
  }

  /// Adds one to [bodyBuilds]. No-op outside debug builds.
  static void countBodyBuild() {
    if (!kDebugMode) return;
    _bodyBuilds++;
  }

  static void _log(String name, String message, [Object? detail]) {
    if (!kDebugMode) return;
    final line = detail != null ? '$message | $detail' : message;
    dev.log(line, name: name);
    debugPrint('[$name] $line');
  }

  /// Logs an interaction/gesture line (DevTools + `flutter run` stdout).
  ///
  /// Honored only when [logInteraction] is enabled.
  static void interaction(String message, [Object? detail]) {
    if (!logInteraction) return;
    _log('FlowCanvas.Interaction', message, detail);
  }

  /// Logs a spatial-index line. Gives the orphan [logSpatialQueries] flag a
  /// working method, matching [interaction]/[perf].
  static void spatial(String message, [Object? detail]) {
    if (!logSpatialQueries) return;
    _log('FlowCanvas.Spatial', message, detail);
  }

  /// Logs an edge-paint line. Gives the [logEdgePaint] flag a working
  /// method; counting stays on [countEdgePaint].
  static void edgePaint(String message, [Object? detail]) {
    if (!logEdgePaint) return;
    _log('FlowCanvas.EdgePaint', message, detail);
  }

  /// Logs a performance line when [logPerf] is enabled.
  static void perf(String message, [Object? detail]) {
    if (!logPerf) return;
    _log('FlowCanvas.Perf', message, detail);
  }

  /// Wraps [fn] in a DevTools timeline event (no-op in release or outside debug).
  static T traceSync<T>(String name, T Function() fn) {
    if (!kDebugMode) {
      return fn();
    }
    dev.Timeline.startSync(name);
    try {
      return fn();
    } finally {
      dev.Timeline.finishSync();
    }
  }
}
