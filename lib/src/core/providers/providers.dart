import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core
import '../../features/canvas/flow_canvas_callbacks.dart';
import '../../features/canvas/flow_canvas_internal_controller.dart';
import '../state/flow_canvas_state.dart';
import '../options/flow_options.dart';

// Features - Nodes
import '../../features/nodes/application/node_service.dart';
import '../../features/nodes/domain/node_registry.dart';

// Features - Edges
import '../../features/edges/application/edge_service.dart';
import '../../features/edges/application/edge_geometry_service.dart';
import '../../features/edges/domain/edge_registry.dart';

// Features - Selection
import '../../features/selection/application/selection_service.dart';

// Features - Viewport
import '../../features/viewport/application/viewport_service.dart';

// Features - Connections
import '../../features/connections/application/connection_service.dart';

// Features - Clipboard
import '../../features/clipboard/application/clipboard_service.dart';

// Features - History
import '../../features/history/application/history_service.dart';

// Features - Spatial
import '../../features/spatial/application/spatial_index_service.dart';

// Features - Keyboard
import '../../features/keyboard/application/keyboard_action_service.dart';

// Features - Z-Index
import '../../features/z_index/application/z_index_service.dart';

final flowControllerProvider =
    NotifierProvider<FlowCanvasInternalController, FlowCanvasState>(
  () {
    throw UnimplementedError(
        'flowControllerProvider must be overridden at the FlowCanvas root.');
  },
);

final internalControllerProvider = flowControllerProvider;

final nodeRegistryProvider = Provider<NodeRegistry>((ref) {
  throw UnimplementedError('NodeRegistryProvider must be overridden');
});

final edgeRegistryProvider = Provider<EdgeRegistry>((ref) {
  throw UnimplementedError('EdgeRegistryProvider must be overridden');
});

final flowOptionsProvider = Provider<FlowCanvasOptions>((ref) {
  throw UnimplementedError('FlowOptionsProvider must be overridden');
});

final flowCanvasCallbacksProvider = Provider<FlowCanvasCallbacks>((ref) {
  return const FlowCanvasCallbacks();
});

final nodeServiceProvider = Provider<NodeService>((ref) => NodeService());
final edgeServiceProvider = Provider<EdgeService>((ref) => EdgeService());
final selectionServiceProvider =
    Provider<SelectionService>((ref) => SelectionService());
final viewportServiceProvider =
    Provider<ViewportService>((ref) => ViewportService());
final connectionServiceProvider =
    Provider<ConnectionService>((ref) => ConnectionService());
final zIndexServiceProvider = Provider<ZIndexService>((ref) => ZIndexService());
final clipboardServiceProvider =
    Provider<ClipboardService>((ref) => ClipboardService());
final historyServiceProvider =
    Provider<HistoryService>((ref) => HistoryService());
final edgeGeometryServiceProvider = Provider<EdgeGeometryService>((ref) {
  return EdgeGeometryService();
});

final spatialIndexServiceProvider = Provider<SpatialIndexService>((ref) {
  return SpatialIndexService();
});

final keyboardActionServiceProvider = Provider<KeyboardActionService>((ref) {
  return KeyboardActionService(
    nodeService: ref.watch(nodeServiceProvider),
    edgeService: ref.watch(edgeServiceProvider),
    selectionService: ref.watch(selectionServiceProvider),
    viewportService: ref.watch(viewportServiceProvider),
    clipboardService: ref.watch(clipboardServiceProvider),
  );
});
