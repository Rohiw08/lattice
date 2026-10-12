import 'lattice_document.dart';

/// Undo/redo history for a lattice session document.
///
/// Stores pre-image [LatticeDocument]s (immutable, value equality, cheap
/// to retain). The owning controller pushes the current document before
/// every mutating verb; [undo]/[redo] swap the live document with the
/// stored entry.
class LatticeHistoryController {
  /// Maximum retained undo entries; older entries are dropped.
  static const int maxLength = 100;

  final List<LatticeDocument> _undo = <LatticeDocument>[];
  final List<LatticeDocument> _redo = <LatticeDocument>[];

  /// Whether [undo] would return a document.
  bool get canUndo => _undo.isNotEmpty;

  /// Whether [redo] would return a document.
  bool get canRedo => _redo.isNotEmpty;

  /// Number of retained undo entries.
  int get length => _undo.length;

  /// Records [before] as the undo pre-image, clears the redo stack, and
  /// caps the undo stack at [maxLength] (drops oldest).
  void push(LatticeDocument before) {
    _undo.add(before);
    _redo.clear();
    if (_undo.length > maxLength) {
      _undo.removeRange(0, _undo.length - maxLength);
    }
  }

  /// Like [push], but consecutive identical pre-images collapse: appends
  /// only when the last undo entry is NOT `== before`.
  void coalescePush(LatticeDocument before) {
    if (_undo.isNotEmpty && _undo.last == before) return;
    push(before);
  }

  /// Steps back: pushes [current] onto the redo stack, pops and returns
  /// the undo top. Returns `null` (no stack change) when empty.
  LatticeDocument? undo(LatticeDocument current) {
    if (_undo.isEmpty) return null;
    _redo.add(current);
    return _undo.removeLast();
  }

  /// Steps forward: pushes [current] onto the undo stack, pops and
  /// returns the redo top. Returns `null` (no stack change) when empty.
  LatticeDocument? redo(LatticeDocument current) {
    if (_redo.isEmpty) return null;
    _undo.add(current);
    return _redo.removeLast();
  }

  /// Clears both stacks (document swap starts a fresh undo timeline).
  void reset() {
    _undo.clear();
    _redo.clear();
  }
}
