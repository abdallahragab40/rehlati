/// أساسيات اتضافت بعد مراجعة المنهج: أشكال الحرف، الشدّة، الشمسية والقمرية، جمل قصيرة،
/// هذا وهذه، ومجموعات الكلمات في العربي — وتحليل العدد والترتيبي والزوجي والفردي والأشكال
/// والقياس والفلوس الصغيرة والتقويم والمسائل والرسم البياني في الحساب.
library;

import 'dart:math' as math;

import '../../content/basics_data.dart';
import '../../content/language_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

List<T> _pick<T>(Rng r, List<T> from, int n, {T? not}) =>
    r.shuffle([for (final x in from) if (x != not) x]).take(n).toList();

/// اختيارات نصية: الإجابة وغلط من قايمة.
List<Object> _with(Rng r, Object answer, Iterable<Object> wrong, int n) =>
    r.shuffle([answer, ...r.shuffle({...wrong}.where((w) => w != answer).toList()).take(n - 1)]);

int _n(int lv) => lv <= 1 ? 2 : (lv == 2 ? 3 : 4);

// ================================================================ العربي

// ---------------------------------------------------------------- أشكال الحرف

final _formLetters = [for (final l in arLetters) l.letter];

/// شكل الحرف في أول الكلمة ووسطها وآخرها: «ده شكل حرف إيه؟» أو «أنهي شكل بييجي في …؟».
Question arForms(int lv, Rng r, {String? focus}) {
  final l = focus != null && _formLetters.contains(focus) ? focus : r.sample(_formLetters);
  final joins = !nonJoining.contains(l);
  final positions = joins ? ['first', 'middle', 'last'] : ['middle', 'last'];
  if (lv >= 2 && r.chance(.5) && joins) {
    final pos = r.sample(positions);
    final opts = {for (final p in positions) letterForm(l, p): p};
    return Question(
      type: 'ar_forms', mode: QMode.choice, skill: 'form:$l', numeric: false, bigChoices: true,
      ask: 'حرف $l في ${positionNames[pos]} شكله إيه؟', speak: 'حرف $l في ${positionNames[pos]} شكله إيه؟',
      clips: [say('حرف'), say(l), say('في ${positionNames[pos]} شكله إيه؟')],
      visuals: [BigLetterVisual(l)],
      choices: r.shuffle(opts.keys.toList()), answer: letterForm(l, pos),
      choiceSay: {for (final e in opts.entries) e.key: 'حرف $l في ${positionNames[e.value]}'},
      hint: 'الخط الصغير (ـ) بيوري الحرف بيتوصل منين 👀', speakHint: 'الخط الصغير بيوري الحرف بيتوصل منين',
    );
  }
  final pos = r.sample(positions);
  final form = letterForm(l, pos);
  final wrong = _pick(r, _formLetters, _n(lv) - 1, not: l);
  return Question(
    type: 'ar_forms', mode: QMode.choice, skill: 'form:$l', numeric: false, bigChoices: true,
    ask: 'ده شكل حرف إيه؟', speak: 'ده شكل حرف إيه؟',
    visuals: [BigLetterVisual(form), CaptionVisual(positionNames[pos]!)],
    choices: r.shuffle([l, ...wrong]), answer: l,
    hint: 'شيل الخط الصغير (ـ) وبص على شكل الحرف ✍️', speakHint: 'بص على شكل الحرف من غير الخط الصغير',
    sayRight: l,
  );
}

/// الحرف جه فين في الكلمة: أولها ولا وسطها ولا آخرها؟
Question arPosition(int lv, Rng r, {String? focus}) {
  final words = arWords.where((w) => w.word.length >= 3).toList();
  final w = r.sample(words);
  final letters = w.word.split('');
  final i = r.rnd(0, letters.length - 1);
  final l = letters[i];
  // نختار حرف مش متكرر في الكلمة عشان الإجابة تبقى واحدة
  if (letters.where((x) => x == l).length > 1) return arPosition(lv, r, focus: focus);
  final pos = i == 0 ? 'first' : (i == letters.length - 1 ? 'last' : 'middle');
  return Question(
    type: 'ar_position', mode: QMode.choice, skill: 'pos:$pos', numeric: false, wide: true,
    ask: 'حرف $l جه فين في كلمة ${w.word}؟', speak: 'حرف $l جه فين في كلمة ${w.word}؟',
    clips: [say('حرف'), say(l), say('جه فين في كلمة'), say(w.word)],
    visuals: [WordLineVisual.text(w.word, big: true), CaptionVisual(w.emoji)],
    choices: r.shuffle([for (final p in ['first', 'middle', 'last']) positionNames[p]!]), answer: positionNames[pos]!,
    hint: 'اقرا الكلمة من اليمين: أول حرف على اليمين وآخر حرف على الشمال ➡️',
    speakHint: 'أول حرف على اليمين وآخر حرف على الشمال',
  );
}

