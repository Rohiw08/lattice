import 'package:flutter/foundation.dart';

import 'lattice_controller.dart';
import 'lattice_edge.dart';
import 'lattice_node.dart';
import 'lattice_selection.dart';
import 'lattice_viewport_value.dart';

/// Nullable observation hooks for a lattice session.
///
/// Every hook is optional and called with `?.call` semantics: a missing hook
/// is a no-op. Hooks fire from the controller verbs that commit the matching
/// state, exactly once per actual change (no-op verbs fire nothing), and
/// never from session-only ticks such as per-frame drag updates.
@immutable
class LatticeCallbacks {
  const LatticeCallbacks({
    this.onNodesAdded,
    this.onNodesRemoved,
    this.onEdgesAdded,
    this.onEdgesRemoved,
    this.onSelectionChange,
    this.onViewportChange,
    this.onConnect,
    this.onInit,
  });

  /// Nodes committed by an add verb ([LatticeController.addNode]).
  final ValueChanged<List<LatticeNode>>? onNodesAdded;

  /// Nodes removed by [LatticeController.removeNodes] or
  /// [LatticeController.deleteElements] (the pre-image objects).
  final ValueChanged<List<LatticeNode>>? onNodesRemoved;

  /// Edges committed by an add verb ([LatticeController.addEdge], including
  /// edges minted by the connect flow).
  final ValueChanged<List<LatticeEdge>>? onEdgesAdded;

  /// Edges removed by [LatticeController.removeEdges] or
  /// [LatticeController.deleteElements] (the pre-image objects).
  final ValueChanged<List<LatticeEdge>>? onEdgesRemoved;

  /// The selection after it actually changed.
  final ValueChanged<LatticeSelection>? onSelectionChange;

  /// The viewport committed to the document by
  /// [LatticeController.saveViewport].
  final ValueChanged<LatticeViewportValue>? onViewportChange;

  /// The edge created by a successful connect flow
  /// ([LatticeController.endConnect]); fires after [onEdgesAdded] for the
  /// same edge.
  final ValueChanged<LatticeEdge>? onConnect;

  /// Fired once, post-frame, by [LatticeCanvas] after the session is
  /// mounted and the initial state is applied.
  final ValueChanged<LatticeController>? onInit;
}
