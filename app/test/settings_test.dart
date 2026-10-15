import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/services/settings.dart';

void main() {
  test('defaults: sound and vibration on, no best, tutorial not done', () {
    final s = Settings.memory();
    expect(s.sound, isTrue);
    expect(s.haptics, isTrue);
    expect(s.best, 0);
    expect(s.tutorialDone, isFalse);
  });

  test('recordRound reports a new best only when the score beats it', () {
    final s = Settings.memory();
    expect(s.recordRound(120), isTrue);
    expect(s.best, 120);
    expect(s.recordRound(80), isFalse);
    expect(s.recordRound(120), isFalse, reason: 'a tie is not a new best');
    expect(s.best, 120);
    expect(s.gamesPlayed, 3);
  });

  test('changes notify listeners', () {
    final s = Settings.memory();
    var calls = 0;
    s.addListener(() => calls++);
    s.sound = false;
    s.haptics = false;
    s.tutorialDone = true;
    expect(calls, 3);
    expect(s.sound, isFalse);
  });
}
