// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'flow_canvas_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FlowCanvasState {

// Core graph data
@NodeMapConverter() Map<String, FlowNode> get nodes; Map<String, FlowEdge> get edges;// Runtime node/edge/handle states
@JsonKey(includeFromJson: false, includeToJson: false) Map<String, NodeRuntimeState> get nodeStates;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, EdgeRuntimeState> get edgeStates;@JsonKey(includeFromJson: false, includeToJson: false) Map<String, HandleRuntimeState> get handleStates;// Selection and z-ordering
 Set<String> get selectedNodes; Set<String> get selectedEdges; int get minZIndex; int get maxZIndex;// Viewport
 FlowViewport get viewport;@SizeConverter() Size? get viewportSize; bool get isPanZoomLocked;// full canvas freeze (not React Flow interactive-only)
/// Master element-interaction switch (React Flow `setInteractive` /
/// Controls `showInteractive`): node drag/select, edge select,
/// connection starts, and marquee selection. Viewport pan/zoom,
/// pointer observations, and programmatic APIs are unaffected.
@JsonKey(includeFromJson: false, includeToJson: false) bool get interactive;// Interaction state
@JsonKey(includeFromJson: false, includeToJson: false) DragMode get dragMode;@JsonKey(includeFromJson: false, includeToJson: false) FlowConnection? get activeConnection;@JsonKey(includeFromJson: false, includeToJson: false) FlowConnectionRuntimeState get connectionState;@RectConverter()@JsonKey(includeFromJson: false, includeToJson: false) Rect get selectionRect;@JsonKey(includeFromJson: false, includeToJson: false) String get hoveredEdgeId;@JsonKey(includeFromJson: false, includeToJson: false) String get lastClickedEdgeId;/// Bumps when edge paths / geometry cache changes (not on viewport pan).
@JsonKey(includeFromJson: false, includeToJson: false) int get geometryRevision;/// Incremented during node drag so edge [CustomPaint] repaints without hashing all positions.
@JsonKey(includeFromJson: false, includeToJson: false) int get edgeLiveStamp;/// Epoch counters for O(1) selector comparisons (perf invariant).
/// Bumped exactly when the corresponding collection changes so watchers
/// can subscribe to the int instead of deep-comparing the collection.
@JsonKey(includeFromJson: false, includeToJson: false) int get selectionEpoch;@JsonKey(includeFromJson: false, includeToJson: false) int get zOrderEpoch;@JsonKey(includeFromJson: false, includeToJson: false) int get runtimeEpoch;
/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FlowCanvasStateCopyWith<FlowCanvasState> get copyWith => _$FlowCanvasStateCopyWithImpl<FlowCanvasState>(this as FlowCanvasState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FlowCanvasState&&const DeepCollectionEquality().equals(other.nodes, nodes)&&const DeepCollectionEquality().equals(other.edges, edges)&&const DeepCollectionEquality().equals(other.nodeStates, nodeStates)&&const DeepCollectionEquality().equals(other.edgeStates, edgeStates)&&const DeepCollectionEquality().equals(other.handleStates, handleStates)&&const DeepCollectionEquality().equals(other.selectedNodes, selectedNodes)&&const DeepCollectionEquality().equals(other.selectedEdges, selectedEdges)&&(identical(other.minZIndex, minZIndex) || other.minZIndex == minZIndex)&&(identical(other.maxZIndex, maxZIndex) || other.maxZIndex == maxZIndex)&&(identical(other.viewport, viewport) || other.viewport == viewport)&&(identical(other.viewportSize, viewportSize) || other.viewportSize == viewportSize)&&(identical(other.isPanZoomLocked, isPanZoomLocked) || other.isPanZoomLocked == isPanZoomLocked)&&(identical(other.interactive, interactive) || other.interactive == interactive)&&(identical(other.dragMode, dragMode) || other.dragMode == dragMode)&&(identical(other.activeConnection, activeConnection) || other.activeConnection == activeConnection)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState)&&(identical(other.selectionRect, selectionRect) || other.selectionRect == selectionRect)&&(identical(other.hoveredEdgeId, hoveredEdgeId) || other.hoveredEdgeId == hoveredEdgeId)&&(identical(other.lastClickedEdgeId, lastClickedEdgeId) || other.lastClickedEdgeId == lastClickedEdgeId)&&(identical(other.geometryRevision, geometryRevision) || other.geometryRevision == geometryRevision)&&(identical(other.edgeLiveStamp, edgeLiveStamp) || other.edgeLiveStamp == edgeLiveStamp)&&(identical(other.selectionEpoch, selectionEpoch) || other.selectionEpoch == selectionEpoch)&&(identical(other.zOrderEpoch, zOrderEpoch) || other.zOrderEpoch == zOrderEpoch)&&(identical(other.runtimeEpoch, runtimeEpoch) || other.runtimeEpoch == runtimeEpoch));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(nodes),const DeepCollectionEquality().hash(edges),const DeepCollectionEquality().hash(nodeStates),const DeepCollectionEquality().hash(edgeStates),const DeepCollectionEquality().hash(handleStates),const DeepCollectionEquality().hash(selectedNodes),const DeepCollectionEquality().hash(selectedEdges),minZIndex,maxZIndex,viewport,viewportSize,isPanZoomLocked,interactive,dragMode,activeConnection,connectionState,selectionRect,hoveredEdgeId,lastClickedEdgeId,geometryRevision,edgeLiveStamp,selectionEpoch,zOrderEpoch,runtimeEpoch]);

