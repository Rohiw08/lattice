// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'handle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowHandle implements DiagnosticableTreeMixin {
  /// Unique identifier for this handle within its parent node.
  ///
  /// Common patterns:
  /// - 'input', 'output' for single handles
  /// - 'input-1', 'input-2' for multiple handles
  /// - 'port-a', 'port-b' for named ports
  String get id;

  /// The type of handle (source or target).
  ///
  /// - [HandleType.source]: Output handle (edges originate here)
  /// - [HandleType.target]: Input handle (edges terminate here)
  HandleType get type;

  /// Position of the handle's center relative to the node's top-left corner.
  ///
  /// Example positions:
  /// - Left side: Offset(0, nodeHeight / 2)
  /// - Right side: Offset(nodeWidth, nodeHeight / 2)
  /// - Top: Offset(nodeWidth / 2, 0)
  @OffsetConverter()
  Offset get position;

  /// Whether this handle can accept new connections.
  ///
  /// When false, users cannot create or connect edges to this handle.
  /// Existing connections remain intact.
  ///
  /// Use cases for false:
  /// - Maximum connections reached
  /// - Handle is disabled/inactive
  /// - Connection validation fails
  ///
  /// Default is true.
  bool get isConnectable;

  /// The size of the handle's interaction area.
  ///
  /// Defines the clickable/hoverable region. The actual visual representation
  /// may be smaller. Typical values: 8-16 pixels.
  ///
  /// Default is Size(10, 10).
  @SizeConverter()
  Size get size;

  /// Optional maximum number of connections allowed to this handle.
  ///
  /// When reached, [isConnectable] should be set to false.
  ///
  /// Examples:
  /// - null: Unlimited connections (default)
  /// - 1: Single connection only
  /// - 5: Up to 5 connections
  int? get maxConnections;

  /// Optional validation group/category for this handle.
  ///
  /// Handles can only connect if their groups are compatible.
  /// Use this for type-safe connections (e.g., 'number', 'string', 'any').
  ///
  /// Examples:
  /// - null: Can connect to any handle (default)
  /// - 'data': Only connects to other 'data' handles
  /// - 'flow': Only connects to other 'flow' handles
  String? get connectionGroup;

  /// Optional custom data attached to this handle.
  ///
  /// Store application-specific metadata like port names, data types, etc.
  Map<String, dynamic> get data;

  /// Create a copy of FlowHandle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FlowHandleCopyWith<FlowHandle> get copyWith =>
      _$FlowHandleCopyWithImpl<FlowHandle>(this as FlowHandle, _$identity);

  /// Serializes this FlowHandle to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'FlowHandle'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('position', position))
      ..add(DiagnosticsProperty('isConnectable', isConnectable))
      ..add(DiagnosticsProperty('size', size))
      ..add(DiagnosticsProperty('maxConnections', maxConnections))
      ..add(DiagnosticsProperty('connectionGroup', connectionGroup))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlowHandle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.isConnectable, isConnectable) ||
                other.isConnectable == isConnectable) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.maxConnections, maxConnections) ||
                other.maxConnections == maxConnections) &&
            (identical(other.connectionGroup, connectionGroup) ||
                other.connectionGroup == connectionGroup) &&
            const DeepCollectionEquality().equals(other.data, data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      position,
      isConnectable,
      size,
      maxConnections,
      connectionGroup,
      const DeepCollectionEquality().hash(data));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowHandle(id: $id, type: $type, position: $position, isConnectable: $isConnectable, size: $size, maxConnections: $maxConnections, connectionGroup: $connectionGroup, data: $data)';
  }
}

/// @nodoc
abstract mixin class $FlowHandleCopyWith<$Res> {
  factory $FlowHandleCopyWith(
          FlowHandle value, $Res Function(FlowHandle) _then) =
      _$FlowHandleCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      HandleType type,
      @OffsetConverter() Offset position,
      bool isConnectable,
      @SizeConverter() Size size,
      int? maxConnections,
      String? connectionGroup,
      Map<String, dynamic> data});
}

/// @nodoc
class _$FlowHandleCopyWithImpl<$Res> implements $FlowHandleCopyWith<$Res> {
  _$FlowHandleCopyWithImpl(this._self, this._then);

