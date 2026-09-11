import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/core/theme/components/controls_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/features/control_panel/presentation/control_button.dart';
import '../../../core/providers/providers.dart';

class FlowCanvasControls extends ConsumerWidget {
  final Size? size;
  final bool showZoom;
  final bool showFitView;
  final bool showLock;
  final bool showUndoRedo;
  final Axis orientation;
  final Alignment alignment;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final List<Widget> children;

  // THEME OVERRIDES
  final FlowControlsStyle? controlsStyle;

  const FlowCanvasControls({
    super.key,
    this.showZoom = true,
    this.showFitView = true,
    this.showLock = true,
    this.showUndoRedo = true,
    this.orientation = Axis.vertical,
    this.alignment = Alignment.bottomLeft,
    this.margin = const EdgeInsets.all(10),
    this.padding = const EdgeInsets.all(10),
    this.children = const [],
    this.spacing = 4.0,
    this.controlsStyle,
    this.size,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Theme
    final contextTheme =
        context.flowCanvasTheme.controls ?? FlowControlsStyle.system(context);
    final theme = contextTheme.merge(controlsStyle);

    // logic
    final controller = ref.read(internalControllerProvider.notifier);
    final options = ref.read(flowOptionsProvider);
    final viewportSize =
        ref.watch(internalControllerProvider.select((s) => s.viewportSize));
    final isLocked = ref.watch(
      internalControllerProvider.select((s) => s.isPanZoomLocked),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: margin,
        padding: padding,
        decoration: theme.decoration,
        height: size?.height,
        width: size?.width,
        child: Wrap(
          direction: orientation,
          spacing: spacing,
          runSpacing: spacing,
          children: _buildButtons(
            context,
            controller,
            isLocked,
            options,
            viewportSize,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildButtons(
    BuildContext context,
    FlowCanvasInternalController controller,
    bool isLocked,
    FlowCanvasOptions options,
    Size? viewportSize,
  ) {
    final screenCenter = viewportSize != null
        ? Offset(viewportSize.width / 2, viewportSize.height / 2)
        : Offset.zero;

    // When frozen, only the lock button stays active so the user can unfreeze.
    VoidCallback? whenUnlocked(VoidCallback action) =>
        isLocked ? null : action;

    return [
      if (showZoom) ...[
        ControlButton(
          icon: Icons.add,
          tooltip: 'Zoom In',
          onPressed: whenUnlocked(
            () => controller.viewport.zoom(
              zoomFactor: 0.2,
              minZoom: options.viewportOptions.minZoom,
              maxZoom: options.viewportOptions.maxZoom,
              focalPoint: screenCenter,
            ),
          ),
        ),
        ControlButton(
          icon: Icons.remove,
          tooltip: 'Zoom Out',
          onPressed: whenUnlocked(
            () => controller.viewport.zoom(
              zoomFactor: -0.2,
              minZoom: options.viewportOptions.minZoom,
              maxZoom: options.viewportOptions.maxZoom,
              focalPoint: screenCenter,
            ),
          ),
        ),
      ],
      if (showFitView)
        ControlButton(
          icon: Icons.fit_screen,
          tooltip: 'Fit View',
          onPressed: whenUnlocked(() => controller.viewport.fitView()),
        ),
      if (showLock)
        ControlButton(
          icon: isLocked ? Icons.lock : Icons.lock_open,
          tooltip: isLocked
              ? 'Unlock (allow all interactions)'
              : 'Lock (freeze canvas)',
          selected: isLocked,
          onPressed: controller.viewport.toggleLock,
        ),
      if (showUndoRedo) ...[
        ControlButton(
          icon: Icons.undo,
          tooltip: 'Undo',
          onPressed: whenUnlocked(controller.history.undo),
        ),
        ControlButton(
          icon: Icons.redo,
          tooltip: 'Redo',
          onPressed: whenUnlocked(controller.history.redo),
        ),
      ],
      ...children,
    ];
  }
}