@override
String toString() {
  return 'FlowCanvasState(nodes: $nodes, edges: $edges, nodeStates: $nodeStates, edgeStates: $edgeStates, handleStates: $handleStates, selectedNodes: $selectedNodes, selectedEdges: $selectedEdges, minZIndex: $minZIndex, maxZIndex: $maxZIndex, viewport: $viewport, viewportSize: $viewportSize, isPanZoomLocked: $isPanZoomLocked, interactive: $interactive, dragMode: $dragMode, activeConnection: $activeConnection, connectionState: $connectionState, selectionRect: $selectionRect, hoveredEdgeId: $hoveredEdgeId, lastClickedEdgeId: $lastClickedEdgeId, geometryRevision: $geometryRevision, edgeLiveStamp: $edgeLiveStamp, selectionEpoch: $selectionEpoch, zOrderEpoch: $zOrderEpoch, runtimeEpoch: $runtimeEpoch)';
}


}

/// @nodoc
abstract mixin class $FlowCanvasStateCopyWith<$Res>  {
  factory $FlowCanvasStateCopyWith(FlowCanvasState value, $Res Function(FlowCanvasState) _then) = _$FlowCanvasStateCopyWithImpl;
@useResult
$Res call({
@NodeMapConverter() Map<String, FlowNode> nodes, Map<String, FlowEdge> edges,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, NodeRuntimeState> nodeStates,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, EdgeRuntimeState> edgeStates,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, HandleRuntimeState> handleStates, Set<String> selectedNodes, Set<String> selectedEdges, int minZIndex, int maxZIndex, FlowViewport viewport,@SizeConverter() Size? viewportSize, bool isPanZoomLocked,@JsonKey(includeFromJson: false, includeToJson: false) bool interactive,@JsonKey(includeFromJson: false, includeToJson: false) DragMode dragMode,@JsonKey(includeFromJson: false, includeToJson: false) FlowConnection? activeConnection,@JsonKey(includeFromJson: false, includeToJson: false) FlowConnectionRuntimeState connectionState,@RectConverter()@JsonKey(includeFromJson: false, includeToJson: false) Rect selectionRect,@JsonKey(includeFromJson: false, includeToJson: false) String hoveredEdgeId,@JsonKey(includeFromJson: false, includeToJson: false) String lastClickedEdgeId,@JsonKey(includeFromJson: false, includeToJson: false) int geometryRevision,@JsonKey(includeFromJson: false, includeToJson: false) int edgeLiveStamp,@JsonKey(includeFromJson: false, includeToJson: false) int selectionEpoch,@JsonKey(includeFromJson: false, includeToJson: false) int zOrderEpoch,@JsonKey(includeFromJson: false, includeToJson: false) int runtimeEpoch
});


$FlowViewportCopyWith<$Res> get viewport;$FlowConnectionCopyWith<$Res>? get activeConnection;$FlowConnectionRuntimeStateCopyWith<$Res> get connectionState;

}
/// @nodoc
class _$FlowCanvasStateCopyWithImpl<$Res>
    implements $FlowCanvasStateCopyWith<$Res> {
  _$FlowCanvasStateCopyWithImpl(this._self, this._then);

  final FlowCanvasState _self;
  final $Res Function(FlowCanvasState) _then;

/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,Object? edges = null,Object? nodeStates = null,Object? edgeStates = null,Object? handleStates = null,Object? selectedNodes = null,Object? selectedEdges = null,Object? minZIndex = null,Object? maxZIndex = null,Object? viewport = null,Object? viewportSize = freezed,Object? isPanZoomLocked = null,Object? interactive = null,Object? dragMode = null,Object? activeConnection = freezed,Object? connectionState = null,Object? selectionRect = null,Object? hoveredEdgeId = null,Object? lastClickedEdgeId = null,Object? geometryRevision = null,Object? edgeLiveStamp = null,Object? selectionEpoch = null,Object? zOrderEpoch = null,Object? runtimeEpoch = null,}) {
  return _then(_self.copyWith(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<String, FlowNode>,edges: null == edges ? _self.edges : edges // ignore: cast_nullable_to_non_nullable
as Map<String, FlowEdge>,nodeStates: null == nodeStates ? _self.nodeStates : nodeStates // ignore: cast_nullable_to_non_nullable
as Map<String, NodeRuntimeState>,edgeStates: null == edgeStates ? _self.edgeStates : edgeStates // ignore: cast_nullable_to_non_nullable
as Map<String, EdgeRuntimeState>,handleStates: null == handleStates ? _self.handleStates : handleStates // ignore: cast_nullable_to_non_nullable
as Map<String, HandleRuntimeState>,selectedNodes: null == selectedNodes ? _self.selectedNodes : selectedNodes // ignore: cast_nullable_to_non_nullable
as Set<String>,selectedEdges: null == selectedEdges ? _self.selectedEdges : selectedEdges // ignore: cast_nullable_to_non_nullable
as Set<String>,minZIndex: null == minZIndex ? _self.minZIndex : minZIndex // ignore: cast_nullable_to_non_nullable
as int,maxZIndex: null == maxZIndex ? _self.maxZIndex : maxZIndex // ignore: cast_nullable_to_non_nullable
as int,viewport: null == viewport ? _self.viewport : viewport // ignore: cast_nullable_to_non_nullable
as FlowViewport,viewportSize: freezed == viewportSize ? _self.viewportSize : viewportSize // ignore: cast_nullable_to_non_nullable
as Size?,isPanZoomLocked: null == isPanZoomLocked ? _self.isPanZoomLocked : isPanZoomLocked // ignore: cast_nullable_to_non_nullable
as bool,interactive: null == interactive ? _self.interactive : interactive // ignore: cast_nullable_to_non_nullable
as bool,dragMode: null == dragMode ? _self.dragMode : dragMode // ignore: cast_nullable_to_non_nullable
as DragMode,activeConnection: freezed == activeConnection ? _self.activeConnection : activeConnection // ignore: cast_nullable_to_non_nullable
as FlowConnection?,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as FlowConnectionRuntimeState,selectionRect: null == selectionRect ? _self.selectionRect : selectionRect // ignore: cast_nullable_to_non_nullable
as Rect,hoveredEdgeId: null == hoveredEdgeId ? _self.hoveredEdgeId : hoveredEdgeId // ignore: cast_nullable_to_non_nullable
as String,lastClickedEdgeId: null == lastClickedEdgeId ? _self.lastClickedEdgeId : lastClickedEdgeId // ignore: cast_nullable_to_non_nullable
as String,geometryRevision: null == geometryRevision ? _self.geometryRevision : geometryRevision // ignore: cast_nullable_to_non_nullable
as int,edgeLiveStamp: null == edgeLiveStamp ? _self.edgeLiveStamp : edgeLiveStamp // ignore: cast_nullable_to_non_nullable
as int,selectionEpoch: null == selectionEpoch ? _self.selectionEpoch : selectionEpoch // ignore: cast_nullable_to_non_nullable
as int,zOrderEpoch: null == zOrderEpoch ? _self.zOrderEpoch : zOrderEpoch // ignore: cast_nullable_to_non_nullable
as int,runtimeEpoch: null == runtimeEpoch ? _self.runtimeEpoch : runtimeEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowViewportCopyWith<$Res> get viewport {
  
  return $FlowViewportCopyWith<$Res>(_self.viewport, (value) {
    return _then(_self.copyWith(viewport: value));
  });
}/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowConnectionCopyWith<$Res>? get activeConnection {
    if (_self.activeConnection == null) {
    return null;
  }

  return $FlowConnectionCopyWith<$Res>(_self.activeConnection!, (value) {
    return _then(_self.copyWith(activeConnection: value));
  });
}/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowConnectionRuntimeStateCopyWith<$Res> get connectionState {
  
  return $FlowConnectionRuntimeStateCopyWith<$Res>(_self.connectionState, (value) {
    return _then(_self.copyWith(connectionState: value));
  });
}
}


/// Adds pattern-matching-related methods to [FlowCanvasState].
extension FlowCanvasStatePatterns on FlowCanvasState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FlowCanvasState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FlowCanvasState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FlowCanvasState value)  $default,){
final _that = this;
switch (_that) {
case _FlowCanvasState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FlowCanvasState value)?  $default,){
final _that = this;
switch (_that) {
case _FlowCanvasState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@NodeMapConverter()  Map<String, FlowNode> nodes,  Map<String, FlowEdge> edges, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, NodeRuntimeState> nodeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, EdgeRuntimeState> edgeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, HandleRuntimeState> handleStates,  Set<String> selectedNodes,  Set<String> selectedEdges,  int minZIndex,  int maxZIndex,  FlowViewport viewport, @SizeConverter()  Size? viewportSize,  bool isPanZoomLocked, @JsonKey(includeFromJson: false, includeToJson: false)  bool interactive, @JsonKey(includeFromJson: false, includeToJson: false)  DragMode dragMode, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnection? activeConnection, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnectionRuntimeState connectionState, @RectConverter()@JsonKey(includeFromJson: false, includeToJson: false)  Rect selectionRect, @JsonKey(includeFromJson: false, includeToJson: false)  String hoveredEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  String lastClickedEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  int geometryRevision, @JsonKey(includeFromJson: false, includeToJson: false)  int edgeLiveStamp, @JsonKey(includeFromJson: false, includeToJson: false)  int selectionEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int zOrderEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int runtimeEpoch)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FlowCanvasState() when $default != null:
return $default(_that.nodes,_that.edges,_that.nodeStates,_that.edgeStates,_that.handleStates,_that.selectedNodes,_that.selectedEdges,_that.minZIndex,_that.maxZIndex,_that.viewport,_that.viewportSize,_that.isPanZoomLocked,_that.interactive,_that.dragMode,_that.activeConnection,_that.connectionState,_that.selectionRect,_that.hoveredEdgeId,_that.lastClickedEdgeId,_that.geometryRevision,_that.edgeLiveStamp,_that.selectionEpoch,_that.zOrderEpoch,_that.runtimeEpoch);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@NodeMapConverter()  Map<String, FlowNode> nodes,  Map<String, FlowEdge> edges, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, NodeRuntimeState> nodeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, EdgeRuntimeState> edgeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, HandleRuntimeState> handleStates,  Set<String> selectedNodes,  Set<String> selectedEdges,  int minZIndex,  int maxZIndex,  FlowViewport viewport, @SizeConverter()  Size? viewportSize,  bool isPanZoomLocked, @JsonKey(includeFromJson: false, includeToJson: false)  bool interactive, @JsonKey(includeFromJson: false, includeToJson: false)  DragMode dragMode, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnection? activeConnection, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnectionRuntimeState connectionState, @RectConverter()@JsonKey(includeFromJson: false, includeToJson: false)  Rect selectionRect, @JsonKey(includeFromJson: false, includeToJson: false)  String hoveredEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  String lastClickedEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  int geometryRevision, @JsonKey(includeFromJson: false, includeToJson: false)  int edgeLiveStamp, @JsonKey(includeFromJson: false, includeToJson: false)  int selectionEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int zOrderEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int runtimeEpoch)  $default,) {final _that = this;
switch (_that) {
case _FlowCanvasState():
return $default(_that.nodes,_that.edges,_that.nodeStates,_that.edgeStates,_that.handleStates,_that.selectedNodes,_that.selectedEdges,_that.minZIndex,_that.maxZIndex,_that.viewport,_that.viewportSize,_that.isPanZoomLocked,_that.interactive,_that.dragMode,_that.activeConnection,_that.connectionState,_that.selectionRect,_that.hoveredEdgeId,_that.lastClickedEdgeId,_that.geometryRevision,_that.edgeLiveStamp,_that.selectionEpoch,_that.zOrderEpoch,_that.runtimeEpoch);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@NodeMapConverter()  Map<String, FlowNode> nodes,  Map<String, FlowEdge> edges, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, NodeRuntimeState> nodeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, EdgeRuntimeState> edgeStates, @JsonKey(includeFromJson: false, includeToJson: false)  Map<String, HandleRuntimeState> handleStates,  Set<String> selectedNodes,  Set<String> selectedEdges,  int minZIndex,  int maxZIndex,  FlowViewport viewport, @SizeConverter()  Size? viewportSize,  bool isPanZoomLocked, @JsonKey(includeFromJson: false, includeToJson: false)  bool interactive, @JsonKey(includeFromJson: false, includeToJson: false)  DragMode dragMode, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnection? activeConnection, @JsonKey(includeFromJson: false, includeToJson: false)  FlowConnectionRuntimeState connectionState, @RectConverter()@JsonKey(includeFromJson: false, includeToJson: false)  Rect selectionRect, @JsonKey(includeFromJson: false, includeToJson: false)  String hoveredEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  String lastClickedEdgeId, @JsonKey(includeFromJson: false, includeToJson: false)  int geometryRevision, @JsonKey(includeFromJson: false, includeToJson: false)  int edgeLiveStamp, @JsonKey(includeFromJson: false, includeToJson: false)  int selectionEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int zOrderEpoch, @JsonKey(includeFromJson: false, includeToJson: false)  int runtimeEpoch)?  $default,) {final _that = this;
switch (_that) {
case _FlowCanvasState() when $default != null:
return $default(_that.nodes,_that.edges,_that.nodeStates,_that.edgeStates,_that.handleStates,_that.selectedNodes,_that.selectedEdges,_that.minZIndex,_that.maxZIndex,_that.viewport,_that.viewportSize,_that.isPanZoomLocked,_that.interactive,_that.dragMode,_that.activeConnection,_that.connectionState,_that.selectionRect,_that.hoveredEdgeId,_that.lastClickedEdgeId,_that.geometryRevision,_that.edgeLiveStamp,_that.selectionEpoch,_that.zOrderEpoch,_that.runtimeEpoch);case _:
  return null;

}
}

}

