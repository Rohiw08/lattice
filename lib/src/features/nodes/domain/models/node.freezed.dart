// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowNode<T> {
  /// Unique identifier for this node.
  String get id;

  /// Optional ID of the parent node (for nested/grouped nodes).
  String? get parentId;

  /// Type identifier for this node (e.g., 'default', 'input', 'output').
  String get type;

  /// Node position in flow coordinates.
  ///
  /// When [parentId] is null this is absolute (graph space).
  /// When [parentId] is set this is **relative to the parent’s top-left**,
  /// matching Lattice sub-flows (`{ x: 0, y: 0 }` = parent origin).
  @OffsetConverter()
  Offset get position;

  /// Custom data attached to this node.
  ///
  /// Optional, like Lattice's `data` (defaults to `{}` there, `null`
  /// here). The built-in node widgets never render it — your node widget
  /// decides how (and whether) to display `props.data`.
  T? get data;

  /// Size of the node in logical pixels.
  @SizeConverter()
  Size get size;

  /// Z-index for rendering order (higher values render on top).
  int get zIndex;

  /// Map of handles (connection points) attached to this node.
  Map<String, FlowHandle> get handles;

  /// Whether this node should be hidden from view.
  bool? get hidden;

  /// Whether this node can be dragged by the user.
  bool? get draggable;

  /// Whether this node can be selected by the user.
  bool? get selectable;

  /// Whether this node can be hovered by the user.
  bool? get hoverable;

  /// Whether edges can be connected to/from this node.
  bool? get connectable;

  /// Whether this node can be deleted by the user.
  bool? get deletable;

  /// Whether this node can be resized by the user.
  bool? get resizable;

  /// Whether this node can receive keyboard focus.
  bool? get focusable;

  /// Grow the parent when this node is dragged past its edge (Lattice default: false).
  bool get expandParent;

  /// Movement boundary (Lattice `extent`). `null` = unbounded (Lattice default).
  FlowNodeExtent? get extent;

  /// Per-node visual style, merged over the theme's node style.
  ///
  /// Like `FlowEdge.style`: applied on top of the canvas theme for this
  /// node only. Not serialized.
  @JsonKey(ignore: true)
  FlowNodeStyle? get style;

  /// Create a copy of FlowNode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FlowNodeCopyWith<T, FlowNode<T>> get copyWith =>
      _$FlowNodeCopyWithImpl<T, FlowNode<T>>(this as FlowNode<T>, _$identity);

  /// Serializes this FlowNode to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FlowNode<T> &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.zIndex, zIndex) || other.zIndex == zIndex) &&
            const DeepCollectionEquality().equals(other.handles, handles) &&
            (identical(other.hidden, hidden) || other.hidden == hidden) &&
            (identical(other.draggable, draggable) ||
                other.draggable == draggable) &&
            (identical(other.selectable, selectable) ||
                other.selectable == selectable) &&
            (identical(other.hoverable, hoverable) ||
                other.hoverable == hoverable) &&
            (identical(other.connectable, connectable) ||
                other.connectable == connectable) &&
            (identical(other.deletable, deletable) ||
                other.deletable == deletable) &&
            (identical(other.resizable, resizable) ||
                other.resizable == resizable) &&
            (identical(other.focusable, focusable) ||
                other.focusable == focusable) &&
            (identical(other.expandParent, expandParent) ||
                other.expandParent == expandParent) &&
            (identical(other.extent, extent) || other.extent == extent) &&
            (identical(other.style, style) || other.style == style));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        parentId,
        type,
        position,
        const DeepCollectionEquality().hash(data),
        size,
        zIndex,
        const DeepCollectionEquality().hash(handles),
        hidden,
        draggable,
        selectable,
        hoverable,
        connectable,
        deletable,
        resizable,
        focusable,
        expandParent,
        extent,
        style
      ]);

  @override
  String toString() {
    return 'FlowNode<$T>(id: $id, parentId: $parentId, type: $type, position: $position, data: $data, size: $size, zIndex: $zIndex, handles: $handles, hidden: $hidden, draggable: $draggable, selectable: $selectable, hoverable: $hoverable, connectable: $connectable, deletable: $deletable, resizable: $resizable, focusable: $focusable, expandParent: $expandParent, extent: $extent, style: $style)';
  }
}

