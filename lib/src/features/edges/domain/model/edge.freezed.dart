// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edge.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FlowEdge {

/// Unique identifier for this edge.
 String get id;/// ID of the source node this edge originates from.
 String get sourceNodeId;/// ID of the target node this edge points to.
 String get targetNodeId;/// Optional handle ID on the source node where the edge connects.
///
/// If null, the edge connects to the node's center or default position.
 String? get sourceHandleId;/// Optional handle ID on the target node where the edge connects.
///
/// If null, the edge connects to the node's center or default position.
 String? get targetHandleId;/// Z-index for layering edges.
///
/// Higher values render on top. Useful when [elevateEdgeOnSelect] is true.
/// Default is 0.
 int get zIndex;/// The path rendering algorithm for this edge.
///
/// Determines the visual style of the connection line:
/// - [EdgePathType.bezier] - Smooth curved path (default)
/// - [EdgePathType.straight] - Direct line
/// - [EdgePathType.step] - Right-angled path
/// - [EdgePathType.smoothstep] - Smooth right-angled path
 EdgePathType get type;/// Width of the invisible interaction area around the edge for easier selection.
///
/// Makes thin edges easier to click/hover. Typical values: 8-15.
/// RF parity: `BaseEdge` defaults to 20.0.
/// Default is 20.0.
 double get interactionWidth;/// Optional widget to display as a label on the edge.
///
/// Typically a Text widget, but can be any widget. Positioned at the
/// center of the edge path.
@JsonKey(ignore: true) Widget? get label;/// Interactive overlay label rendered by [FlowEdgeLabelPortal].
///
/// Unlike [label] (canvas-space, scales with zoom, never interactive),
/// the overlay label renders in a screen-space portal at the path
/// midpoint at a constant size and receives pointer events — the
/// counterpart of RF's `<EdgeLabelRenderer>` content (e.g. a delete
/// button). Rendered only when a [FlowEdgeLabelPortal] is in the
/// canvas `overlays`. Not serialized.
@JsonKey(ignore: true) Widget? get overlayLabel;/// Optional decoration for the label container.
///
/// Controls background, border, padding, etc. of the label.
/// If null, uses default decoration or no decoration.
@JsonKey(ignore: true) FlowEdgeLabelStyle? get labelDecoration;/// Optional custom marker style for the start of the edge.
///
/// Common options: arrow, circle, diamond. If null, no start marker.
@JsonKey(ignore: true) FlowEdgeMarkerStyle? get startMarkerStyle;/// Optional custom marker style for the end of the edge.
///
/// Common options: arrow, circle, diamond. If null, no end marker.
@JsonKey(ignore: true) FlowEdgeMarkerStyle? get endMarkerStyle;/// Optional custom style for this edge.
///
/// Controls stroke width, color, dash pattern, etc.
/// If null, uses the style from the current theme.
@JsonKey(ignore: true) FlowEdgeStyle? get style;/// Custom data that can be attached to this edge.
///
/// Useful for storing application-specific metadata like weights,
/// capacities, or custom properties.
 Map<String, dynamic> get data;/// When true, draws a flowing dash along the path (React Flow `animated`).
///
/// Uses a shared ticker that only runs while any edge is animated; static
/// edges stay on a separate [RepaintBoundary] so they do not repaint every
/// frame (lattice performance pattern).
 bool get animated;/// Optional custom effect when [animated] is true.
///
/// Defaults to [FlowingDashEffect] (marching ants).
@JsonKey(includeFromJson: false, includeToJson: false) EdgeAnimationEffect? get animationEffect;/// Whether this edge should be hidden from view.
///
/// Hidden edges are not rendered but remain in the data structure.
/// If null, uses the global canvas setting.
 bool? get hidden;/// Whether this edge can be deleted by the user.
///
/// If null, uses the global canvas setting.
 bool? get deletable;/// Whether this edge can be selected by the user.
///
/// If null, uses the global canvas setting.
 bool? get selectable;/// Whether this edge can receive keyboard focus.
///
/// If null, uses the global canvas setting.
 bool? get focusable;/// Screen-reader label for this edge.
///
/// Falls back to `'Edge <id>'`. Serialized with the edge.
 String? get semanticsLabel;/// Whether this edge's connections can be changed by dragging.
///
/// Allows reconnecting the edge to different nodes/handles.
/// If null, uses the global canvas setting.
 bool? get reconnectable;/// Whether this edge should be elevated (z-index increased) when selected.
