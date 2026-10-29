import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/harakat_generators.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// الحركات: إجابة واحدة بس صح، ومفيش ألف (أَ أُ إِ همزة).
void main() {
  const marks = {'َ': 'فتحة', 'ُ': 'ضمة', 'ِ': 'كسرة'};

  test('naming the mark: the big syllable carries the mark the answer names', () {
    final r = Rng.seeded(21);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = arHaraka(lv, r);
        final syl = (q.visuals.single as BigLetterVisual).text;
        expect(syl.length, 2);
        expect(syl[0], isNot('أ'));
        expect(q.answer, marks[syl[1]]);
        expect(q.choices.toSet(), marks.values.toSet());
        expect(q.sayRight, syl, reason: 'the child hears the syllable after a right answer');
      }
    }
  });

  test('picking by mark: one letter with its three marks, only one of them right', () {
    final r = Rng.seeded(22);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = arHarakaPick(lv, r);
        final letter = (q.visuals.single as BigLetterVisual).text;
        expect(q.choices.toSet(), {for (final m in marks.keys) '$letter$m'});
        final name = q.ask.split(' ').last;
        expect(q.choices.where((c) => marks['$c'[1]] == name), [q.answer]);
      }
    }
  });

  test('listening: from level 3 another letter with the same mark joins, still one right answer', () {
    final r = Rng.seeded(23);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = arSyllable(lv, r);
        expect(q.choices.length, lv >= 3 ? 4 : 3);
        expect(q.choices.toSet().length, q.choices.length);
        expect(q.choices.where((c) => c == q.answer).length, 1);
        expect((q.visuals.single as ListenVisual).say, q.answer);
      }
    }
  });

  test('adaptive focus asks for the weak mark', () {
    final r = Rng.seeded(24);
    for (var i = 0; i < 50; i++) {
      expect(arHaraka(1, r, focus: 'كسرة').answer, 'كسرة');
    }
  });

  test('the harakat group opens after the letter table, like madd', () {
    expect(packs['ar_haraka']!.after, 'ar_table');
    expect(packs['ar_haraka']!.groupName, 'الحركات');
    expect(packs['ar_haraka_pick']!.world, 'arabic');
  });
}
