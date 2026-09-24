// ignore_for_file: unnecessary_library_name

/// Coordinate conventions for Flow Canvas (React Flow + Flutter style).
///
/// **Flow (graph) space — single source of truth**
/// Node positions, edges, and saved state: use one [Offset] in this unbounded plane.
///
/// **Viewport (viewer local)** — diagram pane coordinates; related to flow via
/// [FlowViewport]: `viewport = flow * zoom + pan`.
///
/// **Flutter global** — [PointerEvent.position], drag/drop offsets; convert through
/// the diagram host [RenderBox] then [ViewportController.flowPositionFromGlobal].
///
/// Gestures on widgets **inside** [InteractiveViewer] already receive positions /
/// deltas in flow space where documented—do not divide drag deltas by zoom.
library flow_coordinates;
