import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {
    'en_prep': enPrep, 'en_days': enDaysGame, 'en_months': enMonthsGame, 'en_feelings': enFeelingsGame,
    'en_weather': enWeatherGame, 'en_seasons': enSeasonsGame, 'en_rooms': enRoomsGame, 'en_places': enPlacesGame,
    'en_transport': enTransportGame, 'en_clothes': enClothesGame, 'en_sports': enSportsGame,
    'en_actions': enActionsGame, 'en_pronouns': enPronouns, 'en_count100': enCount100, 'en_sounds': enSounds,
    'en_possessive': enPossessive, 'en_past': enPast, 'en_safety': enSafety, 'en_food': enFoodGame, 'en_conj': enConj,
    'en_can': enCan,
  };

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.isEnglish, isTrue);
          expect(q.choices, contains(q.answer), reason: q.ask);
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.choices}');
          expect(q.choices.length, greaterThanOrEqualTo(2));
        }
      }
    });
  }

  test('days and months wrap around, and the week starts on Saturday', () {
    expect(enDays.first, 'Saturday');
    expect(enDaysGame(1, Rng.seeded(1), focus: 'Friday').answer, 'Saturday');
    final before = [for (var i = 0; i < 40; i++) enMonthsGame(2, Rng.seeded(i), focus: 'January')]
        .where((q) => q.ask.contains('before'));
    expect(before.first.answer, 'December');
  });

  test('in, on and under only go with places where they make sense', () {
    final r = Rng.seeded(3);
    for (var i = 0; i < 300; i++) {
      final q = enPrep(3, r);
      final v = q.visuals.single as PrepVisual;
      final place = prepPlaces.firstWhere((p) => p.$1 == v.place);
      expect(place.$3, contains(v.prep));
      expect('${q.answer}', anyOf(v.prep, contains(' ${v.prep} the ${place.$2}.')));
    }
  });

  test('English stages are unlocked for children who already passed My family', () {
    expect(ProgressData(best: {'en_family': 2}).isUnlocked('en_prep'), isTrue);
  });

  test('number words', () {
    expect([for (final n in [11, 20, 25, 52, 99, 100]) enNumberWord(n)],
        ['eleven', 'twenty', 'twenty-five', 'fifty-two', 'ninety-nine', 'one hundred']);
  });

  test('the counting lesson stays in its range', () {
    final r = Rng.seeded(12);
    final words = {for (var n = 11; n <= 20; n++) enNumberWord(n)};
    for (var i = 0; i < 200; i++) {
      final q = enCount100(4, r, focus: 'to20');
      if (q.ask == 'Which number is this?') expect(words, contains(q.answer));
    }
  });

  test('the missing sound rebuilds the word', () {
    final r = Rng.seeded(13);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 200; i++) {
        final q = enSounds(lv, r);
        final shown = q.visuals.whereType<BigLetterVisual>().single.text;
        expect(shown.replaceFirst(RegExp('_+'), '${q.answer}'), q.sayRight);
      }
    }
    for (final focus in ['blendS', 'blendL', 'digraph', 'final', 'long']) {
      expect(enSounds(1, Rng.seeded(1), focus: focus).skill, 'en_sound:$focus');
    }
  });

  test('pronoun sentences: am goes with I, are with They', () {
    for (final (_, s, p) in pronounSentences) {
      if (s.contains(' am ')) expect(p, 'I');
      if (s.contains(' are ')) expect(p, 'They');
    }
  });

  test('grade 3 sentences have one blank and the answer among the choices', () {
    for (final (_, s, a) in [...possessiveSentences, ...canSentences]) {
      expect('___'.allMatches(s), hasLength(1), reason: s);
      expect(a, isNotEmpty);
    }
    for (final (s, a, choices) in [...pastSentences, ...pastIrregular]) {
      expect('___'.allMatches(s), hasLength(1), reason: s);
      expect(choices, contains(a));
      expect(s, startsWith('Yesterday'));
    }
    for (final (_, s, a, choices) in safetySentences) {
      expect(choices, contains(a), reason: s);
    }
    expect(enPast(1, Rng.seeded(1), focus: 'irregular').skill, 'en_past:irr');
    for (final (_, s, a) in possessiveSentences) {
      expect(a, switch (s.split(' ').first) { 'I' => 'my', 'He' => 'his', _ => 'her' }, reason: s);
    }
  });
}
