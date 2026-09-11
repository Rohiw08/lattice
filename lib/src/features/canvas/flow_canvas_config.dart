import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:flutter/foundation.dart';

/// Bundle of the primary configuration objects for [FlowCanvas].
///
/// **Uncontrolled (default):** the canvas stores [FlowCanvasState] internally. Use
/// [FlowCanvasCallbacks] to observe changes and mirror them into your app state.
///
/// **Controlled / external state:** own your graph in a `StateNotifier` or
/// Bloc, apply updates from callbacks, and pass the result back by mutating
/// through [FlowCanvasController] (e.g. `load`, `mutate` on the internal
/// controller via the public API) or by rebuilding [FlowCanvas] with a new
/// [FlowCanvasState] as `initialState` when the widget is first created.
@immutable
class FlowCanvasConfig {
  const FlowCanvasConfig({
    this.options = const FlowCanvasOptions(),
    this.callbacks = const FlowCanvasCallbacks(),
  });

  final FlowCanvasOptions options;
  final FlowCanvasCallbacks callbacks;
}

/// Typedef for API docs parity with Lattice "props" naming.
typedef FlowCanvasProps = FlowCanvasConfig;
