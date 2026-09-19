import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/edge_reconnect_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Draggable endpoints on selected reconnectable edges (Lattice edge reconnect).
class EdgeReconnectLayer extends ConsumerWidget {
  const EdgeReconnectLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      internalControllerProvider.select((s) => s.selectedEdges),
    );
    final opts = ref.read(flowOptionsProvider).connectionOptions;
    if (!opts.edgesReconnectable || selected.isEmpty) {
      return const SizedBox.shrink();
    }

    final controller = ref.read(internalControllerProvider.notifier);
    final session = controller.interactionSession;
    final style = context.flowCanvasTheme.edgeReconnect ??
        FlowEdgeReconnectStyle.system(context);
    final cursor = (context.flowCanvasTheme.cursor ??
            FlowCursorStyle.system(context))
        .edgeUpdater;

    // Rebuild during drags: reconnect dots must track live positions (Lattice
    // renders the edge-updater at the node's current drag position).
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) {
        final state = controller.currentState;
        final children = <Widget>[];
        for (final edgeId in selected) {
          final edge = state.edges[edgeId];
          if (edge == null) continue;
          final allowed = edge.reconnectable ??
              ref.read(flowOptionsProvider).edgeOptions.reconnectable;
          if (!allowed) continue;
          if (state.edgeStates[edgeId]?.reconnecting ?? false) continue;

          final sourceNode = state.nodes[edge.sourceNodeId];
          final targetNode = state.nodes[edge.targetNodeId];
          if (sourceNode == null || targetNode == null) continue;

          final sourceHandle = edge.sourceHandleId != null
              ? sourceNode.effectiveHandles[edge.sourceHandleId!]
              : null;
          final targetHandle = edge.targetHandleId != null
              ? targetNode.effectiveHandles[edge.targetHandleId!]
              : null;

          final defaultOrigin =
              ref.read(flowOptionsProvider).nodeOptions.nodeOrigin;
          final sourcePos = NodeLayout.absoluteTopLeft(
                edge.sourceNodeId,
                state.nodes,
                livePositions: session.livePositions,
                defaultOrigin: defaultOrigin,
              ) +
              (sourceHandle?.position ??
                  Offset(sourceNode.size.width, sourceNode.size.height / 2));
          final targetPos = NodeLayout.absoluteTopLeft(
                edge.targetNodeId,
                state.nodes,
                livePositions: session.livePositions,
                defaultOrigin: defaultOrigin,
              ) +
              (targetHandle?.position ??
                  Offset(0, targetNode.size.height / 2));

          children.add(_ReconnectHandle(
            key: ValueKey('reconnect_${edgeId}_${HandleTypeEnd.source.name}'),
            edgeId: edgeId,
            end: HandleTypeEnd.source,
            position: sourcePos,
            style: style,
            cursor: cursor,
            radius: opts.reconnectRadius,
          ));
          children.add(_ReconnectHandle(
            key: ValueKey('reconnect_${edgeId}_${HandleTypeEnd.target.name}'),
            edgeId: edgeId,
            end: HandleTypeEnd.target,
            position: targetPos,
            style: style,
            cursor: cursor,
            radius: opts.reconnectRadius,
          ));
        }

        return Stack(clipBehavior: Clip.none, children: children);
      },
    );
  }
}

class _ReconnectHandle extends ConsumerWidget {
  const _ReconnectHandle({
    super.key,
    required this.edgeId,
    required this.end,
    required this.position,
    required this.style,
    required this.cursor,
    required this.radius,
  });

  final String edgeId;
  final HandleTypeEnd end;
  final Offset position;
  final FlowEdgeReconnectStyle style;
  final MouseCursor cursor;
  final double radius;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final size = radius.clamp(10.0, 28.0);

    return Positioned(
      left: position.dx - size / 2,
      top: position.dy - size / 2,
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            final box = controller.canvasKey.currentContext?.findRenderObject()
                as RenderBox?;
            if (box == null) return;
            final flow = box.globalToLocal(details.globalPosition);
            controller.connection.startReconnect(
              edgeId: edgeId,
              end: end,
              cursorFlow: flow,
            );
          },
          onPanUpdate: (details) {
            final box = controller.canvasKey.currentContext?.findRenderObject()
                as RenderBox?;
            if (box == null) return;
            final flow = box.globalToLocal(details.globalPosition);
            controller.connection.updateConnection(
              flow,
              globalPosition: details.globalPosition,
            );
          },
          onPanEnd: (_) => controller.connection.endConnection(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: style.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: style.borderColor,
                width: style.borderWidth,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

