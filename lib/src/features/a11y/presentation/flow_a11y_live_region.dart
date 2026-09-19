import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lattice/src/core/providers/providers.dart';

/// Invisible assertive live region announcing canvas events to screen
/// readers (≈ Lattice `aria-live="assertive"` announcements).
///
/// Renders the latest [A11yAnnouncer] message as transparent text; assistive
/// tech announces it on change. Mounted once per canvas by
/// [_FlowCanvasCore]; silent when empty or when
/// `A11yOptions.announcements` is off.
class FlowA11yLiveRegion extends ConsumerWidget {
  const FlowA11yLiveRegion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(
      flowOptionsProvider.select((o) => o.a11yOptions.announcements),
    );
    if (!enabled) return const SizedBox.shrink();
    final announcer =
        ref.read(internalControllerProvider.notifier).a11yAnnouncer;
    return ListenableBuilder(
      listenable: announcer,
      builder: (context, _) {
        final message = announcer.message;
        if (message.isEmpty) return const SizedBox.shrink();
        return Opacity(
          opacity: 0,
          child: Semantics(
            liveRegion: true,
            child: Text(
              message,
              key: ValueKey('a11y-live-${announcer.sequence}'),
            ),
          ),
        );
      },
    );
  }
}
