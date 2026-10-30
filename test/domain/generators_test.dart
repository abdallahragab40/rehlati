import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/math_data.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/generators/puzzle_generators.dart';
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

  test('registry has every world and the expected stage counts', () {
    expect(worldStages['math']!.length, 13 + 12 + 5 + 3 + 5 + 3 + 4, reason: 'basics, numbers to 100, grade 2, times tables, money/time, division');
    expect(worldStages['arabic']!.length, 11 + 2 + 2 + 9 + 1 + 1 + 1 + (voiceEnabled ? 3 + 4 : 2 + 3) + 3 + 10 + 6,
        reason: 'letters, concepts, forms, madd, short sentences, shadda, sun/moon letters, harakat, sukun, fading marks, grade 2 grammar, grammar');
    expect(worldStages['english']!.length, 14 + (voiceEnabled ? 3 : 0) + 5 + 15 + 7, reason: 'phonics needs the voice; 15 from the school books');
    expect(worldStages['games']!.length, voiceEnabled ? 12 + 13 + 4 : 11 + 12 + 4, reason: 'listenNum and animalSound need the voice');
    expect([for (final w in ['deen', 'discover', 'write']) worldStages[w]!.length], [8, 5, 5]);
    expect({for (final w in worlds) w.id}, {...worldStages.keys, 'quran'});
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
    case QMode.cups:
      expect(q.cupCount, inInclusiveRange(3, 4), reason: reason);
      expect(q.catCup, inInclusiveRange(0, q.cupCount - 1), reason: reason);
      expect(q.cupSwaps, greaterThan(0), reason: reason);
    case QMode.maze:
      // كل الخانات متوصّلة، والحيطان متطابقة من الناحيتين
      final n = q.mazeSize, seen = {q.mazeStart}, todo = [q.mazeStart];
      while (todo.isNotEmpty) {
        final c = todo.removeLast();
        for (final (bit, back, d) in [(mazeN, mazeS, -n), (mazeS, mazeN, n), (mazeE, mazeW, 1), (mazeW, mazeE, -1)]) {
          if (q.mazeWalls[c] & bit != 0) continue;
          final to = c + d;
          expect(q.mazeWalls[to] & back, 0, reason: '$reason: one-sided wall');
          if (seen.add(to)) todo.add(to);
        }
      }
      expect(seen.length, n * n, reason: '$reason: every cell reachable');
      expect(seen, contains(q.mazeGoal), reason: reason);
    case QMode.trace:
      expect(q.trace, isNotEmpty, reason: reason);
    case QMode.sudoku:
      final n = q.gridSize;
      expect(q.solution.length, n * n, reason: reason);
      // الحل صح: كل صف وعمود ومربع فيه ١…n مرة واحدة
      final all = {for (var v = 1; v <= n; v++) v};
      for (var k = 0; k < n; k++) {
        expect({for (var c = 0; c < n; c++) q.solution[k * n + c]}, all, reason: '$reason: row $k');
        expect({for (var r = 0; r < n; r++) q.solution[r * n + k]}, all, reason: '$reason: column $k');
      }
      for (var b = 0; b < n; b++) {
        final r0 = b ~/ (n ~/ q.boxCols) * q.boxRows, c0 = b % (n ~/ q.boxCols) * q.boxCols;
        expect({
          for (var a = 0; a < q.boxRows; a++)
            for (var c = 0; c < q.boxCols; c++) q.solution[(r0 + a) * n + c0 + c],
        }, all, reason: '$reason: box $b');
      }
      final puzzle = [for (var i = 0; i < n * n; i++) q.givens[i] ? q.solution[i] : 0];
      expect(sudokuSolutions(puzzle, n, q.boxRows, q.boxCols), 1, reason: '$reason: one solution');
      expect(q.symbols.length, n, reason: reason);
    case QMode.hanoi:
      expect(q.discs, inInclusiveRange(2, 4), reason: reason);
    case QMode.slide:
      final n = q.slideSize;
      expect([...q.slideStart]..sort(), [for (var i = 0; i < n * n; i++) i], reason: reason);
      expect(q.slideStart, isNot([for (var i = 1; i < n * n; i++) i, 0]), reason: '$reason: already solved');
  }
  if (q.look == ChoiceLook.picName) {
    expect(q.items.every(q.choiceSay.containsKey), isTrue, reason: '$reason: every step has a name');
  }
}
