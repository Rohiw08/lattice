// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edge_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$EdgeRuntimeState {
  /// Whether this edge is currently valid (e.g., connection rules pass).
  bool get valid;

  /// Whether the edge is highlighted as selected.
  bool get selected;

  /// Whether the edge is being hovered over (UI effect trigger).
  bool get hovered;

  /// Whether the edge has an active animation effect running.
  bool get animating;

  /// Whether the edge is currently being reconnected to another node.
  bool get reconnecting;

  /// Create a copy of EdgeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EdgeRuntimeStateCopyWith<EdgeRuntimeState> get copyWith =>
      _$EdgeRuntimeStateCopyWithImpl<EdgeRuntimeState>(
          this as EdgeRuntimeState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EdgeRuntimeState &&
            (identical(other.valid, valid) || other.valid == valid) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.animating, animating) ||
                other.animating == animating) &&
            (identical(other.reconnecting, reconnecting) ||
                other.reconnecting == reconnecting));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, valid, selected, hovered, animating, reconnecting);

  @override
  String toString() {
    return 'EdgeRuntimeState(valid: $valid, selected: $selected, hovered: $hovered, animating: $animating, reconnecting: $reconnecting)';
  }
}

/// @nodoc
abstract mixin class $EdgeRuntimeStateCopyWith<$Res> {
  factory $EdgeRuntimeStateCopyWith(
          EdgeRuntimeState value, $Res Function(EdgeRuntimeState) _then) =
      _$EdgeRuntimeStateCopyWithImpl;
  @useResult
  $Res call(
      {bool valid,
      bool selected,
      bool hovered,
      bool animating,
      bool reconnecting});
}

/// @nodoc
class _$EdgeRuntimeStateCopyWithImpl<$Res>
    implements $EdgeRuntimeStateCopyWith<$Res> {
  _$EdgeRuntimeStateCopyWithImpl(this._self, this._then);

  final EdgeRuntimeState _self;
  final $Res Function(EdgeRuntimeState) _then;

  /// Create a copy of EdgeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? valid = null,
    Object? selected = null,
    Object? hovered = null,
    Object? animating = null,
    Object? reconnecting = null,
  }) {
    return _then(_self.copyWith(
      valid: null == valid
          ? _self.valid
          : valid // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      animating: null == animating
          ? _self.animating
          : animating // ignore: cast_nullable_to_non_nullable
              as bool,
      reconnecting: null == reconnecting
          ? _self.reconnecting
          : reconnecting // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [EdgeRuntimeState].
extension EdgeRuntimeStatePatterns on EdgeRuntimeState {
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
    TResult Function(_EdgeRuntimeState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState() when $default != null:
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
    TResult Function(_EdgeRuntimeState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState():
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
    TResult? Function(_EdgeRuntimeState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState() when $default != null:
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
    TResult Function(bool valid, bool selected, bool hovered, bool animating,
            bool reconnecting)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState() when $default != null:
        return $default(_that.valid, _that.selected, _that.hovered,
            _that.animating, _that.reconnecting);
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
    TResult Function(bool valid, bool selected, bool hovered, bool animating,
            bool reconnecting)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState():
        return $default(_that.valid, _that.selected, _that.hovered,
            _that.animating, _that.reconnecting);
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
    TResult? Function(bool valid, bool selected, bool hovered, bool animating,
            bool reconnecting)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _EdgeRuntimeState() when $default != null:
        return $default(_that.valid, _that.selected, _that.hovered,
            _that.animating, _that.reconnecting);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _EdgeRuntimeState implements EdgeRuntimeState {
  const _EdgeRuntimeState(
      {this.valid = true,
      this.selected = false,
      this.hovered = false,
      this.animating = false,
      this.reconnecting = false});

  /// Whether this edge is currently valid (e.g., connection rules pass).
  @override
  @JsonKey()
  final bool valid;

  /// Whether the edge is highlighted as selected.
  @override
  @JsonKey()
  final bool selected;

  /// Whether the edge is being hovered over (UI effect trigger).
  @override
  @JsonKey()
  final bool hovered;

  /// Whether the edge has an active animation effect running.
  @override
  @JsonKey()
  final bool animating;

  /// Whether the edge is currently being reconnected to another node.
  @override
  @JsonKey()
  final bool reconnecting;

  /// Create a copy of EdgeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$EdgeRuntimeStateCopyWith<_EdgeRuntimeState> get copyWith =>
      __$EdgeRuntimeStateCopyWithImpl<_EdgeRuntimeState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _EdgeRuntimeState &&
            (identical(other.valid, valid) || other.valid == valid) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.animating, animating) ||
                other.animating == animating) &&
            (identical(other.reconnecting, reconnecting) ||
                other.reconnecting == reconnecting));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, valid, selected, hovered, animating, reconnecting);

  @override
  String toString() {
    return 'EdgeRuntimeState(valid: $valid, selected: $selected, hovered: $hovered, animating: $animating, reconnecting: $reconnecting)';
  }
}

/// @nodoc
abstract mixin class _$EdgeRuntimeStateCopyWith<$Res>
    implements $EdgeRuntimeStateCopyWith<$Res> {
  factory _$EdgeRuntimeStateCopyWith(
          _EdgeRuntimeState value, $Res Function(_EdgeRuntimeState) _then) =
      __$EdgeRuntimeStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool valid,
      bool selected,
      bool hovered,
      bool animating,
      bool reconnecting});
}

/// @nodoc
class __$EdgeRuntimeStateCopyWithImpl<$Res>
    implements _$EdgeRuntimeStateCopyWith<$Res> {
  __$EdgeRuntimeStateCopyWithImpl(this._self, this._then);

  final _EdgeRuntimeState _self;
  final $Res Function(_EdgeRuntimeState) _then;

  /// Create a copy of EdgeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? valid = null,
    Object? selected = null,
    Object? hovered = null,
    Object? animating = null,
    Object? reconnecting = null,
  }) {
    return _then(_EdgeRuntimeState(
      valid: null == valid
          ? _self.valid
          : valid // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      animating: null == animating
          ? _self.animating
          : animating // ignore: cast_nullable_to_non_nullable
              as bool,
      reconnecting: null == reconnecting
          ? _self.reconnecting
          : reconnecting // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
