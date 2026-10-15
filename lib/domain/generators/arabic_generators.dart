/// مولّدات عالم اللغة العربية — منقولة من js/arabic.js.
library;

import '../../content/language_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// عدد الحروف المتاحة حسب المستوى — الطفل مايتحاصرش بكل الأبجدية من أول يوم.
List<Letter> arPool(int lv) => arLetters.sublist(0, const [10, 18, 28, 28][lv.clamp(1, 4) - 1]);

List<Word> arWordPool(int lv) {
  final maxLen = const [3, 4, 5, 6][lv.clamp(1, 4) - 1];
  return arWords.where((w) => w.word.length <= maxLen).toList();
}

List<String> _letters(String w) => w.split('');

/// الحروف والكلمات أجزاء لوحدها في المقاطع عشان تتنطق بالفصحى (lib/core/audio/teaching.dart).
List<String> _spell(String w) => [for (final l in _letters(w)) say(l)];

T _pick<T>(List<T> pool, Rng r, bool Function(T) matchesFocus, String? focus) {
  if (focus != null) {
    for (final x in pool) {
      if (matchesFocus(x)) return x;
    }
  }
  return r.sample(pool);
}

Letter _letterFor(int lv, Rng r, String? focus) =>
    _pick(arPool(lv), r, (x) => x.letter == focus, focus);

Word _wordFor(int lv, Rng r, String? focus) =>
    _pick(arWordPool(lv), r, (x) => x.word == focus, focus);

/// ١ — اختر الحرف: الصورة والكلمة ظاهرين والحرف ناقص.
Question arPick(int lv, Rng r, {String? focus}) {
  final pool = arPool(lv);
  final it = _letterFor(lv, r, focus);
  return Question(
    type: 'ar_pick', mode: QMode.choice, skill: 'ar_letter:${it.letter}',
    ask: 'اختار الحرف الصحيح',
    speak: '${it.word}. اختار الحرف اللي بتبدأ بيه',
    clips: [say(it.word), say('اختار الحرف اللي بتبدأ بيه')],
    visuals: [PicsVisual(it.emoji, 1), CaptionVisual('؟ مثل ${it.word}')],
    choices: r.textChoices(it.letter, [for (final x in pool) x.letter], lv >= 3 ? 4 : 3),
    answer: it.letter,
    hint: '${it.word} بتبدأ بحرف ${it.letter} 👆',
    speakHint: '${it.word} بتبدأ بحرف ${it.letter}',
    clipsHint: [say(it.word), say('بتبدأ بحرف'), say(it.letter)],
  );
}

/// ٢ — طابق الحرف بالصورة.
Question arMatch(int lv, Rng r, {String? focus}) {
  final pool = arPool(lv);
  final it = _letterFor(lv, r, focus);
  return Question(
    type: 'ar_match', mode: QMode.choice, skill: 'ar_letter:${it.letter}',
    ask: 'أنهي صورة تبدأ بحرف ${it.letter} ؟',
    speak: 'أنهي صورة بتبدأ بحرف ${it.letter}؟',
    clips: [say('أنهي صورة بتبدأ بحرف'), say(it.letter)],
    visuals: [BigLetterVisual(it.letter)],
    choices: r.textChoices(it.emoji, [for (final x in pool) x.emoji], lv >= 3 ? 4 : 3),
    answer: it.emoji,
    hint: '${it.letter} مثل ${it.word} ${it.emoji}',
    speakHint: '${it.letter} مثل ${it.word}',
    clipsHint: [say(it.letter), say('مثل'), say(it.word)],
  );
}

/// ٣ — كوّن الكلمة: ترتيب الحروف.
Question arBuild(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  final letters = _letters(it.word);
  return Question(
    type: 'ar_build', mode: QMode.order, numeric: false, rtlSlots: true, skill: 'ar_word:${it.word}',
    ask: 'كوّن الكلمة', speak: 'كوّن كلمة ${it.word}', clips: [say('كوّن كلمة'), say(it.word)],
    orderHint: 'اضغط الحروف بالترتيب من اليمين',
    visuals: [PicsVisual(it.emoji, 1), WordLineVisual.text(it.word, big: true)],
    items: r.shuffle(<Object>[...letters]),
    answer: letters,
    hint: 'الكلمة هي ${it.word} — ابدأ بأول حرف 👆',
    speakHint: 'الكلمة هي ${it.word}',
    clipsHint: [say('الكلمة هي'), say(it.word)],
  );
}

