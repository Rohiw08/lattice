import 'package:flutter_test/flutter_test.dart';

import 'bench_helpers.dart';

void main() {
  test('dense edges triple minus ends', () {
    // 100 nodes: 99 chain + 98 (i-2) + 97 (i-3) = 294.
    expect(benchDenseEdges(100).length, 294);
    expect(benchDenseEdges(450).length, 449 + 448 + 447);
  });

  test('grid rows derive from count', () {
    expect(sweepGridPos(99), const Offset(900, 150));
    expect(sweepGridPos(0), const Offset(0, 0));
  });
}
