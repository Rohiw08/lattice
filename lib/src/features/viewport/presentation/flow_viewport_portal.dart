import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';

/// Renders [child] at a flow-space [position], panning and zooming with the
/// graph.
///
/// Lattice `<ViewportPortal />` counterpart. Place it in
/// [FlowCanvas.overlays]: unlike [FlowPanel] (screen-fixed), the child sticks
/// to the canvas — the canonical host for multiplayer presence (remote
/// cursors, peer viewport frames) and canvas-anchored annotations.
///
/// The child scales with zoom, exactly like node content. It listens to the
/// live transformation matrix, so it tracks smoothly mid-gesture without
/// per-frame state commits.
///
/// ```dart
/// FlowCanvas(
///   overlays: [
///     FlowViewportPortal(
///       position: Offset(200, 100), // flow coordinates
///       child: const Icon(Icons.location_on, color: Colors.red),
///     ),
///   ],
/// )
/// ```
class FlowViewportPortal extends ConsumerWidget {
  const FlowViewportPortal({
    super.key,
    required this.position,
    required this.child,
  });

  /// Flow-space anchor: the top-left of [child] in graph coordinates.
  final Offset position;

  /// Content pinned to [position]. Hit-testing works normally.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);
    return ListenableBuilder(
      listenable: controller.transformationController,
      builder: (context, _) {
        final matrix = controller.transformationController.value;
        final screen = MatrixUtils.transformPoint(matrix, position);
        return Positioned(
          left: screen.dx,
          top: screen.dy,
          child: Transform.scale(
            scale: matrix.getMaxScaleOnAxis(),
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
    );
  }
}
