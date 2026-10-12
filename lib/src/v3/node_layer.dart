import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'handle_widget.dart';
import 'lattice_cull.dart';
import 'lattice_handle.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'session_providers.dart';

/// Builds a node body for [node]; [selected] mirrors the session selection.
typedef LatticeNodeBuilder = Widget Function(
  BuildContext context,
  LatticeNode node,
  bool selected,
);

/// Virtualized node layer: a [Stack] of stable node shells for the culled
/// id set only.
///
/// Watches ONLY [latticeCullProvider]. Per-node session data (record,
/// selection flag, drag live position) is watched inside each shell, so a
/// cull swap rebuilds this layer but never rebuilds unchanged shells, and
/// camera ticks rebuild nothing at all.
class LatticeNodeLayer extends ConsumerWidget {
  const LatticeNodeLayer({super.key, this.nodeBuilders = const {}});

  final Map<String, LatticeNodeBuilder> nodeBuilders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Set<String> culled = ref.watch(latticeCullProvider);
    final List<String> ids = culled.toList()..sort();
    return _NodeShellStack(ids: ids, nodeBuilders: nodeBuilders);
  }
}

/// Owns the shell instance cache: shells for unchanged ids are returned
/// identical across layer rebuilds (stable element map); ids that left the
/// culled set are dropped so no stale shell survives.
class _NodeShellStack extends StatefulWidget {
  const _NodeShellStack({required this.ids, required this.nodeBuilders});

  final List<String> ids;
  final Map<String, LatticeNodeBuilder> nodeBuilders;

  @override
  State<_NodeShellStack> createState() => _NodeShellStackState();
}

class _NodeShellStackState extends State<_NodeShellStack> {
  final Map<String, _LatticeNodeShell> _shells = <String, _LatticeNodeShell>{};

  @override
  void didUpdateWidget(covariant _NodeShellStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.nodeBuilders, widget.nodeBuilders)) {
      _shells.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> wanted = widget.ids.toSet();
    _shells.removeWhere((String id, _) => !wanted.contains(id));
    for (final String id in widget.ids) {
      _shells.putIfAbsent(
        id,
        () => _LatticeNodeShell(
          key: ValueKey<String>(id),
          id: id,
          nodeBuilders: widget.nodeBuilders,
        ),
      );
    }
    return Stack(
      children: <Widget>[for (final String id in widget.ids) _shells[id]!],
    );
  }
}

/// Positions one node from the session: drag live position when active,
/// else the document absolute rect. Renders nothing when the record is
/// gone (removal race between cull passes never crashes).
class _LatticeNodeShell extends ConsumerWidget {
  const _LatticeNodeShell({
    super.key,
    required this.id,
    required this.nodeBuilders,
  });

  final String id;
  final Map<String, LatticeNodeBuilder> nodeBuilders;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, LatticeNode> nodes = ref.watch(latticeNodesProvider);
    final LatticeNode? node = nodes[id];
    if (node == null) return const SizedBox.shrink();
    final bool selected = ref.watch(
      latticeSelectionProvider.select((selection) => selection.nodes.contains(id)),
    );
    final Offset? live = ref.watch(
      latticeDragProvider.select((drag) => drag.livePositions[id]),
    );
    final Rect rect = live == null
        ? latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero)
        : (latticeAnchorTopLeft(
                node.copyWith(position: live), Offset.zero,
              ) &
              node.size);
    final Widget body = nodeBuilders[node.type]?.call(context, node, selected) ??
        _defaultNodeBody(node, selected);
    final Map<String, LatticeHandle> handles = node.resolveHandles();
    if (handles.isEmpty) {
      return Positioned(
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: body,
      );
    }
    // Handle overlay: node bodies are user builders, so the shell mounts
    // a LatticeHandleWidget per resolved handle in a Stack above the
    // body. Each hit area is centered on its handle rect center.
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: Stack(
        children: <Widget>[
          body,
          for (final MapEntry<String, LatticeHandle> entry
              in handles.entries)
            Positioned(
              left: entry.value.position.dx +
                  entry.value.size.width / 2 -
                  latticeHandleHitExtent(entry.value.size.width) / 2,
              top: entry.value.position.dy +
                  entry.value.size.height / 2 -
                  latticeHandleHitExtent(entry.value.size.height) / 2,
              child: LatticeHandleWidget(nodeId: id, handle: entry.value),
            ),
        ],
      ),
    );
  }
}

Widget _defaultNodeBody(LatticeNode node, bool selected) {
  return Container(
    decoration: BoxDecoration(
      color: const Color(0xFFFFFFFF),
      border: Border.all(
        color: selected
            ? const Color(0xFF2563EB)
            : const Color(0xFF94A3B8),
        width: selected ? 2.0 : 1.0,
      ),
      borderRadius: BorderRadius.circular(8.0),
    ),
    alignment: Alignment.center,
    child: Text(
      node.id,
      style: const TextStyle(fontSize: 12),
      overflow: TextOverflow.ellipsis,
    ),
  );
}

/// LOD stand-in: paints node rects (one `drawRect` per node, single paint)
/// for an id set. Reused by the minimap in V3-6.
///
/// Repaints only when the id set differs or [version] (caller-owned
/// geometry version) changes.
class LatticeLodPainter extends CustomPainter {
  const LatticeLodPainter({
    required this.nodes,
    required this.ids,
    this.version = 0,
    this.color = const Color(0xFFCBD5E1),
  });

  final Map<String, LatticeNode> nodes;
  final Set<String> ids;
  final int version;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    for (final String id in ids) {
      final LatticeNode? node = nodes[id];
      if (node == null) continue;
      canvas.drawRect(
        latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant LatticeLodPainter oldDelegate) {
    return version != oldDelegate.version ||
        !identical(nodes, oldDelegate.nodes) ||
        ids.length != oldDelegate.ids.length ||
        !ids.containsAll(oldDelegate.ids);
  }
}