/// @nodoc
abstract mixin class $FlowNodeCopyWith<T, $Res> {
  factory $FlowNodeCopyWith(
          FlowNode<T> value, $Res Function(FlowNode<T>) _then) =
      _$FlowNodeCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String? parentId,
      String type,
      @OffsetConverter() Offset position,
      T? data,
      @SizeConverter() Size size,
      int zIndex,
      Map<String, FlowHandle> handles,
      bool? hidden,
      bool? draggable,
      bool? selectable,
      bool? hoverable,
      bool? connectable,
      bool? deletable,
      bool? resizable,
      bool? focusable,
      bool expandParent,
      FlowNodeExtent? extent,
      @JsonKey(ignore: true) FlowNodeStyle? style});
}

/// @nodoc
class _$FlowNodeCopyWithImpl<T, $Res> implements $FlowNodeCopyWith<T, $Res> {
  _$FlowNodeCopyWithImpl(this._self, this._then);

  final FlowNode<T> _self;
  final $Res Function(FlowNode<T>) _then;

  /// Create a copy of FlowNode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? parentId = freezed,
    Object? type = null,
    Object? position = null,
    Object? data = freezed,
    Object? size = null,
    Object? zIndex = null,
    Object? handles = null,
    Object? hidden = freezed,
    Object? draggable = freezed,
    Object? selectable = freezed,
    Object? hoverable = freezed,
    Object? connectable = freezed,
    Object? deletable = freezed,
    Object? resizable = freezed,
    Object? focusable = freezed,
    Object? expandParent = null,
    Object? extent = freezed,
    Object? style = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as T?,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      zIndex: null == zIndex
          ? _self.zIndex
          : zIndex // ignore: cast_nullable_to_non_nullable
              as int,
      handles: null == handles
          ? _self.handles
          : handles // ignore: cast_nullable_to_non_nullable
              as Map<String, FlowHandle>,
      hidden: freezed == hidden
          ? _self.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool?,
      draggable: freezed == draggable
          ? _self.draggable
          : draggable // ignore: cast_nullable_to_non_nullable
              as bool?,
      selectable: freezed == selectable
          ? _self.selectable
          : selectable // ignore: cast_nullable_to_non_nullable
              as bool?,
      hoverable: freezed == hoverable
          ? _self.hoverable
          : hoverable // ignore: cast_nullable_to_non_nullable
              as bool?,
      connectable: freezed == connectable
          ? _self.connectable
          : connectable // ignore: cast_nullable_to_non_nullable
              as bool?,
      deletable: freezed == deletable
          ? _self.deletable
          : deletable // ignore: cast_nullable_to_non_nullable
              as bool?,
      resizable: freezed == resizable
          ? _self.resizable
          : resizable // ignore: cast_nullable_to_non_nullable
              as bool?,
      focusable: freezed == focusable
          ? _self.focusable
          : focusable // ignore: cast_nullable_to_non_nullable
              as bool?,
      expandParent: null == expandParent
          ? _self.expandParent
          : expandParent // ignore: cast_nullable_to_non_nullable
              as bool,
      extent: freezed == extent
          ? _self.extent
          : extent // ignore: cast_nullable_to_non_nullable
              as FlowNodeExtent?,
      style: freezed == style
          ? _self.style
          : style // ignore: cast_nullable_to_non_nullable
              as FlowNodeStyle?,
    ));
  }
}

