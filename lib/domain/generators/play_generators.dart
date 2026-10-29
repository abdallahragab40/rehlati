/// عالم الألعاب — ألعاب التفكير (مين الغريب، الظل، الأضداد…)، الآداب والنضافة،
/// والحركة (المتاهة، الأكواب، اسحب للسلة، الألوان، ارسم بصباعك).
library;

import 'dart:math' as math;

import '../../content/play_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

Map<Object, String> _names(Iterable<(String, String)> pics) => {for (final (e, n) in pics) e: n};

// ---------------------------------------------------------------- 🤔 مين الغريب؟

/// ٣ (أو ٤) صور من نوع واحد وصورة من نوع تاني. الفاكهة والخضار مابيتقابلوش لحد المستوى التالت.
Question oddOne(int lv, Rng r, {String? focus}) {
  final cats = thingCats.keys.toList();
  final base = focus != null && focus.startsWith('odd:') && cats.contains(focus.substring(4))
      ? focus.substring(4)
      : r.sample(cats);
  final others = [for (final c in cats) if (c != base && (lv >= 3 || nearCats[base] != c)) c];
  final oddCat = r.sample(others);
  final same = r.shuffle(things.where((t) => t.cat == base).toList()).take(lv >= 3 ? 4 : 3).toList();
  final odd = r.sample(things.where((t) => t.cat == oddCat).toList());
  final shown = r.shuffle([...same, odd]);
  return Question(
    type: 'oddOne', mode: QMode.choice, skill: 'odd:$base', numeric: false, bigChoices: true,
    ask: 'مين الغريب؟ 🤔', speak: 'فيه صورة مش شبه الباقيين، هي فين؟',
    choices: [for (final t in shown) t.emoji], answer: odd.emoji,
    choiceSay: {for (final t in shown) t.emoji: t.name},
    okMsg: '👏 ${odd.name} مش ${thingCats[base]!.$1}!',
    hint: 'الصور كلها ${thingCats[base]!.$1} ما عدا واحدة 👀', speakHint: 'دوّر على الصورة اللي لوحدها',
  );
}

// ---------------------------------------------------------------- 👤 ظل الصورة

/// صورة ملوّنة قدامها ظلال، والطفل يختار ظلها. الظلال الغلط من نوع تاني في الأول، ومن نفس النوع بعدين.
Question shadow(int lv, Rng r, {String? focus}) {
  final pic = r.sample(shadowPics);
  final n = lv >= 3 ? 4 : 3;
  final pool = shadowPics.where((p) => p != pic && (lv >= 3 ? true : p.$3 != pic.$3)).toList();
  final shown = r.shuffle([pic, ...r.shuffle(pool).take(n - 1)]);
  return Question(
    type: 'shadow', mode: QMode.choice, skill: 'shadow', numeric: false, bigChoices: true,
    look: ChoiceLook.shadow,
    ask: 'أنهي ظل بتاع الصورة دي؟', speak: 'بص على الصورة ودوّر على ظلها',
    visuals: [EmojiVisual(pic.$1)],
    choices: [for (final p in shown) p.$1], answer: pic.$1,
    choiceSay: {for (final p in shown) p.$1: p.$2},
    okMsg: '🌑 ده ظل ${pic.$2}!',
    hint: 'قارن شكل الظل بشكل الصورة 👀', speakHint: 'قارن شكل الظل بشكل الصورة',
  );
}

// ---------------------------------------------------------------- 🐮 مين بيقول كده؟

/// الصوت بيتنطق بس — محتاج الصوت زي "اسمع واختار".
Question animalSound(int lv, Rng r, {String? focus}) {
  final it = r.sample(animalSounds);
  final n = lv >= 3 ? 4 : 3;
  final shown = r.shuffle([it, ...r.shuffle(animalSounds.where((a) => a != it).toList()).take(n - 1)]);
  return Question(
    type: 'animalSound', mode: QMode.choice, skill: 'sound:${it.$2}', numeric: false, bigChoices: true,
    ask: 'مين بيقول كده؟ 👂', speak: 'مين بيقول: ${it.$3}؟',
    clips: [say('مين بيقول'), say(it.$3)],
    visuals: [ListenVisual(it.$3)],
    choices: [for (final a in shown) a.$1], answer: it.$1,
    choiceSay: {for (final a in shown) a.$1: a.$2},
    sayRight: '${it.$2} ${it.$4 ? 'بتقول' : 'بيقول'} ${it.$3}',
    hint: 'اضغط 🔊 واسمع الصوت تاني', speakHint: 'اسمع الصوت تاني',
  );
}

