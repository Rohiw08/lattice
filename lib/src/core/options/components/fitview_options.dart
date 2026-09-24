import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:lattice/src/core/enums/enums.dart';

/// Options for fitting the canvas viewport to display nodes.
///
/// These options control how the canvas should be transformed when calling
/// `fitView()` to ensure all nodes (or a subset) are visible within the viewport.
///
/// ## React Flow Compatibility
///
/// This closely matches React Flow's `FitViewOptions`:
/// ```
/// {
///   padding?: Padding;
///   minZoom?: number;
///   maxZoom?: number;
///   duration?: number;
///   ease?: (t: number) => number;
///   interpolate?: "smooth" | "linear";
///   nodes?: (Node | { id: string })[];
/// }
/// ```
///
/// ## Usage
///
/// Fit all visible nodes with default options:
/// ```
/// await canvasController.fitView();
/// ```
///
/// Fit with custom padding:
/// ```
/// await canvasController.fitView(
///   options: FitViewOptions(
///     padding: EdgeInsets.all(100),
///   ),
/// );
/// ```
///
/// Fit specific nodes only:
/// ```
/// await canvasController.fitView(
///   options: FitViewOptions(
///     nodes: ['node1', 'node2', 'node3'],
///     padding: EdgeInsets.symmetric(horizontal: 50, vertical: 100),
///   ),
/// );
/// ```
///
/// Instant fit (no animation):
/// ```
/// await canvasController.fitView(
///   options: FitViewOptions(
///     duration: Duration.zero,
///   ),
/// );
/// ```
///
/// See also:
///
///  * [FlowCanvasInternalController.fitView], which uses these options
///  * [Viewport], for viewport state information
@immutable
class FitViewOptions with Diagnosticable {
  /// Padding around the fitted content in logical pixels.
  ///
  /// The padding ensures there's space between the viewport edges and the
  /// fitted nodes. This prevents nodes from being flush against the edges.
  ///
  /// React Flow Note: React Flow 12.5+ supports complex padding (px, %, per-side).
  /// This implementation uses Flutter's EdgeInsets for consistency.
  final EdgeInsets padding;

  /// Whether to include hidden nodes when calculating the bounding box.
  ///
  /// When true, hidden nodes (with `hidden: true` in their options) are
  /// included in the fit calculation. When false, only visible nodes are fitted.
  ///
  /// Defaults to false.
  final bool includeHiddenNodes;

  /// Minimum zoom level allowed during the fit operation.
  ///
  /// If the calculated zoom to fit all nodes would be less than this value,
  /// the zoom will be clamped to this minimum. This prevents zooming out
  /// too far for small node sets.
  ///
  /// Must be greater than 0. Typical values: 0.1 - 0.5.
  /// Defaults to 0.1 (10% zoom).
  final double minZoom;

  /// Maximum zoom level allowed during the fit operation.
  ///
  /// If the calculated zoom to fit all nodes would be greater than this value,
  /// the zoom will be clamped to this maximum. This prevents zooming in
  /// too far for large node sets.
  ///
  /// Must be greater than [minZoom]. Typical values: 1.0 - 4.0.
  /// Defaults to 2.0 (200% zoom).
  final double maxZoom;

  /// Duration of the animated transition to the fitted view.
  ///
  /// Set to a positive value for an animated glide. [Duration.zero] (the
  /// default, matching React Flow) fits instantly.
  /// Typical animated values: 200-500ms for snappy feel, 500-1000ms smooth.
  ///
  /// React Flow equivalent: `duration` (milliseconds, default 0 = instant).
  /// Defaults to [Duration.zero].
  final Duration duration;

  /// Easing curve for the animated transition.
  ///
  /// Defines the acceleration/deceleration profile of the animation.
  /// Common options:
  /// - [Curves.easeInOut] - Smooth start and end (default)
  /// - [Curves.linear] - Constant speed
  /// - [Curves.easeOut] - Fast start, slow end
  /// - [Curves.easeInOutCubic] - Very smooth
  ///
  /// React Flow equivalent: `ease` function.
  final Curve ease;

  /// Interpolation method for the animation.
  ///
  /// Controls how intermediate frames are calculated:
  /// - [FitViewInterpolation.smooth] - Smooth curved path (default)
  /// - [FitViewInterpolation.linear] - Straight-line path
  ///
  /// React Flow equivalent: `interpolate: "smooth" | "linear"`.
  final FitViewInterpolation interpolate;

  /// Specific node IDs to fit, or empty to fit all nodes.
  ///
  /// When provided, only these nodes are considered for the bounding box
  /// calculation. This is useful for focusing on a subset of the graph.
  ///
  /// Empty list (default) means fit all nodes.
  ///
  /// Example:
  /// ```
  /// FitViewOptions(
  ///   nodes: ['node1', 'node2'], // Only fit these two nodes
  /// )
  /// ```
  ///
  /// React Flow equivalent: `nodes` array.
  final List<String> nodes;

