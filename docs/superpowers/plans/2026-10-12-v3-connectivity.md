# Plan V3-5: Connectivity (connections, handles, edge labels)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Drag-to-connect between handles with validation, handle widgets, virtualized edge labels, edge reconnect.

**Architecture:** Pending connection lives in session (`LatticeDragState.connect` variant added here). Validation is a pure function of (source endpoint, target endpoint, document). Labels mount as widgets only for visible edges (same cull set as edges). Reconnect drags an existing edge endpoint onto a new handle.

**Tech Stack:** Flutter, flutter_riverpod, widget tests.

**Spec:** `docs/superpowers/specs/2026-10-12-lattice-rewrite-design.md` (§5 item 3)

## Global Constraints
- SDK `^3.10.0`, Flutter `>=3.35.0`; deps flutter + flutter_riverpod only; no codegen.
- TDD + commit per task. `lib/src/v3/` only; no `lib/lattice.dart` change.

## Review Focus
- Connect node to itself when self-connections disallowed → rejected with callback, no edge. Pinned in Task 1.
- Drag connection over 2500-node canvas → no per-frame document emissions (session only). Pinned in Task 2.
- Label of off-screen edge → unmounted; scroll back → remounts with same state. Pinned in Task 3.
- Reconnect drop on empty pane → edge unchanged, no history entry. Pinned in Task 4.
- Duplicate connection (same endpoints) → rejected by default validator. Pinned in Task 1.

---

### Task 1: Connection validation (pure) + session state

**Files:**
- Create: `lib/src/v3/lattice_connection.dart`
- Test: `test/v3/lattice_connection_test.dart`

**Interfaces:**
- Consumes: V3-1 models.
- Produces:
  - `bool latticeValidateConnection({required LatticeEndpoint source, required LatticeEndpoint target, required LatticeDocument doc, bool allowSelfConnections = false, bool allowDuplicates = false})` — checks: endpoints exist, source is source-type handle, target is target-type handle, not same handle, self/duplicate rules.
  - Extend `LatticeDragState` with `const LatticeDragState.connect({required LatticeEndpoint from, required Offset liveEnd})`.

- [ ] **Step 1: Write failing tests**: valid source→target passes; target→source direction rejected; self-connection rejected by default, allowed with flag; duplicate rejected by default; missing node rejected.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 2: Connect gesture + controller verbs + handle widgets

**Files:**
- Create: `lib/src/v3/handle_widget.dart`
- Modify: `lib/src/v3/lattice_controller.dart` (`beginConnect(LatticeEndpoint from)`, `updateConnect(Offset screenEnd)`, `endConnect(LatticeEndpoint? target)`), `lib/src/v3/gesture_router.dart` (handle hit-test → connect flow)
- Test: `test/v3/connect_flow_test.dart`

**Interfaces:**
- Produces: `class LatticeHandleWidget extends ConsumerWidget { const LatticeHandleWidget({required String nodeId, required LatticeHandle handle}); }` — 20px min hit area, reports hover via `latticeHoverProvider`? (no — hover is node-level; handle hover stays local `StatefulWidget` state). Router: press on handle starts connect session; move updates `liveEnd` (session only — assert zero document emissions during 20 synthetic moves); release on valid handle commits one edge + one history entry; release on empty pane cancels silently.

- [ ] **Step 1: Write failing tests**: full press-drag-release creates edge with correct endpoints; invalid drop creates nothing + no history entry; 20 move events emit zero document notifications (listener count).
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement** widget + verbs + router branch.
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 3: Virtualized edge labels

**Files:**
- Create: `lib/src/v3/edge_label_layer.dart`
- Test: `test/v3/edge_label_layer_test.dart`

**Interfaces:**
- Produces: `class LatticeEdgeLabelLayer extends ConsumerWidget { const LatticeEdgeLabelLayer({required Map<String, LatticeEdgeLabelBuilder> labelBuilders}); }` with `typedef LatticeEdgeLabelBuilder = Widget Function(BuildContext, LatticeEdge)` — mounts labels only for edges in the visible set (reuse cull rect via `EdgePathCache.boundsFor`); label positioned at path midpoint (query cache); edges without builders render nothing.

- [ ] **Step 1: Write failing tests**: labeled visible edge shows label; off-screen labeled edge mounts nothing; label follows after endpoint move (midpoint changes).
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement**; mount layer in canvas above edge layer.
- [ ] **Step 4: Run.** `flutter test test/v3` — Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 4: Edge reconnect

**Files:**
- Modify: `lib/src/v3/lattice_controller.dart` (`beginReconnect(String edgeId, {required bool sourceEnd})`, `updateReconnect(Offset)`, `endReconnect(LatticeEndpoint? target)`), `lib/src/v3/gesture_router.dart`
- Test: `test/v3/edge_reconnect_test.dart`

**Interfaces:** Dragging an edge endpoint: session holds `{edgeId, sourceEnd, liveEnd}` (reuse `LatticeDragState.connect` with nullable `reconnectEdgeId` field — add it); valid drop rewrites endpoint (one history entry); drop on pane cancels with no history; validation reuses `latticeValidateConnection` against the non-moving end.

- [ ] **Step 1: Write failing tests**: reconnect target end to new handle → edge updated, one undo restores; cancel drop → unchanged + history length same; reconnect to same handle → no-op, no history entry.
- [ ] **Step 2: Run to verify fail.** Expected: FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run full suite.** `flutter test test` — Expected: ALL PASS.
- [ ] **Step 5: Commit.**
