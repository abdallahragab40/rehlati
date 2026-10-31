import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/school.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/world_map/world_map_screen.dart';

import '../features/parent_flow_test.dart' show pumpApp;
import 'engine_test.dart' show makeContainer;

/// الألعاب حسب السن المعتاد للمرحلة: كل لعبة ليها سن، والخريطة والرحلة والمستوى بيمشوا عليه.
void main() {
  test('every stage in an open world has an age range inside 3–12, and nothing else has one', () {
    for (final s in packs.values) {
      if (!openWorlds.contains(s.world)) {
        expect(s.ages, isNull, reason: s.id);
        continue;
      }
      final a = s.ages;
      expect(a, isNotNull, reason: '${s.id} has no age range');
      expect(a!.$1 <= a.$2 && a.$1 >= 3 && a.$2 <= 12, isTrue, reason: s.id);
    }
    // كل سن في القايمة لمرحلة ألعاب موجودة (أو مستنية الصوت)
    for (final k in gameAges.keys) {
      expect(openWorlds.contains(packs[k]?.world) || k == 'listenNum' || k == 'animalSound', isTrue, reason: k);
    }
  });

  test('every grade has a good handful of games, and older children get the puzzles', () {
    for (final grade in schoolGrades) {
      final fit = worldStages['games']!.where((s) => fitsGrade(s, grade)).toList();
      expect(fit.length, greaterThanOrEqualTo(6), reason: grade);
    }
    final ten = [for (final s in worldStages['games']!) if (fitsAge(s, 10)) s.id];
    expect(ten, containsAll(['sudoku', 'hanoi', 'slide', 'numberSeq', 'maze']));
    expect(ten, isNot(contains('shadow')));
    expect(fitsAge(packs['shadow']!, null), isTrue, reason: 'no age = everything');
  });

  test('the journey only picks games that suit the child\'s grade', () {
    for (final grade in schoolGrades) {
      for (var d = 1; d <= 28; d++) {
        final j = planJourney(ProgressData(grade: grade), day: '2026-11-${d.toString().padLeft(2, '0')}');
        for (final s in j.steps) {
          if (s.stage case final st? when st.world == 'games') expect(fitsGrade(st, grade), isTrue, reason: '${st.id} at $grade');
        }
      }
    }
  });

  test('games get harder with the grade', () async {
    expect([for (final g in ['kg1', 'kg2', 'p1', 'p2', 'p3', 'p4', 'p6']) ProgressData(grade: g).gamesLevel], [1, 2, 2, 3, 3, 4, 4]);
    expect(ProgressData().gamesLevel, 2, reason: 'no grade keeps the old level');
    final c = await makeContainer();
    c.read(progressProvider.notifier).update((p) => p.grade = 'p5');
    c.read(gameProvider.notifier).start('maze');
    expect(c.read(gameProvider)!.q.mazeSize, 6);
    c.read(progressProvider.notifier).update((p) => p.grade = 'kg1');
    c.read(gameProvider.notifier).start('maze');
    expect(c.read(gameProvider)!.q.mazeSize, 4);
  });

  testWidgets('the games map shows the games for the child\'s grade first, the rest behind a button', (tester) async {
    tester.view.physicalSize = const Size(1200, 9000);
    addTearDown(tester.view.reset);
    Future<void> frames() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpApp(tester, home: const WorldMapScreen(world: 'games'), settle: false);
    ProviderScope.containerOf(tester.element(find.byType(WorldMapScreen)))
        .read(progressProvider.notifier)
        .update((p) => p.grade = 'p5');
    await frames();
    expect(find.text('🎯 على قد خامسة ابتدائي'), findsOneWidget);
    expect(find.text('سودوكو'), findsOneWidget);
    expect(find.text('ظل الصورة'), findsNothing);

    await tester.tap(find.textContaining('ألعاب تانية'));
    await frames();
    expect(find.text('ظل الصورة'), findsOneWidget);
  });

  testWidgets('subject maps show the child\'s grade and below, higher grades behind a button', (tester) async {
    tester.view.physicalSize = const Size(1200, 30000);
    addTearDown(tester.view.reset);
    Future<void> frames() async {
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpApp(tester, home: const WorldMapScreen(world: 'math'), settle: false);
    final c = ProviderScope.containerOf(tester.element(find.byType(WorldMapScreen)));
    c.read(progressProvider.notifier).update((p) => p.grade = 'kg1');
    await frames();
    expect(find.text('العد'), findsOneWidget);
    expect(find.text('حساب أولى ابتدائي'), findsNothing);
    expect(find.text('حساب سادسة ابتدائي'), findsNothing);
    expect(find.textContaining('📚 مراحل الصفوف الأعلى ('), findsOneWidget);

    c.read(progressProvider.notifier).update((p) => p.grade = 'p6');
    await frames();
    expect(find.text('حساب سادسة ابتدائي'), findsOneWidget);
    expect(find.textContaining('مراحل الصفوف الأعلى'), findsNothing, reason: 'nothing is above sixth primary');

    // طفل KG1 وصل بالترتيب لمرحلة أعلى: بتفضل ظاهرة
    c.read(progressProvider.notifier).update((p) => p
      ..grade = 'kg1'
      ..unlocked.add('position'));
    await frames();
    expect(find.text('من اليمين ومن الشمال'), findsOneWidget);
    await tester.tap(find.textContaining('📚 مراحل الصفوف الأعلى ('));
    await frames();
    expect(find.text('حساب سادسة ابتدائي'), findsOneWidget);
  });
}
