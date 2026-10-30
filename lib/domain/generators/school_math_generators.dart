/// دروس الحساب اللي مكانتش في التطبيق (أولى وتانية، الترم الأول — tool/SCHOOL_CURRICULUM_INDEX.md):
/// الموقع (من اليمين والشمال)، العمليات بثلاثة أعداد، التقريب والتقدير، الأعداد لحد ١٠٠٠،
/// والتمثيل بالأعمدة بمقياس.
///
/// الأعداد الكبيرة مش بتتنطق رقم رقم (مفيش مقطع لكل عدد): السؤال بيتقال، والعدد مكتوب قدام الطفل.
library;

import 'dart:math' as math;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

const _ordinals = ['الأول', 'التاني', 'التالت', 'الرابع', 'الخامس'];
const _animals = ['🐰', '🐢', '🦊', '🐻', '🐱', '🐶', '🐸', '🐵'];
const _animalNames = {
  '🐰': 'الأرنب', '🐢': 'السلحفاة', '🦊': 'التعلب', '🐻': 'الدب', '🐱': 'القطة', '🐶': 'الكلب', '🐸': 'الضفدع', '🐵': 'القرد',
};

List<T> _pick<T>(Rng r, List<T> pool, int n) => r.shuffle([...pool]).take(n).toList();

// ---------------------------------------------------------------- الموقع

/// صف حيوانات من غير علم: «مين التالت من اليمين؟»، «الدب رقم كام من الشمال؟»،
/// ومن المستوى التاني «مين على يمين القطة؟». أول عنصر في الصف هو اللي على اليمين.
Question position(int lv, Rng r, {String? focus}) {
  final n = lv <= 1 ? 4 : 5;
  final row = _pick(r, _animals, n);
  final fromRight = r.chance(.5);
  final side = fromRight ? 'اليمين' : 'الشمال';
  // مكان العنصر من الناحية المطلوبة (٠ = الأول)
  int fromSide(int i) => fromRight ? i : n - 1 - i;
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 2);
  final names = {for (final e in row) e: _animalNames[e]!};
  if (kind == 2) {
    // الجار: على يمين العنصر = اللي قبله في الصف، وعلى شماله = اللي بعده
    final i = fromRight ? r.rnd(1, n - 1) : r.rnd(0, n - 2);
    final answer = row[fromRight ? i - 1 : i + 1];
    // «على يمين الدب» من غير «ال»
    final ask = 'مين على ${fromRight ? 'يمين' : 'شمال'} ${names[row[i]]}؟';
    return Question(
      type: 'position', mode: QMode.choice, skill: 'pos:next$side', numeric: false, bigChoices: true,
      ask: ask, speak: ask,
      visuals: [QueueVisual(row, flag: false)],
      choices: r.shuffle(row.where((e) => e != row[i]).toList()), answer: answer,
      choiceSay: names,
      hint: 'دوّر على ${names[row[i]]} وبص على ناحية $side 👀', speakHint: 'دور عليه وبص ناحية $side',
    );
  }
  final i = r.rnd(0, n - 1);
  final k = fromSide(i);
  if (kind == 1) {
    final ask = '${names[row[i]]} رقم كام من $side؟';
    return Question(
      type: 'position', mode: QMode.choice, skill: 'pos:$side$k', numeric: false,
      ask: ask, speak: ask,
      visuals: [QueueVisual(row, flag: false)],
      choices: r.shuffle(_ordinals.take(n).toList()), answer: _ordinals[k],
      hint: 'ابدأ العد من ناحية $side 👉', speakHint: 'ابدأ العد من ناحية $side',
    );
  }
  final ask = 'مين ${_ordinals[k]} من $side؟';
  return Question(
    type: 'position', mode: QMode.choice, skill: 'pos:$side$k', numeric: false, bigChoices: true,
    ask: ask, speak: ask,
    visuals: [QueueVisual(row, flag: false)],
    choices: r.shuffle([...row]), answer: row[i],
    choiceSay: names,
    hint: 'ابدأ العد من ناحية $side 👉', speakHint: 'ابدأ العد من ناحية $side',
  );
}

