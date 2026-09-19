import 'dart:math' as math;

import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Matrix4;

/// Coordinate convention for [InteractiveViewer] ↔ [FlowViewport]:
///
/// **Canvas → screen (viewer local):** `screen = zoom * canvas + offset`
///
/// The transformation matrix is therefore **translate(offset) × scale(zoom)** so that
/// applying scale first matches [ViewportService.flowToViewport] /
/// [ViewportService.viewportToFlow].

/// Builds the matrix that maps canvas coordinates to the InteractiveViewer's local space.
Matrix4 matrix4FromViewport(FlowViewport viewport) {
  return Matrix4.identity()
    ..translateByDouble(viewport.offset.dx, viewport.offset.dy, 0.0, 1.0)
    ..scaleByDouble(viewport.zoom, viewport.zoom, 1.0, 1.0);
}

/// Extracts [FlowViewport] from [matrix] if it is a 2D similarity transform
/// (uniform scale + translation) compatible with our model.
///
/// Returns null if the matrix includes skew, non-uniform scale, or perspective.
FlowViewport? flowViewportFromMatrix4(Matrix4 matrix) {
  final t = matrix.getTranslation();
  final s = matrix.storage;
  final sx = math.sqrt(s[0] * s[0] + s[1] * s[1]);
  final sy = math.sqrt(s[4] * s[4] + s[5] * s[5]);

  if (!sx.isFinite || !sy.isFinite || sx <= 0 || sy <= 0) {
    return null;
  }

  // Allow tiny drift from pointer/pinch on InteractiveViewer.
  if ((sx - sy).abs() > 0.02 * ((sx + sy) / 2)) {
    return null;
  }

  final zoom = (sx + sy) / 2;
  if ((s[8] - 0).abs() > 1e-3 ||
      (s[9] - 0).abs() > 1e-3 ||
      (s[10] - 1).abs() > 1e-3) {
    return null;
  }

  return FlowViewport(
    offset: Offset(t.x, t.y),
    zoom: zoom,
  );
}

bool flowViewportNearEqual(FlowViewport a, FlowViewport b) {
  return (a.offset.dx - b.offset.dx).abs() < 0.25 &&
      (a.offset.dy - b.offset.dy).abs() < 0.25 &&
      (a.zoom - b.zoom).abs() < 1e-4;
}

/// Viewer-local point → flow using a [FlowViewport] (no full canvas state).
Offset flowPointFromViewportPoint(Offset viewportPoint, FlowViewport viewport) {
  return (viewportPoint - viewport.offset) / viewport.zoom;
}

/// Flow → viewer-local using a [FlowViewport].
Offset viewportPointFromFlowPoint(Offset flowPoint, FlowViewport viewport) {
  return flowPoint * viewport.zoom + viewport.offset;
}

bool matrix4NearEqual(Matrix4 a, Matrix4 b) {
  const eps = 1e-5;
  for (var i = 0; i < 16; i++) {
    if ((a.storage[i] - b.storage[i]).abs() > eps) return false;
  }
  return true;
}

/// Interpolates between two viewports for camera animation.
///
/// [t] is the eased progress in `[0, 1]` (already passed through the
/// animation curve by the caller). Offset always lerps linearly; zoom follows
/// [interpolate]: [FitViewInterpolation.smooth] travels in log space so
/// perceived speed stays constant, [FitViewInterpolation.linear] lerps the
/// raw factor.
FlowViewport lerpViewport(
  FlowViewport a,
  FlowViewport b,
  double t, {
  FitViewInterpolation interpolate = FitViewInterpolation.smooth,
}) {
  final clamped = t.clamp(0.0, 1.0);
  final offset = Offset.lerp(a.offset, b.offset, clamped)!;
  double zoom;
  if (interpolate == FitViewInterpolation.linear ||
      a.zoom <= 0 ||
      b.zoom <= 0 ||
      (a.zoom - b.zoom).abs() < 1e-9) {
    zoom = a.zoom + (b.zoom - a.zoom) * clamped;
  } else {
    zoom = a.zoom * math.pow(b.zoom / a.zoom, clamped);
  }
  return FlowViewport(offset: offset, zoom: zoom);
}
