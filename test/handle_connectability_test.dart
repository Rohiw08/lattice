// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:lattice/src/core/providers/providers.dart';
import 'package:lattice/src/features/connections/application/connection_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Per-handle connectability parity (React Flow per-`Handle`
/// `isConnectable` / `isConnectableStart` / `isConnectableEnd` /
/// `isValidConnection` / `onConnect`, plus declarative `maxConnections`).

FlowNode<String> _node(
  String id,
  Offset position, {
  Map<String, FlowHandle> handles = const {},
}) =>
    FlowNode<String>(
      id: id,
      type: 'custom',
      position: position,
      handles: handles,
    );

FlowCanvasState _graph({
  FlowHandle? outHandle,
  FlowHandle? inHandle,
  List<FlowEdge> edges = const [],
}) =>
    FlowCanvasState.initial().copyWith(
      nodes: {
        'a': _node('a', Offset.zero, handles: {
          'out': outHandle ??
              FlowHandle(
                  id: 'out',
                  type: HandleType.source,
                  position: const Offset(160, 22)),
        }),
        'b': _node('b', const Offset(200, 0), handles: {
          'in': inHandle ??
              FlowHandle(
                  id: 'in',
                  type: HandleType.target,
                  position: const Offset(0, 22)),
        }),
      },
      edges: {for (final e in edges) e.id: e},
    );

