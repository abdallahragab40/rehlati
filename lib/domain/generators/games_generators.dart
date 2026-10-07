/// عالم الألعاب — ألعاب مسلية بنفس محتوى التعلّم. منقولة من js/games/{balloons,memoryNum,
/// listenNum,raceAndPuzzle,colorNum,rhythm,more}.js.
library;

import 'dart:math' as math;

import '../../content/math_data.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

// ---------------------------------------------------------------- 🎈 فرقع البالونة

/// بالونات بتطلع وتنزل والطفل يفرقع الصح — مفيش عدّاد وقت ولا فشل، الحركة هي المتعة.
Question balloons(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  final n = math.min(l.choices + 1, 6); // ٤–٦ بالونات
  // في المستويات الأعلى السؤال بيبقى جمع بسيط بدل رقم مجرّد
  final int target;
  final String ask, speak, skill;
  if (lv >= 3 && r.chance(.5)) {
    final a = r.rnd(1, math.min(9, l.max - 1)), b = r.rnd(1, math.min(9, l.max - a));
    target = a + b;
    ask = 'فرقع البالونة اللي عليها ${ar(a)} + ${ar(b)}';
    speak = 'فرقع البالونة اللي عليها ${arNum(a)} زائد ${arNum(b)}';
    skill = 'sum:$target';
  } else {
    target = r.rnd(1, l.max);
    ask = 'فرقع البالونة رقم ${ar(target)}';
    speak = 'فرقع البالونة رقم ${arNum(target)}';
    skill = 'num:$target';
  }
  return Question(
    type: 'balloons', mode: QMode.balloon, skill: skill,
    ask: ask, speak: speak,
    choices: r.numberChoices(target, n, 1, l.max), answer: target,
    hint: 'البالونات بتتحرك — استنى وركّز 🎈', speakHint: 'ركز كويس واختار البالونة الصح',
  );
}

// ---------------------------------------------------------------- 🧠 الرقم وصاحبه

/// كروت مقلوبة: كل رقم صاحبه نفس العدد دواير — ذاكرة وربط الرقم بالكمية.
Question memoryNum(int lv, Rng r, {String? focus}) {
  final pairs = lv >= 3 ? 5 : 4;
  final max = lv >= 3 ? 6 : 5; // أكتر من ٦ دواير تبقى صعبة العدّ على الكارت
  final nums = r.shuffle([for (var i = 1; i <= max; i++) i]).take(pairs);
  return Question(
    type: 'memoryNum', mode: QMode.memory, skill: 'memory',
    skillOf: (k) => 'num:${k.substring(1)}',
    pairs: pairs,
    ask: 'لاقي الرقم وصاحبه',
    speak: 'اقلب كارتين ولاقي الرقم مع العدد اللي يساويه',
    hint: 'الرقم بيساوي عدد الدواير 🔵', speakHint: 'الرقم بيساوي عدد الدواير',
    cards: r.shuffle([
      for (final n in nums) ...[MemoryCard('n$n', '$n'), MemoryCard('n$n', '$n', dots: n)],
    ]),
  );
}

// ---------------------------------------------------------------- 👂 اسمع واختار

/// الرقم بيتنطق بس — محتاج الصوت، فمش متسجّلة لما نطق الأسئلة مقفول.
Question listenNum(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), n = r.rnd(1, l.max);
  return Question(
    type: 'listenNum', mode: QMode.choice, skill: 'listen:$n', bigChoices: true,
    ask: 'اسمع الرقم كويس… واختاره 👂', speak: arNum(n), clips: [nk(n)],
    visuals: [ListenVisual(arNum(n))],
    choices: r.numberChoices(n, l.choices, 1, l.max), answer: n,
    hint: 'اضغط 🔊 واسمع تاني بالراحة', speakHint: 'اسمع تاني بالراحة', sayRight: arNum(n),
  );
}

// ---------------------------------------------------------------- 🏁 السباق و 🧩 البازل

