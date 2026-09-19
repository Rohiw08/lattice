import 'dart:async';

import 'package:flutter/animation.dart';
import 'package:flutter/scheduler.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:lattice/src/features/viewport/domain/viewport_transform.dart';

/// Frame-driven camera animation without a widget ticker.
///
/// Owned by [FlowCanvasInternalController]; driven with [start], cancelled
/// with [cancel]. Writes go through callbacks so the owner decides where
/// frames land (live matrix during flight, one state commit on landing).
/// Zero cost when idle: no ticker, no listeners.
class ViewportAnimator {
  Ticker? _ticker;
  Completer<bool>? _flight;

  /// Whether an animation is currently in progress.
  bool get isAnimating => _ticker?.isActive ?? false;

  /// Animates from [from] to [to] over [duration], easing [t] with [ease].
  ///
  /// Returns true when the flight lands, false when superseded, cancelled,
  /// or disposed. A previous flight is replaced (its future completes
  /// false) with a smooth handoff from wherever it was.
  Future<bool> start({
    required FlowViewport from,
    required FlowViewport to,
    required Duration duration,
    required Curve ease,
    required FitViewInterpolation interpolate,
    required void Function(FlowViewport viewport) onTick,
    required VoidCallback onDone,
  }) {
    // A previous flight is replaced: kill its ticker first (it would
    // otherwise keep writing the matrix), then fail its future.
    stop();
    _completeFlight(false);
    if (duration <= Duration.zero || flowViewportNearEqual(from, to)) {
      onTick(to);
      onDone();
      return Future.value(true);
    }
    final flight = _flight = Completer<bool>();
    // Standalone ticker (no widget TickerProvider needed); the owner must
    // call dispose().
    _ticker = Ticker((elapsed) {
      final raw =
          (elapsed.inMicroseconds / duration.inMicroseconds).clamp(0.0, 1.0);
      onTick(lerpViewport(from, to, ease.transform(raw),
          interpolate: interpolate));
      if (raw >= 1.0) {
        stop();
        onDone();
        _completeFlight(true);
      }
    });
    _ticker!.start();
    return flight.future;
  }

  /// Stops a flight, completing its future with false. State is untouched —
  /// callers commit the live position themselves when cancelling mid-flight.
  void cancel() {
    stop();
    _completeFlight(false);
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
  }

  void _completeFlight(bool value) {
    final flight = _flight;
    _flight = null;
    if (flight != null && !flight.isCompleted) flight.complete(value);
  }

  void dispose() {
    stop();
    _completeFlight(false);
  }
}