// ---------------------------------------------------------------- الشدّة

String _bare(String w) => w.replaceAll(RegExp('[ً-ْ]'), '');

/// الشدّة = حرفين واحد ساكن وواحد متحرك. «أنهي حرف عليه شدّة؟» أو «أنهي كلمة فيها شدّة؟».
Question arShadda(int lv, Rng r, {String? focus}) {
  final withS = shaddaWords.where((w) => w.$2.isNotEmpty).toList();
  final without = shaddaWords.where((w) => w.$2.isEmpty).toList();
  if (lv <= 1 || r.chance(.5)) {
    final yes = r.sample(withS);
    final no = _pick(r, without, _n(lv) - 1);
    final shown = r.shuffle([yes, ...no]);
    return Question(
      type: 'ar_shadda', mode: QMode.choice, skill: 'shadda:find', numeric: false, bigChoices: true,
      ask: 'أنهي كلمة فيها شدّة ( ّ )؟', speak: 'أنهي كلمة فيها شدة؟',
      choices: [for (final w in shown) w.$1], answer: yes.$1,
      hint: 'الشدّة شكلها زي حرف w صغير فوق الحرف ّ', speakHint: 'الشدة علامة صغيرة فوق الحرف',
      sayRight: yes.$1,
    );
  }
  final w = r.sample(withS);
  final letters = {..._bare(w.$1).split('')}.toList();
  return Question(
    type: 'ar_shadda', mode: QMode.choice, skill: 'shadda:letter', numeric: false, bigChoices: true,
    ask: 'أنهي حرف عليه شدّة في الكلمة دي؟', speak: 'أنهي حرف عليه شدة في الكلمة دي؟',
    clips: [say('أنهي حرف عليه شدة في الكلمة دي؟'), say(w.$1)],
    visuals: [WordLineVisual.text(w.$1, big: true), CaptionVisual(w.$3)],
    choices: _with(r, w.$2, letters, math.min(letters.length, _n(lv) + 1)), answer: w.$2,
    hint: 'الحرف المشدّد بيتقري مرتين: مرة ساكن ومرة متحرّك 🗣️', speakHint: 'الحرف المشدد بيتقري مرتين',
    sayRight: w.$1,
  );
}

// ---------------------------------------------------------------- الشمسية والقمرية

/// اللام بتتنطق (قمرية 🌙) ولا بتختفي والحرف اللي بعدها بيتشدّد (شمسية ☀️)؟
Question arAl(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.4)) {
    final shown = _pick(r, alWords, lv >= 3 ? 6 : 4);
    if ({for (final w in shown) w.$2}.length < 2) shown[0] = alWords.firstWhere((w) => w.$2 != shown[1].$2);
    return Question(
      type: 'ar_al', mode: QMode.sort, skill: 'al:sort', skillOf: (t) => 'al:$t',
      ask: 'حط كل كلمة في سلتها', speak: 'حط كل كلمة في السلة بتاعتها: شمسية ولا قمرية',
      orderHint: 'اسحب الكلمة للسلة، أو اضغطها وبعدين اضغط السلة',
      boxes: const [SortBox('sun', '☀️ شمسية', color: 0xFFE0662E), SortBox('moon', '🌙 قمرية', color: 0xFF4C7BE0)],
      sortCards: [for (final w in shown) SortCard(w.$1, w.$1, w.$2 ? 'sun' : 'moon')],
      hint: 'لو اللام بتتنطق تبقى قمرية 🌙، ولو مش بتتنطق تبقى شمسية ☀️',
      speakHint: 'لو اللام بتتنطق تبقى قمرية، ولو مش بتتنطق تبقى شمسية',
    );
  }
  final w = r.sample(alWords);
  return Question(
    type: 'ar_al', mode: QMode.choice, skill: 'al:${w.$2 ? 'sun' : 'moon'}', numeric: false, wide: true,
    ask: 'اللام في الكلمة دي شمسية ولا قمرية؟', speak: 'اللام في الكلمة دي شمسية ولا قمرية؟',
    clips: [say('اللام في الكلمة دي شمسية ولا قمرية؟'), say(w.$1)],
    visuals: [WordLineVisual.text(w.$1, big: true), CaptionVisual(w.$3)],
    choices: const ['☀️ شمسية', '🌙 قمرية'], answer: w.$2 ? '☀️ شمسية' : '🌙 قمرية',
    choiceSay: const {'☀️ شمسية': 'شمسية', '🌙 قمرية': 'قمرية'},
    hint: 'اقرا الكلمة: لو سمعت اللام تبقى قمرية 🌙', speakHint: 'لو سمعت اللام تبقى قمرية',
    sayRight: w.$1,
  );
}

