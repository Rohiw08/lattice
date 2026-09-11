import 'package:lattice/src/core/options/flow_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Provides [FlowCanvasOptions] to descendant widgets.
///
/// This widget makes canvas options available throughout the widget tree
/// using Flutter's InheritedWidget mechanism. All canvas widgets
/// (nodes, edges, controls) access their configuration through this provider.
///
/// ## Usage
///
/// Wrap your canvas with the provider:
/// ```
/// FlowCanvasOptionsProvider(
///   options: FlowCanvasOptions(
///     nodeOptions: NodeOptions.interactive(),
///     edgeOptions: EdgeOptions.readOnly(),
///   ),
///   child: FlowCanvas(
///     nodes: nodes,
///     edges: edges,
///   ),
/// )
/// ```
///
/// Access options in descendants:
/// ```
/// final options = context.flowCanvasOptions;
/// // or
/// final options = FlowCanvasOptionsProvider.of(context);
/// ```
///
/// ## Updating Options
///
/// Create a new provider with updated options to trigger rebuilds:
/// ```
/// setState(() {
///   currentOptions = currentOptions.copyWith(
///     nodeOptions: NodeOptions.readOnly(),
///   );
/// });
/// ```
///
/// See also:
///
///  * [FlowCanvasOptions], for available configuration options
///  * [FlowCanvasOptionsExtension], for convenient context access
class FlowCanvasOptionsProvider extends InheritedWidget {
  /// The canvas options to provide to descendants.
  final FlowCanvasOptions options;

  /// Creates a canvas options provider.
  ///
  /// The [options] parameter is required and defines the configuration
  /// for all descendant canvas widgets.
  const FlowCanvasOptionsProvider({
    super.key,
    required this.options,
    required super.child,
  });

  /// Returns the [FlowCanvasOptions] from the nearest provider in the widget tree.
  ///
  /// If no provider is found, throws a [FlutterError] with helpful debugging
  /// information. Use [maybeOf] if the options might not be available and you
  /// want to handle the null case gracefully.
  ///
  /// Example:
  /// ```
  /// final options = FlowCanvasOptionsProvider.of(context);
  /// if (options.nodeOptions.draggable) {
  ///   // Node is draggable
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [maybeOf], for a nullable version that doesn't throw
  static FlowCanvasOptions of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FlowCanvasOptionsProvider>();

    if (provider == null) {
      throw FlutterError.fromParts([
        ErrorSummary('FlowCanvasOptionsProvider not found in context.'),
        ErrorDescription(
          'No FlowCanvasOptionsProvider ancestor could be found starting from '
          'the context that was passed to FlowCanvasOptionsProvider.of().',
        ),
        ErrorHint(
          'This usually happens when the context provided is from a widget above '
          'the FlowCanvasOptionsProvider. Ensure that your FlowCanvas and related '
          'widgets are descendants of a FlowCanvasOptionsProvider widget.',
        ),
        ErrorHint(
          'To fix this, wrap your canvas with FlowCanvasOptionsProvider:\n\n'
          'FlowCanvasOptionsProvider(\n'
          '  options: FlowCanvasOptions(),\n'
          '  child: FlowCanvas(...),\n'
          ')',
        ),
        context.describeElement('The context used was'),
      ]);
    }

    return provider.options;
  }

  /// Returns the [FlowCanvasOptions] from the nearest provider, or null if not found.
  ///
  /// This is the nullable version of [of]. Use this when you want to provide
  /// a fallback behavior instead of throwing an error when no provider exists.
  ///
  /// Example:
  /// ```
  /// final options = FlowCanvasOptionsProvider.maybeOf(context);
  /// if (options != null) {
  ///   // Use provided options
  ///   return options.nodeOptions.draggable;
  /// } else {
  ///   // Fallback to default
  ///   return true;
  /// }
  /// ```
  ///
  /// See also:
  ///
  ///  * [of], for a version that throws if no provider is found
  static FlowCanvasOptions? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<FlowCanvasOptionsProvider>()
        ?.options;
  }

  @override
  bool updateShouldNotify(FlowCanvasOptionsProvider oldWidget) {
    // Only notify dependents if the options actually changed
    return options != oldWidget.options;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FlowCanvasOptions>('options', options));
  }
}
