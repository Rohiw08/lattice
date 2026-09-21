// ignore_for_file: prefer_const_constructors
import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/options/options_provider.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Component-level reactivity contract for [Handle]'s screen-reader label.
///
/// A runtime `a11yOptions.labels.handleLabel` change (e.g. a locale switch)
/// must rebuild ALREADY-MOUNTED handles so the label never goes stale. The
/// handle watches `handleLabel` through its `flowOptionsProvider` record
/// select; if it were read via `ref.read` instead, an options-only change
/// would leave mounted handles stale.
///
/// This is verified at the *Riverpod* channel in isolation — Theme and the
/// `FlowCanvasOptionsProvider` InheritedWidget are held fixed and only the
/// provider override changes. In the full canvas the label change is masked
/// because any parent rebuild re-creates the Theme and rebuilds every
/// theme-dependent handle; this test is the canary that keeps the label
/// reactive on its own account, independent of that incidental rebuild.
void main() {
  testWidgets('handle Semantics label is reactive to a Riverpod-only change',
      (tester) async {
    final node = FlowNode<String>(
      type: 'default',
      id: 'a',
      position: const Offset(0, 0),
      size: const Size(160, 100),
      data: 'a',
    );
    final state = FlowCanvasState.initial().copyWith(nodes: {'a': node});

    FlowCanvasOptions opts(String label) => FlowCanvasOptions(
          a11yOptions: A11yOptions(
            labels: FlowA11yLabels(handleLabel: label),
          ),
        );

    final container = ProviderContainer(overrides: [
      flowControllerProvider.overrideWith(
        () => FlowCanvasInternalController(initialState: state),
      ),
      flowOptionsProvider.overrideWithValue(opts('Handle-Alpha')),
    ]);
    addTearDown(container.dispose);

    final semantics = tester.ensureSemantics();

    // Theme + FlowCanvasOptionsProvider InheritedWidget held FIXED; only the
    // Riverpod override changes between pumps. (Handle reads options via
    // Riverpod, not the InheritedWidget — the fixed value here just satisfies
    // BaseNode, which does read the InheritedWidget.)
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: FlowCanvasOptionsProvider(
              options: opts('fixed-inherited'),
              child: SizedBox(
                width: 400,
                height: 300,
                child: BaseNode(node: node),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel('Handle-Alpha'), findsWidgets);

    // Runtime label change through the same channel FlowCanvas uses
    // (updateOverrides), with NO widget re-pump — Theme stays identical.
    container.updateOverrides([
      flowControllerProvider.overrideWith(
        () => FlowCanvasInternalController(initialState: state),
      ),
      flowOptionsProvider.overrideWithValue(opts('Handle-Beta')),
    ]);
    await tester.pump();

    expect(find.bySemanticsLabel('Handle-Beta'), findsWidgets);
    expect(find.bySemanticsLabel('Handle-Alpha'), findsNothing);

    semantics.dispose();
  });
}
