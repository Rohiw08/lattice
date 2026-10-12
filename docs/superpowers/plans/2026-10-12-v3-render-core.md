# Plan V3-3: Render core (camera, spatial, cull, layers, input, drag)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Interactive canvas: pan/zoom with zero rebuilds, virtualized node layer, single-painter edge layer, one gesture router, node drag with live positions. The perf heart of the rewrite.

**Architecture:** Layers ride inside the camera `Transform`. `LatticeCullController` (a `Notifier<Set<String>>` in the canvas container) resolves visible ids on scroll-settle/100ms-throttle/structural-change and swaps child lists once. Edge paths cached per edge id, invalidated by endpoint dirty sets. Node drag writes `latticeDragProvider` live positions; node shells position from session, bodies from document.

**Tech Stack:** Flutter (`Transform`, `CustomPaint`, `Listener`), flutter_riverpod, widget tests with fake gestures.

**Spec:** `docs/superpowers/specs/2026-10-12-lattice-rewrite-design.md` (§3.2, §3.3)

## Global Constraints
- SDK `^3.10.0`, Flutter `>=3.35.0`; deps flutter + flutter_riverpod only; no codegen.
- TDD + commit per task. `lib/src/v3/` only; no `lib/lattice.dart` change.

## Review Focus
- 2500 nodes, camera pans continuously → node-layer build count stays flat (no per-frame rebuild). Pinned in Task 3.
- Node dragged outside viewport then released → still receives pointer-up (no stuck drag). Pinned in Task 5.
- Edge whose both endpoints off-screen → skipped from paint entirely. Pinned in Task 4.
- Rapid add+remove of same id between cull passes → no stale shell, no crash. Pinned in Task 3.
- Tap on empty pane with selection → clears selection, single emission. Pinned in Task 5.

---

### Task 1: Camera (matrix owns the truth)

**Files:**
- Create: `lib/src/v3/lattice_camera.dart`
- Test: `test/v3/lattice_camera_test.dart`

**Interfaces:**
- Consumes: V3-1 viewport value, V3-2 container.
- Produces:
  - `class LatticeCameraController extends Notifier<Matrix4> { void setViewport(LatticeViewportValue v); void panBy(Offset delta); void zoomBy(double factor, {Offset? focal}); LatticeViewportValue get viewport; Stream<void> get settled; }` — `settled` fires after 100ms without matrix change (cull trigger). Matrix writes never touch the document.
  - `latticeCameraProvider: NotifierProvider<LatticeCameraController, Matrix4>`.

- [ ] **Step 1: Write failing tests**: `setViewport` produces matrix mapping flow→screen; `panBy` translates; `viewport` round-trips offset/zoom; `settled` fires after quiescence (fake async).
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 2: Spatial index + edge path cache

**Files:**
- Create: `lib/src/v3/lattice_spatial_index.dart`, `lib/src/v3/edge_paths.dart`, `lib/src/v3/edge_path_cache.dart`
- Test: `test/v3/spatial_and_paths_test.dart`

**Interfaces:**
- Consumes: V3-1 models/layout.
- Produces:
  - `class LatticeSpatialIndex { void rebuild(Map<String,LatticeNode> nodes); void moveNode(LatticeNode before, LatticeNode after); void removeNodes(Set<String> ids); Set<String> queryNodes(Rect flowRect); }` — grid-based; adapt (do not import) the algorithm from old `spatial/` code.
  - `Path latticeEdgePath({required Rect sourceRect, required Offset sourceAnchor, required Rect targetRect, required Offset targetAnchor, String type = 'bezier'})` in `edge_paths.dart` — port bezier + straight from old `edge_path_creator.dart` (copy algorithm, new file, no old imports).
  - `class EdgePathCache { Path? pathFor(String edgeId); Rect? boundsFor(String edgeId); void invalidateEdges(Set<String> ids); void syncTo(LatticeDocument doc, {required Offset defaultOrigin}); }` — `syncTo` recomputes only invalidated ids whose endpoints exist; drops paths for removed edges.

- [ ] **Step 1: Write failing tests**: index query returns overlapping ids only; move updates query; path for bezier starts/ends at anchors; `syncTo` after moving one node recomputes only connected edges (count via instrumented subclass or recompute counter); removed edge drops path.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement** three files.
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 3: Cull controller + node layer

**Files:**
- Create: `lib/src/v3/lattice_cull.dart`, `lib/src/v3/node_layer.dart`
- Test: `test/v3/node_layer_test.dart`

