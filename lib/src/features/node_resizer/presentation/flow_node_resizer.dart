import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
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

  /// Per-instance style override (Lattice `handleStyle`/`lineStyle`).
  final FlowNodeResizerStyle? style;

  /// Shorthand tint (Lattice `color`): fills handles and the outline.
  final Color? color;

  const FlowNodeResizer({
    super.key,
    required this.nodeId,
    this.isVisible = true,
    this.style,
    this.color,
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
    // Per-node flag wins; null inherits the global (default false).
    final isDisabled = !node.isResizable(context);

    final theme =
        context.flowCanvasTheme.nodeResizer ??
            FlowNodeResizerStyle.system(context);
    var resolved = theme.merge(style);
    if (color != null) {
      resolved = resolved.merge(FlowNodeResizerStyle.colored(color: color!));
    }

    final controller = ref.read(internalControllerProvider.notifier);

    return InfiniteHitTestStack(
      clipBehavior: Clip.none,
      children: [
        // Outline box
        IgnorePointer(
          child: Container(
            width: node.size.width,
            height: node.size.height,
            decoration: resolved.lineDecoration,
          ),
        ),
        // Corner handles
        _buildHandle(controller, ResizeDirection.topLeft, Alignment.topLeft,
            isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.topRight, Alignment.topRight,
            isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.bottomLeft,
            Alignment.bottomLeft, isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.bottomRight,
            Alignment.bottomRight, isSelected, isDisabled, resolved),
        // Side handles
        _buildHandle(controller, ResizeDirection.top, Alignment.topCenter,
            isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.bottom, Alignment.bottomCenter,
            isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.left, Alignment.centerLeft,
            isSelected, isDisabled, resolved),
        _buildHandle(controller, ResizeDirection.right, Alignment.centerRight,
            isSelected, isDisabled, resolved),
      ],
    );
  }

  Widget _buildHandle(
    dynamic controller,
    ResizeDirection direction,
    Alignment alignment,
    bool isSelected,
    bool isDisabled,
    FlowNodeResizerStyle style,
  ) {
    return NodeResizeHandle(
      nodeId: nodeId,
      direction: alignment,
      isSelected: isSelected,
      isDisabled: isDisabled,
      style: style,
      onResizeStart: () => controller.nodes.onNodeResizeStart(nodeId, direction),
      onResizeUpdate: (delta) =>
          controller.nodes.resizeNode(nodeId, direction, delta),
      onResizeEnd: () => controller.nodes.onNodeResizeEnd(),
    );
  }
}
