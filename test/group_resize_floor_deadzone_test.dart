// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/node_resizer/presentation/flow_node_resizer_handle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Resize floor dead-zone parity (same absolute-mapping semantics as the
/// node-drag clamp dead zone):
///
/// Shrinking a group south pins its bottom edge at the
/// [NodeLayout.childExtentFloor] (children with `extent: parent` /
/// `expandParent`). Pushing further and coming back must pin while the
/// pointer is still inside the floored-away region (dead zone) and restore
/// the exact origin — never a permanent cursor/edge gap.

void main() {
  testWidgets(
      'group south-resize into the child floor dead-zones and restores origin',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: FlowCanvas(
            theme: FlowCanvasTheme.dark(),
            initialNodes: [
              // NOTE: the canvas centers flow origin at the window center
              // (offset 400,300 @zoom 1), so park the fixture where its
              // south handle stays on the 800x600 test surface.
              FlowNode<String>(
                type: 'group',
                id: 'group_1',
                position: const Offset(-260, -150),
                size: const Size(360, 200),
                data: 'Group',
                resizable: true,
              ),
              FlowNode<String>(
                type: 'default',
                id: 'node_a',
                parentId: 'group_1',
                position: const Offset(100, 80),
                size: const Size(160, 100),
                data: 'A',
                extent: FlowNodeExtent.parent,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    // Select the group (tap group-only space) so the resizer mounts.
    // Screen points come from rendered rects — never assume screen==flow.
    final groupRect =
        tester.getRect(find.byKey(const ValueKey('background_group_1')));
    final childRect =
        tester.getRect(find.byKey(const ValueKey('middle_node_a')));
    final tapPoint = groupRect.topLeft + const Offset(50, 20);
    expect(childRect.contains(tapPoint), isFalse,
        reason: 'test setup: tap must hit group-only space');
    await tester.tapAt(tapPoint);
    await tester.pump();

    final container = ProviderScope.containerOf(
      tester.element(find.byType(BaseNode).first),
    );
    double groupHeight() =>
        container.read(internalControllerProvider).nodes['group_1']!.size.height;
    Offset childPos() =>
        container.read(internalControllerProvider).nodes['node_a']!.position;

    // Press the actual rendered south-handle pixels (viewport-agnostic).
    final handle = tester
        .widgetList<NodeResizeHandle>(find.byType(NodeResizeHandle))
        .firstWhere(
          (h) => h.nodeId == 'group_1' && h.direction == Alignment.bottomCenter,
        );
    final handleCenter = tester
        .getRect(
          find.descendant(
            of: find.byWidget(handle),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .center;
    expect(handleCenter.dx, inExclusiveRange(0, 800),
        reason: 'test setup: handle must be on the test surface');
    expect(handleCenter.dy, inExclusiveRange(0, 600),
        reason: 'test setup: handle must be on the test surface');
    final gesture = await tester.startGesture(handleCenter);
    await tester.pump();
    // Breaks touch slop; absorbed, so the resize anchors at height 200.
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();

    // Shrink 50px: group flow bottom 50 -> 0, but the child-extent floor
    // pins it at child abs bottom (-150 + 80 + 100 = 30), i.e. height 180.
    for (var i = 0; i < 5; i++) {
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
    }
    expect(groupHeight(), moreOrLessEquals(180.0),
        reason: 'group bottom must pin at the child-extent floor');

    // Move back DOWN 10px — still inside the floored-away region.
    await gesture.moveBy(const Offset(0, 10));
    await tester.pump();
    expect(groupHeight(), moreOrLessEquals(180.0),
        reason: 'dead zone: edge stays pinned while the pointer is still '
            'inside floored-away travel (no gap opens)');

    // Return the pointer fully (mirror of the push). The framework absorbs
    // the slop-breaking prefix of the gesture into arena acceptance, so the
    // delivered travel lands within that small envelope of zero — but with
    // zero cursor/edge gap either way. (The incremental implementation this
    // replaces ends this same script at 230: the floored-away travel kept
    // as a permanent gap.)
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 10));
      await tester.pump();
    }
    final restored = groupHeight();
    expect(restored, inInclusiveRange(200.0, 210.0),
        reason: 'edge must return to its resize-activation origin up to the '
            'framework-absorbed slop envelope, with no gap');

    await gesture.up();
    await tester.pump();
    expect(groupHeight(), moreOrLessEquals(restored),
        reason: 'commit must preserve the restored size');
    expect(childPos(), const Offset(100, 80),
        reason: 'floor protects the child: never moved nor resized');
  });
}