///
/// If null, uses the global canvas setting.
 bool? get elevateEdgeOnSelect;/// Fully custom path builder (React Flow custom edge path).
///
/// Overrides [type] for path computation; bounds, hit-testing, labels,
/// and markers derive from the returned path. Not serialized.
@JsonKey(ignore: true) FlowEdgePathBuilder? get pathBuilder;/// Canvas-space decorations painted over the base stroke (React Flow
/// custom edge body). Widget content belongs in [overlayLabel].
/// Not serialized.
@JsonKey(ignore: true) FlowEdgeForegroundPainter? get foregroundPainter;
/// Create a copy of FlowEdge
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlowEdgeCopyWith<FlowEdge> get copyWith => _$FlowEdgeCopyWithImpl<FlowEdge>(this as FlowEdge, _$identity);

  /// Serializes this FlowEdge to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlowEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceNodeId, sourceNodeId) || other.sourceNodeId == sourceNodeId)&&(identical(other.targetNodeId, targetNodeId) || other.targetNodeId == targetNodeId)&&(identical(other.sourceHandleId, sourceHandleId) || other.sourceHandleId == sourceHandleId)&&(identical(other.targetHandleId, targetHandleId) || other.targetHandleId == targetHandleId)&&(identical(other.zIndex, zIndex) || other.zIndex == zIndex)&&(identical(other.type, type) || other.type == type)&&(identical(other.interactionWidth, interactionWidth) || other.interactionWidth == interactionWidth)&&(identical(other.label, label) || other.label == label)&&(identical(other.overlayLabel, overlayLabel) || other.overlayLabel == overlayLabel)&&(identical(other.labelDecoration, labelDecoration) || other.labelDecoration == labelDecoration)&&(identical(other.startMarkerStyle, startMarkerStyle) || other.startMarkerStyle == startMarkerStyle)&&(identical(other.endMarkerStyle, endMarkerStyle) || other.endMarkerStyle == endMarkerStyle)&&(identical(other.style, style) || other.style == style)&&const DeepCollectionEquality().equals(other.data, data)&&(identical(other.animated, animated) || other.animated == animated)&&(identical(other.animationEffect, animationEffect) || other.animationEffect == animationEffect)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.deletable, deletable) || other.deletable == deletable)&&(identical(other.selectable, selectable) || other.selectable == selectable)&&(identical(other.focusable, focusable) || other.focusable == focusable)&&(identical(other.semanticsLabel, semanticsLabel) || other.semanticsLabel == semanticsLabel)&&(identical(other.reconnectable, reconnectable) || other.reconnectable == reconnectable)&&(identical(other.elevateEdgeOnSelect, elevateEdgeOnSelect) || other.elevateEdgeOnSelect == elevateEdgeOnSelect)&&(identical(other.pathBuilder, pathBuilder) || other.pathBuilder == pathBuilder)&&(identical(other.foregroundPainter, foregroundPainter) || other.foregroundPainter == foregroundPainter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,sourceNodeId,targetNodeId,sourceHandleId,targetHandleId,zIndex,type,interactionWidth,label,overlayLabel,labelDecoration,startMarkerStyle,endMarkerStyle,style,const DeepCollectionEquality().hash(data),animated,animationEffect,hidden,deletable,selectable,focusable,semanticsLabel,reconnectable,elevateEdgeOnSelect,pathBuilder,foregroundPainter]);

@override
String toString() {
  return 'FlowEdge(id: $id, sourceNodeId: $sourceNodeId, targetNodeId: $targetNodeId, sourceHandleId: $sourceHandleId, targetHandleId: $targetHandleId, zIndex: $zIndex, type: $type, interactionWidth: $interactionWidth, label: $label, overlayLabel: $overlayLabel, labelDecoration: $labelDecoration, startMarkerStyle: $startMarkerStyle, endMarkerStyle: $endMarkerStyle, style: $style, data: $data, animated: $animated, animationEffect: $animationEffect, hidden: $hidden, deletable: $deletable, selectable: $selectable, focusable: $focusable, semanticsLabel: $semanticsLabel, reconnectable: $reconnectable, elevateEdgeOnSelect: $elevateEdgeOnSelect, pathBuilder: $pathBuilder, foregroundPainter: $foregroundPainter)';
}


}

