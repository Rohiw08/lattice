import 'dart:ui';

/// Builds the path for one edge between its resolved anchors.
///
/// [sourceRect]/[targetRect] are the endpoint nodes' absolute rects
/// (reserved for future port-side routing; the current curves only need
/// the anchors). [type] values: `'bezier'` (default), `'straight'`;
/// unknown types fall back to `'bezier'`.
Path latticeEdgePath({
  required Rect sourceRect,
  required Offset sourceAnchor,
  required Rect targetRect,
  required Offset targetAnchor,
  String type = 'bezier',
}) {
  switch (type) {
    case 'straight':
      return Path()
        ..moveTo(sourceAnchor.dx, sourceAnchor.dy)
        ..lineTo(targetAnchor.dx, targetAnchor.dy);
    case 'bezier':
    default:
      // Horizontal cubic: control offset is 40% of the horizontal gap
      // with a 20px floor, so short edges still curve.
      final double gap = (targetAnchor.dx - sourceAnchor.dx).abs();
      final double offset = gap * 0.4 < 20.0 ? 20.0 : gap * 0.4;
      return Path()
        ..moveTo(sourceAnchor.dx, sourceAnchor.dy)
        ..cubicTo(
          sourceAnchor.dx + offset,
          sourceAnchor.dy,
          targetAnchor.dx - offset,
          targetAnchor.dy,
          targetAnchor.dx,
          targetAnchor.dy,
        );
  }
}
