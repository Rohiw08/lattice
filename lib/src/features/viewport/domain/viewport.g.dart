// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewport.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FlowViewport _$FlowViewportFromJson(Map<String, dynamic> json) =>
    _FlowViewport(
      offset: json['offset'] == null
          ? Offset.zero
          : const OffsetConverter()
              .fromJson(json['offset'] as Map<String, dynamic>),
      zoom: (json['zoom'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$FlowViewportToJson(_FlowViewport instance) =>
    <String, dynamic>{
      'offset': const OffsetConverter().toJson(instance.offset),
      'zoom': instance.zoom,
    };
