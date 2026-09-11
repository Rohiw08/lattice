import 'package:lattice/src/core/state/flow_canvas_state.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';
import 'package:lattice/src/features/viewport/domain/viewport.dart';
import 'package:lattice/src/features/viewport/domain/viewport_transform.dart';
import 'package:lattice/src/features/viewport/domain/visible_flow_region.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('computeVisibleFlowRect uses viewport transform', () {
    final state = FlowCanvasState.initial().copyWith(
      viewport: const FlowViewport(offset: Offset(10, 20), zoom: 2),
      viewportSize: const Size(100, 80),
    );
    final r = computeVisibleFlowRect(state);
    expect(r.left, lessThan(r.right));
    expect(r.top, lessThan(r.bottom));
  });

  test('computeVisibleFlowRectFromCanvasTransform matches state viewport', () {
    const vp = FlowViewport(offset: Offset(30, -5), zoom: 1.25);
    const viewSize = Size(640, 480);
    final state = FlowCanvasState.initial().copyWith(
      viewport: vp,
      viewportSize: viewSize,
    );
    final fromState = computeVisibleFlowRect(state, padding: 12);
    final fromMatrix = computeVisibleFlowRectFromCanvasTransform(
      matrix4FromViewport(vp),
      viewSize,
      padding: 12,
    );
    expect(fromMatrix.left, closeTo(fromState.left, 1e-6));
    expect(fromMatrix.top, closeTo(fromState.top, 1e-6));
    expect(fromMatrix.right, closeTo(fromState.right, 1e-6));
    expect(fromMatrix.bottom, closeTo(fromState.bottom, 1e-6));
  });

  test('flowNodeOverlapsRect matches node rect', () {
    final n = FlowNode.create(
      id: 'n',
      type: 'default',
      position: Offset.zero,
      size: const Size(50, 40),
      data: const {},
    );
    final nodes = {'n': n};
    expect(
      flowNodeOverlapsRect(n, const Rect.fromLTWH(0, 0, 10, 10), nodes),
      isTrue,
    );
    expect(
      flowNodeOverlapsRect(n, const Rect.fromLTWH(200, 200, 10, 10), nodes),
      isFalse,
    );
  });
}
