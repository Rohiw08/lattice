// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowNode<T> _$FlowNodeFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => _FlowNode<T>(
  id: json['id'] as String,
  parentId: json['parentId'] as String?,
  type: json['type'] as String,
  position: const OffsetConverter().fromJson(
    json['position'] as Map<String, dynamic>,
  ),
  origin: _$JsonConverterFromJson<Map<String, dynamic>, Offset>(
    json['origin'],
    const OffsetConverter().fromJson,
  ),
  data: _$nullableGenericFromJson(json['data'], fromJsonT),
  size: json['size'] == null
      ? const Size(160, 44)
      : const SizeConverter().fromJson(json['size'] as Map<String, dynamic>),
  zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
  handles:
      (json['handles'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, FlowHandle.fromJson(e as Map<String, dynamic>)),
      ) ??
      const {},
  hidden: json['hidden'] as bool?,
  draggable: json['draggable'] as bool?,
  selectable: json['selectable'] as bool?,
  hoverable: json['hoverable'] as bool?,
  connectable: json['connectable'] as bool?,
  deletable: json['deletable'] as bool?,
  resizable: json['resizable'] as bool?,
  minSize: _$JsonConverterFromJson<Map<String, dynamic>, Size>(
    json['minSize'],
    const SizeConverter().fromJson,
  ),
  maxSize: _$JsonConverterFromJson<Map<String, dynamic>, Size>(
    json['maxSize'],
    const SizeConverter().fromJson,
  ),
  keepAspectRatio: json['keepAspectRatio'] as bool? ?? false,
  focusable: json['focusable'] as bool?,
  dragHandle: json['dragHandle'] as bool? ?? false,
  semanticsLabel: json['semanticsLabel'] as String?,
  expandParent: json['expandParent'] as bool? ?? false,
  extent: $enumDecodeNullable(_$FlowNodeExtentEnumMap, json['extent']),
);

Map<String, dynamic> _$FlowNodeToJson<T>(
  _FlowNode<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'id': instance.id,
  'parentId': instance.parentId,
  'type': instance.type,
  'position': const OffsetConverter().toJson(instance.position),
  'origin': _$JsonConverterToJson<Map<String, dynamic>, Offset>(
    instance.origin,
    const OffsetConverter().toJson,
  ),
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
  'minSize': _$JsonConverterToJson<Map<String, dynamic>, Size>(
    instance.minSize,
    const SizeConverter().toJson,
  ),
  'maxSize': _$JsonConverterToJson<Map<String, dynamic>, Size>(
    instance.maxSize,
    const SizeConverter().toJson,
  ),
  'keepAspectRatio': instance.keepAspectRatio,
  'focusable': instance.focusable,
  'dragHandle': instance.dragHandle,
  'semanticsLabel': instance.semanticsLabel,
  'expandParent': instance.expandParent,
  'extent': _$FlowNodeExtentEnumMap[instance.extent],
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

const _$FlowNodeExtentEnumMap = {FlowNodeExtent.parent: 'parent'};

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);