// ---------------------------------------------------------------- ثلاثة أعداد

/// جمع وطرح ثلاثة أعداد بالترتيب من الشمال لليمين في الحساب. المستوى الأول جمع بس لحد ١٠،
/// وبعده جمع وطرح، ومن المستوى التالت لحد ٢٠. الجملة بتتقال من مقاطع الأعداد.
Question threeNumbers(int lv, Rng r, {String? focus}) {
  final max = lv <= 2 ? 10 : 20;
  final kind = lv <= 1 ? '++' : r.sample(const ['++', '+-', '--']);
  late int a, b, c;
  switch (kind) {
    case '++':
      a = r.rnd(1, max - 2);
      b = r.rnd(1, max - a - 1);
      c = r.rnd(1, max - a - b);
    case '+-':
      a = r.rnd(1, max - 1);
      b = r.rnd(1, max - a);
      c = r.rnd(1, a + b);
    default:
      a = r.rnd(3, max);
      b = r.rnd(1, a - 2);
      c = r.rnd(1, a - b);
  }
  final mid = kind[0] == '+' ? a + b : a - b;
  final ans = kind[1] == '+' ? mid + c : mid - c;
  String sym(String o) => o == '+' ? '+' : '−';
  String word(String o) => o == '+' ? 'زائد' : 'ناقص';
  const tail = 'يساوي كام؟';
  const hint = 'احسب أول عددين، وبعدين كمّل بالتالت';
  return Question(
    type: 'threeNumbers', mode: QMode.choice, skill: 'three:$kind',
    ask: '${ar(a)} ${sym(kind[0])} ${ar(b)} ${sym(kind[1])} ${ar(c)} = ؟',
    speak: '${arNum(a)} ${word(kind[0])} ${arNum(b)} ${word(kind[1])} ${arNum(c)} $tail',
    clips: [nk(a), say(word(kind[0])), nk(b), say(word(kind[1])), nk(c), say(tail)],
    visuals: [
      ExprVisual([
        ExprTile(a), ExprOp(sym(kind[0])), ExprTile(b), ExprOp(sym(kind[1])), ExprTile(c),
        const ExprOp('='), const ExprTile(null),
      ]),
    ],
    choices: r.numberChoices(ans, lv <= 1 ? 3 : 4, 0, max), answer: ans,
    hint: '$hint: ${ar(mid)} ${sym(kind[1])} ${ar(c)} ☝️',
    speakHint: hint, clipsHint: [say(hint)],
  );
}

// ---------------------------------------------------------------- التقريب والتقدير

int _roundTen(int n) => (n + 5) ~/ 10 * 10;

/// قرّب لأقرب عشرة (لو الآحاد ٥ أو أكتر بنطلع)، ومن المستوى التالت: قدّر ناتج الجمع بالتقريب.
Question rounding(int lv, Rng r, {String? focus}) {
  if (lv >= 3 && r.chance(.5)) {
    int odd() {
      var n = r.rnd(11, 49);
      while (n % 10 == 0) {
        n = r.rnd(11, 49);
      }
      return n;
    }

    final a = odd(), b = odd();
    final ans = _roundTen(a) + _roundTen(b);
    const ask = 'قدّر الناتج: قرّب كل عدد لأقرب عشرة واجمع';
    return Question(
      type: 'rounding', mode: QMode.choice, skill: 'estimate', numeric: false,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [ExprVisual([ExprTile(a), const ExprOp('+'), ExprTile(b), const ExprOp('≈'), const ExprTile(null)])],
      choices: r.shuffle({ans, ans - 10, ans + 10, if (ans > 20) ans - 20}.take(lv >= 4 ? 4 : 3).map(ar).toList()),
      answer: ar(ans),
      choiceSay: {for (final v in {ans, ans - 10, ans + 10, ans - 20}) ar(v): ''},
      hint: '${ar(a)} تقريبًا ${ar(_roundTen(a))}، و${ar(b)} تقريبًا ${ar(_roundTen(b))} ☝️',
      speakHint: 'قرب كل عدد لأقرب عشرة، وبعدين اجمع',
      clipsHint: [say('قرب كل عدد لأقرب عشرة، وبعدين اجمع')],
    );
  }
  final hi = lv <= 1 ? 49 : 99;
  var n = r.rnd(11, hi);
  while (n % 10 == 0) {
    n = r.rnd(11, hi);
  }
  final down = n ~/ 10 * 10, up = down + 10;
  final options = {down, up, if (lv >= 2) (up + 10 <= 100 ? up + 10 : down - 10)};
  const ask = 'قرّب العدد ده لأقرب عشرة';
  return Question(
    type: 'rounding', mode: QMode.choice, skill: 'round:${n % 10 >= 5 ? 'up' : 'down'}', numeric: false,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [BigLetterVisual(ar(n))],
    choices: r.shuffle(options.map(ar).toList()), answer: ar(_roundTen(n)),
    choiceSay: {for (final v in options) ar(v): ''},
    hint: 'بص على الآحاد: ٥ أو أكتر نطلع لـ ${ar(up)}، وأقل من ٥ ننزل لـ ${ar(down)} ☝️',
    speakHint: 'بص على الآحاد: خمسة أو أكتر نطلع، وأقل من خمسة ننزل',
    clipsHint: [say('بص على الآحاد: خمسة أو أكتر نطلع، وأقل من خمسة ننزل')],
  );
}

