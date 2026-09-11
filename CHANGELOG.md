# Changelog

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
- Persistence via `CanvasDocument` (`toJson` / `load`), undo / redo history, clipboard copy / paste.