// ---------------------------------------------------------------- 🔄 الأضداد

/// المستويين الأولانيين: صورتين وسؤال "فين الكبير؟". بعدها: صورة صفة و"فين عكسه؟" من ٣.
Question opposite(int lv, Rng r, {String? focus}) {
  final o = r.sample(opposites);
  final pic = r.sample(o.pics);
  final [pa, pb] = pic.contains('|') ? pic.split('|') : [pic, pic];
  final a = '${o.a.$1}|$pa', b = '${o.b.$1}|$pb';
  final flip = r.chance(.5);
  final (want, wantInfo, other, otherInfo) = flip ? (b, o.b, a, o.a) : (a, o.a, b, o.b);
  if (lv <= 2) {
    return Question(
      type: 'opposite', mode: QMode.choice, skill: 'opp:${o.a.$1}', numeric: false, look: ChoiceLook.opposite,
      ask: wantInfo.$2, speak: wantInfo.$2,
      choices: r.shuffle([want, other]), answer: want,
      choiceSay: {want: wantInfo.$3, other: otherInfo.$3},
      sayRight: wantInfo.$3,
      hint: 'بص على الصورتين وقارن 👀', speakHint: 'بص على الصورتين وقارن',
    );
  }
  // صورة صفة واحدة والطفل يختار عكسها من بين ٣
  final others = r.shuffle(opposites.where((x) => x != o).toList()).take(2);
  final wrong = [
    for (final x in others)
      () {
        final p = r.sample(x.pics), side = r.chance(.5) ? x.a : x.b;
        final e = p.contains('|') ? p.split('|')[side == x.a ? 0 : 1] : p;
        return ('${side.$1}|$e', side.$3);
      }(),
  ];
  return Question(
    type: 'opposite', mode: QMode.choice, skill: 'opp:${o.a.$1}', numeric: false, look: ChoiceLook.opposite,
    ask: '${o.demo} ${otherInfo.$3}… فين عكسه؟', speak: '${o.demo} ${otherInfo.$3}، فين عكسه؟',
    visuals: [OppositeVisual(other)],
    choices: r.shuffle([want, for (final (w, _) in wrong) w]), answer: want,
    choiceSay: {want: wantInfo.$3, for (final (w, n) in wrong) w: n},
    sayRight: 'عكس ${otherInfo.$3}، ${wantInfo.$3}',
    hint: 'العكس = الحاجة المختلفة خالص ↔️', speakHint: 'دوّر على العكس',
  );
}

// ---------------------------------------------------------------- 📚 رتّب الحكاية

/// مراحل مألوفة بالصور تترتّب من الأول للآخر. ٣ مراحل في الأول، و٤ من المستوى التاني.
Question storyOrder(int lv, Rng r, {String? focus}) {
  final pool = stories.where((s) => lv >= 2 || s.length == 3).toList();
  final story = r.sample(pool);
  final seq = [for (final (e, _) in story) e];
  return Question(
    type: 'storyOrder', mode: QMode.order, numeric: false, skill: 'story:${seq.first}', bigChoices: true,
    rtlSlots: true, look: ChoiceLook.picName,
    ask: 'رتّب الحكاية من الأول للآخر', speak: 'إيه اللي حصل الأول؟ رتّب الصور من الأول للآخر',
    orderHint: 'اضغط الصور بالترتيب: الأول ← الآخر',
    items: r.shuffle([...seq]), answer: seq,
    choiceSay: _names(story),
    hint: 'فكّر: إيه اللي بيحصل الأول؟ 🤔', speakHint: 'فكر، إيه اللي بيحصل الأول؟', okMsg: '📚 حكاية مترتّبة!',
  );
}

// ---------------------------------------------------------------- 🗂️ صنّف

/// صورة والطفل يختار سلتها. السلال: ٢ في الأول، ٣ ثم ٤.
Question category(int lv, Rng r, {String? focus}) {
  final n = lv <= 1 ? 2 : (lv == 2 ? 3 : 4);
  final it = r.sample(things.where((t) => !thingCats[t.cat]!.$2.contains(t.emoji)).toList());
  final others = r.shuffle(thingCats.keys.where((c) => c != it.cat && (lv >= 3 || nearCats[it.cat] != c)).toList());
  final shown = r.shuffle([it.cat, ...others.take(n - 1)]);
  return Question(
    type: 'category', mode: QMode.choice, skill: 'cat:${it.cat}', numeric: false, look: ChoiceLook.category,
    ask: 'الصورة دي من أنهي نوع؟', speak: 'الصورة دي من أنهي نوع؟',
    visuals: [EmojiVisual(it.emoji)],
    choices: shown, answer: it.cat,
    choiceSay: {for (final c in shown) c: thingCats[c]!.$1},
    sayRight: '${it.name} ${thingCats[it.cat]!.$1}',
    hint: 'بص على الصور اللي على كل سلة 🧺', speakHint: 'بص على الصور اللي على كل سلة',
  );
}

