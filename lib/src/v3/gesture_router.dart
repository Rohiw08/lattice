import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_camera.dart';
import 'lattice_controller.dart';
import 'lattice_layout.dart';
import 'lattice_node.dart';
import 'lattice_scope.dart';
import 'session_providers.dart';

/// Screen-space input router for the lattice pane.
///
/// Lives OUTSIDE the camera transform (mounted above the transformed pane
/// in the canvas stack), so all pointer positions are screen-space and the
/// controller converts to flow coordinates. Wraps the pane with a
/// [Listener] (`HitTestBehavior.translucent`):
///
/// * down on a node records a drag candidate; past a 3px move threshold
///   [LatticeController.beginNodeDrag] starts, otherwise up resolves to
///   [LatticeController.tapAt];
/// * down on empty space records a marquee candidate; past the same
///   threshold [LatticeController.beginMarquee] starts;
/// * secondary-button drags, and drags with exactly two active pointers,
///   pan the camera by the screen delta;
/// * mouse hover sets [latticeHoverProvider] only (never selection).
///
/// Pinch zoom is intentionally NOT implemented here (V3-6 controls cover
/// zoom); two-finger gestures pan.
///
/// A pointer-router route is held while a primary gesture is armed so a
/// pointer-up OUTSIDE the pane still ends the drag/marquee (a raw
/// [Listener] only sees inside-pane ups). Inside-pane events are handled
/// by the [Listener]; the route ignores moves and de-duplicates ups via
/// the state flags, so ends stay idempotent.
class LatticeGestureRouter extends ConsumerWidget {
  const LatticeGestureRouter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _GestureRouterBody(child: child);
  }
}

class _GestureRouterBody extends ConsumerStatefulWidget {
  const _GestureRouterBody({required this.child});

  final Widget child;

  @override
  ConsumerState<_GestureRouterBody> createState() =>
      _GestureRouterBodyState();
}

class _GestureRouterBodyState extends ConsumerState<_GestureRouterBody> {
  static const double _moveThreshold = 3.0;

  late LatticeController _controller;

  final Map<int, Offset> _pointers = <int, Offset>{};
  final Set<int> _routedPointers = <int>{};

