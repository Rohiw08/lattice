# Changelog

## 0.2.0 - 2026-09-22

- Architecture cleanup pass (no behavior change except where noted):
  `endSelection` no longer records an undo entry for the transient
  marquee clear (behavior fix); `watchNodeConnections` /
  `watchNodesDataMany` / edge-label portal select stored maps instead of
  fresh collections (invariant #1: edge commits no longer rebuild every
  consumer); edge-hover clearing routes through
  `EdgesController.clearEdgeHover`; connection flows commit via
  `EdgeService.upsertEdge` (single helper, single-mutate undo steps
  preserved); `flow_canvas_state.dart` no longer imports the barrel.
  Consistency: `package:lattice/` imports everywhere (7 outliers fixed);
  `getNodeBounds` renamed to RF-parity `getNodesBounds`;
  `keyboard_action_service.dart` renamed to `keyboard_service.dart`;
  `benchmark/bench_helpers.dart` dedups the widget-bench harness;
  empty feature shells removed. New `ARCHITECTURE.md` codifies layers,
  write paths, selectors, and naming. Pinned by the full suite
  (439 tests green).
- Publish hygiene: stale `benchmark/*.log` traces removed from the
  package and git-ignored.

## Unreleased

- Theme cascade correctness (no API change, pre-1.0 behavior fix): partial
  local `Flow*Style` overrides now change only the fields they set and inherit
  the rest from the global theme (RF's CSS-inheritance model / the repo's
  "other wins, nulls inherit" contract), instead of silently resetting unset
  fields to component defaults. Fixed across `FlowConnectionStyle`,
  `FlowEdgeLabelStyle`, `FlowMinimapStyle`, `FlowNodeResizerStyle`,
  `FlowBackgroundStyle`, and `FlowSelectionStyle`: customizable fields are now
  nullable (`null` = inherit), `merge()` is uniform `other.x ?? this.x`, and
  defaults resolve at read time via `effectiveX` getters. `FlowBackgroundStyle`
  additionally drops a broken sentinel-comparison merge that both leaked
  defaults *and* silently dropped explicitly-set values equal to the sentinel
  (e.g. `gap: 25.0`); `FlowEdgeLabelStyle` theme padding now actually applies
  (it was read only from `widget.padding`). Pinned by `test/theme_cascade_test.dart`.
- Handle mount cost (no API change): the built-in default node synthesizes 2
  handles, so a 450-node graph mounts 900 `Handle` widgets. Each was a
  `ConsumerWidget` running 5 `.select()` watches wrapped in a nested
  `Consumer` running 5 more — ~9000 provider subscriptions wired at mount,
  ~11.6s of a ~13.2s handle cost. Collapsed into 2 record-selects (one on the
  controller, one on options) with the nested `Consumer` dropped; fair 450-node
  mount fell ~15s → ~2.65s (built-in default node ~9.7s → ~2.97s), closing the
  mount gap vs VNF from ~11.7× to ~1.9×. Also fixed a latent gating bug where a
  non-interactive canvas could still start a connection from an explicitly
  `isConnectable` handle (the override was re-applied after the `&& interactive`
  mask). See PERFORMANCE.md invariant #6.
- Breaking (pre-1.0) default: viewport culling is now **on** by default
  (`ViewportOptions.onlyRenderVisibleElements` flips `false` → `true`, both
  ctors). Off-screen node widgets aren't mounted, so large graphs are fast out
  of the box. This is safe now that culling (a) engages on the first frame —
  the nodes/edges layers fall back to the `LayoutBuilder` size before
  `state.viewportSize` is seeded post-frame, so frame 1 mounts only the visible
  band instead of all N; (b) **freezes** its visible set during node drag
  (`frozen ∪ dragAffected ∪ selected`) instead of wholesale-disabling culling,
  killing the drag-start mass-mount (drag p95 stays ~146ms, was ~4666ms when
  culling was disabled on drag); and (c) preserves keyboard traversal +
  screen-reader access + focus-into-view for off-screen nodes via an
  always-mounted proxy layer (`FlowNodeA11yLayer`, one lightweight
  Focus+Semantics proxy per node, mirroring `EdgeA11yLayer`). Opt out with
  `ViewportOptions(onlyRenderVisibleElements: false)`. Same-machine 450-node
  debug bench (cull on vs off): mount ~31% faster, remount ~37%, tap-select
  ~33%, drag flat with no spike. Pinned by `test/cull_drag_freeze_test.dart`,
  `test/cull_focus_traversal_test.dart`, `test/viewport_options_default_test.dart`.