// ---------------------------------------------------------------- 🖼️ الصورة الناقصة

const _missingSets = [
  ['🍎', '🍌', '🍇'], ['🐶', '🐱', '🐰'], ['🚗', '🚌', '🚲'], ['⭐', '🌙', '☀️'],
  ['🔴', '🔵', '🟡'], ['🌸', '🍀', '🌻'], ['🐟', '🐙', '🦀'], ['⚽', '🎈', '🧸'],
];

/// صف نمط فيه خانة فاضية في أي مكان (مش في الآخر بس زي «اتبع النمط»).
Question missingPic(int lv, Rng r, {String? focus}) {
  final set = r.sample(_missingSets);
  final unit = switch (lv) {
    <= 1 => [set[0], set[1]],
    2 => [set[0], set[1], set[2]],
    3 => [set[0], set[0], set[1]],
    _ => [set[0], set[1], set[1], set[2]],
  };
  final len = math.max(6, unit.length * 2 + 1);
  final seq = [for (var i = 0; i < len; i++) unit[i % unit.length]];
  // الخانة الفاضية بعد أول وحدة كاملة عشان النمط يبان قبلها
  final hole = r.rnd(unit.length, len - 1);
  final answer = seq[hole];
  final wrong = r.shuffle({...set, ...r.sample(_missingSets.where((s) => s != set).toList())}.where((e) => e != answer).toList()).take(2);
  return Question(
    type: 'missingPic', mode: QMode.choice, skill: 'missing:${unit.length}', numeric: false, bigChoices: true,
    ask: 'إيه الصورة الناقصة؟', speak: 'فيه صورة ناقصة في الصف، إيه هي؟',
    visuals: [PatternVisual(seq, hole: hole)],
    choices: r.shuffle([answer, ...wrong]), answer: answer,
    hint: 'الصور بتتكرر بنفس الترتيب — عُدّ من الأول 👀', speakHint: 'الصور بتتكرر، عُدّ من الأول', okMsg: '🖼️ الصف كمل!',
  );
}

// ---------------------------------------------------------------- 🐱 فين القطة؟

/// القطة تحت كوباية، والأكواب بتتبدّل. التبديلات بتزيد وتسرع مع المستوى، و٤ أكواب في الآخر.
Question cups(int lv, Rng r, {String? focus}) {
  final n = lv >= 4 ? 4 : 3;
  return Question(
    type: 'cups', mode: QMode.cups, skill: 'cups:$lv', numeric: false,
    ask: 'فين القطة؟ 🐱', speak: 'شوف القطة فين، وركّز مع الكوباية',
    cupCount: n, catCup: r.rnd(0, n - 1),
    cupSwaps: math.min(lv + 1, 5), cupStepMs: const {1: 900, 2: 800, 3: 700}[lv] ?? 620,
    hint: 'عينك على الكوباية اللي تحتها القطة 👀', speakHint: 'عينك على الكوباية اللي تحتها القطة',
    okMsg: '🐱 لقيت القطة!',
  );
}

// ---------------------------------------------------------------- 🐰 متاهة الأرنب

/// متاهة كاملة (كل الخانات متوصّلة بطريق واحد) بالـ backtracking. الأرنب فوق على اليمين
/// والجزرة تحت على الشمال. ٤×٤ في الأول وبعدين ٥×٥.
Question maze(int lv, Rng r, {String? focus}) {
  final n = lv <= 1 ? 4 : (lv >= 4 ? 6 : 5);
  final walls = List<int>.filled(n * n, mazeN | mazeE | mazeS | mazeW);
  final seen = <int>{};
  const dirs = [(mazeN, -1, 0, mazeS), (mazeE, 0, 1, mazeW), (mazeS, 1, 0, mazeN), (mazeW, 0, -1, mazeE)];
  final start = n - 1, stack = [start];
  seen.add(start);
  while (stack.isNotEmpty) {
    final c = stack.last, row = c ~/ n, col = c % n;
    final next = [
      for (final (bit, dr, dc, back) in dirs)
        if (row + dr >= 0 && row + dr < n && col + dc >= 0 && col + dc < n && !seen.contains((row + dr) * n + col + dc))
          (bit, (row + dr) * n + col + dc, back),
    ];
    if (next.isEmpty) {
      stack.removeLast();
      continue;
    }
    final (bit, to, back) = r.sample(next);
    walls[c] &= ~bit;
    walls[to] &= ~back;
    seen.add(to);
    stack.add(to);
  }
  return Question(
    type: 'maze', mode: QMode.maze, skill: 'maze:$n', numeric: false,
    ask: 'وصّل الأرنب للجزرة 🥕', speak: 'وصّل الأرنب للجزرة بالأسهم',
    mazeSize: n, mazeWalls: walls, mazeStart: start, mazeGoal: n * (n - 1),
    hint: 'لو فيه حيطة جرّب طريق تاني 🧱', speakHint: 'لو فيه حيطة جرب طريق تاني',
    okMsg: '🥕 الأرنب وصل للجزرة!',
  );
}