// ---------------------------------------------------------------- جمل قصيرة

/// جملة قصيرة بصورة وسؤال مين/فين/إيه.
Question arShortRead(int lv, Rng r, {String? focus}) {
  final (text, pic, q, a, wrong) = r.sample(shortSentences);
  return Question(
    type: 'ar_short_read', mode: QMode.choice, skill: 'read:$text', numeric: false, wide: true,
    ask: q, speak: '$text. $q', clips: [say(text), say(q)],
    visuals: [EmojiVisual(pic, caption: text)],
    choices: r.shuffle([a, ...wrong]), answer: a,
    hint: 'اقرا الجملة تاني بالراحة 📖', speakHint: 'اقرا الجملة تاني بالراحة',
  );
}

// ---------------------------------------------------------------- هذا وهذه

Question arThis(int lv, Rng r, {String? focus}) {
  final (pic, name, fem) = r.sample(thisThat);
  final answer = fem ? 'هذه $name' : 'هذا $name';
  return Question(
    type: 'ar_this', mode: QMode.choice, skill: 'this:${fem ? 'f' : 'm'}', numeric: false, wide: true,
    ask: 'نقول إيه؟', speak: 'نقول هذا ولا هذه؟',
    visuals: [EmojiVisual(pic)],
    choices: r.shuffle(['هذا $name', 'هذه $name']), answer: answer,
    hint: 'هذه للمؤنث (قطة، وردة)، وهذا للمذكر (كلب، بيت) 👆', speakHint: 'هذه للمؤنث، وهذا للمذكر',
  );
}

// ---------------------------------------------------------------- مجموعات الكلمات

/// «أنهي كلمة من أعضاء الجسم؟» أو «مين الكلمة الغريبة؟».
Question arGroups(int lv, Rng r, {String? focus}) {
  final groups = wordGroups.keys.toList();
  final g = r.sample(groups);
  final other = r.sample(groups.where((x) => x != g).toList());
  if (lv >= 2 && r.chance(.5)) {
    final same = _pick(r, wordGroups[g]!, 3);
    final odd = r.sample(wordGroups[other]!);
    return Question(
      type: 'ar_groups', mode: QMode.choice, skill: 'group:$g', numeric: false,
      ask: 'أنهي كلمة مش من $g؟', speak: 'أنهي كلمة مش من $g؟',
      choices: r.shuffle([...same, odd]), answer: odd,
      hint: 'تلات كلمات من $g وواحدة لأ 🤔', speakHint: 'تلات كلمات من نفس المجموعة وواحدة لأ',
    );
  }
  final it = r.sample(wordGroups[g]!);
  final wrong = [for (final o in _pick(r, groups.where((x) => x != g).toList(), _n(lv) - 1)) r.sample(wordGroups[o]!)];
  return Question(
    type: 'ar_groups', mode: QMode.choice, skill: 'group:$g', numeric: false,
    ask: 'أنهي كلمة من $g؟', speak: 'أنهي كلمة من $g؟',
    choices: r.shuffle([it, ...wrong]), answer: it,
    hint: 'فكّر في $g اللي تعرفها 💭', speakHint: 'فكر في الكلمات اللي من المجموعة دي',
  );
}

// ================================================================ الحساب

// ---------------------------------------------------------------- تحليل العدد

