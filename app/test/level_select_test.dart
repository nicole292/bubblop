import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pop_core/pop_core.dart';
import 'package:project_pop/progress/progress.dart';
import 'package:project_pop/ui/level_select_screen.dart';

void main() {
  testWidgets('shows completed, current and locked levels; locked ones refuse taps', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = Progress.memory();
    for (var level = 1; level <= 3; level++) {
      progress.completeLevel(level, score: 100);
    }
    final semantics = tester.ensureSemantics();
    var denied = 0;
    LevelDef? played;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelSelectScreen(
          progress: progress,
          onBack: () {},
          onPlay: (level) => played = level,
          onTap: () {},
          onDeny: () => denied++,
        ),
      ),
    ));
    await tester.pump();

    expect(find.bySemanticsLabel('Level 1, completed'), findsOneWidget);
    expect(find.bySemanticsLabel('Level 4'), findsOneWidget, reason: 'the next level is open');
    expect(find.bySemanticsLabel('Level 5, locked'), findsOneWidget);
    expect(find.text('3 of 30 complete'), findsOneWidget);

    // A locked level does not open, and says why.
    await tester.tap(find.bySemanticsLabel('Level 5, locked'));
    await tester.pump();
    expect(denied, 1);
    expect(find.text('Play'), findsNothing);
    expect(find.text('Complete level 4 to unlock the next one!'), findsOneWidget);

    // The open level shows its goal card, then starts.
    await tester.tap(find.bySemanticsLabel('Level 4'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(Campaign.level(4).goals.single.text), findsOneWidget);
    await tester.tap(find.text('Play'));
    expect(played?.number, 4);

    semantics.dispose();
  });

  testWidgets('a completed level offers to play again and shows its best', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final progress = Progress.memory()..completeLevel(1, score: 345);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelSelectScreen(
          progress: progress,
          openLevel: 1,
          onBack: () {},
          onPlay: (_) {},
          onTap: () {},
          onDeny: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Play again'), findsOneWidget);
    expect(find.text('Best 345'), findsOneWidget);
  });

  testWidgets('back closes an open goal card before leaving the map', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final key = GlobalKey<LevelSelectScreenState>();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: LevelSelectScreen(
          key: key,
          progress: Progress.memory(),
          openLevel: 1,
          onBack: () {},
          onPlay: (_) {},
          onTap: () {},
          onDeny: () {},
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Play'), findsOneWidget);
    expect(key.currentState!.closeIntro(), isTrue);
    await tester.pump();
    expect(find.text('Play'), findsNothing);
    expect(key.currentState!.closeIntro(), isFalse, reason: 'nothing left to close');
  });
}
