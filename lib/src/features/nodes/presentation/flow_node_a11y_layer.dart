import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';

/// Keyboard focus + screen-reader anchors for nodes.
///
/// Node *bodies* are culled: only the on-screen band mounts (see
/// `onlyRenderVisibleElements`). Keyboard traversal must still reach every
/// node — including offscreen ones — and pan them into view, so this sibling
/// overlay mounts one lightweight, always-present proxy per node at its
/// absolute flow rect. Focus ownership lives here, not in the (culled) body,
/// so there is exactly **one** traversable `FocusNode` per node regardless of
/// culling. This mirrors [EdgeA11yLayer], which mounts one focus anchor per
/// edge.
///
/// Each proxy:
/// - is the Tab stop (`flow-node-<id>`); Enter/Space selects the node.
/// - pans the node into view on focus when offscreen (`autoPanOnNodeFocus`).
/// - exposes label / hint / selected / focusable to screen readers.
/// - draws the focus ring (the body no longer does).
///
/// Proxies are [IgnorePointer]-wrapped: pointer behavior (drag/select/hover on
/// the real body) is unchanged. Positioned at the node rect so Flutter's
/// default reading-order traversal walks nodes spatially.
class FlowNodeA11yLayer extends ConsumerWidget {
  const FlowNodeA11yLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuild on node-set (add/remove/move/resize) and selection only.
    final nodes = ref.watch(
      internalControllerProvider.select((s) => s.nodes),
    );
    final defaultOrigin =
        ref.watch(flowOptionsProvider.select((o) => o.nodeOptions.nodeOrigin));

    final anchors = <Widget>[];
    for (final entry in nodes.entries) {
      final node = entry.value;
      if (node.isHidden(context)) continue;
      final rect = NodeLayout.absoluteRect(
        node,
        nodes,
        defaultOrigin: defaultOrigin,
      );
      anchors.add(
        UnboundedPositioned(
          left: rect.left,
          top: rect.top,
          width: rect.width,
          height: rect.height,
          child: IgnorePointer(
            child: _NodeA11yAnchor(
              key: ValueKey('node-a11y-${entry.key}'),
              nodeId: entry.key,
            ),
          ),
        ),
      );
    }
    if (anchors.isEmpty) return const SizedBox.shrink();
    return InfiniteHitTestStack(clipBehavior: Clip.none, children: anchors);
  }
}

class _NodeA11yAnchor extends ConsumerStatefulWidget {
  const _NodeA11yAnchor({super.key, required this.nodeId});

  final String nodeId;

  @override
  ConsumerState<_NodeA11yAnchor> createState() => _NodeA11yAnchorState();
}

class _NodeA11yAnchorState extends ConsumerState<_NodeA11yAnchor> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'flow-node-${widget.nodeId}');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Label precedence: explicit semanticsLabel → String data → id.
  static String resolveLabel(FlowNode node) {
    final explicit = node.semanticsLabel;
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final data = node.data;
    if (data is String && data.isNotEmpty) return data;
    return node.id;
  }

  void _handleFocusChange(bool focused) {
    if (!mounted) return;
    setState(() => _focused = focused);
    if (!focused) return;
    final options = ref.read(flowOptionsProvider);
    if (!options.a11yOptions.autoPanOnNodeFocus) return;
    final controller = ref.read(internalControllerProvider.notifier);
    final state = controller.currentState;
    final node = state.nodes[widget.nodeId];
    if (node == null) return;
    // Pan only when the node is actually offscreen — a keyboard Tab may land
    // on a node already in view, and panning it would shove the canvas for
    // no reason.
    final rect = NodeLayout.absoluteRect(node, state.nodes,
        defaultOrigin: options.nodeOptions.nodeOrigin);
    final visible = computeVisibleFlowRect(state);
    final fullyVisible = visible.left <= rect.left &&
        visible.top <= rect.top &&
        visible.right >= rect.right &&
        visible.bottom >= rect.bottom;
    if (fullyVisible) return;
    controller.viewport.centerOnPosition(rect.center);
  }

  KeyEventResult _handleKey(FocusNode focusNode, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (!focusNode.hasPrimaryFocus) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final isConfirm = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
    if (!isConfirm) return KeyEventResult.ignored;

    final controller = ref.read(internalControllerProvider.notifier);
    final state = controller.currentState;
    final node = state.nodes[widget.nodeId];
    final nodeOptions = ref.read(flowOptionsProvider).nodeOptions;
    if (node == null || !(node.selectable ?? nodeOptions.selectable)) {
      return KeyEventResult.ignored;
    }
    // Already the exclusive selection — skip the redundant history entry.
    if (state.selectedNodes.length == 1 &&
        state.selectedNodes.contains(widget.nodeId) &&
        state.selectedEdges.isEmpty) {
      return KeyEventResult.handled;
    }
    controller.selection.selectNode(widget.nodeId);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    // Single subscription for node + selection (invariant #6 pattern: same
    // rebuild decisions as two separate selects, half the per-emission
    // subscription tax across N anchors).
    final record = ref.watch(
      internalControllerProvider.select(
        (s) => (
          s.nodes[widget.nodeId],
          s.selectedNodes.contains(widget.nodeId),
        ),
      ),
    );
    final node = record.$1;
    if (node == null) return const SizedBox.shrink();

    final focusable = node.isFocusable(context) && !node.isHidden(context);
    final selected = record.$2;
    final hint = ref.watch(
      flowOptionsProvider.select((o) => o.a11yOptions.labels.nodeSelectHint),
    );
    final selectable = node.isSelectable(context);

    Widget ring = const SizedBox.expand();
    if (_focused && focusable) {
      ring = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        child: ring,
      );
    }

    return Focus(
      focusNode: _focusNode,
      skipTraversal: !focusable,
      // Explicit UnboundedSemantics below owns the surface (avoids doubled
      // announcements from a framework Semantics wrapper).
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKey,
      child: UnboundedSemantics(
        label: resolveLabel(node),
        hint: selectable ? hint : null,
        selected: selected,
        // Non-null `focused` advertises focusability (null = not focusable).
        focused: focusable ? _focused : null,
        container: true,
        onTap: selectable
            ? () => ref
                .read(internalControllerProvider.notifier)
                .selection
                .selectNode(widget.nodeId)
            : null,
        child: ring,
      ),
    );
  }
}
