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
    this.resizeMinSize = 40,
    this.resizeMaxSize = 2000,
    this.interactive = true,
    this.fitViewOnInit = false,
  });

  final LatticeViewportValue? defaultViewport;
  final bool fitView;
  final double minZoom;
  final double maxZoom;

  /// Floor for node resize gestures, used when the node has no `minSize`.
  final double resizeMinSize;

  /// Ceiling for node resize gestures, used when the node has no `maxSize`.
  final double resizeMaxSize;

  /// Whether pointer gestures (drag, resize, connect, marquee, pan) and the
  /// camera verbs are enabled. Distinct from the session lock: `false` makes
  /// the canvas render-only while selection taps still work.
  final bool interactive;

  /// When true (and no [defaultViewport] is set), the canvas fits the
  /// document content to the pane once, after the first layout.
  final bool fitViewOnInit;

  LatticeOptions copyWith({
    LatticeViewportValue? defaultViewport,
    bool? fitView,
    double? minZoom,
    double? maxZoom,
    double? resizeMinSize,
    double? resizeMaxSize,
    bool? interactive,
    bool? fitViewOnInit,
  }) {
    return LatticeOptions(
      defaultViewport: defaultViewport ?? this.defaultViewport,
      fitView: fitView ?? this.fitView,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      resizeMinSize: resizeMinSize ?? this.resizeMinSize,
      resizeMaxSize: resizeMaxSize ?? this.resizeMaxSize,
      interactive: interactive ?? this.interactive,
      fitViewOnInit: fitViewOnInit ?? this.fitViewOnInit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeOptions &&
        other.defaultViewport == defaultViewport &&
        other.fitView == fitView &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.resizeMinSize == resizeMinSize &&
        other.resizeMaxSize == resizeMaxSize &&
        other.interactive == interactive &&
        other.fitViewOnInit == fitViewOnInit;
  }

  @override
  int get hashCode => Object.hash(
        defaultViewport,
        fitView,
        minZoom,
        maxZoom,
        resizeMinSize,
        resizeMaxSize,
        interactive,
        fitViewOnInit,
      );
}
