import 'dart:ui';

import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:flutter/foundation.dart';

/// Hysteresis cache for viewport culling (chunked culling).
///
/// Queries with an inflated rect and reuses the result until the visible
/// rect approaches the cache edge or [invalidate] is called.
class VisibleCullCache {
  VisibleCullCache({
    this.queryInflate = 1000.0,
    this.edgeMargin = 200.0,
  });

  final double queryInflate;
  final double edgeMargin;

  Rect? _cachedQueryRect;
  Set<String> _cachedIds = const {};
  int _spatialVersion = -1;

  Set<String> get cachedIds => _cachedIds;

  void invalidate() {
    _cachedQueryRect = null;
    _cachedIds = const {};
    _spatialVersion = -1;
  }

  /// Returns node ids to mount. [query] is called only when the cache misses.
  Set<String> resolve({
    required Rect visibleRect,
    required int spatialVersion,
    required Set<String> Function(Rect queryRect) query,
  }) {
    final needsRefresh = _cachedQueryRect == null ||
        spatialVersion != _spatialVersion ||
        !_isComfortablyInside(visibleRect, _cachedQueryRect!);

    if (needsRefresh) {
      final sw = Stopwatch()..start();
      final queryRect = visibleRect.inflate(queryInflate);
      _cachedIds = query(queryRect);
      _cachedQueryRect = queryRect;
      _spatialVersion = spatialVersion;
      sw.stop();
      if (kDebugMode && FlowCanvasDebug.logPerf) {
        FlowCanvasDebug.perf(
          'cull.query',
          'ids=${_cachedIds.length} ms=${sw.elapsedMicroseconds / 1000.0}',
        );
      }
    }
    return _cachedIds;
  }

  bool _isComfortablyInside(Rect visible, Rect cached) {
    return visible.left >= cached.left + edgeMargin &&
        visible.top >= cached.top + edgeMargin &&
        visible.right <= cached.right - edgeMargin &&
        visible.bottom <= cached.bottom - edgeMargin;
  }
}