  /// Creates fit view options with the specified parameters.
  ///
  /// All parameters have sensible defaults that work for most use cases.
  const FitViewOptions({
    this.padding = const EdgeInsets.all(50),
    this.includeHiddenNodes = false,
    this.minZoom = 0.1,
    this.maxZoom = 2.0,
    this.duration = Duration.zero,
    this.ease = Curves.easeInOut,
    this.interpolate = FitViewInterpolation.smooth,
    this.nodes = const [],
  })  : assert(minZoom > 0, 'minZoom must be greater than 0'),
        assert(maxZoom > 0, 'maxZoom must be greater than 0'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom');

  /// Instant fit (no animation) — the default behavior.
  ///
  /// Useful when you want to fit the view immediately without animation,
  /// such as on initial load or after programmatic graph changes.
  ///
  /// Example:
  /// ```
  /// await canvasController.fitView(
  ///   options: FitViewOptions.instant(),
  /// );
  /// ```
  const FitViewOptions.instant({
    this.padding = const EdgeInsets.all(50),
    this.includeHiddenNodes = false,
    this.minZoom = 0.1,
    this.maxZoom = 2.0,
    this.interpolate = FitViewInterpolation.linear,
    this.nodes = const [],
  })  : duration = Duration.zero,
        ease = Curves.linear,
        assert(minZoom > 0, 'minZoom must be greater than 0'),
        assert(maxZoom > 0, 'maxZoom must be greater than 0'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom');

  /// Creates options for a smooth, slow animation.
  ///
  /// Uses a longer duration (800ms) and smooth easing for a more
  /// cinematic effect. Good for onboarding or showcasing. (The default
  /// constructor fits instantly; opt in here for motion.)
  ///
  /// Example:
  /// ```
  /// await canvasController.fitView(
  ///   options: FitViewOptions.smooth(),
  /// );
  /// ```
  const FitViewOptions.smooth({
    this.padding = const EdgeInsets.all(50),
    this.includeHiddenNodes = false,
    this.minZoom = 0.1,
    this.maxZoom = 2.0,
    this.nodes = const [],
  })  : duration = const Duration(milliseconds: 800),
        ease = Curves.easeInOutCubic,
        interpolate = FitViewInterpolation.smooth,
        assert(minZoom > 0, 'minZoom must be greater than 0'),
        assert(maxZoom > 0, 'maxZoom must be greater than 0'),
        assert(maxZoom >= minZoom, 'maxZoom must be >= minZoom');

  /// Returns a copy of these options with the given fields replaced.
  ///
  /// All parameters are optional. Null values retain the current value.
  ///
  /// Example:
  /// ```
  /// final newOptions = options.copyWith(
  ///   padding: EdgeInsets.all(100),
  ///   duration: Duration(milliseconds: 500),
  /// );
  /// ```
  FitViewOptions copyWith({
    EdgeInsets? padding,
    bool? includeHiddenNodes,
    double? minZoom,
    double? maxZoom,
    Duration? duration,
    Curve? ease,
    FitViewInterpolation? interpolate,
    List<String>? nodes,
  }) {
    return FitViewOptions(
      padding: padding ?? this.padding,
      includeHiddenNodes: includeHiddenNodes ?? this.includeHiddenNodes,
      minZoom: minZoom ?? this.minZoom,
      maxZoom: maxZoom ?? this.maxZoom,
      duration: duration ?? this.duration,
      ease: ease ?? this.ease,
      interpolate: interpolate ?? this.interpolate,
      nodes: nodes ?? this.nodes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FitViewOptions &&
        other.padding == padding &&
        other.includeHiddenNodes == includeHiddenNodes &&
        other.minZoom == minZoom &&
        other.maxZoom == maxZoom &&
        other.duration == duration &&
        other.ease == ease &&
        other.interpolate == interpolate &&
        listEquals(other.nodes, nodes);
  }

  @override
  int get hashCode => Object.hash(
        padding,
        includeHiddenNodes,
        minZoom,
        maxZoom,
        duration,
        ease,
        interpolate,
        Object.hashAll(nodes),
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<EdgeInsets>('padding', padding));
    properties.add(FlagProperty('includeHiddenNodes',
        value: includeHiddenNodes,
        defaultValue: false,
        ifTrue: 'including hidden nodes'));
    properties.add(DoubleProperty('minZoom', minZoom, defaultValue: 0.1));
    properties.add(DoubleProperty('maxZoom', maxZoom, defaultValue: 2.0));
    properties.add(DiagnosticsProperty<Duration>('duration', duration,
        defaultValue: Duration.zero));
    properties.add(DiagnosticsProperty<Curve>('ease', ease,
        defaultValue: Curves.easeInOut));
    properties.add(EnumProperty<FitViewInterpolation>(
        'interpolate', interpolate,
        defaultValue: FitViewInterpolation.smooth));
    properties.add(IterableProperty<String>('nodes', nodes,
        defaultValue: const [], ifEmpty: 'all nodes'));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final nodeCount = nodes.isEmpty ? 'all' : '${nodes.length}';
    final animated = duration > Duration.zero ? 'animated' : 'instant';
    return 'FitViewOptions($nodeCount nodes, $animated, zoom: $minZoom-$maxZoom)';
  }
}