/// ٤ — كوّن الكلمة من حروفها: ك + ت + ب ← كتب.
Question arCompose(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  final letters = _letters(it.word);
  return Question(
    type: 'ar_compose', mode: QMode.choice, skill: 'ar_word:${it.word}',
    ask: 'الحروف دي بتكوّن أنهي كلمة؟',
    speak: '${letters.join(' ')} . الحروف دي بتكوّن أنهي كلمة؟',
    clips: [..._spell(it.word), say('الحروف دي بتكوّن أنهي كلمة؟')],
    visuals: [LetterChipsVisual(letters)],
    choices: r.textChoices(it.word, [for (final x in arWords) x.word], 3),
    answer: it.word, wide: true,
    hint: 'اقرا الحروف ورا بعض: ${letters.join(' ')}',
    speakHint: 'اقرا الحروف ورا بعض: ${letters.join(' ')}',
    clipsHint: [say('اقرا الحروف ورا بعض'), ..._spell(it.word)],
  );
}

/// ٥ — حلّل الكلمة: الكلمة ظاهرة والطفل يطلّع حروفها بالترتيب.
Question arAnalyze(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  final letters = _letters(it.word);
  final items = <Object>[...letters];
  // في المستويات الأعلى نحط حرف دخيل عشان الطفل ياخد باله
  if (lv >= 3) {
    final extra = [for (final x in arLetters) if (!letters.contains(x.letter)) x.letter];
    items.add(r.sample(extra));
  }
  return Question(
    type: 'ar_analyze', mode: QMode.order, numeric: false, rtlSlots: true, skill: 'ar_word:${it.word}',
    orderHint: 'اضغط الحروف بالترتيب من اليمين',
    ask: 'حلّل الكلمة لحروفها',
    speak: 'حلّل كلمة ${it.word} لحروفها بالترتيب',
    clips: [say('حلّل كلمة'), say(it.word), say('لحروفها بالترتيب')],
    visuals: [WordLineVisual.text(it.word, big: true)],
    items: r.shuffle(items),
    answer: letters,
    hint: 'اقرا الكلمة بالراحة: ${letters.join(' - ')}',
    speakHint: '${it.word}. اقرا حروفها بالترتيب',
    clipsHint: [say(it.word), say('اقرا حروفها بالترتيب')],
  );
}

/// ٦ — وصّل الكلمة بحروفها.
Question arConnect(int lv, Rng r, {String? focus}) {
  final pool = arWordPool(lv);
  final n = lv >= 3 ? 4 : 3;
  var picks = r.shuffle([...pool]).take(n).toList();
  final want = focus == null ? null : pool.where((x) => x.word == focus).firstOrNull;
  if (want != null && !picks.any((p) => p.word == want.word)) {
    picks = r.shuffle([want, ...picks.take(n - 1)]);
  }
  String spell(String w) => _letters(w).join(' ـ ');
  return Question(
    type: 'ar_connect', mode: QMode.pairs, skill: 'ar_word:${picks.first.word}',
    ask: 'وصّل الكلمة بحروفها', speak: 'وصّل كل كلمة بحروفها',
    items: r.shuffle(<Object>[for (final p in picks) p.word]),
    right: r.shuffle([for (final p in picks) spell(p.word)]),
    pairMap: {for (final p in picks) p.word: spell(p.word)},
    wide: true,
    skillOf: (v) => 'ar_word:$v',
    hint: 'اضغط الكلمة الأول، وبعدين حروفها',
    speakHint: 'اضغط الكلمة الأول، وبعدين دوّر على حروفها',
  );
}

