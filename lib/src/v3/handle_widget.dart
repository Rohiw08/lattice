import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_handle.dart';
import 'lattice_theme.dart';

/// Minimum handle hit-test extent per axis: `max(handle size, 20)`.
double latticeHandleHitExtent(double size) => size < 20.0 ? 20.0 : size;

/// Interactive connection handle rendered over a node shell.
///
/// Hit area is a [SizedBox] of at least 20x20 (`max(handle.size, 20)`
/// per axis) with a visible dot ([LatticeHandleStyle.size], default 8px)
/// centered inside. Hover state is local ([setState]); the router does its
/// own geometric hit test, so this widget owns no gesture detectors.
///
/// Colors come from the nearest [LatticeThemeScope] handle component
/// (falling back to the light theme standalone); the hovered dot uses the
/// theme's node selected-border accent.
class LatticeHandleWidget extends ConsumerStatefulWidget {
  const LatticeHandleWidget({
    super.key,
    required this.nodeId,
    required this.handle,
  });

  final String nodeId;
  final LatticeHandle handle;

  @override
  ConsumerState<LatticeHandleWidget> createState() =>
      _LatticeHandleWidgetState();
}

class _LatticeHandleWidgetState
    extends ConsumerState<LatticeHandleWidget> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final LatticeHandle handle = widget.handle;
    final LatticeTheme theme =
        LatticeThemeScope.maybeOf(context) ?? LatticeTheme.light();
    final LatticeHandleStyle style = theme.resolvedHandle;
    // The hovered dot is the theme's selection accent (the same blue as
    // the selected-node border), not a hardcoded neutral.
    final Color hoveredFill = theme.resolvedNode.selectedBorder;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: latticeHandleHitExtent(handle.size.width),
        height: latticeHandleHitExtent(handle.size.height),
        child: Center(
          child: Container(
            width: style.size,
            height: style.size,
            decoration: BoxDecoration(
              color: _hovered ? hoveredFill : style.fill,
              shape: BoxShape.circle,
              border: Border.all(color: style.border, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
