import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/edges/application/edge_geometry_service.dart';
import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

/// React Flow parity: an edge whose endpoints omit handle ids must still
/// connect to the node's default source/target ports, not the node center.
/// The center fallback (with hard-coded right/left directions) detached the
/// arrowhead from the node border and drew a stray arc from the geometric
/// middle — the screenshot bug #6b/#6c.
void main() {
  FlowCanvasState buildState({String? sourceHandle, String? targetHandle}) {
    return FlowCanvasState.initial().copyWith(
      nodes: {
        'a': FlowNode<String>(
          id: 'a',
          type: 'default', // built-in: source=bottom, target=top
          position: const Offset(0, 0),
          size: const Size(100, 40),
          data: 'A',
        ),
        'b': FlowNode<String>(
          id: 'b',
          type: 'default',
          position: const Offset(200, 0),
          size: const Size(100, 40),
          data: 'B',
        ),
      },
      edges: {
        'e1': FlowEdge(
          id: 'e1',
          sourceNodeId: 'a',
          targetNodeId: 'b',
          sourceHandleId: sourceHandle,
          targetHandleId: targetHandle,
          type: EdgePathType.bezier,
        ),
      },
    );
  }

  void expectOffset(Offset actual, Offset expected) {
    expect(actual.dx, moreOrLessEquals(expected.dx));
    expect(actual.dy, moreOrLessEquals(expected.dy));
  }

  test('handle-less edge connects to default source/target ports, not center',
      () {
    final service = EdgeGeometryService();
    service.updateCache(buildState(), const ['e1']);

    final geom = service.getGeom('e1');
    expect(geom, isNotNull);
    // Source = node a bottom-center (50, 40); target = node b top-center
    // (250, 0). Center fallback would have produced (50, 20) / (250, 20).
    expectOffset(geom!.markers!.startPosition, const Offset(50, 40));
    expectOffset(geom.markers!.endPosition, const Offset(250, 0));
  });

  test('explicit handle ids still resolve to the named handles', () {
    final service = EdgeGeometryService();
    service.updateCache(
      buildState(sourceHandle: 'source', targetHandle: 'target'),
      const ['e1'],
    );

    final geom = service.getGeom('e1');
    expectOffset(geom!.markers!.startPosition, const Offset(50, 40));
    expectOffset(geom.markers!.endPosition, const Offset(250, 0));
  });

  test('unknown handle id falls back to a same-role port, not center', () {
    final service = EdgeGeometryService();
    service.updateCache(
      buildState(sourceHandle: 'does-not-exist'),
      const ['e1'],
    );

    final geom = service.getGeom('e1');
    // Unknown id → first source-capable handle (bottom-center), never center.
    expectOffset(geom!.markers!.startPosition, const Offset(50, 40));
  });
}
