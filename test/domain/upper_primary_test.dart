import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/upper_primary_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  test('division equations and missing dividends are correct at every level', () {
    final r = Rng.seeded(912);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 500; i++) {
        for (final gen in [divisionExact, divisionMissing]) {
          final q = gen(lv, r);
          final parts = (q.visuals.single as ExprVisual).parts;
          final a = (parts[0] as ExprTile).value ?? q.answer;
          final b = (parts[2] as ExprTile).value as int;
          final c = (parts[4] as ExprTile).value ?? q.answer;
          expect(a, (c as int) * b);
          expect((a as int) % b, 0);
        }
      }
    }
  });

  test('fractions of numbers use exact equal parts and proper fractions', () {
    final r = Rng.seeded(22);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 500; i++) {
        final q = fractionOfNumber(lv, r);
        // Each number is also present in the spoken clip sequence.
        final denominator = int.parse(q.skill!.split(':').last);
        expect(q.answer as int, greaterThan(0));
        expect(denominator, inInclusiveRange(2, lv <= 2 ? 5 : 10));
        final text = (q.visuals.single as CaptionVisual).text;
        const digits = '٠١٢٣٤٥٦٧٨٩';
        final numbers = RegExp('[٠-٩]+').allMatches(text).map((m) =>
            int.parse(m[0]!.split('').map((c) => digits.indexOf(c)).join())).toList();
        final [total, parts, taken] = numbers;
        expect(total % parts, 0);
        expect(taken, inInclusiveRange(1, parts - 1));
        expect(q.answer, total ~/ parts * taken);
      }
    }
  });

  test('exactly one fraction choice is equivalent, including all distractors', () {
    final r = Rng.seeded(23);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 500; i++) {
        final q = fractionEquivalent(lv, r);
        final correct = (q.answer as String).split('/').map(int.parse).toList();
        final equivalent = q.choices.where((choice) {
          final f = (choice as String).split('/').map(int.parse).toList();
          expect(f[0], greaterThan(0));
          expect(f[1], greaterThan(0));
          expect(q.choiceSay[choice], fractionSay(choice));
          return f[0] * correct[1] == correct[0] * f[1];
        });
        expect(equivalent.toList(), [q.answer]);
      }
    }
  });

  test('entry respects grade override and earned prerequisites', () {
    for (final age in [9, 10, 11, 12]) {
      expect(ProgressData(age: age).isUnlocked('divisionExact'), isTrue);
    }
    expect(ProgressData(age: 8).isUnlocked('divisionExact'), isFalse);
    expect(ProgressData(age: 12, grade: 'p2').isUnlocked('divisionExact'), isFalse);
    final p = ProgressData(age: 8)..best['timesAll'] = 2;
    expect(p.isUnlocked('divisionExact'), isTrue);
    expect(p.isUnlocked('fractionOfNumber'), isFalse);
    expect(p.unlockNext('divisionMissing')!.id, 'fractionOfNumber');
    expect(p.isUnlocked('fractionOfNumber'), isTrue);
    expect(packs['divisionExact']!.gen!(1, Rng.seeded(1), focus: '3').skill, 'division:3');
  });
}