// ---------------------------------------------------------------- 🧺 ودّي الحاجة مكانها

/// اسحب كل صورة لسلتها (نفس وضع التصنيف بتاع المدود). سلتين في الأول، وتلاتة في الآخر.
Question dragSort(int lv, Rng r, {String? focus}) {
  final nBoxes = lv >= 4 ? 3 : 2;
  final nCards = switch (lv) { <= 1 => 4, 2 => 5, _ => 6 };
  final cats = <String>[];
  for (final c in r.shuffle(thingCats.keys.toList())) {
    if (cats.length < nBoxes && (lv >= 3 || !cats.any((x) => nearCats[x] == c))) cats.add(c);
  }
  final cards = <Thing>[];
  final perCat = {for (final c in cats) c: r.shuffle(things.where((t) => t.cat == c).toList())};
  // كل سلة فيها صورة واحدة على الأقل
  for (var i = 0; i < nCards; i++) {
    cards.add(perCat[cats[i % cats.length]]!.removeLast());
  }
  const colors = [0xFF2FA36B, 0xFF4C7BE0, 0xFFE0662E];
  return Question(
    type: 'dragSort', mode: QMode.sort, skill: 'sort:${cats.join('+')}', skillOf: (c) => 'cat:$c',
    ask: 'ودّي كل حاجة سلتها 🧺', speak: 'اسحب كل صورة وحطها في السلة بتاعتها',
    orderHint: 'اسحب الصورة للسلة، أو اضغطها وبعدين اضغط السلة',
    boxes: [
      for (final (i, c) in cats.indexed)
        SortBox(c, '${thingCats[c]!.$2.first} ${thingCats[c]!.$1}', color: colors[i]),
    ],
    sortCards: [for (final t in r.shuffle(cards)) SortCard(t.emoji, t.name, t.cat)],
    hint: 'كل صورة ليها سلة من نوعها 🧺', speakHint: 'كل صورة ليها سلة من نوعها',
    okMsg: '🧺 كل حاجة في مكانها!',
  );
}

// ---------------------------------------------------------------- 🎨 كرر الألوان

const lightPads = [
  RhythmPad(0, '', 'الأحمر', 0xFFFF4D4D),
  RhythmPad(1, '', 'الأزرق', 0xFF3D8BFF),
  RhythmPad(2, '', 'الأخضر', 0xFF2FBF71),
  RhythmPad(3, '', 'الأصفر', 0xFFFFC21A),
];

/// زي «كرر الإيقاع» بس بأضواء: الألوان بتنوّر بالترتيب والطفل يعيدها. الطول ٢ ← ٥.
Question lights(int lv, Rng r, {String? focus}) {
  final len = math.min(1 + lv, 5);
  final pads = lv <= 1 ? lightPads.sublist(0, 3) : lightPads;
  final beats = <int>[];
  for (var i = 0; i < len; i++) {
    // من غير نفس اللون مرتين ورا بعض في الأول — صعب يتشاف إنه نوّر مرتين
    final pool = [for (final p in pads) if (lv >= 3 || beats.isEmpty || p.k != beats.last) p.k];
    beats.add(r.sample(pool));
  }
  return Question(
    type: 'lights', mode: QMode.rhythm, skill: 'lights:$len', lights: true,
    ask: 'شوف الألوان وكرّرها', speak: 'شوف الألوان بتنوّر إزاي، وبعدين نوّرها زيها',
    hint: 'اضغط ▶️ عشان تشوف الألوان تاني', speakHint: 'اضغط زرار التشغيل عشان تشوف تاني',
    pads: pads, beats: beats,
    okMsg: '🎨 ألوان مظبوطة!',
  );
}

// ---------------------------------------------------------------- 🧼 غسل الإيدين والوضوء