/// @nodoc


class _FlowCanvasState extends FlowCanvasState {
  const _FlowCanvasState({@NodeMapConverter() final  Map<String, FlowNode> nodes = const {}, final  Map<String, FlowEdge> edges = const {}, @JsonKey(includeFromJson: false, includeToJson: false) final  Map<String, NodeRuntimeState> nodeStates = const {}, @JsonKey(includeFromJson: false, includeToJson: false) final  Map<String, EdgeRuntimeState> edgeStates = const {}, @JsonKey(includeFromJson: false, includeToJson: false) final  Map<String, HandleRuntimeState> handleStates = const {}, final  Set<String> selectedNodes = const {}, final  Set<String> selectedEdges = const {}, this.minZIndex = 0, this.maxZIndex = 0, this.viewport = const FlowViewport(), @SizeConverter() this.viewportSize, this.isPanZoomLocked = false, @JsonKey(includeFromJson: false, includeToJson: false) this.interactive = true, @JsonKey(includeFromJson: false, includeToJson: false) this.dragMode = DragMode.none, @JsonKey(includeFromJson: false, includeToJson: false) this.activeConnection, @JsonKey(includeFromJson: false, includeToJson: false) this.connectionState = const FlowConnectionRuntimeState.idle(), @RectConverter()@JsonKey(includeFromJson: false, includeToJson: false) this.selectionRect = Rect.zero, @JsonKey(includeFromJson: false, includeToJson: false) this.hoveredEdgeId = '', @JsonKey(includeFromJson: false, includeToJson: false) this.lastClickedEdgeId = '', @JsonKey(includeFromJson: false, includeToJson: false) this.geometryRevision = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.edgeLiveStamp = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.selectionEpoch = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.zOrderEpoch = 0, @JsonKey(includeFromJson: false, includeToJson: false) this.runtimeEpoch = 0}): _nodes = nodes,_edges = edges,_nodeStates = nodeStates,_edgeStates = edgeStates,_handleStates = handleStates,_selectedNodes = selectedNodes,_selectedEdges = selectedEdges,super._();
  

// Core graph data
 final  Map<String, FlowNode> _nodes;
// Core graph data
@override@JsonKey()@NodeMapConverter() Map<String, FlowNode> get nodes {
  if (_nodes is EqualUnmodifiableMapView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodes);
}

