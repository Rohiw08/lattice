import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_viewport_value.dart';

/// Matrix-owned camera for a lattice canvas session.
///
/// The provider state IS the flow→screen matrix. [setViewport], [panBy],
/// and [zoomBy] only ever rewrite the matrix; they never touch the document.
/// [viewport] derives a [LatticeViewportValue] from the current matrix.
class LatticeCameraController extends Notifier<Matrix4> {
  final StreamController<void> _settledController =
      StreamController<void>.broadcast();
  Timer? _settleTimer;

  @override
  Matrix4 build() {
    ref.onDispose(() {
      _settleTimer?.cancel();
      _settledController.close();
    });
    return Matrix4.identity();
  }

  @override
  set state(Matrix4 value) {
    super.state = value;
    _armSettleTimer();
  }

  /// Replaces the matrix with [v]'s flow→screen transform.
  void setViewport(LatticeViewportValue v) {
    state = v.toMatrix();
  }

  /// Post-translates by the screen-space [delta], so mapped content
  /// follows the finger.
  void panBy(Offset delta) {
    state = Matrix4.translationValues(delta.dx, delta.dy, 0) * state;
  }

  /// Scales about [focal] (default origin), keeping the focal screen
  /// point fixed.
  void zoomBy(double factor, {Offset? focal}) {
    final Offset f = focal ?? Offset.zero;
    state = (Matrix4.identity()
          ..translateByDouble(f.dx, f.dy, 0.0, 1.0)
          ..scaleByDouble(factor, factor, factor, 1.0)
          ..translateByDouble(-f.dx, -f.dy, 0.0, 1.0)) *
        state;
  }

  /// The current matrix expressed as pan/zoom.
  LatticeViewportValue get viewport =>
      LatticeViewportValue.fromMatrix(state);

  /// Broadcast stream firing after 100ms without a matrix change.
  Stream<void> get settled => _settledController.stream;

  void _armSettleTimer() {
    _settleTimer?.cancel();
    _settleTimer = Timer(const Duration(milliseconds: 100), () {
      if (!_settledController.isClosed) {
        _settledController.add(null);
      }
    });
  }
}

final latticeCameraProvider =
    NotifierProvider<LatticeCameraController, Matrix4>(
  LatticeCameraController.new,
);
