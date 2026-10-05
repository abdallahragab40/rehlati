import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/math_data.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// كل مولّد × كل مستوى × ٥٠٠ سؤال: الإجابة لازم تكون ممكنة دايمًا.
void main() {
  final playable = packs.values.where((s) => s.gen != null).toList();

  test('registry has the same stage counts as the web app', () {
    expect(worldStages['math']!.length, 11);
    expect(worldStages['arabic']!.length, 11);
    expect(worldStages['english']!.length, 14);
  });

  for (final stage in playable) {
    test('${stage.id} always produces solvable questions', () {
      final r = Rng.seeded(stage.id.hashCode);
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 500; i++) {
          final q = stage.gen!(lv, r);
          _checkSolvable(q, lv, stage.id);
        }
      }
    });
  }

  test('math numbers stay inside level bounds', () {
    final r = Rng.seeded(7);
    for (var lv = 1; lv <= 4; lv++) {
      final l = levelSpec(lv);
      for (var i = 0; i < 500; i++) {
        final add = packs['addition']!.gen!(lv, r);
        expect(add.answer as int, lessThanOrEqualTo(l.sumMax));
        final sub = packs['subtraction']!.gen!(lv, r);
        expect(sub.answer as int, greaterThanOrEqualTo(1));
        final asc = packs['ascending']!.gen!(lv, r);
        for (final v in asc.items) {
          expect(v as int, inInclusiveRange(1, l.max));
        }
      }
    }
  });

  test('adaptive focus steers the question', () {
    final r = Rng.seeded(1);
    final add = packs['addition']!.gen!(2, r, focus: '7+2');
    expect(add.skill, startsWith('add:7+'));
    final pick = packs['ar_pick']!.gen!(1, r, focus: 'ب');
    expect(pick.answer, 'ب');
    final pairs = packs['en_pairs']!.gen!(1, r, focus: 'D');
    expect(pairs.items, contains('D'));
  });
}

void _checkSolvable(Question q, int lv, String id) {
  final reason = '$id lv$lv ${q.ask}';
  switch (q.mode) {
    case QMode.choice:
      expect(q.choices, contains(q.answer), reason: reason);
      expect(q.choices.toSet().length, q.choices.length, reason: '$reason: duplicate choices');
      expect(q.choices.length, greaterThanOrEqualTo(2), reason: reason);
    case QMode.order:
    case QMode.grid:
      final bank = [...q.items];
      for (final a in q.answerList) {
        expect(bank.remove(a), isTrue, reason: '$reason: $a missing from bank');
      }
      expect(bank.length, lessThanOrEqualTo(1), reason: '$reason: at most one distractor');
      if (q.mode == QMode.grid) {
        final table = q.visuals.whereType<TableVisual>().single;
        expect(table.cells.where((c) => c == null).length, q.answerList.length, reason: reason);
      }
    case QMode.pairs:
      expect(q.items.length, q.right.length, reason: reason);
      for (final l in q.items) {
        expect(q.right, contains(q.pairMap[l]), reason: reason);
      }
    case QMode.find:
      expect(q.cells.where((c) => c.hit).length, q.hits, reason: reason);
    case QMode.memory:
      expect(q.cards.length, q.pairs * 2, reason: reason);
      final keys = <String, int>{};
      for (final c in q.cards) {
        keys[c.key] = (keys[c.key] ?? 0) + 1;
      }
      expect(keys.values.every((v) => v == 2), isTrue, reason: reason);
  }
}
