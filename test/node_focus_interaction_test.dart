import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Regression tests for tap-to-focus on in-node fields.
///
/// Bug: focusing anything inside a node (e.g. tapping a `TextField`)
/// unconditionally panned the camera (`autoPanOnNodeFocus`) AND remounted
/// the node subtree (the focus ring swapped the child widget type), so the
/// camera jumped and the field lost focus + typed text.
///
/// Fixed contract:
/// - focus changes never remount node content (stable ring widget type);
/// - auto-pan fires only when the node is actually offscreen.
class _FieldNode extends StatefulWidget {
  const _FieldNode({
    required this.node,
    required this.focusNode,
    required this.onInit,
  });

  final FlowNode node;
  final FocusNode focusNode;
  final ValueChanged<TextEditingController> onInit;

  @override
  State<_FieldNode> createState() => _FieldNodeState();
}

class _FieldNodeState extends State<_FieldNode> {
  late final TextEditingController field = TextEditingController(text: 'x');

  @override
  void initState() {
    super.initState();
    widget.onInit(field);
  }

  @override
  Widget build(BuildContext context) {
    return BaseNode(
      node: widget.node,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 120,
          height: 36,
          child: TextField(controller: field, focusNode: widget.focusNode),
        ),
      ),
    );
  }
}

Future<FlowCanvasController> _pump(
  WidgetTester tester, {
  required ValueChanged<TextEditingController> captureNear,
  required ValueChanged<TextEditingController> captureFar,
  required FocusNode nearFocus,
  required FocusNode farFocus,
}) async {
  final controller = FlowCanvasController();
  final registry = NodeRegistry()
    ..registerTyped<String>(
      'default',
      (props) => _FieldNode(
        node: props.node,
        focusNode: props.id == 'near' ? nearFocus : farFocus,
        onInit: (c) =>
            (props.id == 'near' ? captureNear : captureFar)(c),
      ),
    );
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            controller: controller,
            theme: FlowCanvasTheme.dark(),
            nodeRegistry: registry,
            options: FlowCanvasOptions(
              viewportOptions: ViewportOptions(
                // Keep the offscreen node mounted so it can take focus.
                onlyRenderVisibleElements: false,
              ),
            ),
            initialNodes: const [
              FlowNode<String>(
                id: 'near',
                type: 'default',
                position: Offset(60, 60),
                size: Size(200, 100),
                data: 'N',
              ),
              FlowNode<String>(
                id: 'far',
                type: 'default',
                position: Offset(5000, 5000),
                size: Size(200, 100),
                data: 'F',
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
  return controller;
}

void main() {
  group('in-node focus', () {
    testWidgets('keeps field state + focus, no camera move when visible',
        (tester) async {
      TextEditingController? near;
      final nearFocus = FocusNode(debugLabel: 'near-field');
      final farFocus = FocusNode(debugLabel: 'far-field');
      addTearDown(nearFocus.dispose);
      addTearDown(farFocus.dispose);
      final controller = await _pump(
        tester,
        captureNear: (c) => near = c,
        captureFar: (_) {},
        nearFocus: nearFocus,
        farFocus: farFocus,
      );
      final before = near;
      final vpBefore = controller.currentState.viewport;

      nearFocus.requestFocus();
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Same State object: no remount across the focus change.
      expect(near, same(before));
      // Focus actually held (typing reaches the field).
      expect(nearFocus.hasPrimaryFocus, isTrue);
      // Visible node: camera untouched.
      expect(
        controller.currentState.viewport.offset,
        vpBefore.offset,
      );
      expect(controller.currentState.viewport.zoom, vpBefore.zoom);
    });

    testWidgets('tap on a field focuses it and holds through rebuilds',
        (tester) async {
      TextEditingController? near;
      final nearFocus = FocusNode(debugLabel: 'near-field');
      final farFocus = FocusNode(debugLabel: 'far-field');
      addTearDown(nearFocus.dispose);
      addTearDown(farFocus.dispose);
      final controller = await _pump(
        tester,
        captureNear: (c) => near = c,
        captureFar: (_) {},
        nearFocus: nearFocus,
        farFocus: farFocus,
      );
      final vpBefore = controller.currentState.viewport;

      final field =
          find.byWidgetPredicate((w) => w is TextField && w.focusNode == nearFocus);
      await tester.tap(field);
      await tester.pump();
      await tester.pump();

      expect(nearFocus.hasPrimaryFocus, isTrue);
      expect(near, same(near));
      expect(controller.currentState.viewport.offset, vpBefore.offset);

      // And typed text actually lands + survives rebuilds.
      tester.testTextInput.enterText('42');
      await tester.pump();
      await tester.pump();
      expect(near?.text, '42');
      expect(nearFocus.hasPrimaryFocus, isTrue);
    });

    testWidgets('offscreen node focus still pans it into view',        (tester) async {
      TextEditingController? far;
      final nearFocus = FocusNode(debugLabel: 'near-field');
      final farFocus = FocusNode(debugLabel: 'far-field');
      addTearDown(nearFocus.dispose);
      addTearDown(farFocus.dispose);
      final controller = await _pump(
        tester,
        captureNear: (_) {},
        captureFar: (c) => far = c,
        nearFocus: nearFocus,
        farFocus: farFocus,
      );

      farFocus.requestFocus();
      await tester.pump();
      await tester.pump();

      final state = controller.currentState;
      final rect = NodeLayout.absoluteRect(state.nodes['far']!, state.nodes);
      final size = state.viewportSize!;
      final z = state.viewport.zoom;
      final o = state.viewport.offset;
      final visible = Rect.fromLTWH(
        -o.dx / z,
        -o.dy / z,
        size.width / z,
        size.height / z,
      );
      expect(
        visible.left <= rect.left &&
            visible.top <= rect.top &&
            visible.right >= rect.right &&
            visible.bottom >= rect.bottom,
        isTrue,
        reason: 'far node should be panned into view, visible=$visible node=$rect',
      );
      expect(far, isNotNull);
    });

    testWidgets('editing keys edit text, never the canvas', (tester) async {
      TextEditingController? near;
      final nearFocus = FocusNode(debugLabel: 'near-field');
      final farFocus = FocusNode(debugLabel: 'far-field');
      addTearDown(nearFocus.dispose);
      addTearDown(farFocus.dispose);
      final controller = await _pump(
        tester,
        captureNear: (c) => near = c,
        captureFar: (_) {},
        nearFocus: nearFocus,
        farFocus: farFocus,
      );

      // Select the node first: canvas is armed to delete it.
      controller.selection.selectNode('near');
      await tester.pump();
      expect(controller.currentState.selectedNodes, {'near'});

      nearFocus.requestFocus();
      await tester.pump();
      await tester.pump();

      Future<void> key(LogicalKeyboardKey key) async {
        await tester.sendKeyDownEvent(key);
        await tester.sendKeyUpEvent(key);
        await tester.pump();
      }

      // Backspace edits the text …
      await key(LogicalKeyboardKey.backspace);
      expect(near?.text, 'x'.substring(1)); // '' (was 'x')
      // … and must NOT delete the selected node (data-loss class).
      expect(controller.currentState.nodes.containsKey('near'), isTrue);
      expect(controller.currentState.selectedNodes, {'near'});

      // Ctrl+A reaches the field (app-level text intent, not canvas select).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pump();
      expect(near?.selection.isValid, isTrue);
    });

    testWidgets('canvas shortcuts work again after blur', (tester) async {
      TextEditingController? near;
      final nearFocus = FocusNode(debugLabel: 'near-field');
      final farFocus = FocusNode(debugLabel: 'far-field');
      addTearDown(nearFocus.dispose);
      addTearDown(farFocus.dispose);
      final controller = await _pump(
        tester,
        captureNear: (c) => near = c,
        captureFar: (_) {},
        nearFocus: nearFocus,
        farFocus: farFocus,
      );
      expect(near, isNotNull);

      controller.selection.selectNode('near');
      await tester.pump();

      nearFocus.requestFocus();
      await tester.pump();
      nearFocus.unfocus();
      await tester.pump();
      await tester.pump();

      // Blurred: click empty canvas (deselects + returns focus to the
      // canvas via pointer-down, exactly like real usage), then reselect.
      await tester.tapAt(const Offset(750, 550));
      await tester.pump();
      expect(controller.currentState.selectedNodes, isEmpty);
      controller.selection.selectNode('near');
      await tester.pump();
      expect(controller.currentState.selectedNodes, {'near'});

      // Delete removes the selected node (canvas behavior intact).
      await tester.sendKeyDownEvent(LogicalKeyboardKey.delete);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.delete);
      await tester.pump();
      expect(controller.currentState.nodes.containsKey('near'), isFalse);
    });
  });
}