- Cull first-drag fix (correctness, no API change): with
  `onlyRenderVisibleElements: true`, the first drag on a fresh canvas lost
  moves/up (0.0 displacement, stuck `DragMode.node`, 3/3 bench repro). Root
  cause: the cull transform-listener wrapper was conditioned on
  `viewportSize`, so its toggle wholesale-unmounted all 450 node shells
  mid-gesture, disposing the in-flight recognizer. The wrapper is now keyed
  on the option only and never toggles (the cull filter keeps its own
  null/empty-size guard). Pinned by `test/cull_drag_test.dart` (fails 0.0
  without, passes with). The same toggle caused the cull select storm
  (~300 bodies, ~34s → ~98ms tap-select).
- Layer instance cache (no API change, invariant #6 one level up):
  `FlowNodesLayer` (now stateful) holds stable `_NodeWidget` instances per
  node id across rebuilds, so a selection toggle no longer mints 450 fresh
  widgets (450 element updates + gesture-shell resyncs) — cascades skip
  unchanged nodes while their own watches still fire exactly when needed.
  Measured: tap-select 5.9s → 136ms, drag mean 656ms → 33ms (first-move
  storm gone), cull tap-select 34.4s → 98ms; mount/remount unchanged
  (genuine first-inflate work).
- Render benchmarking vs VNF (Sept 2026, 450-node outside-in black-box):
  new VNF counterpart bench at
  `vyuh_node_flow/packages/vyuh_node_flow/benchmark/bench_outside_450_test.dart`
  (same fixture/scenarios/harness/JSON shape, asymmetries documented in its
  header). Both benches now render the *same* fair node (`BaseNode` + 2
  handles + label; selectable via `--dart-define=LATTICE_BENCH_NODE=fair|
  bare|chrome|default`) — an earlier run compared a bare lattice
  `SizedBox+Text` against VNF's decorated 2-port node and wrongly read mount
  as tied. Corrected same-machine p50s, each library at its culling default:
  mount ~2.65s vs ~1.36s, drag-move p50 ~31ms (p95 ~80ms) vs ~52ms (p95
  ~371ms), tap-select ~72ms vs ~16ms, bulk move+fitView ~5.16s vs ~1.03s,
  remount ~2.31s vs ~1.11s. **Drag is the one interactive scenario and
  lattice wins it — 4.6× steadier at the tail.** Full table + asymmetries in
  `PERFORMANCE.md`; debug-harness caveats stand (no rasterization, JIT first
  frames).
- Culling verification (superseded by the default-flip entry above): the cull
  variant was validated working — tap-select + gesture drag commit correctly
  under it — before it became the default.
  `benchmark/outside_450_test.dart` accepts `--dart-define=LATTICE_BENCH_CULL=true`
  to force the variant on for the head-to-head bench regardless of the default.
  Full table + asymmetries in `PERFORMANCE.md`.
- Per-node drag scopes (no API change): node shells now listen to a filtered
  session scope instead of the whole gesture notifier, so static siblings run
  zero builders and zero element updates on drag ticks — only dragged roots,
  their descendants, and live-resized ids rebuild. Pinned by
  `test/interaction_scope_test.dart`; full suite green.
- Cascade hardening (no API change): node shells hold stable child/widget
  instances (body, resizer slot, gesture shell, session scope) across parent
  rebuilds, so a selection toggle rebuilds 1 body instead of 450 and never
  recreates recognizers or resubscribes mid-cascade; multi-field Riverpod
  selects are merged into single record selects with identical rebuild
  semantics. Measured: tap-select 41s → ~8s debug (450 nodes), 155ms → 133ms
  (45 nodes); drag p50 1.2s → 32ms.
- Perf governance: `PERFORMANCE.md` now carries a five-invariant contributor
  contract (no fresh collections in selectors, painters skip no-op repaints,
  visual changes bump versions, culling off the drag path, cache-don't-
  recompute) with exemplars; `benchmark/budget_test.dart` gates generous
  service-level ceilings in CI; `.github/workflows/lattice-ci.yml` runs
  analyze + full suite + budgets + headless bench per PR and tracks the
  widget bench weekly as an artifact.
- Steady-state rendering work reduction (no API change): edge tangents are
  now sourced from the shared `EdgeGeometryService` cache in the painter
  (previously recomputed per edge per repaint), the static edge layer skips
  repaints while no painted input changed (per-edge version check), and the
  node layer no longer rebuilds on controller emissions that leave selection
  untouched. Same pixels, fewer repaints/rebuilds during drags and viewport
  gestures.
- `nodeOrigin` parity (RF `nodeOrigin`): `NodeOptions.nodeOrigin` (default
  top-left) plus per-node `FlowNode.origin` override. `position` is the
  anchor point; rendering, hit-testing, edge geometry, minimap, marquee,
  bounds/fitView, and all clamps resolve the visual rect, while drag math,
  snapping, and stored JSON stay in anchor space. Children anchor to the
  parent's stored position. Spatial index, edge cache, and keyboard moves
  are origin-aware; changing the option at runtime re-indexes.
- `dragHandle` parity (RF `dragHandle`), Flutter-idiomatic: set
  `FlowNode.dragHandle` and wrap the grab area in a `FlowDragHandle`
  widget. Drags starting elsewhere still select but never move. Gated at
  pointer-down in the node recognizer (exact — `onStart` is post-slop).
- `NodeToolbar`/`EdgeToolbar` parity: `FlowNodeToolbar`/`FlowEdgeToolbar`
  overlays track their element through pan/zoom/live drags at constant
  screen size. Visibility follows selection unless pinned with `isVisible`;
  position/align/offset mirror RF.
- Edge-label portal parity (RF `EdgeLabelRenderer`): `FlowEdge.overlayLabel`
  + `FlowEdgeLabelPortal` overlay renders interactive labels at the path
  midpoint, unscaled, pointer-opaque on their box (RF `nodrag nopan`
  equivalent). `FlowEdge.label` stays the canvas-space presentation badge;
  new `FlowEdgeText` convenience covers RF `EdgeText`.
- Custom edges parity (RF custom edge guide): `EdgeTypeConfig.pathBuilder`
  replaces path computation (bounds, hit-testing, labels, markers derive
  automatically) and `foregroundPainter` paints canvas-space decorations;
  both are copied onto created edges and settable on `FlowEdge` directly.
  `EdgePathCreator` statics are now public for custom path math.
- Resizer parity (RF `minWidth/minHeight/maxWidth/maxHeight/`
  `keepAspectRatio`/`shouldResize`/`NodeResizeControl`): per-node
  `minSize`/`maxSize`/`keepAspectRatio` (ratio from resize-start size) and
  a `shouldResize` veto (absolute base+travel mapping dead-zones cleanly);
  new `FlowNodeResizeControl` single-handle widget for custom builders
  (also exported: `FlowNodeResizer`). Note: edge-straddling chrome in
  custom builders must root in `InfiniteHitTestStack` — a stock `Stack`
  gates hit tests on `size.contains` (exclusive edges), making exactly
  on-edge presses unreachable.
- Delete lifecycle parity (RF `onBeforeDelete`/`onDelete`/
  `onNodesDelete`/`onEdgesDelete`): synchronous veto/transform gate plus
  combined/split notifications with the removed objects; `deleteElements`
  now returns `FlowDeletedElements` (breaking, pre-1.0). Delete-key
  removal routes through the same gate (still one undo step). Direct state
  writes bypass it, like RF's raw setters.
- Small parity: pure `getViewportForBounds` (RF util; `fitBounds` refactored
  onto it), `onMoveStart`/`onMoveEnd` around user viewport gestures,
  `KeyboardOptions.zoomActivationKeys` (RF `zoomActivationKeyCode`).
  `deleteKeyCode` needs no API — remap `KeyboardOptions.shortcuts`;
  thresholds stay on Flutter slop deliberately.
- Hook parity: `watchConnection` + `FlowConnectionInfo` (RF `useConnection`:
  live rubber-band from/to/validity), `watchNodesInitialized` (RF
  `useNodesInitialized`: true once layout completes — nodes are
  synchronously sized, so no measure pass exists), `FlowKeyPress` widget
  (RF `useKeyPress`: rebuilds while keys are held, never consumes events).
- Per-handle connectability (RF per-`Handle` props): `FlowHandle.
  isConnectableStart`/`isConnectableEnd` with type-derived defaults,
  per-handle `isValidConnection` validators, `onConnect` callbacks fired on
  both ends of fresh edges, and declarative `maxConnections` enforced by
  edge count. Gated at drag start, landing, and drop; node
  `connectable: false` now blocks starts and completions. `Handle` widget
  mirrors the flags for local gating/dimming (widget → model → node);
  service-side validation/callbacks live on the model.
- Pointer-event observation (RF `onNodeClick`/`onEdgeClick`/pane/selection
  families): tap-down `onNodeClick/DoubleClick`, `onEdgeClick/DoubleClick`,
  hover enter/move/leave for nodes and edges (with leave synthesized when
  hover silently transfers), `onNodeDragStart/Stop` and multi-drag
  `onSelectionDragStart/Drag/Stop` in the `NodeChange` shape, marquee
  `onSelectionStart/End`, distinct click-connect `onClickConnectStart/End`,
  `onPaneClick` (tap, suppressed during marquees), routed
  `onNode/Edge/PaneContextMenu` on secondary press-release, and `onInit`
  with the live controller.
- Flags: `NodeOptions.selectNodesOnDrag` (RF exact: unselected drags move
  without selecting and clear selection), top-level `elementsSelectable`
  master switch, `ZIndexMode` (`auto` = current, `basic` = selection boost
  only, `manual` = raw zIndex), `EdgeOptions.style`/`label` globals
  (`defaultEdgeOptions` parity, merged theme → options → edge).
- Utils: `ViewportController.getZoom()`, snapshotted coordinates
  (`viewportToFlow`/`flowPositionFromGlobal` `snapToGrid` flag),
  `getStraightPath`/`getSimpleBezierPath` publics (exact RF control-point
  math), `isEdge`/`isNode` guards, `FlowNodeHandle` (`NodeHandle` parity).
- Round-2 event parity: resize trio `onNodeResizeStart/Resize/End`
  (payload: the resized node), pane `onPaneScroll` (processed wheel scrolls
  only — locked panes and `FlowNoWheel` regions stay silent) and
  `onPaneMouseEnter/Move/Leave` in flow coordinates (pure observers, no
  rebuilds), plus `onSelectionContextMenu` (fires alongside
  `onNodeContextMenu` when the right-clicked node is selected).
- `ReactFlowJsonObject`/`toObject` parity: `controller.toObject()` returns
  `{nodes, edges, viewport}` for save/restore with `load`; `FlowViewport`
  gains RF `x`/`y` aliases; `NodesController.queryNodesInRect` exposes the
  spatial rect query (`getIntersectingNodes` keeps its id form).
- Round-3 completion parity (all RF-verified in `xyflow/`): `onBeforeConnect`
  (`false` cancels, `FlowEdge` inserts as-is, `ConnectionParams` rewrites
  endpoints — drag + click paths) and `onBeforeReconnect` (candidate edge +
  old edge; `false` snaps back, returned edge commits under the old id).
  Only `false` cancels (Dart cannot split RF's void/null); omitting the
  callbacks keeps default behavior.
- Collection utils (RF `addEdge`/`reconnectEdge`/`applyNodeChanges`/
  `applyEdgeChanges`), Map-flavored: same-instance return when unchanged,
  RF `connectionExists` dedup, `shouldReplaceId` id minting. Plus
  `EdgePathCreator.getEdgeCenter` (exact RF center/half-extent math) and
  `EdgesController.updateEdge(id, updater)` (RF whole-edge form; the old
  data-only updater is now `updateEdgeDataWith`, pre-1.0 rename).
- Connection-line completion: `ConnectionOptions.connectionLineStyle`
  (RF `connectionLineStyle`, merged theme → options → per-connection) and
  `connectionLineBuilder` (RF `connectionLineComponent`: flow-space widget
  replacing the painted rubber-band, with `FlowConnectionInfo` endpoints).
- Hook forms: `watchViewportChange` (RF `useOnViewportChange.onChange`) and
  `watchSelectionChange` (RF `useOnSelectionChange`) for `build`-time
  `ref.listen` subscriptions.
- Interactivity switch (RF `setInteractive` / Controls `showInteractive`):
  transient `FlowCanvasState.interactive` (default true, not serialized)
  gating node drag/select, edge select, connection starts, and marquees;
  viewport, observations, and programmatic reads keep working.
  `controller.setInteractive` + a `FlowCanvasControls` toggle button
  (`controlsInteractive` label) drive it.
- Aria completion: `handleLabel` (each `Handle` is now its own labelled
  semantics node, like RF's handle divs), `controlsLabel` (`Control Panel`
  group), `controlsInteractive`; `FlowNodeResizer` gains `style`/`color`
  (RF `handleStyle`/`lineStyle`/`color`); `FlowMiniMap.onClick` (RF minimap
  `onClick`, viewport still centers); viewport `zoomIn`/`zoomOut` and
  `screenToFlowPosition`/`flowToScreenPosition` aliases.
- Final-pass correctness: canvas-level capability flags now actually gate
  behavior (per-node wins, null inherits the global — RF override order).
  `FlowNode` capability flags are null by default (were non-null literals
  that starved the globals); `ResolvedNodeOptions` extension mirrors the
  existing `ResolvedEdgeOptions`. Covered: drag/select/connect/delete/
  resize/focus/hover visuals, connection validation, marquee selection
  (unselectable nodes/edges no longer join), keyboard moves/deletes,
  deleteElements, and the global `expandParent` default. Raw programmatic
  APIs (`removeNodes`, `moveNodes`, `selectNode`, `selectAll`) bypass
  per-element flags by design, like raw writes bypass `onBeforeDelete`.
- Gate fixes: observers (`onConnection`, per-handle `onConnect`) report the
  attempted connection when `onBeforeConnect` rewrites endpoints (RF
  `onconnect` parity); gate-returned edges get RF `addEdge` guards
  (dangling endpoints / duplicates insert nothing).
- Additions: `Controls.onInteractiveChange`, deterministic
  `edgeIdForConnection` (RF `getEdgeId` shape), RF callback/type aliases
  (`Node`, `Edge`, `Position`, `OnConnect`, `OnReconnect`,
  `OnNodesChange`, `OnSelectionChange`, … — `Viewport` deliberately
  omitted, it clashes with Flutter's widget).
- Fixed `NodeOptions.resizable` doc (said true, is false).
- Auto-layout (dagre/ELK counterpart): new `FlowLayout` pure utils.
  `FlowLayout.layered` is longest-path layering with barycenter crossing
  reduction for DAGs/pipelines; `FlowLayout.tree` is Buchheim tidy-tree
  for mindmaps/org-charts. Both take node/edge maps and return positioned
  copies (inputs untouched), honor node sizes, all four directions,
  offsets, forests (tiled), cycles (no hangs), and leave parented children
  riding along. Pair with `load` + `fitView` like the dagre recipe.
- Controls parity: `FlowCanvasControls.fitViewOptions` (RF prop) drives the
  fit-view button, `onZoomIn/onZoomOut/onFitView` fire after the default
  actions, and button tooltips come from `FlowA11yLabels`
  (`controlsZoomIn/Out/FitView/Lock/Unlock/Undo/Redo`, RF
  `controls.*.ariaLabel` + canvas additions). `FlowMiniMap.semanticLabel`
  null now falls back to `labels.minimapLabel` (RF `minimap.ariaLabel`); set
  `includeInSemantics: false` to exclude it (breaking, pre-1.0: explicit
  `semanticLabel: null` no longer excludes). `FlowNodeResizeControl.offset`
  mirrors RF `NodeResizeControl.offset`.
- Breaking (pre-1.0) default: wheel zoom now needs Meta/Ctrl held (RF
  `zoomActivationKeyCode` default, source-verified in
  `ReactFlow/index.tsx`). Pass an explicit `zoomActivationKeys` set to
  change the keys, or an empty set to disable wheel zoom.

- Fixed clamp dead-zone parity for node drag and resize (RF
  `XYDrag.updateNodes` + `calculateNodePosition`): both now map pointer
  travel absolutely from the gesture anchor instead of accumulating
  per-frame deltas, so pushing a node into `extent: parent` (or a group
  edge into the child-extent floor / min size) and coming back pins in a
  dead zone and restores the origin — previously the clamped-away travel
  was kept as a permanent cursor/edge gap. Resize anchors via the handle's
  `onResizeStart` (`NodesController.onNodeResizeStart`); the service takes
  an optional `baseRect` (one-shot calls unchanged).
- Fixed the same dead-zone gap for minimap panning against a finite
  `translateExtent`: `FlowMiniMap` (now stateful) anchors the committed
  offset at pan start, accumulates travel, and writes `anchor + travel`
  through the clamped viewport path instead of incremental `panBy`.

- Diagnostics channel (`FlowCanvasCallbacks.onError`, RF `onError` parity):
  warn-once errors for unregistered node types, `extent: parent` without a
  parent, dangling/reconnect-missing edges, and per-render recreated
  registries.

- Breaking (pre-1.0) RF-parity defaults: resizing is opt-in
  (`FlowNode.resizable` / `NodeOptions.resizable` now false); edges no
  longer elevate on select (`EdgeOptions.elevateEdgeOnSelect` now false);
  `FlowEdge.interactionWidth` now 20.0 (was 10.0, RF `BaseEdge` default).
- Marquee auto-pan (`ViewportOptions.autoPanOnSelection`, default true —
  RF `autoPanOnSelection`): box selection dragged past the viewport edge
  pans the live camera and extends the selection, committing on release.
- Space-pan (`KeyboardOptions.panActivationKeys`, default Space — RF
  `panActivationKeyCode`): held + left-drag pans the viewport instead of
  dragging nodes, marquees, or (de)selecting; taps and keyboard Space-select
  are unaffected. Empty set disables.
- Pane taps and marquee starts now land anywhere visible: the backdrop
  tracks the visible flow rect (previously dead outside the origin box)
  and marquee origins convert to flow coordinates.
- Theme defaults adopted from RF's current xy-theme system (breaking,
  pre-1.0): node cards `#fff`/`#1a1b1e` with `#ededed`/`#303238` borders,
  8px radius and soft shadows (was `#1a192b`/`#1e1e1e`, 3px, shadow-ring
  selection); blue `#2196f3` selection borders; white/`#aaa` and
  `#141519`/`#5a5d66` handles; `#f7f9fb`/`#101012` canvas; purple `#9e86ed`
  group + resizer accents; base-CSS marquee greys. Groups are now
  brightness-aware.
- Defaults aligned to React Flow (source-verified): `fitView()` is instant
  unless a `duration` is passed (`FitViewOptions.duration` now defaults to
  zero), `connectOnClick` defaults to true, `reconnectRadius` to 10,
  `SnapGrid` to 15×15. Already matching: min/maxZoom 0.5/2,
  `selectionMode.full`, zoom/pan/scroll flags + speeds, `selectionKey`
  Shift, Meta/Ctrl multi-select, Backspace delete, `translateExtent`/
  `nodeExtent` infinite, focusable flags, `autoPanOnNodeFocus`,
  `elevateNodesOnSelect`, `connectionMode.strict`, `connectionRadius` 20.
  Deliberately not aligned: fit padding units (px vs fraction),
  drag thresholds (platform slop vs 1px), viewport-clamped fit zoom.

- Camera animation: `FitViewOptions.duration`/`ease`/`interpolate` are now
  honored (`fitView()` is instant by default like React Flow;
  `FitViewOptions.smooth()` glides), `centerOnPosition`/`setViewport`/`zoom` take optional
  `duration`/`ease`/`interpolate`, new `zoomTo`/`fitBounds`, all camera
  methods return `Future<bool>` (true on landing, false on cancel/supersede/
  lock), plus `isAnimating`/`cancelAnimation` (user grabs cancel flights
  without snapping back). `lerpViewport` exported.
- Thumbnail LOD: `ViewportOptions.lodThumbnailBelowZoom` paints nodes as
  cached rects instead of mounting widgets when zoomed out (view-only down
  there). `lerpViewport` exported. See PERFORMANCE.md.
- Accessibility: per-node/edge keyboard focus (Tab traversal, Enter/Space to
  select), `A11yOptions` (`announcements`, `autoPanOnNodeFocus`, localizable
  `FlowA11yLabels`), assertive live region, `semanticsLabel` on nodes/edges,
  minimap label, focus ring, reduced-motion edge paint, Shift-boosted arrow
  movement, `UnboundedSemantics` hit-test-transparent semantics.
- Instance APIs: `FlowCanvasScope.of`, `flowStateProvider`, `getIntersectingNodes`,
  `isNodeIntersecting`, `getConnectedEdges`, `getHandleConnections`,
  `getConnectedNodeIds`, `getEdge`/`removeEdge(s)`, `setViewport`,
  `deleteElements`, `updateNodeInternals`.
- Dataflow (computing-flows parity): `FlowNodeConnection` + `NodeDataSlice`,
  `watchNodeConnections` (`useNodeConnections`), `watchNodesData` /
  `watchNodesDataMany` (`useNodesData`), `watchHandleConnections` alias,
  `nodeConnectionsOf` / `incomersOf` / `outgoersOf` pure helpers,
  `controller.edges.getNodeConnections` / `getIncomers` / `getOutgoers`,
  `setEdgeData` / `patchEdgeData`, `nodes.updateNodeDataWith` (fn updater) /
  `patchNodeData` (Map merge, `replace` mirrors RF's `{ replace: true }`),
  `FlowDataHandle` per-handle binding widget (guide's `CustomHandle`),
  `flowLuminance` / `isLightColor` (guide formula, `>= 128` is light).
- Multiplayer primitives: `FlowViewportPortal` (ViewportPortal counterpart —
  canvas-anchored presence content), `toSyncJson` (sync payload without
  per-client selection), `applyRemote` (remote graph in, local selection /
  viewport / undo history preserved, history rebased so undo never loses
  peer work, no change-callback echo).
- Programmatic edge picking: `controller.edges.hitTestEdgeAt` (flow-space
  point → topmost edge id, same samples + tolerance as tap selection) for
  erasers, lasso-of-edges, and edge context menus.
- Focus fixes: the focus ring no longer remounts node content (stable
  `GlobalKey` reparenting — in-node fields keep focus + text, scroll/anim
  state survives), and `autoPanOnNodeFocus` pans only when the node is
  actually offscreen (tapping a visible node/field no longer jumps the
  camera).
- `centerOnPosition` accepts an optional zoom (`setCenter` parity, instant).
- Breaking (pre-1.0 cleanup): keyboard shortcuts ship enabled by default
  (`KeyboardOptions()` == `withDefaults()`); `FlowCanvasOptions()` and
  `FlowCanvasConfig()` are no longer const-constructible. Pass
  `KeyboardOptions.disabled()` for no keyboard input.
- Keyboard dispatch unification: one Shortcuts pipeline (custom bindings win
  on conflict), `disabled()` truly disables everything, text-input guard
  (every canvas action reports disabled while a field holds focus, checked
  synchronously at invoke time — editing keys always reach the field),
  single-undo Delete, edge-only Delete support, `selectAll(nodes:, edges:)`
  flags, Shift+Arrow bindings.

## 0.1.0

- Initial public release of `lattice`.
- `FlowCanvas` widget with pan / zoom viewport, node and edge layers.
- Node model with grouping (`parentId`), subflow drag sets, expand-parent, extents.
- Edge model with bezier / straight / step / smooth-step paths, labels, markers, animation.
- Connection interaction: drag-connect, click-connect, strict / loose modes, reconnect, validation.
- Selection: click, multi-select, marquee (`partial` / `full`).
- Viewport helpers: `fitView`, culling for large graphs, snap-to-grid.
- Overlays: background, minimap, panel, controls, edge labels, node resizer.
- Theming via `FlowCanvasTheme` + per-component `Flow*Style`.
- Persistence: bare-state `toJson` / `load`, or versioned `saveDocument` / `loadDocument` (`CanvasDocument` envelope with schema migration). Undo / redo history, clipboard copy / paste.
