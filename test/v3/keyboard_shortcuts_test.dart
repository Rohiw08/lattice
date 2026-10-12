import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, Offset position) {
  return LatticeNode(id: id, type: 'default', position: position);
}

LatticeController _seededController() {
  final controller = LatticeController(
    initialNodes: [_node('a', const Offset(100, 100))],
  );
  controller.select({'a'});
  return controller;
}

/// Canvas with a [LatticeShortcuts] ancestor (opt-in chrome: the canvas
/// does NOT include shortcuts itself). The outer [LatticeScope] hands the
/// ancestor the controller; the canvas provides its own inner scope.
Future<void> _pumpCanvasWithShortcuts(
  WidgetTester tester,
  LatticeController controller, {
  bool enabled = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LatticeScope(
        controller: controller,
        child: LatticeShortcuts(
          enabled: enabled,
          child: LatticeCanvas(controller: controller),
        ),
      ),
    ),
  );
  // Flush post-frame callbacks (pane-size publish + forced cull refresh)
  // and settle autofocus.
  await tester.pump();
  await tester.pump();
}

Future<void> _pressWithModifier(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
  LogicalKeyboardKey key,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(key);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

Future<void> _pressCtrl(WidgetTester tester, LogicalKeyboardKey key) {
  return _pressWithModifier(tester, LogicalKeyboardKey.control, key);
}

Future<void> _pressMeta(WidgetTester tester, LogicalKeyboardKey key) {
  return _pressWithModifier(tester, LogicalKeyboardKey.metaLeft, key);
}

void main() {
  group('keyboard shortcuts', () {
    testWidgets('Delete clears selection + adds history entry',
        (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);
      expect(controller.canUndo, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(
        controller.container.read(latticeDocumentProvider).nodes,
        isEmpty,
      );
      expect(
        controller.container.read(latticeSelectionProvider).nodes,
        isEmpty,
      );
      expect(controller.canUndo, isTrue);
    });

    testWidgets('Backspace deletes the selection too', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();

      expect(
        controller.container.read(latticeDocumentProvider).nodes,
        isEmpty,
      );
      expect(controller.canUndo, isTrue);
    });

    testWidgets('Delete on empty selection is a no-op with no history',
        (tester) async {
      final controller = LatticeController(
        initialNodes: [_node('a', const Offset(100, 100))],
      );
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);
      expect(controller.canUndo, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );
      expect(controller.canUndo, isFalse);
    });

    testWidgets('Ctrl+C then Ctrl+V duplicates at center (node count +1)',
        (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await _pressCtrl(tester, LogicalKeyboardKey.keyC);
      await _pressCtrl(tester, LogicalKeyboardKey.keyV);

      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(2),
      );
      expect(controller.canUndo, isTrue);
    });

    testWidgets('Meta+C then Meta+V duplicates too', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await _pressMeta(tester, LogicalKeyboardKey.keyC);
      await _pressMeta(tester, LogicalKeyboardKey.keyV);

      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(2),
      );
    });

    testWidgets('Ctrl+Z undoes the paste', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await _pressCtrl(tester, LogicalKeyboardKey.keyC);
      await _pressCtrl(tester, LogicalKeyboardKey.keyV);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(2),
      );

      await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );
    });

    testWidgets('Ctrl+Shift+Z and Ctrl+Y redo', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await _pressCtrl(tester, LogicalKeyboardKey.keyC);
      await _pressCtrl(tester, LogicalKeyboardKey.keyV);
      await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.control);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.control);
      await tester.pump();
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(2),
      );

      await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );

      await _pressCtrl(tester, LogicalKeyboardKey.keyY);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(2),
      );
    });

    testWidgets('Ctrl+X cuts as one history entry', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await _pressCtrl(tester, LogicalKeyboardKey.keyX);
      expect(
        controller.container.read(latticeDocumentProvider).nodes,
        isEmpty,
      );
      expect(controller.canUndo, isTrue);

      // A single undo restores the cut node (cut = copy with no history
      // + deleteSelection with one entry).
      await _pressCtrl(tester, LogicalKeyboardKey.keyZ);
      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );
      expect(controller.canUndo, isFalse);
    });

    testWidgets('Right-arrow nudges x by 1 (document position)',
        (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);
      expect(controller.canUndo, isFalse);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      // Document position (flow coords), not screen coords.
      expect(
        controller.container
            .read(latticeDocumentProvider)
            .nodes['a']!
            .position,
        equals(const Offset(101, 100)),
      );
      expect(controller.canUndo, isTrue);
    });

    testWidgets('Shift+Right-arrow nudges x by 10', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(tester, controller);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shift);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shift);
      await tester.pump();

      expect(
        controller.container
            .read(latticeDocumentProvider)
            .nodes['a']!
            .position,
        equals(const Offset(110, 100)),
      );
    });

    testWidgets('enabled: false leaves bindings inert', (tester) async {
      final controller = _seededController();
      addTearDown(controller.dispose);

      await _pumpCanvasWithShortcuts(
        tester,
        controller,
        enabled: false,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.delete);
      await tester.pump();

      expect(
        controller.container.read(latticeDocumentProvider).nodes.length,
        equals(1),
      );
      expect(controller.canUndo, isFalse);
    });
  });
}
