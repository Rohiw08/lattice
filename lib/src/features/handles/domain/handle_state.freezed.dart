// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'handle_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HandleRuntimeState {
  /// Whether the handle is being hovered over.
  bool get hovered;

  /// Click-to-connect source (`connectOnClick` / Lattice `clickconnecting`).
  bool get selected;

  /// Whether this handle is currently active in a connection drag.
  bool get active;

  /// Whether the handle is a valid target for the active connection.
  bool get validTarget;

  /// Whether the handle is an invalid target under the pointer.
  bool get invalidTarget;

  /// The number of edges currently connected to this handle.
  int get connectionCount;

  /// The IDs of connected edges (for fast graph lookup).
  List<String> get connectedEdgeIds;

  /// Whether the handle is playing an animation (e.g., pulsing).
  bool get animating;

  /// Create a copy of HandleRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HandleRuntimeStateCopyWith<HandleRuntimeState> get copyWith =>
      _$HandleRuntimeStateCopyWithImpl<HandleRuntimeState>(
          this as HandleRuntimeState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HandleRuntimeState &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.validTarget, validTarget) ||
                other.validTarget == validTarget) &&
            (identical(other.invalidTarget, invalidTarget) ||
                other.invalidTarget == invalidTarget) &&
            (identical(other.connectionCount, connectionCount) ||
                other.connectionCount == connectionCount) &&
            const DeepCollectionEquality()
                .equals(other.connectedEdgeIds, connectedEdgeIds) &&
            (identical(other.animating, animating) ||
                other.animating == animating));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      hovered,
      selected,
      active,
      validTarget,
      invalidTarget,
      connectionCount,
      const DeepCollectionEquality().hash(connectedEdgeIds),
      animating);

  @override
  String toString() {
    return 'HandleRuntimeState(hovered: $hovered, selected: $selected, active: $active, validTarget: $validTarget, invalidTarget: $invalidTarget, connectionCount: $connectionCount, connectedEdgeIds: $connectedEdgeIds, animating: $animating)';
  }
}

/// @nodoc
abstract mixin class $HandleRuntimeStateCopyWith<$Res> {
  factory $HandleRuntimeStateCopyWith(
          HandleRuntimeState value, $Res Function(HandleRuntimeState) _then) =
      _$HandleRuntimeStateCopyWithImpl;
  @useResult
  $Res call(
      {bool hovered,
      bool selected,
      bool active,
      bool validTarget,
      bool invalidTarget,
      int connectionCount,
      List<String> connectedEdgeIds,
      bool animating});
}

