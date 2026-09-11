import 'package:lattice/src/core/canvas_state_accessor.dart';
import 'package:lattice/src/features/z_index/application/z_index_service.dart';

class ZIndexController {
  final CanvasStateAccessor _controller;
  final ZIndexService _zIndexService;

  ZIndexController({
    required CanvasStateAccessor controller,
    required ZIndexService zIndexService,
  })  : _controller = controller,
        _zIndexService = zIndexService;

  /// Brings all currently selected nodes to the front.
  void bringSelectionToFront() =>
      _controller.mutate((s) => _zIndexService.bringSelectedToFront(s));

  /// Sends all currently selected nodes to the back.
  void sendSelectionToBack() =>
      _controller.mutate((s) => _zIndexService.sendSelectedToBack(s));

  /// Brings a specific node to the front.
  void bringNodeToFront(String nodeId) =>
      _controller.mutate((s) => _zIndexService.bringToFront(s, nodeId));

  /// Sends a specific node to the back.
  void sendNodeToBack(String nodeId) =>
      _controller.mutate((s) => _zIndexService.sendToBack(s, nodeId));
}
