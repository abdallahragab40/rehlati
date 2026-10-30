import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade2_arabic_generators.dart';
import 'package:rehlati/domain/generators/grade3_arabic_generators.dart';
import 'package:rehlati/domain/generators/term2_arabic_generators.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {'ar_negation': arNegation, 'ar_punct': arPunct, 'ar_hamza': arHamza, 'ar_sentenceKind': arSentenceKind};

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.choices, contains(q.answer), reason: q.ask);
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.choices}');
        }
      }
    });
  }

  test('لم goes with past cues and a still verb, لن with future cues', () {
    for (final (s, a) in negationSentences) {
      expect('___'.allMatches(s), hasLength(1), reason: s);
      if (s.contains('أَمْسِ')) expect(a, 'لَمْ', reason: s);
      if (s.contains('غَدًا') || s.contains('الْقَادِمَ')) expect(a, 'لَنْ', reason: s);
    }
  });

  test('punctuation: questions get ؟ and ما أفعل gets !', () {
    for (final (s, m) in punctSentences) {
      if (RegExp('^(أَيْنَ|هَلْ|لِمَاذَا)').hasMatch(s)) expect(m, '؟', reason: s);
      if (s.startsWith('مَا أَ')) expect(m, '!', reason: s);
    }
  });

  test('every hamza word ends in اء', () {
    for (final (plain, full, _) in hamzaWords) {
      expect(plain.endsWith('ا'), isTrue, reason: plain);
      expect(full.replaceAll(RegExp('[ً-ْ]'), ''), '$plainء');
    }
  });

  test('هؤلاء and أولئك from the plural focus, عن/على and ثم/ف from theirs', () {
    final r = Rng.seeded(5);
    for (var i = 0; i < 100; i++) {
      final far = arFar(1, r, focus: 'plural');
      expect('${far.answer}', anyOf(startsWith('هَؤُلَاءِ'), startsWith('أُولَئِكَ')));
      expect(arParticles(1, r, focus: 'jarr2').choices.toSet(), {'عَنْ', 'عَلَى'});
      expect(arParticles(1, r, focus: 'atf2').choices.toSet(), {'فَ', 'ثُمَّ'});
    }
    for (final (s, _) in [...jarr2Sentences, ...atf2Sentences]) {
      expect('___'.allMatches(s), hasLength(1), reason: s);
    }
  });

  test('sentence kinds: nominal sentences do not start with a verb', () {
    for (final (s, nominal) in sentenceKinds) {
      final first = s.split(' ').first;
      expect(nominal, !RegExp('^(ذَهَبَ|يَلْعَبُ|شَرِبَتْ|نَامَ)').hasMatch(first), reason: s);
    }
    expect(arSentenceKind(1, Rng.seeded(1)).visuals.single, isA<WordLineVisual>());
  });
}
