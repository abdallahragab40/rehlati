/// ألغاز للكبار في عالم الألعاب (٦–١٢ سنة): سودوكو، برج هانوي، البازل المنزلق، وكمّل المتتالية.
library;

import 'dart:math' as math;

import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

// ---------------------------------------------------------------- 🔢 سودوكو

const sudokuPics = ['🍎', '🍌', '🍇', '🍓'];

/// عدد حلول الشبكة (بيقف عند ٢) — عشان نشيل خانات والحل يفضل واحد بس.
int sudokuSolutions(List<int> cells, int n, int br, int bc, {int limit = 2}) {
  final g = [...cells];
  var found = 0;
  bool ok(int i, int v) {
    final row = i ~/ n, col = i % n;
    for (var k = 0; k < n; k++) {
      if (g[row * n + k] == v || g[k * n + col] == v) return false;
    }
    final r0 = row - row % br, c0 = col - col % bc;
    for (var a = 0; a < br; a++) {
      for (var b = 0; b < bc; b++) {
        if (g[(r0 + a) * n + c0 + b] == v) return false;
      }
    }
    return true;
  }

  void solve(int from) {
    if (found >= limit) return;
    final i = g.indexOf(0, from);
    if (i < 0) {
      found++;
      return;
    }
    for (var v = 1; v <= n; v++) {
      if (ok(i, v)) {
        g[i] = v;
        solve(i + 1);
        g[i] = 0;
      }
    }
  }

  solve(0);
  return found;
}

/// ٤×٤ بصور في الأول، وبعدين بأرقام وخانات أقل، و٦×٦ في الآخر. الحل دايمًا واحد بس.
Question sudoku(int lv, Rng r, {String? focus}) {
  final big = lv >= 4;
  final n = big ? 6 : 4, br = 2, bc = big ? 3 : 2;
  // شبكة صح من النمط المعروف، وبعدين خلط الأرقام والصفوف والأعمدة جوه حدودها
  final digits = r.shuffle([for (var v = 1; v <= n; v++) v]);
  List<int> order(int groups, int size) => [
        for (final g in r.shuffle([for (var i = 0; i < groups; i++) i]))
          for (final k in r.shuffle([for (var i = 0; i < size; i++) i])) g * size + k,
      ];
  final rows = order(n ~/ br, br), cols = order(n ~/ bc, bc);
  final solution = [
    for (final row in rows)
      for (final col in cols) digits[(bc * (row % br) + row ~/ br + col) % n],
  ];
  final remove = switch (lv) { <= 2 => 6, 3 => 9, _ => 18 };
  final puzzle = [...solution];
  var removed = 0;
  for (final i in r.shuffle([for (var i = 0; i < n * n; i++) i])) {
    if (removed >= remove) break;
    final keep = puzzle[i];
    puzzle[i] = 0;
    if (sudokuSolutions(puzzle, n, br, bc) == 1) {
      removed++;
    } else {
      puzzle[i] = keep;
    }
  }
  final pics = lv <= 2;
  return Question(
    type: 'sudoku', mode: QMode.sudoku, skill: 'sudoku:$n', numeric: false,
    ask: pics ? 'كمّل السودوكو بالصور' : 'كمّل السودوكو',
    speak: 'كل صف وكل عمود وكل مربع فيه كل ${pics ? 'صورة' : 'رقم'} مرة واحدة بس',
    gridSize: n, boxRows: br, boxCols: bc, solution: solution,
    givens: [for (final v in puzzle) v != 0],
    symbols: pics ? sudokuPics : [for (var v = 1; v <= n; v++) ar(v)],
    hint: 'اختار خانة فاضية، وبعدين اللي مش موجود في صفها وعمودها ومربعها 👀',
    speakHint: 'دوّر على اللي مش موجود في الصف والعمود والمربع',
    okMsg: '🔢 سودوكو كامل!',
  );
}

// ---------------------------------------------------------------- 🗼 برج هانوي

/// انقل البرج كله للعمود الأخير، حلقة حلقة، والكبيرة ماتقعدش على الصغيرة.
Question hanoi(int lv, Rng r, {String? focus}) {
  final n = switch (lv) { <= 1 => 2, 4 => 4, _ => 3 };
  return Question(
    type: 'hanoi', mode: QMode.hanoi, skill: 'hanoi:$n', numeric: false,
    ask: 'انقل البرج للعمود اللي عليه 🏁', speak: 'انقل البرج كله للعمود التالت، حلقة واحدة كل مرة',
    discs: n,
    hint: 'اضغط عمود تشيل منه، وبعدين عمود تحط فيه 🗼',
    speakHint: 'الحلقة الكبيرة ماتقعدش على الصغيرة',
    okMsg: '🗼 البرج اتنقل!',
  );
}

/// أقل عدد حركات ممكن لبرج من [discs] حلقات.
int hanoiBest(int discs) => (1 << discs) - 1;

