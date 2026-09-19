// ignore_for_file: prefer_const_constructors

import 'package:lattice/lattice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlowLayout parity (dagre/ELK counterpart): layered DAG layout and tidy
/// tree layout as pure map functions.

FlowNode<String> _n(String id, [double w = 100, double h = 50]) =>
    FlowNode<String>(
      type: 'default',
      id: id,
      position: const Offset(-9999, -9999),
      size: Size(w, h),
      data: id,
    );

FlowEdge _e(String id, String source, String target) => FlowEdge(
      id: id,
      sourceNodeId: source,
      targetNodeId: target,
    );

Rect _rect(FlowNode node) =>
    Rect.fromLTWH(node.position.dx, node.position.dy,
        node.size.width, node.size.height);

void _expectFinite(Map<String, FlowNode> placed) {
  for (final node in placed.values) {
    expect(node.position.dx.isFinite, isTrue, reason: '${node.id}.x');
    expect(node.position.dy.isFinite, isTrue, reason: '${node.id}.y');
  }
}

void _expectNoOverlaps(Map<String, FlowNode> placed) {
  final ids = placed.keys.toList();
  for (var i = 0; i < ids.length; i++) {
    for (var j = i + 1; j < ids.length; j++) {
      expect(
        _rect(placed[ids[i]]!).overlaps(_rect(placed[ids[j]]!)),
        isFalse,
        reason: '${ids[i]} overlaps ${ids[j]}',
      );
    }
  }
}

double _cx(FlowNode node) => node.position.dx + node.size.width / 2;
double _cy(FlowNode node) => node.position.dy + node.size.height / 2;

