import 'package:flutter/material.dart';
import 'package:lattice/lattice.dart';

void main() => runApp(const LatticeExampleApp());

/// Sealed payload for every node in this app — see TYPING.md for the recipe.
sealed class DemoNodeData {
  const DemoNodeData();
  String get label;
  IconData get icon;
}

final class StartData extends DemoNodeData {
  const StartData();
  @override
  String get label => 'Start';
  @override
  IconData get icon => Icons.play_arrow;
}

final class ProcessData extends DemoNodeData {
  const ProcessData(this.step);
  final int step;
  @override
  String get label => 'Process $step';
  @override
  IconData get icon => Icons.settings;
}

final class EndData extends DemoNodeData {
  const EndData();
  @override
  String get label => 'End';
  @override
  IconData get icon => Icons.flag;
}

/// Minimal `lattice` example: three typed nodes connected by two edges.
class LatticeExampleApp extends StatelessWidget {
  const LatticeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lattice example',
      theme: FlowCanvasTheme.light().toThemeData(),
      darkTheme: FlowCanvasTheme.dark().toThemeData(
        brightness: Brightness.dark,
      ),
      home: const LatticeExampleScreen(),
    );
  }
}

class LatticeExampleScreen extends StatefulWidget {
  const LatticeExampleScreen({super.key});

  @override
  State<LatticeExampleScreen> createState() => _LatticeExampleScreenState();
}

class _LatticeExampleScreenState extends State<LatticeExampleScreen> {
  late final FlowCanvasController _controller;
  late final NodeRegistry _nodeRegistry;

  static const _nodes = <FlowNode<DemoNodeData>>[
    FlowNode<DemoNodeData>(
      id: 'input_1',
      type: 'input',
      position: Offset(80, 120),
      data: StartData(),
    ),
    FlowNode<DemoNodeData>(
      id: 'default_1',
      type: 'default',
      position: Offset(320, 120),
      data: ProcessData(1),
    ),
    FlowNode<DemoNodeData>(
      id: 'output_1',
      type: 'output',
      position: Offset(560, 120),
      data: EndData(),
    ),
  ];

  static const _edges = <FlowEdge>[
    FlowEdge(
      id: 'e1',
      sourceNodeId: 'input_1',
      targetNodeId: 'default_1',
      sourceHandleId: 'source',
      targetHandleId: 'target',
    ),
    FlowEdge(
      id: 'e2',
      sourceNodeId: 'default_1',
      targetNodeId: 'output_1',
      sourceHandleId: 'source',
      targetHandleId: 'target',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = FlowCanvasController();
    // One typed builder shared across kinds, with an exhaustive switch:
    // adding a DemoNodeData variant without handling it is a compile error.
    // (Built-in kinds keep their synthesized handles.)
    _nodeRegistry = NodeRegistry()
      ..registerTyped<DemoNodeData>('input', _demoBuilder)
      ..registerTyped<DemoNodeData>('default', _demoBuilder)
      ..registerTyped<DemoNodeData>('output', _demoBuilder);
  }

  Widget _demoBuilder(NodeProps<DemoNodeData> props) {
    final (label, icon) = switch (props.data) {
      StartData(:final label, :final icon) => (label, icon),
      ProcessData(:final label, :final icon) => (label, icon),
      EndData(:final label, :final icon) => (label, icon),
      null => ('?', Icons.help_outline),
    };
    return BaseNode(
      node: props.node,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lattice example'),
        actions: [
          IconButton(
            tooltip: 'Fit view',
            icon: const Icon(Icons.center_focus_strong),
            onPressed: () => _controller.viewport.fitView(),
          ),
        ],
      ),
      body: FlowCanvas(
        controller: _controller,
        nodeRegistry: _nodeRegistry,
        initialNodes: _nodes,
        initialEdges: _edges,
        callbacks: FlowCanvasCallbacks(
          onNodesChange: (changes) {
            for (final change in changes) {
              if (change is NodePositionChange && change.dragging) {
                debugPrint('${change.id} → ${change.position}');
              }
            }
          },
        ),
        overlays: const [FlowBackground(), FlowCanvasControls()],
      ),
    );
  }
}
