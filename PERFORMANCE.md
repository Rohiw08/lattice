# Performance

How `lattice` stays fast, what we measured, and the habits that keep it fast.

## Model: matrix-first, hot/cold split

| Path | Behavior |
|------|----------|
| Pan / zoom | `InteractiveViewer` matrix is authoritative. Freezed `state.viewport` commits on gesture **end** (`SyncViewportMode.end`, default). No state churn per frame. |
| Camera flights | `fitView` / `centerOnPosition` / `setViewport` with a duration write the matrix per tick and commit **once** on landing (or on cancel). A user grab cancels the flight and commits the live position — no snap-back. |
| Node drag | Positions live in an `InteractionSession` buffer; committed graph + spatial index + history land on drop. Per move, only the dragged subtree rebuilds — static siblings skip gesture ticks entirely via per-node session scopes (`scopeFor`), and the edge layer does not rebuild (only dragged-attached edges repaint). `onNodeDrag` streams live positions without touching state. |
| Edges | Static edges behind a `RepaintBoundary`; animated edges share one ticker that exists only while mounted (and never under reduced motion);Reconnect/drag-attached edges paint on a separate active layer. |
| Culling | `ViewportOptions.onlyRenderVisibleElements` + spatial grid + hysteresis (`renderCullingPadding`, `nodeMountExtraPadding`). Disabled mid node/connection drag (index defers to drop). Opt-in (RF default `false` preserved). The cull transform-listener wrapper is keyed on the option only and never toggles (a `viewportSize`-conditioned toggle wholesale-remounted all shells mid-gesture — fixed, pinned by `test/cull_drag_test.dart`). |
| LOD | `lodHideHandlesBelowZoom` drops handle widgets when zoomed out; `lodThumbnailBelowZoom` replaces all node widgets with one cached paint below its threshold (view-only down there — drag/resize/focus return when zooming back in). |

## Measured behavior

400 nodes + 399 chain edges, same harness for both libraries
(`flutter test` env: build + layout + gesture dispatch; **no rasterization**,
so paint/GPU costs are invisible here):

| Scenario | lattice | vyuh_node_flow 0.27.3 |
|---|---|---|
| Initial pump (warmed) | ~860 ms median, incl. eager edge geometry for all 399 edges | ~835 ms, nodes only (see notes) |
| Drag, 10 moves, verified displacing | **~85–95 ms total** | ~600–620 ms total |
| Drag cost vs N (9 / 100 / 400 nodes) | flat (~80–95 ms) | not measured |

Why the drag gap: our committed state is frozen mid-drag (one session write
per move, ~1 widget rebuild, edge layer untouched). Their per-move cost
rebuilds the dragged widgets **and** re-evaluates the full connections-layer
observer (two observable writes per move: `position` + `visualPosition`).

Caveats, stated plainly: single-machine widget-test numbers, not device fps;
vyuh samples are single-shot (repeat mounts in one isolate trip their init
ordering — a real bug we reported upstream in spirit); widget loads differ
slightly (ports vs handles). Treat ratios as directional. Re-run method:
grid graph per above, `Stopwatch` around `pumpWidget` / gesture+`pump` loop,
assert displacement so slop-eaten no-ops can't fake a win.

## 450-node render bench (September 2026)

Same fixture/scenarios/harness on both sides, outside-in black-box only:
30x15 grid (x*100, y*50), 50x30 nodes, 449 chain edges, 800x600 canvas,
`minZoom: 0.2`, 3 runs each. Lattice:
`packages/lattice/benchmark/outside_450_test.dart`; VNF counterpart:
`vyuh_node_flow/packages/vyuh_node_flow/benchmark/bench_outside_450_test.dart`.
Debug `flutter test` env (no rasterization; JIT-dominated first frames).
p50 shown; means track p50 except where noted.

| Scenario | lattice (default) | lattice (cull opt-in) | vyuh_node_flow 0.27.3 |
|---|---|---|---|
| Mount (pumpWidget + settle) | ~15.5s | ~16.8s | ~1.3s |
| Drag, 10x10px moves, per-pump | p50 ~25ms (mean ~33ms) | p50 ~27ms (mean ~482ms: one-time un-cull on dragStart) | p50 ~52ms |
| Tap-select | ~136ms | ~98ms | ~20ms |
| Bulk move 450 + fitView, total | ~34.2s | ~28.4s | ~1.1s |
| Full remount | ~16.1s | ~16.8s | ~1.1s |

Read it straight: on mount/bulk-ops VNF is ~10-30x faster in this
harness — leaner node tree vs our RF-parity chrome (first inflate and bulk
rebuilds are genuine O(N) widget work, debug-slow). On interactions, lattice
is at parity or better: steady-state drag moves ~25ms vs ~52ms, tap-select
~136ms vs ~20ms (was ~6s before the layer instance cache — the gap was
cascade waste, now fixed). Both sides show debug variance (VNF drag p95
~376ms; lattice cull-drag first move ~5.6s for the one-time un-cull).