/// سؤال حساب بسيط مشترك بين السباق والبازل — المتعة في التقدّم المرئي مش في نوع السؤال.
Question _raceQuestion(String type, int lv, Rng r, {bool track = false, String? puzzle, required String hint}) {
  final l = levelSpec(lv);
  if (lv >= 2 && r.chance(.55)) {
    final a = r.rnd(1, math.min(9, l.max - 1)), b = r.rnd(1, math.min(9, l.max - a)), sum = a + b;
    return Question(
      type: type, mode: QMode.choice, track: track, puzzle: puzzle, bigChoices: true,
      ask: '${ar(a)} + ${ar(b)} = ؟', speak: '${arNum(a)} زائد ${arNum(b)} يساوي كام؟',
      choices: r.numberChoices(sum, l.choices, 1, l.max), answer: sum, skill: 'sum:$sum', sayRight: arNum(sum),
      hint: hint,
    );
  }
  final n = r.rnd(1, math.min(l.max, 9));
  return Question(
    type: type, mode: QMode.choice, track: track, puzzle: puzzle, bigChoices: true,
    ask: 'عُدّ وقول كام؟', speak: 'عُدّ الصور وقول كام؟',
    visuals: [PicsVisual(r.sample(const ['🍎', '🐥', '🌸', '⭐', '🍌', '🐞', '🎈']), n)],
    choices: r.numberChoices(n, l.choices, 1, l.max), answer: n, skill: 'count:$n', sayRight: arNum(n),
    hint: hint,
  );
}

/// 🐢 سباق الأرقام — الطفل ضد السلحفاة، كل إجابة صح خطوة لقدام.
Question race(int lv, Rng r, {String? focus}) =>
    _raceQuestion('race', lv, r, track: true, hint: 'كل إجابة صح = خطوة للأمام 🏁');

const puzzlePics = ['🦁', '🐘', '🦋', '🌻', '🚀', '🐬', '🦉', '🍉'];

/// 🧩 بازل الصورة — الصورة ثابتة طول اليوم عشان الطفل يفضل فضولي يشوفها كاملة.
Question puzzle(int lv, Rng r, {String? focus}) => _raceQuestion('puzzle', lv, r,
    puzzle: puzzlePics[DateTime.now().day % puzzlePics.length], hint: 'كل إجابة صح بتكشف قطعة من الصورة 🧩');

// ---------------------------------------------------------------- 🎨 لوّن بالأرقام

/// كل نمط ٦×٦ — كل رقم لون، والشكل بيبان لما يتلوّن كله.
const colorPatterns = <(String, List<String>)>[
  ('قلب', ['112211', '121121', '211112', '211112', '121121', '112211']),
  ('نجمة', ['113311', '113311', '331133', '113311', '131131', '311113']),
  ('شجرة', ['112211', '121121', '211112', '112211', '113311', '113311']),
  ('سمكة', ['111221', '112222', '122223', '122223', '112222', '111221']),
];

const colorBox = {1: (0xFF4CC9A7, 'أخضر'), 2: (0xFFFF6B6B, 'أحمر'), 3: (0xFFFFC43D, 'أصفر')};

Question colorNum(int lv, Rng r, {String? focus}) {
  final (name, rows) = r.sample(colorPatterns);
  final cells = [for (final row in rows) for (final c in row.split('')) int.parse(c)];
  final used = cells.toSet().toList()..sort();
  return Question(
    type: 'colorNum', mode: QMode.color, skill: 'color:$name',
    ask: 'لوّن بالأرقام وشوف الصورة',
    speak: 'اختار لون وبعدين لوّن كل الخانات اللي عليها نفس الرقم',
    hint: 'اضغط على اللون الأول، وبعدين على الخانات اللي عليها رقمه 🎨',
    speakHint: 'اختار اللون الأول وبعدين الخانات اللي عليها رقمه',
    paintCells: cells, paintCols: rows.first.length,
    pots: [for (final n in used) PaintPot(n, colorBox[n]!.$1, colorBox[n]!.$2)],
    picName: name, okMsg: '🎨 طلعت صورة $name!',
  );
}

