import 'package:flutter/foundation.dart';

/// One end of a [LatticeEdge]: the node plus the optional handle on it.
@immutable
class LatticeEndpoint {
  const LatticeEndpoint({required this.nodeId, this.handleId});

  final String nodeId;
  final String? handleId;

  Map<String, Object?> toJson() {
    return <String, Object?>{'nodeId': nodeId, 'handleId': handleId};
  }

  factory LatticeEndpoint.fromJson(Map<String, Object?> json) {
    return LatticeEndpoint(
      nodeId: json['nodeId'] as String,
      handleId: json['handleId'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeEndpoint &&
        other.nodeId == nodeId &&
        other.handleId == handleId;
  }

  @override
  int get hashCode => Object.hash(nodeId, handleId);
}

/// An immutable directed connection between two nodes.
@immutable
class LatticeEdge {
  const LatticeEdge({
    required this.id,
    required this.source,
    required this.target,
    this.type = 'default',
    this.data,
    this.label,
    this.animated = false,
    this.hidden,
    this.selectable,
    this.deletable,
    this.zIndex = 0,
  });

  final String id;
  final LatticeEndpoint source;
  final LatticeEndpoint target;
  final String type;
  final Object? data;
  final String? label;
  final bool animated;
  final bool? hidden;
  final bool? selectable;
  final bool? deletable;
  final int zIndex;

  LatticeEdge copyWith({
    String? id,
    LatticeEndpoint? source,
    LatticeEndpoint? target,
    String? type,
    Object? data,
    String? label,
    bool? animated,
    bool? hidden,
    bool? selectable,
    bool? deletable,
    int? zIndex,
  }) {
    return LatticeEdge(
      id: id ?? this.id,
      source: source ?? this.source,
      target: target ?? this.target,
      type: type ?? this.type,
      data: data ?? this.data,
      label: label ?? this.label,
      animated: animated ?? this.animated,
      hidden: hidden ?? this.hidden,
      selectable: selectable ?? this.selectable,
      deletable: deletable ?? this.deletable,
      zIndex: zIndex ?? this.zIndex,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'source': source.toJson(),
      'target': target.toJson(),
      'type': type,
      'data': data,
      'label': label,
      'animated': animated,
      'hidden': hidden,
      'selectable': selectable,
      'deletable': deletable,
      'zIndex': zIndex,
    };
  }

  factory LatticeEdge.fromJson(Map<String, Object?> json) {
    return LatticeEdge(
      id: json['id'] as String,
      source:
          LatticeEndpoint.fromJson(json['source'] as Map<String, dynamic>),
      target:
          LatticeEndpoint.fromJson(json['target'] as Map<String, dynamic>),
      type: json['type'] as String? ?? 'default',
      data: json['data'],
      label: json['label'] as String?,
      animated: json['animated'] as bool? ?? false,
      hidden: json['hidden'] as bool?,
      selectable: json['selectable'] as bool?,
      deletable: json['deletable'] as bool?,
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeEdge &&
        other.id == id &&
        other.source == source &&
        other.target == target &&
        other.type == type &&
        other.data == data &&
        other.label == label &&
        other.animated == animated &&
        other.hidden == hidden &&
        other.selectable == selectable &&
        other.deletable == deletable &&
        other.zIndex == zIndex;
  }

  @override
  int get hashCode => Object.hash(
        id,
        source,
        target,
        type,
        data,
        label,
        animated,
        hidden,
        selectable,
        deletable,
        zIndex,
      );
}
