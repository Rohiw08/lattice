# lattice

A Flutter node-based canvas editor library for building interactive flow editors,
diagram tools, and visual programming surfaces.

## Quick start

```dart
FlowCanvas(
  controller: controller,
  nodeRegistry: registry,
  edgeRegistry: edgeRegistry,
  initialNodes: nodes,
  initialEdges: edges,
)
```

Use [`FlowCanvasController`](lib/src/features/canvas/flow_canvas_controller.dart) for imperative APIs (`nodes`, `edges`, `viewport`, `history`, …).

## Theming

```dart
MaterialApp(
  theme: FlowCanvasTheme.light().toThemeData(),
  darkTheme: FlowCanvasTheme.dark().toThemeData(brightness: Brightness.dark),
  themeMode: ThemeMode.system,
);
```

Customize with `FlowCanvasTheme.copyWith` / per-component `Flow*Style`. Details: [`THEMING.md`](THEMING.md).

## Performance

The canvas uses a **hybrid hot/cold** model:

| Path | Behavior |
|------|----------|
| Pan / zoom | `InteractiveViewer` matrix is authoritative. Freezed `state.viewport` commits on gesture **end** (`SyncViewportMode.end`, default). |
| Node drag | Positions live in an internal `InteractionSession` buffer; Freezed graph + spatial index + history commit on drag **end**. |
| Edges | Static edges sit behind a `RepaintBoundary`; only edges attached to dragged nodes repaint mid-drag. |
| Culling | Enable `ViewportOptions.onlyRenderVisibleElements` for large graphs. Uses the spatial grid + hysteresis. |

### Recommended options for large graphs

```dart
ViewportOptions(
  onlyRenderVisibleElements: true,
  syncViewportToState: SyncViewportMode.end, // default
  lodHideHandlesBelowZoom: 0.4,              // optional LOD
  minZoom: 0.1,
  maxZoom: 4.0,
)
```

### Debug

```dart
FlowCanvasDebug.logPerf = true;
FlowCanvasDebug.logInteraction = true;
FlowCanvasDebug.resetCounters();
```

Stress graphs: `buildSyntheticGrid(cols: 32, rows: 32, withChainEdges: true)`.

### Escape hatch

If your app must read committed `state.viewport` every frame:

```dart
ViewportOptions(syncViewportToState: SyncViewportMode.live)
```

Prefer listening to `onViewportChange` (throttled from the live matrix) instead.
