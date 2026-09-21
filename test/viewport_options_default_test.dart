import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

/// Guards the breaking default (pre-1.0): viewport culling is ON by default.
///
/// Flipped in the Sept-2026 perf pass once culling engaged on the first frame
/// (no all-nodes mount spike), stopped mass-mounting on drag-start, and kept
/// keyboard/screen-reader access to off-screen nodes via an always-mounted
/// proxy layer. A silent revert to `false` would regress the out-of-the-box
/// large-graph story, so pin it here.
void main() {
  test('onlyRenderVisibleElements defaults to true', () {
    expect(const ViewportOptions().onlyRenderVisibleElements, isTrue);
    expect(
      const ViewportOptions.readOnly().onlyRenderVisibleElements,
      isTrue,
    );
  });

  test('the default can still be turned off explicitly', () {
    expect(
      const ViewportOptions(onlyRenderVisibleElements: false)
          .onlyRenderVisibleElements,
      isFalse,
    );
  });

  // Equality must account for every field, or FlowCanvas.didUpdateWidget's
  // `widget.options != oldWidget.options` gate silently drops a runtime change
  // (the Riverpod override is never refreshed). minNodeSize is read live at
  // resize time (NodesController), so an omitted field is a real bug.
  group('equality covers node-size fields', () {
    test('options differing only in minNodeSize are not equal', () {
      const a = ViewportOptions(minNodeSize: Size(50, 50));
      const b = ViewportOptions(minNodeSize: Size(150, 150));
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('options differing only in maxNodeSize are not equal', () {
      const a = ViewportOptions(maxNodeSize: Size(400, 400));
      const b = ViewportOptions(maxNodeSize: Size(800, 800));
      expect(a == b, isFalse);
      expect(a.hashCode == b.hashCode, isFalse);
    });

    test('identical node-size fields still compare equal', () {
      const a = ViewportOptions(
        minNodeSize: Size(50, 50),
        maxNodeSize: Size(400, 400),
      );
      const b = ViewportOptions(
        minNodeSize: Size(50, 50),
        maxNodeSize: Size(400, 400),
      );
      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });
  });
}