 final  Map<String, FlowEdge> _edges;
@override@JsonKey() Map<String, FlowEdge> get edges {
  if (_edges is EqualUnmodifiableMapView) return _edges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_edges);
}

// Runtime node/edge/handle states
 final  Map<String, NodeRuntimeState> _nodeStates;
// Runtime node/edge/handle states
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, NodeRuntimeState> get nodeStates {
  if (_nodeStates is EqualUnmodifiableMapView) return _nodeStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_nodeStates);
}

 final  Map<String, EdgeRuntimeState> _edgeStates;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, EdgeRuntimeState> get edgeStates {
  if (_edgeStates is EqualUnmodifiableMapView) return _edgeStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_edgeStates);
}

 final  Map<String, HandleRuntimeState> _handleStates;
@override@JsonKey(includeFromJson: false, includeToJson: false) Map<String, HandleRuntimeState> get handleStates {
  if (_handleStates is EqualUnmodifiableMapView) return _handleStates;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_handleStates);
}

// Selection and z-ordering
 final  Set<String> _selectedNodes;
// Selection and z-ordering
@override@JsonKey() Set<String> get selectedNodes {
  if (_selectedNodes is EqualUnmodifiableSetView) return _selectedNodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedNodes);
}

 final  Set<String> _selectedEdges;
