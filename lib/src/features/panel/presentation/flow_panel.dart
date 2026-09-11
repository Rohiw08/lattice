import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/theme/components/panel_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fixed overlay panel above the flow viewport (Lattice `<Panel />`).
///
/// Does **not** pan/zoom with the graph. Place it in [FlowCanvas.overlays].
///
/// Chrome is optional: theme default is [FlowPanelStyle.unstyled] (Lattice). Opt in
/// with [style], theme `panel: FlowPanelStyle.light()`, or a raw [decoration].
///
/// ```dart
/// FlowCanvas(
///   overlays: [
///     FlowPanel(
///       position: PanelPosition.topRight,
///       style: FlowPanelStyle.light(),
///       child: Text('Toolbar'),
///     ),
///   ],
/// )
/// ```
class FlowPanel extends ConsumerStatefulWidget {
  const FlowPanel({
    super.key,
    required this.child,
    this.position = PanelPosition.topLeft,
    this.margin = const EdgeInsets.all(15),
    this.padding,
    this.style,
    this.decoration,
    this.selected = false,
    this.enabled = true,
    this.width,
    this.height,
    this.constraints,
    this.clipBehavior = Clip.none,
    this.semanticLabel,
    this.ignorePointerDuringSelection = true,
  });

  /// Content of the panel.
  final Widget child;

  /// Lattice `position` (default `top-left`).
  final PanelPosition position;

  /// Outer margin from the viewport edge. Lattice default is `15px`.
  final EdgeInsetsGeometry margin;

  /// Inner padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Per-panel style override. Merged over [FlowCanvasTheme.panel].
  final FlowPanelStyle? style;

  /// Absolute decoration override (skips theme state resolution when set).
  final Decoration? decoration;

  /// Selected interaction state for themed chrome.
  final bool selected;

  /// When false, resolves [FlowPanelState.disabled].
  final bool enabled;

  final double? width;
  final double? height;

  /// Extra size limits for the panel body.
  final BoxConstraints? constraints;

  final Clip clipBehavior;

  /// Accessibility label (Lattice / HTML `aria-label`).
  final String? semanticLabel;

  /// When true (default), the panel ignores pointers while a box-selection
  /// marquee is active — same as Lattice’s pane-selection CSS rule.
  final bool ignorePointerDuringSelection;

  @override
  ConsumerState<FlowPanel> createState() => _FlowPanelState();
}

class _FlowPanelState extends ConsumerState<FlowPanel> {
  bool _hovered = false;

  Set<FlowPanelState> get _states {
    final states = <FlowPanelState>{FlowPanelState.normal};
    if (!widget.enabled) states.add(FlowPanelState.disabled);
    if (widget.selected) states.add(FlowPanelState.selected);
    if (_hovered) states.add(FlowPanelState.hovered);
    return states;
  }

  @override
  Widget build(BuildContext context) {
    final selecting = widget.ignorePointerDuringSelection &&
        ref.watch(
          internalControllerProvider
              .select((s) => s.dragMode == DragMode.selection),
        );

    final base =
        context.flowCanvasTheme.panel ?? FlowPanelStyle.system(context);
    final panelStyle = base.merge(widget.style);
    final resolvedDecoration = widget.decoration ??
        (panelStyle.isUnstyled && widget.style == null
            ? null
            : panelStyle.resolveDecoration(_states));

    Widget body = widget.child;
    final needsChrome = widget.padding != null ||
        resolvedDecoration != null ||
        widget.width != null ||
        widget.height != null ||
        widget.constraints != null;

    if (needsChrome) {
      body = Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        decoration: resolvedDecoration,
        constraints: widget.constraints,
        clipBehavior:
            resolvedDecoration != null ? widget.clipBehavior : Clip.none,
        child: widget.child,
      );
    }

    if (widget.semanticLabel != null) {
      body = Semantics(
        label: widget.semanticLabel,
        container: true,
        child: body,
      );
    }

    if (selecting || !widget.enabled) {
      body = IgnorePointer(child: body);
    }

    body = MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      child: body,
    );

    return Align(
      alignment: _alignmentFor(widget.position),
      child: Padding(
        padding: widget.margin,
        child: body,
      ),
    );
  }
}

Alignment _alignmentFor(PanelPosition position) => switch (position) {
      PanelPosition.topLeft => Alignment.topLeft,
      PanelPosition.topCenter => Alignment.topCenter,
      PanelPosition.topRight => Alignment.topRight,
      PanelPosition.bottomLeft => Alignment.bottomLeft,
      PanelPosition.bottomCenter => Alignment.bottomCenter,
      PanelPosition.bottomRight => Alignment.bottomRight,
      PanelPosition.centerLeft => Alignment.centerLeft,
      PanelPosition.centerRight => Alignment.centerRight,
    };
