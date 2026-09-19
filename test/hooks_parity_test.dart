// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Hook parity: `useConnection` → [watchConnection], `useNodesInitialized`
/// → [watchNodesInitialized], `useKeyPress` → [FlowKeyPress].

class _ConnProbe extends ConsumerWidget {
  const _ConnProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = watchConnection(ref);
    return Text(
      '${c.inProgress}:${c.fromNodeId}/${c.fromHandleId}:${c.isValid}',
      key: Key('conn'),
    );
  }
}

class _InitProbe extends ConsumerWidget {
  const _InitProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      watchNodesInitialized(ref) ? 'ready' : 'waiting',
      key: Key('init'),
    );
  }
}

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  List<Widget> overlays = const [
    // Tight overlays: bare widgets in the overlay Stack size loosely and
    // can swallow canvas pointers (see FlowEdgeLabelPortal docs).
    Positioned(top: 0, left: 0, child: _ConnProbe()),
    Positioned(top: 20, left: 0, child: _InitProbe()),
  ],
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: FlowCanvas(
          theme: FlowCanvasTheme.dark(),
          initialNodes: [
            FlowNode<String>(id: 'a', type: 'default', position: Offset.zero),
            FlowNode<String>(
              id: 'b',
              type: 'default',
              position: const Offset(300, 0),
            ),
          ],
          overlays: overlays,
        ),
      ),
    ),
  );
  await tester.pump();
  return ProviderScope.containerOf(tester.element(find.byKey(Key('conn'))));
}

void main() {
  testWidgets('watchConnection is idle, then live during a drag',
      (tester) async {
    final container = await _pump(tester);
    expect(find.text('false:null/null:false'), findsOneWidget);
    expect(find.text('ready'), findsOneWidget);

    final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
    final sourceGlobal = tester.getCenter(find.byWidget(handles.firstWhere(
      (h) => h.nodeId == 'a' && h.handleId == 'source',
    )));
    final targetGlobal = tester.getCenter(find.byWidget(handles.firstWhere(
      (h) => h.nodeId == 'b' && h.handleId == 'target',
    )));
    debugPrint(
        'probe main: handles=${handles.length} source=$sourceGlobal target=$targetGlobal');

    final gesture = await tester.startGesture(sourceGlobal);
    await tester.pump();
    await gesture.moveBy(const Offset(30, 20));
    await tester.pump();
    expect(find.text('true:a/source:false'), findsOneWidget,
        reason: 'rubber-band in progress, hovering nothing valid yet');

    await gesture.moveTo(targetGlobal);
    await tester.pump();
    expect(find.text('true:a/source:true'), findsOneWidget,
        reason: 'hovering a valid target flips isValid');

    await gesture.up();
    await tester.pump();
    expect(find.text('false:null/null:false'), findsOneWidget);

    // Sanity: the drag really connected.
    final after = container.read(internalControllerProvider);
    expect(
        after.edges.values
            .any((e) => e.sourceNodeId == 'a' && e.targetNodeId == 'b'),
        isTrue);
  });

  testWidgets('FlowKeyPress rebuilds while the key is held', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FlowKeyPress(
          keys: {LogicalKeyboardKey.shift},
          builder: (context, pressed) =>
              Text(pressed ? 'DOWN' : 'UP', key: Key('kp')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('UP'), findsOneWidget);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.text('DOWN'), findsOneWidget);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(find.text('UP'), findsOneWidget);
  });
}
