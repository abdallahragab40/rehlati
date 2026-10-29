import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/math_data.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// كل مولّد × كل مستوى × ٥٠٠ سؤال: الإجابة لازم تكون ممكنة دايمًا.
void main() {
  // كل مرحلة، وكل نوع لعبة مدود لوحده (اللي "تدريب على الأخطاء" بيستخدمه)
  final types = [
    for (final s in packs.values.where((s) => !s.isLearn)) ...[
      s.id,
      if (s.madd != null) for (final k in s.madd!.kinds) '${s.id}:$k',
    ],
  ];

  test('registry includes the primary expansion stages', () {
    expect(worldStages['math']!.length, 13 + 5 + 5 + 3 + 4, reason: 'with neighbors and emptyTable, plus numbers to 100, times tables, money/time, division and fractions');
    expect(worldStages['arabic']!.length, 11 + 9 + (voiceEnabled ? 3 + 4 : 2 + 3) + 6,
        reason: '11 + 9 madd stages + harakat + sukun and tanween + grammar');
    expect(worldStages['english']!.length, 14 + 7, reason: 'plus primary English');
    expect(worldStages['games']!.length, voiceEnabled ? 12 : 11, reason: 'listenNum needs the voice');
  });

  for (final type in types) {
    test('$type always produces solvable questions', () {
      final r = Rng.seeded(type.hashCode);
      final p = ProgressData();
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 500; i++) {
          _checkSolvable(makeQuestion(type, lv, r, progress: p), lv, type);
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
    final p = ProgressData();
    final add = makeQuestion('addition', 2, r, focus: '7+2', progress: p);
    expect(add.skill, startsWith('add:7+'));
    final pick = makeQuestion('ar_pick', 1, r, focus: 'ب', progress: p);
    expect(pick.answer, 'ب');
    final pairs = makeQuestion('en_pairs', 1, r, focus: 'D', progress: p);
    expect(pairs.items, contains('D'));
    final madd = makeQuestion('madd_types:type', 2, r, focus: 'waw', progress: p);
    expect(madd.mtype, 'waw');
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
      expect(bank.length, lessThanOrEqualTo(3), reason: '$reason: at most three distractors');
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
    case QMode.read:
      expect(q.yes, isNotNull, reason: reason);
      expect(q.visuals, isNotEmpty, reason: reason);
    case QMode.sort:
      final boxKeys = q.boxes.map((b) => b.key).toSet();
      expect(q.sortCards.every((c) => boxKeys.contains(c.type)), isTrue, reason: reason);
      expect(q.sortCards.map((c) => c.type).toSet(), boxKeys, reason: '$reason: every box used');
      // صناديق أنواع المد: البطاقات مختلفة (في الممدود/المد ممكن ألف تتكرر — زي الويب)
      if (q.skill == 'madd:sort') {
        expect(q.sortCards.map((c) => c.text).toSet().length, q.sortCards.length, reason: '$reason: unique cards');
      }
    case QMode.memory:
      expect(q.cards.length, q.pairs * 2, reason: reason);
      final keys = <String, int>{};
      for (final c in q.cards) {
        keys[c.key] = (keys[c.key] ?? 0) + 1;
      }
      expect(keys.values.every((v) => v == 2), isTrue, reason: reason);
    case QMode.balloon:
      expect(q.choices, contains(q.answer), reason: reason);
      expect(q.choices.toSet().length, q.choices.length, reason: '$reason: duplicate balloons');
      expect(q.choices.length, inInclusiveRange(4, 6), reason: reason);
    case QMode.color:
      final used = q.paintCells.toSet();
      expect(q.paintCells.length % q.paintCols, 0, reason: '$reason: full rows');
      expect(q.pots.map((p) => p.n).toSet(), used, reason: '$reason: a pot for every number');
    case QMode.rhythm:
      final pads = q.pads.map((p) => p.k).toSet();
      expect(q.beats, isNotEmpty, reason: reason);
      expect(q.beats.every(pads.contains), isTrue, reason: '$reason: every beat has a pad');
  }
}
