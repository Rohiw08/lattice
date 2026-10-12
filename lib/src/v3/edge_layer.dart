import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edge_path_cache.dart';
import 'lattice_camera.dart';
import 'lattice_cull.dart';
import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_theme.dart';
import 'session_providers.dart';

/// Paint-version counter for the edge layer.
///
/// Starts at 0; bumped by [LatticeEdgeLayer] only when the owned
/// [EdgePathCache] actually recomputed a path (tracked via
/// `recomputeCount`), never by viewport/camera ticks.
class LatticeEdgePaintVersion extends Notifier<int> {
  @override
  int build() => 0;

  void bump() {
    state = state + 1;
  }
}

final latticeEdgePaintVersionProvider =
    NotifierProvider<LatticeEdgePaintVersion, int>(
  LatticeEdgePaintVersion.new,
);

/// Edge stroke theming: selected/unselected color + width pairs for the
/// single edge painter.
///
/// The theme's edge component is a [LatticeEdgeStyle]; the values here are
/// the paint-only subset the layer needs.
@immutable
class LatticeEdgeStyle {
  const LatticeEdgeStyle({
    this.color = const Color(0xFF555555),
    this.width = 2.0,
    this.selectedColor = const Color(0xFF0000FF),
    this.selectedWidth = 3.0,
  });

  final Color color;
  final double width;
  final Color selectedColor;
  final double selectedWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeEdgeStyle &&
        other.color == color &&
        other.width == width &&
        other.selectedColor == selectedColor &&
        other.selectedWidth == selectedWidth;
  }

  @override
  int get hashCode => Object.hash(color, width, selectedColor, selectedWidth);
}

/// Paints one stroked path per edge id.
///
/// Each path in [paths] is drawn exactly once; color/width come from
/// [style] by [selectedEdges] membership.
///
/// [paintedIdsRecorder], when supplied, is the shared backing store for
/// [paintedIdsForTest]: the layer's `State` owns one list across builds
/// and passes it to every painter, so the hook still reflects what is on
/// screen when an equal-contents rebuild yields `shouldRepaint == false`
/// (the new delegate is discarded and never paints). The painter refills
/// the list in place on every [paint] — never reassigns it — so all
/// delegates sharing the list observe the same ids.
class LatticeEdgePainter extends CustomPainter {
  LatticeEdgePainter({
    required this.paths,
    required this.edges,
    required this.selectedEdges,
    required this.style,
    List<String>? paintedIdsRecorder,
  }) : _paintedIds = paintedIdsRecorder ?? <String>[];

  final Map<String, Path> paths;
  final Map<String, LatticeEdge> edges;
  final Set<String> selectedEdges;
  final LatticeEdgeStyle style;

  final List<String> _paintedIds;

  /// Ids actually painted in the last [paint] call.
  ///
  /// Test hook: lets widget tests assert which edges the layer handed
  /// to the painter without pixel sampling. When the painter was built
  /// with a shared recorder, this reflects the on-screen painting even
  /// if this delegate instance never painted (discarded `shouldRepaint`
  /// false rebuild).
  List<String> get paintedIdsForTest =>
      List<String>.unmodifiable(_paintedIds);

  @override
  void paint(Canvas canvas, Size size) {
    final List<String> painted = <String>[];
    paths.forEach((String id, Path path) {
      final bool selected = selectedEdges.contains(id);
      final Paint paint = Paint()
        ..color = selected ? style.selectedColor : style.color
        ..strokeWidth = selected ? style.selectedWidth : style.width
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, paint);
      painted.add(id);
    });
    _paintedIds
      ..clear()
      ..addAll(painted);
  }

  @override
  bool shouldRepaint(covariant LatticeEdgePainter oldDelegate) {
    if (!identical(paths, oldDelegate.paths)) {
      if (paths.length != oldDelegate.paths.length) return true;
      for (final MapEntry<String, Path> entry in paths.entries) {
        if (!identical(entry.value, oldDelegate.paths[entry.key])) {
          return true;
        }
      }
    }
    if (!identical(edges, oldDelegate.edges)) {
      if (edges.length != oldDelegate.edges.length) return true;
      for (final MapEntry<String, LatticeEdge> entry in edges.entries) {
        if (oldDelegate.edges[entry.key] != entry.value) return true;
      }
    }
    if (selectedEdges.length != oldDelegate.selectedEdges.length ||
        !selectedEdges.containsAll(oldDelegate.selectedEdges)) {
      return true;
    }
    return style != oldDelegate.style;
  }
}

