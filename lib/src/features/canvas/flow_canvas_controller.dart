import 'package:lattice/src/features/viewport/application/viewport_controller.dart';
import 'package:lattice/src/core/document/canvas_document.dart';
import 'package:flutter/foundation.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_controller.dart';
import 'package:lattice/src/features/connections/application/connection_controller.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_controller.dart';
import 'package:lattice/src/features/edges/application/edges_controller.dart';
import 'package:lattice/src/features/handles/application/handles_controller.dart';
import 'package:lattice/src/features/history/application/history_controller.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_controller.dart';
import 'package:lattice/src/features/nodes/application/nodes_controller.dart';
import 'package:lattice/src/features/selection/application/selection_controller.dart';
import 'package:lattice/src/features/z_index/application/z_index_controller.dart';

/// A public-facing controller (facade) for interacting with a FlowCanvas widget.
///
/// Create an instance of this controller and pass it to the [FlowCanvas]
/// widget's constructor to gain imperative control over the canvas.
///
/// This pattern hides the internal Riverpod state management from the widget's
/// user, providing a more traditional Flutter "controller-widget" API.
///
/// ### Example:
///
/// ```dart
/// class MyEditor extends StatefulWidget {
///   @override
///   _MyEditorState createState() => _MyEditorState();
/// }
///
/// class _MyEditorState extends State<MyEditor> {
///   // 1. Create the controller
///   late final FlowCanvasController _controller;
///
///   @override
///   void initState() {
///     super.initState();
///     _controller = FlowCanvasController();
///   }
///
///   void _addNode() {
///     // 3. Use the controller's API
///     _controller.nodes.addNode(
///       FlowNode.create(id: 'new-node', type: 'default', position: Offset.zero, data: {}),
///     );
///   }
///
///   @override
///   Widget build(BuildContext context) {
///     return Column(
///       children: [
///         ElevatedButton(onPressed: _addNode, child: Text('Add Node')),
///         Expanded(
///           child: FlowCanvas(
///             // 2. Pass the controller to the widget
///             controller: _controller,
///             nodeRegistry: myNodeRegistry,
///             edgeRegistry: myEdgeRegistry,
///           ),
///         ),
///       ],
///     );
///   }
/// }
/// ```
class FlowCanvasController {
  FlowCanvasInternalController? _internalController;
  final List<void Function(FlowCanvasState)> _listeners = [];

  /// Whether this controller is currently attached to a [FlowCanvas] widget.
  bool get isAttached => _internalController != null;

  /// Returns the internal controller, asserting that this facade is attached.
  FlowCanvasInternalController get _internal {
    if (_internalController == null) {
      throw StateError(
          'FlowCanvasController is not attached to a FlowCanvas widget. '
          'Ensure you have passed this controller to the FlowCanvas widget '
          'and it has been initialized.');
    }
    return _internalController!;
  }

  /// Internal method for the FlowCanvas widget to link the controllers.
  /// Not for public use.
  @internal
  void attach(FlowCanvasInternalController internalController) {
    if (_internalController != null) {
      if (kDebugMode) {
        debugPrint('FlowCanvasController is being re-attached. '
            'This is usually fine during hot reload.');
      }
    }
    _internalController = internalController;
    for (final listener in _listeners) {
      _internalController!.addListener(listener);
    }
  }

  /// Internal method for the FlowCanvas widget to unlink the controllers.
  /// Not for public use.
  @internal
  void detach() {
    for (final listener in _listeners) {
      _internalController?.removeListener(listener);
    }
    _internalController = null;
  }

  /// Access the current, immutable state of the canvas.
  FlowCanvasState get currentState => _internal.currentState;

  /// Replaces the current canvas state with a new one.
  ///
  /// Typically used for loading a saved graph. Resets undo history —
  /// prefer the granular `nodes` / `edges` / `selection` APIs for
  /// incremental updates, and [applyRemote] for live collaboration.
  void load(FlowCanvasState state) => _internal.load(state);

  /// Returns the current canvas state serialized as JSON.
  /// Symmetric counterpart to [load] for save/restore workflows.
  Map<String, dynamic> toJson() => _internal.currentState.toJson();

