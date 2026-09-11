// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowHandle _$FlowHandleFromJson(Map<String, dynamic> json) => _FlowHandle(
      id: json['id'] as String,
      type: $enumDecode(_$HandleTypeEnumMap, json['type']),
      position: const OffsetConverter()
          .fromJson(json['position'] as Map<String, dynamic>),
      isConnectable: json['isConnectable'] as bool? ?? true,
      size: json['size'] == null
          ? const Size(10, 10)
          : const SizeConverter()
              .fromJson(json['size'] as Map<String, dynamic>),
      maxConnections: (json['maxConnections'] as num?)?.toInt(),
      connectionGroup: json['connectionGroup'] as String?,
      data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$FlowHandleToJson(_FlowHandle instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$HandleTypeEnumMap[instance.type]!,
      'position': const OffsetConverter().toJson(instance.position),
      'isConnectable': instance.isConnectable,
      'size': const SizeConverter().toJson(instance.size),
      'maxConnections': instance.maxConnections,
      'connectionGroup': instance.connectionGroup,
      'data': instance.data,
    };

const _$HandleTypeEnumMap = {
  HandleType.both: 'both',
  HandleType.source: 'source',
  HandleType.target: 'target',
};
