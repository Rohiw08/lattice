import 'package:flutter/widgets.dart';

/// Overlay anchor for a [LatticePanel] inside a [Stack].
enum LatticePanelPosition {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Zero-state overlay panel: positions [child] at [position] via a single
/// [Positioned] parent.
///
/// Must mount inside a [Stack] (the canvas pane stack or any overlay
/// stack). Pure layout — no state, no providers, no listeners.
class LatticePanel extends StatelessWidget {
  const LatticePanel({
    super.key,
    required this.position,
    required this.child,
  });

  final LatticePanelPosition position;

  final Widget child;

  // V3-6 Task 6: theme (panel chrome: padding, surface)
  static const double _margin = 16.0;

  @override
  Widget build(BuildContext context) {
    switch (position) {
      case LatticePanelPosition.topLeft:
        return Positioned(
          top: _margin,
          left: _margin,
          child: child,
        );
      case LatticePanelPosition.topCenter:
        return Positioned(
          top: _margin,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case LatticePanelPosition.topRight:
        return Positioned(
          top: _margin,
          right: _margin,
          child: child,
        );
      case LatticePanelPosition.centerLeft:
        return Positioned(
          left: _margin,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      case LatticePanelPosition.centerRight:
        return Positioned(
          right: _margin,
          top: 0,
          bottom: 0,
          child: Center(child: child),
        );
      case LatticePanelPosition.bottomLeft:
        return Positioned(
          bottom: _margin,
          left: _margin,
          child: child,
        );
      case LatticePanelPosition.bottomCenter:
        return Positioned(
          bottom: _margin,
          left: 0,
          right: 0,
          child: Center(child: child),
        );
      case LatticePanelPosition.bottomRight:
        return Positioned(
          bottom: _margin,
          right: _margin,
          child: child,
        );
    }
  }
}
