import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/domain/progress/badges.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  group('arabic utils', () {
    test('ar() converts digits', () => expect(ar('12 / 20'), '١٢ / ٢٠'));
    test('arNum speaks Egyptian numbers', () {
      expect(arNum(2), 'اتنين');
      expect(arNum(13), 'تلاتاشر');
      expect(arNum(20), 'عشرين');
      expect(arNum(23), 'تلاتة وعشرين');
      expect(arNum(40), 'أربعين');
      expect(arNum(100), 'مية');
    });
    test('countOf agrees the noun with the number', () {
      expect([for (final n in [1, 2, 3, 10, 11, 24, 30, 100, 103, 124]) countOf(n, ayahWord)],
          ['آية واحدة', 'آيتين', '٣ آيات', '١٠ آيات', '١١ آية', '٢٤ آية', '٣٠ آية', '١٠٠ آية', '١٠٣ آيات', '١٢٤ آية']);
      expect([countOf(0, starWord), countOf(5, starWord), countOf(9, surahWord)], ['٠ نجمة', '٥ نجوم', '٩ سور']);
    });
  });

  group('progress', () {
    test('starts with the three initial stages unlocked', () {
      final p = ProgressData();
      expect(p.isUnlocked('counting'), isTrue);
      expect(p.isUnlocked('chooseNumber'), isFalse);
      expect(p.level('math'), 1);
    });

    test('unlockNext opens the following stage once', () {
      final p = ProgressData();
      expect(p.unlockNext('counting')?.id, 'chooseNumber');
      expect(p.unlockNext('counting'), isNull);
      expect(p.unlockNext('subtraction')?.id, 'ordinals'); // بعدها أساسيات الأعداد
      expect(p.unlockNext('wordProblem')?.id, 'tensOnes'); // وبعدها الأعداد لحد ١٠٠
      expect(p.unlockNext('sub100')?.id, 'mulGroups'); // بعدها جدول الضرب
      expect(p.unlockNext('timesAll')?.id, 'moneyCount'); // بعدها الفلوس والساعة
      expect(p.unlockNext('clockQuarter')?.id, 'divisionExact');
      expect(p.unlockNext(worldStages['math']!.last.id), isNull); // آخر مرحلة
    });

    test('a parent skip opens the next stage and keeps the skipped one playable', () {
      final p = ProgressData();
      expect([p.canSkip('counting'), p.canSkip('chooseNumber'), p.canSkip('balloons')], [true, false, false],
          reason: 'only an open stage outside the games world, with something locked after it');
      p.skipStage('counting');
      expect([p.skipped, p.isUnlocked('counting'), p.isUnlocked('chooseNumber')], [['counting'], true, true]);
      expect(p.canSkip('counting'), isFalse, reason: 'skipped once');
      expect(p.canSkip('chooseNumber'), isTrue, reason: 'the parent can keep going');

      final passed = ProgressData()..addResult('counting', 9, 10)..unlockNext('counting');
      expect(passed.canSkip('counting'), isFalse, reason: 'nothing left to open');
      final last = worldStages['math']!.last.id;
      expect(ProgressData(unlocked: [last]).canSkip(last), isFalse, reason: 'last stage');
      expect((ProgressData()..settings.dev = true).canSkip('counting'), isFalse, reason: 'everything is open');
    });

    test('skipping a stage opens stages that come "after" it', () {
      final p = ProgressData(unlocked: ['ar_table']);
      expect(p.isUnlocked('madd_alif'), isFalse);
      p.skipStage('ar_table');
      expect([p.isUnlocked('ar_build'), p.isUnlocked('madd_alif')], [true, true]);
    });

    test('skipped stages survive saving', () {
      final p = ProgressData()..skipStage('counting');
      final back = ProgressData.fromJson(p.toJson());
      expect([back.skipped, back.isUnlocked('chooseNumber')], [['counting'], true]);
      expect(ProgressData.fromJson({'name': 'x'}).skipped, isEmpty, reason: 'older saves have no skips');
    });

    test('medals: 10/10 → 3, 8/10 → 2, less → 1, and best is kept', () {
      final p = ProgressData()..addResult('counting', 8, 10);
      expect(p.best['counting'], 2);
      p.addResult('counting', 10, 10);
      expect(p.best['counting'], 3);
      p.addResult('counting', 3, 10);
      expect(p.best['counting'], 3);
      expect(p.games, 3);
    });

    test('stars are tracked per world', () {
      final p = ProgressData()
        ..addStar(1, 'math')
        ..addStar(2, 'arabic');
      expect(p.stars, 3);
      expect(p.starsIn('math'), 1);
    });

    test('quran activity gives its stars only once', () {
      final p = ProgressData()
        ..quranMark(114, 'memorize', 3)
        ..quranMark(114, 'memorize', 3);
      expect(p.starsIn('quran'), 3);
      expect(p.surahsNeedingReview, [114]);
      p.quranMark(114, 'review', 2);
      expect(p.surahsNeedingReview, isEmpty);
    });

    test('json round trip keeps everything', () {
      final p = ProgressData(name: 'ليلى')
        ..addStar(5, 'math')
        ..markLearned('ar_learn', 'أ')
        ..miss('addition', 'add:7+2');
      final back = ProgressData.fromJson(p.toJson());
      expect(back.name, 'ليلى');
      expect(back.starsIn('math'), 5);
      expect(back.learned('ar_learn'), ['أ']);
      expect(back.skills, {'addition|add:7+2': 1});
    });

    test('reads a web-app localStorage blob', () {
      final p = ProgressData.fromJson({
        'name': 'x', 'stars': 4, 'unlocked': ['counting', 'chooseNumber'],
        'best': {'counting': 2}, 'settings': {'speech': false, 'sfx': true, 'dev': false},
      });
      expect(p.isUnlocked('chooseNumber'), isTrue);
      expect(p.settings.speech, isFalse);
    });
  });

  group('adaptive', () {
    test('focus needs two misses and returns the skill payload', () {
      final p = ProgressData()..miss('addition', 'add:7+2');
      expect(p.focus('addition'), isNull);
      p.miss('addition', 'add:7+2');
      expect(p.focus('addition'), '7+2');
      p.hit('addition', 'add:7+2');
      expect(p.focus('addition'), isNull);
    });

    test('misses are capped at 6', () {
      final p = ProgressData();
      for (var i = 0; i < 10; i++) {
        p.miss('counting', 'count:4');
      }
      expect(p.weakest().single.misses, 6);
    });
  });

  test('badges are awarded once', () {
    final p = ProgressData()..addResult('counting', 10, 10);
    expect(checkBadges(p).map((b) => b.id), ['first_game']);
    expect(checkBadges(p), isEmpty);
  });
}
