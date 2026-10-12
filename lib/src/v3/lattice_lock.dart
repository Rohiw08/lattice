import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session lock state for a lattice canvas.
///
/// The lock lives in its own [Notifier] (not on the document, not on the
/// controller's listener set) so controls can `watch` it and rebuild the
/// lock icon while document commits stay untouched. [LatticeController]
/// owns the session container, so `toggleLock`/`isLocked` on the
/// controller are thin aliases over this provider.
///
/// Locked semantics (enforced as start-gates on the controller verbs):
/// node-drag / marquee / connect / reconnect / resize starts no-op, and
/// the camera verbs (`zoomIn`/`zoomOut`/`fitView`) no-op. Selection taps
/// (`tapAt`) still work. Sessions already in flight when the lock engages
/// still commit via their `end*` verb — the lock gates starts, never
/// strands an active gesture.
class LatticeLockController extends Notifier<bool> {
  @override
  bool build() => false;

  /// Flips the locked flag. Always emits (even `false → false` is
  /// impossible here — kept unconditional for symmetry with `set`).
  void toggle() {
    state = !state;
  }

  /// Sets the locked flag. Skips emission when unchanged.
  void set(bool value) {
    if (state != value) state = value;
  }
}

final latticeLockProvider =
    NotifierProvider<LatticeLockController, bool>(
  LatticeLockController.new,
);
