import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/flow_selectors.dart';
import 'package:lattice/src/core/providers/providers.dart';

/// Screen-space portal for interactive edge labels (React Flow
/// `<EdgeLabelRenderer>`).
///
/// Place once in `FlowCanvas(overlays: [...])`. Renders [FlowEdge.overlayLabel]
/// for every labeled edge at its path midpoint at a **constant screen size**
/// (never scales with zoom) with full pointer interactivity — e.g. a delete
/// button, the RF edge-label tutorial's use case:
///
/// ```dart
/// FlowCanvas(
///   overlays: const [FlowEdgeLabelPortal()],
///   initialEdges: [
///     FlowEdge(
///       id: 'e1',
///       sourceNodeId: 'a',
///       targetNodeId: 'b',
///       overlayLabel: _DeleteEdgeButton(edgeId: 'e1'),
///     ),
///   ],
/// )
/// ```
///
/// Labels track live drags (midpoint follows the rubber-banding path).
/// A label's box is pointer-opaque — drags starting on it neither pan the
/// viewport nor start a marquee, matching RF's `nodrag nopan` label
/// requirement. Presentation-only text should use [FlowEdge.label] instead.
///
/// Empty portal area falls through to the canvas, so taps elsewhere still
/// deselect. (The reverse lesson for YOUR overlays: a bare widget in
/// `overlays` sizes loosely and can swallow canvas pointers — wrap overlay
/// content in `Positioned`/tight boxes.)
class FlowEdgeLabelPortal extends ConsumerWidget {
  const FlowEdgeLabelPortal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    // Labeled edge ids + geometry revision (paths change without edge
    // identity changing, e.g. endpoint drags). Watch the stored map and the
    // revision (both stable identities); derive the id list in the body so
    // unrelated edge commits don't rebuild the portal (invariant #1).
    final edges = ref.watch(flowEdgesProvider);
    ref.watch(internalControllerProvider.select((s) => s.geometryRevision));
    final ids = <String>[];
    for (final entry in edges.entries) {
      if (entry.value.overlayLabel != null) ids.add(entry.key);
    }
    ids.sort();
    if (ids.isEmpty) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge(
          [controller.liveViewport, controller.interactionSession]),
      builder: (context, _) {
        final state = controller.currentState;
        final live = controller.liveViewport.viewport;
        Offset toViewer(Offset flow) => flow * live.zoom + live.offset;
        // Lazy-geometry demand fill (same pattern as the edge cull filter):
        // with culling on, mount skips the full cache fill, so a labeled edge
        // can reach this builder before its path exists. Missing-only, so
        // cached labels cost one map hit per tick.
        controller.edgeGeometryService.ensureGeoms(
          state,
          ids,
          defaultOrigin:
              ref.read(flowOptionsProvider).nodeOptions.nodeOrigin,
        );
        final children = <Widget>[];
        for (final id in ids) {
          final edge = state.edges[id];
          final label = edge?.overlayLabel;
          if (edge == null ||
              label == null ||
              (edge.hidden ?? false)) {
            continue;
          }
          final geom = controller.edgeGeometryService.getGeom(id);
          final samples = geom?.samples;
          final anchor = (samples != null && samples.isNotEmpty)
              ? samples[samples.length ~/ 2]
              : geom?.bounds.center;
          if (anchor == null) continue;
          final at = toViewer(anchor);
          children.add(Positioned(
            left: at.dx,
            top: at.dy,
            child: FractionalTranslation(
              translation: const Offset(-0.5, -0.5),
              child: label,
            ),
          ));
        }
        if (children.isEmpty) return const SizedBox.shrink();
        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}