// ---------------------------------------------------------------- الأعداد لحد ١٠٠٠

const _arUnits = ['', 'واحد', 'اثنان', 'ثلاثة', 'أربعة', 'خمسة', 'ستة', 'سبعة', 'ثمانية', 'تسعة'];
const _arTeens = [
  'عشرة', 'أحد عشر', 'اثنا عشر', 'ثلاثة عشر', 'أربعة عشر', 'خمسة عشر', 'ستة عشر', 'سبعة عشر', 'ثمانية عشر', 'تسعة عشر',
];
const _arTens = ['', '', 'عشرون', 'ثلاثون', 'أربعون', 'خمسون', 'ستون', 'سبعون', 'ثمانون', 'تسعون'];
const _arHundreds = ['', 'مائة', 'مائتان', 'ثلاثمائة', 'أربعمائة', 'خمسمائة', 'ستمائة', 'سبعمائة', 'ثمانمائة', 'تسعمائة'];

/// الصيغة الكلامية زي كتاب تانية: ٣٤٥ ← ثلاثمائة وخمسة وأربعون (الآحاد قبل العشرات).
String arNumberWords(int n) {
  final h = n ~/ 100, rest = n % 100, t = rest ~/ 10, u = rest % 10;
  final restWords = switch (rest) {
    0 => '',
    < 10 => _arUnits[rest],
    < 20 => _arTeens[rest - 10],
    _ => u == 0 ? _arTens[t] : '${_arUnits[u]} و${_arTens[t]}',
  };
  if (h == 0) return restWords;
  return restWords.isEmpty ? _arHundreds[h] : '${_arHundreds[h]} و$restWords';
}

