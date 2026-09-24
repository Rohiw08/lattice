# Architecture

How `lattice` is organized, and the rules that keep it consistent.
Performance invariants live in [PERFORMANCE.md](PERFORMANCE.md);
this file covers structure, state, and conventions.

## 1. Layers

`lib/src/features/<name>/{domain,application,presentation}/`, shared
kernel in `lib/src/core/`. Dependency direction:

```
presentation -> application -> domain -> core/{enums,types,utils,options}
```

Rules:

- **Domain is pure data + pure functions.** `Offset`/`Size`/`Rect`/`Matrix4`
  (Flutter value types) are allowed; `Widget`, `BuildContext`, and
  provider/controller references are not. Registries are the one
  sanctioned seam: they map ids to builders, so
  `node_registry.dart`/`edge_registry.dart` may reference `Widget`
  typedefs — but built-in node *implementations* live in
  `presentation/` and are registered from the application side, never
  imported by domain.
- **Application holds behavior.** Controllers orchestrate
  (`*Controller`), services compute pure state transitions
  (`*Service`). Cross-feature calls go through the owning controller
  (e.g. `internal.edges.commitConnectionEdge`), never by importing a
  sibling's service directly into presentation. `EdgeService.upsertEdge`
  is the single force-insert for pre-validated connection flows
  (`addEdge` guards; `upsertEdge` assumes the caller validated).
- **Presentation reads and calls, never writes state directly.**
  Widgets call controller methods (`controller.edges.clearEdgeHover`,
  not `updateStateOnly(state.copyWith(...))` inline).
- **`core/` is the shared kernel, not infrastructure.** `core/providers`
  composes feature services (DI root); `core/state` owns the Freezed
  state; `core/{options,theme,enums}` are consumed everywhere.
  `core` may import feature *domain models*; features never import
  from `core/providers`.
- **One public entry point.** `lib/lattice.dart` is the only barrel.
  No per-feature barrels. `src/` internals (`*Service`,
  `*Controller`, providers, `InteractionSession`) are deliberately
  unexported; tests may import `src/` for white-box coverage but
  benchmarks stay black-box (`bench_helpers.dart` imports the barrel
  only). Never import the barrel from inside `lib/src/`
  (`flow_canvas_state.dart` uses direct imports — barrel cycles are
  fragile even when they compile).

## 2. State: one committed tree, two hot buffers

- **Committed state** is a single Freezed `FlowCanvasState` behind
  `flowControllerProvider` (`NotifierProvider`). Freezed `copyWith`
  reuses unchanged map references — selectors rely on this.
- **Write paths:** `mutate` (records undo) vs `updateStateOnly`
  (transient: hover, selection, marquee, camera). Rule: anything the
  user would expect Ctrl+Z to undo goes through `mutate`; clearing a
  marquee rect or hover highlight must never create a history entry.
  `load`/`applyRemote` assign directly and manage history explicitly.
- **Hot buffers (by design, not violations):** `InteractionSession`
  (drag positions/sizes), `TransformationController` + `LiveViewport`
  (matrix-first pan/zoom), `VisibleCullCache`, `SpatialIndexService`.
  These are mutable on purpose (per-frame writes can't go through
  Freezed) and commit on gesture end. Presentation may read them via
  `ListenableBuilder`, but writes go through controller methods.
- **Second DI graph (by design):** theme/options travel via
  `InheritedWidget` (`context.flowCanvasTheme`,
  `context.flowCanvasOptions`); services travel via Riverpod.
  Don't mix them: no `ref.watch` for theme, no InheritedWidget for
  state.

## 3. Selectors (extends PERFORMANCE.md invariant #1)

- Select the **stored object itself** (`s.edges`, `s.selectedNodes`),
  never a derived collection (`.values`, fresh `List`, sorted copies).
  Derive *after* the watch, in the function/widget body.
- If a derived shape is needed in `select`, it must be a value type
  (`NodeDataSlice`) or a deep-eq wrapper (`NodeKeys`), never a bare
  `List`/`Map`/`Set` in a record.
- `flowStateProvider` is an escape hatch for slices no focused
  provider covers — always with `.select`, never a bare watch.

## 4. Naming

- Controllers are plural (`NodesController`, `EdgesController`),
  services singular (`NodeService`, `EdgeService`).
- One service per feature named `<feature>_service.dart`
  (`keyboard_service.dart`, not `*_action_service.dart`).
- Scoped helpers that are neither layer get neutral names
  (`ViewportAnimator`, `EdgeGeometryController`); don't proliferate
  the pattern.
- RF-parity names win for public API (`getNodesBounds`,
  `watchNodeConnections`, `fitView`).

## 5. Models & codegen

- Domain entities are `@freezed` (`FlowNode`, `FlowEdge`,
  `FlowHandle`, `FlowViewport`, `FlowConnection`); value/style/painter
  state is `Equatable`. Both coexist deliberately — don't "unify".
- `FlowCanvasState` uses manual `toJson`/`fromJson` (version-tolerant
  sync payloads); entity models use generated `.g.dart`.
- Serialization rule: runtime-only fields (`nodeStates`, selection,
  drag mode, hover) are `@JsonKey(includeFromJson: false,
  includeToJson: false)`. Sync payloads additionally strip selection
  (`toSyncJson`); collaborators never share selection.

## 6. Imports & files

- `package:lattice/...` everywhere in `lib/` — no relative imports.
- Feature dirs stay flat unless they earn the split: only
  `a11y, connections, dataflow, edges, handles, nodes, viewport`
  carry all three layers. Don't create empty `domain/application/
  presentation` shells for new features.
- Benchmarks share `benchmark/bench_helpers.dart` (fixture grid,
  `benchStats`, `benchSettle`, `benchNodeCenter`); benchmark-specific
  rigs (registries, options, keys) stay local to each bench file.
