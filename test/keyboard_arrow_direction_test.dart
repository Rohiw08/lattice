import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/core/enums/enums.dart';
import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/clipboard/application/clipboard_service.dart';
import 'package:lattice/src/features/edges/application/edge_service.dart';
import 'package:lattice/src/features/keyboard/application/keyboard_service.dart';
import 'package:lattice/src/features/nodes/application/node_service.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/selection/application/selection_service.dart';
import 'package:lattice/src/features/viewport/application/viewport_service.dart';
import 'package:lattice/src/features/viewport/domain/coordinate_extent.dart';

/// Arrow-key nudges must move nodes in the on-screen direction. Flow space is
/// +y-DOWN (screen convention), and moves apply `position + delta`, so:
///   ArrowUp   → dy must DECREASE
///   ArrowDown → dy must INCREASE
/// A prior bug swapped the vertical signs (moveUp added +dy), so ArrowUp moved
/// the node visually DOWN. Horizontal was always correct; guard all four.
void main() {
  final service = KeyboardService(
    nodeService: NodeService(),
    selectionService: SelectionService(),
    clipboardService: ClipboardService(),
    edgeService: EdgeService(),
    viewportService: ViewportService(),
  );

  // A single selected node at a known position.
  FlowCanvasState seeded() {
    const node = FlowNode<String>(
      id: 'n',
      type: 'default',
      position: Offset(100, 100),
      data: 'N',
    );
    return const FlowCanvasState().copyWith(
      nodes: {'n': node},
      selectedNodes: {'n'},
    );
  }

  Offset move(KeyboardAction action) {
    final next = service.handleAction(
      seeded(),
      action,
      arrowMoveDelta: const Offset(10, 10),
      minZoom: 0.1,
      maxZoom: 4,
      translateExtent: const CoordinateExtent.infinite(),
      zoomStep: 0.1,
    );
    return next.nodes['n']!.position;
  }

  test('ArrowUp moves the node up on screen (dy decreases)', () {
    expect(move(KeyboardAction.moveUp), const Offset(100, 90));
  });

  test('ArrowDown moves the node down on screen (dy increases)', () {
    expect(move(KeyboardAction.moveDown), const Offset(100, 110));
  });

  test('ArrowLeft moves the node left (dx decreases)', () {
    expect(move(KeyboardAction.moveLeft), const Offset(90, 100));
  });

  test('ArrowRight moves the node right (dx increases)', () {
    expect(move(KeyboardAction.moveRight), const Offset(110, 100));
  });
}
