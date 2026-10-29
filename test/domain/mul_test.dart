import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/mul_generators.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// جدول الضرب: كل مرحلة بتسأل من جداولها بس، والناتج صح دايمًا.
void main() {
  List<int?> tiles(Question q) => [
        for (final p in (q.visuals.single as ExprVisual).parts)
          if (p case ExprTile(:final value)) value as int?,
      ];

  test('equal groups: the answer is groups × each, and adding the two is offered as a trap', () {
    final r = Rng.seeded(31);
    var traps = 0;
    for (var lv = 1; lv <= 4; lv++) {
      for (var i = 0; i < 300; i++) {
        final q = mulGroups(lv, r);
        final v = q.visuals.single as GroupsVisual;
        expect(q.answer, v.groups * v.each);
        expect(v.groups, inInclusiveRange(2, lv <= 2 ? 3 : 4));
        if (q.choices.contains(v.groups + v.each) && v.groups + v.each != q.answer) traps++;
      }
    }
    expect(traps, greaterThan(600));
  });

  final tables = {
    'times2510': {2, 5, 10},
    'times34': {3, 4},
    'times6789': {6, 7, 8, 9},
    'timesAll': {2, 3, 4, 5, 6, 7, 8, 9, 10},
  };
  for (final MapEntry(key: id, value: own) in tables.entries) {
    test('$id asks only its own tables, with a right answer every time', () {
      final r = Rng.seeded(id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 400; i++) {
          final q = packs[id]!.gen!(lv, r);
          final [x, y, p] = tiles(q).where((v) => true).toList();
          final table = int.parse(q.skill!.split(':')[1]);
          expect(own, contains(table));
          if (y == null) {
            // العامل الناقص: المستوى الرابع بس
            expect(lv, 4);
            expect(x! * (q.answer as int), p);
            expect(q.answer, inInclusiveRange(1, 10));
          } else {
            expect(p, isNull);
            expect(q.answer, x! * y);
            expect({x, y}, contains(table));
            if (lv <= 2) expect([x, y].reduce((a, b) => a == table ? b : a), lessThanOrEqualTo(5));
          }
          expect(q.choices.toSet().length, q.choices.length);
          expect(q.choices, contains(q.answer));
          expect(q.choices.cast<int>(), everyElement(inInclusiveRange(1, 100)));
        }
      }
    });
  }

  test('adaptive focus asks the weak table', () {
    final r = Rng.seeded(32);
    for (var i = 0; i < 50; i++) {
      expect(times6789(3, r, focus: '7').skill, 'times:7');
    }
  });

  test('times tables open after skip counting and sit at the end of the maths world', () {
    final ids = [for (final s in worldStages['math']!) s.id];
    expect(ids.sublist(18), ['mulGroups', 'times2510', 'times34', 'times6789', 'timesAll']);
    expect(packs['mulGroups']!.after, 'skipCount');
  });
}
