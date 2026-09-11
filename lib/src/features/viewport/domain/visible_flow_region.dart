import 'dart:math' as math;

import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart' show Matrix4, MatrixUtils;

/// Flow-space rectangle currently visible in the diagram pane (inverse of pan/zoom).
Rect computeVisibleFlowRect(FlowCanvasState state, {double padding = 0}) {
  final size = state.viewportSize;
  if (size == null || size.isEmpty) {
    return const Rect.fromLTRB(
      -1e9,
      -1e9,
      1e9,
      1e9,
    );
  }

  final z = state.viewport.zoom;
  final o = state.viewport.offset;
  Offset flow(Offset v) => Offset((v.dx - o.dx) / z, (v.dy - o.dy) / z);

  final a = flow(Offset.zero);
  final b = flow(Offset(size.width, size.height));
  final left = math.min(a.dx, b.dx) - padding;
  final right = math.max(a.dx, b.dx) + padding;
  final top = math.min(a.dy, b.dy) - padding;
  final bottom = math.max(a.dy, b.dy) + padding;
  return Rect.fromLTRB(left, top, right, bottom);
}

/// Same region as [computeVisibleFlowRect], but derived from the live
/// [TransformationController] matrix instead of [FlowCanvasState.viewport].
///
/// Use this for render culling while panning: [FlowCanvasInternalController]
/// may skip copying the matrix into [FlowViewport] when movement is within
/// [flowViewportNearEqual], so state can lag the actual transform.
Rect computeVisibleFlowRectFromCanvasTransform(
  Matrix4 canvasToViewer,
  Size viewportSize, {
  double padding = 0,
}) {
  if (viewportSize.isEmpty) {
    return const Rect.fromLTRB(
      -1e9,
      -1e9,
      1e9,
      1e9,
    );
  }

  final inv = Matrix4.inverted(canvasToViewer);
  Offset map(Offset v) => MatrixUtils.transformPoint(inv, v);

  final p0 = map(Offset.zero);
  final p1 = map(Offset(viewportSize.width, 0));
  final p2 = map(Offset(0, viewportSize.height));
  final p3 = map(Offset(viewportSize.width, viewportSize.height));

  final minX = math.min(math.min(p0.dx, p1.dx), math.min(p2.dx, p3.dx)) -
      padding;
  final maxX = math.max(math.max(p0.dx, p1.dx), math.max(p2.dx, p3.dx)) +
      padding;
  final minY = math.min(math.min(p0.dy, p1.dy), math.min(p2.dy, p3.dy)) -
      padding;
  final maxY = math.max(math.max(p0.dy, p1.dy), math.max(p2.dy, p3.dy)) +
      padding;

  return Rect.fromLTRB(minX, minY, maxX, maxY);
}

/// Whether [node]'s **absolute** bounds overlap [flowRect].
bool flowNodeOverlapsRect(
  FlowNode node,
  Rect flowRect,
  Map<String, FlowNode> nodes,
) {
  return NodeLayout.absoluteRect(node, nodes).overlaps(flowRect);
}