@override@JsonKey() Set<String> get selectedEdges {
  if (_selectedEdges is EqualUnmodifiableSetView) return _selectedEdges;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_selectedEdges);
}

@override@JsonKey() final  int minZIndex;
@override@JsonKey() final  int maxZIndex;
// Viewport
@override@JsonKey() final  FlowViewport viewport;
@override@SizeConverter() final  Size? viewportSize;
@override@JsonKey() final  bool isPanZoomLocked;
// full canvas freeze (not React Flow interactive-only)
/// Master element-interaction switch (React Flow `setInteractive` /
/// Controls `showInteractive`): node drag/select, edge select,
/// connection starts, and marquee selection. Viewport pan/zoom,
/// pointer observations, and programmatic APIs are unaffected.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  bool interactive;
// Interaction state
@override@JsonKey(includeFromJson: false, includeToJson: false) final  DragMode dragMode;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  FlowConnection? activeConnection;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  FlowConnectionRuntimeState connectionState;
@override@RectConverter()@JsonKey(includeFromJson: false, includeToJson: false) final  Rect selectionRect;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String hoveredEdgeId;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  String lastClickedEdgeId;
/// Bumps when edge paths / geometry cache changes (not on viewport pan).
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int geometryRevision;
/// Incremented during node drag so edge [CustomPaint] repaints without hashing all positions.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int edgeLiveStamp;
/// Epoch counters for O(1) selector comparisons (perf invariant).
/// Bumped exactly when the corresponding collection changes so watchers
/// can subscribe to the int instead of deep-comparing the collection.
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int selectionEpoch;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int zOrderEpoch;
@override@JsonKey(includeFromJson: false, includeToJson: false) final  int runtimeEpoch;

