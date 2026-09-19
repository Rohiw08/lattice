import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Unified keyboard dispatch: one Shortcuts pipeline, honored `enabled`,
/// text-input guard, single-step delete.
Future<void> _pump(
  WidgetTester tester, {
  required FlowCanvasController controller,
  FlowCanvasOptions? options,
  NodeRegistry? nodeRegistry,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            options: options ?? FlowCanvasOptions(),
            nodeRegistry: nodeRegistry,
            initialNodes: const [
              FlowNode<String>(
                id: 'a',
                type: 'input',
                position: Offset(80, 120),
                data: 'A',
              ),
              FlowNode<String>(
                id: 'b',
                type: 'output',
                position: Offset(320, 120),
                data: 'B',
              ),
            ],
            initialEdges: const [
              FlowEdge(
                id: 'e1',
                sourceNodeId: 'a',
                targetNodeId: 'b',
                sourceHandleId: 'source',
                targetHandleId: 'target',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('disabled()', () {
    testWidgets('no shortcut fires when keyboard is disabled', (tester) async {
      final controller = FlowCanvasController();
      await _pump(
        tester,
        controller: controller,
        options: FlowCanvasOptions(
          keyboardOptions: const KeyboardOptions.disabled(),
        ),
      );
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();
      final pos = controller.nodes.getNode('a')!.position;

      // Delete, arrows, and select-all are all dead.
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(controller.nodes.getNode('a'), isNotNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(controller.nodes.getNode('a')!.position, pos);

      controller.selection.deselectAll();
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(controller.currentState.selectedNodes, isEmpty);
    });
  });

  group('text-input guard', () {
    testWidgets('keystrokes while editing do not touch the canvas',
        (tester) async {
      final controller = FlowCanvasController();
      final fieldFocus = FocusNode(debugLabel: 'test-field');
      addTearDown(fieldFocus.dispose);
      final registry = NodeRegistry()
        ..registerTyped<String>(
          'input',
          (props) => BaseNode(
            node: props.node,
            child: TextField(
              key: const ValueKey('node-field'),
              focusNode: fieldFocus,
            ),
          ),
        )
        ..registerTyped<String>(
          'output',
          (props) => BaseNode(node: props.node, child: Text(props.data ?? '')),
        );
      await _pump(tester, controller: controller, nodeRegistry: registry);
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();

      fieldFocus.requestFocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus, same(fieldFocus));

      final pos = controller.nodes.getNode('a')!.position;
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Canvas untouched by field-owned keystrokes (canvas actions report
      // disabled while editing, so keys bubble to the text intents; arrows
      // are consumed by directional traversal).
      expect(controller.nodes.getNode('a'), isNotNull);
      expect(controller.nodes.getNode('a')!.position, pos);
    });
  });

  group('unified delete', () {
    testWidgets('one Delete keypress undoes in one step', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.selection.selectNode('a');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(controller.nodes.getNode('a'), isNull);
      expect(controller.edges.getEdge('e1'), isNull);

      controller.history.undo();
      await tester.pump();
      expect(controller.nodes.getNode('a'), isNotNull);
      expect(controller.edges.getEdge('e1'), isNotNull);
    });

    testWidgets('edge-only selection deletes via keyboard', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      controller.selection.selectEdge('e1');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(controller.edges.getEdge('e1'), isNull);
      expect(controller.nodes.getNode('a'), isNotNull);
      expect(controller.nodes.getNode('b'), isNotNull);
    });

    testWidgets('non-deletable edge survives keyboard delete', (tester) async {
      final controller = FlowCanvasController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: FlowCanvas(
                controller: controller,
                theme: FlowCanvasTheme.dark(),
                initialNodes: const [
                  FlowNode<String>(
                    id: 'a',
                    type: 'input',
                    position: Offset(80, 120),
                    data: 'A',
                  ),
                  FlowNode<String>(
                    id: 'b',
                    type: 'output',
                    position: Offset(320, 120),
                    data: 'B',
                  ),
                ],
                initialEdges: const [
                  FlowEdge(
                    id: 'locked',
                    sourceNodeId: 'a',
                    targetNodeId: 'b',
                    sourceHandleId: 'source',
                    targetHandleId: 'target',
                    deletable: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      controller.selection.selectEdge('locked');
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(controller.edges.getEdge('locked'), isNotNull);
    });
  });

  group('selective select-all', () {
    testWidgets('Ctrl+Shift+N selects nodes only', (tester) async {
      final controller = FlowCanvasController();
      await _pump(tester, controller: controller);
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();

      expect(controller.currentState.selectedNodes, containsAll(['a', 'b']));
      expect(controller.currentState.selectedEdges, isEmpty);
    });
  });
}
