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
import 'package:lattice/src/features/nodes/presentation/flow_focusable_node.dart';
import 'package:lattice/src/features/nodes/presentation/flow_interaction.dart';
import 'package:lattice/src/features/nodes/presentation/node_drag_pan_gesture_recognizer.dart';
import 'package:lattice/src/features/nodes/presentation/nodes_thumbnail_layer.dart';
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
class FlowNodesLayer extends ConsumerStatefulWidget {
  const FlowNodesLayer({
    super.key,
    this.layer = NodeRenderLayer.middle,
    this.layoutSize,
  });

  final NodeRenderLayer layer;

  /// Finite pane size from the surrounding [LayoutBuilder], used as the cull
  /// fallback on the first frame before `state.viewportSize` is seeded
  /// post-frame. Without it, culling can't engage until frame 2, so all nodes
  /// mount on the initial frame. Null-safe: culling still guards on emptiness.
  final Size? layoutSize;

  @override
  ConsumerState<FlowNodesLayer> createState() => _FlowNodesLayerState();
}

class _FlowNodesLayerState extends ConsumerState<FlowNodesLayer> {
  NodeRenderLayer get layer => widget.layer;

  /// Stable [_NodeWidget] instances per node id (invariant #6, one level up:
  /// identical instances short-circuit parent-driven cascades).
  ///
  /// A layer rebuild (e.g. a selection toggle) otherwise mints N fresh
  /// widgets, forcing N element updates + `didUpdateWidget` cascades
  /// (gesture-shell resyncs) even when nothing about the node changed.
  /// Cached instances make the cascade a no-op: the child's own fine-grained
  /// watches still rebuild exactly the affected bodies. Evicted when the id
  /// leaves this render layer so removed nodes don't leak.
  final Map<String, _NodeWidget> _widgets = {};

  /// Ids kept by the last *normal* (non-drag) cull for this layer. Frozen at
  /// drag-start and reused for the whole node drag so culling stays on without
  /// re-querying the (mid-drag stale) spatial index. Prevents the drag-start
  /// mass-mount: without it, disabling culling on drag mounted all N nodes in
  /// one pump. See the drag-freeze branch in `buildStack`.
  Set<String> _lastCulledIds = const {};

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    ref.watch(internalControllerProvider
        .select((state) => '${state.nodes.length}-${state.maxZIndex}'));

    final vpOpts = context.flowCanvasOptions.viewportOptions;
    final elevateOnSelect =
        context.flowCanvasOptions.nodeOptions.elevateNodesOnSelected &&
            context.flowCanvasOptions.zIndexMode != ZIndexMode.manual;

    // Thumbnail LOD: below the threshold the middle band paints every node
    // as a rect instead of mounting widgets; other bands stand down.
    final thumbnailBelowZoom = vpOpts.lodThumbnailBelowZoom;
    if (thumbnailBelowZoom != null) {
      final zoom = ref.watch(
        internalControllerProvider.select((s) => s.viewport.zoom),
      );
      if (zoom < thumbnailBelowZoom) {
        if (layer != NodeRenderLayer.middle) {
          return const SizedBox.shrink();
        }
        return const NodesThumbnailLayer();
      }
    }

    // selectedNodes: z-order / keep-mounted when culling.
    // Do not watch dragMode or InteractionSession here — remounts kill pans.
    // NOTE: select the set itself (stable identity across emissions), never
    // a fresh copy — a new collection would fail `==` every time and rebuild
    // the whole layer on each state change.
    ref.watch(internalControllerProvider
        .select((s) => s.selectedNodes));

    final notifier = ref.read(internalControllerProvider.notifier);

    // Keep ListenableBuilder mounted always when culling — toggling it with
    // dragMode remounted nodes and broke in-flight pans.
    // NOTE: keyed on the *option* only, never on viewportSize/dragMode.
    // Conditioning the wrapper on viewportSize reintroduced the forbidden
    // toggle on pre-layout builds: the wrapper flip wholesale-unmounted all
    // node shells mid-gesture (in-flight recognizers disposed, moves/up
    // lost, drag stuck in DragMode.node). The cull filter inside buildStack
    // keeps its own null/empty viewportSize guard, so mounting the listener
    // early is safe.
    final wrapTransformListener = vpOpts.onlyRenderVisibleElements;

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

