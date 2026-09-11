// Constants for the Flutter Workflow package
class FlowConstants {
  // Viewport settings
  static const double defaultMinZoom = 0.1;
  static const double defaultMaxZoom = 2.0;
  static const double defaultZoomStep = 0.1;

  // Spatial indexing
  static const double defaultCellSize = 200.0;

  // UI constants
  static const double autoPanEdge = 24.0;
  static const double autoPanSpeed = 1.0;

  // Grid snapping
  static const double defaultGridWidth = 10.0;
  static const double defaultGridHeight = 10.0;

  // Animation durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);

  // Selection
  static const double selectionTolerance = 5.0;

  // Connection
  static const double connectionTolerance = 10.0;
  static const double handleSize = 8.0;
}
