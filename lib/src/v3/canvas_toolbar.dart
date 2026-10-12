import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_controller.dart';
import 'lattice_lock.dart';
import 'lattice_scope.dart';

/// Zoom / fit / lock controls for a lattice canvas.
///
/// A shrink-wrapped column of [IconButton]s, intended as a
/// [LatticeCanvas] overlay (e.g. inside a [LatticePanel]). All actions go
/// through controller verbs: zoom-in/out scale the camera about the pane
/// center, fit frames the document, and the lock toggle flips
/// [latticeLockProvider]. Zoom and fit buttons disable while locked (the
/// verbs themselves are lock-gated too); the lock toggle stays enabled.
///
/// Must mount under a [LatticeScope] (a [LatticeCanvas] provides one).
class LatticeControls extends ConsumerWidget {
  const LatticeControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LatticeController controller = LatticeScope.of(context);
    final bool locked = ref.watch(latticeLockProvider);
    // V3-6 Task 6: theme
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        IconButton(
          key: const ValueKey<String>('latticeZoomIn'),
          icon: const Icon(Icons.zoom_in),
          tooltip: 'Zoom in',
          onPressed: locked ? null : controller.zoomIn,
        ),
        IconButton(
          key: const ValueKey<String>('latticeZoomOut'),
          icon: const Icon(Icons.zoom_out),
          tooltip: 'Zoom out',
          onPressed: locked ? null : controller.zoomOut,
        ),
        IconButton(
          key: const ValueKey<String>('latticeFitView'),
          icon: const Icon(Icons.fit_screen),
          tooltip: 'Fit view',
          onPressed: locked ? null : controller.fitView,
        ),
        IconButton(
          key: const ValueKey<String>('latticeLock'),
          icon: Icon(locked ? Icons.lock : Icons.lock_open),
          tooltip: locked ? 'Unlock' : 'Lock',
          onPressed: controller.toggleLock,
        ),
      ],
    );
  }
}
