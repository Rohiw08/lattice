# Plan V3-1: Foundation (models, document, codecs)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pure-Dart immutable core (node, edge, handle, viewport value, document, codecs, layout helpers) with unit tests, and dependency closure cut to Flutter SDK + Riverpod.

**Architecture:** Hand-written value classes, no codegen. `LatticeDocument` holds `{nodes, edges, viewport}` only — selection lives in session (Plan V3-2). All `copyWith` paths reuse map instances when unchanged (perf invariant for later selector O(1) checks).

**Tech Stack:** Flutter SDK, `flutter test`, no codegen.

**Spec:** `docs/superpowers/specs/2026-10-12-lattice-rewrite-design.md` (§3.4, §4)

## Global Constraints
- SDK `^3.10.0`, Flutter `>=3.35.0`.
- Runtime `dependencies`: `flutter` SDK + `flutter_riverpod` only (remove `freezed_annotation`, `equatable`, `uuid`, `vector_math`).
- No codegen for contributors or users.
- TDD: failing test first, every task ends green + committed.
- New code lives in `lib/src/v3/`; tests import `package:lattice/src/v3/...`. No change to `lib/lattice.dart` until Plan V3-7.

## Review Focus
- Duplicate node ids in `fromJson` input → last wins, no throw (users hand-edit JSON). Pinned in Task 3.
- `NaN`/`Infinity` doubles in JSON numbers → normalized to `0.0` on decode. Pinned in Task 3.
- Non-JSON-safe `data` with null codecs → passes through by reference, never throws. Pinned in Task 2.
- 2500-node `copyWith` with no changes → identical map instances reused (selector fast path). Pinned in Task 3.
- Parent cycle (`a.parentId == b`, `b.parentId == a`) in layout helper → terminates via visited set. Pinned in Task 4.

---

### Task 1: Dependency closure + package skeleton

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/src/v3/v3.dart` (barrel for internal use only, not exported publicly)

**Interfaces:**
- Consumes: nothing.
- Produces: dependency baseline later tasks rely on.

- [ ] **Step 1: Remove extra runtime deps.** In `pubspec.yaml` delete `freezed_annotation`, `equatable`, `uuid`, `vector_math` from `dependencies`. Keep `flutter`, `flutter_riverpod`, `riverpod`.
- [ ] **Step 2: Verify build.** Run `flutter pub get` then `flutter test test` from `packages/lattice`. Expected: dependency resolution succeeds; suite state unchanged from baseline (old code must not import removed packages in `lib/` — if it does, STOP and report; do not fix old code in this plan).
- [ ] **Step 3: Create barrel.** Create `lib/src/v3/v3.dart` exporting the files from Tasks 2–4 as they land (start empty with a comment).
- [ ] **Step 4: Commit.** `git add pubspec.yaml lib/src/v3/v3.dart; git commit -m "chore(v3): cut runtime deps to flutter+riverpod, add v3 skeleton"`.

### Task 2: Handle, node, edge models + codecs

**Files:**
- Create: `lib/src/v3/lattice_handle.dart`, `lib/src/v3/lattice_node.dart`, `lib/src/v3/lattice_edge.dart`, `lib/src/v3/lattice_codecs.dart`
- Test: `test/v3/lattice_models_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces (exact signatures later tasks use):
  - `enum LatticeHandleType { source, target }`
  - `class LatticeHandle { const LatticeHandle({required String id, required LatticeHandleType type, required Offset position, Size size = const Size(6,6)}); copyWith; ==/hashCode; Map<String,Object?> toJson(); factory LatticeHandle.fromJson(Map<String,Object?> json); }`
  - `class LatticeEndpoint { const LatticeEndpoint({required String nodeId, String? handleId}); ==/hashCode; toJson/fromJson; }`
  - `class LatticeNode { const LatticeNode({required String id, required String type, required Offset position, Offset? origin, Size size = const Size(160,44), Object? data, String? parentId, int zIndex = 0, Map<String,LatticeHandle> handles = const {}, bool? hidden, draggable, selectable, hoverable, connectable, deletable, resizable, focusable, Size? minSize, maxSize, bool keepAspectRatio = false, expandParent = false, dragHandle = false, String? semanticsLabel, Rect? extent}); copyWith; ==/hashCode; Map<String,Object?> toJson([EncodeNodeData? encode]); factory LatticeNode.fromJson(Map<String,Object?> json, [DecodeNodeData? decode]); Map<String,LatticeHandle> resolveHandles(); }` — `resolveHandles()` returns explicit handles, else synthesized defaults for types `default`/`input`/`output`, else `{}`.
  - `class LatticeEdge { const LatticeEdge({required String id, required LatticeEndpoint source, required LatticeEndpoint target, String type = 'default', Object? data, String? label, bool animated = false, hidden/selectable/deletable (bool?), int zIndex = 0}); copyWith; ==/hashCode; toJson/fromJson; }`
  - `typedef EncodeNodeData = Object? Function(String type, Object? data); typedef DecodeNodeData = Object? Function(String type, Object? json);`