  /// Serializes the canvas as a versioned document envelope (`{v, state}`).
  ///
  /// Prefer this over [toJson] for on-disk save files: the version tag lets
  /// [loadDocument] migrate graphs written by an older schema. Restore with
  /// [loadDocument]. Use plain [toJson]/[load] when you don't need versioning.
  Map<String, dynamic> saveDocument() =>
      CanvasDocument.fromState(_internal.currentState).toJson();

  /// Restores a canvas from a versioned document produced by [saveDocument],
  /// applying any schema migration for the document's version. Resets undo
  /// history, exactly like [load].
  void loadDocument(Map<String, dynamic> json) =>
      _internal.load(CanvasDocument.fromJson(json).state);

  /// Returns the canvas state serialized for multiplayer sync: like [toJson]
  /// but strips per-client UI state (selection), which must never be shared.
  /// Pair with [applyRemote] on the receiving side.
  Map<String, dynamic> toSyncJson() => _internal.currentState.toSyncJson();

  /// Applies a remote collaborator's graph without touching local UI state
  /// (selection, viewport) or undo history.
  ///
  /// Multiplayer counterpart to [load] (which resets history and takes over
  /// everything — right for file-open, wrong for live collab). Decoded from
  /// a peer's [toSyncJson]; emits no `onNodesChange`/`onEdgesChange` so sync
  /// adapters can't echo-loop (observe via [addListener] if needed).
  void applyRemote(FlowCanvasState state) => _internal.applyRemote(state);

  /// Returns the nodes, edges and viewport as an object (Lattice
  /// `toObject` / `ReactFlowJsonObject`). Pair with [load] to restore.
  ReactFlowJsonObject toObject() {
    final s = currentState;
    return (
      nodes: s.nodes.values.toList(),
      edges: s.edges.values.toList(),
      viewport: s.viewport,
    );
  }

  /// Pushes the current graph state as an undo checkpoint without mutating.
  void commitHistoryCheckpoint() => _internal.commitHistoryCheckpoint();

  /// Flips the master element-interaction switch (Lattice `setInteractive`).
  ///
  /// While false, node drag/select, edge select, connection starts, and
  /// marquees stop; viewport, pointer observations, and programmatic APIs
  /// keep working. Transient (no history entry, not serialized). The
  /// `FlowCanvasControls` `showInteractive` button drives the same flag.
  void setInteractive(bool interactive) =>
      _internal.setInteractive(interactive);

  /// Removes nodes (with descendants) and edges in a single undo step.
  ///
  /// Lattice `deleteElements` counterpart — see
  /// [FlowCanvasInternalController.deleteElements] for semantics.
  /// Returns the removed objects.
  FlowDeletedElements deleteElements({
    Iterable<String> nodeIds = const {},
    Iterable<String> edgeIds = const {},
  }) =>
      _internal.deleteElements(nodeIds: nodeIds, edgeIds: edgeIds);

  /// Adds a listener that is called whenever the canvas state changes.
  void addListener(void Function(FlowCanvasState) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      _internalController?.addListener(listener);
    }
  }

  /// Removes a previously added listener.
  void removeListener(void Function(FlowCanvasState) listener) {
    _listeners.remove(listener);
    _internalController?.removeListener(listener);
  }

  // --- Delegated Sub-Controllers ---

  /// Controller for all node-related actions (add, remove, update, drag).
  NodesController get nodes => _internal.nodes;

  /// Controller for all edge-related actions (add, remove, update, reconnect).
  EdgesController get edges => _internal.edges;

  /// Controller for managing selection (nodes, edges, box selection).
  SelectionController get selection => _internal.selection;

  /// Controller for managing the viewport (pan, zoom, fitView).
  ViewportController get viewport => _internal.viewport;

  /// Controller for managing active connection-dragging state.
  ConnectionController get connection => _internal.connection;

  /// Controller for clipboard actions (copy, paste).
  ClipboardController get clipboard => _internal.clipboard;

  /// Controller for undo/redo history.
  HistoryController get history => _internal.history;

  /// Controller for managing handle hover/active states.
  HandleController get handle => _internal.handle;

  /// Controller for managing edge geometry and hit-testing.
  EdgeGeometryController get edgeGeometry => _internal.edgeGeometry;

  /// Controller for managing node z-index (bring to front, send to back).
  ZIndexController get zIndex => _internal.zIndex;

  /// Controller for handling keyboard actions.
  KeyboardController get keyboard => _internal.keyboard;
}