/// @nodoc
abstract mixin class $FlowEdgeCopyWith<$Res>  {
  factory $FlowEdgeCopyWith(FlowEdge value, $Res Function(FlowEdge) _then) = _$FlowEdgeCopyWithImpl;
@useResult
$Res call({
 String id, String sourceNodeId, String targetNodeId, String? sourceHandleId, String? targetHandleId, int zIndex, EdgePathType type, double interactionWidth,@JsonKey(ignore: true) Widget? label,@JsonKey(ignore: true) Widget? overlayLabel,@JsonKey(ignore: true) FlowEdgeLabelStyle? labelDecoration,@JsonKey(ignore: true) FlowEdgeMarkerStyle? startMarkerStyle,@JsonKey(ignore: true) FlowEdgeMarkerStyle? endMarkerStyle,@JsonKey(ignore: true) FlowEdgeStyle? style, Map<String, dynamic> data, bool animated,@JsonKey(includeFromJson: false, includeToJson: false) EdgeAnimationEffect? animationEffect, bool? hidden, bool? deletable, bool? selectable, bool? focusable, String? semanticsLabel, bool? reconnectable, bool? elevateEdgeOnSelect,@JsonKey(ignore: true) FlowEdgePathBuilder? pathBuilder,@JsonKey(ignore: true) FlowEdgeForegroundPainter? foregroundPainter
});




}
/// @nodoc
class _$FlowEdgeCopyWithImpl<$Res>
    implements $FlowEdgeCopyWith<$Res> {
  _$FlowEdgeCopyWithImpl(this._self, this._then);

  final FlowEdge _self;
  final $Res Function(FlowEdge) _then;

/// Create a copy of FlowEdge
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sourceNodeId = null,Object? targetNodeId = null,Object? sourceHandleId = freezed,Object? targetHandleId = freezed,Object? zIndex = null,Object? type = null,Object? interactionWidth = null,Object? label = freezed,Object? overlayLabel = freezed,Object? labelDecoration = freezed,Object? startMarkerStyle = freezed,Object? endMarkerStyle = freezed,Object? style = freezed,Object? data = null,Object? animated = null,Object? animationEffect = freezed,Object? hidden = freezed,Object? deletable = freezed,Object? selectable = freezed,Object? focusable = freezed,Object? semanticsLabel = freezed,Object? reconnectable = freezed,Object? elevateEdgeOnSelect = freezed,Object? pathBuilder = freezed,Object? foregroundPainter = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceNodeId: null == sourceNodeId ? _self.sourceNodeId : sourceNodeId // ignore: cast_nullable_to_non_nullable
as String,targetNodeId: null == targetNodeId ? _self.targetNodeId : targetNodeId // ignore: cast_nullable_to_non_nullable
as String,sourceHandleId: freezed == sourceHandleId ? _self.sourceHandleId : sourceHandleId // ignore: cast_nullable_to_non_nullable
as String?,targetHandleId: freezed == targetHandleId ? _self.targetHandleId : targetHandleId // ignore: cast_nullable_to_non_nullable
as String?,zIndex: null == zIndex ? _self.zIndex : zIndex // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EdgePathType,interactionWidth: null == interactionWidth ? _self.interactionWidth : interactionWidth // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Widget?,overlayLabel: freezed == overlayLabel ? _self.overlayLabel : overlayLabel // ignore: cast_nullable_to_non_nullable
as Widget?,labelDecoration: freezed == labelDecoration ? _self.labelDecoration : labelDecoration // ignore: cast_nullable_to_non_nullable
as FlowEdgeLabelStyle?,startMarkerStyle: freezed == startMarkerStyle ? _self.startMarkerStyle : startMarkerStyle // ignore: cast_nullable_to_non_nullable
as FlowEdgeMarkerStyle?,endMarkerStyle: freezed == endMarkerStyle ? _self.endMarkerStyle : endMarkerStyle // ignore: cast_nullable_to_non_nullable
as FlowEdgeMarkerStyle?,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as FlowEdgeStyle?,data: null == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,animated: null == animated ? _self.animated : animated // ignore: cast_nullable_to_non_nullable
as bool,animationEffect: freezed == animationEffect ? _self.animationEffect : animationEffect // ignore: cast_nullable_to_non_nullable
as EdgeAnimationEffect?,hidden: freezed == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool?,deletable: freezed == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool?,selectable: freezed == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as bool?,focusable: freezed == focusable ? _self.focusable : focusable // ignore: cast_nullable_to_non_nullable
as bool?,semanticsLabel: freezed == semanticsLabel ? _self.semanticsLabel : semanticsLabel // ignore: cast_nullable_to_non_nullable
as String?,reconnectable: freezed == reconnectable ? _self.reconnectable : reconnectable // ignore: cast_nullable_to_non_nullable
as bool?,elevateEdgeOnSelect: freezed == elevateEdgeOnSelect ? _self.elevateEdgeOnSelect : elevateEdgeOnSelect // ignore: cast_nullable_to_non_nullable
as bool?,pathBuilder: freezed == pathBuilder ? _self.pathBuilder : pathBuilder // ignore: cast_nullable_to_non_nullable
as FlowEdgePathBuilder?,foregroundPainter: freezed == foregroundPainter ? _self.foregroundPainter : foregroundPainter // ignore: cast_nullable_to_non_nullable
as FlowEdgeForegroundPainter?,
  ));
}

}


