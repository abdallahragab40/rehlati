import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/life_generators.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// الفلوس والساعة: الإجابة دايمًا من المرسوم، والساعة بالكلام المصري الصح.
void main() {
  test('counting money: the answer is the sum of the pieces shown, within the level\'s limit', () {
    final r = Rng.seeded(41);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 400; i++) {
        final q = moneyCount(lv, r);
        final pieces = (q.visuals.single as MoneyVisual).pounds;
        expect(pieces.length, greaterThanOrEqualTo(2));
        expect(q.answer, pieces.fold(0, (s, x) => s + x));
        expect(q.answer as int, lessThanOrEqualTo(const [20, 50, 100, 100][lv - 1]));
        expect(pieces, everyElement(isIn([1, 5, 10, 20, 50])));
        expect(q.choices.toSet().length, q.choices.length);
        expect(q.choices, contains(q.answer));
      }
    }
  });

  test('change: paid minus price, and the price itself is offered as a trap', () {
    final r = Rng.seeded(42);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 400; i++) {
        final q = moneyChange(lv, r);
        final paid = (q.visuals.first as MoneyVisual).pounds.single;
        expect(paid, const [10, 20, 50, 100][lv - 1]);
        final price = paid - (q.answer as int);
        expect(price, inInclusiveRange(1, paid - 1));
        expect((q.visuals[1] as CaptionVisual).text, contains('جنيه'));
        expect(q.choices, contains(price));
        expect(q.choices.toSet().length, q.choices.length);
      }
    }
  });

  test('Egyptian time words: quarters, thirds and "إلا" with the next hour', () {
    expect(clockTime(3, 0), '٣ تمام');
    expect(clockTime(3, 15), '٣ والربع');
    expect(clockTime(3, 20), '٣ والتلت');
    expect(clockTime(3, 25), '٣ والنص إلا خمسة');
    expect(clockTime(3, 30), '٣ والنص');
    expect(clockTime(3, 35), '٣ والنص وخمسة');
    expect(clockTime(3, 40), '٤ إلا تلت');
    expect(clockTime(3, 45), '٤ إلا ربع');
    expect(clockTime(12, 50), '١ إلا عشرة');
    expect(clockTime(11, 55), '١٢ إلا خمسة');
    // كل ساعة ودقيقة ليها كلام مختلف
    final all = {for (var h = 1; h <= 12; h++) for (var m = 0; m < 60; m += 5) clockTime(h, m)};
    expect(all.length, 12 * 12);
  });

  test('reading the clock: quarters only at the first levels, one right answer that matches the hands', () {
    final r = Rng.seeded(43);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 400; i++) {
        final q = clockQuarter(lv, r);
        final c = q.visuals.single as ClockVisual;
        expect(q.answer, clockTime(c.hour, c.minute));
        if (lv <= 2) expect(c.minute, isIn([0, 15, 30, 45]));
        expect(q.choices.length, lv <= 2 ? 3 : 4);
        expect(q.choices.where((x) => x == q.answer).length, 1);
      }
    }
  });

  test('money and time open after adding to 100 and retain their order after times tables', () {
    final ids = [for (final s in worldStages['math']!) s.id];
    final at = ids.indexOf('moneyCount');
    expect(ids.sublist(at, at + 3), ['moneyCount', 'moneyChange', 'clockQuarter']);
    expect(at, greaterThan(ids.indexOf('timesAll')));
    expect(packs['moneyCount']!.after, 'add100');
  });
}
