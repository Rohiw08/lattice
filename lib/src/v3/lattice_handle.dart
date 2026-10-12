import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Which side of a node a handle belongs to.
enum LatticeHandleType { source, target }

/// An immutable connection point on a [LatticeNode].
@immutable
class LatticeHandle {
  const LatticeHandle({
    required this.id,
    required this.type,
    required this.position,
    this.size = const Size(6, 6),
  });

  final String id;
  final LatticeHandleType type;

  /// Top-left offset of the handle rect, relative to the node top-left.
  final Offset position;
  final Size size;

  LatticeHandle copyWith({
    String? id,
    LatticeHandleType? type,
    Offset? position,
    Size? size,
  }) {
    return LatticeHandle(
      id: id ?? this.id,
      type: type ?? this.type,
      position: position ?? this.position,
      size: size ?? this.size,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'type': type.name,
      'position': <String, Object?>{'dx': position.dx, 'dy': position.dy},
      'size': <String, Object?>{'width': size.width, 'height': size.height},
    };
  }

  factory LatticeHandle.fromJson(Map<String, Object?> json) {
    return LatticeHandle(
      id: json['id'] as String,
      type: LatticeHandleType.values.byName(json['type'] as String),
      position: _decodeOffset(json['position']),
      size: _decodeSize(json['size']),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeHandle &&
        other.id == id &&
        other.type == type &&
        other.position == position &&
        other.size == size;
  }

  @override
  int get hashCode => Object.hash(id, type, position, size);
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
