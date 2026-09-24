/// The main entry point for the lattice library.
///
/// This file exports all the public-facing APIs, including the core canvas,
/// controllers, data models, theming, and options.
library;

// --- Core Canvas ---
export 'src/features/canvas/flow_canvas.dart';
export 'src/features/canvas/flow_canvas_callbacks.dart';
export 'src/features/canvas/flow_canvas_controller.dart';
export 'src/features/canvas/flow_canvas_scope.dart';
export 'src/core/state/flow_canvas_state.dart';
export 'src/core/document/canvas_document.dart';
export 'src/core/debug/flow_canvas_debug.dart';

// --- Node Feature ---
export 'src/features/nodes/domain/models/node.dart';
export 'src/features/nodes/domain/models/node_props.dart';
export 'src/features/nodes/domain/node_registry.dart';
export 'src/core/utils/json_converters.dart'
    show NodeDataCodec, NodeDataToJson, NodeDataFromJson;
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
export 'src/features/viewport/domain/viewport.dart';

// --- Background Plugin ---
export 'src/features/background/presentation/flow_background.dart';

// --- Panel Plugin (React Flow Panel) ---
export 'src/features/panel/presentation/flow_panel.dart';

// --- Viewport Portal (React Flow ViewportPortal) ---
export 'src/features/viewport/presentation/flow_viewport_portal.dart';

// --- Minimap Plugin ---
export 'src/features/minimap/presentation/flow_minimap.dart';

// --- Controls Plugin ---
export 'src/features/control_panel/presentation/flow_canvas_controls.dart';
export 'src/features/control_panel/presentation/control_button.dart';

// --- Edge Label Widget ---
export 'src/features/edge_labels/presentation/flow_edge_label.dart';
export 'src/features/edge_labels/presentation/flow_edge_label_portal.dart';

// --- Toolbars (React Flow NodeToolbar / EdgeToolbar) ---
export 'src/features/toolbar/presentation/flow_toolbars.dart';

// --- Node resizer (React Flow NodeResizer / NodeResizeControl) ---
export 'src/features/node_resizer/presentation/flow_node_resizer.dart';
export 'src/features/node_resizer/presentation/flow_node_resize_control.dart';

// --- Theming ---
export 'src/core/theme/theme_export.dart';

// --- Options ---
export 'src/core/options/flow_options.dart';
export 'src/core/options/components/connection_options.dart';
export 'src/core/options/components/edge_options.dart';
export 'src/core/options/components/fitview_options.dart';
export 'src/core/options/components/keyboard_options.dart';
export 'src/features/keyboard/presentation/flow_key_press.dart';
export 'src/core/options/components/node_options.dart';
export 'src/core/options/components/viewport_options.dart';

// --- Accessibility ---
export 'src/features/a11y/domain/a11y_options.dart';

// --- Shared ---
export 'src/core/enums/enums.dart';
export 'src/core/types/api_aliases.dart';

// --- Utility ---
export 'src/core/utils/random_id_generator.dart';
export 'src/core/utils/flow_guards.dart';
export 'src/core/utils/edge_path_creator.dart';
export 'src/core/utils/edge_collection_utils.dart';
export 'src/core/utils/flow_layout.dart';
export 'src/core/utils/custom_stack_widget.dart'
    show InfiniteHitTestStack, UnboundedSizedBox;

// --- Coordinate conventions (flow vs viewport vs global) ---
export 'src/core/coordinates/flow_coordinates.dart';
export 'src/features/viewport/domain/viewport_transform.dart';

// --- State selectors (useNodes / useEdges / useViewport counterparts) ---
export 'src/core/providers/flow_selectors.dart';
export 'src/features/viewport/application/viewport_service.dart'
    show getNodesBounds, NodeBounds;

// --- Dataflow (useNodeConnections / useNodesData / updateNodeData) ---
export 'src/features/dataflow/domain/node_connection.dart';
export 'src/features/dataflow/application/flow_dataflow.dart';
export 'src/features/dataflow/presentation/flow_data_handle.dart';

// --- Stress / benchmark helpers ---
export 'src/features/nodes/domain/synthetic_graph.dart';

// --- Connection params (React Flow Connection) ---
export 'src/features/connections/domain/models/connection_params.dart';
