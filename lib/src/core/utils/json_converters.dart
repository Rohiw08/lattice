import 'dart:ui';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// Serializes [Offset] to/from JSON map with 'x', 'y'.
class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();

  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(
      (json['x'] as num).toDouble(),
      (json['y'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {
      'x': object.dx,
      'y': object.dy,
    };
  }
}

/// Serializes [Size] to/from JSON map with 'width', 'height'.
class SizeConverter implements JsonConverter<Size, Map<String, dynamic>> {
  const SizeConverter();

  @override
  Size fromJson(Map<String, dynamic> json) {
    return Size(
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Size object) {
    return {
      'width': object.width,
      'height': object.height,
    };
  }
}

/// Serializes [Rect] to/from JSON map with 'left', 'top', 'width', 'height'.
class RectConverter implements JsonConverter<Rect, Map<String, dynamic>> {
  const RectConverter();

  @override
  Rect fromJson(Map<String, dynamic> json) {
    return Rect.fromLTWH(
      (json['left'] as num).toDouble(),
      (json['top'] as num).toDouble(),
      (json['width'] as num).toDouble(),
      (json['height'] as num).toDouble(),
    );
  }

  @override
  Map<String, dynamic> toJson(Rect object) {
    return {
      'left': object.left,
      'top': object.top,
      'width': object.width,
      'height': object.height,
    };
  }
}

class NodeMapConverter
    implements JsonConverter<Map<String, FlowNode>, Map<String, dynamic>> {
  const NodeMapConverter();

  @override
  Map<String, FlowNode> fromJson(Map<String, dynamic> json) {
    return json.map(
      (k, v) =>
          MapEntry(k, FlowNode.fromJson(v as Map<String, dynamic>, (o) => o)),
    );
  }

  @override
  Map<String, dynamic> toJson(Map<String, FlowNode> object) {
    return object.map((k, v) => MapEntry(k, (v as dynamic).toJson((o) => o)));
  }
}
