import 'package:flutter/widgets.dart';
import 'package:lattice/src/features/canvas/flow_canvas_controller.dart';

/// Gives descendant widgets access to the enclosing [FlowCanvas] controller.
///
/// This is the Flutter-idiomatic counterpart of `useReactFlow()`'s instance
/// access: instead of a hook, hold the [FlowCanvasController] via
/// [FlowCanvasScope.of] — useful inside custom node builders, panels, and
/// overlays that never receive the controller as a constructor argument.
///
/// ```dart
/// class NodeCountBadge extends StatelessWidget {
///   const NodeCountBadge({super.key});
///
///   @override
///   Widget build(BuildContext context) {
///     // Imperative access, e.g. to call fitView from a toolbar button.
///     final controller = FlowCanvasScope.of(context);
///     return TextButton(
///       onPressed: () => controller.viewport.fitView(),
///       child: const Text('Fit view'),
///     );
///   }
/// }
/// ```
///
/// For reactive reads (rebuild when nodes / edges / viewport change), prefer
/// the selector providers in `flow_selectors.dart` (`flowNodesProvider`,
/// `flowEdgesProvider`, `flowViewportProvider`, …) with a Riverpod
/// `Consumer`.
///
/// Each [FlowCanvas] inserts its own scope, so multiple canvases on one page
/// stay isolated: [of] always resolves to the nearest enclosing canvas.
class FlowCanvasScope extends InheritedWidget {
  const FlowCanvasScope({
    super.key,
    required this.controller,
    required super.child,
  });

  /// The facade controller attached to the enclosing [FlowCanvas].
  final FlowCanvasController controller;

  /// Returns the [FlowCanvasController] of the nearest enclosing [FlowCanvas].
  ///
  /// Throws a [StateError] when called outside a [FlowCanvas] subtree —
  /// use [maybeOf] for the null-safe variant.
  static FlowCanvasController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<FlowCanvasScope>();
    assert(
      scope != null,
      'FlowCanvasScope.of() called outside a FlowCanvas subtree. '
      'Ensure this widget is rendered inside FlowCanvas (e.g. as an overlay, '
      'panel, or node builder child).',
    );
    if (scope == null) {
      throw StateError(
        'FlowCanvasScope.of() called outside a FlowCanvas subtree. '
        'Ensure this widget is rendered inside FlowCanvas (e.g. as an overlay, '
        'panel, or node builder child).',
      );
    }
    return scope.controller;
  }

  /// Null-safe variant of [of]; returns null outside a [FlowCanvas] subtree.
  static FlowCanvasController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlowCanvasScope>()
        ?.controller;
  }

  @override
  bool updateShouldNotify(FlowCanvasScope oldWidget) {
    return controller != oldWidget.controller;
  }
}

/// Convenience accessors mirroring `context.flowCanvasTheme`.
extension FlowCanvasScopeContextExtension on BuildContext {
  /// See [FlowCanvasScope.of].
  FlowCanvasController get flowCanvas => FlowCanvasScope.of(this);

  /// See [FlowCanvasScope.maybeOf].
  FlowCanvasController? get flowCanvasMaybe => FlowCanvasScope.maybeOf(this);
}
