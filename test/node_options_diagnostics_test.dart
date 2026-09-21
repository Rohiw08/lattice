import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Guards [NodeOptions.debugFillProperties] against copy-paste mislabels: each
/// flag must report its OWN field, not a sibling's. A prior bug labelled a
/// property 'hoverable' but read the `selectable` field, so the widget
/// inspector showed the wrong hover state.
///
/// Diagnostic-only (inspector / DevTools / toString) — no runtime behavior
/// depends on it — but a mislabelled inspector flag is actively misleading
/// when debugging interaction gating.
List<DiagnosticsNode> _propsOf(NodeOptions options) {
  final builder = DiagnosticPropertiesBuilder();
  options.debugFillProperties(builder);
  return builder.properties;
}

bool? _flag(List<DiagnosticsNode> props, String name) {
  final node = props.firstWhere(
    (p) => p.name == name,
    orElse: () => throw StateError('no diagnostic property named "$name"'),
  );
  return (node as DiagnosticsProperty).value as bool?;
}

void main() {
  test('each flag reports its own field (hoverable != selectable)', () {
    // The discriminating case: hoverable and selectable set to OPPOSITE
    // values. The old bug made 'hoverable' mirror `selectable`.
    const options = NodeOptions(hoverable: false, selectable: true);
    final props = _propsOf(options);

    expect(_flag(props, 'hoverable'), isFalse,
        reason: "'hoverable' must read the hoverable field, not selectable");
    expect(_flag(props, 'selectable'), isTrue);
  });

  test('every boolean flag maps to its matching field', () {
    // All flags flipped away from their defaults so a cross-wired property
    // (name X reading field Y) would surface as a mismatch.
    const options = NodeOptions(
      hidden: true,
      draggable: false,
      selectable: false,
      hoverable: false,
      connectable: false,
      deletable: false,
      resizable: true,
      focusable: false,
      elevateNodesOnSelected: false,
      expandParent: true,
      selectNodesOnDrag: false,
    );
    final props = _propsOf(options);

    expect(_flag(props, 'hidden'), isTrue);
    expect(_flag(props, 'draggable'), isFalse);
    expect(_flag(props, 'selectable'), isFalse);
    expect(_flag(props, 'hoverable'), isFalse);
    expect(_flag(props, 'connectable'), isFalse);
    expect(_flag(props, 'deletable'), isFalse);
    expect(_flag(props, 'resizable'), isTrue);
    expect(_flag(props, 'focusable'), isFalse);
    expect(_flag(props, 'elevateNodesOnSelected'), isFalse);
    expect(_flag(props, 'expandParent'), isTrue);
    expect(_flag(props, 'selectNodesOnDrag'), isFalse);
  });
}
