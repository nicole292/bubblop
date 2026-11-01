import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_pop/services/settings.dart';
import 'package:project_pop/ui/theme_switch.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults: sound and vibration on, no best, tutorial not done', () {
    final s = Settings.memory();
    expect(s.sound, isTrue);
    expect(s.music, isTrue);
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

  test('recordRound keeps the highest level reached', () {
    final s = Settings.memory();
    expect(s.bestLevel, 0);
    s.recordRound(50, level: 3);
    expect(s.bestLevel, 3);
    s.recordRound(500, level: 2);
    expect(s.bestLevel, 3, reason: 'a lower level never lowers it');
    s.recordRound(10, level: 5);
    expect(s.bestLevel, 5);
    expect(s.best, 500);
  });

  test('changes notify listeners', () {
    final s = Settings.memory();
    var calls = 0;
    s.addListener(() => calls++);
    s.sound = false;
    s.music = false;
    s.haptics = false;
    s.tutorialDone = true;
    expect(calls, 4);
    expect(s.music, isFalse);
    expect(s.sound, isFalse);
  });

  test('theme starts on Auto, which follows the phone', () {
    expect(Settings.memory().theme, ThemeChoice.auto);
    expect(ThemeSwitch.isDark(ThemeChoice.auto, Brightness.dark), isTrue);
    expect(ThemeSwitch.isDark(ThemeChoice.auto, Brightness.light), isFalse);
    expect(ThemeSwitch.isDark(ThemeChoice.dark, Brightness.light), isTrue);
    expect(ThemeSwitch.isDark(ThemeChoice.light, Brightness.dark), isFalse);
  });

  test('the theme choice is saved', () async {
    SharedPreferences.setMockInitialValues({});
    (await Settings.load()).theme = ThemeChoice.dark;
    expect((await Settings.load()).theme, ThemeChoice.dark);
  });
}
