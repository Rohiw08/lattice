import 'package:lattice/src/core/theme/components/selection_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';
import '../painters/selection_painter.dart';

/// Paints the active marquee rectangle. Interaction is owned by
/// [SelectionController]'s global pointer route (and pane/node starters).
class SelectionLayer extends ConsumerWidget {
  const SelectionLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionRect = ref.watch(
      internalControllerProvider.select((s) => s.selectionRect),
    );
    final controller = ref.read(internalControllerProvider.notifier);

    final theme =
        context.flowCanvasTheme.selection ?? FlowSelectionStyle.system(context);

    return IgnorePointer(
      child: UnboundedSizedBox(
        child: ListenableBuilder(
          listenable: controller.liveViewport,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: SelectionRectanglePainter(
                selectionRect:
                    selectionRect == Rect.zero ? null : selectionRect,
                style: theme,
                zoom: controller.liveViewport.zoom,
              ),
            );
          },
        ),
      ),
    );
  }
}
