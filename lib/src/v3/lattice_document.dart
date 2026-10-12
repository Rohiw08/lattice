import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'lattice_codecs.dart';
import 'lattice_edge.dart';
import 'lattice_handle.dart';
import 'lattice_node.dart';
import 'lattice_viewport_value.dart';

/// An immutable canvas document: nodes, edges, and viewport only.
///
/// Selection lives in the session (not here), so documents stay
/// undoable/serializable/syncable.
@immutable
class LatticeDocument {
  const LatticeDocument({
    this.nodes = const {},
    this.edges = const {},
    this.viewport = const LatticeViewportValue(),
  });

  final Map<String, LatticeNode> nodes;
  final Map<String, LatticeEdge> edges;
  final LatticeViewportValue viewport;

  static LatticeDocument empty() => const LatticeDocument();

  /// Returns a copy, reusing the identical map instances for any argument
  /// left null (selector fast path: unchanged slices stay `identical`).
  LatticeDocument copyWith({
    Map<String, LatticeNode>? nodes,
    Map<String, LatticeEdge>? edges,
    LatticeViewportValue? viewport,
  }) {
    return LatticeDocument(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      viewport: viewport ?? this.viewport,
    );
  }

  LatticeDocument withNode(LatticeNode node) {
    return LatticeDocument(
      nodes: <String, LatticeNode>{...nodes, node.id: node},
      edges: edges,
      viewport: viewport,
    );
  }

  LatticeDocument withoutNodes(Set<String> ids) {
    if (ids.isEmpty || !nodes.keys.any(ids.contains)) return this;
    final Map<String, LatticeNode> next = Map<String, LatticeNode>.of(nodes)
      ..removeWhere((String id, LatticeNode _) => ids.contains(id));
    return LatticeDocument(nodes: next, edges: edges, viewport: viewport);
  }

  LatticeDocument withEdge(LatticeEdge edge) {
    return LatticeDocument(
      nodes: nodes,
      edges: <String, LatticeEdge>{...edges, edge.id: edge},
      viewport: viewport,
    );
  }

  LatticeDocument withoutEdges(Set<String> ids) {
    if (ids.isEmpty || !edges.keys.any(ids.contains)) return this;
    final Map<String, LatticeEdge> next = Map<String, LatticeEdge>.of(edges)
      ..removeWhere((String id, LatticeEdge _) => ids.contains(id));
    return LatticeDocument(nodes: nodes, edges: next, viewport: viewport);
  }

  LatticeDocument withViewport(LatticeViewportValue viewport) {
    return LatticeDocument(nodes: nodes, edges: edges, viewport: viewport);
  }

  Map<String, Object?> toJson([EncodeNodeData? encode]) {
    return <String, Object?>{
      'nodes': <Object?>[
        for (final LatticeNode node in nodes.values) node.toJson(encode),
      ],
      'edges': <Object?>[
        for (final LatticeEdge edge in edges.values) edge.toJson(),
      ],
      'viewport': viewport.toJson(),
    };
  }

  factory LatticeDocument.fromJson(
    Map<String, Object?> json, [
    DecodeNodeData? decode,
  ]) {
    final Map<String, LatticeNode> nodes = <String, LatticeNode>{};
    for (final Map<String, Object?> nodeJson in _nodeList(json['nodes'])) {
      final LatticeNode node =
          _sanitizeNode(LatticeNode.fromJson(nodeJson, decode));
      // Duplicate ids (hand-edited JSON): last wins, no throw.
      nodes[node.id] = node;
    }
    final Map<String, LatticeEdge> edges = <String, LatticeEdge>{};
    for (final Map<String, Object?> edgeJson in _nodeList(json['edges'])) {
      final LatticeEdge edge = LatticeEdge.fromJson(edgeJson);
      edges[edge.id] = edge;
    }
    final Object? viewportJson = json['viewport'];
    return LatticeDocument(
      nodes: nodes,
      edges: edges,
      viewport: viewportJson is Map
          ? LatticeViewportValue.fromJson(
              viewportJson.cast<String, Object?>(),
            )
          : const LatticeViewportValue(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeDocument &&
        other.viewport == viewport &&
        _mapsEqual(other.nodes, nodes) &&
        _mapsEqual(other.edges, edges);
  }

  @override
  int get hashCode => Object.hash(
        viewport,
        Object.hashAllUnordered(
          nodes.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        Object.hashAllUnordered(
          edges.entries.map((e) => Object.hash(e.key, e.value)),
        ),
      );
}

List<Map<String, Object?>> _nodeList(Object? json) {
  if (json is List) {
    return <Map<String, Object?>>[
      for (final Object? entry in json) (entry as Map).cast<String, Object?>(),
    ];
  }
  if (json is Map) {
    return <Map<String, Object?>>[
      for (final Object? entry in json.values)
        (entry as Map).cast<String, Object?>(),
    ];
  }
  return const <Map<String, Object?>>[];
}

bool _mapsEqual<T>(Map<String, T> a, Map<String, T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final String key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}

double _finiteOrZero(double value) => value.isFinite ? value : 0.0;

Offset _sanitizeOffset(Offset offset) {
  return Offset(_finiteOrZero(offset.dx), _finiteOrZero(offset.dy));
}

Size _sanitizeSize(Size size) {
  return Size(_finiteOrZero(size.width), _finiteOrZero(size.height));
}

Rect _sanitizeRect(Rect rect) {
  return Rect.fromLTRB(
    _finiteOrZero(rect.left),
    _finiteOrZero(rect.top),
    _finiteOrZero(rect.right),
    _finiteOrZero(rect.bottom),
  );
}

Map<String, LatticeHandle> _sanitizeHandles(
  Map<String, LatticeHandle> handles,
) {
  Map<String, LatticeHandle>? next;
  handles.forEach((String key, LatticeHandle handle) {
    final Offset position = _sanitizeOffset(handle.position);
    final Size size = _sanitizeSize(handle.size);
    if (position != handle.position || size != handle.size) {
      next ??= Map<String, LatticeHandle>.of(handles);
      next![key] = handle.copyWith(position: position, size: size);
    }
  });
  return next ?? handles;
}

/// Normalizes non-finite (`NaN`/`Infinity`) geometric doubles to `0.0`.
/// The opaque `data` payload is left untouched.
LatticeNode _sanitizeNode(LatticeNode node) {
  final Offset position = _sanitizeOffset(node.position);
  final Offset? origin =
      node.origin == null ? null : _sanitizeOffset(node.origin!);
  final Size size = _sanitizeSize(node.size);
  final Size? minSize =
      node.minSize == null ? null : _sanitizeSize(node.minSize!);
  final Size? maxSize =
      node.maxSize == null ? null : _sanitizeSize(node.maxSize!);
  final Rect? extent =
      node.extent == null ? null : _sanitizeRect(node.extent!);
  final Map<String, LatticeHandle> handles = _sanitizeHandles(node.handles);
  if (position == node.position &&
      origin == node.origin &&
      size == node.size &&
      minSize == node.minSize &&
      maxSize == node.maxSize &&
      extent == node.extent &&
      identical(handles, node.handles)) {
    return node;
  }
  return node.copyWith(
    position: position,
    origin: origin,
    size: size,
    minSize: minSize,
    maxSize: maxSize,
    extent: extent,
    handles: handles,
  );
}
