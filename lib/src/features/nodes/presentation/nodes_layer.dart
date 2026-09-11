import 'package:equatable/equatable.dart';
import 'package:lattice/src/core/options/options_extensions.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';
import 'package:lattice/src/core/debug/flow_canvas_debug.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/models/node_props.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/nodes/domain/node_render_layer.dart';
import 'package:lattice/src/features/nodes/presentation/node_drag_pan_gesture_recognizer.dart';
import 'package:lattice/src/features/nodes/presentation/unbounded_raw_gesture_detector.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Dedupes [FlowNodesLayer] interaction logs when only unrelated state flickers.
String _fcLastNodesLayerLogSig = '';

class NodeKeys extends Equatable {
  final Map<String, int> nodes;

  const NodeKeys({required this.nodes});

  static const _deepEq = DeepCollectionEquality.unordered();

  @override
  List<Object?> get props => [_deepEq.hash(nodes)];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NodeKeys && _deepEq.equals(nodes, other.nodes);

  @override
  int get hashCode => _deepEq.hash(nodes);
}

/// Provider that rebuilds only when the *structure* of the node list changes
/// (nodes added/removed or z-index changed). Position updates during dragging
/// do NOT trigger a layer rebuild — individual [_NodeWidget]s handle that.
final nodesProvider = Provider<NodeKeys>((ref) {
  final nodes = ref.watch(internalControllerProvider.select((s) => s.nodes));
  final nodesMap = nodes.map((key, value) => MapEntry(key, value.zIndex));
  return NodeKeys(nodes: nodesMap);
});

/// Renders nodes for a single [NodeRenderLayer] band.
///
/// Within the band, paint order follows Lattice: ascending `zIndex`, with an
/// optional +[kSelectedNodeZBoost] when [NodeOptions.elevateNodesOnSelected].
class FlowNodesLayer extends ConsumerWidget {
  const FlowNodesLayer({
    super.key,
    this.layer = NodeRenderLayer.middle,
  });

  final NodeRenderLayer layer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(internalControllerProvider
        .select((state) => '${state.nodes.length}-${state.maxZIndex}'));

    final vpOpts = context.flowCanvasOptions.viewportOptions;
    final elevateOnSelect =
        context.flowCanvasOptions.nodeOptions.elevateNodesOnSelected;

    // selectedNodes: z-order / keep-mounted when culling.
    // Do not watch dragMode or InteractionSession here — remounts kill pans.
    ref.watch(internalControllerProvider
        .select((s) => Set<String>.from(s.selectedNodes)));

    final notifier = ref.read(internalControllerProvider.notifier);
    final outer = ref.read(internalControllerProvider);

    // Keep ListenableBuilder mounted always when culling — toggling it with
    // dragMode remounted nodes and broke in-flight pans.
    final wrapTransformListener = vpOpts.onlyRenderVisibleElements &&
        outer.viewportSize != null &&
        !outer.viewportSize!.isEmpty;

