import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/handle_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/nodes/presentation/flow_no_drag.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/features/handles/domain/handle_state.dart';
import '../../../core/providers/providers.dart';

/// A builder function for creating a custom handle widget.
///
/// It receives the handle's current runtime state and the resolved `FlowHandleStyle`.
/// Passing the full style object allows the builder to use theme properties
/// (e.g., `style.hovered?.color`) to create completely custom widgets that
/// still respect the canvas theme.
typedef HandleBuilder =
    Widget Function(
      BuildContext context,
      HandleRuntimeState state,
      FlowHandleStyle style,
      HandleType type,
    );

/// A connection point on a node widget.
///
/// This widget is self-contained and communicates directly with the
/// FlowCanvasInternalController via Riverpod to manage its state (hovered, active, etc.)
/// and initiate connections. It relies on its parent widget for positioning.
///
/// Per-handle connectability (Lattice per-`Handle` `isConnectable` /
/// `isConnectableStart` / `isConnectableEnd`) resolves widget prop →
/// [FlowHandle] model → node flag. Widget props gate this handle's drag
/// start and dimming locally; landing validation and `onConnect` run in the
/// connection service, so validators and callbacks belong on the model.
class Handle extends ConsumerWidget {
  final String nodeId;
  final String handleId;
  final HandleType type;
  final Offset position;
  final Size size;
  final FlowHandleStyle? handleStyle;
  final HandleBuilder? handleBuilder;

  /// Local override for drag-start + dimming (see class docs).
  final bool? isConnectable;

  /// Local start-role override (Lattice `isConnectableStart`).
  final bool? isConnectableStart;

  /// Local end-role override (Lattice `isConnectableEnd`).
  final bool? isConnectableEnd;

  const Handle({
    super.key,
    required this.nodeId,
    required this.handleId,
    this.position = Offset.zero,
    this.size = const Size(10.0, 10.0),
    this.type = HandleType.both,
    this.handleStyle,
    this.handleBuilder,
    this.isConnectable,
    this.isConnectableStart,
    this.isConnectableEnd,
  });

  String get handleKey => '$nodeId/$handleId';