/// المئات والعشرات والآحاد، الصيغة الممتدة، والمقارنة، ومن المستوى التاني الصيغة الكلامية.
/// العدد مكتوب والسؤال بس اللي بيتقال.
Question hundreds(int lv, Rng r, {String? focus}) {
  // المستوى الأول عشرات كاملة (٣٤٠)، وبعده أي عدد من ١٠٠ لـ ٩٩٩
  final num = lv <= 1 ? r.rnd(10, 99) * 10 : r.rnd(100, 999);
  final h = num ~/ 100, t = num ~/ 10 % 10, o = num % 10;
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 3);
  if (kind == 3) {
    // الصيغة الكلامية: الغلط بنفس الأرقام في خانات تانية، أو مية زيادة أو ناقصة
    final wrong = {h * 100 + o * 10 + t, num + 100, num - 100, num + 10, num - 10}
      ..removeWhere((x) => x == num || x < 100 || x > 999 || (x % 100 ~/ 10 == x % 10 && x == h * 100 + o * 10 + t));
    final options = [num, ...r.shuffle(wrong.toList()).take(2)];
    final toWords = r.chance(.5);
    final ask = toWords ? 'اختار العدد ده مكتوب بالحروف' : 'العدد ده مكتوب بالأرقام إزاي؟';
    String show(int x) => toWords ? arNumberWords(x) : ar(x);
    return Question(
      type: 'hundreds', mode: QMode.choice, skill: 'words:${toWords ? 'out' : 'in'}', numeric: false, wide: true,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [BigLetterVisual(toWords ? ar(num) : arNumberWords(num))],
      choices: r.shuffle(options.map(show).toList()), answer: show(num),
      choiceSay: {for (final x in options) show(x): ''},
      hint: 'ابدأ بالمئات، وبعدين الآحاد، وفي الآخر العشرات: ${arNumberWords(num)} ☝️',
      speakHint: 'ابدأ بالمئات، وبعدين الآحاد، وفي الآخر العشرات',
      clipsHint: [say('ابدأ بالمئات، وبعدين الآحاد، وفي الآخر العشرات')],
    );
  }
  if (kind == 0) {
    final (ask, answer) = r.sample([('العدد ده فيه كام مية؟', h), ('العدد ده فيه كام عشرة؟', t), ('العدد ده فيه كام آحاد؟', o)]);
    return Question(
      type: 'hundreds', mode: QMode.choice, skill: 'place:${ask.split(' ')[4]}',
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [BigLetterVisual(ar(num))],
      choices: r.numberChoices(answer, 4, 0, 9), answer: answer,
      hint: 'من الشمال: المئات، بعدها العشرات، وفي الآخر الآحاد ☝️',
      speakHint: 'المئات، بعدها العشرات، وفي الآخر الآحاد',
      clipsHint: [say('المئات، بعدها العشرات، وفي الآخر الآحاد')],
    );
  }
  if (kind == 1) {
    // الغلط: نفس الأرقام في خانات تانية، ولو مفيش (زي ١٠٠) أعداد قريبة
    final wrong = {h * 100 + o * 10 + t, t * 100 + h * 10 + o, h * 10 + t * 100 + o, num + 10, num - 10, num + 100, num - 100}
      ..removeWhere((x) => x == num || x < 100 || x > 999);
    final options = [num, ...wrong.take(2)];
    const ask = 'اكتب العدد: مئات وعشرات وآحاد';
    return Question(
      type: 'hundreds', mode: QMode.choice, skill: 'expanded', numeric: false,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [BigLetterVisual('${ar(h * 100)} + ${ar(t * 10)} + ${ar(o)}')],
      choices: r.shuffle(options.map(ar).toList()), answer: ar(num),
      choiceSay: {for (final v in options) ar(v): ''},
      hint: '${ar(h)} مئات و${ar(t)} عشرات و${ar(o)} آحاد ☝️',
      speakHint: 'المئات، بعدها العشرات، وفي الآخر الآحاد',
      clipsHint: [say('المئات، بعدها العشرات، وفي الآخر الآحاد')],
    );
  }
  var other = num;
  while (other == num) {
    // نفس المئات أحيانًا عشان المقارنة تبقى بالعشرات
    other = r.chance(.5) ? h * 100 + r.rnd(0, 99) : r.rnd(100, 999);
  }
  other = other.clamp(100, 999);
  if (other == num) other = num == 999 ? 998 : num + 1;
  final bigger = r.chance(.5);
  final ask = bigger ? 'أنهي عدد أكبر؟' : 'أنهي عدد أصغر؟';
  final answer = bigger ? math.max(num, other) : math.min(num, other);
  return Question(
    type: 'hundreds', mode: QMode.choice, skill: 'compare3', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask)],
    choices: r.shuffle([ar(num), ar(other)]), answer: ar(answer),
    choiceSay: {ar(num): '', ar(other): ''},
    hint: 'قارن المئات الأول، ولو زي بعض قارن العشرات ☝️',
    speakHint: 'قارن المئات الأول، ولو زي بعض قارن العشرات',
    clipsHint: [say('قارن المئات الأول، ولو زي بعض قارن العشرات')],
  );
}

// ---------------------------------------------------------------- التمثيل بالأعمدة

