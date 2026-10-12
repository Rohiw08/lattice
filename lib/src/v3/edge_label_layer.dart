import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edge_layer.dart';
import 'lattice_camera.dart';
import 'lattice_cull.dart';
import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'session_providers.dart';

/// Builds the label widget for [edge].
typedef LatticeEdgeLabelBuilder =
    Widget Function(BuildContext context, LatticeEdge edge);

/// Virtualized edge label layer, mounted above the edge layer.
///
/// Labels are computed from the document directly: each edge's endpoints
/// resolve to node absolute positions, and the label anchor is the
/// midpoint of that straight segment. For bezier edges this is a
/// documented approximation (the average of the two anchors); the exact
/// curve point is V3-6 polish. This layer deliberately owns NO second
/// [EdgePathCache], so there is zero duplicated cache sync work with
/// [LatticeEdgeLayer] — it only reads the paint version as a change
/// signal.
///
/// Only edges that (a) have a builder for their `type`, (b) have both
/// endpoints present, and (c) intersect the visible flow rect mount a
/// label. Visibility is approximated without any path: the anchor
/// midpoint inside the visible rect, or the anchor-bounds overlapping it.
/// Shell instances are stable per edge id across rebuilds (same
/// element-map pattern as the node shells).
class LatticeEdgeLabelLayer extends ConsumerStatefulWidget {
  const LatticeEdgeLabelLayer({super.key, required this.labelBuilders});

  final Map<String, LatticeEdgeLabelBuilder> labelBuilders;

  @override
  ConsumerState<LatticeEdgeLabelLayer> createState() =>
      _LatticeEdgeLabelLayerState();
}

class _LatticeEdgeLabelLayerState extends ConsumerState<LatticeEdgeLabelLayer> {
  final Map<String, _LatticeEdgeLabelShell> _shells =
      <String, _LatticeEdgeLabelShell>{};

  @override
  void didUpdateWidget(covariant LatticeEdgeLabelLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.labelBuilders, widget.labelBuilders)) {
      _shells.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatticeDocument doc = ref.watch(latticeDocumentProvider);
    final Size? paneSize = ref.watch(latticePaneSizeProvider);
    ref.watch(latticeEdgePaintVersionProvider);
    final Matrix4 matrix = ref.read(latticeCameraProvider);

    Rect? visible;
    if (paneSize != null) {
      final Rect screenRect = Offset.zero & paneSize;
      visible = MatrixUtils.inverseTransformRect(matrix, screenRect);
    }

    final List<String> ids = <String>[];
    for (final LatticeEdge edge in doc.edges.values) {
      if (!widget.labelBuilders.containsKey(edge.type)) continue;
      final LatticeNode? source = doc.nodes[edge.source.nodeId];
      final LatticeNode? target = doc.nodes[edge.target.nodeId];
      if (source == null || target == null) continue;
      if (visible != null) {
        final Offset sourceAnchor = _edgeAnchor(
          doc.nodes,
          source,
          edge.source.handleId,
          isSource: true,
        );
        final Offset targetAnchor = _edgeAnchor(
          doc.nodes,
          target,
          edge.target.handleId,
          isSource: false,
        );
        final Offset mid = (sourceAnchor + targetAnchor) / 2;
        final Rect bounds = Rect.fromPoints(sourceAnchor, targetAnchor);
        if (!visible.contains(mid) && !bounds.overlaps(visible)) continue;
      }
      ids.add(edge.id);
    }
    ids.sort();

    final Set<String> wanted = ids.toSet();
    _shells.removeWhere((String id, _) => !wanted.contains(id));
    for (final String id in ids) {
      _shells.putIfAbsent(
        id,
        () => _LatticeEdgeLabelShell(
          key: ValueKey<String>(id),
          id: id,
          labelBuilders: widget.labelBuilders,
        ),
      );
    }
    return Stack(children: <Widget>[for (final String id in ids) _shells[id]!]);
  }
}

/// Positions one edge label from the session document.
///
/// Reads the edge and its endpoint nodes fresh on every build, so the
/// stable shell instance owned by [_LatticeEdgeLabelLayerState] never
/// goes stale. Renders nothing when the edge is gone, its type has no
/// builder, or an endpoint is missing (removal races never crash).
class _LatticeEdgeLabelShell extends ConsumerWidget {
  const _LatticeEdgeLabelShell({
    super.key,
    required this.id,
    required this.labelBuilders,
  });

  final String id;
  final Map<String, LatticeEdgeLabelBuilder> labelBuilders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LatticeDocument doc = ref.watch(latticeDocumentProvider);
    final LatticeEdge? edge = doc.edges[id];
    if (edge == null) return const SizedBox.shrink();
    final LatticeEdgeLabelBuilder? builder = labelBuilders[edge.type];
    if (builder == null) return const SizedBox.shrink();
    final LatticeNode? source = doc.nodes[edge.source.nodeId];
    final LatticeNode? target = doc.nodes[edge.target.nodeId];
    if (source == null || target == null) {
      return const SizedBox.shrink();
    }
    final Offset mid =
        (_edgeAnchor(doc.nodes, source, edge.source.handleId, isSource: true) +
            _edgeAnchor(
              doc.nodes,
              target,
              edge.target.handleId,
              isSource: false,
            )) /
        2;
    return Positioned(
      left: mid.dx,
      top: mid.dy,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: builder(context, edge),
      ),
    );
  }
}

/// Resolves one edge endpoint to a flow-space anchor, mirroring the
/// [EdgePathCache] resolution: the handle's absolute position when
/// [handleId] resolves in the endpoint node's handles, else the node's
/// center-right (source) / center-left (target) default ports.
/// Absolute rects use [Offset.zero] as the default origin.
Offset _edgeAnchor(
  Map<String, LatticeNode> nodes,
  LatticeNode node,
  String? handleId, {
  required bool isSource,
}) {
  final Rect rect = latticeAbsoluteRect(
    nodes,
    node.id,
    defaultOrigin: Offset.zero,
  );
  if (handleId != null) {
    final handle = node.resolveHandles()[handleId];
    if (handle != null) {
      return rect.topLeft + handle.position;
    }
  }
  return isSource ? rect.centerRight : rect.centerLeft;
}
