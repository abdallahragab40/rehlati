import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade6_arabic_generators.dart';
import 'package:rehlati/domain/generators/grade6_math_generators.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = <String, Question Function(int, Rng, {String? focus})>{
    'ar_nakira': arNakira, 'ar_hamzaMid': arHamzaMid, 'ar_asmaa5': arAsmaa5, 'ar_khabarType': arKhabarType, 'ar_kana': arKana,
    'ar_naat': arNaat, 'ar_mudari': arMudari,
    'divisibility': divisibility, 'integers': integers, 'algebra6': algebra6, 'statistics': statistics, 'ratios': ratios,
    'fractionDiv6': fractionDiv6, 'quadrants': quadrants, 'area6': area6,
    'en_ableTo': enAbleTo, 'en_bothEither': enBothEither, 'en_whoWhich': enWhoWhich, 'en_presentPerfect': enPresentPerfect,
    'en_usedTo': enUsedTo, 'en_conditional': enConditional, 'en_jobs6': enCommunityJobsGame, 'en_travel': enTravelGame,
    'en_art': enArtGame, 'en_heritage': enHeritageGame,
  };

  for (final MapEntry(key: id, value: gen) in gens.entries) {
    test('$id: one right answer among different choices at every level', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 300; i++) {
          final q = gen(lv, r);
          expect(q.type, id);
          expect(q.choices, contains(q.answer), reason: '${q.ask} ${q.choices}');
          expect(q.choices.toSet(), hasLength(q.choices.length), reason: '${q.ask} ${q.choices}');
          expect(q.choices.length, greaterThanOrEqualTo(2), reason: q.ask);
        }
      }
    });
  }

  test('mid-word hamza words rebuild, and no two words look the same with the gap', () {
    final shown = <String>{};
    for (final (before, after, full, hamza, _) in hamzaMidWords) {
      expect(full.replaceAll(RegExp('[ً-ْ]'), ''), '$before$hamza$after', reason: full);
      expect(shown.add('$before|$after'), isTrue, reason: '$full looks like another word');
    }
  });

  test('prime factors multiply back', () {
    for (final n in [12, 18, 20, 24, 28, 30, 36, 40, 45, 48, 60]) {
      expect(primeFactors(n).reduce((a, b) => a * b), n);
    }
  });

  test('integers are written in words', () {
    expect([intWord(-3), intWord(0), intWord(4)], ['سالب ٣', 'صفر', '٤']);
  });

  test('statistics answers are right', () {
    final r = Rng.seeded(5);
    for (var i = 0; i < 300; i++) {
      final q = statistics(3, r);
      final data = (q.visuals.single as CaptionVisual).text.split(': ').last.split('، ')
          .map((s) => int.parse(s.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join())).toList();
      final sorted = [...data]..sort();
      int v(String s) => int.parse(s.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join());
      switch (q.skill) {
        case 'stat:mean':
          expect(v('${q.answer}') * data.length, data.reduce((a, b) => a + b));
        case 'stat:median':
          expect(v('${q.answer}'), sorted[2]);
        case 'stat:range':
          expect(v('${q.answer}'), sorted.last - sorted.first);
      }
    }
  });

  test('grade 6 stages open from existing progress', () {
    final p = ProgressData(best: {'ar_majrur': 2, 'decimals5': 2, 'en_frequency': 2});
    for (final id in ['ar_nakira', 'divisibility', 'en_ableTo']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
  });
}
