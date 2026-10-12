import 'package:flutter/foundation.dart';

import 'lattice_viewport_value.dart';

/// User-facing canvas options, read at build time.
///
/// Later plans add fields additively — keep this class open for extension,
/// do not seal it.
@immutable
class LatticeOptions {
  const LatticeOptions({
    this.defaultViewport,
    this.fitView = false,
    this.minZoom = 0.05,
    this.maxZoom = 4.0,
  });

  final LatticeViewportValue? defaultViewport;
  final bool fitView;
  final double minZoom;
  final double maxZoom;

  LatticeOptions copyWith({
    LatticeViewportValue? defaultViewport,
    bool? fitView,
    double? minZoom,
    double? maxZoom,
  }) {
    return LatticeOptions(
      defaultViewport: defaultViewport ?? this.defaultViewport,
      fitView: fitView ?? this.fitView,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeOptions &&
        other.defaultViewport == defaultViewport &&
        other.fitView == fitView &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom;
  }

  @override
  int get hashCode =>
      Object.hash(defaultViewport, fitView, minZoom, maxZoom);
}