/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FlowCanvasStateCopyWith<_FlowCanvasState> get copyWith => __$FlowCanvasStateCopyWithImpl<_FlowCanvasState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FlowCanvasState&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&const DeepCollectionEquality().equals(other._edges, _edges)&&const DeepCollectionEquality().equals(other._nodeStates, _nodeStates)&&const DeepCollectionEquality().equals(other._edgeStates, _edgeStates)&&const DeepCollectionEquality().equals(other._handleStates, _handleStates)&&const DeepCollectionEquality().equals(other._selectedNodes, _selectedNodes)&&const DeepCollectionEquality().equals(other._selectedEdges, _selectedEdges)&&(identical(other.minZIndex, minZIndex) || other.minZIndex == minZIndex)&&(identical(other.maxZIndex, maxZIndex) || other.maxZIndex == maxZIndex)&&(identical(other.viewport, viewport) || other.viewport == viewport)&&(identical(other.viewportSize, viewportSize) || other.viewportSize == viewportSize)&&(identical(other.isPanZoomLocked, isPanZoomLocked) || other.isPanZoomLocked == isPanZoomLocked)&&(identical(other.interactive, interactive) || other.interactive == interactive)&&(identical(other.dragMode, dragMode) || other.dragMode == dragMode)&&(identical(other.activeConnection, activeConnection) || other.activeConnection == activeConnection)&&(identical(other.connectionState, connectionState) || other.connectionState == connectionState)&&(identical(other.selectionRect, selectionRect) || other.selectionRect == selectionRect)&&(identical(other.hoveredEdgeId, hoveredEdgeId) || other.hoveredEdgeId == hoveredEdgeId)&&(identical(other.lastClickedEdgeId, lastClickedEdgeId) || other.lastClickedEdgeId == lastClickedEdgeId)&&(identical(other.geometryRevision, geometryRevision) || other.geometryRevision == geometryRevision)&&(identical(other.edgeLiveStamp, edgeLiveStamp) || other.edgeLiveStamp == edgeLiveStamp)&&(identical(other.selectionEpoch, selectionEpoch) || other.selectionEpoch == selectionEpoch)&&(identical(other.zOrderEpoch, zOrderEpoch) || other.zOrderEpoch == zOrderEpoch)&&(identical(other.runtimeEpoch, runtimeEpoch) || other.runtimeEpoch == runtimeEpoch));
}


