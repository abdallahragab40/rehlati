import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/generators/madd_generators.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/parent_guide/pg_search.dart';

import 'engine_test.dart' show makeContainer;

void main() {
  group('madd unlock and adaptive', () {
    test('madd_alif opens once "complete the alphabet" is passed', () {
      final p = ProgressData();
      expect(p.isUnlocked('madd_alif'), isFalse);
      p.best['ar_table'] = 2;
      expect(p.isUnlocked('madd_alif'), isTrue);
      expect(p.isUnlocked('madd_waw'), isFalse, reason: 'the rest unlock in order');
    });

    test('three misses on a type trigger the small practice, easing resets it', () {
      final p = ProgressData();
      for (var i = 0; i < 3; i++) {
        p.miss('madd_alif', 'madd:waw');
      }
      expect(maddWeakType(p), 'waw');
      maddEaseMisses(p, 'waw');
      expect(maddWeakType(p), isNull);
      expect(p.skills['madd_alif|madd:waw'], 1, reason: 'eased, not erased');
    });

    test('mastery needs 10 tries at 90%', () {
      final s = MaddStats();
      for (var i = 0; i < 9; i++) {
        s.record(type: 'alif', ok: true);
      }
      expect(s.mastered('alif'), isFalse);
      s.record(type: 'alif', ok: true);
      expect(s.mastered('alif'), isTrue);
    });
  });

  group('madd in the engine', () {
    test('first-try answers record madd stats, read mode always succeeds', () async {
      final c = await makeContainer();
      final engine = c.read(gameProvider.notifier)..start('madd_alif');
      final s = c.read(gameProvider)!;
      final q = s.q;
      if (q.mode == QMode.read) {
        engine.readDone();
      } else if (q.mode == QMode.choice) {
        engine.answer(q.choices.indexOf(q.answer!));
      } else {
        for (final v in q.answerList) {
          engine.pick(q.items.indexOf(v));
        }
      }
      expect(s.locked, isTrue);
      final p = c.read(progressProvider);
      expect(p.madd.types['alif']?.ok, 1);
      expect(p.madd.started, contains('madd_alif'));
      expect(p.stars, 1);
    });

    test('sort: right box places the card, wrong box is a gentle miss', () async {
      final c = await makeContainer();
      final engine = c.read(gameProvider.notifier);
      // نلعب لحد ما يطلع سؤال تصنيف في مرحلة "ما نوع المد؟"
      GameSession? s;
      for (var tries = 0; tries < 30; tries++) {
        engine.start('madd_types');
        s = c.read(gameProvider)!;
        if (s.q.mode == QMode.sort) break;
      }
      final q = s!.q;
      expect(q.mode, QMode.sort);
      final card = q.sortCards.first;
      final wrongBox = q.boxes.firstWhere((b) => b.key != card.type).key;

      engine
        ..sortSelect(0)
        ..sortPlace(wrongBox);
      expect(s.placed, isEmpty);
      expect(s.tries, 1);
      expect(s.mistakes, isNotEmpty);

      for (var i = 0; i < q.sortCards.length; i++) {
        engine
          ..sortSelect(i)
          ..sortPlace(q.sortCards[i].type);
      }
      expect(s.placed.length, q.sortCards.length);
      expect(s.locked, isTrue);
    });

    test('a passed madd round gives +2 every time and +5 the first time', () async {
      final c = await makeContainer();
      final engine = c.read(gameProvider.notifier)..start('madd_waw');
      for (var i = 0; i < 10; i++) {
        final q = c.read(gameProvider)!.q;
        switch (q.mode) {
          case QMode.read:
            engine.readDone();
          case QMode.choice:
            engine.answer(q.choices.indexOf(q.answer!));
          default:
            for (final v in q.answerList) {
              engine.pick(q.items.indexOf(v));
            }
        }
        await Future<void>.delayed(const Duration(milliseconds: 1450));
      }
      final p = c.read(progressProvider);
      expect(c.read(gameProvider)!.result?.correct, 10);
      // ١٠ نجوم للإجابات + ٢ للجولة + ٥ أول نجاح
      expect(p.starsIn('arabic'), 17);
      expect(p.madd.rounds['madd_waw'], 1);
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('parent guide', () {
    test('search finds the behaviour from everyday words', () {
      expect(pgSearch('ابني بيضرب اخوه').first.id, 'hit');
      expect(pgSearch('بيصرخ لما اقوله لا').first.id, 'tantrum');
      expect(pgSearch('   '), isEmpty);
      expect(pgSearch('كلام مالوش علاقة xyz'), isEmpty);
    });

    test('goals and madd stats survive a json round trip and read web data', () {
      final p = ProgressData.fromJson({
        'madd': {
          'types': {'alif': {'ok': 3, 'tries': 4}},
          'review': {'waw': 1},
          'rounds': {'madd_alif': 2},
        },
        'parentGuide': {
          'focus': {
            'hit': {'start': 1, 'days': [true, false, true, false, false, false, false], 'paused': true},
          },
        },
      });
      expect(p.madd.types['alif']!.tries, 4);
      expect(p.madd.review, {'waw'});
      expect(p.pgFocus['hit']!.done, 2);
      final back = ProgressData.fromJson(p.toJson());
      expect(back.pgFocus['hit']!.paused, isTrue);
      expect(back.madd.rounds['madd_alif'], 2);
    });
  });

  test('every madd stage has a lesson and the registry keeps web order', () {
    final ids = [for (final s in worldStages['arabic']!) s.id];
    // بعد الـ١١ مرحلة الأصلية، والحركات وأشكال الحرف قبلها عشان المدود بتفترض إن الطفل يعرفهم
    expect(ids.indexOf('madd_alif'), greaterThan(ids.indexOf('ar_match_word')));
    expect(ids.indexOf('madd_alif'), greaterThan(ids.indexOf('ar_haraka_pick')));
    expect(ids.indexOf('madd_alif'), greaterThan(ids.indexOf('ar_position')));
    expect(packs['madd_alif']!.after, 'ar_table');
    expect(packs.values.where((s) => s.isMadd).length, 9);
  });
}