  final FlowHandle _self;
  final $Res Function(FlowHandle) _then;

  /// Create a copy of FlowHandle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? position = null,
    Object? isConnectable = null,
    Object? size = null,
    Object? maxConnections = freezed,
    Object? connectionGroup = freezed,
    Object? data = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as HandleType,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      isConnectable: null == isConnectable
          ? _self.isConnectable
          : isConnectable // ignore: cast_nullable_to_non_nullable
              as bool,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      maxConnections: freezed == maxConnections
          ? _self.maxConnections
          : maxConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      connectionGroup: freezed == connectionGroup
          ? _self.connectionGroup
          : connectionGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// Adds pattern-matching-related methods to [FlowHandle].
extension FlowHandlePatterns on FlowHandle {
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
    TResult Function(_FlowHandle value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowHandle() when $default != null:
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
    TResult Function(_FlowHandle value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowHandle():
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
    TResult? Function(_FlowHandle value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowHandle() when $default != null:
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
            String id,
            HandleType type,
            @OffsetConverter() Offset position,
            bool isConnectable,
            @SizeConverter() Size size,
            int? maxConnections,
            String? connectionGroup,
            Map<String, dynamic> data)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowHandle() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.position,
            _that.isConnectable,
            _that.size,
            _that.maxConnections,
            _that.connectionGroup,
            _that.data);
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
            String id,
            HandleType type,
            @OffsetConverter() Offset position,
            bool isConnectable,
            @SizeConverter() Size size,
            int? maxConnections,
            String? connectionGroup,
            Map<String, dynamic> data)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowHandle():
        return $default(
            _that.id,
            _that.type,
            _that.position,
            _that.isConnectable,
            _that.size,
            _that.maxConnections,
            _that.connectionGroup,
            _that.data);
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
            String id,
            HandleType type,
            @OffsetConverter() Offset position,
            bool isConnectable,
            @SizeConverter() Size size,
            int? maxConnections,
            String? connectionGroup,
            Map<String, dynamic> data)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowHandle() when $default != null:
        return $default(
            _that.id,
            _that.type,
            _that.position,
            _that.isConnectable,
            _that.size,
            _that.maxConnections,
            _that.connectionGroup,
            _that.data);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FlowHandle extends FlowHandle with DiagnosticableTreeMixin {
  const _FlowHandle(
      {required this.id,
      required this.type,
      @OffsetConverter() required this.position,
      this.isConnectable = true,
      @SizeConverter() this.size = const Size(10, 10),
      this.maxConnections,
      this.connectionGroup,
      final Map<String, dynamic> data = const <String, dynamic>{}})
      : _data = data,
        super._();
  factory _FlowHandle.fromJson(Map<String, dynamic> json) =>
      _$FlowHandleFromJson(json);

  /// Unique identifier for this handle within its parent node.
  ///
  /// Common patterns:
  /// - 'input', 'output' for single handles
  /// - 'input-1', 'input-2' for multiple handles
  /// - 'port-a', 'port-b' for named ports
  @override
  final String id;

  /// The type of handle (source or target).
  ///
  /// - [HandleType.source]: Output handle (edges originate here)
  /// - [HandleType.target]: Input handle (edges terminate here)
  @override
  final HandleType type;

  /// Position of the handle's center relative to the node's top-left corner.
  ///
  /// Example positions:
  /// - Left side: Offset(0, nodeHeight / 2)
  /// - Right side: Offset(nodeWidth, nodeHeight / 2)
  /// - Top: Offset(nodeWidth / 2, 0)
  @override
  @OffsetConverter()
  final Offset position;

  /// Whether this handle can accept new connections.
  ///
  /// When false, users cannot create or connect edges to this handle.
  /// Existing connections remain intact.
  ///
  /// Use cases for false:
  /// - Maximum connections reached
  /// - Handle is disabled/inactive
  /// - Connection validation fails
  ///
  /// Default is true.
  @override
  @JsonKey()
  final bool isConnectable;

  /// The size of the handle's interaction area.
  ///
  /// Defines the clickable/hoverable region. The actual visual representation
  /// may be smaller. Typical values: 8-16 pixels.
  ///
  /// Default is Size(10, 10).
  @override
  @JsonKey()
  @SizeConverter()
  final Size size;

  /// Optional maximum number of connections allowed to this handle.
  ///
  /// When reached, [isConnectable] should be set to false.
  ///
  /// Examples:
  /// - null: Unlimited connections (default)
  /// - 1: Single connection only
  /// - 5: Up to 5 connections
  @override
  final int? maxConnections;

  /// Optional validation group/category for this handle.
  ///
  /// Handles can only connect if their groups are compatible.
  /// Use this for type-safe connections (e.g., 'number', 'string', 'any').
  ///
  /// Examples:
  /// - null: Can connect to any handle (default)
  /// - 'data': Only connects to other 'data' handles
  /// - 'flow': Only connects to other 'flow' handles
  @override
  final String? connectionGroup;

  /// Optional custom data attached to this handle.
  ///
  /// Store application-specific metadata like port names, data types, etc.
  final Map<String, dynamic> _data;

  /// Optional custom data attached to this handle.
  ///
  /// Store application-specific metadata like port names, data types, etc.
  @override
  @JsonKey()
  Map<String, dynamic> get data {
    if (_data is EqualUnmodifiableMapView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_data);
  }

  /// Create a copy of FlowHandle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FlowHandleCopyWith<_FlowHandle> get copyWith =>
      __$FlowHandleCopyWithImpl<_FlowHandle>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FlowHandleToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'FlowHandle'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('type', type))
      ..add(DiagnosticsProperty('position', position))
      ..add(DiagnosticsProperty('isConnectable', isConnectable))
      ..add(DiagnosticsProperty('size', size))
      ..add(DiagnosticsProperty('maxConnections', maxConnections))
      ..add(DiagnosticsProperty('connectionGroup', connectionGroup))
      ..add(DiagnosticsProperty('data', data));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FlowHandle &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.isConnectable, isConnectable) ||
                other.isConnectable == isConnectable) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.maxConnections, maxConnections) ||
                other.maxConnections == maxConnections) &&
            (identical(other.connectionGroup, connectionGroup) ||
                other.connectionGroup == connectionGroup) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      position,
      isConnectable,
      size,
      maxConnections,
      connectionGroup,
      const DeepCollectionEquality().hash(_data));

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowHandle(id: $id, type: $type, position: $position, isConnectable: $isConnectable, size: $size, maxConnections: $maxConnections, connectionGroup: $connectionGroup, data: $data)';
  }
}

