import 'package:lattice/src/core/theme/theme_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Interaction states for [FlowPanel] chrome (same set as [FlowNodeState]).
enum FlowPanelState { normal, selected, hovered, disabled }

/// Optional overlay panel chrome — same decoration-state model as [FlowNodeStyle].
///
/// Lattice’s `<Panel />` is unstyled by default; use [FlowPanelStyle.unstyled]
/// (theme default) or opt into [light] / [dark] / [colored] card chrome.
@immutable
class FlowPanelStyle extends ThemeExtension<FlowPanelStyle>
    with Diagnosticable {
  /// Decoration for the panel in its normal state.
  final Decoration decoration;

  /// Decoration when selected.
  ///
  /// Falls back to [hoverDecoration] or [decoration] if null.
  final Decoration? selectedDecoration;

  /// Decoration when hovered.
  ///
  /// Falls back to [decoration] if null.
  final Decoration? hoverDecoration;

  /// Decoration when disabled.
  ///
  /// Falls back to a dimmed [decoration] if null.
  final Decoration? disabledDecoration;

  const FlowPanelStyle({
    required this.decoration,
    this.selectedDecoration,
    this.hoverDecoration,
    this.disabledDecoration,
  });

  /// State priority: disabled → selected → hovered → normal.
  Decoration resolveDecoration(Set<FlowPanelState> states) {
    if (states.contains(FlowPanelState.disabled)) {
      if (disabledDecoration != null) return disabledDecoration!;
      return FlowThemeDim.decoration(decoration) ?? decoration;
    }
    if (states.contains(FlowPanelState.selected)) {
      return selectedDecoration ?? hoverDecoration ?? decoration;
    }
    if (states.contains(FlowPanelState.hovered)) {
      return hoverDecoration ?? decoration;
    }
    return decoration;
  }

  /// Whether [decoration] has no visible fill, border, or shadow (Lattice default).
  bool get isUnstyled {
    if (decoration is! BoxDecoration) return false;
    final box = decoration as BoxDecoration;
    final color = box.color;
    final transparent = color == null || color.a == 0;
    final noBorder = box.border == null;
    final noShadow = box.boxShadow == null || box.boxShadow!.isEmpty;
    final noGradient = box.gradient == null;
    final noImage = box.image == null;
    return transparent && noBorder && noShadow && noGradient && noImage;
  }

  factory FlowPanelStyle.colored({
    required Color color,
    Color? selectedColor,
    Color? hoverColor,
    Color? disabledColor,
    Color? borderColor,
    Color? selectedBorderColor,
    Color? hoverBorderColor,
    Color? disabledBorderColor,
    double borderWidth = 1.0,
    double selectedBorderWidth = 1.0,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
    List<BoxShadow>? shadows,
  }) {
    BoxDecoration createDecoration({
      required Color bgColor,
      Color? bColor,
      double bWidth = 1.0,
    }) {
      return BoxDecoration(
        color: bgColor,
        border:
            bColor != null ? Border.all(color: bColor, width: bWidth) : null,
        borderRadius: borderRadius,
        boxShadow: shadows,
      );
    }

    return FlowPanelStyle(
      decoration: createDecoration(
        bgColor: color,
        bColor: borderColor,
        bWidth: borderWidth,
      ),
      selectedDecoration: selectedColor != null || selectedBorderColor != null
          ? createDecoration(
              bgColor: selectedColor ?? color,
              bColor: selectedBorderColor,
              bWidth: selectedBorderWidth,
            )
          : null,
      hoverDecoration: hoverColor != null || hoverBorderColor != null
          ? createDecoration(
              bgColor: hoverColor ?? color,
              bColor: hoverBorderColor,
              bWidth: borderWidth,
            )
          : null,
      disabledDecoration: disabledColor != null || disabledBorderColor != null
          ? createDecoration(
              bgColor: disabledColor ?? FlowThemeDim.color(color),
              bColor: disabledBorderColor ??
                  (borderColor != null
                      ? FlowThemeDim.color(borderColor)
                      : null),
              bWidth: borderWidth,
            )
          : null,
    );
  }

  /// No visible chrome (Lattice `<Panel />` default).
  factory FlowPanelStyle.unstyled() {
    return const FlowPanelStyle(decoration: BoxDecoration());
  }

  /// Optional light card chrome (controls-like).
  factory FlowPanelStyle.light() {
    return FlowPanelStyle.colored(
      color: const Color(0xFFFEFEFE),
      borderColor: const Color(0xFFEEEEEE),
      hoverColor: const Color(0xFFF4F4F4),
      selectedBorderColor: const Color(0xFF1A192B),
      disabledColor: const Color(0xFFF5F5F5),
      disabledBorderColor: const Color(0xFFE0E0E0),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  /// Optional dark card chrome.
  factory FlowPanelStyle.dark() {
    return FlowPanelStyle.colored(
      color: const Color(0xFF2A2A2A),
      borderColor: const Color(0xFF3C3C3C),
      hoverColor: const Color(0xFF333333),
      selectedBorderColor: const Color(0xFFBEBEBE),
      disabledColor: const Color(0xFF222222),
      disabledBorderColor: const Color(0xFF2A2A2A),
      shadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  factory FlowPanelStyle.system(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? FlowPanelStyle.dark()
        : FlowPanelStyle.light();
  }

  factory FlowPanelStyle.fromColorScheme(ColorScheme colorScheme) {
    return FlowPanelStyle.colored(
      color: colorScheme.surfaceContainerHigh,
      borderColor: colorScheme.outlineVariant,
      selectedBorderColor: colorScheme.primary,
      hoverColor: colorScheme.surfaceContainerHighest,
      disabledColor: colorScheme.surfaceContainerLow,
      disabledBorderColor: colorScheme.outlineVariant.withValues(alpha: 0.5),
      shadows: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  factory FlowPanelStyle.fromSeed(
    Color seedColor, {
    Brightness brightness = Brightness.light,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return FlowPanelStyle.fromColorScheme(colorScheme);
  }

  factory FlowPanelStyle.fromTheme(ThemeData theme) {
    if (theme.useMaterial3) {
      return FlowPanelStyle.fromColorScheme(theme.colorScheme);
    }
    return theme.brightness == Brightness.dark
        ? FlowPanelStyle.dark()
        : FlowPanelStyle.light();
  }

  FlowPanelStyle merge(FlowPanelStyle? other) {
    if (other == null) return this;
    return FlowPanelStyle(
      decoration: other.decoration,
      selectedDecoration: other.selectedDecoration ?? selectedDecoration,
      hoverDecoration: other.hoverDecoration ?? hoverDecoration,
      disabledDecoration: other.disabledDecoration ?? disabledDecoration,
    );
  }

  @override
  FlowPanelStyle copyWith({
    Decoration? decoration,
    Decoration? selectedDecoration,
    Decoration? hoverDecoration,
    Decoration? disabledDecoration,
  }) {
    return FlowPanelStyle(
      decoration: decoration ?? this.decoration,
      selectedDecoration: selectedDecoration ?? this.selectedDecoration,
      hoverDecoration: hoverDecoration ?? this.hoverDecoration,
      disabledDecoration: disabledDecoration ?? this.disabledDecoration,
    );
  }

  @override
  FlowPanelStyle lerp(
    covariant ThemeExtension<FlowPanelStyle>? other,
    double t,
  ) {
    if (other is! FlowPanelStyle) return this;
    if (identical(this, other)) return this;
    if (t == 0.0) return this;
    if (t == 1.0) return other;

    return FlowPanelStyle(
      decoration:
          Decoration.lerp(decoration, other.decoration, t) ?? decoration,
      selectedDecoration:
          Decoration.lerp(selectedDecoration, other.selectedDecoration, t) ??
              selectedDecoration,
      hoverDecoration:
          Decoration.lerp(hoverDecoration, other.hoverDecoration, t) ??
              hoverDecoration,
      disabledDecoration:
          Decoration.lerp(disabledDecoration, other.disabledDecoration, t) ??
              disabledDecoration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FlowPanelStyle &&
        other.decoration == decoration &&
        other.selectedDecoration == selectedDecoration &&
        other.hoverDecoration == hoverDecoration &&
        other.disabledDecoration == disabledDecoration;
  }

  @override
  int get hashCode => Object.hash(
        decoration,
        selectedDecoration,
        hoverDecoration,
        disabledDecoration,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Decoration>('decoration', decoration));
    properties.add(DiagnosticsProperty<Decoration?>(
      'selectedDecoration',
      selectedDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'hoverDecoration',
      hoverDecoration,
      defaultValue: null,
    ));
    properties.add(DiagnosticsProperty<Decoration?>(
      'disabledDecoration',
      disabledDecoration,
      defaultValue: null,
    ));
  }

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'FlowPanelStyle('
        'decoration: $decoration, '
        'selectedDecoration: $selectedDecoration, '
        'hoverDecoration: $hoverDecoration, '
        'disabledDecoration: $disabledDecoration'
        ')';
  }
}

extension FlowPanelStyleExtension on ThemeData {
  FlowPanelStyle get flowPanelStyle =>
      extension<FlowPanelStyle>() ?? FlowPanelStyle.unstyled();
}