/// Adds pattern-matching-related methods to [FlowNode].
extension FlowNodePatterns<T> on FlowNode<T> {
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
    TResult Function(_FlowNode<T> value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowNode() when $default != null:
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
    TResult Function(_FlowNode<T> value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowNode():
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
    TResult? Function(_FlowNode<T> value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowNode() when $default != null:
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
            String? parentId,
            String type,
            @OffsetConverter() Offset position,
            T? data,
            @SizeConverter() Size size,
            int zIndex,
            Map<String, FlowHandle> handles,
            bool? hidden,
            bool? draggable,
            bool? selectable,
            bool? hoverable,
            bool? connectable,
            bool? deletable,
            bool? resizable,
            bool? focusable,
            bool expandParent,
            FlowNodeExtent? extent,
            @JsonKey(ignore: true) FlowNodeStyle? style)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FlowNode() when $default != null:
        return $default(
            _that.id,
            _that.parentId,
            _that.type,
            _that.position,
            _that.data,
            _that.size,
            _that.zIndex,
            _that.handles,
            _that.hidden,
            _that.draggable,
            _that.selectable,
            _that.hoverable,
            _that.connectable,
            _that.deletable,
            _that.resizable,
            _that.focusable,
            _that.expandParent,
            _that.extent,
            _that.style);
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
            String? parentId,
            String type,
            @OffsetConverter() Offset position,
            T? data,
            @SizeConverter() Size size,
            int zIndex,
            Map<String, FlowHandle> handles,
            bool? hidden,
            bool? draggable,
            bool? selectable,
            bool? hoverable,
            bool? connectable,
            bool? deletable,
            bool? resizable,
            bool? focusable,
            bool expandParent,
            FlowNodeExtent? extent,
            @JsonKey(ignore: true) FlowNodeStyle? style)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowNode():
        return $default(
            _that.id,
            _that.parentId,
            _that.type,
            _that.position,
            _that.data,
            _that.size,
            _that.zIndex,
            _that.handles,
            _that.hidden,
            _that.draggable,
            _that.selectable,
            _that.hoverable,
            _that.connectable,
            _that.deletable,
            _that.resizable,
            _that.focusable,
            _that.expandParent,
            _that.extent,
            _that.style);
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
            String? parentId,
            String type,
            @OffsetConverter() Offset position,
            T? data,
            @SizeConverter() Size size,
            int zIndex,
            Map<String, FlowHandle> handles,
            bool? hidden,
            bool? draggable,
            bool? selectable,
            bool? hoverable,
            bool? connectable,
            bool? deletable,
            bool? resizable,
            bool? focusable,
            bool expandParent,
            FlowNodeExtent? extent,
            @JsonKey(ignore: true) FlowNodeStyle? style)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FlowNode() when $default != null:
        return $default(
            _that.id,
            _that.parentId,
            _that.type,
            _that.position,
            _that.data,
            _that.size,
            _that.zIndex,
            _that.handles,
            _that.hidden,
            _that.draggable,
            _that.selectable,
            _that.hoverable,
            _that.connectable,
            _that.deletable,
            _that.resizable,
            _that.focusable,
            _that.expandParent,
            _that.extent,
            _that.style);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)
class _FlowNode<T> extends FlowNode<T> {
  const _FlowNode(
      {required this.id,
      this.parentId,
      required this.type,
      @OffsetConverter() required this.position,
      this.data,
      @SizeConverter() this.size = const Size(160, 44),
      this.zIndex = 0,
      final Map<String, FlowHandle> handles = const {},
      this.hidden = false,
      this.draggable = true,
      this.selectable = true,
      this.hoverable = true,
      this.connectable = true,
      this.deletable = true,
      this.resizable = true,
      this.focusable = true,
      this.expandParent = false,
      this.extent,
      @JsonKey(ignore: true) this.style})
      : _handles = handles,
        super._();
  factory _FlowNode.fromJson(
          Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$FlowNodeFromJson(json, fromJsonT);

  /// Unique identifier for this node.
  @override
  final String id;

  /// Optional ID of the parent node (for nested/grouped nodes).
  @override
  final String? parentId;

  /// Type identifier for this node (e.g., 'default', 'input', 'output').
  @override
  final String type;

  /// Node position in flow coordinates.
  ///
  /// When [parentId] is null this is absolute (graph space).
  /// When [parentId] is set this is **relative to the parent’s top-left**,
  /// matching Lattice sub-flows (`{ x: 0, y: 0 }` = parent origin).
  @override
  @OffsetConverter()
  final Offset position;

  /// Custom data attached to this node.
  ///
  /// Optional, like Lattice's `data` (defaults to `{}` there, `null`
  /// here). The built-in node widgets never render it — your node widget
  /// decides how (and whether) to display `props.data`.
  @override
  final T? data;

  /// Size of the node in logical pixels.
  @override
  @JsonKey()
  @SizeConverter()
  final Size size;

  /// Z-index for rendering order (higher values render on top).
  @override
  @JsonKey()
  final int zIndex;

  /// Map of handles (connection points) attached to this node.
  final Map<String, FlowHandle> _handles;

  /// Map of handles (connection points) attached to this node.
  @override
  @JsonKey()
  Map<String, FlowHandle> get handles {
    if (_handles is EqualUnmodifiableMapView) return _handles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_handles);
  }