**Interfaces:**
- Consumes: Tasks 1–2, V3-2 canvas placeholder (replace it).
- Produces:
  - `class LatticeCullController extends Notifier<Set<String>> { void refresh({bool force = false}); }` + `latticeCullProvider`. Refresh computes visible ids = index query of visible flow rect (from camera matrix + pane size) ∪ selected ids ∪ drag ids; engages on frame 1 using `LayoutBuilder` size passed via `LatticeCanvas` (add internal `latticePaneSizeProvider: StateProvider<Size?>` set by the canvas).
  - `class LatticeNodeLayer extends ConsumerWidget` — `Stack` of `_LatticeNodeShell` keyed `ValueKey(id)` for culled ids; shells cached in a `StatefulWidget` map across builds (stable instances); shell positions from drag session live positions else document; body built by `nodeBuilders` map (`Map<String, LatticeNodeBuilder>` where `typedef LatticeNodeBuilder = Widget Function(BuildContext, LatticeNode, bool selected)`), default builder = plain bordered box. Off-screen nodes painted by `LatticeLodPainter` rects (same painter reused by minimap in V3-6).

- [ ] **Step 1: Write failing tests**: 500 nodes, pane shows only visible subset (`find.byKey` counts); selection of off-screen node keeps it mounted; removing a node between frames leaves no stale shell; first frame already culled (no full mount).
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement**; wire layer into `LatticeCanvas` replacing placeholder (modify `lattice_canvas.dart`, add `nodeBuilders` param defaulting to `{}`).
- [ ] **Step 4: Add pan-flat test**: pump 2500 seeded nodes, dispatch 20 synthetic pan frames on camera, assert node-layer build count unchanged (instrument via debug counter in test file, not library).
- [ ] **Step 5: Run full suite.** `flutter test test` — Expected: ALL PASS.
- [ ] **Step 6: Commit.**

### Task 4: Edge layer (single painter)

**Files:**
- Create: `lib/src/v3/edge_layer.dart`
- Test: `test/v3/edge_layer_test.dart`

**Interfaces:**
- Consumes: Task 2 cache, V3-2 providers.
- Produces:
  - `class LatticeEdgeLayer extends ConsumerWidget` — one `CustomPaint(painter: LatticeEdgePainter(...))` for static edges + one for animated/active (repaint split); watches `latticeEdgePaintVersionProvider: StateProvider<int>` (bumped by cache sync, not by viewport); skips edges whose cached bounds miss the visible rect or whose endpoints are missing; selected edges painted with selection style param.

- [ ] **Step 1: Write failing tests**: painter receives only visible edges (record painted ids via test painter subclass hook — expose `paintedIdsForTest` on painter); moving an unrelated node does not bump paint version; edge with missing endpoint paints nothing and throws nothing.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement**; wire into `LatticeCanvas` under node layer.
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 5: Gesture router + node drag + tap select

**Files:**
- Create: `lib/src/v3/gesture_router.dart`
- Modify: `lib/src/v3/lattice_controller.dart` (add verbs), `lib/src/v3/lattice_canvas.dart` (mount router)
- Test: `test/v3/gesture_router_test.dart`

**Interfaces:**
- Consumes: Tasks 1–4.
- Produces controller verbs: `tapAt(Offset screenPosition)`, `beginNodeDrag(String id)`, `updateNodeDrag(Offset screenDelta)`, `endNodeDrag()`, `beginMarquee(Offset p)`, `updateMarquee(Offset p)`, `endMarquee({bool append = false})`. Router (`LatticeGestureRouter` widget using `Listener` + pan/zoom from a still-SDK `InteractiveViewer`? NO — camera is custom: router handles 1-finger drag dispatch + 2-finger pinch via scale events, space/middle-drag pan). Hit-test via `LatticeSpatialIndex` + `latticeAbsoluteRect`; drag writes live positions into `latticeDragProvider`; release commits single document with moved nodes. Tap on empty pane clears selection (one emission).

- [ ] **Step 1: Write failing tests**: tap node selects (selection provider has id); tap pane clears; drag node 100px moves live position during gesture and commits document on release with exactly one controller notification; pointer-up outside pane ends drag (no stuck `isActive`).
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement** router + controller verbs; mount router in canvas.
- [ ] **Step 4: Run full suite.** `flutter test test` — Expected: ALL PASS.
- [ ] **Step 5: Commit.**
