// ignore_for_file: invalid_annotation_target

import 'package:lattice/src/core/utils/json_converters.dart';
import 'dart:ui';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'viewport.freezed.dart';
part 'viewport.g.dart';

@freezed
abstract class FlowViewport with _$FlowViewport {
  const FlowViewport._();

  const factory FlowViewport({
    @Default(Offset.zero)
    @OffsetConverter()
    @JsonKey(includeFromJson: true, includeToJson: true)
    Offset offset,
    @Default(1.0)
    @JsonKey(includeFromJson: true, includeToJson: true)
    double zoom,
  }) = _FlowViewport;

  factory FlowViewport.fromJson(Map<String, dynamic> json) =>
      _$FlowViewportFromJson(json);

  /// Lattice `Viewport.x` alias for [offset.dx].
  double get x => offset.dx;

  /// Lattice `Viewport.y` alias for [offset.dy].
  double get y => offset.dy;
}
