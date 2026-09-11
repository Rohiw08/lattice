import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:lattice/src/features/background/presentation/painters/flow_space_background_painter.dart';
import 'package:lattice/src/features/viewport/domain/viewport_transform.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pattern dots/grid in **flow space** under nodes (transforms with IV).
class FlowBackgroundPatternLayer extends ConsumerWidget {
  const FlowBackgroundPatternLayer({
    super.key,
    required this.style,
    required this.viewportSize,
  });

  final FlowBackgroundStyle style;
  final Size viewportSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(internalControllerProvider.notifier);

    return IgnorePointer(
      child: ListenableBuilder(
        listenable: controller.transformationController,
        builder: (context, _) {
          final matrix = controller.transformationController.value;
          final viewport = flowViewportFromMatrix4(matrix) ??
              controller.liveViewport.viewport;
          final visible = computeVisibleFlowRectFromCanvasTransform(
            matrix,
            viewportSize,
            padding: style.gap * 2,
          );

          return CustomPaint(
            painter: FlowSpaceBackgroundPainter(
              style: style,
              visibleFlow: visible,
              zoom: viewport.zoom,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}
