import 'package:lattice/src/core/theme/components/node_theme.dart';
import 'package:lattice/src/core/theme/theme_extension.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/nodes/presentation/flow_node.dart';
import 'package:flutter/material.dart';

/// Lattice–compatible built-in node type ids.
///
/// Matches `built-in node types` `builtinNodeTypes` keys:
/// `input`, `default`, `output`, `group`.
abstract final class BuiltInNodeType {
  static const input = 'input';
  static const defaultType = 'default';
  static const output = 'output';
  static const group = 'group';

  static const all = <String>[
    input,
    defaultType,
    output,
    group,
  ];
}

/// Lattice `input` node — source handle only.
///
/// Like Lattice v12, built-in nodes never render [FlowNode.data]: the label is
/// the responsibility of your own node widget (see [NodeRegistry.registerTyped]).
class InputNode extends StatelessWidget {
  const InputNode({super.key, required this.node});

  final FlowNode node;

  @override
  Widget build(BuildContext context) {
    return BaseNode(node: node);
  }
}

/// Lattice `default` node — target + source handles.
class DefaultNode extends StatelessWidget {
  const DefaultNode({super.key, required this.node});

  final FlowNode node;

  @override
  Widget build(BuildContext context) {
    return BaseNode(node: node);
  }
}

/// Lattice `output` node — target handle only.
class OutputNode extends StatelessWidget {
  const OutputNode({super.key, required this.node});

  final FlowNode node;

  @override
  Widget build(BuildContext context) {
    return BaseNode(node: node);
  }
}

Color? _decorationBorderColor(Decoration? decoration) {
  if (decoration is! BoxDecoration) return null;
  final border = decoration.border;
  if (border is Border) return border.top.color;
  return null;
}

BorderRadius _decorationRadius(Decoration? decoration) {
  if (decoration is BoxDecoration &&
      decoration.borderRadius is BorderRadius) {
    return decoration.borderRadius as BorderRadius;
  }
  return const BorderRadius.all(Radius.circular(3));
}

List<BoxShadow>? _boxShadow(Decoration? decoration) {
  if (decoration is BoxDecoration) return decoration.boxShadow;
  return null;
}

/// Translucent group chrome in xy-theme purples.
///
/// Light: `rgba(207,182,255,0.4)` fill + `#9e86ed` border; dark:
/// `rgba(123,107,148,0.22)` fill + `#7b6b94` border. Hover/selected reuse
/// the node state's shadows; selected border follows the blue selection
/// language.
FlowNodeStyle _groupStyleFrom(FlowNodeStyle base, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final fill = dark ? const Color(0x387B6B94) : const Color(0x66CFB6FF);
  final border =
      dark ? const Color(0xFF7B6B94) : const Color(0xFF9E86ED);
  final selectedBorder =
      _decorationBorderColor(base.selectedDecoration) ?? border;
  final hoverShadow = _boxShadow(base.hoverDecoration) ?? const [];
  final selectedShadow = _boxShadow(base.selectedDecoration) ?? const [];
  final radius = _decorationRadius(base.decoration);

  BoxDecoration decoration({
    required Color bColor,
    List<BoxShadow> shadows = const [],
  }) {
    return BoxDecoration(
      color: fill,
      border: Border.all(color: bColor, width: 1),
      borderRadius: radius,
      boxShadow: shadows,
    );
  }

  return FlowNodeStyle(
    decoration: decoration(bColor: border),
    hoverDecoration: decoration(bColor: border, shadows: hoverShadow),
    selectedDecoration:
        decoration(bColor: selectedBorder, shadows: selectedShadow),
  );
}

/// Lattice `group` node — empty translucent container.
///
/// Matches Lattice v12: `GroupNode` renders nothing; a label requires a custom
/// node component. Styling comes from [_groupStyleFrom].
class GroupNode extends StatelessWidget {
  const GroupNode({super.key, required this.node});

  final FlowNode node;

  @override
  Widget build(BuildContext context) {
    final base = (context.flowCanvasTheme.node ?? FlowNodeStyle.system(context))
        .merge(node.style);
    final style =
        _groupStyleFrom(base, Theme.of(context).brightness);

    return BaseNode(
      node: node,
      style: style,
    );
  }
}