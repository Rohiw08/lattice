import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:flutter/foundation.dart';

/// Bundle of the primary configuration objects for [FlowCanvas].
///
/// **Uncontrolled (the only mode):** the canvas owns its [FlowCanvasState]
/// internally. Drive it imperatively through [FlowCanvasController] and
/// observe it through [FlowCanvasCallbacks] — there are no `nodes`/`edges`
/// props that sync back and forth.
///
/// **Persistence / wholesale replace:** use `controller.toJson()` to save
/// and `controller.load(state)` to restore (file open, template switch,
/// session restore). Note `load` replaces the document and resets undo
/// history — it is not a per-change mirroring tool. For per-change
/// mirroring into app state, subscribe to the callbacks instead.
@immutable
class FlowCanvasConfig {
  FlowCanvasConfig({
    FlowCanvasOptions? options,
    this.callbacks = const FlowCanvasCallbacks(),
  }) : options = options ?? FlowCanvasOptions();

  final FlowCanvasOptions options;
  final FlowCanvasCallbacks callbacks;
}

/// Typedef for API docs parity with Lattice "props" naming.
typedef FlowCanvasProps = FlowCanvasConfig;
