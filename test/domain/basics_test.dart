import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/basics_data.dart';
import 'package:rehlati/content/deen_data.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

import 'engine_test.dart' show makeContainer;

/// المحتوى اللي اتضاف بعد مراجعة المنهج: ترتيبه، فتحه للتقدّم القديم، والعوالم الجديدة.
void main() {
  test('the arabic map teaches harakat and letter forms before the madd', () {
    final ids = [for (final s in worldStages['arabic']!) s.id];
    expect(ids.indexOf('ar_haraka'), lessThan(ids.indexOf('madd_alif')));
    expect(ids.indexOf('ar_forms'), lessThan(ids.indexOf('madd_alif')));
    expect(ids.indexOf('ar_shadda'), greaterThan(ids.indexOf('ar_sukun')));
  });

  test('a child who passed the letter table keeps the madd and also gets harakat and letter forms', () {
    final p = ProgressData()
      ..unlocked.addAll(['ar_pick', 'ar_match', 'ar_table'])
      ..best['ar_table'] = 2;
    for (final id in ['madd_alif', 'ar_haraka', 'ar_forms']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
    expect(p.isUnlocked('ar_short_read'), isFalse, reason: 'short sentences wait for reading madd words');
    p.best['madd_read'] = 2;
    expect(p.isUnlocked('ar_short_read'), isTrue);
  });

  test('released progress opens the new groups that sit between released stages', () {
    final p = ProgressData()
      ..best['chooseNumber'] = 2
      ..best['ar_match_word'] = 2
      ..best['en_pick'] = 2
      ..best['en_word'] = 2;
    for (final id in ['ordinals', 'ar_this', 'en_shapes']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
  });

  test('the religion, discover and writing worlds are open, age-matched and have no skip', () {
    final p = ProgressData();
    for (final w in ['deen', 'discover', 'write']) {
      for (final s in worldStages[w]!) {
        expect(p.isUnlocked(s.id), isTrue, reason: s.id);
        expect(p.canSkip(s.id), isFalse, reason: s.id);
        expect(s.ages, isNotNull, reason: s.id);
      }
    }
    expect(p.unlockNext('deen_dua'), isNull);
  });

  test('repeating a dhikr is a read-and-confirm round with no wrong answer', () async {
    final c = await makeContainer();
    final engine = c.read(gameProvider.notifier)..start('deen_repeat');
    final s = c.read(gameProvider)!;
    expect(s.q.mode, QMode.read);
    expect(s.q.visuals.whereType<ListenVisual>(), isNotEmpty);
    engine.readDone();
    expect(s.locked, isTrue);
    expect(s.dots[0], DotState.done);
  });

  test('content lists stay consistent', () {
    // كل كلمة شدّة ليها الحرف المشدّد جواها
    for (final (w, l, _) in shaddaWords) {
      if (l.isNotEmpty) expect(RegExp('$l[\u064B-\u0650]?\u0651').hasMatch(w), isTrue, reason: w);
    }
    // اللام الشمسية: الحرف اللي بعد «ال» عليه شدّة، والقمرية لأ
    for (final (w, sun, _) in alWords) {
      expect(RegExp('^ال.[\u064B-\u0650]?\u0651').hasMatch(w), sun, reason: w);
    }
    expect(islamPillars.length, 5);
    expect(imanPillars.length, 6);
    expect(hijriMonths.length, 12);
    expect(hijriMonths[8], 'رمضان');
    for (final story in prophetStories) {
      expect(story.$6, isNot(contains(story.$5)), reason: story.$1);
    }
    expect({for (final a in habitatAnimals) a.$3}, habitats.keys.toSet());
  });

  test('letter forms: joining letters have three shapes, the others two', () {
    expect([for (final p in ['first', 'middle', 'last']) letterForm('ب', p)], ['بـ', 'ـبـ', 'ـب']);
    expect([for (final p in ['first', 'middle', 'last']) letterForm('د', p)], ['د', 'ـد', 'ـد']);
    final q = packs['ar_forms']!.gen!(3, Rng.seeded(5));
    expect(q.choices, contains(q.answer));
  });
}
