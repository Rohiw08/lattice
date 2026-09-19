# Typing

`lattice` is fully typed — and because the canvas owns its state
(uncontrolled by default), there is no `applyNodeChanges` ceremony.
This guide covers the idiomatic patterns; see `example/main.dart` for a
runnable version of the sealed-data recipe.

## Uncontrolled first

The common case needs no state plumbing at all. Types flow from your node
declarations into builders and controllers:

```dart
final nodes = <FlowNode<DemoNodeData>>[
  FlowNode(id: 'a', type: 'demo', position: Offset(80, 120), data: StartData()),
];

FlowCanvas(
  controller: controller,
  initialNodes: nodes,
  initialEdges: const [
    FlowEdge(id: 'e1', sourceNodeId: 'a', targetNodeId: 'b'),
  ],
  callbacks: FlowCanvasCallbacks(
    onNodesChange: (changes) {
      for (final change in changes) {
        switch (change) {
          case NodeAddChange(:final node):
            debugPrint('added ${node.id}');
          case NodeRemoveChange(:final id):
            debugPrint('removed $id');
          case NodePositionChange(
              :final id,
              :final position,
              :final dragging
            ):
            debugPrint('$id → $position (dragging: $dragging)');
          case NodeDimensionsChange(:final id, :final size):
            debugPrint('$id resized to $size');
        }
      }
    },
    onConnect: (edge) => debugPrint('connected ${edge.id}'),
  ),
);
```

`NodeChange` / `EdgeChange` are sealed: the `switch` above is
compiler-checked for exhaustiveness.

## Sealed node data (recommended)

Model each node's payload as a `sealed` hierarchy instead of raw maps.
One union for the whole app, one branch per variant:

```dart
sealed class DemoNodeData {
  const DemoNodeData();
  String get label;
}

final class StartData extends DemoNodeData {
  const StartData();
  @override
  String get label => 'Start';
}

final class ProcessData extends DemoNodeData {
  const ProcessData(this.step);
  final int step;
  @override
  String get label => 'Process $step';
}

final class EndData extends DemoNodeData {
  const EndData();
  @override
  String get label => 'End';
}
```

Register one typed builder per node `type` and switch exhaustively —
adding a variant without handling it is a compile error:

```dart
NodeRegistry()
  ..registerTyped<DemoNodeData>('demo', (props) {
    final label = switch (props.data) {
      StartData(:final label) => label,
      ProcessData(:final label) => label,
      EndData(:final label) => label,
      null => '?', // unreachable when every node carries data
    };
    return BaseNode(node: props.node, child: Text(label));
  });
```

`NodeProps<T>.data` is `T?`. Prefer per-type builders (`registerTyped`)
over one giant union builder; use `props.cast<R>()` to narrow when a
builder must reinterpret the payload (throws on mismatch, like `as`).

## Selectors keep their types

```dart
// Map<String, FlowNode> — data stays Object? here; narrow per node.
final nodes = ref.watch(flowNodesProvider);

// Arbitrary slices stay typed through inference:
final zoom = ref.watch(flowViewportProvider.select((v) => v.zoom)); // double
final dragging = ref.watch(
  flowStateProvider.select((s) => s.dragMode == DragMode.node),
); // bool
```

Narrow a single node's payload with a plain `is` check:

```dart
final data = controller.nodes.getNode('a')?.data;
if (data is ProcessData) {
  debugPrint(data.step); // int, no cast needed
}
```

## Edge data

Edges carry `Map<String, dynamic> data` (deliberately not generic — see
below). For typed access, add extension getters next to your model:

```dart
extension on FlowEdge {
  double get weight => (data['weight'] as num?)?.toDouble() ?? 1.0;
}
```

## Controlled vs uncontrolled

Prefer uncontrolled (controller + callbacks). If you mirror graph state
into app state, do it selectively — and never round-trip through `load()`
per change: `load()` replaces the document and resets undo history.
`toJson()` is for persistence (save files, share links), not for the
frame loop.

## Non-goals

- `FlowEdge<T>` stays non-generic: threading a data type through state,
  services, registries, and codegen buys a cast saved per edge type at the
  cost of verbosity at every call site.
- `FlowCanvas` itself stays non-generic: registries already carry your
  types, so widget-level type parameters would only repeat them.
