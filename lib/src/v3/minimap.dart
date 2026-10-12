import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_cull.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'lattice_theme.dart';
import 'lattice_viewport_value.dart';
import 'session_providers.dart';

/// Canvas minimap: paints every document node rect plus the current
/// viewport rect into a [size] square. Mounts ZERO node widgets (pure
/// `CustomPaint`, single-paint discipline: one `drawRect` per node).
///
/// Content bounds are the union of the document absolute rects with the
/// canvas default origin ([Offset.zero] — the canvas default origin is a
/// V3-6 options concern; this widget assumes zero). Bounds fit the square
/// with a uniform scale and centering.
///
/// Dragging inside the minimap pans the camera so the pressed content
/// point lands at the pane center. Writes the camera matrix only — never
/// the document, so zero document notifications. [onViewportChange] fires
/// on drag end with the current viewport value (null-safe: ignored when
/// null).
///
/// Reuse note: [LatticeLodPainter] (node_layer.dart) paints node rects in
/// untransformed FLOW space, but the minimap needs rects pre-mapped into
/// minimap space (uniform fit scale + centering). Reusing it would still
/// require a second transform stage, so this widget draws rects directly
/// with the same single-paint discipline instead.
class LatticeMinimap extends ConsumerWidget {
  const LatticeMinimap({super.key, this.size = 180, this.onViewportChange});

  final double size;
  final ValueChanged<LatticeViewportValue>? onViewportChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, LatticeNode> nodes = ref.watch(latticeNodesProvider);
    final Matrix4 matrix = ref.watch(latticeCameraProvider);
    final Size? paneSize = ref.watch(latticePaneSizeProvider);

    final Rect bounds = _contentBounds(nodes);
    final _MinimapMapping mapping = _MinimapMapping(bounds, size);
    final LatticeTheme theme =
        LatticeThemeScope.maybeOf(context) ?? LatticeTheme.light();
    final LatticeMinimapStyle style = theme.resolvedMinimap;

    final List<Rect> nodeRects = <Rect>[
      for (final String id in nodes.keys)
        mapping.flowToMini(
          latticeAbsoluteRect(nodes, id, defaultOrigin: Offset.zero),
        ),
    ];

    Rect? viewportRect;
    if (paneSize != null) {
      final Rect flowRect = MatrixUtils.inverseTransformRect(
        matrix,
        Offset.zero & paneSize,
      );
      if (flowRect.isFinite) {
        viewportRect = mapping.flowToMini(flowRect);
      }
    }

    void centerOn(Offset local) {
      final LatticeCameraController camera = ref.read(
        latticeCameraProvider.notifier,
      );
      final Size? pane = ref.read(latticePaneSizeProvider);
      if (pane == null) return;
      final LatticeViewportValue viewport = camera.viewport;
      final Offset flow = mapping.miniToFlow(local);
      final Offset center = Offset(pane.width / 2, pane.height / 2);
      camera.setViewport(
        viewport.copyWith(offset: center - flow * viewport.zoom),
      );
    }

    void fireViewportChanged() {
      onViewportChange?.call(
        ref.read(latticeCameraProvider.notifier).viewport,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: GestureDetector(
        onPanStart: (DragStartDetails details) =>
            centerOn(details.localPosition),
        onPanUpdate: (DragUpdateDetails details) =>
            centerOn(details.localPosition),
        onPanEnd: (_) => fireViewportChanged(),
        child: Stack(
          children: <Widget>[
            CustomPaint(
              size: Size.square(size),
              painter: _MinimapNodePainter(
                rects: nodeRects,
                background: style.background,
                nodeColor: style.node,
              ),
            ),
            CustomPaint(
              key: const ValueKey<String>('minimapViewport'),
              size: Size.square(size),
              painter: _MinimapViewportPainter(
                rect: viewportRect,
                color: style.viewport,
                strokeWidth: style.viewportWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Union of the document absolute rects (default origin [Offset.zero];
/// see [LatticeMinimap] docs). Falls back to a 1x1 rect at the origin
/// when the document has no nodes, so the fit scale stays finite.
Rect _contentBounds(Map<String, LatticeNode> nodes) {
  Rect? bounds;
  for (final String id in nodes.keys) {
    final Rect rect = latticeAbsoluteRect(
      nodes,
      id,
      defaultOrigin: Offset.zero,
    );
    bounds = bounds == null ? rect : bounds.expandToInclude(rect);
  }
  return bounds ?? const Rect.fromLTWH(0, 0, 1, 1);
}

/// Uniform-fit mapping between flow space and the minimap square.
class _MinimapMapping {
  _MinimapMapping(Rect bounds, double size)
    : _scale = _fitScale(bounds, size),
      _offset = _fitOffset(bounds, _fitScale(bounds, size), size);

  final double _scale;
  final Offset _offset;

  static double _fitScale(Rect bounds, double size) {
    final double w = bounds.width == 0 ? 1 : bounds.width;
    final double h = bounds.height == 0 ? 1 : bounds.height;
    return size / (w > h ? w : h);
  }

  static Offset _fitOffset(Rect bounds, double scale, double size) {
    final double w = (bounds.width == 0 ? 1 : bounds.width) * scale;
    final double h = (bounds.height == 0 ? 1 : bounds.height) * scale;
    return Offset(
      (size - w) / 2 - bounds.left * scale,
      (size - h) / 2 - bounds.top * scale,
    );
  }

  Rect flowToMini(Rect rect) {
    return Rect.fromLTWH(
      _offset.dx + rect.left * _scale,
      _offset.dy + rect.top * _scale,
      rect.width * _scale,
      rect.height * _scale,
    );
  }

  Offset miniToFlow(Offset local) {
    return Offset(
      (local.dx - _offset.dx) / _scale,
      (local.dy - _offset.dy) / _scale,
    );
  }
}

/// Paints the minimap surface fill, then one filled rect per node
/// (single [Paint], single paint pass).
class _MinimapNodePainter extends CustomPainter {
  _MinimapNodePainter({
    required this.rects,
    required this.background,
    required this.nodeColor,
  });

  final List<Rect> rects;
  final Color background;
  final Color nodeColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = background,
    );
    final Paint paint = Paint()..color = nodeColor;
    for (final Rect rect in rects) {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MinimapNodePainter oldDelegate) {
    if (background != oldDelegate.background ||
        nodeColor != oldDelegate.nodeColor) {
      return true;
    }
    if (rects.length != oldDelegate.rects.length) return true;
    for (var i = 0; i < rects.length; i++) {
      if (rects[i] != oldDelegate.rects[i]) return true;
    }
    return false;
  }
}

/// Paints the viewport rect as a stroked outline.
class _MinimapViewportPainter extends CustomPainter {
  _MinimapViewportPainter({
    required this.rect,
    required this.color,
    required this.strokeWidth,
  });

  final Rect? rect;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect? target = rect;
    if (target == null) return;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRect(target, paint);
  }

  @override
  bool shouldRepaint(covariant _MinimapViewportPainter oldDelegate) {
    return rect != oldDelegate.rect ||
        color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}
