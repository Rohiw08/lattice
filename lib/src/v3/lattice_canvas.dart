import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'edge_label_layer.dart';
import 'edge_layer.dart';
import 'gesture_router.dart';
import 'lattice_callbacks.dart';
import 'lattice_controller.dart';
import 'lattice_cull.dart';
import 'lattice_options.dart';
import 'lattice_scope.dart';
import 'lattice_theme.dart';
import 'node_layer.dart';

/// Mounts a [LatticeController] session as a widget.
///
/// Attaches to [controller] in [initState] and detaches in [dispose].
/// Mounting a second canvas while [controller] is already attached throws
/// a [StateError] (one container, one canvas).
///
/// [theme] (default [LatticeTheme.light]) is provided to the subtree via
/// [LatticeThemeScope]; [callbacks] are attached to the controller and
/// observed from the controller verbs.
class LatticeCanvas extends StatefulWidget {
  const LatticeCanvas({
    super.key,
    required this.controller,
    this.theme,
    this.callbacks,
    this.overlays = const [],
    this.nodeBuilders = const {},
    this.labelBuilders = const {},
  });

  final LatticeController controller;

  /// Paint theme for every layer; null means [LatticeTheme.light].
  final LatticeTheme? theme;

  /// Optional session observation hooks. Attached once in [initState].
  final LatticeCallbacks? callbacks;

  /// Widgets stacked above the lattice pane (edges land in V3-4).
  final List<Widget> overlays;

  /// Per-type node body builders for the node layer. Unknown types fall
  /// back to a default bordered box.
  final Map<String, LatticeNodeBuilder> nodeBuilders;

  /// Per-type edge label builders for the edge label layer. Edges whose
  /// type has no builder render no label.
  final Map<String, LatticeEdgeLabelBuilder> labelBuilders;

  @override
  State<LatticeCanvas> createState() => _LatticeCanvasState();
}

class _LatticeCanvasState extends State<LatticeCanvas> {
  Size? _publishedSize;
  bool _onInitFired = false;
  bool _initialFitResolved = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller.isAttached) {
      throw StateError(
        'LatticeCanvas: a second canvas was mounted on the same '
        'LatticeController. One controller owns one canvas; create a '
        'separate LatticeController per canvas.',
      );
    }
    widget.controller.attach();
    final LatticeCallbacks? callbacks = widget.callbacks;
    if (callbacks != null) {
      widget.controller.attachCallbacks(callbacks);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The LayoutBuilder has already recorded its size by the time the
      // first post-frame flush runs; publish it here so the forced cull
      // refresh and the optional initial fit see it without waiting for
      // the build-scheduled publish.
      _publishRecordedSize();
      widget.controller.container
          .read(latticeCullProvider.notifier)
          .refresh(force: true);
      _applyInitialFit();
      _fireOnInit();
    });
  }

  @override
  void dispose() {
    widget.controller.detach();
    super.dispose();
  }

  /// Publishes the last size recorded by [build]'s [LayoutBuilder] (if
  /// any) to [latticePaneSizeProvider]. Idempotent: the publish scheduled
  /// from `build` writes the same value, which the notifier dedupes.
  void _publishRecordedSize() {
    final Size? size = _publishedSize;
    if (size == null) return;
    widget.controller.container.read(latticePaneSizeProvider.notifier).set(
          size,
        );
  }

  /// Fires `options.fitViewOnInit` once, as soon as a pane size exists.
  /// Deferred to the pane-size publish path when the first post-frame
  /// flush cannot see a size yet.
  void _applyInitialFit() {
    if (_initialFitResolved) return;
    final LatticeOptions options = widget.controller.options;
    if (!options.fitViewOnInit || options.defaultViewport != null) {
      _initialFitResolved = true;
      return;
    }
    if (widget.controller.container.read(latticePaneSizeProvider) == null) {
      return;
    }
    _initialFitResolved = true;
    widget.controller.fitView();
  }

  /// Fires `callbacks.onInit` exactly once, post-frame.
  void _fireOnInit() {
    if (_onInitFired) return;
    _onInitFired = true;
    widget.controller.callbacks?.onInit?.call(widget.controller);
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: widget.controller.container,
      child: LatticeThemeScope(
        theme: widget.theme ?? LatticeTheme.light(),
        child: LatticeScope(
          controller: widget.controller,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final Size size = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );
              if (size != _publishedSize &&
                  size.width.isFinite &&
                  size.height.isFinite) {
                _publishedSize = size;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  widget.controller.container
                      .read(latticePaneSizeProvider.notifier)
                      .set(size);
                  // Covers the deferred initial fit when the first
                  // post-frame flush had no size to fit against.
                  _applyInitialFit();
                  _fireOnInit();
                });
              }
              // The router wraps the pane (ancestor of the stack) so it stays
              // in screen space, outside any camera transform applied to the
              // layers below.
              return LatticeGestureRouter(
                child: Stack(
                  key: const ValueKey<String>('latticePane'),
                  children: [
                    const SizedBox.expand(),
                    const LatticeEdgeLayer(),
                    LatticeEdgeLabelLayer(
                      labelBuilders: widget.labelBuilders,
                    ),
                    LatticeNodeLayer(nodeBuilders: widget.nodeBuilders),
                    ...widget.overlays,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
