# Performance

How `lattice` stays fast, what we measured, and the habits that keep it fast.

## Model: matrix-first, hot/cold split

| Path | Behavior |
|------|----------|
| Pan / zoom | `InteractiveViewer` matrix is authoritative. Freezed `state.viewport` commits on gesture **end** (`SyncViewportMode.end`, default). No state churn per frame. |
| Camera flights | `fitView` / `centerOnPosition` / `setViewport` with a duration write the matrix per tick and commit **once** on landing (or on cancel). A user grab cancels the flight and commits the live position — no snap-back. |
| Node drag | Positions live in an `InteractionSession` buffer; committed graph + spatial index + history land on drop. Per move, only the dragged subtree rebuilds — static siblings skip gesture ticks entirely via per-node session scopes (`scopeFor`), and the edge layer does not rebuild (only dragged-attached edges repaint). `onNodeDrag` streams live positions without touching state. |
| Edges | Static edges behind a `RepaintBoundary`; animated edges share one ticker that exists only while mounted (and never under reduced motion);Reconnect/drag-attached edges paint on a separate active layer. |
| Culling | `ViewportOptions.onlyRenderVisibleElements` + spatial grid + hysteresis (`renderCullingPadding`, `nodeMountExtraPadding`). **On by default** — engages on the first frame (falls back to the `LayoutBuilder` size before `state.viewportSize` is seeded post-frame). During node drag the layer **freezes** its pre-drag visible set (`frozen ∪ dragAffected ∪ selected`) instead of querying the mid-drag-stale index, so no node vanishes and drag-start never mass-mounts. Keyboard/screen-reader reach to off-screen nodes is preserved by an always-mounted proxy layer (`FlowNodeA11yLayer`). Opt out with `onlyRenderVisibleElements: false`. |
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

Culling is now **on by default** (Sept 2026). The table pairs the default
against `onlyRenderVisibleElements: false` on the same machine/run so the
delta is honest; VNF's column is the earlier recorded run (not re-benched
this pass — treat cross-column ratios as directional, same-column deltas as
solid). p50 shown; means noted where they diverge.

| Scenario | lattice (default, cull on) | lattice (cull off) | vyuh_node_flow 0.27.3† |
|---|---|---|---|
| Mount (pumpWidget + settle) | ~9.7s (mean ~10.1s) | ~14.0s (mean ~13.7s) | ~1.3s |
| Drag, 10x10px moves, per-pump | p50 ~23ms (mean ~31ms, p95 ~146ms) | p50 ~21ms (mean ~29ms, p95 ~156ms) | p50 ~52ms |
| Tap-select | ~118ms (mean ~122ms) | ~175ms (mean ~179ms) | ~20ms |
| Bulk move 450 + fitView, total | ~26.8s | ~27.5s | ~1.1s |
| Full remount | ~8.4s (mean ~7.5s) | ~13.2s (mean ~12.4s) | ~1.1s |

† VNF column recorded in an earlier pass on the same harness; not re-run when
culling was flipped, so use it for order-of-magnitude context only.

Read it straight. Culling default-on is a clear same-machine win on the
mount-class scenarios — mount ~31% faster, remount ~37%, tap-select ~33% —
because only the on-screen band mounts instead of all 450 bodies. Drag is
**flat** (p50 23 vs 21ms) with **no drag-start spike**: freezing the visible
set on drag replaced the old wholesale un-cull that used to stall the first
move. Bulk move + `fitView` is flat (~27s) because it repositions and
re-fits every node — a genuine full-graph O(N) pass culling can't shortcut.

Versus VNF, mount/bulk-ops are still ~7-30x slower in this debug harness:
that's our RF-parity chrome (first inflate and bulk rebuilds are real O(N)
widget work, debug-slow) against a leaner node tree — culling narrows the
mount gap but does not close it. On interactive drag lattice stays ~2x
ahead (p50 23ms vs 52ms). Tap-select's pure-Dart cost is ~0.23ms at 450
nodes and rebuilds exactly one body; the ~120ms here is debug-mode
per-frame framework tax (assertions/timeline/layout), not an optimizable
term — so it's left alone (measured, September 2026).

Asymmetries documented in the bench headers (not hidden): VNF edges are
port-to-port (every node carries 2 ports; lattice edges are portless);
VNF changePos is 450x public `setNodePosition` (450 MobX actions) vs our
single bulk `load`; VNF select flushes an extra 100ms pump for its
double-tap timer.

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
   `SizedBox`; `onlyRenderVisibleElements` (on by default) unmounts off-screen
   subtrees while keeping keyboard/screen-reader reach via the proxy layer.
4. **Keep node chrome cheap.** Shadows, gradients, and animated edges cost
   raster time on every repaint — fine at 50 nodes, felt at 5000.
5. **Large-graph recipe:** `onlyRenderVisibleElements: true` (already the
   default), `lodHideHandlesBelowZoom: 0.4`, `lodThumbnailBelowZoom: 0.35`,
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
4. **Never query the spatial index mid node-drag.** The index holds stale
   pre-drag positions until drop, so a mid-drag query could drop a
   still-visible node. During `DragMode.node` the nodes layer keeps culling on
   but **freezes** its pre-drag visible set and adds only the drag-affected
   subtree + selection (`_lastCulledIds ∪ session.dragAffected ∪ selected`) —
   no query, no drag-start mass-mount. Correctness (no stuck/vanished nodes,
   no spike) beats frame savings here.
   Exemplar: the `DragMode.node` freeze branch in `buildStack`
   (`nodes_layer.dart`); pinned by `test/cull_drag_freeze_test.dart`.
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
