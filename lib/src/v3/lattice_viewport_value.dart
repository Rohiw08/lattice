import 'package:flutter/widgets.dart';

/// An immutable pan/zoom camera value.
///
/// Flow→screen mapping is scale-then-translate:
/// `screen = offset + zoom * flow`.
@immutable
class LatticeViewportValue {
  const LatticeViewportValue({
    this.offset = Offset.zero,
    this.zoom = 1.0,
  });

  final Offset offset;
  final double zoom;

  LatticeViewportValue copyWith({Offset? offset, double? zoom}) {
    return LatticeViewportValue(
      offset: offset ?? this.offset,
      zoom: zoom ?? this.zoom,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'offset': <String, Object?>{'dx': offset.dx, 'dy': offset.dy},
      'zoom': zoom,
    };
  }

  factory LatticeViewportValue.fromJson(Map<String, Object?> json) {
    final offsetJson = json['offset'] as Map<String, dynamic>?;
    return LatticeViewportValue(
      offset: offsetJson == null
          ? Offset.zero
          : Offset(
              _finiteOrZero((offsetJson['dx'] as num?)?.toDouble() ?? 0.0),
              _finiteOrZero((offsetJson['dy'] as num?)?.toDouble() ?? 0.0),
            ),
      zoom: _finiteOrZero((json['zoom'] as num?)?.toDouble() ?? 1.0),
    );
  }

  /// Flow→screen transform: applying it to a flow point yields
  /// `offset + zoom * flow`.
  ///
  /// Built as translate-then-scale (`T * S`) so the translation stays
  /// unscaled. (Note: `scale(..)..translate(..)` would yield `S * T` and
  /// scale the translation by [zoom]; the round-trip and screen-mapping
  /// tests pin the `offset + zoom * flow` behavior.)
  Matrix4 toMatrix() {
    return Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0.0, 1.0)
      ..scaleByDouble(zoom, zoom, zoom, 1.0);
  }

  factory LatticeViewportValue.fromMatrix(Matrix4 m) {
    return LatticeViewportValue(
      offset: Offset(
        _finiteOrZero(m.storage[12]),
        _finiteOrZero(m.storage[13]),
      ),
      zoom: _finiteOrZero(m.storage[0]),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LatticeViewportValue &&
        other.offset == offset &&
        other.zoom == zoom;
  }

  @override
  int get hashCode => Object.hash(offset, zoom);
}

double _finiteOrZero(double value) => value.isFinite ? value : 0.0;
