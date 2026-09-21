import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/intent_actions.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/keymap.dart';

/// The "bonus" bindings (Copy/Paste/FitView + node-only/edge-only select-all)
/// live ONLY in [Keymap.standard]. They must follow the platform's standard
/// modifier — Cmd on macOS, Ctrl elsewhere — exactly like the user-facing
/// KeyboardOptions defaults. A prior version hardcoded Control via LogicalKeySet,
/// so on macOS these actions had NO Cmd binding at all.
SingleActivator _activatorFor<T extends Intent>(Keymap km) {
  final entry = km.shortcuts.entries.firstWhere(
    (e) => e.value is T,
    orElse: () => throw StateError('no binding produces $T'),
  );
  return entry.key as SingleActivator;
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  group('on macOS the bonus bindings use Cmd (meta), not Control', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);

    test('Copy is Cmd+C', () {
      final a = _activatorFor<CopyIntent>(Keymap.standard());
      expect(a.trigger, LogicalKeyboardKey.keyC);
      expect(a.meta, isTrue);
      expect(a.control, isFalse);
    });

    test('Paste is Cmd+V', () {
      final a = _activatorFor<PasteIntent>(Keymap.standard());
      expect(a.trigger, LogicalKeyboardKey.keyV);
      expect(a.meta, isTrue);
      expect(a.control, isFalse);
    });

    test('FitView is Cmd+F', () {
      final a = _activatorFor<FitViewIntent>(Keymap.standard());
      expect(a.trigger, LogicalKeyboardKey.keyF);
      expect(a.meta, isTrue);
      expect(a.control, isFalse);
    });
  });

  group('off macOS the bonus bindings use Control', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.windows);

    test('Copy is Ctrl+C', () {
      final a = _activatorFor<CopyIntent>(Keymap.standard());
      expect(a.trigger, LogicalKeyboardKey.keyC);
      expect(a.control, isTrue);
      expect(a.meta, isFalse);
    });

    test('the two select-all variants keep Shift and their own trigger', () {
      final km = Keymap.standard();
      final nodesOnly = km.shortcuts.entries
          .where((e) => e.value is SelectAllIntent)
          .map((e) => e.key as SingleActivator)
          .toList();
      // Both are Ctrl+Shift+<key>; distinct triggers (N nodes-only, E edges-only).
      expect(nodesOnly.length, 2);
      for (final a in nodesOnly) {
        expect(a.control, isTrue);
        expect(a.shift, isTrue);
        expect(a.meta, isFalse);
      }
      final triggers = nodesOnly.map((a) => a.trigger).toSet();
      expect(triggers, {LogicalKeyboardKey.keyN, LogicalKeyboardKey.keyE});
    });
  });
}