/// رتّب الخطوات: غسل الإيدين في الأول، وبعدين حتة متتالية من خطوات الوضوء بتطول مع المستوى.
Question cleanSteps(int lv, Rng r, {String? focus}) {
  final wudu = lv >= 2 && r.chance(.75);
  final List<(String, String)> steps;
  if (wudu) {
    final n = math.min(lv + 2, wuduSteps.length);
    final from = r.rnd(0, wuduSteps.length - n);
    steps = wuduSteps.sublist(from, from + n);
  } else {
    steps = handWashSteps.sublist(0, lv <= 1 ? 4 : 5);
  }
  final seq = [for (final (e, _) in steps) e];
  return Question(
    type: 'cleanSteps', mode: QMode.order, numeric: false, skill: wudu ? 'wudu' : 'handwash', bigChoices: true,
    rtlSlots: true, look: ChoiceLook.picName,
    ask: wudu ? 'رتّب خطوات الوضوء' : 'رتّب خطوات غسل الإيدين',
    speak: wudu ? 'رتّب خطوات الوضوء بالترتيب' : 'رتّب خطوات غسل الإيدين بالترتيب',
    orderHint: 'اضغط الخطوات بالترتيب: الأولى ← الأخيرة',
    items: r.shuffle([...seq]), answer: seq,
    choiceSay: _names(steps),
    hint: 'إيه أول حاجة بنعملها؟ 🤔', speakHint: 'فكر، إيه أول حاجة بنعملها؟',
    okMsg: wudu ? '💧 وضوء مظبوط!' : '🧼 إيدك نضيفة!',
  );
}

// ---------------------------------------------------------------- ✅ ده يصح ولا لأ؟

/// موقف بسيط والطفل يختار ✅ أو ❌. الغلطة تشجيع لطيف، وبعد الإجابة بيتقال السبب.
Question manner(int lv, Rng r, {String? focus}) {
  final (emoji, text, ok, why) = r.sample(manners);
  final answer = ok ? '✅' : '❌';
  return Question(
    type: 'manner', mode: QMode.choice, skill: 'manner:$text', numeric: false, bigChoices: true, gentle: true,
    ask: 'ده يصح ولا لأ؟', speak: '$text. ده يصح ولا لأ؟',
    clips: [say(text), say('ده يصح ولا لأ؟')],
    visuals: [EmojiVisual(emoji, caption: text)],
    choices: const ['✅', '❌'], answer: answer,
    choiceSay: const {'✅': 'يصح', '❌': 'ما يصحش'},
    sayRight: why, okMsg: '${ok ? '👏' : '🙅'} $why',
    hint: 'فكّر: لو حد عمل كده معاك، هتفرح؟ 💭', speakHint: 'فكر، لو حد عمل كده معاك هتفرح؟',
  );
}

// ---------------------------------------------------------------- ✍️ ارسم بصباعك

/// كود واحد للأرقام والحروف العربي والإنجليزي: الطفل يمشي بصباعه على الشكل.
Question _trace(String type, String glyph, String ask, String speak, {List<String?>? clips, bool en = false}) => Question(
      type: type, mode: QMode.trace, skill: 'trace:$glyph', numeric: false, gentle: true,
      lang: en ? 'en' : 'ar', ltr: en,
      ask: ask, speak: speak, clips: clips, trace: glyph,
      hint: en ? 'Follow the grey letter with your finger ✍️' : 'امشي بصباعك فوق الشكل الرمادي ✍️',
      speakHint: en ? 'Follow the grey letter' : 'امشي بصباعك فوق الشكل',
      okMsg: en ? '✍️ Great tracing!' : '✍️ رسمة حلوة!',
    );

Question traceNum(int lv, Rng r, {String? focus}) {
  final n = lv <= 1 ? r.rnd(1, 5) : r.rnd(1, 9);
  return _trace('traceNum', ar(n), 'ارسم رقم ${ar(n)}', 'ارسم رقم ${arNum(n)}', clips: [say('ارسم رقم'), nk(n)]);
}

Question traceAr(int lv, Rng r, {String? focus}) {
  final l = r.sample(lv <= 1 ? traceArEasy : traceArAll);
  return _trace('traceAr', l, 'ارسم حرف $l', 'ارسم حرف $l', clips: [say('ارسم حرف'), say(l)]);
}

Question traceEn(int lv, Rng r, {String? focus}) {
  final upper = r.sample(lv <= 1 ? traceEnEasy : [for (var c = 65; c <= 90; c++) String.fromCharCode(c)]);
  final l = lv >= 3 && r.chance(.5) ? upper.toLowerCase() : upper;
  return _trace('traceEn', l, 'Trace the letter $l', 'Trace the letter $l', en: true);
}
