import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:flutter/material.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/handle_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/features/handles/presentation/flow_handle.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/core/theme/components/node_theme.dart';

/// Styled chrome for custom (and built-in) nodes: body decoration + handles.
///
/// ```dart
/// registry.registerTyped<MyData>('mine', (props) {
///   return BaseNode(
///     node: props.node,
///     child: Text(props.data.label), // drag / select / connect — automatic
///   );
/// });
/// ```
///
/// Put buttons, fields, and menus in [child] — node-drag yields to them
/// automatically (React Flow `nodrag` behavior). Use [overlay] for a side
/// panel; it is hit-testable and non-dragging without extra wrappers.
///
/// Optional [style] overrides the theme for this node only.
class BaseNode extends ConsumerWidget {
  final FlowNode node;
  final FlowNodeStyle? style;
  final Widget? child;
  final HandleBuilder? handleBuilder;
  final FlowHandleStyle? handleStyle;

  /// Extra UI painted beside the node (color pickers, menus, …).
  ///
  /// Placed in the same overflow-friendly stack as handles. Defaults to just
  /// right of the node; override with [overlayOffset].
  final Widget? overlay;

  /// Top-left of [overlay] in node-local coordinates.
  ///
  /// When null and [overlay] is set: `Offset(node.size.width + 8, 0)`.
  final Offset? overlayOffset;

  const BaseNode({
    super.key,
    required this.node,
    this.child,
    this.style,
    this.handleBuilder,
    this.handleStyle,
    this.overlay,
    this.overlayOffset,
  });

  Set<FlowNodeState> _computeStates(
      NodeRuntimeState nodeRuntimeState, FlowNode node, BuildContext context) {
    final states = <FlowNodeState>{FlowNodeState.normal};
    if (!node.isSelectable(context)) {
      states.add(FlowNodeState.disabled);
    }
    if (nodeRuntimeState.selected) {
      states.add(FlowNodeState.selected);
    }
    if (nodeRuntimeState.hovered) {
      states.add(FlowNodeState.hovered);
    }
    return states;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseTheme =
        context.flowCanvasTheme.node ?? FlowNodeStyle.system(context);
    final theme = baseTheme.merge(style ?? node.style);

    final nodeRuntimeState = ref.watch(
      internalControllerProvider.select(
        (state) => state.nodeStates[node.id] ?? const NodeRuntimeState(),
      ),
    );

    final states = _computeStates(nodeRuntimeState, node, context);
    final decoration = theme.resolveDecoration(states);
    final controller = ref.read(internalControllerProvider.notifier);
    final isHoverable = node.isHoverable(context);
    final cursors =
        context.flowCanvasTheme.cursor ?? FlowCursorStyle.system(context);
    final cursor = cursors.resolveNode(
      selectable: node.isSelectable(context),
      draggable: node.isDraggable(context),
      dragging: nodeRuntimeState.dragging,
    );

    final resolvedOverlayOffset =
        overlayOffset ?? Offset(node.size.width + 8, 0);

    // InfiniteHitTestStack: handles / overlay may sit outside the node box.
    return InfiniteHitTestStack(
      clipBehavior: Clip.none,
      alignment: Alignment.topLeft,
      children: [
        SizedBox(
          width: node.size.width,
          height: node.size.height,
          child: MouseRegion(
            cursor: cursor,
            onEnter: isHoverable
                ? (e) => controller.nodes.onNodeMouseEnter(node.id, e)
                : null,
            onHover: isHoverable
                ? (e) => controller.nodes.onNodeMouseMove(node.id, e)
                : null,
            onExit: isHoverable
                ? (e) => controller.nodes.onNodeMouseLeave(node.id, e)
                : null,
            child: Container(
              decoration: decoration,
              child: Material(
                color: Colors.transparent,
                child: child,
              ),
            ),
          ),
        ),
        if (overlay != null)
          Positioned(
            left: resolvedOverlayOffset.dx,
            top: resolvedOverlayOffset.dy,
            child: overlay!,
          ),
        ...node.effectiveHandles.values.map(
          (handle) {
            final hitW =
                handle.size.width < 20 ? 20.0 : handle.size.width;
            final hitH =
                handle.size.height < 20 ? 20.0 : handle.size.height;
            return Positioned(
              left: handle.position.dx - hitW / 2,
              top: handle.position.dy - hitH / 2,
              width: hitW,
              height: hitH,
              child: Handle(
                nodeId: node.id,
                handleId: handle.id,
                type: handle.type,
                position: Offset.zero,
                size: handle.size,
                handleBuilder: handleBuilder,
                handleStyle: handleStyle,
              ),
            );
          },
        ),
      ],
    );
  }
}
