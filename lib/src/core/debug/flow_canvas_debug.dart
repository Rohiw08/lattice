import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';

/// Dev-only metrics and DevTools timeline helpers for the canvas.
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

  static int get edgePaintCount => _edgePaintCount;
  static int get nodesBuilt => _nodesBuilt;
  static int get panCommits => _panCommits;
  static int get dragCommits => _dragCommits;

  static void resetCounters() {
    _edgePaintCount = 0;
    _nodesBuilt = 0;
    _panCommits = 0;
    _dragCommits = 0;
  }

  static void countEdgePaint([int n = 1]) => _edgePaintCount += n;
  static void countNodesBuilt([int n = 1]) => _nodesBuilt += n;
  static void countPanCommit() => _panCommits++;
  static void countDragCommit() => _dragCommits++;

  /// Logs an interaction/gesture line (DevTools + `flutter run` stdout).
  static void interaction(String message, [Object? detail]) {
    if (!kDebugMode || !logInteraction) return;
    final line = detail != null ? '$message | $detail' : message;
    dev.log(line, name: 'FlowCanvas.Interaction');
    debugPrint('[FlowCanvas.Interaction] $line');
  }

  /// Logs a performance line when [logPerf] is enabled.
  static void perf(String message, [Object? detail]) {
    if (!kDebugMode || !logPerf) return;
    final line = detail != null ? '$message | $detail' : message;
    dev.log(line, name: 'FlowCanvas.Perf');
    debugPrint('[FlowCanvas.Perf] $line');
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
