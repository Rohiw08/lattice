import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_document.dart';
import 'lattice_node.dart';
import 'lattice_selection.dart';
import 'lattice_spatial_index.dart';
import 'session_providers.dart';

/// Pane size in logical px, published by [LatticeCanvas] from its
/// `LayoutBuilder` constraints on every layout. `null` before first layout.
///
/// (A [NotifierProvider] of nullable state — the `StateProvider` spelling
/// from the plan no longer exists in flutter_riverpod 3.x. Name, state
/// type, and read/write ergonomics are unchanged.)
class LatticePaneSizeController extends Notifier<Size?> {
  @override
  Size? build() => null;

  void set(Size? size) {
    if (state != size) state = size;
  }
}

final latticePaneSizeProvider =
    NotifierProvider<LatticePaneSizeController, Size?>(
  LatticePaneSizeController.new,
);

/// Resolves the visible node id set for the canvas pane.
///
/// Hot path rules (binding): cull resolves on camera settle, pane resize,
/// or structural change (document/selection/drag) only — never per camera
/// tick. The controller reads the camera matrix with `ref.read` and
/// subscribes to the camera `settled` stream; it never `ref.watch`es the
/// matrix, so per-tick matrix writes notify nobody. Visibility uses the
/// owned [LatticeSpatialIndex] plus direct rect math — never
/// `latticeOverlapsRect` per candidate (it copies the full node map).
class LatticeCullController extends Notifier<Set<String>> {
  final LatticeSpatialIndex _index = LatticeSpatialIndex();

  /// Last node map the index was synced to (identity fast path).
  Map<String, LatticeNode>? _lastSyncedNodes;

  /// Record snapshot for incremental `moveNode` deltas.
  Map<String, LatticeNode> _snapshot = const <String, LatticeNode>{};

  StreamSubscription<void>? _settledSub;
  bool _disposed = false;

  @override
  Set<String> build() {
    ref.listen<LatticeDocument>(
      latticeDocumentProvider,
      (_, _) => refresh(),
    );
    ref.listen<LatticeSelection>(
      latticeSelectionProvider,
      (_, _) => refresh(),
    );
    ref.listen<LatticeDragState>(
      latticeDragProvider,
      (_, _) => refresh(),
    );
    ref.listen<Size?>(
      latticePaneSizeProvider,
      (_, _) => refresh(),
    );
    _settledSub = ref
        .read(latticeCameraProvider.notifier)
        .settled
        .listen((_) {
      if (!_disposed) refresh();
    });
    ref.onDispose(() {
      _disposed = true;
      _settledSub?.cancel();
      _settledSub = null;
    });

    final Map<String, LatticeNode> nodes =
        ref.read(latticeDocumentProvider).nodes;
    _syncIndex(nodes);
    // Safe initial state: the full id set until the first refresh
    // (forced post-frame by the canvas) resolves the culled subset.
    return Set<String>.of(nodes.keys);
  }

  /// Recomputes the visible id set: index hits for the visible flow rect
  /// ∪ selected ids ∪ drag ids, pruned to ids still in the document.
  ///
  /// The visible flow rect inverts the camera matrix over the pane rect
  /// (`MatrixUtils.inverseTransformRect`). With no pane size yet, keeps
  /// the full id set. Skips emission when the set is content-equal.
  /// `force` additionally performs a full index rebuild.
  void refresh({bool force = false}) {
    final Map<String, LatticeNode> nodes =
        ref.read(latticeDocumentProvider).nodes;
    _syncIndex(nodes, full: force);

    final Size? paneSize = ref.read(latticePaneSizeProvider);
    Set<String> visible;
    if (paneSize == null) {
      visible = Set<String>.of(nodes.keys);
    } else {
      final Rect screenRect = Offset.zero & paneSize;
      final Matrix4 matrix = ref.read(latticeCameraProvider);
      final Rect flowRect =
          MatrixUtils.inverseTransformRect(matrix, screenRect);
      visible = _index.queryNodes(flowRect);
    }
    visible.addAll(ref.read(latticeSelectionProvider).nodes);
    visible.addAll(ref.read(latticeDragProvider).ids);
    visible.removeWhere((String id) => !nodes.containsKey(id));

    if (_setsEqual(visible, state)) return;
    state = visible;
  }

  /// Full index `rebuild` when the key set changed; otherwise `moveNode`
  /// deltas for records that differ from the cached snapshot. Skipped
  /// entirely when [nodes] is identical to the last synced map.
  void _syncIndex(Map<String, LatticeNode> nodes, {bool full = false}) {
    if (!full && identical(nodes, _lastSyncedNodes)) return;
    if (full ||
        nodes.length != _snapshot.length ||
        !_snapshotContainsAll(nodes)) {
      _index.rebuild(nodes, defaultOrigin: Offset.zero);
      _snapshot = Map<String, LatticeNode>.of(nodes);
    } else {
      nodes.forEach((String id, LatticeNode node) {
        final LatticeNode? before = _snapshot[id];
        if (before != null && before != node) {
          _index.moveNode(before, node);
          _snapshot[id] = node;
        }
      });
    }
    _lastSyncedNodes = nodes;
  }

  bool _snapshotContainsAll(Map<String, LatticeNode> nodes) {
    for (final String id in nodes.keys) {
      if (!_snapshot.containsKey(id)) return false;
    }
    return true;
  }
}

final latticeCullProvider =
    NotifierProvider<LatticeCullController, Set<String>>(
  LatticeCullController.new,
);

bool _setsEqual(Set<String> a, Set<String> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  return a.containsAll(b);
}
