import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/node_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';

/// Paint-only node layer for deep zoom-out (thumbnail LOD).
///
/// Rendered by the middle [FlowNodesLayer] instead of individual widgets
/// when `ViewportOptions.lodThumbnailBelowZoom` is set and the current zoom
/// falls below it. One [RepaintBoundary] + one [CustomPaint] replaces N
/// widget subtrees, so very large graphs stay fluid while zoomed out.
///
/// Tradeoffs (documented, opt-in via non-null threshold):
/// - View-only: drag, resize, handles, and node focus are unavailable below
///   the threshold (tap empty canvas still deselects). Zoom back in for
///   full interaction.
/// - Approximate styling: fill + selected outline from the resolved node
///   decoration; per-widget content (labels, custom paint) is not rendered.
/// - Repaints on graph commits only; pan/zoom move the cached layer.
class NodesThumbnailLayer extends ConsumerWidget {
  const NodesThumbnailLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch (not read) exactly the two things the thumbnail draws — the node
    // map and the selection — so graph edits and selection changes repaint it
    // while zoomed out. Selecting the whole state would rebuild on every
    // pan/zoom frame and defeat the LOD cache; the map/set carry stable
    // identity, so this rebuilds only on real structural or selection changes.
    final record = ref.watch(
      internalControllerProvider.select(
        (s) => (s.nodes, s.selectedNodes),
      ),
    );
    final nodes = record.$1;
    final selectedNodes = record.$2;
    final baseTheme =
        context.flowCanvasTheme.node ?? FlowNodeStyle.system(context);

    final items = <({Rect rect, Color fill, Color? selectedBorder, int zIndex})>[];
    final defaultOrigin =
        ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;
    for (final node in nodes.values) {
      if (node.hidden ?? false) continue;
      final rect = NodeLayout.absoluteRect(node, nodes,
          defaultOrigin: defaultOrigin);
      final states = <FlowNodeState>{
        FlowNodeState.normal,
        if (selectedNodes.contains(node.id)) FlowNodeState.selected,
      };
      final style = node.style == null ? baseTheme : baseTheme.merge(node.style);
      final decoration = style.resolveDecoration(states);
      final box = decoration is BoxDecoration ? decoration : null;
      final boxBorder = box?.border;
      items.add((
        rect: rect,
        fill: box?.color ?? const Color(0xFF3A3A3A),
        selectedBorder:
            states.contains(FlowNodeState.selected) && boxBorder is Border
                ? boxBorder.top.color
                : null,
        zIndex: node.zIndex,
      ));
    }
    items.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    return RepaintBoundary(
      child: CustomPaint(
        key: const ValueKey('nodes-thumbnail'),
        painter: NodesThumbnailPainter(items),
        size: Size.infinite,
      ),
    );
  }
}

/// Paints pre-resolved node rects; repaints only when [items] is replaced
/// (graph commits), never on pan/zoom (matrix moves the cached layer).
@immutable
class NodesThumbnailPainter extends CustomPainter {
  const NodesThumbnailPainter(this.items);

  final List<({Rect rect, Color fill, Color? selectedBorder, int zIndex})>
      items;

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      if (item.rect.isEmpty) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(item.rect, const Radius.circular(4)),
        Paint()..color = item.fill,
      );
      final border = item.selectedBorder;
      if (border != null) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(item.rect.deflate(1), const Radius.circular(4)),
          Paint()
            ..color = border
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(NodesThumbnailPainter oldDelegate) =>
      !identical(oldDelegate.items, items);
}
