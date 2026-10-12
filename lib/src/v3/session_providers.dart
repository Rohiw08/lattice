import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_node.dart';
import 'lattice_selection.dart';
import 'lattice_viewport_value.dart';

/// Owns the session document. Replaced wholesale (e.g. load, undo step).
class LatticeDocumentController extends Notifier<LatticeDocument> {
  @override
  LatticeDocument build() => const LatticeDocument();

  void replace(LatticeDocument document) {
    state = document;
  }
}

final latticeDocumentProvider =
    NotifierProvider<LatticeDocumentController, LatticeDocument>(
  LatticeDocumentController.new,
);

/// Owns the current selection. Skips emission when the value is unchanged.
class LatticeSelectionController extends Notifier<LatticeSelection> {
  @override
  LatticeSelection build() => const LatticeSelection();

  void setSelection(LatticeSelection selection) {
    if (selection == state) return;
    state = selection;
  }

  void clear() {
    setSelection(const LatticeSelection());
  }
}

final latticeSelectionProvider =
    NotifierProvider<LatticeSelectionController, LatticeSelection>(
  LatticeSelectionController.new,
);

/// Owns the transient drag gesture state.
class LatticeDragController extends Notifier<LatticeDragState> {
  @override
  LatticeDragState build() => const LatticeDragState.idle();

  void set(LatticeDragState drag) {
    state = drag;
  }
}

final latticeDragProvider =
    NotifierProvider<LatticeDragController, LatticeDragState>(
  LatticeDragController.new,
);

/// Owns the currently hovered node/edge id (`null` when none).
class LatticeHoverController extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? id) {
    state = id;
  }
}

final latticeHoverProvider =
    NotifierProvider<LatticeHoverController, String?>(
  LatticeHoverController.new,
);

/// The document's nodes map. Stable reference: unchanged across emissions
/// that leave the map instance untouched (e.g. hover/selection changes).
final latticeNodesProvider = Provider<Map<String, LatticeNode>>((ref) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.nodes),
  );
});

/// The document's edges map. Stable reference, same contract as [latticeNodesProvider].
final latticeEdgesProvider = Provider<Map<String, LatticeEdge>>((ref) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.edges),
  );
});

/// The document's viewport value.
final latticeViewportProvider = Provider<LatticeViewportValue>((ref) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.viewport),
  );
});

/// The node with [id], or `null` when absent.
final latticeNodeProvider =
    Provider.family<LatticeNode?, String>((ref, id) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.nodes[id]),
  );
});

/// The edge with [id], or `null` when absent.
final latticeEdgeProvider =
    Provider.family<LatticeEdge?, String>((ref, id) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.edges[id]),
  );
});
