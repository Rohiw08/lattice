import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

/// Edge ids touching [nodeId], split by direction.
///
/// Derived from the document, so it updates on every document commit
/// (add/remove edge, load, undo/redo).
final latticeNodeConnectionsProvider = Provider.family<
    ({Set<String> incoming, Set<String> outgoing}), String>((ref, nodeId) {
  final edges = ref.watch(
    latticeDocumentProvider.select((document) => document.edges),
  );
  final Set<String> incoming = <String>{};
  final Set<String> outgoing = <String>{};
  for (final entry in edges.entries) {
    if (entry.value.target.nodeId == nodeId) incoming.add(entry.key);
    if (entry.value.source.nodeId == nodeId) outgoing.add(entry.key);
  }
  return (incoming: incoming, outgoing: outgoing);
});

/// The opaque `data` payload of the node with [nodeId], or `null` when
/// absent.
///
/// NOTE: the plan draft named this `latticeNodesDataProvider(Set<String>)`,
/// but a family keyed by `Set` defeats provider caching (a new set instance
/// per read). This single-node family covers the same `useNodesData` needs:
/// callers watch one provider per id and combine the results.
final latticeNodeDataProvider =
    Provider.family<Object?, String>((ref, nodeId) {
  return ref.watch(
    latticeDocumentProvider.select((document) => document.nodes[nodeId]?.data),
  );
});
