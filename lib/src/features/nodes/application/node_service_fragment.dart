import 'package:lattice/src/core/state/flow_canvas_state.dart';

Set<String> getDescendants(
    FlowCanvasState state, Iterable<String> rootNodeIds) {
  if (rootNodeIds.isEmpty) return {};

  final parentToChildren = <String, List<String>>{};
  for (final node in state.nodes.values) {
    if (node.parentId != null) {
      parentToChildren.putIfAbsent(node.parentId!, () => []).add(node.id);
    }
  }

  final allNodes = <String>{};
  final queue = List<String>.from(rootNodeIds);

  while (queue.isNotEmpty) {
    final id = queue.removeLast();
    if (allNodes.contains(id)) continue;
    allNodes.add(id);

    final children = parentToChildren[id];
    if (children != null) {
      queue.addAll(children);
    }
  }
  return allNodes;
}
