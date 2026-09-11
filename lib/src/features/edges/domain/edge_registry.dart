import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/components/edge_marker_theme.dart';
import '../../../core/theme/components/edge_theme.dart';

/// A registry for managing edge type configurations.
///
/// Similar in design to [NodeRegistry], this allows users to register
/// different edge types with their own visual and behavioral defaults.
///
/// If a requested edge type has not been registered, it falls back to
/// a default [EdgeTypeConfig.bezier].
///
/// ## Usage
/// ```
/// final registry = EdgeRegistry()
///   ..register('smooth', EdgeTypeConfig.smoothStep())
///   ..register('dashed', EdgeTypeConfig.dashed());
///
/// final edge = registry.createEdge(
///   id: 'e1',
///   sourceNodeId: 'n1',
///   targetNodeId: 'n2',
///   sourceHandleId: 'out',
///   targetHandleId: 'in',
///   type: 'dashed',
/// );
/// ```
class EdgeRegistry {
  final Map<String, EdgeTypeConfig> _types;

  /// Creates a registry with the default edge type registered.
  EdgeRegistry() : _types = {} {
    _registerDefaultTypes();
  }

  /// Creates an empty registry with no default types.
  EdgeRegistry.empty() : _types = {};

  /// Registers a new edge type with its configuration.
  void register(String type, EdgeTypeConfig config) {
    assert(type.trim().isNotEmpty, 'Edge type cannot be empty');
    _types[type] = config;
  }

  /// Unregisters an edge type. Returns true if it was found and removed.
  bool unregister(String type) =>
      type.isNotEmpty && _types.remove(type) != null;

  /// Clears all registered edge types.
  void clear() => _types.clear();

  /// Returns true if the edge type exists.
  bool isRegistered(String type) => _types.containsKey(type);

  /// Returns a read-only view of all edge types.
  Map<String, EdgeTypeConfig> get types => Map.unmodifiable(_types);

  /// Returns the configuration for a given type, or [EdgeTypeConfig.bezier].
  EdgeTypeConfig getConfig(String? type) {
    if (type == null || type.isEmpty) {
      return EdgeTypeConfig.bezier();
    }
    return _types[type] ?? EdgeTypeConfig.bezier();
  }

  /// Creates a [FlowEdge] using the configuration for the given type.
  FlowEdge createEdge({
    required String id,
    required String sourceNodeId,
    required String targetNodeId,
    String? sourceHandleId,
    String? targetHandleId,
    String? type,
    Map<String, dynamic>? data,
  }) {
    final config = getConfig(type);
    return FlowEdge(
      id: id,
      sourceNodeId: sourceNodeId,
      targetNodeId: targetNodeId,
      sourceHandleId: sourceHandleId,
      targetHandleId: targetHandleId,
      type: config.pathType,
      style: config.style,
      startMarkerStyle: config.startMarker,
      endMarkerStyle: config.endMarker,
      data: {...config.data, ...?data},
      deletable: config.deletable,
      selectable: config.selectable,
      focusable: config.focusable,
      reconnectable: config.reconnectable,
      animated: config.animated ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // Default Types
  // ---------------------------------------------------------------------------

  void _registerDefaultTypes() {
    register('default', EdgeTypeConfig.bezier());
  }
}

/// Configuration for a custom edge type.
///
/// Defines how edges of a particular type are drawn and behave.
/// Provides convenience factories for common configurations.
@immutable
class EdgeTypeConfig {
  final EdgePathType pathType;
  final FlowEdgeStyle? style;
  final FlowEdgeMarkerStyle? startMarker;
  final FlowEdgeMarkerStyle? endMarker;
  final Map<String, dynamic> data;
  final bool? animated;
  final bool? deletable;
  final bool? selectable;
  final bool? focusable;
  final bool? reconnectable;

  const EdgeTypeConfig({
    this.pathType = EdgePathType.bezier,
    this.style,
    this.startMarker,
    this.endMarker,
    this.data = const {},
    this.animated,
    this.deletable,
    this.selectable,
    this.focusable,
    this.reconnectable,
  });

  /// Predefined bezier edge configuration.
  factory EdgeTypeConfig.bezier() => const EdgeTypeConfig(
        pathType: EdgePathType.bezier,
      );

  /// Predefined straight line configuration.
  factory EdgeTypeConfig.straight() => const EdgeTypeConfig(
        pathType: EdgePathType.straight,
      );

  /// Predefined smooth step edge configuration.
  factory EdgeTypeConfig.smoothStep() => const EdgeTypeConfig(
        pathType: EdgePathType.smoothStep,
      );

  /// Copies this configuration with optional overrides.
  EdgeTypeConfig copyWith({
    EdgePathType? pathType,
    FlowEdgeStyle? style,
    FlowEdgeMarkerStyle? startMarker,
    FlowEdgeMarkerStyle? endMarker,
    Map<String, dynamic>? data,
    bool? animated,
    bool? deletable,
    bool? selectable,
    bool? focusable,
    bool? reconnectable,
  }) {
    return EdgeTypeConfig(
      pathType: pathType ?? this.pathType,
      style: style ?? this.style,
      startMarker: startMarker ?? this.startMarker,
      endMarker: endMarker ?? this.endMarker,
      data: data ?? this.data,
      animated: animated ?? this.animated,
      deletable: deletable ?? this.deletable,
      selectable: selectable ?? this.selectable,
      focusable: focusable ?? this.focusable,
      reconnectable: reconnectable ?? this.reconnectable,
    );
  }
}
