import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_layout.dart';
import 'package:lattice/src/core/theme/components/minimap_theme.dart';
import 'package:lattice/src/features/minimap/presentation/flow_minimap.dart';

class MiniMapTransform {
  final double scale;
  final Offset offset;
  final Rect contentBounds;

  const MiniMapTransform({
    required this.scale,
    required this.offset,
    required this.contentBounds,
  });
}

class MiniMapPainter extends CustomPainter {
  final List<FlowNode> nodes;
  final Rect viewport;
  final FlowMinimapStyle theme;
  final Set<String> selectedNodeIds;
  final MiniMapNodeColorFunc? nodeColor;
  final MiniMapNodeColorFunc? nodeStrokeColor;
  final MiniMapNodeProperty<double>? nodeStrokeWidth;
  final MiniMapNodeProperty<double>? nodeBorderRadius;
  final MiniMapNodeBuilder? nodeBuilder;
  final Map<String, Offset> livePositions;

  /// Bumped by the interaction session on every live position change —
  /// drives [shouldRepaint] (live positions live in a single mutated map,
  /// whose identity never changes mid-drag).
  final int liveStamp;

  // Paints are inexpensive to create, no major change needed here.
  final Paint _backgroundPaint;
  final Paint _maskPaint;
  final Paint _maskStrokePaint;
  final Paint _nodePaint;
  final Paint _nodeStrokePaint;
  final Paint _viewportStrokePaint;
  final Paint _viewportFillPaint;

  MiniMapPainter({
    required this.nodes,
    required this.viewport,
    required this.theme,
    this.selectedNodeIds = const {},
    this.nodeColor,
    this.nodeStrokeColor,
    this.nodeStrokeWidth,
    this.nodeBorderRadius,
    this.nodeBuilder,
    this.livePositions = const {},
    this.liveStamp = 0,
  })  : _backgroundPaint = Paint()..color = theme.backgroundColor,
        _maskPaint = Paint()..color = theme.maskColor,
        _maskStrokePaint = Paint()
          ..color = theme.maskStrokeColor
          ..strokeWidth = theme.maskStrokeWidth
          ..style = PaintingStyle.stroke,
        _nodePaint = Paint()..style = PaintingStyle.fill,
        _nodeStrokePaint = Paint()..style = PaintingStyle.stroke,
        _viewportStrokePaint = Paint()
          ..color = theme.viewportBorderColor
          ..strokeWidth = theme.viewportBorderWidth
          ..style = PaintingStyle.stroke,
        _viewportFillPaint = Paint()
          ..color = theme.viewportColor
          ..style = PaintingStyle.fill;

