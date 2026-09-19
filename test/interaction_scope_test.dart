import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/features/canvas/interaction_session.dart';

/// Render-scope contract for [InteractionSession]: per-node scopes fire only
/// for nodes whose visuals can change during a gesture (dragged roots,
/// their descendants, live-positioned/resized ids). Static nodes stay silent
/// — no builder runs, no element updates — on every gesture tick.
void main() {
  testWidgets('scopes notify only affected nodes across a drag',
      (tester) async {
    final session = InteractionSession();
    var aFires = 0;
    var bFires = 0;
    var childFires = 0;
    session.scopeFor('a').addListener(() => aFires++);
    session.scopeFor('b').addListener(() => bFires++);
    session.scopeFor('child').addListener(() => childFires++);

    // beginDrag notifies synchronously: dragged root + descendant fire.
    session.beginDrag(
      nodeIds: {'a'},
      startPositions: {'a': Offset.zero},
      edgeIds: const {},
      affectedNodeIds: {'a', 'child'},
    );
    expect(aFires, 1);
    expect(childFires, 1);
    expect(bFires, 0);

    // Frame-coalesced tick: dragged root and riding-along descendant fire.
    session.setLivePositions({'a': const Offset(10, 0)});
    await tester.pump();
    expect(aFires, 2);
    expect(childFires, 2);
    expect(bFires, 0);

    // No-op write schedules nothing.
    session.setLivePositions({'a': const Offset(10, 0)});
    await tester.pump();
    expect(aFires, 2);
    expect(childFires, 2);
    expect(bFires, 0);

    // endDrag notifies synchronously; cleared stamps force one resync fire
    // for previously-touched scopes only.
    session.endDrag();
    expect(aFires, 3);
    expect(childFires, 3);
    expect(bFires, 0);

    session.dispose();
  });

  testWidgets('live size bumps only the resized scope', (tester) async {
    final session = InteractionSession();
    var parentFires = 0;
    var otherFires = 0;
    session.scopeFor('parent').addListener(() => parentFires++);
    session.scopeFor('other').addListener(() => otherFires++);

    session.beginDrag(
      nodeIds: {'a'},
      startPositions: {'a': Offset.zero},
      edgeIds: const {},
      affectedNodeIds: {'a'},
    );
    expect(parentFires, 0);

    session.setLiveSize('parent', const Size(200, 200));
    await tester.pump();
    expect(parentFires, 1);
    expect(otherFires, 0);

    session.endDrag();
    // 'other' never fired the whole gesture.
    expect(otherFires, 0);

    session.dispose();
  });
}
