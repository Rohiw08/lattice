import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/node_resizer_theme.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Single resize handle for custom nodes (Lattice `<NodeResizeControl />`).
///
/// Place inside a custom node builder to expose one drag direction; the
/// node's own [FlowNode.minSize]/[maxSize]/[keepAspectRatio]/[shouldResize]
/// still govern the gesture. Unlike the auto-rendered [FlowNodeResizer]
/// (8 handles on selection), this renders whenever [isVisible] — manual
/// placement is explicit intent, so it ignores the `resizable` flag.
///
/// > **Hit-testing note:** the handle straddles the node edge, and stock
/// > Flutter boxes gate hit tests on `size.contains` (exclusive edges) — a
/// > press exactly on the edge dies inside a stock [Stack]. Root custom
/// > builders with overflowing chrome in [InfiniteHitTestStack] (exported
/// > by this package), which forwards edge-exact hits like the canvas
/// > layers do.
///
/// ```dart
/// NodeRegistry()..register('tall', (node) => InfiniteHitTestStack(
///   clipBehavior: Clip.none,
///   children: [
///     Text(node.id),
///     FlowNodeResizeControl(
///       nodeId: node.id,
///       direction: ResizeDirection.bottom,
///     ),
///   ],
/// ));
/// ```
class FlowNodeResizeControl extends ConsumerWidget {
  const FlowNodeResizeControl({
    super.key,
    required this.nodeId,
    this.direction = ResizeDirection.bottomRight,
    this.isVisible = true,
    this.style,
    this.offset = Offset.zero,
  });

  final String nodeId;

  /// Which corner/edge this handle drives.
  final ResizeDirection direction;

  final bool isVisible;

  /// Per-control theme override.
  final FlowNodeResizerStyle? style;

  /// Extra pixel nudge applied after centering (Lattice `offset`).
  final Offset offset;

  static Alignment _alignmentFor(ResizeDirection direction) {
    return switch (direction) {
      ResizeDirection.topLeft => Alignment.topLeft,
      ResizeDirection.topRight => Alignment.topRight,
      ResizeDirection.bottomLeft => Alignment.bottomLeft,
      ResizeDirection.bottomRight => Alignment.bottomRight,
      ResizeDirection.top => Alignment.topCenter,
      ResizeDirection.bottom => Alignment.bottomCenter,
      ResizeDirection.left => Alignment.centerLeft,
      ResizeDirection.right => Alignment.centerRight,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();
    final node = ref.watch(
      internalControllerProvider.select((s) => s.nodes[nodeId]),
    );
    if (node == null) return const SizedBox.shrink();
    final isSelected = ref.watch(
      internalControllerProvider.select((s) => s.selectedNodes.contains(nodeId)),
    );
    final controller = ref.read(internalControllerProvider.notifier);
    return NodeResizeHandle(
      nodeId: nodeId,
      direction: _alignmentFor(direction),
      offset: offset,
      isSelected: isSelected,
      style: style,
      onResizeStart: () =>
          controller.nodes.onNodeResizeStart(nodeId, direction),
      onResizeUpdate: (delta) =>
          controller.nodes.resizeNode(nodeId, direction, delta),
      onResizeEnd: () => controller.nodes.onNodeResizeEnd(),
    );
  }
}
