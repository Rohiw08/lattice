import 'package:lattice/src/core/enums/enums.dart';
import 'package:flutter/foundation.dart';

/// canvas-style connection / connection-line options.
///
/// Maps to Lattice props: `connectionMode`, `connectionRadius`, `connectOnClick`,
/// `connectionLineType`, plus whether the library auto-inserts the edge.
@immutable
class ConnectionOptions with Diagnosticable {
  /// Strict = source→target only; loose = any handle pair (Lattice `connectionMode`).
  final ConnectionMode connectionMode;

  /// Snap radius in **screen pixels** around a handle (Lattice `connectionRadius`).
  final double connectionRadius;

  /// Click a source handle, then a target, to connect (Lattice `connectOnClick`).
  final bool connectOnClick;

  /// Path type for the live connection line (Lattice `connectionLineType`).
  ///
  /// When null, uses [FlowConnectionStyle.pathType] from the theme.
  final EdgePathType? connectionLineType;

  /// When true (default), a completed drag/click inserts a [FlowEdge].
  /// When false, only [FlowCanvasCallbacks.onConnection] fires — Lattice controlled style.
  final bool autoCreateEdge;

  /// Allow dragging edge endpoints to reconnect (Lattice `edgesReconnectable`).
  final bool edgesReconnectable;

  /// Hit radius in screen px for edge reconnect endpoints.
  final double reconnectRadius;

  const ConnectionOptions({
    this.connectionMode = ConnectionMode.strict,
    this.connectionRadius = 20.0,
    this.connectOnClick = false,
    this.connectionLineType,
    this.autoCreateEdge = true,
    this.edgesReconnectable = true,
    this.reconnectRadius = 20.0,
  })  : assert(connectionRadius > 0),
        assert(reconnectRadius > 0);

  const ConnectionOptions.readOnly()
      : connectionMode = ConnectionMode.strict,
        connectionRadius = 20.0,
        connectOnClick = false,
        connectionLineType = null,
        autoCreateEdge = false,
        edgesReconnectable = false,
        reconnectRadius = 20.0;

  ConnectionOptions copyWith({
    ConnectionMode? connectionMode,
    double? connectionRadius,
    bool? connectOnClick,
    EdgePathType? connectionLineType,
    bool clearConnectionLineType = false,
    bool? autoCreateEdge,
    bool? edgesReconnectable,
    double? reconnectRadius,
  }) {
    return ConnectionOptions(
      connectionMode: connectionMode ?? this.connectionMode,
      connectionRadius: connectionRadius ?? this.connectionRadius,
      connectOnClick: connectOnClick ?? this.connectOnClick,
      connectionLineType: clearConnectionLineType
          ? null
          : (connectionLineType ?? this.connectionLineType),
      autoCreateEdge: autoCreateEdge ?? this.autoCreateEdge,
      edgesReconnectable: edgesReconnectable ?? this.edgesReconnectable,
      reconnectRadius: reconnectRadius ?? this.reconnectRadius,
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
        other.autoCreateEdge == autoCreateEdge &&
        other.edgesReconnectable == edgesReconnectable &&
        other.reconnectRadius == reconnectRadius;
  }

  @override
  int get hashCode => Object.hash(
        connectionMode,
        connectionRadius,
        connectOnClick,
        connectionLineType,
        autoCreateEdge,
        edgesReconnectable,
        reconnectRadius,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty('connectionMode', connectionMode));
    properties.add(DoubleProperty('connectionRadius', connectionRadius));
    properties.add(FlagProperty('connectOnClick',
        value: connectOnClick, ifTrue: 'click-connect'));
    properties.add(EnumProperty('connectionLineType', connectionLineType));
    properties.add(FlagProperty('autoCreateEdge',
        value: autoCreateEdge, defaultValue: true, ifFalse: 'controlled'));
    properties.add(FlagProperty('edgesReconnectable',
        value: edgesReconnectable, ifFalse: 'no-reconnect'));
  }
}
