import 'package:lattice/src/core/theme/components/cursor_theme.dart';
import 'package:lattice/src/core/theme/components/node_resizer_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/utils/custom_stack_widget.dart';
import 'package:flutter/material.dart';

/// A draggable handle for node resizing with theme support.
class NodeResizeHandle extends StatefulWidget {
  final String nodeId;
  final Alignment direction;
  final Offset offset;
  final VoidCallback? onResizeStart;
  final ValueChanged<Offset>? onResizeUpdate;
  final VoidCallback? onResizeEnd;
  final FlowNodeResizerStyle? style;
  final bool isSelected;
  final bool isDisabled;

  const NodeResizeHandle({
    super.key,
    required this.nodeId,
    required this.direction,
    this.offset = Offset.zero,
    this.onResizeStart,
    this.onResizeUpdate,
    this.onResizeEnd,
    this.style,
    this.isSelected = false,
    this.isDisabled = false,
  });

  @override
  State<NodeResizeHandle> createState() => _NodeResizeHandleState();
}

class _NodeResizeHandleState extends State<NodeResizeHandle> {
  bool _isHovered = false;
  bool _isActive = false;

  Set<FlowNodeResizerState> get _states {
    final states = <FlowNodeResizerState>{FlowNodeResizerState.normal};
    if (widget.isDisabled) {
      states.add(FlowNodeResizerState.disabled);
    }
    if (widget.isSelected) {
      states.add(FlowNodeResizerState.selected);
    }
    if (_isActive) {
      states.add(FlowNodeResizerState.active);
    } else if (_isHovered) {
      states.add(FlowNodeResizerState.hovered);
    }
    return states;
  }

  @override
  Widget build(BuildContext context) {
    final canvasTheme = context.flowCanvasTheme;
    final baseTheme =
        canvasTheme.nodeResizer ?? FlowNodeResizerStyle.system(context);
    final theme = baseTheme.merge(widget.style);
    final cursors = canvasTheme.cursor ?? FlowCursorStyle.light();
    final cursor = cursors.resolveResizer(
      widget.direction,
      isDisabled: widget.isDisabled,
    );

    final color = theme.resolveColor(_states);
    // Standard translation to center handle on the alignment point
    final translation =
        Offset(widget.direction.x * 0.5, widget.direction.y * 0.5);

    return UnboundedAlign(
      alignment: widget.direction,
      child: FractionalTranslation(
        translation: translation,
        child: Transform.translate(
          offset: widget.offset,
          child: MouseRegion(
            cursor: cursor,
            onEnter: widget.isDisabled
                ? null
                : (_) => setState(() => _isHovered = true),
            onExit: widget.isDisabled
                ? null
                : (_) => setState(() => _isHovered = false),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: widget.isDisabled
                  ? null
                  : (_) {
                      setState(() => _isActive = true);
                      widget.onResizeStart?.call();
                    },
              onPanUpdate: widget.isDisabled
                  ? null
                  : (details) => widget.onResizeUpdate?.call(details.delta),
              onPanEnd: widget.isDisabled
                  ? null
                  : (_) {
                      setState(() => _isActive = false);
                      widget.onResizeEnd?.call();
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: theme.size,
                height: theme.size,
                decoration: BoxDecoration(
                  color: color,
                  shape: theme.shape,
                  border: Border.all(
                    color: theme.borderColor,
                    width: theme.borderWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