Asymmetries documented in the bench headers (not hidden): VNF edges are
port-to-port (every node carries 2 ports; lattice edges are portless);
VNF changePos is 450x public `setNodePosition` (450 MobX actions) vs our
single bulk `load` — and still 30x faster, so the gap is per-emission/frame
cost, not API shape; VNF select flushes an extra 100ms pump for its
double-tap timer.

Cull opt-in bug (Sept 2026 bench, 3/3 repro — FIXED): on a fresh
canvas with `onlyRenderVisibleElements: true`, the first node drag started
(mode=node, selection lands) but moves/up were lost — displacement 0.0 and
the drag stuck in `DragMode.node`. Root cause: the cull transform-listener
wrapper was conditioned on `viewportSize`, so its toggle wholesale-unmounted
every node shell mid-gesture (in-flight recognizer disposed). Fix: the
wrapper is keyed on the *option* only and never toggles; the cull filter
keeps its own null/empty-size guard. Pinned by `test/cull_drag_test.dart`.
The same toggle also caused the ~300-body select storm under culling
(~34s → ~98ms tap-select).

## Habits that keep it fast

1. **Hoist `callbacks`, registries, and options to `State` fields.**
   `didUpdateWidget` refreshes provider overrides when these change identity;
   fresh closures per `build` mean churn on every parent repaint (and can
   reset in-flight gestures). Same reason React Flow says `useCallback`.
2. **Select slices, never filter maps in `build`.**
   `flowNodesProvider.select((n) => n.length)` rebuilds only when the count
   changes; watching the whole map rebuilds on every commit. Dedicated
   `flowSelectedNodeIdsProvider` / `flowViewportProvider` exist for this.
3. **Collapse with `hidden`, cull with options.** `hidden` nodes mount one
   `SizedBox`; `onlyRenderVisibleElements` unmounts off-screen subtrees.
4. **Keep node chrome cheap.** Shadows, gradients, and animated edges cost
   raster time on every repaint — fine at 50 nodes, felt at 5000.
5. **Large-graph recipe:** `onlyRenderVisibleElements: true`,
   `lodHideHandlesBelowZoom: 0.4`, `lodThumbnailBelowZoom: 0.35`,
   `syncViewportToState: SyncViewportMode.end` (the default).

## Debugging

```dart
FlowCanvasDebug.logPerf = true;
FlowCanvasDebug.logInteraction = true;
FlowCanvasDebug.resetCounters();
```

Stress graphs: `buildSyntheticGrid(cols: 32, rows: 32, withChainEdges: true)`.
`controller.viewport.isAnimating` tells you whether a camera flight is active.

## Contributor contract: five invariants

Custom nodes/edges stay widgets forever — contributors never need perf
knowledge to build on this library. Performance lives in a handful of core
files as boring, documented invariants. If your change touches one of these
areas, keep its invariant or update the contract test next to it:

1. **No fresh collections in selectors.** A rebuilt `Set`/`Map`/`List` fails
   `==` every emission and rebuilds the whole consumer. Select the stored
   object itself. Exemplar: `selectedNodes` passthrough in
   `lib/src/features/nodes/presentation/nodes_layer.dart`.
2. **Every painter skips no-op repaints.** Fresh map instances per build mean
   identity comparison always repaints — compare key sets, then per-edge
   versions. Every new painter ships with a skip/repaint unit test.
   Exemplar + template: `test/edge_painter_test.dart`.
3. **Every visual change bumps a version.** The geometry service hashes all
   paint inputs (path, style, markers, animation, selectable, data) into
   `edgeVersions`; painters compare only their own ids. If you add a paint
   input, add it to the hash or stale pixels won't repaint.
   Exemplar: `lib/src/features/edges/application/edge_geometry_service.dart`.
4. **Culling stays off the drag path.** The spatial index defers to drag-end,
   so nothing may cull on mid-drag queries. Correctness (no stuck/vanished
   nodes) beats frame savings here.
   Exemplar: `allowCull` in `nodes_layer.dart`.
5. **Cache, don't recompute, per frame.** Tangents, laid-out text, and
   precomputed paths come from a service cache the painter receives — never
   recomputed inside `paint`.
   Exemplar: `geoms` threading in `lib/src/features/edges/presentation/layer/edges_layer.dart`.
6. **Stable child instances across cascades.** Parent rebuilds must pass the
   identical child widget where inputs are unchanged (bodies, gesture shells,
   listenables) — identical instances short-circuit element updates, while
   the child's own watches still fire exactly when its inputs change. Fresh
   instances per build turn every cascade O(N) bodies + recognizer
   re-creation + subscription churn. Multi-field `select`s merge into single
   record selects with identical rebuild semantics.
   Exemplar: `_NodeWidgetState` caches in `nodes_layer.dart`.

## CI budgets and benches

- `benchmark/budget_test.dart` — gated in CI. Pure service-level ceilings at
  >50x measured values: catches algorithmic regressions, never flakes.
- `benchmark/headless_450_test.dart` — runs in CI, informational numbers.
- `benchmark/outside_450_test.dart` — widget-level, run alone on a quiet
  machine (or scheduled CI); numbers are tracked as artifacts, never gated,
  because debug-build frame timings vary run to run. Its displacement asserts
  still guard correctness.