/// Single-painter edge layer, mounted under the node layer.
///
/// The effective [LatticeEdgeStyle] is the explicit [style] when given,
/// else the nearest [LatticeThemeScope]'s edge style, else the light
/// default.
///
/// Owns an [EdgePathCache] in the [_LatticeEdgeLayerBody] state so the
/// cache survives rebuilds. On each build the state syncs the cache to
/// the current document and bumps [latticeEdgePaintVersionProvider]
/// only when `recomputeCount` changed since the last build. The painter
/// receives only edges whose cached bounds intersect the visible flow
/// rect (camera matrix + pane size via `MatrixUtils.inverseTransformRect`,
/// same as the cull) and whose endpoints exist; `hidden == true` edges
/// are skipped.
class LatticeEdgeLayer extends ConsumerWidget {
  const LatticeEdgeLayer({super.key, this.style});

  final LatticeEdgeStyle? style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LatticeTheme theme =
        LatticeThemeScope.maybeOf(context) ?? LatticeTheme.light();
    return _LatticeEdgeLayerBody(style: style ?? theme.resolvedEdge);
  }
}

class _LatticeEdgeLayerBody extends ConsumerStatefulWidget {
  const _LatticeEdgeLayerBody({required this.style});

  final LatticeEdgeStyle style;

  @override
  ConsumerState<_LatticeEdgeLayerBody> createState() =>
      _LatticeEdgeLayerBodyState();
}

class _LatticeEdgeLayerBodyState
    extends ConsumerState<_LatticeEdgeLayerBody> {
  final EdgePathCache _cache = EdgePathCache();
  final List<String> _paintedIds = <String>[];
  int _lastCount = 0;

  @override
  Widget build(BuildContext context) {
    final LatticeDocument doc = ref.watch(latticeDocumentProvider);
    final Set<String> selectedEdges = ref.watch(
      latticeSelectionProvider.select((selection) => selection.edges),
    );
    final Size? paneSize = ref.watch(latticePaneSizeProvider);
    ref.watch(latticeEdgePaintVersionProvider);
    final Matrix4 matrix = ref.read(latticeCameraProvider);

    _cache.syncTo(doc, defaultOrigin: Offset.zero);
    if (_cache.recomputeCount != _lastCount) {
      _lastCount = _cache.recomputeCount;
      // Riverpod forbids mutating a provider during build; defer the
      // version bump post-frame (same pattern as the canvas pane-size
      // publish). Still exactly one bump per recompute batch: [_lastCount]
      // is updated synchronously, so repeat builds before the callback
      // runs schedule nothing further.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(latticeEdgePaintVersionProvider.notifier).bump();
      });
    }

    Rect? visible;
    if (paneSize != null) {
      final Rect screenRect = Offset.zero & paneSize;
      visible = MatrixUtils.inverseTransformRect(matrix, screenRect);
    }

    final Map<String, Path> paths = <String, Path>{};
    final Map<String, LatticeEdge> edges = <String, LatticeEdge>{};
    for (final LatticeEdge edge in doc.edges.values) {
      if (edge.hidden == true) continue;
      if (!doc.nodes.containsKey(edge.source.nodeId)) continue;
      if (!doc.nodes.containsKey(edge.target.nodeId)) continue;
      final Path? path = _cache.pathFor(edge.id);
      final Rect? bounds = _cache.boundsFor(edge.id);
      if (path == null || bounds == null) continue;
      if (visible != null && !bounds.overlaps(visible)) continue;
      paths[edge.id] = path;
      edges[edge.id] = edge;
    }

    return SizedBox.expand(
      child: CustomPaint(
        painter: LatticeEdgePainter(
          paths: paths,
          edges: edges,
          selectedEdges: selectedEdges,
          style: widget.style,
          paintedIdsRecorder: _paintedIds,
        ),
      ),
    );
  }
}
