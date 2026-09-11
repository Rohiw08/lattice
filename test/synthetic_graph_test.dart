import 'package:lattice/lattice.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('synthetic grid scale', () {
    final s = buildSyntheticGrid(cols: 10, rows: 10);
    expect(s.nodes.length, 100);
  });

  test('synthetic grid with chain edges', () {
    final s = buildSyntheticGrid(cols: 5, rows: 2, withChainEdges: true);
    expect(s.nodes.length, 10);
    expect(s.edges.length, 9);
  });
}