    Widget buildStack() {
      final state = ref.read(internalControllerProvider);
      var entries = state.nodes.entries
          .where((e) => e.value.renderLayer == layer)
          .toList()
        ..sort((a, b) {
          final za = _effectiveZ(
            a.value,
            selected: state.selectedNodes.contains(a.key),
            elevateOnSelect: elevateOnSelect,
          );
          final zb = _effectiveZ(
            b.value,
            selected: state.selectedNodes.contains(b.key),
            elevateOnSelect: elevateOnSelect,
          );
          final cmp = za.compareTo(zb);
          if (cmp != 0) return cmp;
          return a.key.compareTo(b.key);
        });

      if (entries.isEmpty) return const SizedBox.shrink();

      final dragging = notifier.interactionSession.draggingNodeIds;

      // Do not cull while dragging nodes: the spatial index is deferred until
      // drag-end, so a spatial query mid-drag can drop widgets that are still
      // on screen (looks "stuck" / unclickable once the element is gone).
      final allowCull = vpOpts.onlyRenderVisibleElements &&
          state.dragMode != DragMode.node &&
          state.dragMode != DragMode.connection;

      if (allowCull &&
          state.viewportSize != null &&
          !state.viewportSize!.isEmpty) {
        final rect = computeVisibleFlowRectFromCanvasTransform(
          notifier.transformationController.value,
          state.viewportSize!,
          padding: vpOpts.renderCullingPadding + vpOpts.nodeMountExtraPadding,
        );

        final spatialIds = notifier.visibleCullCache.resolve(
          visibleRect: rect,
          spatialVersion: notifier.spatialVersion,
          query: (queryRect) =>
              notifier.spatialIndex.nodeIndex.queryNodesInRect(queryRect),
        );

        entries = entries.where((e) {
          if (state.selectedNodes.contains(e.key) ||
              dragging.contains(e.key)) {
            return true;
          }
          // Prefer spatial hits; fall back to Freezed AABB so a desynced
          // index cannot leave a visible node unmounted/unclickable.
          if (spatialIds.contains(e.key)) return true;
          return flowNodeOverlapsRect(e.value, rect, state.nodes);
        }).toList();
      }

      if (kDebugMode) {
        FlowCanvasDebug.countNodesBuilt(entries.length);
        if (FlowCanvasDebug.logInteraction) {
          final mountedIds = entries.map((e) => e.key).toList()..sort();
          final sig =
              '${layer.name}|${state.dragMode}|${mountedIds.length}|${notifier.liveViewport.zoom.toStringAsFixed(3)}';
          if (sig != _fcLastNodesLayerLogSig) {
            _fcLastNodesLayerLogSig = sig;
            FlowCanvasDebug.interaction(
              'FlowNodesLayer(${layer.name}) mounted=${entries.length}',
              'dragMode=${state.dragMode} selected=${state.selectedNodes.length}',
            );
          }
        }
      }

      return UnboundedRepaintBoundary(
        child: InfiniteHitTestStack(
          children: [
            for (final entry in entries)
              _NodeWidget(
                key: ValueKey('${layer.name}_${entry.key}'),
                nodeId: entry.key,
              ),
          ],
        ),
      );
    }

    if (wrapTransformListener) {
      return ListenableBuilder(
        listenable: notifier.transformationController,
        builder: (context, _) => buildStack(),
      );
    }
    return buildStack();
  }

  static int _effectiveZ(
    FlowNode node, {
    required bool selected,
    required bool elevateOnSelect,
  }) {
    final boost =
        (selected && elevateOnSelect) ? kSelectedNodeZBoost : 0;
    return node.zIndex + boost;
  }
}

/// Handles gestures and position for a single node.
///
/// Does not watch selection/hover — those rebuild [_NodeBody] / resizer only,
/// so the pan recognizer stays alive across select-on-pointer-down.
class _NodeWidget extends ConsumerWidget {
  final String nodeId;

