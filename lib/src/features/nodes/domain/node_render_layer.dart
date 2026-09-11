import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/presentation/builtin_nodes.dart';

/// Paint / hit-test band for nodes (layered), while canvas-style z-order applies
/// *within* each band.
///
/// Viewport stacking (back → front):
/// 1. [background] — group containers
/// 2. edges
/// 3. [middle] — regular nodes
/// 4. selection / UI
///
/// Opaque groups therefore cannot cover edges; child nodes still cover edges.
enum NodeRenderLayer {
  /// Group / container nodes painted behind edges.
  background,

  /// Default nodes painted above edges.
  middle,

  /// Reserved for overlays (comments, etc.).
  foreground,
}

/// Resolves which stack band a node belongs to.
extension FlowNodeRenderLayer on FlowNode {
  /// Built-in `group` type → background; everything else → middle.
  ///
  /// Override by setting `data['renderLayer']` to `'background'`, `'middle'`,
  /// or `'foreground'` when [data] is a [Map].
  NodeRenderLayer get renderLayer {
    final fromData = _layerFromData(data);
    if (fromData != null) return fromData;
    if (type == BuiltInNodeType.group) return NodeRenderLayer.background;
    return NodeRenderLayer.middle;
  }

  static NodeRenderLayer? _layerFromData(Object? data) {
    if (data is! Map) return null;
    final raw = data['renderLayer'] ?? data['layer'];
    if (raw is! String) return null;
    switch (raw) {
      case 'background':
        return NodeRenderLayer.background;
      case 'middle':
        return NodeRenderLayer.middle;
      case 'foreground':
        return NodeRenderLayer.foreground;
      default:
        return null;
    }
  }
}

/// canvas-style selected boost applied when sorting within a layer
/// (`elevateNodesOnSelect` → +1000).
const int kSelectedNodeZBoost = 1000;
