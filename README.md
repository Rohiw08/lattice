# lattice

A Flutter node-based canvas editor library for building interactive flow editors,
diagram tools, and visual programming surfaces. A Flutter port of the
[React Flow](https://reactflow.dev) API, tuned for large graphs.

## Install

```bash
flutter pub add lattice
```

```dart
import 'package:lattice/lattice.dart';
```

## Features

- **Nodes & edges** — draggable, selectable, resizable nodes; bezier / straight /
  step / smoothstep edges with labels, markers, and reconnection.
- **Typed node data** — model payloads as `sealed` hierarchies and register typed
  builders; no `applyNodeChanges` ceremony ([`TYPING.md`](TYPING.md)).
- **Connections & handles** — drag-to-connect and click-to-connect, per-handle
  validation, custom handle widgets.
- **Viewport** — matrix-first pan/zoom, `fitView`, snap-to-grid, coordinate extents.
- **Built-in UI** — minimap, controls, panels, node/edge toolbars, background patterns.
- **Theming** — light/dark themes with per-component `Flow*Style` cascades.
- **Accessibility** — keyboard navigation and screen-reader support out of the box.
- **Performance** — viewport culling, hot/cold rendering, and a spatial index keep
  large graphs smooth ([`PERFORMANCE.md`](PERFORMANCE.md)).
- **React Flow parity** — familiar API surface (`fitView`, `getNodesBounds`,
  `onConnect`, …) for developers coming from React Flow.

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

## Typing

Uncontrolled by default — no `applyNodeChanges` ceremony. Model payloads
as `sealed` hierarchies, register typed builders, switch exhaustively.
Details + runnable example: [`TYPING.md`](TYPING.md), [`example/main.dart`](example/main.dart).

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

The canvas uses a **hybrid hot/cold** model. Full story + measured numbers:
[`PERFORMANCE.md`](PERFORMANCE.md).

| Path | Behavior |
|------|----------|
| Pan / zoom | `InteractiveViewer` matrix is authoritative. Freezed `state.viewport` commits on gesture **end** (`SyncViewportMode.end`, default). |
| Node drag | Positions live in an internal `InteractionSession` buffer; Freezed graph + spatial index + history commit on drag **end**. |
| Edges | Static edges sit behind a `RepaintBoundary`; only edges attached to dragged nodes repaint mid-drag. |
| Culling | On by default (`ViewportOptions.onlyRenderVisibleElements`): off-screen node widgets aren't mounted, so large graphs are fast out of the box. Uses the spatial grid + hysteresis; keyboard/screen-reader access to off-screen nodes is preserved. Set it `false` to mount every node. |

### Recommended options for large graphs

```dart
ViewportOptions(
  onlyRenderVisibleElements: true,           // default (shown for clarity)
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
