import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';

/// In-node-field focus observer for one node.
///
/// Node focus, semantics, the focus ring, and Tab traversal live in
/// [FlowNodeA11yLayer] (an always-mounted sibling proxy layer), so this shell
/// no longer owns a traversable `FocusNode`. It exists only to preserve one
/// behavior that the proxy cannot: when a widget *inside* a custom node body
/// (e.g. a `TextField`) takes focus, an offscreen node should still pan into
/// view (`A11yOptions.autoPanOnNodeFocus`).
///
/// That works because this [Focus] is an **ancestor** of the node child, so
/// descendant-focus bubbles to [Focus.onFocusChange] here. It is
/// non-traversable (`canRequestFocus: false`, `skipTraversal: true`) and
/// carries no semantics/label, so it is never itself a Tab stop and does not
/// collide with the proxy's `flow-node-<id>` focus node.
///
/// Because it never wraps/unwraps a ring, node content is not remounted on
/// focus changes — in-node State (text controllers, field focus, scroll) is
/// preserved without any reparenting trick.
class FlowFocusableNode extends ConsumerWidget {
  const FlowFocusableNode({
    super.key,
    required this.nodeId,
    required this.child,
  });

  final String nodeId;
  final Widget child;

  void _handleFocusChange(WidgetRef ref, String nodeId, bool focused) {
    if (!focused) return;
    final options = ref.read(flowOptionsProvider);
    if (!options.a11yOptions.autoPanOnNodeFocus) return;
    final controller = ref.read(internalControllerProvider.notifier);
    final state = controller.currentState;
    final node = state.nodes[nodeId];
    if (node == null) return;
    // Pan only when the node is actually offscreen. Pointer focus always
    // lands on visible content (tapping it proves it), so an unconditional
    // pan just shoves the canvas out from under the user's finger — and the
    // resulting viewport churn used to remount in-node fields, eating focus
    // and typed text.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Observer only: never focusable, never traversable, no semantics.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) => _handleFocusChange(ref, nodeId, focused),
      child: child,
    );
  }
}
