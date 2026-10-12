import 'dart:async';

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'session_providers.dart';

/// Announces lattice session events to assistive technologies.
///
/// Watches the selection count and the document edge count and posts a
/// polite announcement via [SemanticsService.sendAnnouncement] whenever
/// either changes after mount:
/// - selection count change → `"<N> nodes selected"` / `"Selection cleared"`;
/// - edge count increase → `"Edge created"`.
///
/// Renders nothing visible ([SizedBox.shrink]).
///
/// NOTE: the brief names this as a `ConsumerWidget`, but previous-change
/// tracking needs state, so this is a [ConsumerStatefulWidget] with the
/// identical public constructor (`const LatticeLiveRegion({super.key})`).
/// Change detection uses [Ref.listen] (no announcement on mount).
class LatticeLiveRegion extends ConsumerStatefulWidget {
  const LatticeLiveRegion({super.key});

  /// Test hook: the last message passed to [_announce], or `null` when
  /// nothing has been announced yet. Reset per test; never read in
  /// production code.
  @visibleForTesting
  static String? lastAnnouncedForTest;

  @override
  ConsumerState<LatticeLiveRegion> createState() => _LatticeLiveRegionState();
}

class _LatticeLiveRegionState extends ConsumerState<LatticeLiveRegion> {
  void _announce(String message) {
    LatticeLiveRegion.lastAnnouncedForTest = message;
    // Fire-and-forget: announcement delivery must not block the frame.
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        message,
        TextDirection.ltr,
        assertiveness: Assertiveness.polite,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      latticeSelectionProvider.select((selection) => selection.nodes.length),
      (int? previous, int next) {
        if (previous == null || previous == next) return;
        if (next == 0) {
          _announce('Selection cleared');
        } else {
          _announce('$next nodes selected');
        }
      },
    );
    ref.listen<int>(
      latticeDocumentProvider.select((document) => document.edges.length),
      (int? previous, int next) {
        if (previous == null || previous == next) return;
        if (next > previous) _announce('Edge created');
      },
    );
    return const SizedBox.shrink();
  }
}
