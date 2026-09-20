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
}