/// ٥ = ٢ + ؟ بالدواير. من المستوى التالت: «أنهي اتنين مع بعض يعملوا ٥؟».
Question numBonds(int lv, Rng r, {String? focus}) {
  // focus = العدد اللي بنحلّله (مهارة bond:N) — من التعلّم المتكيّف أو درس «مكونات العدد»
  final f = int.tryParse(focus ?? '');
  final total = f != null && f >= 2 && f <= 10 ? f : switch (lv) { <= 1 => r.rnd(3, 5), 2 => r.rnd(4, 7), _ => r.rnd(5, 10) };
  final a = r.rnd(1, total - 1), b = total - a;
  if (lv >= 3 && r.chance(.5)) {
    final pairs = <(int, int)>{(a, b)};
    var guard = 0;
    while (pairs.length < 4 && guard++ < 40) {
      final x = r.rnd(1, total), y = r.rnd(1, total);
      if (x + y != total) pairs.add((x, y));
    }
    String shown((int, int) p) => '${ar(p.$1)} + ${ar(p.$2)}';
    final right = shown((a, b));
    return Question(
      type: 'numBonds', mode: QMode.choice, skill: 'bond:$total', numeric: false, wide: true,
      ask: 'أنهي اتنين مع بعض يعملوا ${ar(total)}؟', speak: 'أنهي اتنين مع بعض يعملوا ${arNum(total)}؟',
      choices: r.shuffle([for (final p in pairs) shown(p)]), answer: right,
      choiceSay: {for (final p in pairs) shown(p): '${arNum(p.$1)} زائد ${arNum(p.$2)}'},
      hint: 'اجمع الاتنين وشوف يطلعوا ${ar(total)} ولا لأ ➕', speakHint: 'اجمع الاتنين وشوف',
    );
  }
  return Question(
    type: 'numBonds', mode: QMode.choice, skill: 'bond:$total',
    ask: '${ar(total)} = ${ar(a)} + ؟', speak: '${arNum(total)} يساوي ${arNum(a)} زائد كام؟',
    visuals: [
      ExprVisual([ExprTile(total), const ExprOp('='), ExprSide('🔵', a, number: a), const ExprOp('+'), const ExprTile(null)]),
    ],
    choices: r.numberChoices(b, 3, 0, total), answer: b,
    hint: 'عُدّ من ${ar(a)} لحد ${ar(total)} على صوابعك ✋', speakHint: 'عد من ${arNum(a)} لحد ${arNum(total)}',
  );
}

// ---------------------------------------------------------------- الأعداد الترتيبية

const _queue = ['🐰', '🐢', '🦊', '🐻', '🐱', '🐶', '🐸', '🐵'];
const _queueNames = {'🐰': 'الأرنب', '🐢': 'السلحفاة', '🦊': 'التعلب', '🐻': 'الدب', '🐱': 'القطة', '🐶': 'الكلب', '🐸': 'الضفدع', '🐵': 'القرد'};

/// طابور حيوانات من عند العلم: «مين التالت؟» أو «الدب رقم كام؟».
Question ordinals(int lv, Rng r, {String? focus}) {
  final n = lv <= 1 ? 3 : (lv == 2 ? 4 : 5);
  final row = _pick(r, _queue, n);
  final i = r.rnd(0, n - 1);
  if (lv >= 2 && r.chance(.5)) {
    return Question(
      type: 'ordinals', mode: QMode.choice, skill: 'ord:$i', numeric: false,
      ask: '${_queueNames[row[i]]} رقم كام في الطابور؟', speak: '${_queueNames[row[i]]} رقم كام في الطابور؟',
      visuals: [QueueVisual(row)],
      choices: r.shuffle(ordinalWords.take(n).toList()),
      answer: ordinalWords[i],
      hint: 'عُدّ من عند العلم 🏁', speakHint: 'عد من عند العلم',
    );
  }
  return Question(
    type: 'ordinals', mode: QMode.choice, skill: 'ord:$i', numeric: false, bigChoices: true,
    ask: 'مين ${ordinalWords[i]} في الطابور؟', speak: 'مين ${ordinalWords[i]} في الطابور؟',
    visuals: [QueueVisual(row)],
    choices: r.shuffle([...row]), answer: row[i],
    choiceSay: {for (final e in row) e: _queueNames[e]!},
    hint: 'الأول هو اللي جنب العلم 🏁', speakHint: 'الأول هو اللي جنب العلم',
  );
}

// ---------------------------------------------------------------- الصفر والزوجي والفردي

