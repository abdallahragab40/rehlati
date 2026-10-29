import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/en_primary_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// English للابتدائي: إجابة واحدة صح، والمستوى بيحدد إمتى يظهر الصعب.
void main() {
  String text(Question q) => switch (q.visuals.last) {
        WordLineVisual(:final word) => word!,
        CaptionVisual(:final text) => text,
        _ => throw StateError('unexpected visual'),
      };

  test('every question is in English, spoken in English, with one right answer', () {
    final r = Rng.seeded(61);
    for (final gen in [enCvc, enAAn, enPlural, enIsAre, enQuestions, enSentence]) {
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          expect([q.lang, q.ltr], ['en', true]);
          expect(q.choices.where((c) => c == q.answer).length, 1, reason: q.type);
          expect(q.choices.toSet().length, q.choices.length, reason: q.type);
        }
      }
    }
  });

  test('CVC words: distractors differ from the answer by exactly one letter', () {
    for (final (word, _, near) in cvcWords) {
      expect(word.length, 3);
      for (final n in near) {
        expect(n.length, 3, reason: n);
        var diff = 0;
        for (var i = 0; i < 3; i++) {
          if (word[i] != n[i]) diff++;
        }
        expect(diff, 1, reason: '$word vs $n');
      }
    }
  });

  test('a or an follows the first sound of the noun', () {
    final r = Rng.seeded(62);
    for (var i = 0; i < 300; i++) {
      final q = enAAn(2, r);
      final noun = text(q).replaceFirst('___ ', '');
      expect(q.answer, 'aeiou'.contains(noun[0]) ? 'an' : 'a', reason: noun);
    }
  });

  test('plurals: irregular ones only at level 4, y→ies from level 3, and the singular is always a trap', () {
    final r = Rng.seeded(63);
    final irregular = {'children', 'mice', 'teeth', 'feet'};
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = enPlural(lv, r);
        final many = q.answer as String;
        if (lv < 4) expect(irregular, isNot(contains(many)));
        if (lv < 3) expect(many.endsWith('ies'), isFalse);
        final one = plurals.firstWhere((p) => p.$2 == many).$1;
        expect(q.choices, contains(one));
        expect((q.visuals.first as PicsVisual).count, inInclusiveRange(2, 5));
      }
    }
  });

  test('is, are or am: "am" only from level 3, and it always follows "I"', () {
    final r = Rng.seeded(64);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = enIsAre(lv, r);
        if (lv <= 2) expect(q.choices, ['is', 'are']);
        if (q.answer == 'am') expect(text(q).startsWith('I '), isTrue);
        expect(q.sayRight, isNot(contains('___')));
      }
    }
  });

  test('question words and sentences: one blank, read back in full', () {
    final r = Rng.seeded(65);
    for (var i = 0; i < 200; i++) {
      for (final q in [enQuestions(3, r), enSentence(3, r)]) {
        expect('___'.allMatches(text(q)).length, 1);
        expect(q.sayRight, contains(q.answer as String));
      }
    }
  });

  test('primary English opens from first primary, English grammar from fourth', () {
    expect([packs['en_cvc']!.after, packs['en_isare']!.after], ['en_word', 'en_plural']);
    expect(ProgressData(age: 6).isUnlocked('en_cvc'), isTrue);
    expect(ProgressData(age: 6).isUnlocked('en_isare'), isFalse);
    expect(ProgressData(age: 9).isUnlocked('en_isare'), isTrue);
    expect(ProgressData(age: 5).isUnlocked('en_cvc'), isFalse);
  });
}