const _barKinds = [('🍎', 'التفاح'), ('🍌', 'الموز'), ('🍊', 'البرتقال'), ('🍇', 'العنب'), ('🍓', 'الفراولة')];

/// أعمدة بمقياس ١ أو ٢ أو ١٠ (زي كتاب تانية): كام؟ أنهي أكتر أو أقل؟ والفرق.
Question barGraph(int lv, Rng r, {String? focus}) {
  final scale = switch (lv) { <= 1 => 1, 2 => 2, _ => r.chance(.5) ? 2 : 10 };
  final kinds = _pick(r, _barKinds, lv <= 1 ? 3 : 4);
  final steps = _pick(r, [1, 2, 3, 4, 5, 6, 7, 8], kinds.length);
  final rows = [for (var i = 0; i < kinds.length; i++) (kinds[i].$1, steps[i] * scale)];
  final visual = BarGraphVisual(rows, scale);
  final names = {for (final k in kinds) k.$1: k.$2};
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 2);
  if (kind == 0) {
    final i = r.rnd(0, kinds.length - 1);
    final v = rows[i].$2;
    final ask = 'عدد ${kinds[i].$2} كام؟';
    final options = {v, v + scale, if (v > scale) v - scale, v + 2 * scale}.take(lv <= 1 ? 3 : 4).toList();
    return Question(
      type: 'barGraph', mode: QMode.choice, skill: 'bar:read$scale',
      ask: ask, speak: ask,
      visuals: [visual],
      choices: r.shuffle(options), answer: v,
      hint: 'امشي من فوق العمود لحد الأرقام اللي على الجنب، وكل خط = ${ar(scale)} 📊',
      speakHint: 'امشي من فوق العمود لحد الأرقام اللي على الجنب',
    );
  }
  if (kind == 1) {
    final most = r.chance(.5);
    final target = most ? rows.map((x) => x.$2).reduce(math.max) : rows.map((x) => x.$2).reduce(math.min);
    final it = rows.firstWhere((x) => x.$2 == target).$1;
    final ask = most ? 'أنهي فاكهة أكتر؟' : 'أنهي فاكهة أقل؟';
    return Question(
      type: 'barGraph', mode: QMode.choice, skill: 'bar:compare', numeric: false, bigChoices: true,
      ask: ask, speak: ask,
      visuals: [visual],
      choices: r.shuffle([for (final k in kinds) k.$1]), answer: it,
      choiceSay: names,
      hint: most ? 'العمود الأطول هو الأكتر 📊' : 'العمود الأقصر هو الأقل 📊',
      speakHint: most ? 'العمود الأطول هو الأكتر' : 'العمود الأقصر هو الأقل',
    );
  }
  final hi = rows.reduce((a, b) => a.$2 >= b.$2 ? a : b), lo = rows.reduce((a, b) => a.$2 <= b.$2 ? a : b);
  final diff = hi.$2 - lo.$2;
  final ask = '${names[hi.$1]} أكتر من ${names[lo.$1]} بكام؟';
  return Question(
    type: 'barGraph', mode: QMode.choice, skill: 'bar:diff$scale',
    ask: ask, speak: ask,
    visuals: [visual],
    choices: r.shuffle({diff, diff + scale, if (diff > scale) diff - scale, hi.$2}.take(4).toList()), answer: diff,
    hint: 'اطرح: ${ar(hi.$2)} − ${ar(lo.$2)} ➖', speakHint: 'اطرح العمود الصغير من الكبير',
  );
}

// ---------------------------------------------------------------- تكوين أشكال