/// صفر: «كام تفاحة في السلة؟» والسلة فاضية. زوجي/فردي: كل واحد ليه صاحب؟
Question zeroEvenOdd(int lv, Rng r, {String? focus}) {
  if (r.chance(lv <= 1 ? .4 : .25)) {
    final e = r.sample(const ['🍎', '🐟', '⭐', '🎈']);
    return Question(
      type: 'zeroEvenOdd', mode: QMode.choice, skill: 'zero',
      ask: 'كام صورة في الطبق؟', speak: 'كام صورة في الطبق؟',
      visuals: [EmojiVisual('🍽️', caption: 'الطبق فاضي — مافيهوش $e')],
      choices: r.shuffle([0, 1, 2]), answer: 0,
      hint: 'مفيش ولا واحدة = صفر ٠', speakHint: 'مفيش ولا واحدة يعني صفر', sayRight: 'صفر',
    );
  }
  final n = lv <= 1 ? r.rnd(2, 6) : r.rnd(3, 12);
  final even = n.isEven;
  return Question(
    type: 'zeroEvenOdd', mode: QMode.choice, skill: 'parity:${even ? 'even' : 'odd'}', numeric: false, wide: true,
    ask: '${ar(n)} زوجي ولا فردي؟', speak: '${arNum(n)} زوجي ولا فردي؟',
    visuals: [PairsVisual(r.sample(const ['🧦', '👟', '🧤', '🐥']), n)],
    choices: const ['زوجي (كله ليه صاحب)', 'فردي (واحد لوحده)'],
    answer: even ? 'زوجي (كله ليه صاحب)' : 'فردي (واحد لوحده)',
    choiceSay: const {'زوجي (كله ليه صاحب)': 'زوجي', 'فردي (واحد لوحده)': 'فردي'},
    hint: 'بص: فيه واحد فضل من غير صاحب؟ 👀', speakHint: 'بص، فيه واحد فضل من غير صاحب؟',
  );
}

// ---------------------------------------------------------------- الأشكال الهندسية

Question geometry(int lv, Rng r, {String? focus}) {
  final s = r.sample(lv <= 1 ? geoShapes.take(3).toList() : geoShapes);
  final kind = lv <= 1 ? 0 : r.rnd(0, 2);
  if (kind == 1 && s.$3 > 0) {
    return Question(
      type: 'geometry', mode: QMode.choice, skill: 'sides:${s.$1}',
      ask: '${s.$2} ليه كام ضلع؟', speak: '${s.$2} ليه كام ضلع؟',
      visuals: [ShapeVisual(s.$1)],
      choices: r.shuffle([3, 4, 5]), answer: s.$3,
      hint: 'عُدّ الخطوط اللي حوالين الشكل ✏️', speakHint: 'عد الخطوط اللي حوالين الشكل',
    );
  }
  if (kind == 2) {
    final (q, a) = r.sample(const [
      ('أنهي شكل مالوش أركان؟', 'circle'),
      ('أنهي شكل ليه ٣ أضلاع؟', 'triangle'),
      ('أنهي شكل أضلاعه الأربعة زي بعض؟', 'square'),
      ('أنهي شكل ليه ضلعين طوال وضلعين قصيرين؟', 'rect'),
    ]);
    return Question(
      type: 'geometry', mode: QMode.choice, skill: 'shapeFact:$a', numeric: false, look: ChoiceLook.shape,
      ask: q, speak: q,
      choices: r.shuffle(['circle|', 'triangle|', 'square|', 'rect|']), answer: '$a|',
      choiceSay: {for (final g in geoShapes) '${g.$1}|': g.$2},
      hint: 'بص على الأضلاع والأركان 👀', speakHint: 'بص على الأضلاع والأركان',
    );
  }
  final names = lv <= 1 ? geoShapes.take(3) : geoShapes;
  return Question(
    type: 'geometry', mode: QMode.choice, skill: 'shape:${s.$1}', numeric: false, wide: true,
    ask: 'اسم الشكل ده إيه؟', speak: 'اسم الشكل ده إيه؟',
    visuals: [ShapeVisual(s.$1)],
    choices: r.shuffle([for (final g in names) g.$2]), answer: s.$2,
    hint: 'عُدّ الأضلاع: ٣ = مثلث، ٤ = مربع أو مستطيل، ولا حاجة = دايرة', speakHint: 'عد الأضلاع',
  );
}

// ---------------------------------------------------------------- القياس

