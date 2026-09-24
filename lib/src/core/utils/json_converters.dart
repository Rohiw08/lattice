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

/// Encodes a node's [FlowNode.data] to a JSON-safe value, keyed by node `type`.
///
/// Supplied by the registered [NodeDataCodec] for that type (see
/// `NodeRegistry.registerTyped`). Falls back to identity when no codec is
/// registered, so primitive/`Map` data still round-trips unchanged.
typedef NodeDataToJson = Object? Function(String type, Object? data);

/// Rehydrates a node's [FlowNode.data] from its JSON form, keyed by node `type`.
///
/// The decode half of [NodeDataToJson]; the counterpart used on load.
typedef NodeDataFromJson = Object? Function(String type, Object? json);

/// Serializes typed [FlowNode.data] for one node type.
///
/// Register with `NodeRegistry.registerTyped(toJson:, fromJson:)` (or the
/// `register(codec:)` escape hatch) so `saveDocument`/`loadDocument` and
/// `toJson`/`toSyncJson` can round-trip non-primitive `data` (e.g. a sealed
/// class). Without a codec, `data` must already be JSON-encodable.
@immutable
class NodeDataCodec {
  const NodeDataCodec({required this.encode, required this.decode});

  /// `data` → JSON-safe value. Receives `null` untouched (returns `null`).
  final Object? Function(Object? data) encode;

  /// JSON value → `data`. Receives `null` untouched (returns `null`).
  final Object? Function(Object? json) decode;
}

class NodeMapConverter
    implements JsonConverter<Map<String, FlowNode>, Map<String, dynamic>> {
  const NodeMapConverter();

  /// Decodes the node map. When [decodeData] is supplied, each node's
  /// [FlowNode.data] is rehydrated per its `type`; otherwise `data` passes
  /// through unchanged (identity), preserving primitive-data behavior.
  @override
  Map<String, FlowNode> fromJson(
    Map<String, dynamic> json, [
    NodeDataFromJson? decodeData,
  ]) {
    return json.map((k, v) {
      final map = v as Map<String, dynamic>;
      if (decodeData == null) {
        return MapEntry(k, FlowNode.fromJson(map, (o) => o));
      }
      final type = map['type'] as String? ?? '';
      return MapEntry(k, FlowNode.fromJson(map, (o) => decodeData(type, o)));
    });
  }

  /// Encodes the node map. When [encodeData] is supplied, each node's
  /// [FlowNode.data] is encoded per its `type`; otherwise `data` passes
  /// through unchanged (identity).
  @override
  Map<String, dynamic> toJson(
    Map<String, FlowNode> object, [
    NodeDataToJson? encodeData,
  ]) {
    return object.map((k, v) {
      if (encodeData == null) {
        return MapEntry(k, (v as dynamic).toJson((o) => o));
      }
      return MapEntry(k, (v as dynamic).toJson((o) => encodeData(v.type, o)));
    });
  }
}
