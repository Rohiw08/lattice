import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pointer target stacked *above* edge paint and *above* background (group)
/// nodes, but *behind* middle nodes.
///
/// Only participates in hit-testing when the pointer is on an edge stroke so
/// empty group bodies behind this layer remain clickable (layered hit-testing).
class FlowCanvasPointerLayer extends ConsumerWidget {
  const FlowCanvasPointerLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);

    final edgeCursor =
        (context.flowCanvasTheme.cursor ?? FlowCursorStyle.system(context))
            .edge;

    return _EdgeOnlyHitListener(
      cursor: edgeCursor,
      hitTestEdge: (Offset localPosition) {
        final state = controller.currentState;
        return controller.edgeGeometryService.hitTestEdgeAt(
              localPosition,
              state,
              state.viewport.zoom,
            ) !=
            null;
      },
      onPointerHover: (PointerHoverEvent event) {
        controller.edges.onEdgePointerHover(event, event.localPosition);
      },
      onPointerDown: (PointerDownEvent event) {
        controller.edges.onEdgeTapDown(
          TapDownDetails(
            globalPosition: event.position,
            localPosition: event.localPosition,
            kind: event.kind,
          ),
          event.localPosition,
          pointer: event.pointer,
        );
      },
      child: const SizedBox.expand(),
    );
  }
}

/// Full-screen backdrop behind groups — empty-canvas click deselects, or
/// starts a marquee when the selection key / [selectionOnDrag] is active.
class FlowCanvasDeselectLayer extends ConsumerWidget {
  const FlowCanvasDeselectLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);

    return UnboundedListener(
      behavior: HitTestBehavior.opaque,
      onPointerHover: (_) {
        final state = controller.currentState;
        if (state.hoveredEdgeId.isNotEmpty) {
          controller.updateStateOnly(state.copyWith(hoveredEdgeId: ''));
        }
      },
      onPointerDown: (event) {
        final options = ref.read(flowOptionsProvider).viewportOptions;
        // Middle/right pan is handled by the viewport Listener.
        if (options.isAuxiliaryPanButton(event.buttons)) return;

        if (controller.selection.shouldStartBoxSelection) {
          controller.selection.startSelection(
            event.localPosition,
            pointer: event.pointer,
          );
        } else {
          controller.selection.deselectAll();
        }
      },
      child: const SizedBox.expand(),
    );
  }
}

/// Listener that only claims hits when [hitTestEdge] is true.
class _EdgeOnlyHitListener extends SingleChildRenderObjectWidget {
  const _EdgeOnlyHitListener({
    required this.hitTestEdge,
    required this.cursor,
    this.onPointerDown,
    this.onPointerHover,
    super.child,
  });

  final bool Function(Offset localPosition) hitTestEdge;
  final MouseCursor cursor;
  final PointerDownEventListener? onPointerDown;
  final void Function(PointerHoverEvent)? onPointerHover;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderEdgeOnlyHitListener(
      hitTestEdge: hitTestEdge,
      cursor: cursor,
      onPointerDown: onPointerDown,
      onPointerHover: onPointerHover,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderEdgeOnlyHitListener renderObject,
  ) {
    renderObject
      ..hitTestEdge = hitTestEdge
      ..cursor = cursor
      ..onPointerDown = onPointerDown
      ..onPointerHover = onPointerHover;
  }
}

class _RenderEdgeOnlyHitListener extends RenderProxyBox
    implements MouseTrackerAnnotation {
  _RenderEdgeOnlyHitListener({
    required this.hitTestEdge,
    required MouseCursor cursor,
    this.onPointerDown,
    this.onPointerHover,
  }) : _cursor = cursor;

  bool Function(Offset localPosition) hitTestEdge;
  PointerDownEventListener? onPointerDown;
  void Function(PointerHoverEvent)? onPointerHover;

  MouseCursor _cursor;

  @override
  MouseCursor get cursor => _cursor;

  set cursor(MouseCursor value) {
    if (_cursor == value) return;
    _cursor = value;
    // Nudge mouse tracker so cursor updates without a move.
    markNeedsPaint();
  }

  @override
  PointerEnterEventListener? get onEnter => null;

  @override
  PointerExitEventListener? get onExit => null;

  @override
  bool get validForMouseTracker => true;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!hitTestEdge(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    assert(debugHandleEvent(event, entry));
    if (event is PointerDownEvent) {
      onPointerDown?.call(event);
    } else if (event is PointerHoverEvent) {
      onPointerHover?.call(event);
    }
  }
}
