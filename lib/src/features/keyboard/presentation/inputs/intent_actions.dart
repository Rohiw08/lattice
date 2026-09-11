import 'package:flutter/widgets.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/core/options/flow_options.dart';

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class FitViewIntent extends Intent {
  const FitViewIntent();
}

class SelectAllIntent extends Intent {
  final bool selectNodes;
  final bool selectEdges;
  const SelectAllIntent({
    this.selectNodes = true,
    this.selectEdges = true,
  });
}

class DeleteIntent extends Intent {
  const DeleteIntent();
}

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class CopyIntent extends Intent {
  const CopyIntent();
}

class PasteIntent extends Intent {
  const PasteIntent();
}

Map<Type, Action<Intent>> buildActions(
  FlowCanvasInternalController controller,
  FlowCanvasOptions options,
) {
  return <Type, Action<Intent>>{
    ZoomInIntent: CallbackAction<ZoomInIntent>(
      onInvoke: (intent) {
        controller.viewport.zoomAtViewportCenter(
          zoomIn: true,
          minZoom: options.viewportOptions.minZoom,
          maxZoom: options.viewportOptions.maxZoom,
        );
        return null;
      },
    ),
    ZoomOutIntent: CallbackAction<ZoomOutIntent>(
      onInvoke: (intent) {
        controller.viewport.zoomAtViewportCenter(
          zoomIn: false,
          minZoom: options.viewportOptions.minZoom,
          maxZoom: options.viewportOptions.maxZoom,
        );
        return null;
      },
    ),
    FitViewIntent: CallbackAction<FitViewIntent>(
      onInvoke: (intent) {
        final v = options.viewportOptions;
        controller.viewport.fitView(
          viewportOptions: v,
          fitviewOptions: v.fitViewOptions,
        );
        return null;
      },
    ),
    SelectAllIntent: CallbackAction<SelectAllIntent>(
      onInvoke: (intent) {
        controller.selection.selectAll();
        return null;
      },
    ),
    DeleteIntent: CallbackAction<DeleteIntent>(
      onInvoke: (intent) {
        final state = controller.currentState;

        // Pre-compute deletable nodes and edges from INITIAL state
        final defaultNodeDeletable = options.nodeOptions.deletable;
        final deletableNodeIds = state.selectedNodes.where((id) {
          final n = state.nodes[id];
          if (n == null) return false;
          return n.deletable ?? defaultNodeDeletable;
        }).toList();

        final defaultEdgeDeletable = options.edgeOptions.deletable;
        final deletableEdgeIds = state.selectedEdges.where((id) {
          final e = state.edges[id];
          if (e == null) return false;
          return e.deletable ?? defaultEdgeDeletable;
        }).toList();

        // 1. Delete Nodes
        if (deletableNodeIds.isNotEmpty) {
          controller.selection.deselectAll();
          for (final id in deletableNodeIds) {
            controller.selection.selectNode(id, addToSelection: true);
          }
          controller.nodes.removeSelectedNodes();
        }

        // 2. Delete Edges (using pre-computed list)
        if (deletableEdgeIds.isNotEmpty) {
          controller.selection.deselectAll();
          for (final id in deletableEdgeIds) {
            controller.selection.selectEdge(id, addToSelection: true);
          }
          controller.edges.removeSelectedEdges();
        }

        return null;
      },
    ),
    UndoIntent: CallbackAction<UndoIntent>(
      onInvoke: (intent) {
        controller.history.undo();
        return null;
      },
    ),
    RedoIntent: CallbackAction<RedoIntent>(
      onInvoke: (intent) {
        controller.history.redo();
        return null;
      },
    ),
    CopyIntent: CallbackAction<CopyIntent>(
      onInvoke: (intent) {
        controller.clipboard.copySelection();
        return null;
      },
    ),
    PasteIntent: CallbackAction<PasteIntent>(
      onInvoke: (intent) {
        controller.clipboard.paste();
        return null;
      },
    ),
  };
}
