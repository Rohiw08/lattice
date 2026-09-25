import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/edge_index.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_index.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SelectionService selection;
  late FlowCanvasState base;
  late NodeIndex nodeIndex;
  late EdgeIndex edgeIndex;

  setUp(() {
    selection = SelectionService();
    final nodes = NodeService().addNodes(const FlowCanvasState(), [
      FlowNode<String>(
        id: 'a',
        type: 'default',
        position: const Offset(0, 0),
        size: const Size(100, 40),
        data: 'A',
        resizable: false,
      ),
      FlowNode<String>(
        id: 'b',
        type: 'default',
        position: const Offset(200, 0),
        size: const Size(100, 40),
        data: 'B',
        resizable: false,
      ),
    ]);
    base = nodes.copyWith(
      edges: {
        'e1': const FlowEdge(
          id: 'e1',
          sourceNodeId: 'a',
          targetNodeId: 'b',
          type: EdgePathType.bezier,
        ),
      },
    );
    nodeIndex = NodeIndex.fromNodes(base.nodes.values);
    edgeIndex = EdgeIndex.fromEdges(base.edges);
  });

  test('box select partial includes overlapping nodes and connecting edge', () {
    var state = selection.startBoxSelection(base, Offset.zero);
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(250, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );

    expect(state.selectedNodes, {'a', 'b'});
    expect(state.selectedEdges, {'e1'});
    expect(state.nodeStates['a']!.selected, isTrue);
  });

  test('box select includes an edge with only one endpoint selected (RF OR)',
      () {
    // React Flow parity: box selection marks every edge connected to a selected
    // node (getConnectedEdges uses source OR target), even when the other
    // endpoint sits outside the marquee. Here the box captures only node a;
    // edge e1 (a→b) must still be selected though b is untouched.
    var state = selection.startBoxSelection(base, Offset.zero);
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(150, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );

    expect(state.selectedNodes, {'a'});
    expect(state.selectedEdges, {'e1'});
    expect(state.edgeStates['e1']!.selected, isTrue);
  });

  test('box select full requires node entirely inside', () {
    var state = selection.startBoxSelection(base, Offset.zero);
    // Covers only left half of node a (100 wide) → partial would include, full not.
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(50, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.full,
    );
    expect(state.selectedNodes, isEmpty);

    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(120, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.full,
    );
    expect(state.selectedNodes, {'a'});
  });

  test('membership-unchanged frame updates rect but preserves selection flags',
      () {
    var state = selection.startBoxSelection(base, Offset.zero);
    // First frame: box selects only node a (b starts at x=200).
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(150, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );
    expect(state.selectedNodes, {'a'});
    expect(state.nodeStates['a']!.selected, isTrue);

    // Second frame: box grows but still selects only a → fast path. The rect
    // must update while the selection + runtime flags are preserved untouched.
    final grown = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(180, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );
    expect(grown.selectedNodes, {'a'});
    expect(grown.nodeStates['a']!.selected, isTrue);
    expect(grown.selectionRect, const Rect.fromLTRB(0, 0, 180, 50));
  });

  test('shrinking membership clears the deselected node flag', () {
    var state = selection.startBoxSelection(base, Offset.zero);
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(250, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );
    expect(state.selectedNodes, {'a', 'b'});

    // Box shrinks to drop b → membership changed → full path re-runs and must
    // flip b's runtime flag back off.
    state = selection.updateBoxSelection(
      state,
      Offset.zero,
      const Offset(150, 50),
      nodeIndex,
      edgeIndex,
      selectionMode: SelectionMode.partial,
    );
    expect(state.selectedNodes, {'a'});
    expect(state.nodeStates['a']!.selected, isTrue);
    expect(state.nodeStates['b']!.selected, isFalse);
  });
}
