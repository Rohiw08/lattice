# Lattice Rewrite — Design Spec (2026-10-12)

## Status
Approved design (approach A). Next: implementation plan via writing-plans.

## 1. Intent
Rewrite `packages/lattice` internals as a Google-quality Flutter library:
any Flutter developer can use it with only Flutter SDK + Riverpod knowledge.
Keep React Flow behavior parity; break internal architecture and public
names freely (clean break; demos migrated by us).

Agreed constraints:
- Riverpod stays, and selectors are **public** (users import `flutter_riverpod`).
- Runtime deps = Flutter SDK + `flutter_riverpod` only. Remove
  `freezed_annotation`, `equatable`, `uuid`, `vector_math` from `dependencies`.
- No codegen for contributors or users (no freezed/json_serializable at runtime).
- All current features ported (nothing dropped).
- Success bar: 469 tests ported and green **plus** fair-sweep beats VNF on
  mount/remount/relocate at 100/500/1000/2500 x chain/dense, drag stays won.

## 2. Non-goals
- Custom RenderObject layout engine (widgets remain the node host; virtualization
  caps mounted-widget count, which is what determines mount cost).
- Outer-repo demo redesign (demos migrate to the new API, no new demos).
- Multiplayer transport (document is sync-friendly; transport stays out).

## 3. Architecture

```
LatticeCanvas (public widget)
├── ProviderScope (per-canvas container; multiple canvases coexist)
├── LatticeController (public, user-owned; commands + Listenable)
├── LatticeDocument (immutable {nodes, edges, viewport}; undoable/serializable)
├── Session notifiers (internal; drag/hover/marquee/connection/live camera)
├── LatticeViewport (Transform-based pan/zoom; camera moves rebuild nothing)
├── NodeLayer (visible-id widgets only + LOD rect painter for the rest)
├── EdgeLayer (single static CustomPaint + animated/active painter)
├── GestureRouter (one canvas-level router; spatial-index hit-test)
└── Features (history/clipboard/selection/connections/labels/minimap/
    resizer/toolbar/panels/background/keyboard/a11y/dataflow)
```

### 3.1 State split
- `LatticeDocument`: immutable value `{nodes: Map<String,LatticeNode>,
  edges: Map<String,LatticeEdge>, viewport: LatticeViewportValue}`.
  Only undoable/serializable/syncable thing. Commits are O(delta).
- Session: Riverpod `Notifier`s for drag positions, hover, marquee rect,
  active connection, live camera. Never serialized, never in history,
  never notifies document listeners.
- Deleted concepts: selection/zOrder/runtime/edgeLiveStamp epochs,
  `geometryRevision`, `identical()`-map fast paths. Selectors subscribe to
  structural slices (`select`), so ephemeral ticks touch session listeners only.

### 3.2 Rendering
- Camera = `Transform` matrix. Node/edge layers ride inside it: pan/zoom
  rebuilds nothing. Culling re-resolves on scroll-settle / 100ms throttle /
  structural change and swaps child lists once.
- Node layer mounts visible ids only; cull engages on frame 1 via
  `LayoutBuilder` size (no post-frame seeding gap). Stable keyed widget
  instances across rebuilds (no N-element cascade on selection toggles).
- Off-screen nodes paint as rects in one `CustomPaint`; the same painter
  serves minimap + zoom-out LOD.
- Edge layer: one static `CustomPaint` + one animated/active painter.
  Per-edge path cache keyed by edge id, invalidated by endpoint dirty-set
  from node commits only. No global O(N+E) scans on any write path.
- Spatial index: synchronous O(delta) updates on commit (add/remove/move);
  serves cull queries + hit-testing. No O(N) fallback loops in hot paths.

### 3.3 Input
- Single canvas-level gesture router. Pointer down -> spatial-index hit-test
  -> dispatch to select / node-drag / connect-start / marquee / pane.
  Arena cost O(1) per pointer regardless of node count.
- `dragHandle` / `nodrag` become hit-test tags on node chrome, not widget trees.
- Node drag writes session live positions per frame (keeps current drag win);
  single document commit on release (one history entry).

### 3.4 Models (no codegen)
- `LatticeNode`, `LatticeEdge`: hand-written immutable classes, const
  constructors, `copyWith`, `==`/`hashCode`. No freezed, no equatable.
- `data`: `Object?` with user-supplied `encodeData`/`decodeData` codecs per
  node type (same pattern as today, plain typedefs, no generics-with-codegen).
- Nullable per-node flags (`draggable?`, `selectable?`, ...) resolve against
  `LatticeOptions` via a pure function; resolution cached at commit, never
  allocated per build.
- IDs: internal counter + `dart:math` randomness (no uuid).
- Geometry math on `dart:ui` types only (no vector_math).

## 4. Public API (~15 symbols, `lib/lattice.dart` only)

```dart
// Widgets
LatticeCanvas(controller:, nodes:, edges:, nodeBuilders:, edgeBuilders:,
  options:, theme:, callbacks:, overlays:)
// Controller (user-owned, single class — no facade/internal duality)
LatticeController
  // graph: addNode/removeNodes/moveNodes/addEdge/removeEdges/...
  // selection: select/deselect/selectAll/deleteSelection
  // viewport: fitView/zoomTo/centerOn/moveBy
  // history: undo/redo/canUndo/canRedo
  // persistence: toJson/fromJson/load
  // observation: ChangeNotifier (fires on document commits; session ticks
  // available via selectors inside the canvas subtree, not via the controller)
// Models
LatticeNode(id, type, position, size, data, ...)
LatticeEdge(id, source, target, type, ...)
LatticeViewportValue, LatticeOptions, LatticeTheme, LatticeCallbacks
// Riverpod selectors (users import flutter_riverpod)
latticeNodesProvider, latticeEdgesProvider, latticeViewportProvider,
latticeSelectionProvider, latticeNodeProvider(id), latticeEdgeProvider(id)
```

- `src/` is never exported. Old `Flow*` names removed; CHANGELOG carries
  a migration table (`FlowCanvas` -> `LatticeCanvas`, etc.).
- One options object, one theme object, one callbacks object. No nested
  options-cascade maze, no `updateOverrides` remount hazards.

## 5. Feature porting order (each with its tests)
1. Core: document/session/render/input/spatial/edge-geometry.
2. Selection, viewport ops, history, clipboard.
3. Connections, handles, edge labels (labels virtualized like nodes).
4. Minimap, resizer, toolbar, panels, background.
5. Keyboard, a11y (nodes stay widgets, so semantics/focus come free), dataflow.

## 6. Verification
- `flutter test test` (ported 469) green after every change.
- Fair-sweep (`benchmark/sweep_*` + workspace driver) run per milestone;
  gates: mount/remount/relocate < VNF at all 8 cells, drag still won.
- Budgets recorded in `PERFORMANCE.md`; a missed gate = redesign, not waiver.
- Public API freeze: `lib/lattice.dart` export list changes only via separate
  proposal after v1.

## 7. Risks
- Virtualized node widgets + stable instances: focus traversal and
  `dragHandle` hit-testing need dedicated tests (cull_focus tests ported first).
- Single gesture router must reproduce all current pointer behaviors
  (pan-vs-drag arbitration, tap-select, marquee, connect click/drag);
  port input tests before deleting per-node recognizers.
- Beat-VNF bar depends on software-WebGL CI numbers staying ratio-fair;
  same-driver/same-machine policy from fair-sweep is mandatory.
