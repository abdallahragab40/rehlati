import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/school_math_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';

void main() {
  final gens = {
    'position': position, 'threeNumbers': threeNumbers, 'rounding': rounding, 'hundreds': hundreds, 'barGraph': barGraph,
    'composeShapes': composeShapes,
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
          expect(q.choices.length, greaterThanOrEqualTo(2));
        }
      }
    });
  }

  test('position: the row reads from the right, so the first item is first from the right', () {
    final r = Rng.seeded(2);
    for (var i = 0; i < 300; i++) {
      final q = position(2, r);
      final row = (q.visuals.single as QueueVisual).items;
      expect((q.visuals.single as QueueVisual).flag, isFalse);
      final m = RegExp('^مين (\\S+) من (اليمين|الشمال)؟').firstMatch(q.ask);
      if (m != null) {
        final k = ['الأول', 'التاني', 'التالت', 'الرابع', 'الخامس'].indexOf(m[1]!);
        expect(q.answer, m[2] == 'اليمين' ? row[k] : row[row.length - 1 - k]);
      }
      expect(q.ask, isNot(contains('على الشمال')), reason: 'على شمال الدب');
      final next = RegExp('^مين على (يمين|شمال) ').firstMatch(q.ask);
      if (next != null) {
        final i = row.indexOf(q.answer as String);
        // اللي على يمين حاجة هو اللي قبلها في الصف
        final of = next[1] == 'يمين' ? row[i + 1] : row[i - 1];
        expect(q.ask, contains(q.choiceSay[of] ?? '—'), reason: q.ask);
      }
    }
  });

  test('three numbers: the answer is the sum worked left to right, never below zero', () {
    final r = Rng.seeded(4);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = threeNumbers(lv, r);
        final parts = (q.visuals.single as ExprVisual).parts;
        final a = (parts[0] as ExprTile).value as int, b = (parts[2] as ExprTile).value as int, c = (parts[4] as ExprTile).value as int;
        final o1 = (parts[1] as ExprOp).op, o2 = (parts[3] as ExprOp).op;
        final mid = o1 == '+' ? a + b : a - b;
        expect(mid, greaterThanOrEqualTo(0));
        expect(q.answer, o2 == '+' ? mid + c : mid - c);
        expect(q.answer as int, inInclusiveRange(0, lv <= 2 ? 10 : 20));
        expect(q.clips!.every((k) => k != null), isTrue, reason: 'numbers up to 20 have clips');
        if (lv == 1) expect([o1, o2], ['+', '+']);
      }
    }
  });

  test('rounding goes up from five', () {
    final r = Rng.seeded(6);
    for (var i = 0; i < 300; i++) {
      final q = rounding(2, r);
      final shown = (q.visuals.single as BigLetterVisual).text;
      final n = int.parse(shown.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join());
      expect(q.answer, ar(n % 10 >= 5 ? (n ~/ 10 + 1) * 10 : n ~/ 10 * 10), reason: shown);
    }
  });

  test('hundreds: numbers are three digits and the place answers match', () {
    final r = Rng.seeded(8);
    for (var i = 0; i < 300; i++) {
      final q = hundreds(2, r);
      if (q.visuals.isEmpty || q.visuals.single is! BigLetterVisual || q.ask.contains('اكتب')) continue;
      final text = (q.visuals.single as BigLetterVisual).text;
      final n = int.parse(text.split('').map((d) => '٠١٢٣٤٥٦٧٨٩'.indexOf(d)).join());
      expect(n, inInclusiveRange(100, 999));
      final digit = q.ask.contains('مية') ? n ~/ 100 : (q.ask.contains('عشرة') ? n ~/ 10 % 10 : n % 10);
      expect(q.answer, digit, reason: '$n ${q.ask}');
    }
  });

  test('bar graphs use the scale and their values sit on the grid', () {
    final r = Rng.seeded(10);
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 100; i++) {
        final v = barGraph(lv, r).visuals.single as BarGraphVisual;
        for (final (_, n) in v.rows) {
          expect(n % v.scale, 0);
        }
        if (lv == 1) expect(v.scale, 1);
      }
    }
  });

  test('children who already passed the stages before them find the new ones open', () {
    final p = ProgressData(best: {'wordProblem': 2, 'add100': 3, 'ar_al': 2});
    for (final id in ['position', 'hundreds', 'ar_far']) {
      expect(p.isUnlocked(id), isTrue, reason: id);
    }
    expect(p.isUnlocked('threeNumbers'), isFalse, reason: 'opens after position, in order');
  });

  test('shape figures: the parts text matches the pieces, and pieces apart are the same pieces', () {
    for (final (pieces, _, parts) in composeFigures) {
      final tri = pieces.where((p) => p.length == 3).length, sq = pieces.where((p) => p.length == 4).length;
      final words = {'مثلثين': (2, 0), '٤ مثلثات': (4, 0), 'مربعين': (0, 2), '٣ مربعات': (0, 3), 'مربع ومثلث': (1, 1)};
      expect(words[parts], (tri, sq), reason: parts);
    }
    final r = Rng.seeded(14);
    for (var i = 0; i < 200; i++) {
      final q = composeShapes(3, r);
      final v = q.visuals.single as ComposeVisual;
      if (q.ask.startsWith('كام')) expect(q.answer, v.pieces.length);
      expect(v.apart, q.ask.startsWith('القطع'));
    }
  });
}
