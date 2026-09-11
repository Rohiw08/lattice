// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'viewport.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowViewport {
  @OffsetConverter()
  @JsonKey(includeFromJson: true, includeToJson: true)
  Offset get offset;
  @JsonKey(includeFromJson: true, includeToJson: true)
  double get zoom;

  /// Create a copy of FlowViewport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FlowViewportCopyWith<FlowViewport> get copyWith =>
      _$FlowViewportCopyWithImpl<FlowViewport>(
          this as FlowViewport, _$identity);

  /// Serializes this FlowViewport to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlowViewport &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.zoom, zoom) || other.zoom == zoom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, offset, zoom);

  @override
  String toString() {
    return 'FlowViewport(offset: $offset, zoom: $zoom)';
  }
}

/// @nodoc
abstract mixin class $FlowViewportCopyWith<$Res> {
  factory $FlowViewportCopyWith(
          FlowViewport value, $Res Function(FlowViewport) _then) =
      _$FlowViewportCopyWithImpl;
  @useResult
  $Res call(
      {@OffsetConverter()
      @JsonKey(includeFromJson: true, includeToJson: true)
      Offset offset,
      @JsonKey(includeFromJson: true, includeToJson: true) double zoom});
}

/// @nodoc
class _$FlowViewportCopyWithImpl<$Res> implements $FlowViewportCopyWith<$Res> {
  _$FlowViewportCopyWithImpl(this._self, this._then);

  final FlowViewport _self;
  final $Res Function(FlowViewport) _then;

  /// Create a copy of FlowViewport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? offset = null,
    Object? zoom = null,
  }) {
    return _then(_self.copyWith(
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
      zoom: null == zoom
          ? _self.zoom
          : zoom // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [FlowViewport].
extension FlowViewportPatterns on FlowViewport {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_FlowViewport value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowViewport() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_FlowViewport value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowViewport():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_FlowViewport value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowViewport() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            @OffsetConverter()
            @JsonKey(includeFromJson: true, includeToJson: true)
            Offset offset,
            @JsonKey(includeFromJson: true, includeToJson: true) double zoom)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowViewport() when $default != null:
        return $default(_that.offset, _that.zoom);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            @OffsetConverter()
            @JsonKey(includeFromJson: true, includeToJson: true)
            Offset offset,
            @JsonKey(includeFromJson: true, includeToJson: true) double zoom)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowViewport():
        return $default(_that.offset, _that.zoom);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            @OffsetConverter()
            @JsonKey(includeFromJson: true, includeToJson: true)
            Offset offset,
            @JsonKey(includeFromJson: true, includeToJson: true) double zoom)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowViewport() when $default != null:
        return $default(_that.offset, _that.zoom);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FlowViewport implements FlowViewport {
  const _FlowViewport(
      {@OffsetConverter()
      @JsonKey(includeFromJson: true, includeToJson: true)
      this.offset = Offset.zero,
      @JsonKey(includeFromJson: true, includeToJson: true) this.zoom = 1.0});
  factory _FlowViewport.fromJson(Map<String, dynamic> json) =>
      _$FlowViewportFromJson(json);

  @override
  @OffsetConverter()
  @JsonKey(includeFromJson: true, includeToJson: true)
  final Offset offset;
  @override
  @JsonKey(includeFromJson: true, includeToJson: true)
  final double zoom;

  /// Create a copy of FlowViewport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FlowViewportCopyWith<_FlowViewport> get copyWith =>
      __$FlowViewportCopyWithImpl<_FlowViewport>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FlowViewportToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FlowViewport &&
            (identical(other.offset, offset) || other.offset == offset) &&
            (identical(other.zoom, zoom) || other.zoom == zoom));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, offset, zoom);

  @override
  String toString() {
    return 'FlowViewport(offset: $offset, zoom: $zoom)';
  }
}

/// @nodoc
abstract mixin class _$FlowViewportCopyWith<$Res>
    implements $FlowViewportCopyWith<$Res> {
  factory _$FlowViewportCopyWith(
          _FlowViewport value, $Res Function(_FlowViewport) _then) =
      __$FlowViewportCopyWithImpl;
  @override
  @useResult
  $Res call(
      {@OffsetConverter()
      @JsonKey(includeFromJson: true, includeToJson: true)
      Offset offset,
      @JsonKey(includeFromJson: true, includeToJson: true) double zoom});
}

/// @nodoc
class __$FlowViewportCopyWithImpl<$Res>
    implements _$FlowViewportCopyWith<$Res> {
  __$FlowViewportCopyWithImpl(this._self, this._then);

  final _FlowViewport _self;
  final $Res Function(_FlowViewport) _then;

  /// Create a copy of FlowViewport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? offset = null,
    Object? zoom = null,
  }) {
    return _then(_FlowViewport(
      offset: null == offset
          ? _self.offset
          : offset // ignore: cast_nullable_to_non_nullable
              as Offset,
      zoom: null == zoom
          ? _self.zoom
          : zoom // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

// dart format on
