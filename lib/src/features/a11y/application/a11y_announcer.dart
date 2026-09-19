import 'package:flutter/foundation.dart';

/// Per-canvas screen-reader announcement bus.
///
/// Controllers post polite live-region messages here (keyboard moves,
/// deletions); [FlowA11yLiveRegion] renders the latest message into an
/// `assertive` live region. Owned by [FlowCanvasInternalController] —
/// one bus per canvas, disposed with it.
///
/// Zero cost when unread: plain [ChangeNotifier], no state writes, no
/// history entries.
class A11yAnnouncer extends ChangeNotifier {
  String _message = '';
  int _sequence = 0;

  /// Latest announcement text (empty before the first announcement).
  String get message => _message;

  /// Bumps on every [announce], even for repeated text.
  int get sequence => _sequence;

  /// Posts [message] to the live region (no-op for empty text).
  void announce(String message) {
    if (message.isEmpty) return;
    _message = message;
    _sequence++;
    notifyListeners();
  }
}
