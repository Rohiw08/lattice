import 'package:flutter/foundation.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/connection_options.dart';
import 'package:lattice/src/core/options/components/edge_options.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/core/options/components/viewport_options.dart';

/// Global configuration options for the flow canvas.
@immutable
class FlowCanvasOptions with Diagnosticable {
  final NodeOptions nodeOptions;
  final EdgeOptions edgeOptions;
  final ViewportOptions viewportOptions;
  final KeyboardOptions keyboardOptions;
  final ConnectionOptions connectionOptions;

  const FlowCanvasOptions({
    this.nodeOptions = const NodeOptions(),
    this.edgeOptions = const EdgeOptions(),
    this.viewportOptions = const ViewportOptions(),
    this.keyboardOptions = const KeyboardOptions(),
    this.connectionOptions = const ConnectionOptions(),
  });

  const FlowCanvasOptions.readOnly()
      : nodeOptions = const NodeOptions.readOnly(),
        edgeOptions = const EdgeOptions.readOnly(),
        viewportOptions = const ViewportOptions.readOnly(),
        keyboardOptions = const KeyboardOptions.disabled(),
        connectionOptions = const ConnectionOptions.readOnly();

  FlowCanvasOptions.interactive()
      : nodeOptions = const NodeOptions.interactive(),
        edgeOptions = const EdgeOptions.interactive(),
        viewportOptions = const ViewportOptions(),
        keyboardOptions = KeyboardOptions.withDefaults(),
        connectionOptions = const ConnectionOptions();

  FlowCanvasOptions.presentation()
      : nodeOptions = const NodeOptions.readOnly(),
        edgeOptions = const EdgeOptions.readOnly(),
        viewportOptions = const ViewportOptions(
          panOnDrag: {PanMouseButton.left},
          zoomOnScroll: true,
          selectionOnDrag: false,
        ),
        keyboardOptions = KeyboardOptions.navigationOnly(),
        connectionOptions = const ConnectionOptions.readOnly();

  FlowCanvasOptions copyWith({
    NodeOptions? nodeOptions,
    EdgeOptions? edgeOptions,
    ViewportOptions? viewportOptions,
    KeyboardOptions? keyboardOptions,
    ConnectionOptions? connectionOptions,
  }) {
    return FlowCanvasOptions(
      nodeOptions: nodeOptions ?? this.nodeOptions,
      edgeOptions: edgeOptions ?? this.edgeOptions,
      viewportOptions: viewportOptions ?? this.viewportOptions,
      keyboardOptions: keyboardOptions ?? this.keyboardOptions,
      connectionOptions: connectionOptions ?? this.connectionOptions,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FlowCanvasOptions &&
        other.nodeOptions == nodeOptions &&
        other.edgeOptions == edgeOptions &&
        other.viewportOptions == viewportOptions &&
        other.keyboardOptions == keyboardOptions &&
        other.connectionOptions == connectionOptions;
  }

  @override
  int get hashCode => Object.hash(
        nodeOptions,
        edgeOptions,
        viewportOptions,
        keyboardOptions,
        connectionOptions,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
        .add(DiagnosticsProperty<NodeOptions>('nodeOptions', nodeOptions));
    properties
        .add(DiagnosticsProperty<EdgeOptions>('edgeOptions', edgeOptions));
    properties.add(DiagnosticsProperty<ViewportOptions>(
        'viewportOptions', viewportOptions));
    properties.add(DiagnosticsProperty<KeyboardOptions>(
        'keyboardOptions', keyboardOptions));
    properties.add(DiagnosticsProperty<ConnectionOptions>(
        'connectionOptions', connectionOptions));
  }
}
