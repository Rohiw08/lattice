import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'lattice_codecs.dart';
import 'lattice_handle.dart';

/// An immutable canvas node.
@immutable
class LatticeNode {
  const LatticeNode({
    required this.id,
    required this.type,
    required this.position,
    this.origin,
    this.size = const Size(160, 44),
    this.data,
    this.parentId,
    this.zIndex = 0,
    this.handles = const {},
    this.hidden,
    this.draggable,
    this.selectable,
    this.hoverable,
    this.connectable,
    this.deletable,
    this.resizable,
    this.focusable,
    this.minSize,
    this.maxSize,
    this.keepAspectRatio = false,
    this.expandParent = false,
    this.dragHandle = false,
    this.semanticsLabel,
    this.extent,
  });

  final String id;
  final String type;
  final Offset position;
  final Offset? origin;
  final Size size;

  /// Opaque payload. Passes through `toJson`/`fromJson` by reference when
  /// codecs are null; otherwise converted via [EncodeNodeData]/[DecodeNodeData].
  final Object? data;
  final String? parentId;
  final int zIndex;
  final Map<String, LatticeHandle> handles;
  final bool? hidden;
  final bool? draggable;
  final bool? selectable;
  final bool? hoverable;
  final bool? connectable;
  final bool? deletable;
  final bool? resizable;
  final bool? focusable;
  final Size? minSize;
  final Size? maxSize;
  final bool keepAspectRatio;
  final bool expandParent;
  final bool dragHandle;
  final String? semanticsLabel;
  final Rect? extent;

  LatticeNode copyWith({
    String? id,
    String? type,
    Offset? position,
    Offset? origin,
    Size? size,
    Object? data,
    String? parentId,
    int? zIndex,
    Map<String, LatticeHandle>? handles,
    bool? hidden,
    bool? draggable,
    bool? selectable,
    bool? hoverable,
    bool? connectable,
    bool? deletable,
    bool? resizable,
    bool? focusable,
    Size? minSize,
    Size? maxSize,
    bool? keepAspectRatio,
    bool? expandParent,
    bool? dragHandle,
    String? semanticsLabel,
    Rect? extent,
  }) {
    return LatticeNode(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      origin: origin ?? this.origin,
      size: size ?? this.size,
      data: data ?? this.data,
      parentId: parentId ?? this.parentId,
      zIndex: zIndex ?? this.zIndex,
      handles: handles ?? this.handles,
      hidden: hidden ?? this.hidden,
      draggable: draggable ?? this.draggable,
      selectable: selectable ?? this.selectable,
      hoverable: hoverable ?? this.hoverable,
      connectable: connectable ?? this.connectable,
      deletable: deletable ?? this.deletable,
      resizable: resizable ?? this.resizable,
      focusable: focusable ?? this.focusable,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      keepAspectRatio: keepAspectRatio ?? this.keepAspectRatio,
      expandParent: expandParent ?? this.expandParent,
      dragHandle: dragHandle ?? this.dragHandle,
      semanticsLabel: semanticsLabel ?? this.semanticsLabel,
      extent: extent ?? this.extent,
    );
  }

  /// Effective handles for this node.
  ///
  /// Returns the explicit [handles] when non-empty. Otherwise synthesizes
  /// defaults for the built-in types: `default` gets a `source` handle at the
  /// bottom-center plus a `target` handle at the top-center; `input` gets only
  /// `target`; `output` gets only `source`. All other types yield `{}`.
  Map<String, LatticeHandle> resolveHandles() {
    if (handles.isNotEmpty) return handles;
    switch (type) {
      case 'default':
        return <String, LatticeHandle>{
          'source': _sourceHandle(size),
          'target': _targetHandle(size),
        };
      case 'input':
        return <String, LatticeHandle>{'target': _targetHandle(size)};
      case 'output':
        return <String, LatticeHandle>{'source': _sourceHandle(size)};
      default:
        return const <String, LatticeHandle>{};
    }
  }

  Map<String, Object?> toJson([EncodeNodeData? encode]) {
    return <String, Object?>{
      'id': id,
      'type': type,
      'position': _encodeOffset(position),
      'origin': origin == null ? null : _encodeOffset(origin!),
      'size': _encodeSize(size),
      'data': encode == null ? data : encode(type, data),
      'parentId': parentId,
      'zIndex': zIndex,
      'handles': <String, Object?>{
        for (final entry in handles.entries) entry.key: entry.value.toJson(),
      },
      'hidden': hidden,
      'draggable': draggable,
      'selectable': selectable,
      'hoverable': hoverable,
      'connectable': connectable,
      'deletable': deletable,
      'resizable': resizable,
      'focusable': focusable,
      'minSize': minSize == null ? null : _encodeSize(minSize!),
      'maxSize': maxSize == null ? null : _encodeSize(maxSize!),
      'keepAspectRatio': keepAspectRatio,
      'expandParent': expandParent,
      'dragHandle': dragHandle,
      'semanticsLabel': semanticsLabel,
      'extent': extent == null ? null : _encodeRect(extent!),
    };
  }

