import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/node_resizer_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlowNodeResizer extends ConsumerWidget {
  final String nodeId;
  final bool isVisible;

  const FlowNodeResizer({
    super.key,
    required this.nodeId,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isVisible) return const SizedBox.shrink();

    final node =
        ref.watch(internalControllerProvider.select((s) => s.nodes[nodeId]));
    if (node == null) return const SizedBox.shrink();

    final isSelected = ref.watch(
      internalControllerProvider.select((s) => s.selectedNodes.contains(nodeId)),
    );
    final isDisabled = node.resizable == false;

    final theme =
        context.flowCanvasTheme.nodeResizer ??
            FlowNodeResizerStyle.system(context);

    final controller = ref.read(internalControllerProvider.notifier);

    return InfiniteHitTestStack(
      clipBehavior: Clip.none,
      children: [
        // Outline box
        IgnorePointer(
          child: Container(
            width: node.size.width,
            height: node.size.height,
            decoration: theme.lineDecoration,
          ),
        ),
        // Corner handles
        _buildHandle(controller, ResizeDirection.topLeft, Alignment.topLeft,
            isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.topRight, Alignment.topRight,
            isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.bottomLeft,
            Alignment.bottomLeft, isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.bottomRight,
            Alignment.bottomRight, isSelected, isDisabled),
        // Side handles
        _buildHandle(controller, ResizeDirection.top, Alignment.topCenter,
            isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.bottom, Alignment.bottomCenter,
            isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.left, Alignment.centerLeft,
            isSelected, isDisabled),
        _buildHandle(controller, ResizeDirection.right, Alignment.centerRight,
            isSelected, isDisabled),
      ],
    );
  }

  Widget _buildHandle(
    dynamic controller,
    ResizeDirection direction,
    Alignment alignment,
    bool isSelected,
    bool isDisabled,
  ) {
    return NodeResizeHandle(
      nodeId: nodeId,
      direction: alignment,
      isSelected: isSelected,
      isDisabled: isDisabled,
      onResizeUpdate: (delta) =>
          controller.nodes.resizeNode(nodeId, direction, delta),
      onResizeEnd: () => controller.nodes.onNodeResizeEnd(),
    );
  }
}
