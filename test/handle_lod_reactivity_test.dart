// ignore_for_file: prefer_const_constructors
import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/options/options_provider.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Component-level reactivity contract for [Handle]'s zoom-LOD hiding.
///
/// A runtime `viewportOptions.lodHideHandlesBelowZoom` change must rebuild
/// ALREADY-MOUNTED handles: turning the threshold on (above the current zoom)
/// hides them, turning it back off shows them. The handle watches this field
/// through its `flowOptionsProvider` record select; if it were read via
/// `ref.read`, an options-only change would leave mounted handles wired to the
/// stale threshold (a handle mounted with a null threshold would never start
/// hiding, and one mounted with a wrapper would keep it after the option was
/// cleared).
///
/// Verified at the *Riverpod* channel in isolation (Theme and the options
/// InheritedWidget held fixed, only the provider override changes) — a full
/// canvas re-pump would mask the bug by rebuilding every handle incidentally.
void main() {
  testWidgets('handle LOD hiding is reactive to a Riverpod-only change',
      (tester) async {
    final node = FlowNode<String>(
      type: 'default',
      id: 'a',
      position: const Offset(0, 0),
      size: const Size(160, 100),
      data: 'a',
    );
    // Seed a known zoom so the LOD threshold comparison is deterministic.
    final state = FlowCanvasState.initial().copyWith(
      nodes: {'a': node},
      viewport: const FlowViewport(offset: Offset.zero, zoom: 1.0),
    );

    FlowCanvasOptions opts(double? lod) => FlowCanvasOptions(
          a11yOptions: const A11yOptions(
            labels: FlowA11yLabels(handleLabel: 'Handle-LOD'),
          ),
          viewportOptions: ViewportOptions(lodHideHandlesBelowZoom: lod),
        );

    final container = ProviderContainer(overrides: [
      flowControllerProvider.overrideWith(
        () => FlowCanvasInternalController(initialState: state),
      ),
      flowOptionsProvider.overrideWithValue(opts(null)),
    ]);
    addTearDown(container.dispose);

    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: FlowCanvasOptionsProvider(
              options: opts(null),
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
    // No threshold → handles visible.
    expect(find.bySemanticsLabel('Handle-LOD'), findsWidgets);

    // Turn the threshold on above the current zoom (1.0 < 2.0) through the same
    // channel FlowCanvas uses (updateOverrides), with NO widget re-pump.
    container.updateOverrides([
      flowControllerProvider.overrideWith(
        () => FlowCanvasInternalController(initialState: state),
      ),
      flowOptionsProvider.overrideWithValue(opts(2.0)),
    ]);
    await tester.pump();
    // Below threshold → handles hidden.
    expect(find.bySemanticsLabel('Handle-LOD'), findsNothing);

    // Clear the threshold again → handles return.
    container.updateOverrides([
      flowControllerProvider.overrideWith(
        () => FlowCanvasInternalController(initialState: state),
      ),
      flowOptionsProvider.overrideWithValue(opts(null)),
    ]);
    await tester.pump();
    expect(find.bySemanticsLabel('Handle-LOD'), findsWidgets);

    semantics.dispose();
  });
}
