// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowNode<T> _$FlowNodeFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    _FlowNode<T>(
      id: json['id'] as String,
      parentId: json['parentId'] as String?,
      type: json['type'] as String,
      position: const OffsetConverter()
          .fromJson(json['position'] as Map<String, dynamic>),
      data: _$nullableGenericFromJson(json['data'], fromJsonT),
      size: json['size'] == null
          ? const Size(160, 44)
          : const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
      handles: (json['handles'] as Map<String, dynamic>?)?.map(
            (k, e) =>
                MapEntry(k, FlowHandle.fromJson(e as Map<String, dynamic>)),
          ) ??
          const {},
      hidden: json['hidden'] as bool? ?? false,
      draggable: json['draggable'] as bool? ?? true,
      selectable: json['selectable'] as bool? ?? true,
      hoverable: json['hoverable'] as bool? ?? true,
      connectable: json['connectable'] as bool? ?? true,
      deletable: json['deletable'] as bool? ?? true,
      resizable: json['resizable'] as bool? ?? true,
      focusable: json['focusable'] as bool? ?? true,
      expandParent: json['expandParent'] as bool? ?? false,
      extent: $enumDecodeNullable(_$FlowNodeExtentEnumMap, json['extent']),
    );

Map<String, dynamic> _$FlowNodeToJson<T>(
  _FlowNode<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'id': instance.id,
      'parentId': instance.parentId,
      'type': instance.type,
      'position': const OffsetConverter().toJson(instance.position),
      'data': _$nullableGenericToJson(instance.data, toJsonT),
      'size': const SizeConverter().toJson(instance.size),
      'zIndex': instance.zIndex,
      'handles': instance.handles,
      'hidden': instance.hidden,
      'draggable': instance.draggable,
      'selectable': instance.selectable,
      'hoverable': instance.hoverable,
      'connectable': instance.connectable,
      'deletable': instance.deletable,
      'resizable': instance.resizable,
      'focusable': instance.focusable,
      'expandParent': instance.expandParent,
      'extent': _$FlowNodeExtentEnumMap[instance.extent],
    };

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) =>
    input == null ? null : fromJson(input);

const _$FlowNodeExtentEnumMap = {
  FlowNodeExtent.parent: 'parent',
};

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) =>
    input == null ? null : toJson(input);
