import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/term2_arabic_generators.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {'ar_pronoun': arPronoun, 'ar_tense': arTense, 'ar_taa': arTaa, 'ar_style': arStyle, 'ar_particles': arParticles};

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.choices, contains(q.answer), reason: q.ask);
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.choices}');
          expect(q.choices.length, greaterThanOrEqualTo(2));
        }
      }
    });
  }

  test('every blank sentence has exactly one blank', () {
    for (final (_, sentences, _, _) in pronounSets.values) {
      for (final (s, _) in sentences) {
        expect('___'.allMatches(s), hasLength(1), reason: s);
      }
    }
    for (final (s, _) in [...jarrSentences, ...atfSentences]) {
      expect('___'.allMatches(s), hasLength(1), reason: s);
    }
    for (final (s, _, _) in questionWordSentences) {
      expect(s.startsWith('___'), isTrue, reason: s);
    }
  });

  test('the lesson focus picks its own pronouns, styles and particles', () {
    final r = Rng.seeded(7);
    for (var i = 0; i < 100; i++) {
      expect(arPronoun(1, r, focus: 'anta').choices.toSet(), {'أَنْتَ', 'أَنْتِ'});
      expect(arPronoun(4, r, focus: 'ghaib').skill, 'pronoun:ghaib');
      expect(arParticles(1, r, focus: 'atf').choices.toSet(), {'وَ', 'أَوْ'});
      expect(arStyle(2, r, focus: 'taajjub').skill, 'style:taajjub');
    }
  });

  test('taa words end the way the answer says', () {
    for (final (plain, full, _, last) in taaWords) {
      final bare = full.replaceAll(RegExp('[ً-ْ]'), '');
      expect(bare, '$plain$last', reason: full);
    }
  });

  test('the question-word replies are shown under the question', () {
    final r = Rng.seeded(9);
    for (var i = 0; i < 100; i++) {
      final q = arStyle(2, r, focus: 'istifham');
      if (q.visuals.length == 2) expect(q.visuals.last, isA<CaptionVisual>());
    }
  });
}
