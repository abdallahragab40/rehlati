import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/grade5_arabic_generators.dart';
import 'package:rehlati/domain/generators/grade5_math_generators.dart';
import 'package:rehlati/domain/generators/school_english_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = <String, Question Function(int, Rng, {String? focus})>{
    'ar_mafool': arMafool, 'ar_hamzaQat': arHamzaQat, 'ar_hamzaEnd': arHamzaEnd, 'ar_mafaeel': arMafaeel, 'ar_majrur': arMajrur,
    'decimals5': decimals5, 'equations': equations, 'fractions5': fractions5, 'coordinates': coordinates, 'volume': volume,
    'pieChart': pieChart,
    'en_frequency': enFrequency, 'en_someAny': enSomeAny, 'en_did': enDid, 'en_inOnAt': enInOnAt, 'en_could': enCould,
    'en_haveTo': enHaveTo, 'en_goingTo': enGoingTo, 'en_continuous': enContinuous, 'en_health': enHealthGame,
    'en_space': enSpaceGame, 'en_nature': enNatureGame, 'en_hobbies': enHobbiesGame,
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

  test('decimal text trims zeros', () {
    expect([decimalText(3450, 3), decimalText(3000, 3), decimalText(5, 2), decimalText(120, 1)], ['٣٫٤٥', '٣', '٠٫٠٥', '١٢']);
  });

  test('hamza words: the hamza follows the vowel before it, and the word rebuilds', () {
    for (final (plain, full, hamza, _) in hamzaEndWords) {
      expect(full.replaceAll(RegExp('[ً-ْ]'), ''), '$plain$hamza', reason: full);
    }
    for (final (rest, full, first) in hamzaQatWords) {
      expect(full.replaceAll(RegExp('[ً-ْ]'), ''), '$first$rest', reason: full);
    }
  });

  test('fraction answers are never equal in value to a wrong choice', () {
    final r = Rng.seeded(7);
    for (var i = 0; i < 400; i++) {
      final q = fractions5(3, r);
      if (q.look != ChoiceLook.fraction) continue;
      final a = '${q.answer}'.split('/').map(int.parse).toList();
      for (final c in q.choices.where((c) => c != q.answer)) {
        final b = '$c'.split('/').map(int.parse).toList();
        expect(a[0] * b[1] == b[0] * a[1], isFalse, reason: '${q.answer} vs $c');
      }
    }
  });

  test('coordinates read the point that is drawn', () {
    final r = Rng.seeded(8);
    for (var i = 0; i < 200; i++) {
      final q = coordinates(2, r);
      final v = q.visuals.single as CoordVisual;
      if (q.ask == 'إحداثيات النقطة أ؟') expect(q.answer, coordText(v.points.single.$2, v.points.single.$3));
    }
  });

  test('pie charts have one biggest slice and add up to the whole circle', () {
    final r = Rng.seeded(9);
    for (var i = 0; i < 200; i++) {
      final v = pieChart(2, r).visuals.whereType<PieVisual>().single;
      expect(v.eighths.reduce((a, b) => a + b), 8);
      final top = v.eighths.reduce((a, b) => a > b ? a : b);
      expect(v.eighths.where((e) => e == top), hasLength(1));
    }
  });

  test('grade 5 stages open from existing progress', () {
    final p = ProgressData(best: {'ar_fail': 2, 'decimals': 2, 'en_present': 2});
    for (final id in ['ar_mafool', 'decimals5', 'en_frequency']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
  });
}
