import 'package:lattice/src/features/canvas/flow_canvas_callbacks.dart';
import 'package:lattice/src/features/canvas/flow_canvas_controller.dart';
import 'package:lattice/src/features/canvas/flow_canvas_internal_controller.dart';
import 'package:lattice/src/features/a11y/presentation/flow_a11y_live_region.dart';
import 'package:lattice/src/features/canvas/flow_canvas_scope.dart';
import 'package:lattice/src/features/canvas/flow_canvas_viewport.dart';
import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/core/options/options_provider.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/core/theme/theme_export.dart';
import 'package:lattice/src/features/background/presentation/flow_background.dart';
import 'package:lattice/src/features/edges/domain/edge_registry.dart';
import 'package:lattice/src/features/edges/domain/edge_state.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/keyboard/presentation/controller_adapter.dart';
import 'package:lattice/src/features/keyboard/presentation/inputs/keymap.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/domain/node_registry.dart';
import 'package:lattice/src/features/nodes/domain/models/node_state.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;

/// The main entry point widget for the Flow Canvas library.
class FlowCanvas extends StatefulWidget {
  // --- CORE MEMBERS ---
  /// Optional. When omitted, an internal [FlowCanvasController] is created.
  final FlowCanvasController? controller;

  /// Optional. When omitted, state is built from [initialNodes]/[initialEdges]
  /// or starts empty (see [initState]).
  final FlowCanvasState? initialState;

  /// Optional initial nodes when [initialState] is null.
  final List<FlowNode>? initialNodes;

  /// Optional initial edges when [initialState] is null.
  final List<FlowEdge>? initialEdges;

  /// Optional. Defaults to [NodeRegistry] (includes built-in `default` node type).
  final NodeRegistry nodeRegistry;

  /// Optional. Defaults to [EdgeRegistry] (includes built-in edge types).
  final EdgeRegistry edgeRegistry;

  /// Optional. Defaults to [FlowCanvasOptions].
  final FlowCanvasOptions options;

  /// Optional. When null, inherits [FlowCanvasTheme] from [MaterialApp]
  /// (`toThemeData()` / theme extensions), else light/dark from brightness.
  final FlowCanvasTheme? theme;

  // --- UI ---
  final List<Widget> overlays;

  /// Called when a draggable String item is dropped onto the canvas.
  /// Provides the node type and the drop position in **flow (graph) space**.
  final void Function(String nodeType, Offset flowPosition)? onDrop;

  /// Optional canvas-style lifecycle callbacks.
  final FlowCanvasCallbacks callbacks;

  FlowCanvas({
    super.key,
    this.controller,
    this.initialState,
    NodeRegistry? nodeRegistry,
    EdgeRegistry? edgeRegistry,
    this.initialNodes,
    this.initialEdges,
    this.theme,
    FlowCanvasOptions? options,
    this.overlays = const [],
    this.onDrop,
    this.callbacks = const FlowCanvasCallbacks(),
  })  : nodeRegistry = nodeRegistry ?? NodeRegistry(),
        edgeRegistry = edgeRegistry ?? EdgeRegistry(),
        options = options ?? FlowCanvasOptions();

  @override
  State<FlowCanvas> createState() => _FlowCanvasState();
}

class _FlowCanvasState extends State<FlowCanvas> {
  late final ProviderContainer _providerContainer;
  late final FlowCanvasInternalController _internalController;
  /// Stable controller override so [updateOverrides] never remounts the canvas.
  late final Override _controllerOverride;

  // The facade controller provided by the user (or a default one).
  late FlowCanvasController _facade;

  @override
  void initState() {
    super.initState();

    _facade = widget.controller ?? FlowCanvasController();

    FlowCanvasState initialState;

    if (widget.initialState != null) {
      initialState = widget.initialState!;
    } else {
      final initialNodesMap = {
        for (var n in widget.initialNodes ?? []) n.id as String: n as FlowNode
      };

      final initialNodeStatesMap = {
        for (var n in widget.initialNodes ?? [])
          n.id as String: const NodeRuntimeState(),
      };

      final initialEdgesMap = {
        for (var e in widget.initialEdges ?? []) e.id as String: e as FlowEdge
      };

      final initialEdgesStatesMap = {
        for (var e in widget.initialEdges ?? [])
          e.id as String: const EdgeRuntimeState(),
      };

      final defaultVp = widget.options.viewportOptions.defaultViewport;
      initialState = FlowCanvasState.initial().copyWith(
        nodes: initialNodesMap,
        edges: initialEdgesMap,
        nodeStates: initialNodeStatesMap,
        edgeStates: initialEdgesStatesMap,
        viewport: defaultVp ?? const FlowViewport(),
      );
    }

    // Keep a stable override so [updateOverrides] never remounts the canvas.
    _controllerOverride = flowControllerProvider.overrideWith(
      () => FlowCanvasInternalController(initialState: initialState),
    );

    _providerContainer = ProviderContainer(
      overrides: [
        nodeRegistryProvider.overrideWithValue(widget.nodeRegistry),
        edgeRegistryProvider.overrideWithValue(widget.edgeRegistry),
        flowOptionsProvider.overrideWithValue(widget.options),
        flowCanvasCallbacksProvider.overrideWithValue(widget.callbacks),
        _controllerOverride,
      ],
    );

    _internalController =
        _providerContainer.read(flowControllerProvider.notifier);

    _facade.attach(_internalController);
  }

