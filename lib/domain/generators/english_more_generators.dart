/// English بعد المراجعة: Phonics (صوت الحرف مش اسمه، وتجميع CVC)، ومفردات أكتر،
/// وsight words، وجمل يومية.
library;

import '../../content/basics_data.dart';
import '../../core/utils/rng.dart';
import '../question.dart';
import 'english_generators.dart';

/// الصوت بيتقال بالـ TTS بتاع الجهاز: الحرف بصوته مرتين ("buh, buh").
String _sound(String s) => '$s, $s';

/// «Which picture starts with /b/?» — الطفل بيسمع الصوت ويختار الصورة.
Question enPhonics(int lv, Rng r, {String? focus}) {
  final pool = lv <= 1 ? phonics.take(8).toList() : phonics;
  final (letter, sound, words) = phonics.where((p) => p.$1 == focus).firstOrNull ?? r.sample(pool);
  final right = r.sample(words);
  final others = r.shuffle([for (final p in pool) if (p.$1 != letter) r.sample(p.$3)]).take(lv <= 1 ? 1 : 2);
  final shown = r.shuffle([right, ...others]);
  return Question(
    type: 'en_phonics', mode: QMode.choice, lang: 'en', ltr: true, skill: 'phon:$letter', numeric: false,
    bigChoices: true,
    ask: 'Which one starts with the “${letter.toLowerCase()}” sound?', speak: 'Which one starts with ${_sound(sound)}?',
    visuals: [BigLetterVisual(letter), ListenVisual(_sound(sound), en: true)],
    choices: [for (final w in shown) w.emoji], answer: right.emoji,
    choiceSay: {for (final w in shown) w.emoji: w.word},
    hint: '${right.word} starts with ${letter.toLowerCase()} 👂', speakHint: '${right.word}. ${_sound(sound)}',
    sayRight: '${_sound(sound)}, ${right.word}',
  );
}

/// «What sound does 🐶 start with?» — صورة وبيختار الحرف بصوته.
Question enFirstSound(int lv, Rng r, {String? focus}) {
  final pool = lv <= 1 ? phonics.take(8).toList() : phonics;
  final (letter, sound, words) = phonics.where((p) => p.$1 == focus).firstOrNull ?? r.sample(pool);
  final w = r.sample(words);
  final letters = r.shuffle([letter, ...r.shuffle([for (final p in pool) if (p.$1 != letter) p.$1]).take(lv <= 1 ? 2 : 3)]);
  return Question(
    type: 'en_firstsound', mode: QMode.choice, lang: 'en', ltr: true, skill: 'phon:$letter', numeric: false,
    bigChoices: true,
    ask: 'What sound does it start with?', speak: '${w.word}. What sound does it start with?',
    visuals: [PicsVisual(w.emoji, 1, big: true)],
    choices: letters, answer: letter,
    choiceSay: {for (final p in pool) if (letters.contains(p.$1)) p.$1: _sound(p.$2)},
    hint: 'Say it slowly: ${w.word} 🗣️', speakHint: 'Say it slowly. ${w.word}',
    sayRight: '${_sound(sound)}, ${w.word}',
  );
}

/// تجميع الأصوات: c-a-t ← 🐱.
Question enBlend(int lv, Rng r, {String? focus}) {
  final (word, sounds, pic) = r.sample(blendWords);
  final others = r.shuffle([for (final b in blendWords) if (b.$1 != word) b.$3]).take(lv <= 1 ? 1 : 2);
  final shown = r.shuffle([pic, ...others]);
  return Question(
    type: 'en_blend', mode: QMode.choice, lang: 'en', ltr: true, skill: 'blend:$word', numeric: false,
    bigChoices: true,
    ask: 'Put the sounds together: ${word.split('').join(' - ')}', speak: '${sounds.join('... ')}. What word is it?',
    visuals: [ListenVisual(sounds.join('... '), en: true)],
    choices: shown, answer: pic,
    choiceSay: {for (final b in blendWords) if (shown.contains(b.$3)) b.$3: b.$1},
    hint: 'Say the sounds faster and faster 🗣️', speakHint: 'Say the sounds faster. ${sounds.join(' ')}',
    sayRight: word,
  );
}

final enShapesGame = vocabGame('en_shapes', enShapes, 'en_shape');
final enBodyGame = vocabGame('en_body', enBody, 'en_body');
final enFamilyGame = vocabGame('en_family', enFamily, 'en_family');

/// Sight words: الطفل بيسمع الكلمة ويلاقيها.
Question enSight(int lv, Rng r, {String? focus}) {
  final pool = lv <= 1 ? sightWords.take(6).toList() : sightWords;
  final w = r.sample(pool);
  return Question(
    type: 'en_sight', mode: QMode.choice, lang: 'en', ltr: true, skill: 'sight:$w', numeric: false, bigChoices: true,
    ask: 'Find the word 👂', speak: 'Find the word: $w',
    visuals: [ListenVisual(w, en: true)],
    choices: r.textChoices(w, pool, lv <= 1 ? 3 : 4), answer: w,
    hint: 'Listen again and look at the first letter 👀', speakHint: 'Listen again. $w',
  );
}

/// موقف والطفل يختار الجملة المناسبة.
Question enPhrase(int lv, Rng r, {String? focus}) {
  final (pic, situation, say) = r.sample(enPhrases);
  return Question(
    type: 'en_phrases', mode: QMode.choice, lang: 'en', ltr: true, wide: true, skill: 'phrase:$say', numeric: false,
    ask: 'What do you say?', speak: '$situation What do you say?',
    visuals: [PicsVisual(pic, 1, big: true), CaptionVisual(situation)],
    choices: r.textChoices(say, [for (final p in enPhrases) p.$3], 3), answer: say,
    hint: 'Think: how do people feel? 💭', speakHint: 'Think about what fits',
  );
}
