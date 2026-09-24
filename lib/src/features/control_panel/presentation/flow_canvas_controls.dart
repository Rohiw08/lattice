import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/options/components/fitview_options.dart';
import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/core/theme/components/controls_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/features/control_panel/presentation/control_button.dart';
import 'package:lattice/src/core/providers/providers.dart';

class FlowCanvasControls extends ConsumerWidget {
  final Size? size;
  final bool showZoom;
  final bool showFitView;
  final bool showInteractive;
  final bool showLock;
  final bool showUndoRedo;
  final Axis orientation;
  final Alignment alignment;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double spacing;
  final List<Widget> children;

  /// Options for the fit-view button (Lattice `fitViewOptions`).
  final FitViewOptions fitViewOptions;

  /// Extra listeners after the default actions run (Lattice
  /// `onZoomIn`/`onZoomOut`/`onFitView`).
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback? onFitView;

  /// Fired when the interactivity toggle flips (Lattice
  /// `onInteractiveChange`), with the new value.
  final ValueChanged<bool>? onInteractiveChange;

  // THEME OVERRIDES
  final FlowControlsStyle? controlsStyle;

  const FlowCanvasControls({
    super.key,
    this.showZoom = true,
    this.showFitView = true,
    this.showInteractive = true,
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
    this.fitViewOptions = const FitViewOptions(),
    this.onZoomIn,
    this.onZoomOut,
    this.onFitView,
    this.onInteractiveChange,
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
    final isInteractive = ref.watch(
      internalControllerProvider.select((s) => s.interactive),
    );

    return Align(
      alignment: alignment,
      child: Semantics(
        label: options.a11yOptions.labels.controlsLabel,
        container: true,
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
            isInteractive,
            options,
            viewportSize,
          ),
        ),
        ),
      ),
    );
  }

  List<Widget> _buildButtons(
    BuildContext context,
    FlowCanvasInternalController controller,
    bool isLocked,
    bool isInteractive,
    FlowCanvasOptions options,
    Size? viewportSize,
  ) {
    final screenCenter = viewportSize != null
        ? Offset(viewportSize.width / 2, viewportSize.height / 2)
        : Offset.zero;

    // When frozen, only the lock button stays active so the user can unfreeze.
    VoidCallback? whenUnlocked(VoidCallback action) =>
        isLocked ? null : action;

    final labels = options.a11yOptions.labels;

    return [
      if (showZoom) ...[
        ControlButton(
          icon: Icons.add,
          tooltip: labels.controlsZoomIn,
          onPressed: whenUnlocked(
            () {
              controller.viewport.zoom(
                zoomFactor: 0.2,
                minZoom: options.viewportOptions.minZoom,
                maxZoom: options.viewportOptions.maxZoom,
                focalPoint: screenCenter,
              );
              onZoomIn?.call();
            },
          ),
        ),
        ControlButton(
          icon: Icons.remove,
          tooltip: labels.controlsZoomOut,
          onPressed: whenUnlocked(
            () {
              controller.viewport.zoom(
                zoomFactor: -0.2,
                minZoom: options.viewportOptions.minZoom,
                maxZoom: options.viewportOptions.maxZoom,
                focalPoint: screenCenter,
              );
              onZoomOut?.call();
            },
          ),
        ),
      ],
      if (showFitView)
        ControlButton(
          icon: Icons.fit_screen,
          tooltip: labels.controlsFitView,
          onPressed: whenUnlocked(() {
            controller.viewport.fitView(
              fitviewOptions: fitViewOptions,
              viewportOptions: options.viewportOptions,
            );
            onFitView?.call();
          }),
        ),
      if (showInteractive)
        ControlButton(
          icon: Icons.touch_app,
          tooltip: labels.controlsInteractive,
          selected: !isInteractive,
          onPressed: () {
            controller.setInteractive(!isInteractive);
            onInteractiveChange?.call(!isInteractive);
          },
        ),
      if (showLock)
        ControlButton(
          icon: isLocked ? Icons.lock : Icons.lock_open,
          tooltip: isLocked ? labels.controlsUnlock : labels.controlsLock,
          selected: isLocked,
          onPressed: controller.viewport.toggleLock,
        ),
      if (showUndoRedo) ...[
        ControlButton(
          icon: Icons.undo,
          tooltip: labels.controlsUndo,
          onPressed: whenUnlocked(controller.history.undo),
        ),
        ControlButton(
          icon: Icons.redo,
          tooltip: labels.controlsRedo,
          onPressed: whenUnlocked(controller.history.redo),
        ),
      ],
      ...children,
    ];
  }
}