Question measure(int lv, Rng r, {String? focus}) {
  final kind = r.rnd(0, 2);
  if (kind == 0) {
    final heavy = r.sample(weights.where((w) => w.$3).toList()), light = r.sample(weights.where((w) => !w.$3).toList());
    final askHeavy = r.chance(.5);
    return Question(
      type: 'measure', mode: QMode.choice, skill: 'weight', numeric: false, bigChoices: true,
      ask: askHeavy ? 'أنهي أتقل؟' : 'أنهي أخف؟', speak: askHeavy ? 'أنهي أتقل؟' : 'أنهي أخف؟',
      choices: r.shuffle([heavy.$1, light.$1]), answer: askHeavy ? heavy.$1 : light.$1,
      choiceSay: {heavy.$1: heavy.$2, light.$1: light.$2},
      hint: 'تخيّل إنك شايله في إيدك 🤲', speakHint: 'تخيل إنك شايله في إيدك',
    );
  }
  if (kind == 1) {
    final lens = _pick(r, [2, 3, 4, 5, 6, 7], _n(lv) + (lv <= 1 ? 0 : 0));
    final longest = r.chance(.5);
    final a = longest ? lens.reduce(math.max) : lens.reduce(math.min);
    return Question(
      type: 'measure', mode: QMode.choice, skill: 'length', numeric: false, look: ChoiceLook.bar,
      ask: longest ? 'أنهي قلم أطول؟' : 'أنهي قلم أقصر؟', speak: longest ? 'أنهي قلم أطول؟' : 'أنهي قلم أقصر؟',
      choices: [for (final l in lens) '$l'], answer: '$a',
      choiceSay: {for (final l in lens) '$l': longest ? (l == a ? 'ده الأطول' : 'ده مش الأطول') : (l == a ? 'ده الأقصر' : 'ده مش الأقصر')},
      hint: 'قارن الأقلام من أولها ✏️', speakHint: 'قارن الأقلام من أولها',
    );
  }
  final e = r.sample(const ['🍎', '⭐', '🐟', '🌸']);
  final x = r.rnd(1, lv <= 1 ? 5 : 9);
  var y = r.rnd(1, lv <= 1 ? 5 : 9);
  if (y == x) y = x == 1 ? 3 : x - 1;
  final more = r.chance(.5);
  final a = more ? math.max(x, y) : math.min(x, y);
  return Question(
    type: 'measure', mode: QMode.choice, skill: 'quantity', numeric: false, look: ChoiceLook.group,
    ask: more ? 'أنهي فيها أكتر؟' : 'أنهي فيها أقل؟', speak: more ? 'أنهي فيها أكتر؟' : 'أنهي فيها أقل؟',
    choices: ['$e|$x', '$e|$y'], answer: '$e|$a',
    choiceSay: {'$e|$x': arNum(x), '$e|$y': arNum(y)},
    hint: 'عُدّ كل مجموعة 👆', speakHint: 'عد كل مجموعة',
  );
}

// ---------------------------------------------------------------- الجنيه ونصه وربعه

/// فلوس مصرية صغيرة: ربع جنيه ونص جنيه وجنيه وورقة ٥ و١٠.
const coinNames = {'q': 'ربع جنيه', 'h': 'نص جنيه', '1': 'جنيه', '5': 'خمسة جنيه', '10': 'عشرة جنيه'};

/// قيمة كل عملة بالربع (ربع جنيه = ١).
const _coinQuarters = {'q': 1, 'h': 2, '1': 4, '5': 20, '10': 40};

/// المبلغ بالكلام: "جنيه ونص"، "٣ جنيه إلا ربع" — [spoken] بيكتب الأرقام بالحروف للصوت.
String _quartersWord(int q, {bool spoken = false}) {
  String n(int x) => spoken ? arNum(x) : ar(x);
  final pounds = q ~/ 4, rest = q % 4;
  final p = pounds == 0 ? '' : (pounds == 1 ? 'جنيه' : (pounds == 2 ? 'جنيهين' : '${n(pounds)} جنيه'));
  final r = switch (rest) { 1 => 'ربع', 2 => 'نص', 3 => 'إلا ربع', _ => '' };
  if (pounds == 0) return rest == 2 ? 'نص جنيه' : (rest == 1 ? 'ربع جنيه' : 'تلاتة ربع جنيه');
  if (rest == 3) return pounds + 1 == 2 ? 'جنيهين إلا ربع' : '${n(pounds + 1)} جنيه إلا ربع';
  return r.isEmpty ? p : '$p و$r';
}