/// Adds pattern-matching-related methods to [FlowEdge].
extension FlowEdgePatterns on FlowEdge {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlowEdge value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlowEdge() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlowEdge value)  $default,){
final _that = this;
switch (_that) {
case _FlowEdge():
return $default(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlowEdge value)?  $default,){
final _that = this;
switch (_that) {
case _FlowEdge() when $default != null:
return $default(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sourceNodeId,  String targetNodeId,  String? sourceHandleId,  String? targetHandleId,  int zIndex,  EdgePathType type,  double interactionWidth, @JsonKey(ignore: true)  Widget? label, @JsonKey(ignore: true)  Widget? overlayLabel, @JsonKey(ignore: true)  FlowEdgeLabelStyle? labelDecoration, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? startMarkerStyle, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? endMarkerStyle, @JsonKey(ignore: true)  FlowEdgeStyle? style,  Map<String, dynamic> data,  bool animated, @JsonKey(includeFromJson: false, includeToJson: false)  EdgeAnimationEffect? animationEffect,  bool? hidden,  bool? deletable,  bool? selectable,  bool? focusable,  String? semanticsLabel,  bool? reconnectable,  bool? elevateEdgeOnSelect, @JsonKey(ignore: true)  FlowEdgePathBuilder? pathBuilder, @JsonKey(ignore: true)  FlowEdgeForegroundPainter? foregroundPainter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlowEdge() when $default != null:
return $default(_that.id,_that.sourceNodeId,_that.targetNodeId,_that.sourceHandleId,_that.targetHandleId,_that.zIndex,_that.type,_that.interactionWidth,_that.label,_that.overlayLabel,_that.labelDecoration,_that.startMarkerStyle,_that.endMarkerStyle,_that.style,_that.data,_that.animated,_that.animationEffect,_that.hidden,_that.deletable,_that.selectable,_that.focusable,_that.semanticsLabel,_that.reconnectable,_that.elevateEdgeOnSelect,_that.pathBuilder,_that.foregroundPainter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sourceNodeId,  String targetNodeId,  String? sourceHandleId,  String? targetHandleId,  int zIndex,  EdgePathType type,  double interactionWidth, @JsonKey(ignore: true)  Widget? label, @JsonKey(ignore: true)  Widget? overlayLabel, @JsonKey(ignore: true)  FlowEdgeLabelStyle? labelDecoration, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? startMarkerStyle, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? endMarkerStyle, @JsonKey(ignore: true)  FlowEdgeStyle? style,  Map<String, dynamic> data,  bool animated, @JsonKey(includeFromJson: false, includeToJson: false)  EdgeAnimationEffect? animationEffect,  bool? hidden,  bool? deletable,  bool? selectable,  bool? focusable,  String? semanticsLabel,  bool? reconnectable,  bool? elevateEdgeOnSelect, @JsonKey(ignore: true)  FlowEdgePathBuilder? pathBuilder, @JsonKey(ignore: true)  FlowEdgeForegroundPainter? foregroundPainter)  $default,) {final _that = this;
switch (_that) {
case _FlowEdge():
return $default(_that.id,_that.sourceNodeId,_that.targetNodeId,_that.sourceHandleId,_that.targetHandleId,_that.zIndex,_that.type,_that.interactionWidth,_that.label,_that.overlayLabel,_that.labelDecoration,_that.startMarkerStyle,_that.endMarkerStyle,_that.style,_that.data,_that.animated,_that.animationEffect,_that.hidden,_that.deletable,_that.selectable,_that.focusable,_that.semanticsLabel,_that.reconnectable,_that.elevateEdgeOnSelect,_that.pathBuilder,_that.foregroundPainter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sourceNodeId,  String targetNodeId,  String? sourceHandleId,  String? targetHandleId,  int zIndex,  EdgePathType type,  double interactionWidth, @JsonKey(ignore: true)  Widget? label, @JsonKey(ignore: true)  Widget? overlayLabel, @JsonKey(ignore: true)  FlowEdgeLabelStyle? labelDecoration, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? startMarkerStyle, @JsonKey(ignore: true)  FlowEdgeMarkerStyle? endMarkerStyle, @JsonKey(ignore: true)  FlowEdgeStyle? style,  Map<String, dynamic> data,  bool animated, @JsonKey(includeFromJson: false, includeToJson: false)  EdgeAnimationEffect? animationEffect,  bool? hidden,  bool? deletable,  bool? selectable,  bool? focusable,  String? semanticsLabel,  bool? reconnectable,  bool? elevateEdgeOnSelect, @JsonKey(ignore: true)  FlowEdgePathBuilder? pathBuilder, @JsonKey(ignore: true)  FlowEdgeForegroundPainter? foregroundPainter)?  $default,) {final _that = this;
switch (_that) {
case _FlowEdge() when $default != null:
return $default(_that.id,_that.sourceNodeId,_that.targetNodeId,_that.sourceHandleId,_that.targetHandleId,_that.zIndex,_that.type,_that.interactionWidth,_that.label,_that.overlayLabel,_that.labelDecoration,_that.startMarkerStyle,_that.endMarkerStyle,_that.style,_that.data,_that.animated,_that.animationEffect,_that.hidden,_that.deletable,_that.selectable,_that.focusable,_that.semanticsLabel,_that.reconnectable,_that.elevateEdgeOnSelect,_that.pathBuilder,_that.foregroundPainter);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FlowEdge extends FlowEdge {
  const _FlowEdge({required this.id, required this.sourceNodeId, required this.targetNodeId, this.sourceHandleId, this.targetHandleId, this.zIndex = 0, this.type = EdgePathType.bezier, this.interactionWidth = 20.0, @JsonKey(ignore: true) this.label, @JsonKey(ignore: true) this.overlayLabel, @JsonKey(ignore: true) this.labelDecoration, @JsonKey(ignore: true) this.startMarkerStyle, @JsonKey(ignore: true) this.endMarkerStyle, @JsonKey(ignore: true) this.style, final  Map<String, dynamic> data = const <String, dynamic>{}, this.animated = false, @JsonKey(includeFromJson: false, includeToJson: false) this.animationEffect, this.hidden, this.deletable, this.selectable, this.focusable, this.semanticsLabel, this.reconnectable, this.elevateEdgeOnSelect, @JsonKey(ignore: true) this.pathBuilder, @JsonKey(ignore: true) this.foregroundPainter}): assert(sourceNodeId != targetNodeId, 'Source and target cannot be the same node'),_data = data,super._();
  factory _FlowEdge.fromJson(Map<String, dynamic> json) => _$FlowEdgeFromJson(json);

/// Unique identifier for this edge.
@override final  String id;
/// ID of the source node this edge originates from.
@override final  String sourceNodeId;
/// ID of the target node this edge points to.
@override final  String targetNodeId;
/// Optional handle ID on the source node where the edge connects.
///
/// If null, the edge connects to the node's center or default position.
@override final  String? sourceHandleId;
/// Optional handle ID on the target node where the edge connects.
///
/// If null, the edge connects to the node's center or default position.
@override final  String? targetHandleId;
/// Z-index for layering edges.
///
/// Higher values render on top. Useful when [elevateEdgeOnSelect] is true.
/// Default is 0.
@override@JsonKey() final  int zIndex;
/// The path rendering algorithm for this edge.
///
/// Determines the visual style of the connection line:
/// - [EdgePathType.bezier] - Smooth curved path (default)
/// - [EdgePathType.straight] - Direct line
/// - [EdgePathType.step] - Right-angled path
/// - [EdgePathType.smoothstep] - Smooth right-angled path
@override@JsonKey() final  EdgePathType type;
/// Width of the invisible interaction area around the edge for easier selection.
///
/// Makes thin edges easier to click/hover. Typical values: 8-15.
/// RF parity: `BaseEdge` defaults to 20.0.
/// Default is 20.0.
@override@JsonKey() final  double interactionWidth;
/// Optional widget to display as a label on the edge.
///
/// Typically a Text widget, but can be any widget. Positioned at the
/// center of the edge path.
@override@JsonKey(ignore: true) final  Widget? label;
/// Interactive overlay label rendered by [FlowEdgeLabelPortal].
///
/// Unlike [label] (canvas-space, scales with zoom, never interactive),
/// the overlay label renders in a screen-space portal at the path
/// midpoint at a constant size and receives pointer events — the
/// counterpart of RF's `<EdgeLabelRenderer>` content (e.g. a delete
/// button). Rendered only when a [FlowEdgeLabelPortal] is in the
/// canvas `overlays`. Not serialized.
@override@JsonKey(ignore: true) final  Widget? overlayLabel;
/// Optional decoration for the label container.
///
/// Controls background, border, padding, etc. of the label.
/// If null, uses default decoration or no decoration.
@override@JsonKey(ignore: true) final  FlowEdgeLabelStyle? labelDecoration;
/// Optional custom marker style for the start of the edge.
///
/// Common options: arrow, circle, diamond. If null, no start marker.
@override@JsonKey(ignore: true) final  FlowEdgeMarkerStyle? startMarkerStyle;
/// Optional custom marker style for the end of the edge.
///
/// Common options: arrow, circle, diamond. If null, no end marker.
@override@JsonKey(ignore: true) final  FlowEdgeMarkerStyle? endMarkerStyle;
/// Optional custom style for this edge.
///
/// Controls stroke width, color, dash pattern, etc.
/// If null, uses the style from the current theme.
@override@JsonKey(ignore: true) final  FlowEdgeStyle? style;
/// Custom data that can be attached to this edge.
///
/// Useful for storing application-specific metadata like weights,
/// capacities, or custom properties.
 final  Map<String, dynamic> _data;
/// Custom data that can be attached to this edge.
///
/// Useful for storing application-specific metadata like weights,
/// capacities, or custom properties.
@override@JsonKey() Map<String, dynamic> get data {
  if (_data is EqualUnmodifiableMapView) return _data;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_data);
}

/// When true, draws a flowing dash along the path (React Flow `animated`).
///
/// Uses a shared ticker that only runs while any edge is animated; static
/// edges stay on a separate [RepaintBoundary] so they do not repaint every
/// frame (lattice performance pattern).
@override@JsonKey() final  bool animated;
/// Optional custom effect when [animated] is true.
///
/// Defaults to [FlowingDashEffect] (marching ants).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  EdgeAnimationEffect? animationEffect;
/// Whether this edge should be hidden from view.
///
/// Hidden edges are not rendered but remain in the data structure.
/// If null, uses the global canvas setting.
@override final  bool? hidden;
/// Whether this edge can be deleted by the user.
///
/// If null, uses the global canvas setting.
@override final  bool? deletable;
/// Whether this edge can be selected by the user.
///
/// If null, uses the global canvas setting.
@override final  bool? selectable;
/// Whether this edge can receive keyboard focus.
///
/// If null, uses the global canvas setting.
@override final  bool? focusable;
/// Screen-reader label for this edge.
///
/// Falls back to `'Edge <id>'`. Serialized with the edge.
@override final  String? semanticsLabel;
/// Whether this edge's connections can be changed by dragging.
///
/// Allows reconnecting the edge to different nodes/handles.
/// If null, uses the global canvas setting.
@override final  bool? reconnectable;
/// Whether this edge should be elevated (z-index increased) when selected.
///
/// If null, uses the global canvas setting.
@override final  bool? elevateEdgeOnSelect;
/// Fully custom path builder (React Flow custom edge path).
///
/// Overrides [type] for path computation; bounds, hit-testing, labels,
/// and markers derive from the returned path. Not serialized.
@override@JsonKey(ignore: true) final  FlowEdgePathBuilder? pathBuilder;
/// Canvas-space decorations painted over the base stroke (React Flow
/// custom edge body). Widget content belongs in [overlayLabel].
/// Not serialized.
@override@JsonKey(ignore: true) final  FlowEdgeForegroundPainter? foregroundPainter;

/// Create a copy of FlowEdge
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlowEdgeCopyWith<_FlowEdge> get copyWith => __$FlowEdgeCopyWithImpl<_FlowEdge>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FlowEdgeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlowEdge&&(identical(other.id, id) || other.id == id)&&(identical(other.sourceNodeId, sourceNodeId) || other.sourceNodeId == sourceNodeId)&&(identical(other.targetNodeId, targetNodeId) || other.targetNodeId == targetNodeId)&&(identical(other.sourceHandleId, sourceHandleId) || other.sourceHandleId == sourceHandleId)&&(identical(other.targetHandleId, targetHandleId) || other.targetHandleId == targetHandleId)&&(identical(other.zIndex, zIndex) || other.zIndex == zIndex)&&(identical(other.type, type) || other.type == type)&&(identical(other.interactionWidth, interactionWidth) || other.interactionWidth == interactionWidth)&&(identical(other.label, label) || other.label == label)&&(identical(other.overlayLabel, overlayLabel) || other.overlayLabel == overlayLabel)&&(identical(other.labelDecoration, labelDecoration) || other.labelDecoration == labelDecoration)&&(identical(other.startMarkerStyle, startMarkerStyle) || other.startMarkerStyle == startMarkerStyle)&&(identical(other.endMarkerStyle, endMarkerStyle) || other.endMarkerStyle == endMarkerStyle)&&(identical(other.style, style) || other.style == style)&&const DeepCollectionEquality().equals(other._data, _data)&&(identical(other.animated, animated) || other.animated == animated)&&(identical(other.animationEffect, animationEffect) || other.animationEffect == animationEffect)&&(identical(other.hidden, hidden) || other.hidden == hidden)&&(identical(other.deletable, deletable) || other.deletable == deletable)&&(identical(other.selectable, selectable) || other.selectable == selectable)&&(identical(other.focusable, focusable) || other.focusable == focusable)&&(identical(other.semanticsLabel, semanticsLabel) || other.semanticsLabel == semanticsLabel)&&(identical(other.reconnectable, reconnectable) || other.reconnectable == reconnectable)&&(identical(other.elevateEdgeOnSelect, elevateEdgeOnSelect) || other.elevateEdgeOnSelect == elevateEdgeOnSelect)&&(identical(other.pathBuilder, pathBuilder) || other.pathBuilder == pathBuilder)&&(identical(other.foregroundPainter, foregroundPainter) || other.foregroundPainter == foregroundPainter));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,id,sourceNodeId,targetNodeId,sourceHandleId,targetHandleId,zIndex,type,interactionWidth,label,overlayLabel,labelDecoration,startMarkerStyle,endMarkerStyle,style,const DeepCollectionEquality().hash(_data),animated,animationEffect,hidden,deletable,selectable,focusable,semanticsLabel,reconnectable,elevateEdgeOnSelect,pathBuilder,foregroundPainter]);

@override
String toString() {
  return 'FlowEdge(id: $id, sourceNodeId: $sourceNodeId, targetNodeId: $targetNodeId, sourceHandleId: $sourceHandleId, targetHandleId: $targetHandleId, zIndex: $zIndex, type: $type, interactionWidth: $interactionWidth, label: $label, overlayLabel: $overlayLabel, labelDecoration: $labelDecoration, startMarkerStyle: $startMarkerStyle, endMarkerStyle: $endMarkerStyle, style: $style, data: $data, animated: $animated, animationEffect: $animationEffect, hidden: $hidden, deletable: $deletable, selectable: $selectable, focusable: $focusable, semanticsLabel: $semanticsLabel, reconnectable: $reconnectable, elevateEdgeOnSelect: $elevateEdgeOnSelect, pathBuilder: $pathBuilder, foregroundPainter: $foregroundPainter)';
}


}

/// @nodoc
abstract mixin class _$FlowEdgeCopyWith<$Res> implements $FlowEdgeCopyWith<$Res> {
  factory _$FlowEdgeCopyWith(_FlowEdge value, $Res Function(_FlowEdge) _then) = __$FlowEdgeCopyWithImpl;
@override @useResult
$Res call({
 String id, String sourceNodeId, String targetNodeId, String? sourceHandleId, String? targetHandleId, int zIndex, EdgePathType type, double interactionWidth,@JsonKey(ignore: true) Widget? label,@JsonKey(ignore: true) Widget? overlayLabel,@JsonKey(ignore: true) FlowEdgeLabelStyle? labelDecoration,@JsonKey(ignore: true) FlowEdgeMarkerStyle? startMarkerStyle,@JsonKey(ignore: true) FlowEdgeMarkerStyle? endMarkerStyle,@JsonKey(ignore: true) FlowEdgeStyle? style, Map<String, dynamic> data, bool animated,@JsonKey(includeFromJson: false, includeToJson: false) EdgeAnimationEffect? animationEffect, bool? hidden, bool? deletable, bool? selectable, bool? focusable, String? semanticsLabel, bool? reconnectable, bool? elevateEdgeOnSelect,@JsonKey(ignore: true) FlowEdgePathBuilder? pathBuilder,@JsonKey(ignore: true) FlowEdgeForegroundPainter? foregroundPainter
});




}
/// @nodoc
class __$FlowEdgeCopyWithImpl<$Res>
    implements _$FlowEdgeCopyWith<$Res> {
  __$FlowEdgeCopyWithImpl(this._self, this._then);

  final _FlowEdge _self;
  final $Res Function(_FlowEdge) _then;

/// Create a copy of FlowEdge
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sourceNodeId = null,Object? targetNodeId = null,Object? sourceHandleId = freezed,Object? targetHandleId = freezed,Object? zIndex = null,Object? type = null,Object? interactionWidth = null,Object? label = freezed,Object? overlayLabel = freezed,Object? labelDecoration = freezed,Object? startMarkerStyle = freezed,Object? endMarkerStyle = freezed,Object? style = freezed,Object? data = null,Object? animated = null,Object? animationEffect = freezed,Object? hidden = freezed,Object? deletable = freezed,Object? selectable = freezed,Object? focusable = freezed,Object? semanticsLabel = freezed,Object? reconnectable = freezed,Object? elevateEdgeOnSelect = freezed,Object? pathBuilder = freezed,Object? foregroundPainter = freezed,}) {
  return _then(_FlowEdge(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sourceNodeId: null == sourceNodeId ? _self.sourceNodeId : sourceNodeId // ignore: cast_nullable_to_non_nullable
as String,targetNodeId: null == targetNodeId ? _self.targetNodeId : targetNodeId // ignore: cast_nullable_to_non_nullable
as String,sourceHandleId: freezed == sourceHandleId ? _self.sourceHandleId : sourceHandleId // ignore: cast_nullable_to_non_nullable
as String?,targetHandleId: freezed == targetHandleId ? _self.targetHandleId : targetHandleId // ignore: cast_nullable_to_non_nullable
as String?,zIndex: null == zIndex ? _self.zIndex : zIndex // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as EdgePathType,interactionWidth: null == interactionWidth ? _self.interactionWidth : interactionWidth // ignore: cast_nullable_to_non_nullable
as double,label: freezed == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as Widget?,overlayLabel: freezed == overlayLabel ? _self.overlayLabel : overlayLabel // ignore: cast_nullable_to_non_nullable
as Widget?,labelDecoration: freezed == labelDecoration ? _self.labelDecoration : labelDecoration // ignore: cast_nullable_to_non_nullable
as FlowEdgeLabelStyle?,startMarkerStyle: freezed == startMarkerStyle ? _self.startMarkerStyle : startMarkerStyle // ignore: cast_nullable_to_non_nullable
as FlowEdgeMarkerStyle?,endMarkerStyle: freezed == endMarkerStyle ? _self.endMarkerStyle : endMarkerStyle // ignore: cast_nullable_to_non_nullable
as FlowEdgeMarkerStyle?,style: freezed == style ? _self.style : style // ignore: cast_nullable_to_non_nullable
as FlowEdgeStyle?,data: null == data ? _self._data : data // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,animated: null == animated ? _self.animated : animated // ignore: cast_nullable_to_non_nullable
as bool,animationEffect: freezed == animationEffect ? _self.animationEffect : animationEffect // ignore: cast_nullable_to_non_nullable
as EdgeAnimationEffect?,hidden: freezed == hidden ? _self.hidden : hidden // ignore: cast_nullable_to_non_nullable
as bool?,deletable: freezed == deletable ? _self.deletable : deletable // ignore: cast_nullable_to_non_nullable
as bool?,selectable: freezed == selectable ? _self.selectable : selectable // ignore: cast_nullable_to_non_nullable
as bool?,focusable: freezed == focusable ? _self.focusable : focusable // ignore: cast_nullable_to_non_nullable
as bool?,semanticsLabel: freezed == semanticsLabel ? _self.semanticsLabel : semanticsLabel // ignore: cast_nullable_to_non_nullable
as String?,reconnectable: freezed == reconnectable ? _self.reconnectable : reconnectable // ignore: cast_nullable_to_non_nullable
as bool?,elevateEdgeOnSelect: freezed == elevateEdgeOnSelect ? _self.elevateEdgeOnSelect : elevateEdgeOnSelect // ignore: cast_nullable_to_non_nullable
as bool?,pathBuilder: freezed == pathBuilder ? _self.pathBuilder : pathBuilder // ignore: cast_nullable_to_non_nullable
as FlowEdgePathBuilder?,foregroundPainter: freezed == foregroundPainter ? _self.foregroundPainter : foregroundPainter // ignore: cast_nullable_to_non_nullable
as FlowEdgeForegroundPainter?,
  ));
}


}

// dart format on