void main() {
  test('layered chain runs top to bottom, centered', () {
    final nodes = {'a': _n('a'), 'b': _n('b'), 'c': _n('c')};
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'b', 'c'),
    };
    final laid = FlowLayout.layered(nodes, edges);

    _expectFinite(laid);
    expect(laid['a']!.position.dy, lessThan(laid['b']!.position.dy));
    expect(laid['b']!.position.dy, lessThan(laid['c']!.position.dy));
    expect(_cx(laid['a']!), _cx(laid['b']!));
    expect(_cx(laid['b']!), _cx(laid['c']!));
    _expectNoOverlaps(laid);
  });

  test('layered diamond shares a layer, order stable', () {
    final nodes = {
      'a': _n('a'),
      'b': _n('b'),
      'c': _n('c'),
      'd': _n('d'),
    };
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'a', 'c'),
      'e3': _e('e3', 'b', 'd'),
      'e4': _e('e4', 'c', 'd'),
    };
    final laid = FlowLayout.layered(nodes, edges);

    _expectFinite(laid);
    expect(laid['b']!.position.dy, laid['c']!.position.dy);
    expect(laid['b']!.position.dx, lessThan(laid['c']!.position.dx));
    expect(laid['a']!.position.dy, lessThan(laid['b']!.position.dy));
    expect(laid['d']!.position.dy, greaterThan(laid['c']!.position.dy));
    _expectNoOverlaps(laid);
  });

  test('layered directions mirror axes', () {
    Map<String, FlowNode> nodes() =>
        {'a': _n('a'), 'b': _n('b'), 'c': _n('c')};
    Map<String, FlowEdge> edges() => {
          'e1': _e('e1', 'a', 'b'),
          'e2': _e('e2', 'b', 'c'),
        };

    final lr = FlowLayout.layered(nodes(), edges(),
        direction: FlowLayoutDirection.leftRight);
    expect(lr['a']!.position.dx, lessThan(lr['b']!.position.dx));
    expect(lr['b']!.position.dx, lessThan(lr['c']!.position.dx));
    expect(_cy(lr['a']!), _cy(lr['b']!));
    _expectNoOverlaps(lr);

    final bt = FlowLayout.layered(nodes(), edges(),
        direction: FlowLayoutDirection.bottomTop);
    expect(bt['a']!.position.dy, greaterThan(bt['b']!.position.dy));
    expect(bt['b']!.position.dy, greaterThan(bt['c']!.position.dy));
    _expectNoOverlaps(bt);

    final rl = FlowLayout.layered(nodes(), edges(),
        direction: FlowLayoutDirection.rightLeft);
    expect(rl['a']!.position.dx, greaterThan(rl['b']!.position.dx));
    _expectNoOverlaps(rl);
  });

  test('layered tolerates cycles without hanging', () {
    final nodes = {'a': _n('a'), 'b': _n('b'), 'c': _n('c')};
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'b', 'c'),
      'e3': _e('e3', 'c', 'a'),
    };
    final laid = FlowLayout.layered(nodes, edges);

    _expectFinite(laid);
    expect(laid.keys.toSet(), {'a', 'b', 'c'});
    _expectNoOverlaps(laid);
  });

  test('layered tiles disconnected components', () {
    final nodes = {
      'a': _n('a'),
      'b': _n('b'),
      'x': _n('x'),
      'y': _n('y'),
    };
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'x', 'y'),
    };
    final laid = FlowLayout.layered(nodes, edges);

    _expectFinite(laid);
    _expectNoOverlaps(laid);
    // Second chain sits beside the first, same structure.
    expect(laid['x']!.position.dx, greaterThan(laid['b']!.position.dx));
    expect(laid['x']!.position.dy, laid['a']!.position.dy);
  });

  test('layered respects mixed sizes and offset', () {
    final nodes = {
      'a': _n('a', 300, 60),
      'b': _n('b', 60, 200),
      'c': _n('c'),
    };
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'a', 'c'),
    };
    final laid = FlowLayout.layered(nodes, edges,
        nodeSpacing: 20, layerSpacing: 30, offset: const Offset(10, 10));

    _expectFinite(laid);
    _expectNoOverlaps(laid);
    expect(laid['a']!.position.dx, greaterThanOrEqualTo(10));
    expect(laid['a']!.position.dy, greaterThanOrEqualTo(10));
    // b and c share a band below a: same center, top-lefts differ by
    // height (vertically centered, dagre-style).
    expect(laid['b']!.position.dy, greaterThan(laid['a']!.position.dy));
    expect(_cy(laid['b']!), _cy(laid['c']!));
  });

  test('layered ignores dangling edges and is pure', () {
    final nodes = {'a': _n('a'), 'b': _n('b')};
    final before = Map<String, FlowNode>.from(nodes);
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'ghost': FlowEdge(id: 'ghost', sourceNodeId: 'a', targetNodeId: 'zzz'),
    };
    final laid = FlowLayout.layered(nodes, edges);

    _expectFinite(laid);
    expect(laid['a']!.position.dy, lessThan(laid['b']!.position.dy));
    // Inputs untouched.
    for (final id in before.keys) {
      expect(nodes[id]!.position, before[id]!.position);
    }
  });

  test('layered leaves parented children riding along', () {
    final nodes = {
      'p': _n('p'),
      'c': FlowNode<String>(
        type: 'default',
        id: 'c',
        position: const Offset(10, 10),
        size: const Size(50, 50),
        data: 'c',
        parentId: 'p',
      ),
    };
    final laid = FlowLayout.layered(nodes, {});

    expect(laid['c']!.position, const Offset(10, 10));
    expect(laid['p']!.position, isNot(const Offset(-9999, -9999)));
  });

  test('layered empty passes through, singletons go to the origin', () {
    expect(FlowLayout.layered({}, {}), isEmpty);
    final single = {'a': _n('a')};
    final laid = FlowLayout.layered(single, {});
    // Like dagre, a lone root is placed at the offset origin.
    expect(laid['a']!.position, Offset.zero);
  });

  test('tree centers parents over children', () {
    final nodes = {
      'r': _n('r'),
      'l': _n('l'),
      'rr': _n('rr'),
      'll': _n('ll'),
      'lr': _n('lr'),
      'rl': _n('rl'),
      'rrr': _n('rrr'),
    };
    final edges = {
      'e1': _e('e1', 'r', 'l'),
      'e2': _e('e2', 'r', 'rr'),
      'e3': _e('e3', 'l', 'll'),
      'e4': _e('e4', 'l', 'lr'),
      'e5': _e('e5', 'rr', 'rl'),
      'e6': _e('e6', 'rr', 'rrr'),
    };
    final laid = FlowLayout.tree(nodes, edges);

    _expectFinite(laid);
    // Leaves share a band; each parent centers over its children.
    for (final leaf in ['ll', 'lr', 'rl', 'rrr']) {
      expect(laid[leaf]!.position.dy, laid['ll']!.position.dy);
    }
    expect(_cx(laid['l']!),
        moreOrLessEquals((_cx(laid['ll']!) + _cx(laid['lr']!)) / 2));
    expect(_cx(laid['rr']!),
        moreOrLessEquals((_cx(laid['rl']!) + _cx(laid['rrr']!)) / 2));
    expect(_cx(laid['r']!),
        moreOrLessEquals((_cx(laid['l']!) + _cx(laid['rr']!)) / 2));
    // Left subtree sits left of the right subtree.
    expect(laid['lr']!.position.dx, lessThan(laid['rl']!.position.dx));
    _expectNoOverlaps(laid);
  });

  test('tree handles chains, direction, and forests', () {
    Map<String, FlowNode> chain() =>
        {'a': _n('a'), 'b': _n('b'), 'c': _n('c')};
    Map<String, FlowEdge> chainEdges() => {
          'e1': _e('e1', 'a', 'b'),
          'e2': _e('e2', 'b', 'c'),
        };

    final tb = FlowLayout.tree(chain(), chainEdges());
    expect(tb['a']!.position.dy, lessThan(tb['b']!.position.dy));
    _expectNoOverlaps(tb);

    final lr = FlowLayout.tree(chain(), chainEdges(),
        direction: FlowLayoutDirection.leftRight);
    expect(lr['a']!.position.dx, lessThan(lr['b']!.position.dx));
    expect(_cy(lr['a']!), _cy(lr['b']!));

    final forest = FlowLayout.tree(
      {'a': _n('a'), 'b': _n('b'), 'x': _n('x')},
      {'e1': _e('e1', 'a', 'b')},
    );
    _expectFinite(forest);
    _expectNoOverlaps(forest);
    expect(forest.keys.toSet(), {'a', 'b', 'x'});
  });

  test('tree rootId scopes to a subtree, unknown throws', () {
    Map<String, FlowNode> nodes() => {
          'a': _n('a'),
          'b': _n('b'),
          'c': _n('c'),
        };
    Map<String, FlowEdge> edges() => {
          'e1': _e('e1', 'a', 'b'),
          'e2': _e('e2', 'b', 'c'),
        };

    final laid = FlowLayout.tree(nodes(), edges(), rootId: 'b');
    // 'a' keeps its sentinel; b/c laid out as a chain.
    expect(laid['a']!.position, const Offset(-9999, -9999));
    expect(laid['b']!.position.dy, lessThan(laid['c']!.position.dy));

    expect(
      () => FlowLayout.tree(nodes(), edges(), rootId: 'nope'),
      throwsArgumentError,
    );
  });

  test('tree tolerates cycles and mixed sizes', () {
    final nodes = {
      'a': _n('a', 200, 60),
      'b': _n('b', 60, 60),
      'c': _n('c', 80, 120),
    };
    final edges = {
      'e1': _e('e1', 'a', 'b'),
      'e2': _e('e2', 'a', 'c'),
      'e3': _e('e3', 'c', 'a'),
    };
    final laid = FlowLayout.tree(nodes, edges);

    _expectFinite(laid);
    expect(laid.keys.toSet(), {'a', 'b', 'c'});
    _expectNoOverlaps(laid);
  });

  test('layouts are deterministic and pure', () {
    Map<String, FlowNode> nodes() => {
          'a': _n('a'),
          'b': _n('b'),
          'c': _n('c'),
          'd': _n('d'),
        };
    Map<String, FlowEdge> edges() => {
          'e1': _e('e1', 'a', 'b'),
          'e2': _e('e2', 'a', 'c'),
          'e3': _e('e3', 'b', 'd'),
          'e4': _e('e4', 'c', 'd'),
        };

    final input = nodes();
    final snapshot = {for (final e in input.entries) e.key: e.value.position};
    final first = FlowLayout.layered(input, edges());
    final second = FlowLayout.layered(nodes(), edges());
    for (final id in first.keys) {
      expect(second[id]!.position, first[id]!.position);
      // Inputs untouched.
      expect(input[id]!.position, snapshot[id]);
    }
    final t1 = FlowLayout.tree(input, edges());
    final t2 = FlowLayout.tree(nodes(), edges());
    for (final id in t1.keys) {
      expect(t2[id]!.position, t1[id]!.position);
      expect(input[id]!.position, snapshot[id]);
    }
  });
}
