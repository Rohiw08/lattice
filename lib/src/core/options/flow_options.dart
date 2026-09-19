import 'package:flutter/foundation.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/options/components/connection_options.dart';
import 'package:lattice/src/core/options/components/edge_options.dart';
import 'package:lattice/src/core/options/components/keyboard_options.dart';
import 'package:lattice/src/core/options/components/node_options.dart';
import 'package:lattice/src/core/options/components/viewport_options.dart';
import 'package:lattice/src/features/a11y/domain/a11y_options.dart';

/// Global configuration options for the flow canvas.
@immutable
class FlowCanvasOptions with Diagnosticable {
  final NodeOptions nodeOptions;
  final EdgeOptions edgeOptions;
  final ViewportOptions viewportOptions;
  final KeyboardOptions keyboardOptions;
  final ConnectionOptions connectionOptions;
  final A11yOptions a11yOptions;

  /// Master selection switch (Lattice `elementsSelectable`).
  ///
  /// When false, user selection is disabled entirely: taps, marquee, and
  /// select-all select nothing (deselect still works). Defaults to true.
  final bool elementsSelectable;

  /// Automatic z-order management (Lattice `zIndexMode`).
  ///
  /// Defaults to [ZIndexMode.auto] (current behavior).
  final ZIndexMode zIndexMode;

  FlowCanvasOptions({
    this.nodeOptions = const NodeOptions(),
    this.edgeOptions = const EdgeOptions(),
    this.viewportOptions = const ViewportOptions(),
    KeyboardOptions? keyboardOptions,
    this.connectionOptions = const ConnectionOptions(),
    this.a11yOptions = const A11yOptions(),
    this.elementsSelectable = true,
    this.zIndexMode = ZIndexMode.auto,
  }) : keyboardOptions = keyboardOptions ?? KeyboardOptions();

  const FlowCanvasOptions.readOnly()
      : nodeOptions = const NodeOptions.readOnly(),
        edgeOptions = const EdgeOptions.readOnly(),
        viewportOptions = const ViewportOptions.readOnly(),
        keyboardOptions = const KeyboardOptions.disabled(),
        connectionOptions = const ConnectionOptions.readOnly(),
        a11yOptions = const A11yOptions(),
        elementsSelectable = true,
        zIndexMode = ZIndexMode.auto;

  FlowCanvasOptions.interactive()
      : nodeOptions = const NodeOptions.interactive(),
        edgeOptions = const EdgeOptions.interactive(),
        viewportOptions = const ViewportOptions(),
        keyboardOptions = KeyboardOptions.withDefaults(),
        connectionOptions = const ConnectionOptions(),
        a11yOptions = const A11yOptions(),
        elementsSelectable = true,
        zIndexMode = ZIndexMode.auto;

  FlowCanvasOptions.presentation()
      : nodeOptions = const NodeOptions.readOnly(),
        edgeOptions = const EdgeOptions.readOnly(),
        viewportOptions = const ViewportOptions(
          panOnDrag: {PanMouseButton.left},
          zoomOnScroll: true,
          selectionOnDrag: false,
        ),
        keyboardOptions = KeyboardOptions.navigationOnly(),
        connectionOptions = const ConnectionOptions.readOnly(),
        a11yOptions = const A11yOptions(),
        elementsSelectable = true,
        zIndexMode = ZIndexMode.auto;

  FlowCanvasOptions copyWith({
    NodeOptions? nodeOptions,
    EdgeOptions? edgeOptions,
    ViewportOptions? viewportOptions,
    KeyboardOptions? keyboardOptions,
    ConnectionOptions? connectionOptions,
    A11yOptions? a11yOptions,
    bool? elementsSelectable,
    ZIndexMode? zIndexMode,
  }) {
    return FlowCanvasOptions(
      nodeOptions: nodeOptions ?? this.nodeOptions,
      edgeOptions: edgeOptions ?? this.edgeOptions,
      viewportOptions: viewportOptions ?? this.viewportOptions,
      keyboardOptions: keyboardOptions ?? this.keyboardOptions,
      connectionOptions: connectionOptions ?? this.connectionOptions,
      a11yOptions: a11yOptions ?? this.a11yOptions,
      elementsSelectable: elementsSelectable ?? this.elementsSelectable,
      zIndexMode: zIndexMode ?? this.zIndexMode,
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
        other.connectionOptions == connectionOptions &&
        other.a11yOptions == a11yOptions &&
        other.elementsSelectable == elementsSelectable &&
        other.zIndexMode == zIndexMode;
  }

  @override
  int get hashCode => Object.hash(
        nodeOptions,
        edgeOptions,
        viewportOptions,
        keyboardOptions,
        connectionOptions,
        a11yOptions,
        elementsSelectable,
        zIndexMode,
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
    properties.add(DiagnosticsProperty<A11yOptions>(
        'a11yOptions', a11yOptions));
    properties.add(FlagProperty('elementsSelectable',
        value: elementsSelectable,
        defaultValue: true,
        ifFalse: 'selection disabled'));
    properties.add(EnumProperty<ZIndexMode>('zIndexMode', zIndexMode,
        defaultValue: ZIndexMode.auto));
  }
}
