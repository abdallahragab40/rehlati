/// مولّدات English World — منقولة من js/english.js. النطق بصوت إنجليزي (lang: 'en').
library;

import '../../content/language_data.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

List<Letter> enPool(int lv) => enLetters.sublist(0, const [10, 18, 26, 26][lv.clamp(1, 4) - 1]);

Letter _letterFor(List<Letter> pool, Rng r, String? focus) =>
    pool.where((x) => x.letter == focus).firstOrNull ?? r.sample(pool);

/// Choose the letter — picture + word, letter missing.
Question enPick(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = _letterFor(pool, r, focus);
  return Question(
    type: 'en_pick', mode: QMode.choice, lang: 'en', ltr: true, skill: 'en_letter:${it.letter}',
    ask: 'Which letter?', speak: '${it.word}. Which letter does it start with?',
    visuals: [PicsVisual(it.emoji, 1), CaptionVisual('? is for ${it.word}')],
    choices: r.textChoices(it.letter, [for (final x in pool) x.letter], lv >= 3 ? 4 : 3),
    answer: it.letter,
    hint: '${it.word} starts with ${it.letter}',
    speakHint: '${it.word} starts with ${it.letter}',
  );
}

/// Match letter with picture.
Question enMatch(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = _letterFor(pool, r, focus);
  return Question(
    type: 'en_match', mode: QMode.choice, lang: 'en', ltr: true, skill: 'en_letter:${it.letter}',
    ask: 'Which picture starts with ${it.letter} ?',
    speak: 'Which picture starts with the letter ${it.letter}?',
    visuals: [BigLetterVisual(it.letter)],
    choices: r.textChoices(it.emoji, [for (final x in pool) x.emoji], lv >= 3 ? 4 : 3),
    answer: it.emoji,
    hint: '${it.letter} is for ${it.word} ${it.emoji}',
    speakHint: '${it.letter} is for ${it.word}',
  );
}

/// Complete the word — one missing letter.
///
/// نسخة الويب كانت بتعرض الكلمة بحروف صغيرة والاختيارات كابيتل دايمًا ("pple" و"A").
/// هنا الاختيارات بتيجي بنفس حالة الحرف الناقص.
Question enComplete(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = pool.where((x) => x.word == focus).firstOrNull ?? r.sample<Letter>(pool);
  final letters = it.word.replaceAll(RegExp(r'\s'), '').split('');
  final hole = r.rnd(0, letters.length - 1);
  final miss = letters[hole];
  final upper = miss == miss.toUpperCase();
  return Question(
    type: 'en_complete', mode: QMode.choice, lang: 'en', ltr: true, skill: 'en_word:${it.word}',
    ask: 'Complete the word', speak: 'Complete the word ${it.word}',
    visuals: [
      PicsVisual(it.emoji, 1),
      WordLineVisual.letters([for (var i = 0; i < letters.length; i++) i == hole ? null : letters[i]]),
    ],
    choices: r.textChoices(
        miss, [for (final x in enLetters) upper ? x.letter : x.letter.toLowerCase()], lv >= 3 ? 4 : 3),
    answer: miss,
    hint: 'The word is ${it.word}',
    speakHint: 'The word is ${it.word}',
  );
}

/// Choose the correct word.
Question enWord(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = pool.where((x) => x.word == focus).firstOrNull ?? r.sample<Letter>(pool);
  return Question(
    type: 'en_word', mode: QMode.choice, lang: 'en', ltr: true, wide: true, skill: 'en_word:${it.word}',
    ask: 'Choose the correct word', speak: 'Choose the correct word',
    visuals: [PicsVisual(it.emoji, 1, big: true)],
    choices: r.textChoices(it.word, [for (final x in enLetters) x.word], 3),
    answer: it.word,
    hint: 'Look at the picture and read each word',
    speakHint: 'Look at the picture and read each word',
  );
}

/// Big & small — الكابيتل والسمول في الاتجاهين.
Question enCase(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = _letterFor(pool, r, focus);
  final big = it.letter, small = it.letter.toLowerCase();
  final toSmall = r.chance(.5); // الاتجاه بيتبدّل عشوائيًا
  final shown = toSmall ? big : small;
  final answer = toSmall ? small : big;
  final others = [for (final x in pool) if (x.letter != big) toSmall ? x.letter.toLowerCase() : x.letter];
  return Question(
    type: 'en_case', mode: QMode.choice, lang: 'en', ltr: true, skill: 'en_case:$big',
    ask: toSmall ? 'Find the small letter' : 'Find the BIG letter',
    speak: toSmall ? 'Which one is the small $big?' : 'Which one is the big $big?',
    visuals: [BigLetterVisual(shown)],
    choices: r.shuffle(<Object>[answer, ...r.shuffle(others).take(lv >= 3 ? 3 : 2)]),
    answer: answer,
    hint: toSmall ? 'Big $big and small $small are the same letter' : 'Small $small and big $big are the same letter',
    speakHint: '$big and $small are the same letter',
  );
}

List<Letter> _picksWithFocus(List<Letter> pool, int n, Rng r, String? focus) {
  var picks = r.shuffle([...pool]).take(n).toList();
  final want = pool.where((x) => x.letter == focus).firstOrNull;
  if (want != null && !picks.any((p) => p.letter == want.letter)) {
    picks = r.shuffle([want, ...picks.take(n - 1)]);
  }
  return picks;
}

