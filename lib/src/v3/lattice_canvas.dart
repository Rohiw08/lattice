import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_controller.dart';
import 'lattice_scope.dart';

/// Mounts a [LatticeController] session as a widget.
///
/// Attaches to [controller] in [initState] and detaches in [dispose].
/// Mounting a second canvas while [controller] is already attached throws
/// a [StateError] (one container, one canvas).
class LatticeCanvas extends StatefulWidget {
  const LatticeCanvas({
    super.key,
    required this.controller,
    this.overlays = const [],
  });

  final LatticeController controller;

  /// Widgets stacked above the lattice pane (nodes/edges land in V3-3).
  final List<Widget> overlays;

  @override
  State<LatticeCanvas> createState() => _LatticeCanvasState();
}

class _LatticeCanvasState extends State<LatticeCanvas> {
  @override
  void initState() {
    super.initState();
    if (widget.controller.isAttached) {
      throw StateError(
        'LatticeCanvas: a second canvas was mounted on the same '
        'LatticeController. One controller owns one canvas; create a '
        'separate LatticeController per canvas.',
      );
    }
    widget.controller.attach();
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: widget.controller.container,
      child: LatticeScope(
        controller: widget.controller,
        child: Stack(
          children: [
            const SizedBox.expand(key: ValueKey('latticePane')),
            ...widget.overlays,
          ],
        ),
      ),
    );
  }
}