  Set<FlowHandleState> _states(
    HandleRuntimeState state, {
    required bool connectable,
  }) {
    final states = <FlowHandleState>{FlowHandleState.normal};
    if (!connectable) states.add(FlowHandleState.disabled);
    if (state.invalidTarget) states.add(FlowHandleState.invalidTarget);
    if (state.validTarget) states.add(FlowHandleState.validTarget);
    if (state.selected) states.add(FlowHandleState.selected);
    if (state.active) states.add(FlowHandleState.active);
    if (state.hovered) states.add(FlowHandleState.hovered);
    return states;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Invariant #6: merge multi-field selects into ONE record select — same
    // rebuild semantics, but a single provider subscription instead of many.
    // At 450 nodes × 2 handles the old 10-subscriptions-per-handle wired ~9000
    // subscriptions at mount; this cuts it to ~4 (2 here + LOD/notifier reads),
    // which is the bulk of the built-in-node mount cost. `effectiveHandles`
    // is read once per emission (stored map for custom handles; the getter
    // only synthesizes for built-in nodes with no explicit handles).
    final (handleState, nodeConnectable, modelHandle, interactive) = ref.watch(
      internalControllerProvider.select((s) {
        final node = s.nodes[nodeId];
        return (
          s.handleStates[handleKey] ?? const HandleRuntimeState(),
          node?.connectable,
          node?.effectiveHandles[handleId],
          s.interactive,
        );
      }),
    );
    final (
      globalConnectable,
      connectionMode,
      clickConnect,
      handleLabel,
      lodZoom
    ) = ref.watch(
      flowOptionsProvider.select(
        (o) => (
          o.nodeOptions.connectable,
          o.connectionOptions.connectionMode,
          o.connectionOptions.connectOnClick,
          // Watched (not ref.read): a runtime label change — e.g. a locale
          // switch — must rebuild mounted handles so the screen-reader label
          // never goes stale. FlowA11yLabels has identity equality, so a new
          // labels object always fires; a value-equal one is a no-op.
          o.a11yOptions.labels.handleLabel,
          // Watched for the same reason: a runtime change to the LOD-hide
          // threshold must rebuild mounted handles so they start/stop hiding.
          // Read via ref.read, a handle mounted with a null threshold would
          // never begin hiding, and one mounted with the wrapper would keep it
          // after the option was cleared.
          o.viewportOptions.lodHideHandlesBelowZoom,
        ),
      ),
    );

    // Widget prop → model → node flag → global (null props fall through).
    // Non-interactive masters everything off (Lattice setInteractive) — applied
    // uniformly, including when an explicit isConnectable override is present.
    final connectable =
        (isConnectable ??
            modelHandle?.isConnectable ??
            nodeConnectable ??
            globalConnectable) &&
        interactive;
    final startOverride =
        isConnectableStart ?? modelHandle?.isConnectableStart;
    final canStart =
        connectable &&
        (startOverride ??
            (connectionMode == ConnectionMode.loose ||
                type == HandleType.source ||
                type == HandleType.both));

    final controller = ref.read(internalControllerProvider.notifier);

    Widget buildHandle() {
      final baseTheme =
          context.flowCanvasTheme.handle ?? FlowHandleStyle.system(context);
      final theme = baseTheme.merge(handleStyle);
      final decoration = theme.resolveDecoration(
        _states(handleState, connectable: connectable),
      );
      final Widget handleCore = handleBuilder != null
          ? handleBuilder!(context, handleState, theme, type)
          : _DefaultHandle(decoration: decoration);

      // Expand hit target beyond the tiny visual so connect-drag is reliable.
      final hitW = size.width < 20 ? 20.0 : size.width;
      final hitH = size.height < 20 ? 20.0 : size.height;

      // Pointer-driven connect (not GestureDetector pan): InteractiveViewer's
      // ScaleGestureRecognizer wins the arena and would swallow onPan*.
      // FlowNoDrag: beat the parent node pan so drag-to-connect isn't stolen.
      final child = FlowNoDrag(
        child: Semantics(
          // Lattice `handle.ariaLabel` — each handle is its own node, like
          // RF's labelled handle divs.
          label: handleLabel,
          container: true,
          child: MouseRegion(
            onEnter: (_) => controller.handle.setHandleHover(handleKey, true),
            onExit: (_) => controller.handle.setHandleHover(handleKey, false),
            cursor:
                (context.flowCanvasTheme.cursor ??
                        FlowCursorStyle.system(context))
                    .handle,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (canStart || clickConnect) && connectable
                  ? (event) => controller.connection.onConnectionPointerDown(
                      nodeId,
                      handleId,
                      event,
                    )
                  : null,
              child: SizedBox(
                width: hitW,
                height: hitH,
                child: Center(
                  child: SizedBox(
                    width: size.width,
                    height: size.height,
                    child: handleCore,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      if (position == Offset.zero) return child;
      return Transform.translate(offset: position, child: child);
    }

    if (lodZoom != null) {
      return ListenableBuilder(
        listenable: controller.liveViewport,
        builder: (context, _) {
          if (controller.liveViewport.zoom < lodZoom) {
            return const SizedBox.shrink();
          }
          return buildHandle();
        },
      );
    }

    return buildHandle();
  }
}

class _DefaultHandle extends StatelessWidget {
  final Decoration decoration;
  const _DefaultHandle({required this.decoration});

  @override
  Widget build(BuildContext context) {
    return Container(decoration: decoration);
  }
}

/*
  removed for performance

  final bool? enableAnimations;
  final Curve? animationCurve;
  final Duration? animationDuration;
  final double? animationScale;

  this.animationScale = 1.5,
  this.enableAnimations = true,
  this.animationCurve = Curves.easeInOut,
  this.animationDuration = const Duration(milliseconds: 200),

      final bool isAnimated = handleState.hovered || handleState.active;
    final double targetScale = isAnimated ? (animationScale ?? 1.5) : 1.0;

    
AnimatedContainer(
                  transformAlignment: Alignment.center,
                  duration:
                      animationDuration ?? const Duration(milliseconds: 200),
                  transform: Matrix4.identity()..scale(targetScale),
                  curve: animationCurve ?? Curves.easeInOut,
                  width: size.width,
                  height: size.height,
                  child: Center(child: handleCore),
                )
              : 
*/