// ---------------------------------------------------------------- 🥁 كرر الإيقاع

const rhythmPads = [
  RhythmPad(0, '🥁', 'الطبلة', 0xFFFF6B6B),
  RhythmPad(1, '👏', 'التصفيقة', 0xFFFFC43D),
  RhythmPad(2, '🔔', 'الجرس', 0xFF4C9BFF),
];

/// الذاكرة السمعية: الطول بيزيد بهدوء ٢ ← ٣ ← ٤ ← ٥، وأول مستوى طبلتين بس.
Question rhythm(int lv, Rng r, {String? focus}) {
  final len = math.min(1 + lv, 5);
  final pads = lv <= 1 ? rhythmPads.sublist(0, 2) : rhythmPads;
  return Question(
    type: 'rhythm', mode: QMode.rhythm, skill: 'rhythm:$len',
    ask: 'اسمع الإيقاع وكرّره', speak: 'اسمع الإيقاع كويس وبعدين كرّره',
    hint: 'اضغط ▶️ عشان تسمع الإيقاع تاني', speakHint: 'اضغط زرار التشغيل عشان تسمع تاني',
    pads: pads, beats: [for (var i = 0; i < len; i++) r.sample(pads).k],
    okMsg: '🥁 إيقاع مظبوط!',
  );
}

// ---------------------------------------------------------------- 🔁 اتبع النمط

const patternSets = [
  ['🔴', '🔵'], ['⭐', '🌙'], ['🍎', '🍌'], ['🐱', '🐶'], ['🔺', '🟦'], ['☀️', '☁️'], ['🎈', '🎁'],
];

/// الوحدة المتكرّرة بتطول مع المستوى: AB ثم AAB ثم ABC ثم ABBC.
Question pattern(int lv, Rng r, {String? focus}) {
  final set = r.sample(patternSets);
  final List<String> unit;
  if (lv <= 1) {
    unit = [set[0], set[1]];
  } else if (lv == 2) {
    unit = [set[0], set[0], set[1]];
  } else {
    final third = r.sample(patternSets.where((s) => s != set).toList())[0];
    unit = lv == 3 ? [set[0], set[1], third] : [set[0], set[1], set[1], third];
  }
  final seq = [for (var i = 0; i < unit.length * 2 + 1; i++) unit[i % unit.length]];
  final answer = seq.removeLast();
  final wrong = r.shuffle({for (final s in patternSets) ...s}.where((c) => c != answer).toList()).take(2);
  return Question(
    type: 'pattern', mode: QMode.choice, skill: 'pattern:${unit.length}', numeric: false, bigChoices: true,
    ask: 'إيه اللي بعده؟', speak: 'بُص على الترتيب وقول إيه اللي بعده',
    visuals: [PatternVisual(seq)],
    choices: r.shuffle([answer, ...wrong]), answer: answer,
    hint: 'النمط بيتكرر — عُدّ من الأول 👀', speakHint: 'النمط بيتكرر، عُدّ من الأول', okMsg: '⭐ النمط مظبوط!',
  );
}

// ---------------------------------------------------------------- 🔤 صيد الحروف

const huntLetters = ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ر', 'س', 'ش', 'ص', 'ط', 'ع', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي'];

/// نفس البالونات بالظبط بس بحروف.
Question letterHunt(int lv, Rng r, {String? focus}) {
  final pool = r.shuffle([...huntLetters]).take(lv >= 3 ? 6 : 4).toList();
  final target = r.sample(pool);
  return Question(
    type: 'letterHunt', mode: QMode.balloon, skill: 'letter:$target', numeric: false,
    ask: 'فرقع البالونة اللي عليها حرف $target', speak: 'فرقع البالونة اللي عليها حرف $target',
    choices: pool, answer: target,
    hint: 'البالونات بتتحرك — خد وقتك 🎈', speakHint: 'خد وقتك واختار الحرف الصح', sayRight: target,
  );
}

// ---------------------------------------------------------------- 🔺 الأشكال والألوان