/// ٧ — أكمل جدول الحروف.
Question arTable(int lv, Rng r, {String? focus}) {
  final all = [for (final x in arLetters) x.letter];
  final holeCount = const [2, 3, 4, 5][lv.clamp(1, 4) - 1];
  final holes = <String>{};
  while (holes.length < holeCount) {
    holes.add(r.sample(all));
  }
  final sorted = holes.toList()..sort((a, b) => all.indexOf(a) - all.indexOf(b));
  final opts = <Object>[...sorted];
  if (lv >= 3) {
    String d;
    var guard = 0;
    do {
      d = r.sample(all);
    } while (holes.contains(d) && guard++ < 40);
    opts.add(d);
  }
  return Question(
    type: 'ar_table', mode: QMode.grid, numeric: false, skill: 'ar_alphabet',
    ask: 'أكمل جدول الحروف',
    speak: 'أكمل جدول الحروف. إيه الحروف الناقصة؟',
    visuals: [TableVisual([for (final v in all) holes.contains(v) ? null : v], kind: TableKind.arLetters)],
    items: r.shuffle(opts), answer: sorted,
    hint: 'قول الحروف من الألف لحد الخانة الفاضية',
    speakHint: 'قول الحروف من الألف لحد الخانة الفاضية',
  );
}

/// ٨ — أكمل الكلمة: حرف ناقص.
Question arComplete(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  final letters = _letters(it.word);
  final hole = r.rnd(0, letters.length - 1);
  final miss = letters[hole];
  return Question(
    type: 'ar_complete', mode: QMode.choice, skill: 'ar_word:${it.word}',
    ask: 'أكمل الكلمة', speak: 'أكمل كلمة ${it.word}. إيه الحرف الناقص؟',
    clips: [say('أكمل كلمة'), say(it.word), say('إيه الحرف الناقص؟')],
    visuals: [
      PicsVisual(it.emoji, 1),
      WordLineVisual.letters([for (var i = 0; i < letters.length; i++) i == hole ? null : letters[i]]),
    ],
    choices: r.textChoices(miss, [for (final x in arLetters) x.letter], lv >= 3 ? 4 : 3),
    answer: miss,
    hint: 'الكلمة هي ${it.word}',
    speakHint: 'الكلمة هي ${it.word}',
    clipsHint: [say('الكلمة هي'), say(it.word)],
  );
}

/// ٩ — اختار الكلمة الصحيحة: من الصورة للكلمة.
Question arChooseWord(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  return Question(
    type: 'ar_choose_word', mode: QMode.choice, skill: 'ar_word:${it.word}',
    ask: 'اختار الكلمة الصحيحة', speak: 'اختار الكلمة الصحيحة',
    visuals: [PicsVisual(it.emoji, 1, big: true)],
    choices: r.textChoices(it.word, [for (final x in arWords) x.word], 3),
    answer: it.word, wide: true,
    hint: 'اقرا الكلمات بالراحة وشوف أنهي واحدة تناسب الصورة',
    speakHint: 'اقرا الكلمات بالراحة',
  );
}

/// ١٠ — طابق الكلمة بالصورة: من الكلمة للصورة.
Question arMatchWord(int lv, Rng r, {String? focus}) {
  final it = _wordFor(lv, r, focus);
  return Question(
    type: 'ar_match_word', mode: QMode.choice, skill: 'ar_word:${it.word}',
    ask: 'أنهي صورة للكلمة دي؟', speak: '${it.word}. أنهي صورة للكلمة دي؟',
    clips: [say(it.word), say('أنهي صورة للكلمة دي؟')],
    visuals: [WordLineVisual.text(it.word, big: true)],
    choices: r.textChoices(it.emoji, [for (final x in arWords) x.emoji], 3),
    answer: it.emoji,
    hint: 'اقرا الكلمة حرف حرف: ${_letters(it.word).join(' - ')}',
    speakHint: 'اقرا الكلمة بالراحة: ${it.word}',
    clipsHint: [say('اقرا الكلمة بالراحة'), say(it.word)],
  );
}