@override
int get hashCode => Object.hashAll([runtimeType,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_edges),const DeepCollectionEquality().hash(_nodeStates),const DeepCollectionEquality().hash(_edgeStates),const DeepCollectionEquality().hash(_handleStates),const DeepCollectionEquality().hash(_selectedNodes),const DeepCollectionEquality().hash(_selectedEdges),minZIndex,maxZIndex,viewport,viewportSize,isPanZoomLocked,interactive,dragMode,activeConnection,connectionState,selectionRect,hoveredEdgeId,lastClickedEdgeId,geometryRevision,edgeLiveStamp,selectionEpoch,zOrderEpoch,runtimeEpoch]);

@override
String toString() {
  return 'FlowCanvasState(nodes: $nodes, edges: $edges, nodeStates: $nodeStates, edgeStates: $edgeStates, handleStates: $handleStates, selectedNodes: $selectedNodes, selectedEdges: $selectedEdges, minZIndex: $minZIndex, maxZIndex: $maxZIndex, viewport: $viewport, viewportSize: $viewportSize, isPanZoomLocked: $isPanZoomLocked, interactive: $interactive, dragMode: $dragMode, activeConnection: $activeConnection, connectionState: $connectionState, selectionRect: $selectionRect, hoveredEdgeId: $hoveredEdgeId, lastClickedEdgeId: $lastClickedEdgeId, geometryRevision: $geometryRevision, edgeLiveStamp: $edgeLiveStamp, selectionEpoch: $selectionEpoch, zOrderEpoch: $zOrderEpoch, runtimeEpoch: $runtimeEpoch)';
}


}

