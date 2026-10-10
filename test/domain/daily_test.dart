import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/progress/ranks.dart';
import 'package:rehlati/features/daily/week_card.dart';

import 'engine_test.dart' show makeContainer;

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 5, 10);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  void nextDay() => now = now.add(const Duration(days: 1));

  group('daily log and streak', () {
    test('activity is logged under the local day', () {
      final p = ProgressData()
        ..addStar(3, 'math')
        ..addAnswer(ok: false)
        ..addResult('counting', 8, 10)
        ..addTime(120000);
      final d = p.days['2026-10-05']!;
      expect((d.stars, d.wrong, d.games, d.ms), (3, 1, 1, 120000));
      expect(p.todayMin, 2);
    });

    test('streak counts back from today, or from yesterday before playing today', () {
      final p = ProgressData()..addStar(1);
      nextDay();
      p.addStar(1);
      nextDay();
      p.addStar(1);
      expect(p.streak, 3);
      nextDay(); // لسه ملعبش النهاردة — السلسلة ماتضيعش
      expect(p.streak, 3);
      nextDay(); // فات يوم من غير لعب
      expect(p.streak, 0);
    });

    test('the daily goal celebrates once', () {
      final p = ProgressData()..settings.goal = 5;
      p.addStar(4);
      expect(p.celebrateGoal(), isFalse);
      p.addStar(1);
      expect(p.goalPct, 100);
      expect(p.celebrateGoal(), isTrue);
      expect(p.celebrateGoal(), isFalse, reason: 'once per day');
      nextDay();
      p.addStar(5);
      expect(p.celebrateGoal(), isTrue, reason: 'new day, new goal');
    });

    test('play-time limit', () {
      final p = ProgressData();
      expect(p.limitLeft, isNull);
      p.settings.limitMin = 10;
      p.addTime(4 * 60000);
      expect(p.limitLeft, 6);
      expect(p.limitReached, isFalse);
      p.addTime(6 * 60000);
      expect(p.limitReached, isTrue);
      nextDay();
      expect(p.limitReached, isFalse);
    });

    test('week sums and comparison notes', () {
      final p = ProgressData();
      // الأسبوع اللي فات: يومين و٢٠ إجابة — كفاية للمقارنة
      for (var i = 0; i < 2; i++) {
        p.addStar(1);
        for (var k = 0; k < 10; k++) {
          p.addAnswer(ok: true);
        }
        nextDay();
      }
      now = now.add(const Duration(days: 5));
      for (var i = 0; i < 5; i++) {
        p
          ..addStar(2)
          ..addResult('counting', 10, 10);
        nextDay();
      }
      final w = p.weekSum();
      expect((w.stars, w.games, w.days), (10, 5, 5));
      expect(p.week().length, 7);
      final (up, need) = weekNotes(p);
      expect(up.first, contains('النجوم زادت'));
      expect(need.where((n) => n.contains('المواظبة')), isEmpty, reason: '5 active days');
    });

    test('no comparison without enough history last week', () {
      final p = ProgressData()
        ..addStar(4)
        ..addAnswer(ok: true);
      final (up, need) = weekNotes(p);
      expect(up, [contains('مفيش تدريب كفاية')]);
      expect(need, [contains('المواظبة')]);
    });

    test('old days are pruned to 70, and web blobs load', () {
      final p = ProgressData.fromJson({
        'days': {
          for (var i = 1; i <= 80; i++) ProgressData.dayKey(DateTime(2026, 1, i)): {'stars': i, 'done': 1},
        },
        'settings': {'speech': true, 'sfx': true, 'dev': false},
      })
        ..pruneDays();
      expect(p.days.length, 70);
      expect(p.settings.music, isTrue, reason: 'new setting defaults on for old users');
      expect(p.settings.goal, 20);
      expect(p.days.values.last.done, isTrue);
      final back = ProgressData.fromJson(p.toJson());
      expect(back.days.length, 70);
    });
  });

  group('ranks', () {
    test('thresholds and progress to the next cup', () {
      expect(rankOf(0).id, 'egg');
      expect(rankOf(49).id, 'egg');
      expect(rankOf(50).id, 'bronze');
      expect(rankPct(100), 50);
      expect(starsToNext(100), 50);
      expect(nextRank(1500), isNull);
      expect(rankPct(2000), 100);
    });

    test('first check records silently, later upgrades celebrate once', () {
      final p = ProgressData(stars: 60);
      expect(rankCheck(p), isNull, reason: 'existing progress: no celebration');
      p.addStar(100);
      expect(rankCheck(p)?.id, 'silver');
      expect(rankCheck(p), isNull);
    });
  });

  test('the empty table round has 3 questions', () async {
    final c = await makeContainer();
    c.read(gameProvider.notifier).start('emptyTable');
    expect(c.read(gameProvider)!.total, 3);
    expect(c.read(progressProvider).settings.goal, 20);
  });
}
