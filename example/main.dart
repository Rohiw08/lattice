import 'package:flutter/material.dart';
import 'package:lattice/lattice.dart';

void main() => runApp(const LatticeExampleApp());

/// Minimal `lattice` example: three nodes connected by two edges.
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

  static const _nodes = <FlowNode<Object>>[
    FlowNode<String>(
      id: 'input_1',
      type: 'input',
      position: Offset(80, 120),
      data: 'Start',
    ),
    FlowNode<String>(
      id: 'default_1',
      type: 'default',
      position: Offset(320, 120),
      data: 'Process',
    ),
    FlowNode<String>(
      id: 'output_1',
      type: 'output',
      position: Offset(560, 120),
      data: 'End',
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
        initialNodes: _nodes,
        initialEdges: _edges,
        overlays: const [FlowBackground(), FlowCanvasControls()],
      ),
    );
  }
}