      if (entries.isEmpty) {
        _widgets.clear();
        return const SizedBox.shrink();
      }

      // Evict widgets for nodes that left this render layer; reuse stable
      // instances for the rest so cascades skip unchanged nodes entirely.
      final ids = entries.map((e) => e.key).toSet();
      _widgets.removeWhere((id, _) => !ids.contains(id));
      for (final entry in entries) {
        _widgets.putIfAbsent(
          entry.key,
          () => _NodeWidget(
            key: ValueKey('${layer.name}_${entry.key}'),
            nodeId: entry.key,
          ),
        );
      }

      final session = notifier.interactionSession;
      final dragging = session.draggingNodeIds;

      // Fall back to the LayoutBuilder size on the first frame, before
      // `viewportSize` is seeded post-frame (see [FlowNodesLayer.layoutSize]).
      final size = state.viewportSize ?? widget.layoutSize;
      final cullEnabled =
          vpOpts.onlyRenderVisibleElements && size != null && !size.isEmpty;

      if (cullEnabled && state.dragMode == DragMode.node) {
        // Drag freeze: keep culling on but do NOT query the spatial index —
        // it holds stale pre-drag positions until drag-end, so a mid-drag
        // query could drop still-visible widgets. Reuse the pre-drag visible
        // set plus the ids whose visuals move this drag (roots + descendants,
        // via [InteractionSession.dragAffected]) plus the selection. This
        // avoids the drag-start mass-mount (previously all N mounted at once
        // when culling was disabled wholesale on drag).
        final keep = <String>{
          ..._lastCulledIds,
          ...session.dragAffected,
          ...dragging,
          ...state.selectedNodes,
        };
        entries = entries.where((e) => keep.contains(e.key)).toList();
      } else if (cullEnabled && state.dragMode != DragMode.connection) {
        final rect = computeVisibleFlowRectFromCanvasTransform(
          notifier.transformationController.value,
          size,
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
          return flowNodeOverlapsRect(
              e.value, rect, state.nodes,
              defaultOrigin:
                  context.flowCanvasOptions.nodeOptions.nodeOrigin);
        }).toList();

        // Freeze this layer's visible set for the next drag-start.
        _lastCulledIds = entries.map((e) => e.key).toSet();
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
            for (final entry in entries) _widgets[entry.key]!,
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

/// Ancestor geometry hash for [nodeId] (Lattice relative children ride along
/// when an ancestor moves/resizes). Excludes selection/hover/runtime so
/// gesture recognizers are not remounted by unrelated state changes.
int _ancestorHash(Map<String, FlowNode> nodes, String nodeId) {
  final parts = <Object?>[];
  String? id = nodeId;
  final seen = <String>{};
  while (id != null && seen.add(id)) {
    final n = nodes[id];
    if (n == null) break;
    parts.add(n.position.dx);
    parts.add(n.position.dy);
    parts.add(n.size.width);
    parts.add(n.size.height);
    parts.add(n.origin);
    id = n.parentId;
  }
  return Object.hashAll(parts);
}

/// Handles gestures and position for a single node.
///
/// Does not watch selection/hover — those rebuild [_NodeBody] / resizer only,
/// so the pan recognizer stays alive across select-on-pointer-down.
///
/// Stateful purely to hold stable child instances ([_NodeBody],
/// [_NodeResizerSlot]): passing the identical instance down lets the child
/// element skip parent-driven cascades, while their own fine-grained watches
/// still rebuild them exactly when their inputs change. Without this, every
/// layer rebuild (e.g. a selection toggle) rebuilds all N node contents.
class _NodeWidget extends ConsumerStatefulWidget {
  final String nodeId;

  const _NodeWidget({
    super.key,
    required this.nodeId,
  });

