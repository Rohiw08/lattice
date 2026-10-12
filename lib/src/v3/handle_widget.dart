import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_handle.dart';

/// Minimum handle hit-test extent per axis: `max(handle size, 20)`.
double latticeHandleHitExtent(double size) => size < 20.0 ? 20.0 : size;

/// Interactive connection handle rendered over a node shell.
///
/// Hit area is a [SizedBox] of at least 20x20 (`max(handle.size, 20)`
/// per axis) with a visible 8px dot centered inside. Hover state is
/// local ([setState]); the router does its own geometric hit test, so
/// this widget owns no gesture detectors.
///
/// Theme comes in V3-6: colors are hardcoded neutrals until then.
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
    // Theme lands in V3-6: hardcoded neutral colors until then.
    const Color dot = Color(0xFF64748B);
    const Color dotHovered = Color(0xFF2563EB);
    const Color ring = Color(0xFFFFFFFF);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
        width: latticeHandleHitExtent(handle.size.width),
        height: latticeHandleHitExtent(handle.size.height),
        child: Center(
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _hovered ? dotHovered : dot,
              shape: BoxShape.circle,
              border: Border.all(color: ring, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}
