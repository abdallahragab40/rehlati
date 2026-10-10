import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';

import 'engine_test.dart' show correctIndex, makeContainer, wrongIndex;

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 10, 9);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  void days(int n) => now = now.add(Duration(days: n));
  String today() => ProgressData.dayKey(now);

  group('schedule', () {
    test('one perfect round is not mastery', () {
      final p = ProgressData()..recordMastery('counting', 10, 10);
      final r = p.mastery['counting']!;
      expect([r.rounds, r.box, r.due], [1, 1, '2026-10-11']);
      expect(p.masteryOf('counting'), MasteryState.practicing);
      expect(p.masteryOf('addition'), MasteryState.fresh);
    });

    test('reviews space out 1, 3 then 7 days and only the first round of a day counts', () {
      final p = ProgressData()
        ..recordMastery('counting', 10, 10)
        ..recordMastery('counting', 10, 10)
        ..recordMastery('counting', 10, 10);
      expect(p.mastery['counting']!.box, 1, reason: 'same-day repeats do not speed things up');

      days(1);
      expect(p.masteryOf('counting'), MasteryState.review);
      expect(p.dueForReview, ['counting']);
      p.recordMastery('counting', 9, 10);
      expect([p.mastery['counting']!.box, p.mastery['counting']!.due], [2, '2026-10-14']);

      days(2);
      expect(p.masteryOf('counting'), MasteryState.practicing, reason: 'the day before it is due');
      days(1);
      expect(p.masteryOf('counting'), MasteryState.review, reason: 'on the due day');
      p.recordMastery('counting', 8, 10);
      expect([p.mastery['counting']!.box, p.mastery['counting']!.due], [3, '2026-10-21']);
      expect(p.masteryOf('counting'), MasteryState.mastered);
    });

    test('a missed review is not punished and a weak round steps back only one box', () {
      final p = ProgressData();
      for (final gap in [0, 1, 3]) {
        days(gap);
        p.recordMastery('counting', 10, 10);
      }
      expect(p.mastery['counting']!.box, 3);
      days(40);
      expect(p.masteryOf('counting'), MasteryState.review);
      expect(p.mastery['counting']!.box, 3, reason: 'nothing is lost by missing the date');
      p.recordMastery('counting', 4, 10);
      expect(p.mastery['counting']!.box, 2);
      expect(p.mastery['counting']!.due, ProgressData.dayKey(now.add(const Duration(days: 3))));
    });

    test('records survive a JSON round trip', () {
      final p = ProgressData()..recordMastery('counting', 7, 10);
      final back = ProgressData.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      final r = back.mastery['counting']!;
      expect([r.rounds, r.ok, r.tries, r.box, r.recent], [1, 7, 10, 0, [70]]);
    });
  });

  group('difficulty', () {
    test('a parent starting level overrides the age floor', () {
      final p = ProgressData(age: 6);
      expect(p.ageLevel, 3);
      p.settings.startLevel = 1;
      expect(p.ageLevel, 1);
      expect(Settings.fromJson(p.settings.toJson()).startLevel, 1);
    });

    test('two weak rounds start the next round at the easiest level, even for an older child', () async {
      final c = await makeContainer();
      c.read(progressProvider.notifier).update((p) => p.age = 6);
      final engine = c.read(gameProvider.notifier)..start('counting');
      expect(c.read(gameProvider)!.level, 2, reason: 'age 6 normally starts one above the stage base');

      c.read(progressProvider.notifier).update((p) {
        p.recordMastery('counting', 3, 10);
        days(1);
        p.recordMastery('counting', 4, 10);
      });
      expect(c.read(progressProvider).struggling('counting'), isTrue);
      engine.start('counting');
      expect(c.read(gameProvider)!.level, 1);
    });
  });

  test('retries and mistake practice never count as first-try successes', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('counting');
    for (var i = 0; i < 10; i++) {
      final q = c.read(gameProvider)!.q;
      engine
        ..answer(wrongIndex(q))
        ..answer(correctIndex(q));
      await Future<void>.delayed(const Duration(milliseconds: 1450));
    }
    var r = c.read(progressProvider).mastery['counting']!;
    expect([r.rounds, r.ok, r.tries], [1, 0, 10]);

    engine.trainMistakes();
    for (var i = 0; i < c.read(gameProvider)!.total; i++) {
      engine.answer(correctIndex(c.read(gameProvider)!.q));
      await Future<void>.delayed(const Duration(milliseconds: 1450));
    }
    r = c.read(progressProvider).mastery['counting']!;
    expect(r.rounds, 1, reason: 'practice rounds are retries');
  }, timeout: const Timeout(Duration(seconds: 60)));

  test('version 1 progress migrates: played stages are known, nothing is claimed as mastered', () {
    final (:data, :newer) = ProgressRepository.decode(jsonEncode({
      'schemaVersion': 1,
      'best': {'counting': 3, 'addition': 1},
      'stars': 12,
    }));
    expect(newer, isFalse);
    expect(data.stars, 12);
    expect(data.mastery.keys.toSet(), {'counting', 'addition'});
    expect(data.masteryOf('counting'), MasteryState.practicing);
    expect(data.mastery['counting']!.box, 0);
    expect(data.dueForReview, isEmpty);
    expect(data.toJson()['schemaVersion'], 2);
  });

  test('a stage due for review leads the journey', () {
    final p = ProgressData(unlocked: ['counting', 'chooseNumber', 'addition'], best: {'counting': 3, 'chooseNumber': 2})
      ..recordMastery('chooseNumber', 9, 10);
    days(1);
    final j = planJourney(p, day: today());
    expect(j.steps.first.kind, StepKind.review);
    expect(j.steps.first.target, 'stage:chooseNumber');
  });
}