/// شكل متكوّن من قطع: (القطع، اسم الشكل، القطع بالكلام). النقط على شبكة والـ y لفوق.
const composeFigures = [
  ([[(0.0, 0.0), (2.0, 0.0), (0.0, 2.0)], [(2.0, 0.0), (2.0, 2.0), (0.0, 2.0)]], 'مربع', 'مثلثين'),
  ([[(0.0, 0.0), (2.0, 0.0), (1.0, 1.0)], [(2.0, 0.0), (2.0, 2.0), (1.0, 1.0)], [(2.0, 2.0), (0.0, 2.0), (1.0, 1.0)], [(0.0, 2.0), (0.0, 0.0), (1.0, 1.0)]], 'مربع', '٤ مثلثات'),
  ([[(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)], [(2.0, 0.0), (4.0, 0.0), (4.0, 2.0), (2.0, 2.0)]], 'مستطيل', 'مربعين'),
  ([[(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)], [(2.0, 0.0), (4.0, 0.0), (4.0, 2.0), (2.0, 2.0)], [(4.0, 0.0), (6.0, 0.0), (6.0, 2.0), (4.0, 2.0)]], 'مستطيل', '٣ مربعات'),
  ([[(0.0, 0.0), (2.0, 0.0), (0.0, 2.0)], [(2.0, 0.0), (2.0, 2.0), (0.0, 2.0)], [(2.0, 0.0), (4.0, 0.0), (2.0, 2.0)], [(4.0, 0.0), (4.0, 2.0), (2.0, 2.0)]], 'مستطيل', '٤ مثلثات'),
  ([[(0.0, 0.0), (2.0, 0.0), (0.0, 2.0)], [(2.0, 0.0), (4.0, 0.0), (2.0, 2.0)], [(0.0, 2.0), (2.0, 2.0), (0.0, 4.0)], [(2.0, 0.0), (2.0, 2.0), (0.0, 2.0)]], 'مثلث', '٤ مثلثات'),
  ([[(0.0, 0.0), (2.0, 0.0), (2.0, 2.0)], [(2.0, 0.0), (4.0, 0.0), (2.0, 2.0)]], 'مثلث', 'مثلثين'),
  ([[(0.0, 0.0), (2.0, 0.0), (2.0, 2.0), (0.0, 2.0)], [(0.0, 2.0), (2.0, 2.0), (1.0, 3.3)]], 'بيت', 'مربع ومثلث'),
];

/// كام قطعة عملت الشكل؟ القطع دي تعمل أنهي شكل؟ ومن المستوى التاني: الشكل اتعمل من إيه؟
Question composeShapes(int lv, Rng r, {String? focus}) {
  final pool = lv <= 1 ? composeFigures.where((f) => f.$1.length <= 3).toList() : composeFigures;
  final (pieces, name, parts) = r.sample(pool);
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 2);
  if (kind == 0) {
    const ask = 'كام قطعة عملت الشكل ده؟';
    return Question(
      type: 'composeShapes', mode: QMode.choice, skill: 'compose:count',
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [ComposeVisual(pieces)],
      choices: r.numberChoices(pieces.length, 3, 2, 5), answer: pieces.length,
      hint: 'عُدّ كل لون لوحده 🎨', speakHint: 'عد كل لون لوحده', clipsHint: [say('عد كل لون لوحده')],
    );
  }
  if (kind == 1) {
    const ask = 'القطع دي لو اتجمعت تعمل أنهي شكل؟';
    final others = r.shuffle(['مربع', 'مستطيل', 'مثلث', 'بيت'].where((x) => x != name).toList()).take(2);
    return Question(
      type: 'composeShapes', mode: QMode.choice, skill: 'compose:make', numeric: false,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [ComposeVisual(pieces, apart: true)],
      choices: r.shuffle([name, ...others]), answer: name,
      hint: 'تخيّل القطع بتقرّب من بعض لحد ما تلزق 🧩', speakHint: 'تخيل القطع بتقرب من بعض لحد ما تلزق',
      clipsHint: [say('تخيل القطع بتقرب من بعض لحد ما تلزق')],
    );
  }
  const ask = 'الشكل ده اتعمل من إيه؟';
  final others = r.shuffle({for (final f in composeFigures) f.$3}.where((x) => x != parts).toList()).take(2);
  return Question(
    type: 'composeShapes', mode: QMode.choice, skill: 'compose:parts', numeric: false,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [ComposeVisual(pieces)],
    choices: r.shuffle([parts, ...others]), answer: parts,
    hint: 'بص على كل لون: مثلث ولا مربع؟ وعُدّهم 🔺🟦', speakHint: 'بص على كل لون، مثلث ولا مربع، وعدهم',
    clipsHint: [say('بص على كل لون، مثلث ولا مربع، وعدهم')],
  );
}
