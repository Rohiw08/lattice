import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/options/components/edge_options.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';

/// Keyboard focus + screen-reader anchors for edges.
///
/// Edges paint inside an [IgnorePointer] layer, so this sibling overlay
/// places one transparent 32×32 anchor per visible, focusable edge at its
/// path midpoint (≈ React Flow edge focusability):
/// - Tab reaches the anchor; Enter/Space selects the edge.
/// - Screen readers announce the edge label + selected state.
/// - Anchors are [IgnorePointer]-wrapped: pointer behavior is unchanged.
///
/// Anchors rebuild on edge-set, selection, and geometry changes only.
class EdgeA11yLayer extends ConsumerWidget {
  const EdgeA11yLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    final edges = ref.watch(
      internalControllerProvider.select((s) => s.edges),
    );
    ref.watch(
      internalControllerProvider.select((s) => s.geometryRevision),
    );
    // Set-identity watch (not epoch): edge anchors only depend on edge
    // selection, and the set instance changes only on real edge-selection
    // changes — node-selection emissions skip this layer entirely.
    final selected = ref.watch(
      internalControllerProvider.select((s) => s.selectedEdges),
    );
    // Pan/zoom must add anchors for edges scrolled into view: their geometry
    // is demand-filled (lazy mount), and no provider emission fires on a pure
    // camera move — so the layer also listens to the live matrix when culling
    // is on. Without culling the eager fill covers everything.
    final cullOn = ref
        .read(flowOptionsProvider)
        .viewportOptions
        .onlyRenderVisibleElements;
    // Rebuild when the pane size lands (post-frame) so frame-1 anchors
    // resolve even if this layer built before the edge layer's cull fill.
    ref.watch(
      internalControllerProvider.select((s) => s.viewportSize),
    );

    Widget buildAnchors() {
      final state = controller.currentState;
      // Visible-subset demand fill (NOT ensure-all: that would recompute
      // every offscreen edge and defeat the lazy mount). Endpoints decide
      // visibility without geometry; only survivors compute.
      if (cullOn) {
        final size = state.viewportSize;
        if (size != null && !size.isEmpty) {
          final opts = ref.read(flowOptionsProvider);
          final rect = computeVisibleFlowRectFromCanvasTransform(
            controller.transformationController.value,
            size,
            padding: opts.viewportOptions.renderCullingPadding,
          );
          final origin = opts.nodeOptions.nodeOrigin;
          final visibleIds = <String>[];
          for (final entry in edges.entries) {
            final s = state.nodes[entry.value.sourceNodeId];
            final t = state.nodes[entry.value.targetNodeId];
            if (s == null || t == null) {
              visibleIds.add(entry.key);
              continue;
            }
            if (flowNodeOverlapsRect(s, rect, state.nodes,
                    defaultOrigin: origin) ||
                flowNodeOverlapsRect(t, rect, state.nodes,
                    defaultOrigin: origin)) {
              visibleIds.add(entry.key);
            }
          }
          controller.edgeGeometryService.ensureGeoms(
            state,
            visibleIds,
            defaultOrigin: origin,
          );
        }
      }
      const anchorSize = 32.0;
      final anchors = <Widget>[];
      for (final entry in edges.entries) {
        final edge = entry.value;
        if (edge.isHidden(context) || !edge.isFocusable(context)) continue;
        final geom = controller.edgeGeometryService.getGeom(entry.key);
        if (geom == null) continue;
        final center = geom.bounds.center;
        anchors.add(
          Positioned(
            left: center.dx - anchorSize / 2,
            top: center.dy - anchorSize / 2,
            width: anchorSize,
            height: anchorSize,
            child: IgnorePointer(
              child: _EdgeA11yAnchor(
                key: ValueKey('edge-a11y-${entry.key}'),
                edgeId: entry.key,
                selected: selected.contains(entry.key),
              ),
            ),
          ),
        );
      }
      if (anchors.isEmpty) return const SizedBox.shrink();
      return Stack(children: anchors);
    }

    if (!cullOn) return buildAnchors();
    return ListenableBuilder(
      listenable: controller.transformationController,
      builder: (context, _) => buildAnchors(),
    );
  }
}

class _EdgeA11yAnchor extends ConsumerStatefulWidget {
  const _EdgeA11yAnchor({
    super.key,
    required this.edgeId,
    required this.selected,
  });

  final String edgeId;
  final bool selected;

  @override
  ConsumerState<_EdgeA11yAnchor> createState() => _EdgeA11yAnchorState();
}

class _EdgeA11yAnchorState extends ConsumerState<_EdgeA11yAnchor> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'flow-edge-${widget.edgeId}');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
    final edge = controller.currentState.edges[widget.edgeId];
    final edgeOptions = ref.read(flowOptionsProvider).edgeOptions;
    if (edge == null || !(edge.selectable ?? edgeOptions.selectable)) {
      return KeyEventResult.ignored;
    }
    if (widget.selected &&
        controller.currentState.selectedNodes.isEmpty &&
        controller.currentState.selectedEdges.length == 1) {
      return KeyEventResult.handled;
    }
    controller.selection.selectEdge(widget.edgeId);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final edge = ref.watch(
      internalControllerProvider.select((s) => s.edges[widget.edgeId]),
    );
    if (edge == null) return const SizedBox.shrink();
    final hint = ref.watch(
      flowOptionsProvider.select((o) => o.a11yOptions.labels.edgeSelectHint),
    );
    final selectable = edge.isSelectable(context);
    final label = edge.semanticsLabel;
    final resolvedLabel =
        (label != null && label.isNotEmpty) ? label : 'Edge ${edge.id}';

    return Focus(
      focusNode: _focusNode,
      // No framework Semantics wrapper: the explicit Semantics below
      // already describes this anchor (avoids doubled announcements).
      includeSemantics: false,
      onFocusChange: (focused) {
        if (mounted) setState(() => _focused = focused);
      },
      onKeyEvent: _handleKey,
      child: Semantics(
        label: resolvedLabel,
        hint: selectable ? hint : null,
        selected: widget.selected,
        focused: _focused,
        container: true,
        onTap: selectable
            ? () => ref
                .read(internalControllerProvider.notifier)
                .selection
                .selectEdge(widget.edgeId)
            : null,
        child: const SizedBox.expand(),
      ),
    );
  }
}
