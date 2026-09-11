import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Live camera transform for overlays (background, minimap) without writing
/// Freezed [FlowCanvasState] every pan/zoom tick.
///
/// Visual pan/zoom is owned by [TransformationController]; this notifier
/// mirrors it for widgets that sit *outside* the transformed stack.
class LiveViewport extends ChangeNotifier {
  FlowViewport _viewport;

  LiveViewport([FlowViewport? initial])
      : _viewport = initial ?? const FlowViewport();

  FlowViewport get viewport => _viewport;

  double get zoom => _viewport.zoom;
  Offset get offset => _viewport.offset;

  /// Updates without notifying if values are near-equal (reduces overlay churn).
  void setViewport(FlowViewport next, {bool force = false}) {
    if (!force &&
        (next.offset - _viewport.offset).distance < 0.25 &&
        (next.zoom - _viewport.zoom).abs() < 1e-4) {
      return;
    }
    _viewport = next;
    notifyListeners();
  }
}
