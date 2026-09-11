/// The main entry point for the lattice library.
///
/// This file exports all the public-facing APIs, including the core canvas,
/// controllers, data models, theming, and options.
library;

// --- Core Canvas ---
export 'src/features/canvas/flow_canvas.dart';
export 'src/features/canvas/flow_canvas_callbacks.dart';
export 'src/features/canvas/flow_canvas_config.dart';
export 'src/features/canvas/flow_canvas_controller.dart';
export 'src/core/state/flow_canvas_state.dart';
export 'src/core/document/canvas_document.dart';
export 'src/core/debug/flow_canvas_debug.dart';

// --- Node Feature ---
export 'src/features/nodes/domain/models/node.dart';
export 'src/features/nodes/domain/models/node_props.dart';
export 'src/features/nodes/domain/node_registry.dart';
export 'src/features/nodes/presentation/flow_node.dart';
export 'src/features/nodes/presentation/flow_interaction.dart';
export 'src/features/nodes/presentation/builtin_nodes.dart';
export 'src/features/nodes/domain/node_render_layer.dart';
export 'src/features/nodes/domain/node_layout.dart';

// --- Edge Feature ---
export 'src/features/edges/domain/model/edge.dart';
export 'src/features/edges/domain/edge_registry.dart';
export 'src/features/edges/domain/edge_animation_effect.dart';

// --- Handle Feature ---
export 'src/features/handles/domain/handle.dart';
export 'src/features/handles/presentation/flow_handle.dart';

// --- Connection Feature ---
export 'src/features/connections/domain/models/connection.dart';

// --- Viewport Feature ---
export 'src/features/viewport/domain/coordinate_extent.dart';
export 'src/features/viewport/domain/snap_grid.dart';

// --- Background Plugin ---
export 'src/features/background/presentation/flow_background.dart';

// --- Panel Plugin (Lattice Panel) ---
export 'src/features/panel/presentation/flow_panel.dart';

// --- Minimap Plugin ---
export 'src/features/minimap/presentation/flow_minimap.dart';

// --- Controls Plugin ---
export 'src/features/control_panel/presentation/flow_canvas_controls.dart';
export 'src/features/control_panel/presentation/control_button.dart';

// --- Edge Label Widget ---
export 'src/features/edge_labels/presentation/flow_edge_label.dart';

// --- Theming ---
export 'src/core/theme/theme_export.dart';

// --- Options ---
export 'src/core/options/flow_options.dart';
export 'src/core/options/components/connection_options.dart';
export 'src/core/options/components/edge_options.dart';
export 'src/core/options/components/fitview_options.dart';
export 'src/core/options/components/keyboard_options.dart';
export 'src/core/options/components/node_options.dart';
export 'src/core/options/components/viewport_options.dart';

// --- Shared ---
export 'src/core/enums/enums.dart';

// --- Utility ---
export 'src/core/utils/random_id_generator.dart';
export 'src/core/utils/custom_stack_widget.dart'
    show InfiniteHitTestStack, UnboundedSizedBox;

// --- Coordinate conventions (flow vs viewport vs global) ---
export 'src/core/coordinates/flow_coordinates.dart';

// --- History extension point ---
export 'src/features/history/domain/canvas_undo_command.dart';

// --- Stress / benchmark helpers ---
export 'src/features/nodes/domain/synthetic_graph.dart';

// --- Connection params (Lattice Connection) ---
export 'src/features/connections/domain/models/connection_params.dart';
