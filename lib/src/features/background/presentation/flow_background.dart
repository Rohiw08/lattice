import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/core/theme/components/background_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Solid (and gradient) canvas backdrop. Pattern is painted in flow space
/// inside [InteractiveViewer] so it stays locked to nodes while panning.
class FlowBackground extends ConsumerWidget {
  final FlowBackgroundStyle? backgroundStyle;

  const FlowBackground({
    super.key,
    this.backgroundStyle,
  });

  /// Resolved style for the in-viewport pattern layer.
  FlowBackgroundStyle resolveStyle(BuildContext context) {
    final base =
        context.flowCanvasTheme.background ?? FlowBackgroundStyle.system(context);
    return base.merge(backgroundStyle);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = resolveStyle(context);

    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          gradient: style.gradient,
        ),
      ),
    );
  }
}