String _caseSkill(String v) => 'en_case:${v.toUpperCase()}';

/// Match big with small — توصيل عمودين.
Question enPairs(int lv, Rng r, {String? focus}) {
  final picks = _picksWithFocus(enPool(lv), lv >= 3 ? 5 : 4, r, focus);
  return Question(
    type: 'en_pairs', mode: QMode.pairs, lang: 'en', ltr: true, skill: 'en_case:${picks.first.letter}',
    ask: 'Match big and small', speak: 'Match each big letter with its small letter',
    items: r.shuffle(<Object>[for (final p in picks) p.letter]),
    right: r.shuffle([for (final p in picks) p.letter.toLowerCase()]),
    pairMap: {for (final p in picks) p.letter: p.letter.toLowerCase()},
    skillOf: _caseSkill,
    hint: 'Tap a big letter, then its small one',
    speakHint: 'Tap a big letter, then tap its small letter',
  );
}

/// Circle the letter — ضع دائرة حول كل حرف مشابه (كابيتل وسمول).
Question enCircle(int lv, Rng r, {String? focus}) {
  final pool = enPool(lv);
  final it = _letterFor(pool, r, focus);
  final i = lv.clamp(1, 4) - 1;
  final hits = const [3, 3, 4, 4][i], total = const [12, 15, 18, 20][i];
  final big = it.letter, small = it.letter.toLowerCase();
  final others = pool.where((x) => x.letter != big).toList();
  // الحرف المطلوب بالحالتين — الطفل لازم يشوف A و a على إنهم نفس الحرف
  final cells = <FindCell>[
    for (var k = 0; k < hits; k++) FindCell(r.chance(.5) ? big : small, hit: true),
  ];
  while (cells.length < total) {
    final d = r.sample(others);
    cells.add(FindCell(r.chance(.5) ? d.letter : d.letter.toLowerCase(), hit: false));
  }
  return Question(
    type: 'en_circle', mode: QMode.find, lang: 'en', ltr: true, skill: 'en_case:$big',
    ask: 'Circle every $big$small',
    speak: 'Find every letter $big. Big $big and small $small.',
    visuals: [BigLetterVisual('$big $small')],
    cells: r.shuffle(cells), hits: hits,
    hint: 'Big $big and small $small are both the same letter',
    speakHint: 'Big $big and small $small are the same letter',
  );
}

/// Find the friends — لعبة ذاكرة: كل حرف صاحبه هو نفسه بالحالة التانية.
Question enFriends(int lv, Rng r, {String? focus}) {
  final picks = _picksWithFocus(enPool(lv), const [3, 4, 4, 5][lv.clamp(1, 4) - 1], r, focus);
  final cards = r.shuffle([
    for (final p in picks) ...[MemoryCard(p.letter, p.letter), MemoryCard(p.letter, p.letter.toLowerCase())],
  ]);
  return Question(
    type: 'en_friends', mode: QMode.memory, lang: 'en', ltr: true, skill: 'en_case:${picks.first.letter}',
    ask: 'Find the friends', speak: 'Find the friends. Every big letter has a small friend.',
    cards: cards, pairs: picks.length,
    skillOf: _caseSkill,
    hint: 'Flip two cards. A and a are friends!',
    speakHint: 'Big A and small a are friends',
  );
}

/// Complete the alphabet — جدول الحروف الناقصة.
Question enTable(int lv, Rng r, {String? focus}) {
  final all = [for (final x in enLetters) x.letter];
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
    type: 'en_table', mode: QMode.grid, numeric: false, lang: 'en', ltr: true, skill: 'en_alphabet',
    ask: 'Complete the alphabet', speak: 'Complete the alphabet. Which letters are missing?',
    visuals: [TableVisual([for (final v in all) holes.contains(v) ? null : v], kind: TableKind.enLetters)],
    items: r.shuffle(opts), answer: sorted,
    hint: 'Say the alphabet from A until you reach the empty box',
    speakHint: 'Say the alphabet from A until you reach the empty box',
  );
}

/// مولّد عام لأي قائمة مفردات: صورة ← الكلمة.
/// [ask] السؤال، و[hint] جملة التلميح للكلمة الصح (مثلًا "They feel happy").
Question Function(int, Rng, {String? focus}) vocabGame(String type, List<Word> list, String skillTag,
    {String ask = 'What is this?', String Function(String word)? hint}) {
  return (int lv, Rng r, {String? focus}) {
    final n = [6, 8, 10, list.length][lv.clamp(1, 4) - 1];
    final pool = list.take(n).toList();
    final it = pool.where((x) => x.word == focus).firstOrNull ?? r.sample<Word>(pool);
    final h = hint?.call(it.word) ?? 'It is ${it.word}';
    return Question(
      type: type, mode: QMode.choice, lang: 'en', ltr: true, wide: true, skill: '$skillTag:${it.word}',
      ask: ask, speak: ask,
      visuals: [PicsVisual(it.emoji, 1, big: true)],
      choices: r.textChoices(it.word, [for (final x in pool) x.word], 3),
      answer: it.word,
      hint: h,
      speakHint: h,
    );
  };
}

final enNumbersGame = vocabGame('en_numbers', enNumbers, 'en_num');
final enColorsGame = vocabGame('en_colors', enColors, 'en_color');
final enAnimalsGame = vocabGame('en_animals', enAnimals, 'en_animal');
final enDailyGame = vocabGame('en_daily', enDaily, 'en_daily');