void main() {
  group('allowsStart / allowsEnd defaults', () {
    test('type-derived roles in strict mode', () {
      const source = FlowHandle(
          id: 's', type: HandleType.source, position: Offset.zero);
      const target = FlowHandle(
          id: 't', type: HandleType.target, position: Offset.zero);
      expect(source.allowsStart(ConnectionMode.strict), isTrue);
      expect(source.allowsEnd(ConnectionMode.strict), isFalse);
      expect(target.allowsStart(ConnectionMode.strict), isFalse);
      expect(target.allowsEnd(ConnectionMode.strict), isTrue);
    });

    test('explicit overrides win', () {
      const targetStarter = FlowHandle(
        id: 't',
        type: HandleType.target,
        position: Offset.zero,
        isConnectableStart: true,
      );
      expect(targetStarter.allowsStart(ConnectionMode.strict), isTrue);

      const endOnly = FlowHandle(
        id: 's',
        type: HandleType.source,
        position: Offset.zero,
        isConnectableEnd: false,
      );
      expect(endOnly.allowsEnd(ConnectionMode.loose), isFalse);
    });

    test('isConnectable false blocks everything', () {
      const off = FlowHandle(
        id: 's',
        type: HandleType.source,
        position: Offset.zero,
        isConnectable: false,
      );
      expect(off.allowsStart(ConnectionMode.loose), isFalse);
      expect(off.allowsEnd(ConnectionMode.loose), isFalse);
    });
  });

  group('service enforcement', () {
    final service = ConnectionService();

    test('non-connectable source cannot start', () {
      final state = _graph(
        outHandle: FlowHandle(
            id: 'out',
            type: HandleType.source,
            position: const Offset(160, 22),
            isConnectable: false),
      );
      final next = service.startConnection(state,
          fromNodeId: 'a', fromHandleId: 'out', startPosition: Offset.zero);
      expect(next.activeConnection, isNull);
    });

    test('target can start in strict only with isConnectableStart', () {
      final plain = _graph();
      final blocked = service.startConnection(plain,
          fromNodeId: 'b', fromHandleId: 'in', startPosition: Offset.zero);
      expect(blocked.activeConnection, isNull);

      final enabled = _graph(
        inHandle: FlowHandle(
            id: 'in',
            type: HandleType.target,
            position: const Offset(0, 22),
            isConnectableStart: true),
      );
      final started = service.startConnection(enabled,
          fromNodeId: 'b', fromHandleId: 'in', startPosition: Offset.zero);
      expect(started.activeConnection, isNotNull);
    });

    test('isConnectableEnd false rejects landing even in loose mode', () {
      final state = _graph(
        inHandle: FlowHandle(
            id: 'in',
            type: HandleType.target,
            position: const Offset(0, 22),
            isConnectableEnd: false),
      );
      final a = state.nodes['a']!;
      final b = state.nodes['b']!;
      expect(
          service.isValidConnectionPair(
            a,
            a.effectiveHandles['out']!,
            b,
            b.effectiveHandles['in']!,
            mode: ConnectionMode.loose,
          ),
          isFalse);
    });

    test('per-handle validator vetoes the pair', () {
      bool seen = false;
      final state = _graph(
        inHandle: FlowHandle(
          id: 'in',
          type: HandleType.target,
          position: const Offset(0, 22),
          isValidConnection: (params) {
            seen = true;
            expect(params.sourceNodeId, 'a');
            return false;
          },
        ),
      );
      final a = state.nodes['a']!;
      final b = state.nodes['b']!;
      expect(
          service.isValidConnectionPair(
              a, a.effectiveHandles['out']!, b, b.effectiveHandles['in']!),
          isFalse);
      expect(seen, isTrue);
    });

    test('maxConnections caps declaratively', () {
      final capped = FlowHandle(
          id: 'out',
          type: HandleType.source,
          position: const Offset(160, 22),
          maxConnections: 1);
      expect(capped.hasCapacity(const [], 'a'), isTrue);
      final used = [
        FlowEdge(
            id: 'e1',
            sourceNodeId: 'a',
            sourceHandleId: 'out',
            targetNodeId: 'b',
            targetHandleId: 'in'),
      ];
      expect(capped.hasCapacity(used, 'a'), isFalse);

      // ...and the service rejects the second edge.
      final state = _graph(outHandle: capped, edges: used);
      final a = state.nodes['a']!;
      final b = state.nodes['b']!;
      expect(
          service.isValidConnectionPair(
            a,
            a.effectiveHandles['out']!,
            b,
            b.effectiveHandles['in']!,
            existingEdges: state.edges.values,
          ),
          isFalse);
      // Starting another drag from the full handle is blocked too.
      final next = service.startConnection(state,
          fromNodeId: 'a', fromHandleId: 'out', startPosition: Offset.zero);
      expect(next.activeConnection, isNull);
    });
  });

  group('widget drags', () {
    Future<ProviderContainer> pump(
      WidgetTester tester, {
      FlowHandle? outHandle,
      FlowHandle? inHandle,
      void Function(ConnectionParams)? onSourceConnect,
      void Function(ConnectionParams)? onTargetConnect,
      NodeRegistry? registry,
    }) async {
      final out = (outHandle ??
              FlowHandle(
                  id: 'out',
                  type: HandleType.source,
                  position: const Offset(160, 22)))
          .copyWith(
              onConnect: onSourceConnect ??
                  outHandle?.onConnect);
      final inn = (inHandle ??
              FlowHandle(
                  id: 'in',
                  type: HandleType.target,
                  position: const Offset(0, 22)))
          .copyWith(
              onConnect:
                  onTargetConnect ?? inHandle?.onConnect);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 800,
            height: 600,
            child: FlowCanvas(
              theme: FlowCanvasTheme.dark(),
              nodeRegistry: registry,
              initialState: _graph(outHandle: out, inHandle: inn),
            ),
          ),
        ),
      );
      await tester.pump();
      return ProviderScope.containerOf(
          tester.element(find.byKey(ValueKey('middle_a'))));
    }

    Future<void> dragOutToIn(WidgetTester tester) async {
      final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
      final sourceGlobal = tester.getCenter(find.byWidget(handles.firstWhere(
        (h) => h.nodeId == 'a' && h.handleId == 'out',
      )));
      final targetGlobal = tester.getCenter(find.byWidget(handles.firstWhere(
        (h) => h.nodeId == 'b' && h.handleId == 'in',
      )));
      final gesture = await tester.startGesture(sourceGlobal);
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      await gesture.moveTo(targetGlobal);
      await tester.pump();
      await gesture.up();
      await tester.pump();
    }

    testWidgets('model onConnect fires on both ends', (tester) async {
      var sourceCalls = 0;
      var targetCalls = 0;
      final container = await pump(tester,
          onSourceConnect: (_) => sourceCalls++,
          onTargetConnect: (_) => targetCalls++);
      await dragOutToIn(tester);

      final after = container.read(internalControllerProvider);
      expect(
          after.edges.values.any(
              (e) => e.sourceNodeId == 'a' && e.targetNodeId == 'b'),
          isTrue);
      expect(sourceCalls, 1);
      expect(targetCalls, 1);
    });

    testWidgets('model isConnectable false blocks the drag', (tester) async {
      final container = await pump(tester,
          outHandle: FlowHandle(
              id: 'out',
              type: HandleType.source,
              position: const Offset(160, 22),
              isConnectable: false));
      final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
      final sourceGlobal = tester.getCenter(find.byWidget(handles.firstWhere(
        (h) => h.nodeId == 'a' && h.handleId == 'out',
      )));
      final gesture = await tester.startGesture(sourceGlobal);
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      expect(container.read(internalControllerProvider).activeConnection,
          isNull,
          reason: 'disabled handle must not start a rubber-band');
      await gesture.up();
      await tester.pump();
    });

    testWidgets('widget isConnectable gates the drag locally', (tester) async {
      final registry = NodeRegistry()
        ..register('gated', (node) {
          // Model entry stays default-connectable; the widget restricts.
          return InfiniteHitTestStack(
            clipBehavior: Clip.none,
            children: [
              Text('g-${node.id}'),
              Handle(
                nodeId: node.id,
                handleId: 'out',
                type: HandleType.source,
                position: const Offset(160, 22),
                isConnectable: false,
              ),
            ],
          );
        });
      final container = await pump(tester, registry: registry);
      // Swap node a to the gated custom type (model handle untouched).
      container
          .read(internalControllerProvider.notifier)
          .nodes
          .updateNode(container
              .read(internalControllerProvider)
              .nodes['a']!
              .copyWith(type: 'gated'));
      await tester.pump();

      final handles = tester.widgetList<Handle>(find.byType(Handle)).toList();
      final gated = handles.firstWhere(
        (h) => h.nodeId == 'a' && h.handleId == 'out',
      );
      expect(gated.isConnectable, isFalse);
      final gesture =
          await tester.startGesture(tester.getCenter(find.byWidget(gated)));
      await tester.pump();
      await gesture.moveBy(const Offset(30, 20));
      await tester.pump();
      expect(container.read(internalControllerProvider).activeConnection,
          isNull,
          reason: 'widget-gated handle must not start a rubber-band');
      await gesture.up();
      await tester.pump();
    });
  });
}