  @override
  void didUpdateWidget(FlowCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _facade.detach();
      _facade = widget.controller ?? FlowCanvasController();
      _facade.attach(_internalController);
    }

    // ProviderContainer overrides are only applied at creation unless updated.
    // Without this, AppBar toggles (connectOnClick, connectionMode, etc.) are ignored.
    if (widget.options != oldWidget.options ||
        widget.callbacks != oldWidget.callbacks ||
        !identical(widget.nodeRegistry, oldWidget.nodeRegistry) ||
        !identical(widget.edgeRegistry, oldWidget.edgeRegistry)) {
      // RF warns when nodeTypes/edgeTypes are recreated per render (usually
      // a builder defined inside build): remounts every custom node.
      if (!identical(widget.nodeRegistry, oldWidget.nodeRegistry) ||
          !identical(widget.edgeRegistry, oldWidget.edgeRegistry)) {
        final changed = [
          if (!identical(widget.nodeRegistry, oldWidget.nodeRegistry))
            'nodeRegistry',
          if (!identical(widget.edgeRegistry, oldWidget.edgeRegistry))
            'edgeRegistry',
        ].join(' + ');
        widget.callbacks.onError?.call(FlowCanvasError(
          'registries-recreated',
          'New $changed instance on rebuild — define registries once '
          '(State field / top-level) or every custom node remounts.',
        ));
      }
      _providerContainer.updateOverrides([
        nodeRegistryProvider.overrideWithValue(widget.nodeRegistry),
        edgeRegistryProvider.overrideWithValue(widget.edgeRegistry),
        flowOptionsProvider.overrideWithValue(widget.options),
        flowCanvasCallbacksProvider.overrideWithValue(widget.callbacks),
        _controllerOverride,
      ]);
      // Cell placement and cached paths depend on the origin — re-index
      // when it changes (no-op otherwise).
      if (widget.options.nodeOptions.nodeOrigin !=
          oldWidget.options.nodeOptions.nodeOrigin) {
        _internalController.syncNodeOrigin();
      }
    }
  }

  @override
  void dispose() {
    _facade.detach();
    _providerContainer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container: _providerContainer,
      child: FlowCanvasScope(
        controller: _facade,
        child: FlowCanvasThemeProvider(
          theme: widget.theme,
          child: FlowCanvasOptionsProvider(
            options: widget.options,
            child: _FlowCanvasCore(
              overlays: widget.overlays,
              centerOnInitialLoad: widget.initialState == null,
              onDrop: widget.onDrop,
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowCanvasCore extends ConsumerStatefulWidget {
  final List<Widget> overlays;
  final bool centerOnInitialLoad;
  final void Function(String nodeType, Offset canvasOffset)? onDrop;

  const _FlowCanvasCore({
    required this.overlays,
    this.centerOnInitialLoad = true,
    this.onDrop,
  });

  @override
  ConsumerState<_FlowCanvasCore> createState() => _FlowCanvasCoreState();
}

class _FlowCanvasCoreState extends ConsumerState<_FlowCanvasCore> {
  bool _hasInitialized = false;
  Size? _lastViewportSize;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(internalControllerProvider.notifier);
    final options = ref.read(flowOptionsProvider);

    final backgroundOverlays =
        widget.overlays.whereType<FlowBackground>().toList();
    final foregroundOverlays =
        widget.overlays.where((w) => w is! FlowBackground).toList();

    return KeyboardAdapter(
      controller: controller,
      options: options,
      keymap: Keymap.standard(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final newSize = Size(constraints.maxWidth, constraints.maxHeight);
          if (newSize != _lastViewportSize) {
            _lastViewportSize = newSize;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                controller.viewport.setViewportSize(newSize);
              }
              if (context.mounted && !_hasInitialized) {
                final viewportOpts = options.viewportOptions;
                if (widget.centerOnInitialLoad) {
                  if (viewportOpts.fitView) {
                    controller.viewport.fitView(
                      fitviewOptions: viewportOpts.fitViewOptions,
                      viewportOptions: viewportOpts,
                    );
                  } else if (viewportOpts.defaultViewport == null) {
                    controller.viewport.centerOnPosition(Offset.zero);
                  }
                }
                _hasInitialized = true;
                // React Flow onInit: live controller after first layout.
                ref
                    .read(flowCanvasCallbacksProvider)
                    .onInit
                    ?.call(FlowCanvasScope.of(context));
              }
            });
          }

          return DragTarget<String>(
            onWillAcceptWithDetails: (details) => true,
            onAcceptWithDetails: (details) {
              if (widget.onDrop == null) return;
              final canvasOffset =
                  controller.viewport.flowPositionFromGlobal(details.offset) ??
                      controller.viewport.viewportToFlow(Offset.zero);
              widget.onDrop!(details.data, canvasOffset);
            },
            builder: (context, candidateData, rejectedData) {
              FlowBackgroundStyle? patternStyle;
              if (backgroundOverlays.isNotEmpty) {
                patternStyle = backgroundOverlays.first.resolveStyle(context);
              }

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  ...backgroundOverlays,
                  FlowCanvasInteractiveSurface(
                    backgroundPatternStyle: patternStyle,
                  ),
                  ...foregroundOverlays,
                  const Positioned(
                    left: 0,
                    top: 0,
                    child: FlowA11yLiveRegion(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
