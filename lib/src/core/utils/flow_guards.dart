import 'package:lattice/src/features/edges/domain/model/edge.dart';
import 'package:lattice/src/features/nodes/domain/models/node.dart';

/// Type guards (Lattice `isEdge` / `isNode`).
///
/// Dart's `is` operator covers this natively; these exist so ported code
/// and mixed `List<Object>` graphs read the same as the RF originals.

/// Whether [element] is a [FlowEdge].
bool isEdge(Object? element) => element is FlowEdge;

/// Whether [element] is a [FlowNode].
bool isNode(Object? element) => element is FlowNode<dynamic>;
