import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_controller.dart';
import 'lattice_cull.dart';
import 'lattice_scope.dart';
import 'node_layer.dart';

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
    this.nodeBuilders = const {},
  });

  final LatticeController controller;

  /// Widgets stacked above the lattice pane (edges land in V3-4).
  final List<Widget> overlays;

  /// Per-type node body builders for the node layer. Unknown types fall
  /// back to a default bordered box.
  final Map<String, LatticeNodeBuilder> nodeBuilders;

  @override
  State<LatticeCanvas> createState() => _LatticeCanvasState();
}

class _LatticeCanvasState extends State<LatticeCanvas> {
  Size? _publishedSize;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.controller.container
          .read(latticeCullProvider.notifier)
          .refresh(force: true);
    });
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
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final Size size = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );
            if (size != _publishedSize &&
                size.width.isFinite &&
                size.height.isFinite) {
              _publishedSize = size;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                widget.controller.container
                    .read(latticePaneSizeProvider.notifier)
                    .set(size);
              });
            }
            return Stack(
              key: const ValueKey<String>('latticePane'),
              children: [
                const SizedBox.expand(),
                LatticeNodeLayer(nodeBuilders: widget.nodeBuilders),
                ...widget.overlays,
              ],
            );
          },
        ),
      ),
    );
  }
}