  int? _primaryPointer;
  Offset? _downPosition;
  String? _downNodeId;
  bool _nodeDragging = false;
  bool _marquee = false;
  bool _panning = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = LatticeScope.of(context);
  }

  @override
  void dispose() {
    for (final int pointer in _routedPointers) {
      GestureBinding.instance.pointerRouter.removeRoute(
        pointer,
        _handleRoutedEvent,
      );
    }
    _routedPointers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _onPointerDown,
      onPointerMove: _onPointerMove,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: MouseRegion(
        onHover: (PointerHoverEvent event) =>
            _updateHover(event.localPosition),
        onExit: (_) => _clearHover(),
        child: widget.child,
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (event.buttons == kSecondaryMouseButton) {
      _panning = true;
      _addRoute(event.pointer);
      return;
    }
    if (_pointers.length == 2) {
      // Second finger parks any single-finger gesture and pans.
      if (_nodeDragging) {
        _nodeDragging = false;
        _controller.endNodeDrag();
      }
      if (_marquee) {
        _marquee = false;
        _controller.endMarquee();
      }
      _primaryPointer = null;
      _downPosition = null;
      _downNodeId = null;
      _panning = true;
      _addRoute(event.pointer);
      return;
    }
    if (_pointers.length > 2 || _primaryPointer != null) return;
    _primaryPointer = event.pointer;
    _downPosition = event.localPosition;
    _downNodeId = _hitNode(event.localPosition);
    _addRoute(event.pointer);
  }

  void _onPointerMove(PointerMoveEvent event) {
    _pointers[event.pointer] = event.localPosition;
    if (_panning) {
      _controller.container
          .read(latticeCameraProvider.notifier)
          .panBy(event.delta);
      return;
    }
    if (event.pointer != _primaryPointer) return;
    final Offset? down = _downPosition;
    if (down == null) return;
    final Offset position = event.localPosition;
    if (_nodeDragging) {
      _controller.updateNodeDrag(event.delta);
      return;
    }
    if (_marquee) {
      _controller.updateMarquee(position);
      return;
    }
    if ((position - down).distance > _moveThreshold) {
      final String? id = _downNodeId;
      if (id != null) {
        _controller.beginNodeDrag(id);
        _controller.updateNodeDrag(event.delta);
        _nodeDragging = true;
      } else {
        _controller.beginMarquee(down);
        _controller.updateMarquee(position);
        _marquee = true;
      }
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointers.remove(event.pointer);
    _removeRoute(event.pointer);
    if (_panning) {
      if (_pointers.length < 2) _panning = false;
      if (event.pointer == _primaryPointer) {
        _primaryPointer = null;
        _downPosition = null;
        _downNodeId = null;
      }
      return;
    }
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;
    if (_nodeDragging) {
      _nodeDragging = false;
      _controller.endNodeDrag();
    } else if (_marquee) {
      _marquee = false;
      _controller.endMarquee();
    } else {
      _controller.tapAt(event.localPosition);
    }
    _downPosition = null;
    _downNodeId = null;
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointers.remove(event.pointer);
    _removeRoute(event.pointer);
    if (_panning) {
      if (_pointers.length < 2) _panning = false;
    }
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;
    if (_nodeDragging) {
      _nodeDragging = false;
      _controller.endNodeDrag();
    } else if (_marquee) {
      _marquee = false;
      _controller.endMarquee();
    }
    _downPosition = null;
    _downNodeId = null;
  }

  /// Safety net for ups/cancels outside the pane (the [Listener] never
  /// sees those). Moves are intentionally ignored here: inside-pane
  /// moves are handled by the [Listener], and ignoring outside travel
  /// keeps the commit anchored at the last inside position.
  void _handleRoutedEvent(PointerEvent event) {
    if (event is! PointerUpEvent && event is! PointerCancelEvent) return;
    if (_panning) {
      _pointers.remove(event.pointer);
      if (_pointers.length < 2) _panning = false;
    }
    if (event.pointer != _primaryPointer) return;
    _primaryPointer = null;
    if (_nodeDragging) {
      _nodeDragging = false;
      _controller.endNodeDrag();
    } else if (_marquee) {
      _marquee = false;
      _controller.endMarquee();
    } else if (event is PointerUpEvent) {
      _controller.tapAt(event.localPosition);
    }
    _downPosition = null;
    _downNodeId = null;
  }

  void _addRoute(int pointer) {
    if (_routedPointers.add(pointer)) {
      GestureBinding.instance.pointerRouter.addRoute(
        pointer,
        _handleRoutedEvent,
      );
    }
  }

  void _removeRoute(int pointer) {
    // Deferred: removal can race in-flight dispatch of the same event
    // (route fires before the Listener for inside-pane ups).
    if (_routedPointers.remove(pointer)) {
      Future.microtask(() {
        if (!_pointers.containsKey(pointer) && _primaryPointer != pointer) {
          GestureBinding.instance.pointerRouter.removeRoute(
            pointer,
            _handleRoutedEvent,
          );
        }
      });
    }
  }

  /// Router-side hit test (no selection side effects): topmost node
  /// (highest `zIndex`, ties broken by smallest id) whose absolute rect
  /// contains the flow point. Mirrors the controller's pick rule.
  String? _hitNode(Offset screenPosition) {
    final ProviderContainer container = _controller.container;
    final Map<String, LatticeNode> nodes =
        container.read(latticeDocumentProvider).nodes;
    if (nodes.isEmpty) return null;
    final Offset flow = _controller.screenToFlow(screenPosition);
    String? best;
    int bestZ = 0;
    bool found = false;
    for (final LatticeNode node in nodes.values) {
      if (!latticeAbsoluteRect(nodes, node.id, defaultOrigin: Offset.zero)
          .contains(flow)) {
        continue;
      }
      if (!found ||
          node.zIndex > bestZ ||
          (node.zIndex == bestZ && node.id.compareTo(best!) < 0)) {
        best = node.id;
        bestZ = node.zIndex;
        found = true;
      }
    }
    return best;
  }

  void _updateHover(Offset screenPosition) {
    final ProviderContainer container = _controller.container;
    final String? hit = _hitNode(screenPosition);
    if (container.read(latticeHoverProvider) != hit) {
      container.read(latticeHoverProvider.notifier).set(hit);
    }
  }

  void _clearHover() {
    final ProviderContainer container = _controller.container;
    if (container.read(latticeHoverProvider) != null) {
      container.read(latticeHoverProvider.notifier).set(null);
    }
  }
}
