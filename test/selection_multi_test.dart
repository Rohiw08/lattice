import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SelectionService selection;
  late FlowCanvasState base;

  setUp(() {
    selection = SelectionService();
    final nodes = NodeService().addNodes(const FlowCanvasState(), [
      FlowNode<String>(
        id: 'a',
        type: 'default',
        position: Offset.zero,
        data: 'A',
        resizable: false,
      ),
      FlowNode<String>(
        id: 'b',
        type: 'default',
        position: const Offset(100, 0),
        data: 'B',
        resizable: false,
      ),
      FlowNode<String>(
        id: 'c',
        type: 'default',
        position: const Offset(200, 0),
        data: 'C',
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
        'e2': const FlowEdge(
          id: 'e2',
          sourceNodeId: 'b',
          targetNodeId: 'c',
          type: EdgePathType.bezier,
        ),
      },
    );
  });

  test('exclusive click replaces selection', () {
    var state = selection.toggleNodeSelection(base, 'a');
    expect(state.selectedNodes, {'a'});

    state = selection.toggleNodeSelection(state, 'b');
    expect(state.selectedNodes, {'b'});
  });

  test('exclusive re-click of selected node is no-op (Lattice)', () {
    var state = selection.toggleNodeSelection(base, 'a');
    state = selection.toggleNodeSelection(state, 'a');
    expect(state.selectedNodes, {'a'});
  });

  test('multi-select adds and toggles off (Lattice)', () {
    var state = selection.toggleNodeSelection(base, 'a', addToSelection: true);
    state = selection.toggleNodeSelection(state, 'b', addToSelection: true);
    expect(state.selectedNodes, {'a', 'b'});

    state = selection.toggleNodeSelection(state, 'a', addToSelection: true);
    expect(state.selectedNodes, {'b'});
  });

  test('multi-select edges does not clear nodes', () {
    var state = selection.toggleNodeSelection(base, 'a', addToSelection: true);
    state = selection.toggleEdgeSelection(state, 'e1', addToSelection: true);
    expect(state.selectedNodes, {'a'});
    expect(state.selectedEdges, {'e1'});
  });

  test('exclusive edge select clears nodes', () {
    var state = selection.toggleNodeSelection(base, 'a');
    state = selection.toggleEdgeSelection(state, 'e1');
    expect(state.selectedNodes, isEmpty);
    expect(state.selectedEdges, {'e1'});
  });

  test('default multiSelectionKeys is Control or Meta by platform', () {
    final keys = KeyboardOptions.defaultMultiSelectionKeys();
    expect(
      keys,
      anyOf(
        {LogicalKeyboardKey.control},
        {LogicalKeyboardKey.meta},
      ),
    );
    expect(const KeyboardOptions(multiSelectionKeys: {}).isMultiSelectionActive,
        isFalse);
  });

  test('control synonym maps through isControlPressed helper path', () {
    // Regression: isLogicalKeyPressed(LogicalKeyboardKey.control) is always
    // false; multi-select must use HardwareKeyboard.isControlPressed.
    expect(
      KeyboardOptions.isAnyMultiSelectionKeyPressed(
        {LogicalKeyboardKey.control},
      ),
      HardwareKeyboard.instance.isControlPressed,
    );
    expect(
      KeyboardOptions.isAnyMultiSelectionKeyPressed(
        {LogicalKeyboardKey.meta},
      ),
      HardwareKeyboard.instance.isMetaPressed,
    );
  });
}