  /// Whether this node should be hidden from view.
  @override
  @JsonKey()
  final bool? hidden;

  /// Whether this node can be dragged by the user.
  @override
  @JsonKey()
  final bool? draggable;

  /// Whether this node can be selected by the user.
  @override
  @JsonKey()
  final bool? selectable;

  /// Whether this node can be hovered by the user.
  @override
  @JsonKey()
  final bool? hoverable;

  /// Whether edges can be connected to/from this node.
  @override
  @JsonKey()
  final bool? connectable;

  /// Whether this node can be deleted by the user.
  @override
  @JsonKey()
  final bool? deletable;

  /// Whether this node can be resized by the user.
  @override
  @JsonKey()
  final bool? resizable;

  /// Whether this node can receive keyboard focus.
  @override
  @JsonKey()
  final bool? focusable;

  /// Grow the parent when this node is dragged past its edge (Lattice default: false).
  @override
  @JsonKey()
  final bool expandParent;

  /// Movement boundary (Lattice `extent`). `null` = unbounded (Lattice default).
  @override
  final FlowNodeExtent? extent;

  /// Per-node visual style, merged over the theme's node style.
  ///
  /// Like `FlowEdge.style`: applied on top of the canvas theme for this
  /// node only. Not serialized.
  @override
  @JsonKey(ignore: true)
  final FlowNodeStyle? style;

  /// Create a copy of FlowNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FlowNodeCopyWith<T, _FlowNode<T>> get copyWith =>
      __$FlowNodeCopyWithImpl<T, _FlowNode<T>>(this, _$identity);

  @override
  Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
    return _$FlowNodeToJson<T>(this, toJsonT);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FlowNode<T> &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.position, position) ||
                other.position == position) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.size, size) || other.size == size) &&
            (identical(other.zIndex, zIndex) || other.zIndex == zIndex) &&
            const DeepCollectionEquality().equals(other._handles, _handles) &&
            (identical(other.hidden, hidden) || other.hidden == hidden) &&
            (identical(other.draggable, draggable) ||
                other.draggable == draggable) &&
            (identical(other.selectable, selectable) ||
                other.selectable == selectable) &&
            (identical(other.hoverable, hoverable) ||
                other.hoverable == hoverable) &&
            (identical(other.connectable, connectable) ||
                other.connectable == connectable) &&
            (identical(other.deletable, deletable) ||
                other.deletable == deletable) &&
            (identical(other.resizable, resizable) ||
                other.resizable == resizable) &&
            (identical(other.focusable, focusable) ||
                other.focusable == focusable) &&
            (identical(other.expandParent, expandParent) ||
                other.expandParent == expandParent) &&
            (identical(other.extent, extent) || other.extent == extent) &&
            (identical(other.style, style) || other.style == style));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        parentId,
        type,
        position,
        const DeepCollectionEquality().hash(data),
        size,
        zIndex,
        const DeepCollectionEquality().hash(_handles),
        hidden,
        draggable,
        selectable,
        hoverable,
        connectable,
        deletable,
        resizable,
        focusable,
        expandParent,
        extent,
        style
      ]);

  @override
  String toString() {
    return 'FlowNode<$T>(id: $id, parentId: $parentId, type: $type, position: $position, data: $data, size: $size, zIndex: $zIndex, handles: $handles, hidden: $hidden, draggable: $draggable, selectable: $selectable, hoverable: $hoverable, connectable: $connectable, deletable: $deletable, resizable: $resizable, focusable: $focusable, expandParent: $expandParent, extent: $extent, style: $style)';
  }
}

