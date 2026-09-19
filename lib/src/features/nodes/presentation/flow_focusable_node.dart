import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';

/// Keyboard focus + screen-reader shell for one node.
///
/// Wired automatically by [_NodeWidget] — custom node builders get it for
/// free, matching the guidance that builders should not manage focus or
/// semantics themselves (only their *inner* interactive elements, if any).
///
/// Behavior (≈ Lattice a11y):
/// - Tab reaches the node when it is focusable (`FlowNode.focusable` over
///   `NodeOptions.focusable`; hidden nodes never). Traversal order is spatial
///   (reading order), not DOM order.
/// - Enter/Space selects the node (idempotent — no history spam on repeat).
/// - Focusing pans the node into view when
///   `A11yOptions.autoPanOnNodeFocus` is on — but only when the node is
///   actually offscreen. A tapped node is visible by definition, so pointer
///   focus never moves the camera (and never disturbs in-node fields).
/// - Exposes label (model → String data → id), selected state, and tap
///   action to screen readers; draws a focus ring while focused. The ring
///   appears/disappears without remounting node content (a stable [GlobalKey]
///   reparents the subtree), so focus changes never destroy in-node State:
///   fields keep focus + text, scroll/anim state survives.
class FlowFocusableNode extends ConsumerStatefulWidget {
  const FlowFocusableNode({
    super.key,
    required this.nodeId,
    required this.child,
  });

  final String nodeId;
  final Widget child;

  @override
  ConsumerState<FlowFocusableNode> createState() => _FlowFocusableNodeState();
}

class _FlowFocusableNodeState extends ConsumerState<FlowFocusableNode> {
  late final FocusNode _focusNode;

  /// Stable identity for the node content across focus-ring swaps.
  ///
  /// The ring wraps/unwraps [widget.child] on focus change, which would
  /// otherwise dispose + remount the whole subtree (destroying in-node
  /// State: text controllers, field focus, scroll/anim state). A stable
  /// [GlobalKey] reparents the subtree instead — State (and focus) survives.
  /// One key per node instance, so no cross-node clashes.
  late final GlobalKey _contentKey = GlobalKey();

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
    // Pan only when the node is actually offscreen. Pointer focus always
    // lands on visible content (tapping it proves it), so an unconditional
    // pan just shoves the canvas out from under the user's finger — and the
    // resulting viewport churn used to remount in-node fields, eating focus
    // and typed text. Keyboard traversal to offscreen nodes still reveals
    // them, which is the point of the option.
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
    // Only the node itself: a focused button/field inside keeps its own
    // Space/Enter behavior (text input is additionally guarded centrally).
    if (!focusNode.hasPrimaryFocus) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final isConfirm = key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space;
    if (!isConfirm) return KeyEventResult.ignored;

    final controller = ref.read(internalControllerProvider.notifier);
    final state = controller.currentState;
    final node = state.nodes[widget.nodeId];
    final nodeOptions =
        ref.read(flowOptionsProvider).nodeOptions;
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
    final node = ref.watch(
      internalControllerProvider.select((s) => s.nodes[widget.nodeId]),
    );
    if (node == null) return widget.child;

    final focusable =
        node.isFocusable(context) && !node.isHidden(context);
    final selected = ref.watch(
      internalControllerProvider
          .select((s) => s.selectedNodes.contains(widget.nodeId)),
    );
    final hint = ref.watch(
      flowOptionsProvider.select((o) => o.a11yOptions.labels.nodeSelectHint),
    );
    final selectable = node.isSelectable(context);

    // The ring wraps/unwraps on focus change; [_contentKey] keeps the subtree
    // (and its State) alive across the swap — see [_contentKey].
    final Widget content = KeyedSubtree(key: _contentKey, child: widget.child);
    Widget current = content;
    if (_focused && focusable) {
      current = DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(8)),
        ),
        position: DecorationPosition.foreground,
        child: current,
      );
    }

    return Focus(
      focusNode: _focusNode,
      skipTraversal: !focusable,
      // No framework Semantics wrapper: its render object gates hit tests
      // to the node box and would hide overflowing resize/connection
      // handles from pointers. UnboundedSemantics below covers the
      // screen-reader surface instead.
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKey,
      // Unbounded: plain Semantics would gate hit tests to the node box and
      // hide overflowing resize/connection handles from pointers.
      // `focused` doubles as the focusable advertisement (null = not
      // focusable on current Flutter semantics).
      child: UnboundedSemantics(
        label: resolveLabel(node),
        hint: selectable ? hint : null,
        selected: selected,
        focused: focusable ? _focused : null,
        container: true,
        onTap: selectable
            ? () => ref
                .read(internalControllerProvider.notifier)
                .selection
                .selectNode(widget.nodeId)
            : null,
        child: current,
      ),
    );
  }
}