  const _NodeWidget({
    super.key,
    required this.nodeId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(
      internalControllerProvider.select(
        (state) => state.nodes[nodeId],
      ),
    );

    if (node == null) return const SizedBox.shrink();

    // Rebuild when ancestor geometry changes (Lattice relative children).
    // Intentionally excludes selection so the pan recognizer is not remounted.
    ref.watch(internalControllerProvider.select((state) {
      final parts = <Object?>[];
      String? id = nodeId;
      final seen = <String>{};
      while (id != null && seen.add(id)) {
        final n = state.nodes[id];
        if (n == null) break;
        parts.add(n.position.dx);
        parts.add(n.position.dy);
        parts.add(n.size.width);
        parts.add(n.size.height);
        id = n.parentId;
      }
      return Object.hashAll(parts);
    }));

    final controller = ref.read(internalControllerProvider.notifier);
    final nodesController = controller.nodes;
    final session = controller.interactionSession;

    final baseOptions = context.flowCanvasOptions.nodeOptions;
    final options = baseOptions.copyWith(
      draggable: node.draggable,
      hidden: node.hidden,
      selectable: node.selectable,
      hoverable: node.hoverable,
      resizable: node.resizable,
    );

    if (options.hidden) return const SizedBox.shrink();

    final isSelectable = options.selectable;
    final isDraggable = options.draggable;
    final isResizable = options.resizable;

    // Gesture detector is stable across selection (body rebuilds separately).
    // The sized box lives inside the session ListenableBuilder below so an
    // expandParent-grown parent resizes live while its child is dragged.
    final gestureChild = UnboundedRepaintBoundary(
      child: InfiniteHitTestStack(
        clipBehavior: Clip.none,
        children: [
          NodeDragShell(
            child: UnboundedRawGestureDetector(
              behavior: HitTestBehavior.opaque,
              gestures: <Type, GestureRecognizerFactory>{
                if (isDraggable)
                  NodeDragPanGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                          NodeDragPanGestureRecognizer>(
                    () => NodeDragPanGestureRecognizer(),
                    (recognizer) {
                      recognizer
                        ..dragStartBehavior = DragStartBehavior.start
                        ..onStart = (details) {
                          nodesController.onNodeDragStart(
                            nodeId,
                            details,
                            isSelectable,
                          );
                        }
                        ..onUpdate = nodesController.onNodeDragUpdate
                        ..onEnd = nodesController.onNodeDragEnd
                        ..onCancel = nodesController.onNodePanCancel;
                    },
                  ),
                if (isSelectable)
                  TapGestureRecognizer: GestureRecognizerFactoryWithHandlers<
                      TapGestureRecognizer>(
                    () => TapGestureRecognizer(),
                    (recognizer) {
                      recognizer.onTapDown = (details) {
                        nodesController.onNodeTap(
                          nodeId,
                          details,
                          isSelectable,
                        );
                      };
                    },
                  ),
              },
              child: _NodeBody(nodeId: nodeId),
            ),
          ),
          if (isResizable) _NodeResizerSlot(nodeId: nodeId),
        ],
      ),
    );

    return ListenableBuilder(
      listenable: session,
      child: gestureChild,
      builder: (context, child) {
        final nodes = ref.read(internalControllerProvider).nodes;
        final absolute = NodeLayout.absolutePosition(
          nodeId,
          nodes,
          livePositions: session.isActive ? session.livePositions : null,
        );
        final size = session.liveSizes[nodeId] ?? node.size;
        return Positioned(
          left: absolute.dx,
          top: absolute.dy,
          child: UnboundedSizedBox(
            height: size.height,
            width: size.width,
            child: child!,
          ),
        );
      },
    );
  }
}

/// Node chrome / custom builder — may rebuild on select/hover/drag flags.
class _NodeBody extends ConsumerWidget {
  const _NodeBody({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = ref.watch(
      internalControllerProvider.select((s) => s.nodes[nodeId]),
    );
    if (node == null) return const SizedBox.shrink();

    final isSelected = ref.watch(
      internalControllerProvider.select(
        (s) => s.selectedNodes.contains(nodeId),
      ),
    );
    final runtime = ref.watch(
      internalControllerProvider.select(
        (s) => s.nodeStates[nodeId] ?? const NodeRuntimeState(),
      ),
    );

    return ref.read(nodeRegistryProvider).buildWidget(
          NodeProps.fromNode(
            node,
            selected: isSelected || runtime.selected,
            dragging: runtime.dragging,
            hovered: runtime.hovered,
          ),
        );
  }
}

class _NodeResizerSlot extends ConsumerWidget {
  const _NodeResizerSlot({required this.nodeId});

  final String nodeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(
      internalControllerProvider.select(
        (s) => s.selectedNodes.contains(nodeId),
      ),
    );
    if (!selected) return const SizedBox.shrink();
    return FlowNodeResizer(nodeId: nodeId);
  }
}