/// @nodoc
abstract mixin class _$FlowNodeCopyWith<T, $Res>
    implements $FlowNodeCopyWith<T, $Res> {
  factory _$FlowNodeCopyWith(
          _FlowNode<T> value, $Res Function(_FlowNode<T>) _then) =
      __$FlowNodeCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String? parentId,
      String type,
      @OffsetConverter() Offset position,
      T? data,
      @SizeConverter() Size size,
      int zIndex,
      Map<String, FlowHandle> handles,
      bool? hidden,
      bool? draggable,
      bool? selectable,
      bool? hoverable,
      bool? connectable,
      bool? deletable,
      bool? resizable,
      bool? focusable,
      bool expandParent,
      FlowNodeExtent? extent,
      @JsonKey(ignore: true) FlowNodeStyle? style});
}

/// @nodoc
class __$FlowNodeCopyWithImpl<T, $Res> implements _$FlowNodeCopyWith<T, $Res> {
  __$FlowNodeCopyWithImpl(this._self, this._then);

  final _FlowNode<T> _self;
  final $Res Function(_FlowNode<T>) _then;

  /// Create a copy of FlowNode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? parentId = freezed,
    Object? type = null,
    Object? position = null,
    Object? data = freezed,
    Object? size = null,
    Object? zIndex = null,
    Object? handles = null,
    Object? hidden = freezed,
    Object? draggable = freezed,
    Object? selectable = freezed,
    Object? hoverable = freezed,
    Object? connectable = freezed,
    Object? deletable = freezed,
    Object? resizable = freezed,
    Object? focusable = freezed,
    Object? expandParent = null,
    Object? extent = freezed,
    Object? style = freezed,
  }) {
    return _then(_FlowNode<T>(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      parentId: freezed == parentId
          ? _self.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      position: null == position
          ? _self.position
          : position // ignore: cast_nullable_to_non_nullable
              as Offset,
      data: freezed == data
          ? _self.data
          : data // ignore: cast_nullable_to_non_nullable
              as T?,
      size: null == size
          ? _self.size
          : size // ignore: cast_nullable_to_non_nullable
              as Size,
      zIndex: null == zIndex
          ? _self.zIndex
          : zIndex // ignore: cast_nullable_to_non_nullable
              as int,
      handles: null == handles
          ? _self._handles
          : handles // ignore: cast_nullable_to_non_nullable
              as Map<String, FlowHandle>,
      hidden: freezed == hidden
          ? _self.hidden
          : hidden // ignore: cast_nullable_to_non_nullable
              as bool?,
      draggable: freezed == draggable
          ? _self.draggable
          : draggable // ignore: cast_nullable_to_non_nullable
              as bool?,
      selectable: freezed == selectable
          ? _self.selectable
          : selectable // ignore: cast_nullable_to_non_nullable
              as bool?,
      hoverable: freezed == hoverable
          ? _self.hoverable
          : hoverable // ignore: cast_nullable_to_non_nullable
              as bool?,
      connectable: freezed == connectable
          ? _self.connectable
          : connectable // ignore: cast_nullable_to_non_nullable
              as bool?,
      deletable: freezed == deletable
          ? _self.deletable
          : deletable // ignore: cast_nullable_to_non_nullable
              as bool?,
      resizable: freezed == resizable
          ? _self.resizable
          : resizable // ignore: cast_nullable_to_non_nullable
              as bool?,
      focusable: freezed == focusable
          ? _self.focusable
          : focusable // ignore: cast_nullable_to_non_nullable
              as bool?,
      expandParent: null == expandParent
          ? _self.expandParent
          : expandParent // ignore: cast_nullable_to_non_nullable
              as bool,
      extent: freezed == extent
          ? _self.extent
          : extent // ignore: cast_nullable_to_non_nullable
              as FlowNodeExtent?,
      style: freezed == style
          ? _self.style
          : style // ignore: cast_nullable_to_non_nullable
              as FlowNodeStyle?,
    ));
  }
}

// dart format on
