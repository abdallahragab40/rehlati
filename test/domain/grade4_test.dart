import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade4_arabic_generators.dart';
import 'package:rehlati/domain/generators/grade4_math_generators.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = <String, Question Function(int, Rng, {String? focus})>{
    'ar_nounSigns': arNounSigns, 'ar_alPrefix': arAlPrefix, 'ar_mubtada': arMubtada, 'ar_hiddenAlif': arHiddenAlif,
    'ar_alifLayyina': arAlifLayyina, 'ar_fail': arFail,
    'roundLarge': roundLarge, 'bigAddSub': bigAddSub, 'unitConvert': unitConvert, 'mulCompare': mulCompare,
    'factors': factors, 'longMulDiv': longMulDiv, 'orderOps': orderOps, 'fractionOps': fractionOps, 'decimals': decimals,
    'geometry4': geometry4,
    'en_present': enPresent, 'en_compare': enCompare, 'en_prep2': enPrep2, 'en_jobs': enJobsGame,
    'en_environment': enEnvironmentGame, 'en_containers': enContainers, 'en_celebrate': enCelebrateGame, 'en_should': enShould,
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

  test('ل with ال drops the alif (and a lam), the other letters keep it', () {
    expect(alWith('ل', 'البيت'), 'للبيت');
    expect(alWith('ل', 'الليل'), 'لليل');
    expect(alWith('ب', 'القلم'), 'بالقلم');
    expect(alWith('ك', 'الشجرة'), 'كالشجرة');
  });

  test('alif layyina words end the way the answer says', () {
    for (final (plain, full, last, _) in layyinaWords) {
      expect(full.replaceAll(RegExp('[ً-ْ]'), ''), '$plain$last', reason: full);
    }
  });

  test('every verbal sentence starts with its verb and has its subject', () {
    for (final (s, verb, subject, _) in verbalSentences) {
      expect(s.startsWith(verb), isTrue, reason: s);
      expect(s.contains(subject), isTrue, reason: s);
    }
  });

  test('maths answers are right', () {
    final r = Rng.seeded(9);
    for (var i = 0; i < 300; i++) {
      final q = orderOps(3, r);
      final parts = (q.visuals.single as ExprVisual).parts;
      int n(int k) => (parts[k] as ExprTile).value as int;
      final ans = parts.first is ExprOp ? (n(1) + n(3)) * n(6) : n(0) + n(2) * n(4);
      expect(q.answer, ans.toString().split('').map((d) => '٠١٢٣٤٥٦٧٨٩'[int.parse(d)]).join());
    }
    expect(decimals(1, Rng.seeded(1)).choices.every((c) => '$c'.contains('٫')), isTrue);
  });

  test('a square is never offered next to names that also fit it', () {
    final r = Rng.seeded(4);
    for (var i = 0; i < 300; i++) {
      final q = geometry4(2, r, focus: 'shapes');
      if (q.answer == 'مربع') expect(q.choices, isNot(contains('مستطيل')));
    }
  });

  test('grade 4 stages open from existing progress', () {
    final p = ProgressData(best: {'ar_reading': 2, 'divisionExact': 2, 'en_isare': 2});
    for (final id in ['ar_nounSigns', 'roundLarge', 'en_present']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
  });
}
