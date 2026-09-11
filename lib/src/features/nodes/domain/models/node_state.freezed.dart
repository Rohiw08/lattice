// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NodeRuntimeState {
  bool get selected;
  bool get hovered;
  bool get dragging;
  bool get resizing;
  Rect? get extent;

  /// Create a copy of NodeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NodeRuntimeStateCopyWith<NodeRuntimeState> get copyWith =>
      _$NodeRuntimeStateCopyWithImpl<NodeRuntimeState>(
          this as NodeRuntimeState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NodeRuntimeState &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.dragging, dragging) ||
                other.dragging == dragging) &&
            (identical(other.resizing, resizing) ||
                other.resizing == resizing) &&
            (identical(other.extent, extent) || other.extent == extent));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, selected, hovered, dragging, resizing, extent);

  @override
  String toString() {
    return 'NodeRuntimeState(selected: $selected, hovered: $hovered, dragging: $dragging, resizing: $resizing, extent: $extent)';
  }
}

/// @nodoc
abstract mixin class $NodeRuntimeStateCopyWith<$Res> {
  factory $NodeRuntimeStateCopyWith(
          NodeRuntimeState value, $Res Function(NodeRuntimeState) _then) =
      _$NodeRuntimeStateCopyWithImpl;
  @useResult
  $Res call(
      {bool selected,
      bool hovered,
      bool dragging,
      bool resizing,
      Rect? extent});
}

/// @nodoc
class _$NodeRuntimeStateCopyWithImpl<$Res>
    implements $NodeRuntimeStateCopyWith<$Res> {
  _$NodeRuntimeStateCopyWithImpl(this._self, this._then);

  final NodeRuntimeState _self;
  final $Res Function(NodeRuntimeState) _then;

  /// Create a copy of NodeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selected = null,
    Object? hovered = null,
    Object? dragging = null,
    Object? resizing = null,
    Object? extent = freezed,
  }) {
    return _then(_self.copyWith(
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      dragging: null == dragging
          ? _self.dragging
          : dragging // ignore: cast_nullable_to_non_nullable
              as bool,
      resizing: null == resizing
          ? _self.resizing
          : resizing // ignore: cast_nullable_to_non_nullable
              as bool,
      extent: freezed == extent
          ? _self.extent
          : extent // ignore: cast_nullable_to_non_nullable
              as Rect?,
    ));
  }
}

/// Adds pattern-matching-related methods to [NodeRuntimeState].
extension NodeRuntimeStatePatterns on NodeRuntimeState {
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
    TResult Function(_NodeRuntimeState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState() when $default != null:
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
    TResult Function(_NodeRuntimeState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState():
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
    TResult? Function(_NodeRuntimeState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState() when $default != null:
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
    TResult Function(bool selected, bool hovered, bool dragging, bool resizing,
            Rect? extent)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState() when $default != null:
        return $default(_that.selected, _that.hovered, _that.dragging,
            _that.resizing, _that.extent);
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
    TResult Function(bool selected, bool hovered, bool dragging, bool resizing,
            Rect? extent)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState():
        return $default(_that.selected, _that.hovered, _that.dragging,
            _that.resizing, _that.extent);
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
    TResult? Function(bool selected, bool hovered, bool dragging, bool resizing,
            Rect? extent)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NodeRuntimeState() when $default != null:
        return $default(_that.selected, _that.hovered, _that.dragging,
            _that.resizing, _that.extent);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _NodeRuntimeState implements NodeRuntimeState {
  const _NodeRuntimeState(
      {this.selected = false,
      this.hovered = false,
      this.dragging = false,
      this.resizing = false,
      this.extent});

  @override
  @JsonKey()
  final bool selected;
  @override
  @JsonKey()
  final bool hovered;
  @override
  @JsonKey()
  final bool dragging;
  @override
  @JsonKey()
  final bool resizing;
  @override
  final Rect? extent;

  /// Create a copy of NodeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NodeRuntimeStateCopyWith<_NodeRuntimeState> get copyWith =>
      __$NodeRuntimeStateCopyWithImpl<_NodeRuntimeState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NodeRuntimeState &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.dragging, dragging) ||
                other.dragging == dragging) &&
            (identical(other.resizing, resizing) ||
                other.resizing == resizing) &&
            (identical(other.extent, extent) || other.extent == extent));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, selected, hovered, dragging, resizing, extent);

  @override
  String toString() {
    return 'NodeRuntimeState(selected: $selected, hovered: $hovered, dragging: $dragging, resizing: $resizing, extent: $extent)';
  }
}

/// @nodoc
abstract mixin class _$NodeRuntimeStateCopyWith<$Res>
    implements $NodeRuntimeStateCopyWith<$Res> {
  factory _$NodeRuntimeStateCopyWith(
          _NodeRuntimeState value, $Res Function(_NodeRuntimeState) _then) =
      __$NodeRuntimeStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool selected,
      bool hovered,
      bool dragging,
      bool resizing,
      Rect? extent});
}

/// @nodoc
class __$NodeRuntimeStateCopyWithImpl<$Res>
    implements _$NodeRuntimeStateCopyWith<$Res> {
  __$NodeRuntimeStateCopyWithImpl(this._self, this._then);

  final _NodeRuntimeState _self;
  final $Res Function(_NodeRuntimeState) _then;

  /// Create a copy of NodeRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? selected = null,
    Object? hovered = null,
    Object? dragging = null,
    Object? resizing = null,
    Object? extent = freezed,
  }) {
    return _then(_NodeRuntimeState(
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      dragging: null == dragging
          ? _self.dragging
          : dragging // ignore: cast_nullable_to_non_nullable
              as bool,
      resizing: null == resizing
          ? _self.resizing
          : resizing // ignore: cast_nullable_to_non_nullable
              as bool,
      extent: freezed == extent
          ? _self.extent
          : extent // ignore: cast_nullable_to_non_nullable
              as Rect?,
    ));
  }
}

// dart format on
