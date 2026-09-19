import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/theme/components/connection_theme.dart';
import 'package:lattice/src/features/dataflow/application/flow_dataflow.dart';
import 'package:flutter/foundation.dart';

/// canvas-style connection / connection-line options.
///
/// Maps to Lattice props: `connectionMode`, `connectionRadius`, `connectOnClick`,
/// `connectionLineType`, `connectionLineStyle`, `connectionLineComponent`,
/// plus whether the library auto-inserts the edge.
@immutable
class ConnectionOptions with Diagnosticable {
  /// Strict = source→target only; loose = any handle pair (Lattice `connectionMode`).
  final ConnectionMode connectionMode;

  /// Snap radius in **screen pixels** around a handle (Lattice `connectionRadius`).
  final double connectionRadius;

  /// Click a source handle, then a target, to connect (Lattice `connectOnClick`,
  /// default true).
  final bool connectOnClick;

  /// Path type for the live connection line (Lattice `connectionLineType`).
  ///
  /// When null, uses [FlowConnectionStyle.pathType] from the theme.
  final EdgePathType? connectionLineType;

  /// Style override for the live connection line (Lattice
  /// `connectionLineStyle`). Merged over the theme, under a
  /// per-connection `connectionStyle` when both are set.
  final FlowConnectionStyle? connectionLineStyle;

  /// Custom connection-line widget (Lattice `connectionLineComponent`).
  ///
  /// Replaces the painted rubber-band while a drag is active. Compared by
  /// identity in `==` (a new closure instance counts as a change, like a
  /// re-rendered component prop).
  final FlowConnectionLineBuilder? connectionLineBuilder;

  /// When true (default), a completed drag/click inserts a [FlowEdge].
  /// When false, only [FlowCanvasCallbacks.onConnection] fires — Lattice controlled style.
  final bool autoCreateEdge;

  /// Allow dragging edge endpoints to reconnect (Lattice `edgesReconnectable`).
  final bool edgesReconnectable;

  /// Hit radius in screen px for edge reconnect endpoints.
  final double reconnectRadius;

  /// Drag threshold in flow px before a handle press becomes a connection
  /// drag (Lattice `connectionDragThreshold`, default 1). Below it, the
  /// press stays a click (click-connect). Prevents accidental rubber-bands.
  final double connectionDragThreshold;

  const ConnectionOptions({
    this.connectionMode = ConnectionMode.strict,
    this.connectionRadius = 20.0,
    this.connectOnClick = true,
    this.connectionLineType,
    this.connectionLineStyle,
    this.connectionLineBuilder,
    this.autoCreateEdge = true,
    this.edgesReconnectable = true,
    this.reconnectRadius = 10.0,
    this.connectionDragThreshold = 1.0,
  })  : assert(connectionRadius > 0),
        assert(reconnectRadius > 0),
        assert(connectionDragThreshold >= 0);

  const ConnectionOptions.readOnly()
      : connectionMode = ConnectionMode.strict,
        connectionRadius = 20.0,
        connectOnClick = false,
        connectionLineType = null,
        connectionLineStyle = null,
        connectionLineBuilder = null,
        autoCreateEdge = false,
        edgesReconnectable = false,
        reconnectRadius = 10.0,
        connectionDragThreshold = 1.0;

  ConnectionOptions copyWith({
    ConnectionMode? connectionMode,
    double? connectionRadius,
    bool? connectOnClick,
    EdgePathType? connectionLineType,
    bool clearConnectionLineType = false,
    FlowConnectionStyle? connectionLineStyle,
    bool clearConnectionLineStyle = false,
    FlowConnectionLineBuilder? connectionLineBuilder,
    bool clearConnectionLineBuilder = false,
    bool? autoCreateEdge,
    bool? edgesReconnectable,
    double? reconnectRadius,
    double? connectionDragThreshold,
  }) {
    return ConnectionOptions(
      connectionMode: connectionMode ?? this.connectionMode,
      connectionRadius: connectionRadius ?? this.connectionRadius,
      connectOnClick: connectOnClick ?? this.connectOnClick,
      connectionLineType: clearConnectionLineType
          ? null
          : (connectionLineType ?? this.connectionLineType),
      connectionLineStyle: clearConnectionLineStyle
          ? null
          : (connectionLineStyle ?? this.connectionLineStyle),
      connectionLineBuilder: clearConnectionLineBuilder
          ? null
          : (connectionLineBuilder ?? this.connectionLineBuilder),
      autoCreateEdge: autoCreateEdge ?? this.autoCreateEdge,
      edgesReconnectable: edgesReconnectable ?? this.edgesReconnectable,
      reconnectRadius: reconnectRadius ?? this.reconnectRadius,
      connectionDragThreshold:
          connectionDragThreshold ?? this.connectionDragThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectionOptions &&
        other.connectionMode == connectionMode &&
        other.connectionRadius == connectionRadius &&
        other.connectOnClick == connectOnClick &&
        other.connectionLineType == connectionLineType &&
        other.connectionLineStyle == connectionLineStyle &&
        identical(other.connectionLineBuilder, connectionLineBuilder) &&
        other.autoCreateEdge == autoCreateEdge &&
        other.edgesReconnectable == edgesReconnectable &&
        other.reconnectRadius == reconnectRadius &&
        other.connectionDragThreshold == connectionDragThreshold;
  }

  @override
  int get hashCode => Object.hash(
        connectionMode,
        connectionRadius,
        connectOnClick,
        connectionLineType,
        connectionLineStyle,
        identityHashCode(connectionLineBuilder),
        autoCreateEdge,
        edgesReconnectable,
        reconnectRadius,
        connectionDragThreshold,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('connectionMode', connectionMode));
    properties.add(DoubleProperty('connectionRadius', connectionRadius));
    properties.add(DoubleProperty(
        'connectionDragThreshold', connectionDragThreshold,
        defaultValue: 1.0));    properties.add(FlagProperty('connectOnClick',
        value: connectOnClick, ifTrue: 'click-connect'));
    properties.add(EnumProperty('connectionLineType', connectionLineType));
    properties.add(DiagnosticsProperty<FlowConnectionStyle>(
        'connectionLineStyle', connectionLineStyle));
    properties.add(FlagProperty('connectionLineBuilder',
        value: connectionLineBuilder != null, ifTrue: 'custom-line'));
    properties.add(FlagProperty('autoCreateEdge',
        value: autoCreateEdge, defaultValue: true, ifFalse: 'controlled'));
    properties.add(FlagProperty('edgesReconnectable',
        value: edgesReconnectable, ifFalse: 'no-reconnect'));
  }
}
