import 'package:lattice/src/core/theme/flow_theme.dart';
import 'package:lattice/src/core/theme/theme_provider.dart';
import 'package:flutter/widgets.dart';

extension FlowCanvasThemeContextExtension on BuildContext {
  FlowCanvasTheme get flowCanvasTheme {
    return FlowCanvasThemeProvider.of(this);
  }

  FlowCanvasTheme? get flowCanvasThemeMaybe {
    return FlowCanvasThemeProvider.maybeOf(this);
  }
}
