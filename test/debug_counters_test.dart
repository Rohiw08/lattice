import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/lattice.dart';

void main() {
  group('FlowCanvasDebug counters', () {
    test('reset/snapshot/count round-trip', () {
      FlowCanvasDebug.resetCounters();
      expect(
        FlowCanvasDebug.snapshot(),
        (edgePaints: 0, nodesBuilt: 0, panCommits: 0, dragCommits: 0),
      );

      FlowCanvasDebug.countEdgePaint(3);
      FlowCanvasDebug.countNodesBuilt();
      FlowCanvasDebug.countPanCommit();
      FlowCanvasDebug.countDragCommit();
      expect(FlowCanvasDebug.edgePaintCount, 3);
      expect(FlowCanvasDebug.nodesBuilt, 1);
      expect(FlowCanvasDebug.panCommits, 1);
      expect(FlowCanvasDebug.dragCommits, 1);
      expect(
        FlowCanvasDebug.snapshot(),
        (edgePaints: 3, nodesBuilt: 1, panCommits: 1, dragCommits: 1),
      );

      FlowCanvasDebug.resetCounters();
      expect(
        FlowCanvasDebug.snapshot(),
        (edgePaints: 0, nodesBuilt: 0, panCommits: 0, dragCommits: 0),
      );
    });

    test('log methods are safe with flags off', () {
      // Must not throw; must not log.
      FlowCanvasDebug.interaction('x');
      FlowCanvasDebug.spatial('x');
      FlowCanvasDebug.edgePaint('x');
      FlowCanvasDebug.perf('x');
      expect(FlowCanvasDebug.traceSync('t', () => 42), 42);
    });
  });
}
