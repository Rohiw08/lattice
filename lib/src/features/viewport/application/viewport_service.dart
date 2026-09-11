import 'dart:math';
import 'package:lattice/src/core/options/components/fitview_options.dart';
import 'package:lattice/src/core/options/components/viewport_options.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/painting.dart';

import '../../nodes/domain/models/node.dart';

typedef NodeBounds = ({Rect rect, List<FlowNode> nodes});

/// Pan/zoom and **flow** ↔ **viewport** conversion ([FlowViewport]).
///
/// Flow (graph) space is the only persisted coordinate system. Viewport space is
/// the diagram pane’s local coordinates (origin top-left of [InteractiveViewer]).
class ViewportService {
  ViewportService();

  // --- Flow ↔ viewport (same math as Lattice screen ↔ flow with “viewport” = pane local) ---

  /// Viewer-local point → flow (graph) coordinates.
  Offset viewportToFlow(FlowCanvasState state, Offset viewport) {
    return (viewport - state.viewport.offset) / state.viewport.zoom;
  }

  /// Flow (graph) coordinates → viewer-local point.
  Offset flowToViewport(FlowCanvasState state, Offset flow) {
    return flow * state.viewport.zoom + state.viewport.offset;
  }

  /// Clamps [FlowViewport.offset] to [translateExtent] (Lattice `translateExtent`).
  FlowViewport clampViewport(FlowViewport viewport, CoordinateExtent extent) {
    if (extent.isInfinite) return viewport;
    return viewport.copyWith(
      offset: Offset(
        viewport.offset.dx.clamp(extent.minX, extent.maxX),
        viewport.offset.dy.clamp(extent.minY, extent.maxY),
      ),
    );
  }

  FlowCanvasState _withClampedPan(
    FlowCanvasState state,
    CoordinateExtent translateExtent,
  ) {
    if (translateExtent.isInfinite) return state;
    final next = clampViewport(state.viewport, translateExtent);
    if (next == state.viewport) return state;
    return state.copyWith(viewport: next);
  }

  /// Re-applies [translateExtent] after a viewport change (e.g. [resetView]).
  FlowCanvasState applyTranslateExtent(
    FlowCanvasState state,
    CoordinateExtent translateExtent,
  ) {
    return _withClampedPan(state, translateExtent);
  }

  // --- VIEWPORT MANIPULATION ---

  /// Pans by a delta in **viewport** space (same units as [FlowViewport.offset]).
  FlowCanvasState pan(
    FlowCanvasState state,
    Offset delta,
    CoordinateExtent translateExtent,
  ) {
    final moved = state.copyWith(
      viewport: state.viewport.copyWith(offset: state.viewport.offset + delta),
    );
    return _withClampedPan(moved, translateExtent);
  }

  /// Zooms; [focalViewportPoint] is in **viewport** space (viewer local).
  FlowCanvasState zoom(
    FlowCanvasState state, {
    required double zoomFactor,
    required Offset focalViewportPoint,
    required double minZoom,
    required double maxZoom,
    required CoordinateExtent translateExtent,
  }) {
    final newZoom = (state.viewport.zoom * zoomFactor).clamp(minZoom, maxZoom);

    if (newZoom == state.viewport.zoom) {
      return _withClampedPan(state, translateExtent);
    }
    final flowPoint = viewportToFlow(state, focalViewportPoint);
    final newOffset = focalViewportPoint - (flowPoint * newZoom);

    final zoomed = state.copyWith(
      viewport: FlowViewport(offset: newOffset, zoom: newZoom),
    );
    return _withClampedPan(zoomed, translateExtent);
  }

  FlowCanvasState centerOnPosition(
    FlowCanvasState state,
    Offset flowPosition, {
    required CoordinateExtent translateExtent,
  }) {
    if (state.viewportSize == null) return state;

    final newOffset = (flowPosition * state.viewport.zoom * -1) +
        Offset(state.viewportSize!.width / 2, state.viewportSize!.height / 2);

    final next = state.copyWith(
      viewport: state.viewport.copyWith(offset: newOffset),
    );
    return _withClampedPan(next, translateExtent);
  }

  /// Fits nodes in the diagram; uses **viewport** dimensions from state.
  FlowCanvasState fitView({
    required FlowCanvasState state,
    required ViewportOptions viewportOptions,
    required FitViewOptions fitViewOptions,
  }) {
    final viewportSize = state.viewportSize;
    if (viewportSize == null || viewportSize.isEmpty) return state;

    final allNodes = state.nodes.values.toList();
    final nodes = fitViewOptions.nodes.isEmpty
        ? allNodes
        : allNodes
            .where((n) => fitViewOptions.nodes.contains(n.id))
            .toList();
    final bounds = getNodeBounds(
        nodes: nodes, includeHidden: fitViewOptions.includeHiddenNodes);
    if (bounds.nodes.isEmpty || bounds.rect.isEmpty) return state;

    final availableWidth =
        viewportSize.width - fitViewOptions.padding.horizontal;
    final availableHeight =
        viewportSize.height - fitViewOptions.padding.vertical;

    if (availableWidth <= 0 || availableHeight <= 0) return state;

    final scaleX = availableWidth / bounds.rect.width;
    final scaleY = availableHeight / bounds.rect.height;
    final idealZoom = min(scaleX, scaleY);

    final effectiveMinZoom =
        max(viewportOptions.minZoom, fitViewOptions.minZoom);
    final effectiveMaxZoom =
        min(viewportOptions.maxZoom, fitViewOptions.maxZoom);

    final newZoom = idealZoom.clamp(effectiveMinZoom, effectiveMaxZoom);

    final scaledContentWidth = bounds.rect.width * newZoom;
    final scaledContentHeight = bounds.rect.height * newZoom;

    final newOffsetX = (viewportSize.width - scaledContentWidth) / 2 -
        (bounds.rect.left * newZoom);
    final newOffsetY = (viewportSize.height - scaledContentHeight) / 2 -
        (bounds.rect.top * newZoom);

    final next = state.copyWith(
      viewport:
          FlowViewport(offset: Offset(newOffsetX, newOffsetY), zoom: newZoom),
    );
    return _withClampedPan(next, viewportOptions.translateExtent);
  }

  // --- UTILITY METHODS ---

  NodeBounds getNodeBounds({
    List<FlowNode> nodes = const [],
    bool includeHidden = false,
  }) {
    final nodesToConsider = nodes.where((node) {
      final isVisible = includeHidden || !(node.hidden ?? false);
      return isVisible;
    }).toList();

    if (nodesToConsider.isEmpty) {
      return (rect: Rect.zero, nodes: []);
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    final lookup = {for (final n in nodes) n.id: n};

    for (final node in nodesToConsider) {
      final nodeRect = NodeLayout.absoluteRect(node, lookup);

      minX = min(minX, nodeRect.left);
      minY = min(minY, nodeRect.top);
      maxX = max(maxX, nodeRect.right);
      maxY = max(maxY, nodeRect.bottom);
    }

    return (
      rect: Rect.fromLTRB(minX, minY, maxX, maxY),
      nodes: nodesToConsider
    );
  }
}