- [ ] **Step 1: Write failing tests** in `test/v3/lattice_models_test.dart`: const construction + `==`; `copyWith` changes one field; `resolveHandles()` for `default` yields `source`+`target`; round-trip `toJson`/`fromJson` with data passthrough when codecs null; custom codecs called with `(type, data)`.
- [ ] **Step 2: Run to verify fail.** Run `flutter test test/v3/lattice_models_test.dart`. Expected: FAIL (files missing).
- [ ] **Step 3: Implement** the four files with exact signatures above.
- [ ] **Step 4: Add passthrough test.** Non-JSON-safe `data` object with null codecs round-trips by reference without throwing.
- [ ] **Step 5: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 6: Commit.**

### Task 3: Viewport value + document

**Files:**
- Create: `lib/src/v3/lattice_viewport_value.dart`, `lib/src/v3/lattice_document.dart`
- Test: `test/v3/lattice_document_test.dart`

**Interfaces:**
- Consumes: Task 2 types.
- Produces:
  - `class LatticeViewportValue { const LatticeViewportValue({Offset offset = Offset.zero, double zoom = 1.0}); copyWith; ==/hashCode; toJson/fromJson; Matrix4 toMatrix(); factory LatticeViewportValue.fromMatrix(Matrix4 m); }`
  - `class LatticeDocument { const LatticeDocument({Map<String,LatticeNode> nodes = const {}, Map<String,LatticeEdge> edges = const {}, LatticeViewportValue viewport = const LatticeViewportValue()}); copyWith (reuses identical map instances when args null); withNode(LatticeNode n); withoutNodes(Set<String> ids); withEdge(LatticeEdge e); withoutEdges(Set<String> ids); withViewport(LatticeViewportValue v); Map<String,Object?> toJson([EncodeNodeData? encode]); factory LatticeDocument.fromJson(Map<String,Object?> json, [DecodeNodeData? decode]); static LatticeDocument empty(); }` — no selection anywhere in this class.

- [ ] **Step 1: Write failing tests**: empty defaults; `withNode`/`withoutNodes` add/remove; `copyWith()` with no args reuses `identical()` map instances; `toJson`/`fromJson` round-trip incl. viewport; `fromJson` with duplicate node ids keeps last; `NaN`/`Infinity` doubles decode to `0.0`.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement** both files.
- [ ] **Step 4: Add 2500-node identity test**: build doc with 2500 nodes, call `copyWith()` argless, assert `identical(doc.nodes, copy.nodes)`.
- [ ] **Step 5: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 6: Commit.**

### Task 4: Layout helpers (parent chains, origins)

**Files:**
- Create: `lib/src/v3/lattice_layout.dart`
- Test: `test/v3/lattice_layout_test.dart`

**Interfaces:**
- Consumes: Task 2–3 types.
- Produces:
  - `Offset latticeAnchorTopLeft(LatticeNode node, Offset defaultOrigin)` — stored anchor minus origin shift.
  - `Offset latticeAbsoluteTopLeft(Map<String,LatticeNode> nodes, String id, {required Offset defaultOrigin})` — walks parent chain.
  - `Rect latticeAbsoluteRect(Map<String,LatticeNode> nodes, String id, {required Offset defaultOrigin})`
  - `bool latticeOverlapsRect(Map<String,LatticeNode> nodes, LatticeNode node, Rect rect, {required Offset defaultOrigin})`

- [ ] **Step 1: Write failing tests**: top-left origin passthrough; center origin shifts by half size; nested child resolves through parent; per-node origin override wins; parent cycle terminates (visited set) and returns best-effort value.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement** with cycle guard.
- [ ] **Step 4: Run full v3 + old suite.** `flutter test test` — Expected: ALL PASS (no regressions).
- [ ] **Step 5: Commit.**