Question coins(int lv, Rng r, {String? focus}) {
  if (lv <= 1 || r.chance(.4)) {
    final keys = coinNames.keys.toList();
    final k = r.sample(lv <= 1 ? const ['h', '1', '5', '10'] : keys);
    return Question(
      type: 'coins', mode: QMode.choice, skill: 'coin:$k', numeric: false, look: ChoiceLook.coin,
      ask: 'فين ال${coinNames[k]}؟', speak: 'فين ال${coinNames[k]}؟',
      choices: _with(r, k, keys, _n(lv) + 1), answer: k,
      choiceSay: coinNames,
      hint: 'اقرا الرقم المكتوب على الفلوس 🪙', speakHint: 'اقرا الرقم المكتوب على الفلوس',
    );
  }
  final pool = lv >= 3 ? const ['q', 'h', '1'] : const ['h', '1'];
  final pieces = [for (var i = 0; i < r.rnd(2, lv >= 3 ? 4 : 3); i++) r.sample(pool)]
    ..sort((a, b) => _coinQuarters[b]! - _coinQuarters[a]!);
  final total = pieces.fold(0, (s, k) => s + _coinQuarters[k]!);
  final right = _quartersWord(total);
  final wrong = {for (final d in [-2, -1, 1, 2]) if (total + d > 0) _quartersWord(total + d)}..remove(right);
  final shown = r.shuffle([right, ...r.shuffle(wrong.toList()).take(2)]);
  final spoken = {for (var q = 1; q <= total + 2; q++) _quartersWord(q): _quartersWord(q, spoken: true)};
  return Question(
    type: 'coins', mode: QMode.choice, skill: 'coinSum', numeric: false, wide: true,
    ask: 'كام فلوس كلهم؟', speak: 'كام فلوس كلهم؟',
    visuals: [CoinsVisual(pieces)],
    choices: shown, answer: right,
    choiceSay: {for (final c in shown) c: spoken[c]!},
    hint: 'نصّين = جنيه، و٤ أرباع = جنيه 🪙', speakHint: 'نصين يعملوا جنيه، وأربع أرباع يعملوا جنيه',
  );
}

// ---------------------------------------------------------------- الأسبوع والشهور والفصول

Question calendar(int lv, Rng r, {String? focus}) {
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 3);
  switch (kind) {
    case 0:
      final (name, pic, things) = r.sample(seasons);
      final it = r.sample(things);
      return Question(
        type: 'calendar', mode: QMode.choice, skill: 'season:$name', numeric: false, wide: true,
        ask: 'ده بيبقى في أنهي فصل؟', speak: 'ده بيبقى في أنهي فصل؟',
        visuals: [EmojiVisual(it)],
        choices: r.shuffle([for (final s in seasons) '${s.$2} ${s.$1}']).take(lv <= 1 ? 4 : 4).toList(),
        answer: '$pic $name',
        choiceSay: {for (final s in seasons) '${s.$2} ${s.$1}': s.$1},
        hint: 'فكّر: الجو بيبقى عامل إزاي؟ 🌤️', speakHint: 'فكر، الجو بيبقى عامل إزاي؟',
      );
    case 1:
      final i = r.rnd(0, weekDays.length - 1);
      final next = weekDays[(i + 1) % 7];
      return Question(
        type: 'calendar', mode: QMode.choice, skill: 'day', numeric: false, wide: true,
        ask: 'إيه اليوم اللي بعد ${weekDays[i]}؟', speak: 'إيه اليوم اللي بعد ${weekDays[i]}؟',
        choices: _with(r, next, weekDays, 3), answer: next,
        hint: 'السبت، الحد، الاتنين، التلات، الأربع، الخميس، الجمعة 📅', speakHint: 'السبت، الحد، الاتنين، التلات، الأربع، الخميس، الجمعة',
      );
    case 2:
      final i = r.rnd(0, months.length - 2);
      return Question(
        type: 'calendar', mode: QMode.choice, skill: 'month', numeric: false, wide: true,
        ask: 'إيه الشهر اللي بعد ${months[i]}؟', speak: 'إيه الشهر اللي بعد ${months[i]}؟',
        choices: _with(r, months[i + 1], months, 3), answer: months[i + 1],
        hint: 'الشهور: يناير، فبراير، مارس… 📅', speakHint: 'يناير، فبراير، مارس، وهكذا',
      );
    default:
      final start = r.rnd(0, 3);
      final seq = [for (var k = 0; k < 4; k++) weekDays[(start + k) % 7]];
      return Question(
        type: 'calendar', mode: QMode.order, numeric: false, skill: 'dayOrder', rtlSlots: true,
        ask: 'رتّب الأيام', speak: 'رتب الأيام بالترتيب',
        orderHint: 'اضغط الأيام بالترتيب',
        items: r.shuffle([...seq]), answer: seq,
        hint: 'السبت، الحد، الاتنين، التلات، الأربع، الخميس، الجمعة 📅', speakHint: 'السبت، الحد، الاتنين، التلات، الأربع، الخميس، الجمعة',
      );
  }
}

// ---------------------------------------------------------------- المسائل الكلامية

