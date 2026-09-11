import 'package:lattice/src/core/options/flow_options.dart';
import 'package:lattice/src/core/options/options_provider.dart';
import 'package:flutter/widgets.dart';

/// Extension on [BuildContext] to easily access [FlowCanvasOptions].
///
/// Provides convenient access to canvas options from anywhere in the widget tree
/// without needing to manually call `FlowCanvasOptionsProvider.of(context)`.
///
/// ## Usage
///
/// ```
/// @override
/// Widget build(BuildContext context) {
///   final options = context.flowCanvasOptions;
///
///   if (node.isDraggable(context)) {
///     // Access node options
///     final draggable = options.nodeOptions.draggable;
///   }
/// }
/// ```
///
/// ## Accessing Sub-Options
///
/// ```
/// // Node options
/// final nodeOptions = context.flowCanvasOptions.nodeOptions;
///
/// // Edge options
/// final edgeOptions = context.flowCanvasOptions.edgeOptions;
///
/// // Viewport options
/// final viewportOptions = context.flowCanvasOptions.viewportOptions;
///
/// // Keyboard options
/// final keyboardOptions = context.flowCanvasOptions.keyboardOptions;
/// ```
///
/// ## Error Handling
///
/// If no [FlowCanvasOptionsProvider] is found in the widget tree, this will
/// throw a [FlutterError] explaining the issue. Always ensure your canvas
/// is wrapped with [FlowCanvasOptionsProvider].
///
/// See also:
///
///  * [FlowCanvasOptionsProvider], which provides the options
///  * [FlowCanvasOptions], for the options configuration
extension FlowCanvasOptionsExtension on BuildContext {
  /// Returns the [FlowCanvasOptions] from the nearest [FlowCanvasOptionsProvider].
  ///
  /// Throws [FlutterError] if no provider is found in the widget tree.
  FlowCanvasOptions get flowCanvasOptions {
    return FlowCanvasOptionsProvider.of(this);
  }

  /// Returns the [FlowCanvasOptions] from the nearest provider, or null if not found.
  ///
  /// Use this when options might not be available and you want to handle
  /// the null case gracefully instead of throwing.
  ///
  /// Example:
  /// ```
  /// final options = context.flowCanvasOptionsMaybe;
  /// if (options != null) {
  ///   // Use options
  /// } else {
  ///   // Fallback behavior
  /// }
  /// ```
  FlowCanvasOptions? get flowCanvasOptionsMaybe {
    return FlowCanvasOptionsProvider.maybeOf(this);
  }
}