/// @nodoc
class _$HandleRuntimeStateCopyWithImpl<$Res>
    implements $HandleRuntimeStateCopyWith<$Res> {
  _$HandleRuntimeStateCopyWithImpl(this._self, this._then);

  final HandleRuntimeState _self;
  final $Res Function(HandleRuntimeState) _then;

  /// Create a copy of HandleRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? hovered = null,
    Object? selected = null,
    Object? active = null,
    Object? validTarget = null,
    Object? invalidTarget = null,
    Object? connectionCount = null,
    Object? connectedEdgeIds = null,
    Object? animating = null,
  }) {
    return _then(_self.copyWith(
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _self.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      validTarget: null == validTarget
          ? _self.validTarget
          : validTarget // ignore: cast_nullable_to_non_nullable
              as bool,
      invalidTarget: null == invalidTarget
          ? _self.invalidTarget
          : invalidTarget // ignore: cast_nullable_to_non_nullable
              as bool,
      connectionCount: null == connectionCount
          ? _self.connectionCount
          : connectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      connectedEdgeIds: null == connectedEdgeIds
          ? _self.connectedEdgeIds
          : connectedEdgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      animating: null == animating
          ? _self.animating
          : animating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [HandleRuntimeState].
extension HandleRuntimeStatePatterns on HandleRuntimeState {
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
    TResult Function(_HandleRuntimeState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState() when $default != null:
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
    TResult Function(_HandleRuntimeState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState():
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
    TResult? Function(_HandleRuntimeState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState() when $default != null:
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
            bool hovered,
            bool selected,
            bool active,
            bool validTarget,
            bool invalidTarget,
            int connectionCount,
            List<String> connectedEdgeIds,
            bool animating)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState() when $default != null:
        return $default(
            _that.hovered,
            _that.selected,
            _that.active,
            _that.validTarget,
            _that.invalidTarget,
            _that.connectionCount,
            _that.connectedEdgeIds,
            _that.animating);
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
            bool hovered,
            bool selected,
            bool active,
            bool validTarget,
            bool invalidTarget,
            int connectionCount,
            List<String> connectedEdgeIds,
            bool animating)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState():
        return $default(
            _that.hovered,
            _that.selected,
            _that.active,
            _that.validTarget,
            _that.invalidTarget,
            _that.connectionCount,
            _that.connectedEdgeIds,
            _that.animating);
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
            bool hovered,
            bool selected,
            bool active,
            bool validTarget,
            bool invalidTarget,
            int connectionCount,
            List<String> connectedEdgeIds,
            bool animating)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HandleRuntimeState() when $default != null:
        return $default(
            _that.hovered,
            _that.selected,
            _that.active,
            _that.validTarget,
            _that.invalidTarget,
            _that.connectionCount,
            _that.connectedEdgeIds,
            _that.animating);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _HandleRuntimeState implements HandleRuntimeState {
  const _HandleRuntimeState(
      {this.hovered = false,
      this.selected = false,
      this.active = false,
      this.validTarget = false,
      this.invalidTarget = false,
      this.connectionCount = 0,
      final List<String> connectedEdgeIds = const <String>[],
      this.animating = false})
      : _connectedEdgeIds = connectedEdgeIds;

  /// Whether the handle is being hovered over.
  @override
  @JsonKey()
  final bool hovered;

  /// Click-to-connect source (`connectOnClick` / Lattice `clickconnecting`).
  @override
  @JsonKey()
  final bool selected;

  /// Whether this handle is currently active in a connection drag.
  @override
  @JsonKey()
  final bool active;

  /// Whether the handle is a valid target for the active connection.
  @override
  @JsonKey()
  final bool validTarget;

  /// Whether the handle is an invalid target under the pointer.
  @override
  @JsonKey()
  final bool invalidTarget;

  /// The number of edges currently connected to this handle.
  @override
  @JsonKey()
  final int connectionCount;

  /// The IDs of connected edges (for fast graph lookup).
  final List<String> _connectedEdgeIds;

  /// The IDs of connected edges (for fast graph lookup).
  @override
  @JsonKey()
  List<String> get connectedEdgeIds {
    if (_connectedEdgeIds is EqualUnmodifiableListView)
      return _connectedEdgeIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_connectedEdgeIds);
  }

  /// Whether the handle is playing an animation (e.g., pulsing).
  @override
  @JsonKey()
  final bool animating;

  /// Create a copy of HandleRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HandleRuntimeStateCopyWith<_HandleRuntimeState> get copyWith =>
      __$HandleRuntimeStateCopyWithImpl<_HandleRuntimeState>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HandleRuntimeState &&
            (identical(other.hovered, hovered) || other.hovered == hovered) &&
            (identical(other.selected, selected) ||
                other.selected == selected) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.validTarget, validTarget) ||
                other.validTarget == validTarget) &&
            (identical(other.invalidTarget, invalidTarget) ||
                other.invalidTarget == invalidTarget) &&
            (identical(other.connectionCount, connectionCount) ||
                other.connectionCount == connectionCount) &&
            const DeepCollectionEquality()
                .equals(other._connectedEdgeIds, _connectedEdgeIds) &&
            (identical(other.animating, animating) ||
                other.animating == animating));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      hovered,
      selected,
      active,
      validTarget,
      invalidTarget,
      connectionCount,
      const DeepCollectionEquality().hash(_connectedEdgeIds),
      animating);

  @override
  String toString() {
    return 'HandleRuntimeState(hovered: $hovered, selected: $selected, active: $active, validTarget: $validTarget, invalidTarget: $invalidTarget, connectionCount: $connectionCount, connectedEdgeIds: $connectedEdgeIds, animating: $animating)';
  }
}

/// @nodoc
abstract mixin class _$HandleRuntimeStateCopyWith<$Res>
    implements $HandleRuntimeStateCopyWith<$Res> {
  factory _$HandleRuntimeStateCopyWith(
          _HandleRuntimeState value, $Res Function(_HandleRuntimeState) _then) =
      __$HandleRuntimeStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool hovered,
      bool selected,
      bool active,
      bool validTarget,
      bool invalidTarget,
      int connectionCount,
      List<String> connectedEdgeIds,
      bool animating});
}

/// @nodoc
class __$HandleRuntimeStateCopyWithImpl<$Res>
    implements _$HandleRuntimeStateCopyWith<$Res> {
  __$HandleRuntimeStateCopyWithImpl(this._self, this._then);

  final _HandleRuntimeState _self;
  final $Res Function(_HandleRuntimeState) _then;

  /// Create a copy of HandleRuntimeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? hovered = null,
    Object? selected = null,
    Object? active = null,
    Object? validTarget = null,
    Object? invalidTarget = null,
    Object? connectionCount = null,
    Object? connectedEdgeIds = null,
    Object? animating = null,
  }) {
    return _then(_HandleRuntimeState(
      hovered: null == hovered
          ? _self.hovered
          : hovered // ignore: cast_nullable_to_non_nullable
              as bool,
      selected: null == selected
          ? _self.selected
          : selected // ignore: cast_nullable_to_non_nullable
              as bool,
      active: null == active
          ? _self.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool,
      validTarget: null == validTarget
          ? _self.validTarget
          : validTarget // ignore: cast_nullable_to_non_nullable
              as bool,
      invalidTarget: null == invalidTarget
          ? _self.invalidTarget
          : invalidTarget // ignore: cast_nullable_to_non_nullable
              as bool,
      connectionCount: null == connectionCount
          ? _self.connectionCount
          : connectionCount // ignore: cast_nullable_to_non_nullable
              as int,
      connectedEdgeIds: null == connectedEdgeIds
          ? _self._connectedEdgeIds
          : connectedEdgeIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      animating: null == animating
          ? _self.animating
          : animating // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
