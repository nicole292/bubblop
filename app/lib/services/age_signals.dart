import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Google Play Age Signals, Android only (android/.../MainActivity.kt).
///
/// Called once per launch. Where Play says mandatory age sharing applies,
/// the Android side requests the age signal and then checks it; elsewhere
/// it does nothing. The age is never stored, sent or used: the game is the
/// same for everyone. Never throws and never holds up the game.
abstract final class AgeSignals {
  static const _channel = MethodChannel('com.bubblop.game/age_signals');
  static bool _asked = false;

  static Future<void> checkOnce() async {
    if (_asked || kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    _asked = true;
    try {
      final status = await _channel.invokeMethod<String>('check');
      debugPrint('Age signals: $status');
    } catch (e) {
      debugPrint('Age signals unavailable: $e');
    }
  }
}
