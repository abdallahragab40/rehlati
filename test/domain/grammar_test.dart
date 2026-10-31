import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grammar_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// القواعد والفهم: الكلمة المعروضة دايمًا من القوايم، والإجابة واحدة صح.
void main() {
  String shown(Question q) => switch (q.visuals.last) {
        BigLetterVisual(:final text) => text,
        WordLineVisual(:final word) => word!,
        _ => throw StateError('unexpected visual'),
      };
  bool vowelled(String w) => RegExp('[ً-ْ]').hasMatch(w);

  test('word lists are fully vowelled, with no word in two groups', () {
    final all = [
      for (final w in wordTypes) w.$1,
      for (final f in numberForms) ...[f.$1, f.$2, f.$3],
      for (final g in genderPairs) ...[g.$1, g.$2],
      for (final o in opposites) ...[o.$1, o.$2],
    ];
    expect(all.every(vowelled), isTrue);
    expect({for (final o in opposites) ...[o.$1, o.$2]}.length, opposites.length * 2, reason: 'each opposite once');
    expect({for (final w in wordTypes) w.$1}.length, wordTypes.length);
    expect(wordTypes.where((w) => w.$2 == 'حرف').length, 10);
    // دايمًا ـانِ في المثنى المرفوع
    expect(numberForms.every((f) => f.$2.endsWith('انِ')), isTrue);
  });

  test('word type: particles only from level 3, and the answer matches the list', () {
    final r = Rng.seeded(51);
    final types = {for (final w in wordTypes) w.$1: w.$2};
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = arWordType(lv, r);
        expect(q.answer, types[shown(q)]);
        if (lv <= 2) expect(q.answer, isNot('حرف'));
      }
    }
  });

  test('number, gender and opposites: one right answer that matches the lists', () {
    final r = Rng.seeded(52);
    final kinds = {for (final f in numberForms) ...{f.$1: 'مفرد', f.$2: 'مثنى', f.$3: 'جمع'}};
    final fem = {for (final g in genderPairs) g.$2};
    final opp = {for (final o in opposites) ...{o.$1: o.$2, o.$2: o.$1}};
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final n = arNumber(lv, r);
        expect(n.answer, kinds[shown(n)]);
        final g = arGender(lv, r);
        expect(g.answer, fem.contains(shown(g)) ? 'مؤنث' : 'مذكر');
        final o = arOpposite(lv, r);
        expect(o.answer, opp[shown(o)]);
        expect(o.choices.where((c) => c == o.answer).length, 1);
        expect(o.choices, isNot(contains(shown(o))));
        expect(o.choices.length, lv <= 2 ? 3 : 4);
      }
    }
  });

  test('completing a sentence: one blank, three choices, and the right one reads back in full', () {
    final r = Rng.seeded(53);
    for (var i = 0; i < 200; i++) {
      final q = arSentence(2, r);
      final s = shown(q);
      expect('_____'.allMatches(s).length, 1);
      expect(q.choices.length, 3);
      expect(q.choices.toSet().length, 3);
      expect(q.sayRight, isNot(contains('_____')));
      expect(q.sayRight, contains(q.answer as String));
    }
  });

  test('the grammar group opens from fourth primary, or after the sukun stage', () {
    expect(packs['ar_wordType']!.after, 'ar_sukun');
    expect(ProgressData(grade: 'p4').isUnlocked('ar_wordType'), isTrue);
    expect(ProgressData(grade: 'p3').isUnlocked('ar_wordType'), isFalse);
    expect(ProgressData(grade: 'p4').isUnlocked('ar_number'), isFalse, reason: 'the rest open one by one');
  });
}
