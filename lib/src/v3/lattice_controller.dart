import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'lattice_document.dart';
import 'lattice_edge.dart';
import 'lattice_node.dart';
import 'lattice_options.dart';
import 'lattice_viewport_value.dart';
import 'session_providers.dart';

/// User-owned controller for a lattice canvas session.
///
/// Creates its own [ProviderContainer] at construction, so graph verbs are
/// legal before any canvas mounts. The owning widget (or user code) must call
/// [dispose]; disposing twice is a no-op and never throws.
class LatticeController extends ChangeNotifier {
  LatticeController({
    List<LatticeNode> initialNodes = const [],
    List<LatticeEdge> initialEdges = const [],
    LatticeOptions options = const LatticeOptions(),
  })  : _options = options,
        _container = ProviderContainer() {
    _container.read(latticeDocumentProvider.notifier).replace(
          LatticeDocument(
            nodes: <String, LatticeNode>{
              for (final LatticeNode node in initialNodes) node.id: node,
            },
            edges: <String, LatticeEdge>{
              for (final LatticeEdge edge in initialEdges) edge.id: edge,
            },
            viewport:
                options.defaultViewport ?? const LatticeViewportValue(),
          ),
        );
  }

  final ProviderContainer _container;
  LatticeOptions _options;
  bool _attached = false;
  bool _disposed = false;

  /// The session container owned by this controller.
  ProviderContainer get container => _container;

  /// The current session document.
  LatticeDocument get document =>
      _container.read(latticeDocumentProvider);

  /// Canvas options, read at build time. Setting this never notifies.
  LatticeOptions get options => _options;
  set options(LatticeOptions value) {
    _options = value;
  }

  /// Whether a [LatticeCanvas] is currently mounted on this controller.
  bool get isAttached => _attached;

  /// Replaces the document's nodes, keeping edges and viewport.
  /// Notifies listeners exactly once.
  void setNodes(Iterable<LatticeNode> nodes) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _container.read(latticeDocumentProvider.notifier).replace(
          current.copyWith(
            nodes: <String, LatticeNode>{
              for (final LatticeNode node in nodes) node.id: node,
            },
          ),
        );
    notifyListeners();
  }

  /// Replaces the document's edges, keeping nodes and viewport.
  /// Notifies listeners exactly once.
  void setEdges(Iterable<LatticeEdge> edges) {
    final LatticeDocument current =
        _container.read(latticeDocumentProvider);
    _container.read(latticeDocumentProvider.notifier).replace(
          current.copyWith(
            edges: <String, LatticeEdge>{
              for (final LatticeEdge edge in edges) edge.id: edge,
            },
          ),
        );
    notifyListeners();
  }

  /// Replaces the whole document and clears the selection.
  /// Notifies listeners exactly once.
  void load(LatticeDocument document) {
    _container.read(latticeDocumentProvider.notifier).replace(document);
    _container.read(latticeSelectionProvider.notifier).clear();
    notifyListeners();
  }

  /// Marks the controller as mounted. Canvas use only.
  @internal
  void attach() {
    if (_attached) return;
    _attached = true;
    notifyListeners();
  }

  /// Marks the controller as unmounted. Canvas use only.
  @internal
  void detach() {
    if (!_attached) return;
    _attached = false;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _container.dispose();
    super.dispose();
  }
}
