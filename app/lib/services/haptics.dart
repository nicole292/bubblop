import 'package:flutter/services.dart';

import 'settings.dart';

/// Vibration feedback on phones (does nothing on desktop). Strength follows
/// the size of the moment: light for a landing, heavy for a big chain.
class Haptics {
  Haptics(this._settings);

  final Settings _settings;

  void land() => _run(HapticFeedback.selectionClick);
  void pop(int step) => _run(step >= 3
      ? HapticFeedback.heavyImpact
      : step == 2
          ? HapticFeedback.mediumImpact
          : HapticFeedback.lightImpact);
  void deny() => _run(HapticFeedback.mediumImpact);
  void tap() => _run(HapticFeedback.selectionClick);
  void big() => _run(HapticFeedback.heavyImpact);

  void _run(Future<void> Function() feedback) {
    if (_settings.haptics) feedback();
  }
}