const shapeNames = {'circle': 'الدائرة', 'square': 'المربع', 'triangle': 'المثلث', 'star': 'النجمة', 'heart': 'القلب'};
const shapeColors = {
  'red': (0xFFFF6B6B, 'الأحمر'),
  'blue': (0xFF4C9BFF, 'الأزرق'),
  'green': (0xFF4CC9A7, 'الأخضر'),
  'yellow': (0xFFFFC43D, 'الأصفر'),
};

/// في المستوى الأول الشكل وحده هو الفرق (كله بنفسجي)، وبعدين اللون كمان.
/// الاختيار "شكل|لون" — في المستوى الأول "شكل|" والواجهة بترسمه بنفسجي.
Question shapes(int lv, Rng r, {String? focus}) {
  final n = lv >= 3 ? 6 : 4, byColor = lv >= 2;
  final opts = <String>{};
  var guard = 0;
  while (opts.length < n && guard++ < 200) {
    final s = r.sample(shapeNames.keys.toList()), c = r.sample(shapeColors.keys.toList());
    opts.add(byColor ? '$s|$c' : '$s|');
  }
  final pick = r.sample(opts.toList());
  final [sk, ck] = pick.split('|');
  final label = byColor ? '${shapeNames[sk]} ${shapeColors[ck]!.$2}' : shapeNames[sk]!;
  return Question(
    type: 'shapes', mode: QMode.choice, skill: 'shape:$pick', numeric: false, look: ChoiceLook.shape,
    ask: 'اضغط $label', speak: 'اضغط $label',
    choices: r.shuffle(opts.toList()), answer: pick,
    hint: 'بُص على الشكل كويس 👀', speakHint: 'بص على الشكل كويس', sayRight: label,
  );
}

// ---------------------------------------------------------------- 📏 رتّب بالحجم

const sizePics = ['🐘', '🎈', '🍎', '⭐', '🐟', '🌳', '🚗', '🐻'];

Question sizeOrder(int lv, Rng r, {String? focus}) {
  final n = lv >= 3 ? 4 : 3;
  final sizes = const ['1', '1.55', '2.15', '2.8'].sublist(0, n);
  final up = lv.isEven || lv == 1; // تصاعدي أو تنازلي
  return Question(
    type: 'sizeOrder', mode: QMode.order, numeric: false, skill: 'size:$n',
    ask: up ? 'رتّب من الأصغر للأكبر' : 'رتّب من الأكبر للأصغر',
    speak: up ? 'رتب الصور من الأصغر للأكبر' : 'رتب الصور من الأكبر للأصغر',
    orderHint: 'اضغط الصور بالترتيب',
    items: r.shuffle([...sizes]), answer: up ? sizes : sizes.reversed.toList(),
    sizePic: r.sample(sizePics),
    hint: 'قارن الأحجام الأول 👀', speakHint: 'قارن الأحجام الأول', okMsg: '⭐ ترتيب مظبوط!',
  );
}

// ---------------------------------------------------------------- 🕐 كام الساعة

String clockWord(int h, int m) => m == 0 ? '${ar(h)} تمام' : '${ar(h)} والنص';

/// الساعات تمام، والنص بيظهر من المستوى التالت.
Question clock(int lv, Rng r, {String? focus}) {
  int minute() => lv >= 3 && r.chance(.5) ? 30 : 0;
  final h = r.rnd(1, 12), m = minute(), ans = clockWord(h, m);
  final set = <String>{ans};
  var guard = 0;
  while (set.length < (lv >= 3 ? 4 : 3) && guard++ < 60) {
    set.add(clockWord(r.rnd(1, 12), minute()));
  }
  return Question(
    type: 'clock', mode: QMode.choice, skill: 'clock:$h:$m', numeric: false, wide: true,
    ask: 'كام الساعة؟', speak: 'كام الساعة؟',
    visuals: [ClockVisual(h, m)],
    choices: r.shuffle(set.toList()), answer: ans,
    hint: 'العقرب القصير = الساعة، والطويل = الدقايق ⏰', speakHint: 'العقرب القصير يقول الساعة', sayRight: ans,
  );
}
