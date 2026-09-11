// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'connection_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowConnectionRuntimeState {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlowConnectionRuntimeState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlowConnectionRuntimeState()';
  }
}

/// @nodoc
class $FlowConnectionRuntimeStateCopyWith<$Res> {
  $FlowConnectionRuntimeStateCopyWith(FlowConnectionRuntimeState _,
      $Res Function(FlowConnectionRuntimeState) __);
}

/// Adds pattern-matching-related methods to [FlowConnectionRuntimeState].
extension FlowConnectionRuntimeStatePatterns on FlowConnectionRuntimeState {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(IdleConnectionState value)? idle,
    TResult Function(HoveringConnectionState value)? hovering,
    TResult Function(ReleasedConnectionState value)? released,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState() when idle != null:
        return idle(_that);
      case HoveringConnectionState() when hovering != null:
        return hovering(_that);
      case ReleasedConnectionState() when released != null:
        return released(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(IdleConnectionState value) idle,
    required TResult Function(HoveringConnectionState value) hovering,
    required TResult Function(ReleasedConnectionState value) released,
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState():
        return idle(_that);
      case HoveringConnectionState():
        return hovering(_that);
      case ReleasedConnectionState():
        return released(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(IdleConnectionState value)? idle,
    TResult? Function(HoveringConnectionState value)? hovering,
    TResult? Function(ReleasedConnectionState value)? released,
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState() when idle != null:
        return idle(_that);
      case HoveringConnectionState() when hovering != null:
        return hovering(_that);
      case ReleasedConnectionState() when released != null:
        return released(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? idle,
    TResult Function(String targetHandleKey, bool isValid)? hovering,
    TResult Function(String? targetHandleKey, bool isValid)? released,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState() when idle != null:
        return idle();
      case HoveringConnectionState() when hovering != null:
        return hovering(_that.targetHandleKey, _that.isValid);
      case ReleasedConnectionState() when released != null:
        return released(_that.targetHandleKey, _that.isValid);
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
  TResult when<TResult extends Object?>({
    required TResult Function() idle,
    required TResult Function(String targetHandleKey, bool isValid) hovering,
    required TResult Function(String? targetHandleKey, bool isValid) released,
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState():
        return idle();
      case HoveringConnectionState():
        return hovering(_that.targetHandleKey, _that.isValid);
      case ReleasedConnectionState():
        return released(_that.targetHandleKey, _that.isValid);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? idle,
    TResult? Function(String targetHandleKey, bool isValid)? hovering,
    TResult? Function(String? targetHandleKey, bool isValid)? released,
  }) {
    final _that = this;
    switch (_that) {
      case IdleConnectionState() when idle != null:
        return idle();
      case HoveringConnectionState() when hovering != null:
        return hovering(_that.targetHandleKey, _that.isValid);
      case ReleasedConnectionState() when released != null:
        return released(_that.targetHandleKey, _that.isValid);
      case _:
        return null;
    }
  }
}

/// @nodoc

class IdleConnectionState implements FlowConnectionRuntimeState {
  const IdleConnectionState();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is IdleConnectionState);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'FlowConnectionRuntimeState.idle()';
  }
}

/// @nodoc

class HoveringConnectionState implements FlowConnectionRuntimeState {
  const HoveringConnectionState(
      {required this.targetHandleKey, this.isValid = false});

  final String targetHandleKey;
  @JsonKey()
  final bool isValid;

  /// Create a copy of FlowConnectionRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HoveringConnectionStateCopyWith<HoveringConnectionState> get copyWith =>
      _$HoveringConnectionStateCopyWithImpl<HoveringConnectionState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HoveringConnectionState &&
            (identical(other.targetHandleKey, targetHandleKey) ||
                other.targetHandleKey == targetHandleKey) &&
            (identical(other.isValid, isValid) || other.isValid == isValid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetHandleKey, isValid);

  @override
  String toString() {
    return 'FlowConnectionRuntimeState.hovering(targetHandleKey: $targetHandleKey, isValid: $isValid)';
  }
}

/// @nodoc
abstract mixin class $HoveringConnectionStateCopyWith<$Res>
    implements $FlowConnectionRuntimeStateCopyWith<$Res> {
  factory $HoveringConnectionStateCopyWith(HoveringConnectionState value,
          $Res Function(HoveringConnectionState) _then) =
      _$HoveringConnectionStateCopyWithImpl;
  @useResult
  $Res call({String targetHandleKey, bool isValid});
}

/// @nodoc
class _$HoveringConnectionStateCopyWithImpl<$Res>
    implements $HoveringConnectionStateCopyWith<$Res> {
  _$HoveringConnectionStateCopyWithImpl(this._self, this._then);

  final HoveringConnectionState _self;
  final $Res Function(HoveringConnectionState) _then;

  /// Create a copy of FlowConnectionRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? targetHandleKey = null,
    Object? isValid = null,
  }) {
    return _then(HoveringConnectionState(
      targetHandleKey: null == targetHandleKey
          ? _self.targetHandleKey
          : targetHandleKey // ignore: cast_nullable_to_non_nullable
              as String,
      isValid: null == isValid
          ? _self.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class ReleasedConnectionState implements FlowConnectionRuntimeState {
  const ReleasedConnectionState({this.targetHandleKey, this.isValid = false});

  final String? targetHandleKey;
  @JsonKey()
  final bool isValid;

  /// Create a copy of FlowConnectionRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReleasedConnectionStateCopyWith<ReleasedConnectionState> get copyWith =>
      _$ReleasedConnectionStateCopyWithImpl<ReleasedConnectionState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReleasedConnectionState &&
            (identical(other.targetHandleKey, targetHandleKey) ||
                other.targetHandleKey == targetHandleKey) &&
            (identical(other.isValid, isValid) || other.isValid == isValid));
  }

  @override
  int get hashCode => Object.hash(runtimeType, targetHandleKey, isValid);

  @override
  String toString() {
    return 'FlowConnectionRuntimeState.released(targetHandleKey: $targetHandleKey, isValid: $isValid)';
  }
}

/// @nodoc
abstract mixin class $ReleasedConnectionStateCopyWith<$Res>
    implements $FlowConnectionRuntimeStateCopyWith<$Res> {
  factory $ReleasedConnectionStateCopyWith(ReleasedConnectionState value,
          $Res Function(ReleasedConnectionState) _then) =
      _$ReleasedConnectionStateCopyWithImpl;
  @useResult
  $Res call({String? targetHandleKey, bool isValid});
}

/// @nodoc
class _$ReleasedConnectionStateCopyWithImpl<$Res>
    implements $ReleasedConnectionStateCopyWith<$Res> {
  _$ReleasedConnectionStateCopyWithImpl(this._self, this._then);

  final ReleasedConnectionState _self;
  final $Res Function(ReleasedConnectionState) _then;

  /// Create a copy of FlowConnectionRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? targetHandleKey = freezed,
    Object? isValid = null,
  }) {
    return _then(ReleasedConnectionState(
      targetHandleKey: freezed == targetHandleKey
          ? _self.targetHandleKey
          : targetHandleKey // ignore: cast_nullable_to_non_nullable
              as String?,
      isValid: null == isValid
          ? _self.isValid
          : isValid // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
