import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/math100_generators.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// الأعداد لحد ١٠٠: كل مستوى بيسأل النوع اللي المفروض يسأله.
void main() {
  List<int> nums(Question q) => [
        for (final v in q.visuals.whereType<ExprVisual>())
          for (final p in v.parts)
            if (p case ExprTile(value: final int n)) n,
      ];

  test('addition has no carry below level 4 and always a carry at level 4', () {
    final r = Rng.seeded(11);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 500; i++) {
        final q = add100(lv, r);
        final [a, b] = nums(q);
        expect(q.answer, a + b);
        expect(a + b, inInclusiveRange(1, 100));
        final carry = a % 10 + b % 10 >= 10;
        expect(carry, lv == 4, reason: 'level $lv: $a + $b');
        if (lv == 1) expect([a % 10, b % 10], [0, 0], reason: 'level 1 adds whole tens');
        if (lv == 2) expect(b, lessThan(10), reason: 'level 2 adds a one-digit number');
      }
    }
  });

  test('subtraction has no borrow below level 4 and always a borrow at level 4', () {
    final r = Rng.seeded(12);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 500; i++) {
        final q = sub100(lv, r);
        final [a, b] = nums(q);
        expect(q.answer, a - b);
        expect(a - b, inInclusiveRange(1, 99));
        expect(a % 10 < b % 10, lv == 4, reason: 'level $lv: $a − $b');
      }
    }
  });

  test('tens and ones: the blocks match the answer, and digit swaps are offered as a trap', () {
    final r = Rng.seeded(13);
    var swaps = 0;
    for (var i = 0; i < 500; i++) {
      final q = tensOnes(3, r);
      if (q.visuals.first case TensOnesVisual(:final tens, :final ones)) {
        expect(q.answer, tens * 10 + ones);
        if (ones > 0 && ones != tens && q.choices.contains(ones * 10 + tens)) swaps++;
      } else {
        // العكس: العدد مكتوب، والإجابة رقم العشرات
        expect(q.answer, nums(q).single ~/ 10);
      }
    }
    expect(swaps, greaterThan(100));
  });

  test('skip counting jumps by the same step, and comparison signs are right', () {
    final r = Rng.seeded(14);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final s = skipCount(lv, r);
        final step = int.parse(s.skill!.split(':')[1]);
        expect(step, lv <= 2 ? 10 : anyOf(2, 5, 10));
        final shown = nums(s);
        expect(shown.length, 4);
        final c = compare100(lv, r);
        final [a, b] = nums(c);
        expect([a, b], everyElement(inInclusiveRange(10, 99)));
        expect(c.answer, a > b ? '>' : (a < b ? '<' : '='));
        if (lv == 2) expect(a ~/ 10, b ~/ 10, reason: 'level 2 compares numbers with the same tens');
      }
    }
  });

  test('the numbers-to-100 group opens after addition and sits at the end of the maths world', () {
    final ids = [for (final s in worldStages['math']!) s.id];
    expect(ids.sublist(13), ['tensOnes', 'skipCount', 'compare100', 'add100', 'sub100']);
    expect(packs['tensOnes']!.after, 'addition');
    expect({for (final id in ids.sublist(13)) packs[id]!.groupName}, {'الأعداد لحد ١٠٠'});
  });
}
