import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade2_arabic_generators.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {'ar_far': arFar, 'ar_adverb': arAdverb, 'ar_command': arCommand, 'ar_similar': arSimilar, 'ar_relative': arRelative};

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

  test('ذلك وتلك: the far thing takes ذلك or تلك by gender, and level 1 is all far', () {
    final r = Rng.seeded(1);
    for (var i = 0; i < 100; i++) {
      final q = arFar(1, r);
      final (_, word, fem) = farThings.firstWhere((x) => '${q.answer}'.endsWith(x.$2));
      expect(q.answer, '${fem ? 'تِلْكَ' : 'ذَلِكَ'} $word');
      expect((q.visuals.single as EmojiVisual).caption, contains('بعيد'));
    }
  });

  test('every adverb sentence has a blank, and the wrong choices are the other kind', () {
    for (final (s, a, time) in adverbSentences) {
      expect(s, contains('_____'));
      expect((time ? timeAdverbs : placeAdverbs), contains(a), reason: s);
    }
    final r = Rng.seeded(3);
    for (var i = 0; i < 200; i++) {
      final q = arAdverb(3, r);
      if (q.visuals.single is! WordLineVisual) continue;
      final time = timeAdverbs.contains(q.answer);
      for (final c in q.choices.where((c) => c != q.answer)) {
        expect((time ? placeAdverbs : timeAdverbs), contains(c), reason: '${q.answer} vs $c');
      }
    }
  });

  test('نهي starts with لا and أمر does not', () {
    for (final (s, amr) in commandSentences) {
      expect(s.startsWith('لَا '), !amr, reason: s);
    }
    for (final (amr, nahy, _) in commandVerbs) {
      expect(nahy.startsWith('لَا '), isTrue);
      expect(amr.startsWith('لَا'), isFalse);
    }
  });

  test('similar letters: the missing letter shows once and the blank rebuilds the word', () {
    for (final (plain, _, _, right, wrong) in similarLetterWords) {
      expect(right.allMatches(plain), hasLength(1), reason: plain);
      expect(plain.contains(wrong), isFalse, reason: '$plain has $wrong too');
    }
    final r = Rng.seeded(5);
    for (var i = 0; i < 100; i++) {
      final q = arSimilar(1, r);
      final shown = q.visuals.whereType<BigLetterVisual>().single.text;
      final plain = similarLetterWords.firstWhere((w) => w.$2 == q.sayRight).$1;
      expect(shown.replaceAll('ـ', '').replaceFirst('؟', '${q.answer}'.replaceAll('ـ', '')), plain);
      expect(q.choices, isNot(contains('ه')), reason: 'a lone ه looks like ٥');
    }
  });

  test('relative sentences use الذي, التي and الذين', () {
    final used = {for (final (_, a) in relativeSentences) a};
    expect(used, {'الَّذِي', 'الَّتِي', 'الَّذِينَ'});
    for (final (s, _) in relativeSentences) {
      expect('_____'.allMatches(s), hasLength(1), reason: s);
    }
  });

  test('focus picks the item', () {
    expect(arSimilar(1, Rng.seeded(1), focus: 'ضرس').sayRight, 'ضِرْسٌ');
    expect(arRelative(1, Rng.seeded(1), focus: relativeSentences[4].$1).answer, 'الَّتِي');
  });
}