/// @nodoc
abstract mixin class _$FlowHandleCopyWith<$Res>
    implements $FlowHandleCopyWith<$Res> {
  factory _$FlowHandleCopyWith(
          _FlowHandle value, $Res Function(_FlowHandle) _then) =
      __$FlowHandleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      HandleType type,
      @OffsetConverter() Offset position,
      bool isConnectable,
      @SizeConverter() Size size,
      int? maxConnections,
      String? connectionGroup,
      Map<String, dynamic> data});
}

/// @nodoc
class __$FlowHandleCopyWithImpl<$Res> implements _$FlowHandleCopyWith<$Res> {
  __$FlowHandleCopyWithImpl(this._self, this._then);

  final _FlowHandle _self;
  final $Res Function(_FlowHandle) _then;

  /// Create a copy of FlowHandle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? position = null,
    Object? isConnectable = null,
    Object? size = null,
    Object? maxConnections = freezed,
    Object? connectionGroup = freezed,
    Object? data = null,
  }) {
    return _then(_FlowHandle(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as HandleType,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      isConnectable: null == isConnectable
          ? _self.isConnectable
          : isConnectable // ignore: cast_nullable_to_non_nullable
              as bool,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      maxConnections: freezed == maxConnections
          ? _self.maxConnections
          : maxConnections // ignore: cast_nullable_to_non_nullable
              as int?,
      connectionGroup: freezed == connectionGroup
          ? _self.connectionGroup
          : connectionGroup // ignore: cast_nullable_to_non_nullable
              as String?,
      data: null == data
          ? _self._data
          : data // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

// dart format on