/// @nodoc
abstract mixin class _$FlowCanvasStateCopyWith<$Res> implements $FlowCanvasStateCopyWith<$Res> {
  factory _$FlowCanvasStateCopyWith(_FlowCanvasState value, $Res Function(_FlowCanvasState) _then) = __$FlowCanvasStateCopyWithImpl;
@override @useResult
$Res call({
@NodeMapConverter() Map<String, FlowNode> nodes, Map<String, FlowEdge> edges,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, NodeRuntimeState> nodeStates,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, EdgeRuntimeState> edgeStates,@JsonKey(includeFromJson: false, includeToJson: false) Map<String, HandleRuntimeState> handleStates, Set<String> selectedNodes, Set<String> selectedEdges, int minZIndex, int maxZIndex, FlowViewport viewport,@SizeConverter() Size? viewportSize, bool isPanZoomLocked,@JsonKey(includeFromJson: false, includeToJson: false) bool interactive,@JsonKey(includeFromJson: false, includeToJson: false) DragMode dragMode,@JsonKey(includeFromJson: false, includeToJson: false) FlowConnection? activeConnection,@JsonKey(includeFromJson: false, includeToJson: false) FlowConnectionRuntimeState connectionState,@RectConverter()@JsonKey(includeFromJson: false, includeToJson: false) Rect selectionRect,@JsonKey(includeFromJson: false, includeToJson: false) String hoveredEdgeId,@JsonKey(includeFromJson: false, includeToJson: false) String lastClickedEdgeId,@JsonKey(includeFromJson: false, includeToJson: false) int geometryRevision,@JsonKey(includeFromJson: false, includeToJson: false) int edgeLiveStamp,@JsonKey(includeFromJson: false, includeToJson: false) int selectionEpoch,@JsonKey(includeFromJson: false, includeToJson: false) int zOrderEpoch,@JsonKey(includeFromJson: false, includeToJson: false) int runtimeEpoch
});


@override $FlowViewportCopyWith<$Res> get viewport;@override $FlowConnectionCopyWith<$Res>? get activeConnection;@override $FlowConnectionRuntimeStateCopyWith<$Res> get connectionState;

}
/// @nodoc
class __$FlowCanvasStateCopyWithImpl<$Res>
    implements _$FlowCanvasStateCopyWith<$Res> {
  __$FlowCanvasStateCopyWithImpl(this._self, this._then);

  final _FlowCanvasState _self;
  final $Res Function(_FlowCanvasState) _then;

/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,Object? edges = null,Object? nodeStates = null,Object? edgeStates = null,Object? handleStates = null,Object? selectedNodes = null,Object? selectedEdges = null,Object? minZIndex = null,Object? maxZIndex = null,Object? viewport = null,Object? viewportSize = freezed,Object? isPanZoomLocked = null,Object? interactive = null,Object? dragMode = null,Object? activeConnection = freezed,Object? connectionState = null,Object? selectionRect = null,Object? hoveredEdgeId = null,Object? lastClickedEdgeId = null,Object? geometryRevision = null,Object? edgeLiveStamp = null,Object? selectionEpoch = null,Object? zOrderEpoch = null,Object? runtimeEpoch = null,}) {
  return _then(_FlowCanvasState(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as Map<String, FlowNode>,edges: null == edges ? _self._edges : edges // ignore: cast_nullable_to_non_nullable
as Map<String, FlowEdge>,nodeStates: null == nodeStates ? _self._nodeStates : nodeStates // ignore: cast_nullable_to_non_nullable
as Map<String, NodeRuntimeState>,edgeStates: null == edgeStates ? _self._edgeStates : edgeStates // ignore: cast_nullable_to_non_nullable
as Map<String, EdgeRuntimeState>,handleStates: null == handleStates ? _self._handleStates : handleStates // ignore: cast_nullable_to_non_nullable
as Map<String, HandleRuntimeState>,selectedNodes: null == selectedNodes ? _self._selectedNodes : selectedNodes // ignore: cast_nullable_to_non_nullable
as Set<String>,selectedEdges: null == selectedEdges ? _self._selectedEdges : selectedEdges // ignore: cast_nullable_to_non_nullable
as Set<String>,minZIndex: null == minZIndex ? _self.minZIndex : minZIndex // ignore: cast_nullable_to_non_nullable
as int,maxZIndex: null == maxZIndex ? _self.maxZIndex : maxZIndex // ignore: cast_nullable_to_non_nullable
as int,viewport: null == viewport ? _self.viewport : viewport // ignore: cast_nullable_to_non_nullable
as FlowViewport,viewportSize: freezed == viewportSize ? _self.viewportSize : viewportSize // ignore: cast_nullable_to_non_nullable
as Size?,isPanZoomLocked: null == isPanZoomLocked ? _self.isPanZoomLocked : isPanZoomLocked // ignore: cast_nullable_to_non_nullable
as bool,interactive: null == interactive ? _self.interactive : interactive // ignore: cast_nullable_to_non_nullable
as bool,dragMode: null == dragMode ? _self.dragMode : dragMode // ignore: cast_nullable_to_non_nullable
as DragMode,activeConnection: freezed == activeConnection ? _self.activeConnection : activeConnection // ignore: cast_nullable_to_non_nullable
as FlowConnection?,connectionState: null == connectionState ? _self.connectionState : connectionState // ignore: cast_nullable_to_non_nullable
as FlowConnectionRuntimeState,selectionRect: null == selectionRect ? _self.selectionRect : selectionRect // ignore: cast_nullable_to_non_nullable
as Rect,hoveredEdgeId: null == hoveredEdgeId ? _self.hoveredEdgeId : hoveredEdgeId // ignore: cast_nullable_to_non_nullable
as String,lastClickedEdgeId: null == lastClickedEdgeId ? _self.lastClickedEdgeId : lastClickedEdgeId // ignore: cast_nullable_to_non_nullable
as String,geometryRevision: null == geometryRevision ? _self.geometryRevision : geometryRevision // ignore: cast_nullable_to_non_nullable
as int,edgeLiveStamp: null == edgeLiveStamp ? _self.edgeLiveStamp : edgeLiveStamp // ignore: cast_nullable_to_non_nullable
as int,selectionEpoch: null == selectionEpoch ? _self.selectionEpoch : selectionEpoch // ignore: cast_nullable_to_non_nullable
as int,zOrderEpoch: null == zOrderEpoch ? _self.zOrderEpoch : zOrderEpoch // ignore: cast_nullable_to_non_nullable
as int,runtimeEpoch: null == runtimeEpoch ? _self.runtimeEpoch : runtimeEpoch // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowViewportCopyWith<$Res> get viewport {
  
  return $FlowViewportCopyWith<$Res>(_self.viewport, (value) {
    return _then(_self.copyWith(viewport: value));
  });
}/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowConnectionCopyWith<$Res>? get activeConnection {
    if (_self.activeConnection == null) {
    return null;
  }

  return $FlowConnectionCopyWith<$Res>(_self.activeConnection!, (value) {
    return _then(_self.copyWith(activeConnection: value));
  });
}/// Create a copy of FlowCanvasState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FlowConnectionRuntimeStateCopyWith<$Res> get connectionState {
  
  return $FlowConnectionRuntimeStateCopyWith<$Res>(_self.connectionState, (value) {
    return _then(_self.copyWith(connectionState: value));
  });
}
}

// dart format on