  factory LatticeNode.fromJson(
    Map<String, Object?> json, [
    DecodeNodeData? decode,
  ]) {
    final String nodeType = json['type'] as String;
    final handlesJson = json['handles'] as Map<String, dynamic>?;
    return LatticeNode(
      id: json['id'] as String,
      type: nodeType,
      position: _decodeOffset(json['position']),
      origin: json['origin'] == null ? null : _decodeOffset(json['origin']),
      size: json['size'] == null
          ? const Size(160, 44)
          : _decodeSize(json['size']),
      data: decode == null ? json['data'] : decode(nodeType, json['data']),
      parentId: json['parentId'] as String?,
      zIndex: json['zIndex'] as int? ?? 0,
      handles: handlesJson == null
          ? const <String, LatticeHandle>{}
          : <String, LatticeHandle>{
              for (final entry in handlesJson.entries)
                entry.key: LatticeHandle.fromJson(
                  (entry.value as Map).cast<String, Object?>(),
                ),
            },
      hidden: json['hidden'] as bool?,
      draggable: json['draggable'] as bool?,
      selectable: json['selectable'] as bool?,
      hoverable: json['hoverable'] as bool?,
      connectable: json['connectable'] as bool?,
      deletable: json['deletable'] as bool?,
      resizable: json['resizable'] as bool?,
      focusable: json['focusable'] as bool?,
      minSize: json['minSize'] == null ? null : _decodeSize(json['minSize']),
      maxSize: json['maxSize'] == null ? null : _decodeSize(json['maxSize']),
      keepAspectRatio: json['keepAspectRatio'] as bool? ?? false,
      expandParent: json['expandParent'] as bool? ?? false,
      dragHandle: json['dragHandle'] as bool? ?? false,
      semanticsLabel: json['semanticsLabel'] as String?,
      extent: json['extent'] == null ? null : _decodeRect(json['extent']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeNode &&
        other.id == id &&
        other.type == type &&
        other.position == position &&
        other.origin == origin &&
        other.size == size &&
        other.data == data &&
        other.parentId == parentId &&
        other.zIndex == zIndex &&
        _handlesEqual(other.handles, handles) &&
        other.hidden == hidden &&
        other.draggable == draggable &&
        other.selectable == selectable &&
        other.hoverable == hoverable &&
        other.connectable == connectable &&
        other.deletable == deletable &&
        other.resizable == resizable &&
        other.focusable == focusable &&
        other.minSize == minSize &&
        other.maxSize == maxSize &&
        other.keepAspectRatio == keepAspectRatio &&
        other.expandParent == expandParent &&
        other.dragHandle == dragHandle &&
        other.semanticsLabel == semanticsLabel &&
        other.extent == extent;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
        id,
        type,
        position,
        origin,
        size,
        data,
        parentId,
        zIndex,
        Object.hashAll(
          handles.entries.map((e) => Object.hash(e.key, e.value)),
        ),
        hidden,
        draggable,
        selectable,
        hoverable,
        connectable,
        deletable,
        resizable,
        focusable,
        minSize,
        maxSize,
        keepAspectRatio,
        expandParent,
        dragHandle,
        semanticsLabel,
        extent,
      ]);
}

/// Source handle centered on the bottom edge of a node of [nodeSize].
LatticeHandle _sourceHandle(Size nodeSize) {
  return LatticeHandle(
    id: 'source',
    type: LatticeHandleType.source,
    position: Offset(nodeSize.width / 2 - 3, nodeSize.height - 3),
    size: const Size(6, 6),
  );
}

/// Target handle centered on the top edge of a node of [nodeSize].
LatticeHandle _targetHandle(Size nodeSize) {
  return LatticeHandle(
    id: 'target',
    type: LatticeHandleType.target,
    position: Offset(nodeSize.width / 2 - 3, -3),
    size: const Size(6, 6),
  );
}

bool _handlesEqual(
  Map<String, LatticeHandle> a,
  Map<String, LatticeHandle> b,
) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (final key in a.keys) {
    if (!b.containsKey(key) || b[key] != a[key]) return false;
  }
  return true;
}

Map<String, Object?> _encodeOffset(Offset offset) {
  return <String, Object?>{'dx': offset.dx, 'dy': offset.dy};
}

Map<String, Object?> _encodeSize(Size size) {
  return <String, Object?>{'width': size.width, 'height': size.height};
}

Map<String, Object?> _encodeRect(Rect rect) {
  return <String, Object?>{
    'left': rect.left,
    'top': rect.top,
    'right': rect.right,
    'bottom': rect.bottom,
  };
}

Offset _decodeOffset(Object? json) {
  final map = json as Map<String, dynamic>;
  return Offset(
    (map['dx'] as num).toDouble(),
    (map['dy'] as num).toDouble(),
  );
}

Size _decodeSize(Object? json) {
  final map = json as Map<String, dynamic>;
  return Size(
    (map['width'] as num).toDouble(),
    (map['height'] as num).toDouble(),
  );
}

Rect _decodeRect(Object? json) {
  final map = json as Map<String, dynamic>;
  return Rect.fromLTRB(
    (map['left'] as num).toDouble(),
    (map['top'] as num).toDouble(),
    (map['right'] as num).toDouble(),
    (map['bottom'] as num).toDouble(),
  );
}
