# Theming

## Recommended path

```dart
MaterialApp(
  theme: FlowCanvasTheme.light().toThemeData(),
  darkTheme: FlowCanvasTheme.dark().toThemeData(brightness: Brightness.dark),
  themeMode: ThemeMode.system, // ≈ Lattice colorMode: 'system'
);
```

Or:

```dart
final pair = FlowCanvasTheme.materialPair();
MaterialApp(theme: pair.light, darkTheme: pair.dark, themeMode: ThemeMode.system);
```

Customize with `copyWith` / `merge`:

```dart
final theme = FlowCanvasTheme.light().copyWith(
  edge: FlowEdgeStyle.light().copyWith(
    decoration: const FlowEdgeStrokeStyle(
      strokeWidth: 1,
      color: Color(0xFFEA580C),
    ),
  ),
  node: FlowNodeStyle.colored(
    color: Color(0xFFFFF7ED),
    borderColor: Color(0xFF1A192B),
  ),
);
```

Read inside the canvas with `FlowCanvasTheme.of(context)` (or `Theme.of(context).flowCanvasTheme`).

Material-driven apps can use:

```dart
FlowCanvasTheme.fromSeed(seedColor: Colors.teal);
FlowCanvasTheme.fromColorScheme(Theme.of(context).colorScheme);
```

## Naming

Component look-and-feel types are always `Flow*Style` — never `*Theme` for components:

| Style | Role |
|---|---|
| `FlowBackgroundStyle` | Canvas fill + pattern |
| `FlowNodeStyle` | Node container states |
| `FlowEdgeStyle` | Edge strokes |
| `FlowHandleStyle` | Port / handle states |
| `FlowConnectionStyle` | Drag connection line |
| `FlowSelectionStyle` | Marquee selection |
| `FlowControlsStyle` / `FlowControlsButtonStyle` | Control chrome |
| `FlowMinimapStyle` | Minimap |
| `FlowNodeResizerStyle` | Resize handles |
| `FlowPanelStyle` | Optional overlay panel chrome (default unstyled) |
| `FlowCursorStyle` | Pane / node / edge / handle / resizer cursors |
| `FlowEdgeReconnectStyle` | Edge updater endpoints (thin; no states) |
| `FlowEdgeLabelStyle` / `FlowEdgeMarkerStyle` | Edge chrome |

`FlowCanvasTheme` is the **bundle** (`ThemeExtension`) that holds those styles. Factories on each style: `.light()`, `.dark()`, `.system(context)`, `.fromColorScheme()`, `.fromSeed()`, `.fromTheme(ThemeData)` where applicable.

## Interaction state matrix

| Component | normal | hovered | selected | disabled | validTarget | invalidTarget |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| **Node** | ✓ | ✓ | ✓ | ✓ | — | — |
| **Edge** (+ label / marker) | ✓ | ✓ | ✓ | ✓ | — | — |
| **Handle** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Connection line** | — | — | — | — | ✓ | ✓ |
| **Controls button** | ✓ | ✓ | ✓ | ✓ | — | — |
| **Node resizer** | ✓ | ✓ | ✓ | ✓ | — | — |
| **Minimap node** | ✓ | — | ✓ | ✓ | — | — |
| **Panel** | ✓ | ✓ | ✓ | ✓ | — | — |
| **Edge reconnect / selection / background / minimap chrome** | ✓ only | — | — | — | — | — |

Panel theme default is [FlowPanelStyle.unstyled] (Lattice). Opt in with `FlowPanelStyle.light()` / `.dark()` / `.colored()`, or `theme.copyWith(panel: …)`, or per-panel `FlowPanel(style: …)`.

Light/dark presets paint **distinct** valid (green) and invalid (red) on handles and connection lines. Normal / hover / selected / active handles keep Lattice greys (`#1a192b` / `#bebebe`); connection active stays `#b1b1b7`.

## What “disabled” means

| Component | Disabled when |
|---|---|
| **Node** / minimap node | `selectable == false` |
| **Edge** | `selectable == false` |
| **Handle** | `connectable == false` |
| **Node resizer** | `resizable == false` |
| **Controls button** | button `enabled == false` (or equivalent) |
| **Panel** | `FlowPanel(enabled: false)` |

Handle **selected** ← click-to-connect; **active** ← drag-connect.

## Layers (when to use which)

Runtime cascade (most specific wins):

1. **Widget `style:` / per-edge fields** — merged over canvas theme (`base.merge(style)`).
2. **`FlowCanvasTheme`** — from `FlowCanvas(theme: …)` and/or `MaterialApp` via `toThemeData()` (provider inherits parent extension).
3. **Factory defaults** — `.system(context)` / `.light()` / `.dark()` when a slot is still null.

Authoring helpers:

1. **`FlowCanvasTheme.light` / `.dark`** — default path.
2. **`FlowCanvasTheme.copyWith` / `.merge`** — swap or tweak one component style.
3. **`FlowNodeStyle.colored` / per-instance `style:`** — one-off look (Lattice className).