  @override
  ConsumerState<_NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends ConsumerState<_NodeWidget> {
  late final _body = _NodeBody(nodeId: widget.nodeId);
  late final _resizer = _NodeResizerSlot(nodeId: widget.nodeId);

  /// Cached session scope (see `InteractionSession.scopeFor`). A fresh scope
  /// per build would resubscribe on the session on every layer rebuild —
  /// resubscribe scans the O(N) listener list, turning each cascade O(N^2).
  /// Refreshed only if the session object itself is swapped.
  Object? _scopeSession;
  Listenable? _scope;

  /// Cached gesture shell (see [_NodeWidgetState] docs): recognizer factories
  /// compare by identity, so a fresh shell per build would dispose + recreate
  /// every recognizer on each layer cascade. Refreshed only when capability
  /// flags change, so callbacks never go stale.
  Widget? _gestureShell;
  (bool, bool, bool)? _gestureFlags;

  String get nodeId => widget.nodeId;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    // Single subscription: node record + ancestor geometry hash (Lattice
    // relative children). One select instead of two halves the per-emission
    // subscription tax across N shells; rebuild semantics are identical.
    final record = ref.watch(
      internalControllerProvider.select(
        (state) => (state.nodes[nodeId], _ancestorHash(state.nodes, nodeId)),
      ),
    );
    final node = record.$1;

    if (node == null) return const SizedBox.shrink();

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

    // Gesture shell is stable across selection (body rebuilds separately).
    // The sized box lives inside the session ListenableBuilder below so an
    // expandParent-grown parent resizes live while its child is dragged.
    final gestureFlags = (isSelectable, isDraggable, isResizable);
    if (_gestureShell == null || _gestureFlags != gestureFlags) {
      _gestureFlags = gestureFlags;
      _gestureShell = UnboundedRepaintBoundary(
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
                      // Space-pan owns the pointer: skip node drag so the
                      // viewport pan wins the arena (evaluated per pointer;
                      // assigned outside the cascade below on purpose).
                      recognizer.shouldYieldPointer = () => ref
                          .read(flowOptionsProvider)
                          .keyboardOptions
                          .isPanActivationHeld;
                      recognizer.shouldBlockDragStart = (event) {
                        final gated = ref
                                .read(internalControllerProvider)
                                .nodes[nodeId]
                                ?.dragHandle ??
                            false;
                        if (!gated) return false;
                        return !FlowInteraction.isDragHandleAt(event.position);
                      };
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
              child: _body,
            ),
          ),
          if (isResizable) _resizer,
        ],
      ),
    );
    }
    final gestureChild = _gestureShell!;

    // Per-node session scope: only this node (and its dragged descendants)
    // rebuild on gesture ticks; static siblings skip the tick entirely.
    // Global session listeners (edge layers, minimap, toolbars) are separate.
    // The scope is cached (not rebuilt per build) so layer cascades don't
    // churn session subscriptions.
    if (!identical(session, _scopeSession)) {
      _scopeSession = session;
      _scope = session.scopeFor(nodeId);
    }
    return ListenableBuilder(
      listenable: _scope!,
      child: gestureChild,
      builder: (context, child) {
        final nodes = ref.read(internalControllerProvider).nodes;
        // Visual top-left: the stored anchor minus this node's origin shift
        // (identical to the anchor when the origin is top-left).
        final topLeft = NodeLayout.absoluteTopLeft(
          nodeId,
          nodes,
          livePositions: session.isActive ? session.livePositions : null,
          defaultOrigin: baseOptions.nodeOrigin,
        );
        final size = session.liveSizes[nodeId] ?? node.size;
        return Positioned(
          left: topLeft.dx,
          top: topLeft.dy,
          child: FlowFocusableNode(
            nodeId: nodeId,
            child: UnboundedSizedBox(
              height: size.height,
              width: size.width,
              child: child!,
            ),
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
    // Single subscription for node + selection + runtime (see _NodeWidgetState
    // docs): same rebuild decisions as three separate selects, one third of
    // the per-emission subscription tax.
    final record = ref.watch(
      internalControllerProvider.select(
        (s) => (
          s.nodes[nodeId],
          s.selectedNodes.contains(nodeId),
          s.nodeStates[nodeId] ?? const NodeRuntimeState(),
        ),
      ),
    );
    final node = record.$1;
    if (node == null) return const SizedBox.shrink();

    final isSelected = record.$2;
    final runtime = record.$3;

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