// ---------------------------------------------------------------- 🔲 البازل المنزلق

/// ٣×٣ فيها خانة فاضية: الأرقام بتتلخبط بحركات حقيقية من الحل (فدايمًا ليها حل)،
/// والحركات بتزيد مع المستوى.
Question slide(int lv, Rng r, {String? focus}) {
  const n = 3;
  final moves = switch (lv) { <= 2 => 6, 3 => 14, _ => 30 };
  final tiles = [for (var i = 1; i < n * n; i++) i, 0];
  var blank = n * n - 1, prev = -1;
  final solved = [...tiles];
  for (var k = 0; k < moves || _same(tiles, solved); k++) {
    final row = blank ~/ n, col = blank % n;
    final next = [
      if (row > 0) blank - n,
      if (row < n - 1) blank + n,
      if (col > 0) blank - 1,
      if (col < n - 1) blank + 1,
    ]..remove(prev);
    final to = r.sample(next);
    tiles[blank] = tiles[to];
    tiles[to] = 0;
    prev = blank;
    blank = to;
  }
  return Question(
    type: 'slide', mode: QMode.slide, skill: 'slide:$lv', numeric: false,
    ask: 'رتّب الأرقام من ${ar(1)} لـ ${ar(8)}', speak: 'زحلق الأرقام للخانة الفاضية لحد ما تترتب من واحد لتمانية',
    slideSize: n, slideStart: tiles,
    hint: 'اضغط رقم جنب الخانة الفاضية عشان يتزحلق 👆', speakHint: 'اضغط رقم جنب الخانة الفاضية',
    okMsg: '🔲 الأرقام اترتبت!',
  );
}

bool _same(List<int> a, List<int> b) => [for (var i = 0; i < a.length; i++) a[i] == b[i]].every((x) => x);

// ---------------------------------------------------------------- ➡️ كمّل المتتالية

/// قاعدة المتتالية بتصعب: نفس الزيادة ← نقصان وزيادات أكبر ← ضرب في ٢ وزيادة بتكبر.
/// الأرقام لحد ١٠٠ عشان كلها ليها صوت مسجّل.
Question numberSeq(int lv, Rng r, {String? focus}) {
  const len = 5;
  final List<int> seq;
  final String rule, hint;
  final kind = lv <= 2 ? 'add' : (lv == 3 ? r.sample(const ['add', 'sub']) : r.sample(const ['add', 'sub', 'double', 'grow']));
  switch (kind) {
    case 'sub':
      final d = r.sample(const [2, 3, 4, 5, 10]);
      final start = r.rnd(d * (len - 1) + 1, math.min(100, d * (len - 1) + 30));
      seq = [for (var i = 0; i < len; i++) start - i * d];
      rule = 'sub:$d';
      hint = 'بننقّص ${ar(d)} كل مرة ⬇️';
    case 'double':
      final start = r.rnd(1, 6);
      seq = [for (var i = 0; i < len; i++) start << i];
      rule = 'double';
      hint = 'كل رقم = اللي قبله × ٢ ✖️';
    case 'grow':
      final start = r.rnd(1, 10);
      seq = [start];
      for (var i = 1; i < len; i++) {
        seq.add(seq.last + i);
      }
      rule = 'grow';
      hint = 'الزيادة بتكبر واحد كل مرة: +١، +٢، +٣… 📈';
    default:
      final d = lv <= 2 ? r.sample(const [1, 2, 5, 10]) : r.sample(const [3, 4, 6, 9, 11]);
      final start = r.rnd(1, math.max(1, math.min(20, 100 - d * (len - 1))));
      seq = [for (var i = 0; i < len; i++) start + i * d];
      rule = 'add:$d';
      hint = 'بنزوّد ${ar(d)} كل مرة ⬆️';
  }
  final hole = lv <= 2 ? len - 1 : r.rnd(1, len - 1);
  final a = seq[hole];
  final parts = <ExprPart>[];
  for (var i = 0; i < len; i++) {
    if (i > 0) parts.add(const ExprOp('•', separator: true));
    parts.add(ExprTile(i == hole ? null : seq[i]));
  }
  final step = (seq[1] - seq[0]).abs();
  final wrong = <int>{for (final w in [a + 1, a - 1, a + step, a - step, a + 2]) if (w > 0 && w <= 100 && w != a) w};
  return Question(
    type: 'numberSeq', mode: QMode.choice, skill: 'nseq:$rule',
    ask: 'كمّل المتتالية', speak: 'اكتشف القاعدة، وقول إيه الرقم الناقص',
    visuals: [ExprVisual(parts)],
    choices: r.shuffle([a, ...r.shuffle(wrong.toList()).take(3)]), answer: a,
    hint: hint, speakHint: 'اكتشف القاعدة الأول، وبعدين كمّل',
  );
}
