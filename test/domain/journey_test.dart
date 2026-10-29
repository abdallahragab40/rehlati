import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';

import 'engine_test.dart' show correctIndex, makeContainer;

const day = '2026-10-10';

List<String> targets(Journey j) => [for (final s in j.steps) s.target];
List<StepKind> kinds(Journey j) => [for (final s in j.steps) s.kind];

/// طفل لعب شوية: العد كويس، الجمع فيه أخطاء، وفيه مراحل مفتوحة ما اتلعبتش.
ProgressData returning() => ProgressData(
      unlocked: ['counting', 'chooseNumber', 'addition', 'ar_learn', 'en_learn'],
      best: {'counting': 3, 'chooseNumber': 2, 'addition': 1},
      skills: {'addition|add:3+4': 4},
    );

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 10, 9);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  group('planning', () {
    test('a new child starts with the first stage and something new from another world', () {
      final j = planJourney(ProgressData(), day: day);
      expect(kinds(j), [StepKind.start, StepKind.fresh]);
      expect(j.steps.first.target, 'stage:counting');
      expect(j.steps.last.world, isNot('math'));
      expect(j.steps.every((s) => s.stage != null && !s.stage!.isLearn), isTrue);
    });

    test('a new primary child starts at their grade, not at counting', () {
      final ten = planJourney(ProgressData(age: 10), day: day);
      expect(targets(ten), ['stage:divisionExact', 'stage:ar_wordType'], reason: 'fourth-primary maths, then Arabic');
      final seven = planJourney(ProgressData(age: 7), day: day);
      expect(seven.steps.first.target, 'stage:tensOnes');
      expect(seven.steps.last.target, 'stage:ar_tanween');
      final parentPicked = planJourney(ProgressData(age: 10, grade: 'kg2'), day: day);
      expect(parentPicked.steps.first.target, 'stage:counting', reason: 'the parent\'s grade wins');
      expect(planJourney(ProgressData(age: 4), day: day).steps.first.target, 'stage:counting');
    });

    test('the parent report suggests a new stage at the child\'s grade', () {
      List<String> fresh(ProgressData p) =>
          [for (final s in practiceSuggestions(p)) if (s.kind == StepKind.fresh) s.target];
      expect(fresh(ProgressData(age: 10)), ['stage:divisionExact']);
      expect(fresh(ProgressData(age: 4)), ['stage:counting']);
    });

    test('a returning child gets a warm-up, the weak stage, then an unplayed stage', () {
      final j = planJourney(returning(), day: day);
      expect(kinds(j), [StepKind.warm, StepKind.practice, StepKind.fresh]);
      expect(['stage:counting', 'stage:chooseNumber'], contains(j.steps[0].target));
      expect(j.steps[1].target, 'stage:addition');
      final fresh = j.steps[2].stage!;
      expect(returning().best[fresh.id], isNull);
      expect(returning().isUnlocked(fresh.id), isTrue);
    });

    test('only unlocked stages are suggested, and the same day plans the same journey', () {
      final p = returning();
      final j = planJourney(p, day: day);
      expect(j.steps.every((s) => p.isUnlocked(s.stage!.id)), isTrue);
      expect(targets(planJourney(p, day: day)), targets(j));
      expect(targets(Journey.fromJson(j.toJson())), targets(j));
    });

    test('a surah due for review joins only when its text is on the device', () {
      final p = returning()..quran['112:memorize'] = 3;
      expect(targets(planJourney(p, day: day, quranReady: {112})).last, 'quran:112:review');
      expect(targets(planJourney(p, day: day)), isNot(contains('quran:112:review')), reason: 'not downloaded');
      p.settings.journeyOff.add('quran');
      expect(targets(planJourney(p, day: day, quranReady: {112})), isNot(contains('quran:112:review')));
    });

    test('worlds the parent turned off are left out', () {
      final p = returning()..settings.journeyOff.addAll(['math', 'games']);
      final j = planJourney(p, day: day);
      expect(j.steps.where((s) => s.world == 'math' || s.world == 'games'), isEmpty);
    });

    test('little time left keeps the journey short and keeps the practice step', () {
      expect(kinds(planJourney(returning(), day: day, minutesLeft: 5)), [StepKind.practice]);
      expect(planJourney(returning(), day: day, minutesLeft: 9).steps, hasLength(2));
      expect(planJourney(returning(), day: day, minutesLeft: 60).steps, hasLength(3));
    });
  });

  group('progress', () {
    Journey threeSteps() => Journey(ProgressData.dayKey(now), [
          JourneyStep(StepKind.warm, 'stage:counting'),
          JourneyStep(StepKind.practice, 'stage:addition'),
          JourneyStep(StepKind.quran, 'quran:112:review'),
        ]);

    test('steps complete once and the bonus is given once', () {
      final p = ProgressData()..journey = threeSteps();
      expect(p.journeyMark('stage:counting'), isFalse);
      expect(p.journeyMark('stage:counting'), isFalse);
      expect(p.journeyMark('stage:somethingElse'), isFalse);
      expect(p.journeyMark('stage:addition'), isFalse);
      expect(p.stars, 0);
      expect(p.journeyMark('quran:112:review'), isTrue);
      expect(p.stars, Journey.bonusStars);
      expect(p.starsIn('quran'), Journey.bonusStars, reason: 'world totals still add up');
      expect(p.journeyMark('quran:112:review'), isFalse);
      expect(p.stars, Journey.bonusStars);
      expect(p.todayJourney!.complete, isTrue);
    });

    test("yesterday's journey is not today's and cannot be marked", () {
      final p = ProgressData()..journey = threeSteps();
      now = now.add(const Duration(days: 1));
      expect(p.todayJourney, isNull);
      expect(p.journeyMark('stage:counting'), isFalse);
    });

    test('finishing a round in the game marks its step, and siblings keep their own journey', () async {
      final c = await makeContainer();
      final n = c.read(progressProvider.notifier)..update((p) => p.journey = threeSteps());
      final engine = c.read(gameProvider.notifier)..start('counting');
      for (var i = 0; i < 10; i++) {
        engine.answer(correctIndex(c.read(gameProvider)!.q));
        await Future<void>.delayed(const Duration(milliseconds: 1450));
      }
      expect(c.read(gameProvider)!.result, isNotNull);
      expect(c.read(progressProvider).todayJourney!.steps.first.done, isTrue);

      await n.addChild();
      expect(c.read(progressProvider).todayJourney, isNull);
      await n.switchTo(ProgressRepository.mainId);
      expect(c.read(progressProvider).todayJourney!.doneCount, 1);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
