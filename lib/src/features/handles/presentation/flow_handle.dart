import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/handle_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
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
    final handleState = ref.watch(
      internalControllerProvider.select(
        (s) => s.handleStates[handleKey] ?? const HandleRuntimeState(),
      ),
    );
    final nodeConnectable = ref.watch(
      internalControllerProvider.select((s) => s.nodes[nodeId]?.connectable),
    );
    final modelConnectable = ref.watch(
      internalControllerProvider.select(
        (s) => s.nodes[nodeId]?.effectiveHandles[handleId]?.isConnectable,
      ),
    );
    final globalConnectable = ref.watch(
      flowOptionsProvider.select((o) => o.nodeOptions.connectable),
    );
    // Widget prop → model → node flag → global (null widget/type props
    // fall through). Non-interactive masters everything off.
    final interactive = ref.watch(
      internalControllerProvider.select((s) => s.interactive),
    );
    final connectable =
        (isConnectable ??
            modelConnectable ??
            nodeConnectable ??
            globalConnectable) &&
        interactive;

    final controller = ref.read(internalControllerProvider.notifier);
    final lodZoom = ref
        .read(flowOptionsProvider)
        .viewportOptions
        .lodHideHandlesBelowZoom;

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

      return _handleInteractive(controller, handleCore);
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

  Widget _handleInteractive(
    FlowCanvasInternalController controller,
    Widget handleCore,
  ) {
    return Consumer(
      builder: (context, ref, _) {
        final connOpts = ref.watch(flowOptionsProvider).connectionOptions;
        final mode = connOpts.connectionMode;
        final modelHandle = ref.watch(
          internalControllerProvider.select(
            (s) => s.nodes[nodeId]?.effectiveHandles[handleId],
          ),
        );
        final bool? modelConnectable = modelHandle?.isConnectable;
        final bool? nodeConnectable = ref.watch(
          internalControllerProvider.select(
            (s) => s.nodes[nodeId]?.connectable,
          ),
        );
        final globalConnectable = ref.watch(
          flowOptionsProvider.select((o) => o.nodeOptions.connectable),
        );
        final interactive = ref.watch(
          internalControllerProvider.select((s) => s.interactive),
        );
        bool resolvedConnectable = nodeConnectable ?? globalConnectable;
        if (isConnectable != null) {
          resolvedConnectable = isConnectable!;
        } else if (modelConnectable != null) {
          resolvedConnectable = modelConnectable;
        }
        // Non-interactive masters everything off (Lattice setInteractive).
        resolvedConnectable = resolvedConnectable && interactive;
        if (isConnectable != null) {
          resolvedConnectable = isConnectable!;
        } else if (modelConnectable != null) {
          resolvedConnectable = modelConnectable;
        }
        final startOverride =
            isConnectableStart ?? modelHandle?.isConnectableStart;
        final canStart =
            resolvedConnectable &&
            (startOverride ??
                (mode == ConnectionMode.loose ||
                    type == HandleType.source ||
                    type == HandleType.both));
        final clickConnect = connOpts.connectOnClick;

        // Expand hit target beyond the tiny visual so connect-drag is reliable.
        final hitW = size.width < 20 ? 20.0 : size.width;
        final hitH = size.height < 20 ? 20.0 : size.height;

        // Pointer-driven connect (not GestureDetector pan): InteractiveViewer's
        // ScaleGestureRecognizer wins the arena and would swallow onPan*.
        // FlowNoDrag: beat the parent node pan so drag-to-connect isn't stolen.
        final child = FlowNoDrag(
          child: Semantics(
            // Lattice `handle.ariaLabel` — each handle is its own node,
            // like RF's labelled handle divs.
            label: ref.read(flowOptionsProvider).a11yOptions.labels.handleLabel,
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
                onPointerDown: (canStart || clickConnect) && resolvedConnectable
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
      },
    );
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
