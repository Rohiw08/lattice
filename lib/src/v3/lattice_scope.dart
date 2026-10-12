import 'package:flutter/widgets.dart';

import 'lattice_controller.dart';

/// Exposes the [LatticeController] to the canvas subtree.
///
/// The controller instance is stable for the life of the canvas, so
/// dependents rebuild only when a *different* controller is provided.
class LatticeScope extends InheritedWidget {
  const LatticeScope({
    required super.child,
    required this.controller,
  });

  final LatticeController controller;

  /// Returns the nearest [LatticeScope] controller, registering [context]
  /// as a dependent. Asserts in debug builds when no scope is present.
  static LatticeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<LatticeScope>();
    assert(
      scope != null,
      'LatticeScope.of() called outside a LatticeScope subtree. '
      'Place the caller under a LatticeCanvas.',
    );
    return scope!.controller;
  }

  @override
  bool updateShouldNotify(LatticeScope old) =>
      !identical(old.controller, controller);
}