  Color _resolveNodeColor(FlowNode node) {
    final override = nodeColor?.call(node);
    if (override != null) return override;

    final states = <MinimapNodeState>{};
    if (node.selectable == false) {
      states.add(MinimapNodeState.disabled);
    }
    if (selectedNodeIds.contains(node.id)) {
      states.add(MinimapNodeState.selected);
    }
    if (states.isEmpty) {
      states.add(MinimapNodeState.normal);
    }
    return theme.resolveNodeColor(states);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Calculations are now done in the widget and passed in,
    // but we still need them here for painting.
    final combinedBounds = getCombinedBounds(nodes, viewport);
    final transform = calculateTransform(combinedBounds, size, theme);

    canvas.save();
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), _backgroundPaint);

    if (transform.scale > 0) {
      final byId = {for (final n in nodes) n.id: n};
      _drawMask(canvas, transform, size);
      _drawNodes(canvas, transform, size, byId);
      _drawViewport(canvas, transform, size);
    }

    canvas.restore();
  }

  void _drawMask(
      Canvas canvas, MiniMapTransform transform, Size minimapSize) {
    final finalRect = fromCanvasToMiniMap(viewport, transform, minimapSize);
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, minimapSize.width, minimapSize.height))
      ..addRect(finalRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, _maskPaint);
    if (_maskStrokePaint.strokeWidth > 0) {
      canvas.drawRect(finalRect, _maskStrokePaint);
    }
  }

  void _drawNodes(Canvas canvas, MiniMapTransform transform, Size minimapSize,
      Map<String, FlowNode> byId) {
    for (final node in nodes) {
      if (nodeBuilder != null) {
        final customPath = nodeBuilder!(node);
        final matrix = Matrix4.identity()
          ..translateByDouble(
              transform.offset.dx, transform.offset.dy, 0.0, 1.0)
          ..scaleByDouble(transform.scale, transform.scale, 1.0, 1.0);
        final transformedPath = customPath.transform(matrix.storage);

        _nodePaint.color = _resolveNodeColor(node);
        canvas.drawPath(transformedPath, _nodePaint);

        final strokeWidth =
            nodeStrokeWidth?.call(node) ?? theme.nodeStrokeWidth;
        if (strokeWidth > 0) {
          _nodeStrokePaint.color =
              (nodeStrokeColor?.call(node) ?? theme.nodeStrokeColor);
          _nodeStrokePaint.strokeWidth = strokeWidth;
          canvas.drawPath(transformedPath, _nodeStrokePaint);
        }
      } else {
        final transformedRect = fromCanvasToMiniMap(
          NodeLayout.absoluteRect(node, byId, livePositions: livePositions),
          transform,
          minimapSize,
        );
        const minSize = 2.0;
        final adjustedRect = Rect.fromLTWH(
          transformedRect.left,
          transformedRect.top,
          math.max(transformedRect.width, minSize),
          math.max(transformedRect.height, minSize),
        );
        _nodePaint.color = _resolveNodeColor(node);
        final radius = nodeBorderRadius?.call(node) == null
            ? theme.nodeBorderRadius
            : BorderRadius.circular(nodeBorderRadius!.call(node));

        final rrect = RRect.fromRectAndRadius(adjustedRect, radius.topLeft);
        canvas.drawRRect(rrect, _nodePaint);

        final strokeWidth =
            nodeStrokeWidth?.call(node) ?? theme.nodeStrokeWidth;
        if (strokeWidth > 0) {
          _nodeStrokePaint.color =
              nodeStrokeColor?.call(node) ?? theme.nodeStrokeColor;
          _nodeStrokePaint.strokeWidth = strokeWidth;
          canvas.drawRRect(rrect, _nodeStrokePaint);
        }
      }
    }
  }

  void _drawViewport(
      Canvas canvas, MiniMapTransform transform, Size minimapSize) {
    if (viewport.isEmpty) return;
    final finalRect = fromCanvasToMiniMap(viewport, transform, minimapSize);
    canvas.drawRect(finalRect, _viewportFillPaint);
    if (_viewportStrokePaint.strokeWidth > 0) {
      canvas.drawRect(finalRect, _viewportStrokePaint);
    }
  }

  // Make this static so it can be called from the widget
  static Rect getCombinedBounds(
    List<FlowNode> nodes,
    Rect viewport, {
    Map<String, Offset> livePositions = const {},
  }) {
    if (nodes.isEmpty && viewport.isEmpty) return Rect.zero;
    Rect? combinedBounds;
    if (nodes.isNotEmpty) {
      final byId = {for (final n in nodes) n.id: n};
      combinedBounds = nodes
          .map((n) => NodeLayout.absoluteRect(n, byId,
              livePositions: livePositions))
          .reduce((a, b) => a.expandToInclude(b));
    }
    if (!viewport.isEmpty) {
      combinedBounds = combinedBounds?.expandToInclude(viewport) ?? viewport;
    }
    return combinedBounds?.inflate(
            math.max(combinedBounds.width, combinedBounds.height) * 0.1) ??
        Rect.zero;
  }

  static MiniMapTransform calculateTransform(
      Rect contentBounds, Size minimapSize, FlowMinimapStyle theme) {
    if (contentBounds.isEmpty || minimapSize.isEmpty) {
      return const MiniMapTransform(
          scale: 0, offset: Offset.zero, contentBounds: Rect.zero);
    }
    final padding = theme.padding;
    final paddedWidth = minimapSize.width - (padding * 2);
    final paddedHeight = minimapSize.height - (padding * 2);
    if (contentBounds.width <= 0 ||
        contentBounds.height <= 0 ||
        paddedWidth <= 0 ||
        paddedHeight <= 0) {
      return MiniMapTransform(
          scale: 0, offset: Offset.zero, contentBounds: contentBounds);
    }
    final scaleX = paddedWidth / contentBounds.width;
    final scaleY = paddedHeight / contentBounds.height;
    final scale = math.min(scaleX, scaleY);
    final scaledContentWidth = contentBounds.width * scale;
    final scaledContentHeight = contentBounds.height * scale;
    final offsetX = (minimapSize.width - scaledContentWidth) / 2 -
        (contentBounds.left * scale);
    final offsetY = (minimapSize.height - scaledContentHeight) / 2 -
        (contentBounds.top * scale);
    return MiniMapTransform(
        scale: scale,
        offset: Offset(offsetX, offsetY),
        contentBounds: contentBounds);
  }

  static Offset fromMiniMapToCanvas(
      Offset miniMapPosition, MiniMapTransform transform, Size minimapSize) {
    if (transform.scale == 0) return Offset.zero;
    return Offset(
      (miniMapPosition.dx - transform.offset.dx) / transform.scale,
      (miniMapPosition.dy - transform.offset.dy) / transform.scale,
    );
  }

  static Rect fromCanvasToMiniMap(
      Rect canvasRect, MiniMapTransform transform, Size minimapSize) {
    final left = canvasRect.left * transform.scale + transform.offset.dx;
    final top = canvasRect.top * transform.scale + transform.offset.dy;
    return Rect.fromLTWH(left, top, canvasRect.width * transform.scale,
        canvasRect.height * transform.scale);
  }

  @override
  bool shouldRepaint(covariant MiniMapPainter oldDelegate) {
    return oldDelegate.nodes != nodes ||
        oldDelegate.viewport != viewport ||
        oldDelegate.theme != theme ||
        oldDelegate.selectedNodeIds != selectedNodeIds ||
        oldDelegate.nodeColor != nodeColor ||
        oldDelegate.nodeStrokeColor != nodeStrokeColor ||
        oldDelegate.nodeStrokeWidth != nodeStrokeWidth ||
        oldDelegate.nodeBorderRadius != nodeBorderRadius ||
        oldDelegate.nodeBuilder != nodeBuilder ||
        oldDelegate.livePositions != livePositions ||
        oldDelegate.liveStamp != liveStamp;
  }
}
