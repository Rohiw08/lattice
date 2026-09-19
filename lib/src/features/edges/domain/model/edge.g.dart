// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edge.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowEdge _$FlowEdgeFromJson(Map<String, dynamic> json) => _FlowEdge(
  id: json['id'] as String,
  sourceNodeId: json['sourceNodeId'] as String,
  targetNodeId: json['targetNodeId'] as String,
  sourceHandleId: json['sourceHandleId'] as String?,
  targetHandleId: json['targetHandleId'] as String?,
  zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
  type:
      $enumDecodeNullable(_$EdgePathTypeEnumMap, json['type']) ??
      EdgePathType.bezier,
  interactionWidth: (json['interactionWidth'] as num?)?.toDouble() ?? 20.0,
  data: json['data'] as Map<String, dynamic>? ?? const <String, dynamic>{},
  animated: json['animated'] as bool? ?? false,
  hidden: json['hidden'] as bool?,
  deletable: json['deletable'] as bool?,
  selectable: json['selectable'] as bool?,
  focusable: json['focusable'] as bool?,
  semanticsLabel: json['semanticsLabel'] as String?,
  reconnectable: json['reconnectable'] as bool?,
  elevateEdgeOnSelect: json['elevateEdgeOnSelect'] as bool?,
);

Map<String, dynamic> _$FlowEdgeToJson(_FlowEdge instance) => <String, dynamic>{
  'id': instance.id,
  'sourceNodeId': instance.sourceNodeId,
  'targetNodeId': instance.targetNodeId,
  'sourceHandleId': instance.sourceHandleId,
  'targetHandleId': instance.targetHandleId,
  'zIndex': instance.zIndex,
  'type': _$EdgePathTypeEnumMap[instance.type]!,
  'interactionWidth': instance.interactionWidth,
  'data': instance.data,
  'animated': instance.animated,
  'hidden': instance.hidden,
  'deletable': instance.deletable,
  'selectable': instance.selectable,
  'focusable': instance.focusable,
  'semanticsLabel': instance.semanticsLabel,
  'reconnectable': instance.reconnectable,
  'elevateEdgeOnSelect': instance.elevateEdgeOnSelect,
};

const _$EdgePathTypeEnumMap = {
  EdgePathType.bezier: 'bezier',
  EdgePathType.step: 'step',
  EdgePathType.straight: 'straight',
  EdgePathType.smoothStep: 'smoothStep',
  EdgePathType.simpleBezier: 'simpleBezier',
};