/// «عند أحمد ٣ تفاحات واشترى ٢. بقى معاه كام؟» بالصور. الصوت متركّب من جمل صغيرة + أرقام.
Question wordProblem(int lv, Rng r, {String? focus}) {
  final (kid, girl) = r.sample(problemKids);
  final (one, many, pic) = r.sample(problemThings);
  final add = lv <= 1 || r.chance(.6);
  final a = add ? r.rnd(3, lv <= 1 ? 5 : 7) : r.rnd(4, lv <= 2 ? 7 : 9);
  final b = add ? r.rnd(1, lv <= 1 ? 2 : 3) : r.rnd(1, a - 1);
  final ans = add ? a + b : a - b;
  final has = girl ? 'معاها' : 'معاه';
  final verb = add ? (girl ? 'وجابت كمان' : 'وجاب كمان') : (girl ? 'وادّت صاحبتها' : 'وادّى صاحبه');
  final text = 'عند $kid ${ar(a)} $many $verb ${ar(b)}. بقى $has كام $one؟';
  return Question(
    type: 'wordProblem', mode: QMode.choice, skill: add ? 'wp:add' : 'wp:sub',
    ask: text,
    speak: 'عند $kid ${arNum(a)} $many $verb ${arNum(b)}. بقى $has كام $one؟',
    clips: [say('عند $kid'), nk(a), say(many), say(verb), nk(b), say('بقى $has كام $one؟')],
    visuals: [
      ExprVisual([ExprSide(pic, a, number: a), ExprOp(add ? '+' : '-'), ExprSide(pic, b, number: b)]),
    ],
    choices: r.numberChoices(ans, 3, 0, 12), answer: ans,
    hint: add ? 'جاب كمان يعني نجمع ➕' : 'ادّى يعني نطرح ➖', speakHint: add ? 'جاب كمان يعني نجمع' : 'ادى يعني نطرح',
  );
}

// ---------------------------------------------------------------- الرسم البياني بالصور

const _graphPics = [('🍎', 'التفاح'), ('🍌', 'الموز'), ('🍇', 'العنب'), ('🍓', 'الفراولة')];

/// أعمدة صور: «أنهي أكتر؟» و«كام موزة؟»، وفي الآخر «الموز أكتر من التفاح بكام؟».
Question picGraph(int lv, Rng r, {String? focus}) {
  final kinds = _pick(r, _graphPics, lv <= 1 ? 2 : 3);
  final counts = _pick(r, [1, 2, 3, 4, 5, 6], kinds.length);
  final rows = [for (var i = 0; i < kinds.length; i++) (kinds[i].$1, counts[i])];
  final kind = lv <= 1 ? r.rnd(0, 1) : r.rnd(0, 2);
  if (kind == 0) {
    final most = r.chance(.5);
    final target = most ? counts.reduce(math.max) : counts.reduce(math.min);
    final it = kinds[counts.indexOf(target)];
    return Question(
      type: 'picGraph', mode: QMode.choice, skill: 'graph:compare', numeric: false, bigChoices: true,
      ask: most ? 'أنهي فاكهة أكتر؟' : 'أنهي فاكهة أقل؟', speak: most ? 'أنهي فاكهة أكتر؟' : 'أنهي فاكهة أقل؟',
      visuals: [PicGraphVisual(rows)],
      choices: r.shuffle([for (final k in kinds) k.$1]), answer: it.$1,
      choiceSay: {for (final k in kinds) k.$1: k.$2},
      hint: 'العمود الأطول = الأكتر 📊', speakHint: 'العمود الأطول هو الأكتر',
    );
  }
  if (kind == 1) {
    final i = r.rnd(0, kinds.length - 1);
    return Question(
      type: 'picGraph', mode: QMode.choice, skill: 'graph:count',
      ask: 'كام ${kinds[i].$1}؟', speak: 'عدد ${kinds[i].$2} كام؟',
      visuals: [PicGraphVisual(rows)],
      choices: r.numberChoices(counts[i], 3, 1, 7), answer: counts[i],
      hint: 'عُدّ العمود بتاعه من تحت لفوق 👆', speakHint: 'عد العمود بتاعه من تحت لفوق',
    );
  }
  final hi = counts.indexOf(counts.reduce(math.max)), lo = counts.indexOf(counts.reduce(math.min));
  final diff = counts[hi] - counts[lo];
  return Question(
    type: 'picGraph', mode: QMode.choice, skill: 'graph:diff',
    ask: '${kinds[hi].$1} أكتر من ${kinds[lo].$1} بكام؟', speak: '${kinds[hi].$2} أكتر من ${kinds[lo].$2} بكام؟',
    visuals: [PicGraphVisual(rows)],
    choices: r.numberChoices(diff, 3, 1, 6), answer: diff,
    hint: 'اطرح العدد الصغير من الكبير ➖', speakHint: 'اطرح العدد الصغير من الكبير',
  );
}
