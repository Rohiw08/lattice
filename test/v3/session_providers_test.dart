import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lattice/src/v3/v3.dart';

LatticeNode _node(String id, [Offset offset = Offset.zero]) {
  return LatticeNode(id: id, type: 'default', position: offset);
}

void main() {
  group('session defaults', () {
    test('document defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(latticeDocumentProvider), equals(const LatticeDocument()));
    });

    test('selection defaults to empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const selection = LatticeSelection();
      expect(container.read(latticeSelectionProvider), equals(selection));
      expect(container.read(latticeSelectionProvider).isEmpty, isTrue);
    });

    test('drag defaults to idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const drag = LatticeDragState.idle();
      expect(drag.isActive, isFalse);
      expect(container.read(latticeDragProvider).isActive, isFalse);
    });

    test('hover defaults to null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(latticeHoverProvider), isNull);
    });
  });

  group('LatticeSelection value', () {
    test('==/hashCode/copyWith/isEmpty', () {
      const a = LatticeSelection(nodes: {'n1'}, edges: {'e1'});
      const b = LatticeSelection(nodes: {'n1'}, edges: {'e1'});
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a.isEmpty, isFalse);
      expect(const LatticeSelection().isEmpty, isTrue);
      expect(
        a.copyWith(nodes: {'n2'}),
        equals(const LatticeSelection(nodes: {'n2'}, edges: {'e1'})),
      );
    });
  });

  group('LatticeDragState value', () {
    test('node and marquee variants are active', () {
      const node = LatticeDragState.node(
        ids: {'n1'},
        livePositions: {'n1': Offset(3, 4)},
      );
      expect(node.isActive, isTrue);
      const marquee = LatticeDragState.marquee(
        rect: Rect.fromLTRB(0, 0, 10, 10),
      );
      expect(marquee.isActive, isTrue);
    });
  });

  group('session mutations', () {
    test('replace swaps the document', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final doc = LatticeDocument(nodes: {'n1': _node('n1')});
      container.read(latticeDocumentProvider.notifier).replace(doc);
      expect(container.read(latticeDocumentProvider), equals(doc));
    });

    test('setSelection with equal value emits nothing', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      var emissions = 0;
      container.listen<LatticeSelection>(
        latticeSelectionProvider,
        (_, _) => emissions++,
        fireImmediately: false,
      );
      const selection = LatticeSelection(nodes: {'n1'});
      container.read(latticeSelectionProvider.notifier).setSelection(selection);
      expect(emissions, equals(1));
      container
          .read(latticeSelectionProvider.notifier)
          .setSelection(const LatticeSelection(nodes: {'n1'}));
      expect(emissions, equals(1));
    });

    test('clear empties the selection', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container
          .read(latticeSelectionProvider.notifier)
          .setSelection(const LatticeSelection(nodes: {'n1'}));
      container.read(latticeSelectionProvider.notifier).clear();
      expect(container.read(latticeSelectionProvider).isEmpty, isTrue);
    });

    test('drag set swaps variants', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const marquee = LatticeDragState.marquee(
        rect: Rect.fromLTRB(1, 2, 4, 6),
      );
      container.read(latticeDragProvider.notifier).set(marquee);
      expect(container.read(latticeDragProvider).isActive, isTrue);
      container
          .read(latticeDragProvider.notifier)
          .set(const LatticeDragState.idle());
      expect(container.read(latticeDragProvider).isActive, isFalse);
    });

    test('hover set stores the id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(latticeHoverProvider.notifier).set('n1');
      expect(container.read(latticeHoverProvider), equals('n1'));
      container.read(latticeHoverProvider.notifier).set(null);
      expect(container.read(latticeHoverProvider), isNull);
    });
  });

  group('public selectors', () {
    test('families return null for missing ids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(latticeNodeProvider('missing')), isNull);
      expect(container.read(latticeEdgeProvider('missing')), isNull);
    });

    test('families return records for present ids', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final node = _node('n1', const Offset(1, 2));
      const edge = LatticeEdge(
        id: 'e1',
        source: LatticeEndpoint(nodeId: 'n1'),
        target: LatticeEndpoint(nodeId: 'n2'),
      );
      container.read(latticeDocumentProvider.notifier).replace(
            LatticeDocument(
              nodes: {'n1': node},
              edges: {'e1': edge},
            ),
          );
      expect(container.read(latticeNodeProvider('n1')), equals(node));
      expect(container.read(latticeEdgeProvider('e1')), equals(edge));
      expect(
        container.read(latticeNodesProvider),
        equals(<String, LatticeNode>{'n1': node}),
      );
      expect(
        container.read(latticeEdgesProvider),
        equals(<String, LatticeEdge>{'e1': edge}),
      );
    });

    test('viewport selector follows the document', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(latticeViewportProvider),
        equals(const LatticeViewportValue()),
      );
      const viewport = LatticeViewportValue(offset: Offset(5, 6), zoom: 2.0);
      container
          .read(latticeDocumentProvider.notifier)
          .replace(const LatticeDocument(viewport: viewport));
      expect(container.read(latticeViewportProvider), equals(viewport));
    });

    test('derived maps stay identical across a session-only emission', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(latticeDocumentProvider.notifier).replace(
            LatticeDocument(nodes: {'n1': _node('n1')}),
          );
      final nodesBefore = container.read(latticeNodesProvider);
      final edgesBefore = container.read(latticeEdgesProvider);
      container.read(latticeHoverProvider.notifier).set('n1');
      expect(container.read(latticeNodesProvider), same(nodesBefore));
      expect(container.read(latticeEdgesProvider), same(edgesBefore));
    });
  });
}
