/// دروس عربي تالتة ابتدائي اللي مكانتش في التطبيق (tool/SCHOOL_CURRICULUM_INDEX.md):
/// النفي بـ لم ولن، علامات الترقيم، الهمزة المتطرفة بعد المد، والجملة الاسمية والفعلية.
/// (هؤلاء وأولئك في ar_far، وعن وعلى وثم والفاء في ar_particles.)
///
/// الأمثلة من عندنا ومشكولة، وكل جملة ليها إجابة واحدة بس. محتاجة مراجعة مدرّس عربي.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

// ---------------------------------------------------------------- النفي

/// (الجملة، أداة النفي) — لَمْ للماضي وبعدها الفعل ساكن، لَنْ للمستقبل وبعدها الفعل مفتوح.
const negationSentences = [
  ('أَمْسِ ___ أَذْهَبْ إِلَى النَّادِي.', 'لَمْ'), ('___ يَحْضُرْ أَحْمَدُ الدَّرْسَ أَمْسِ.', 'لَمْ'),
  ('___ أَنَمْ مُبَكِّرًا أَمْسِ.', 'لَمْ'), ('غَدًا ___ أَتَأَخَّرَ عَنِ الْمَدْرَسَةِ.', 'لَنْ'),
  ('___ أَكْذِبَ أَبَدًا.', 'لَنْ'), ('___ نُسَافِرَ الْأُسْبُوعَ الْقَادِمَ.', 'لَنْ'),
];

Question arNegation(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = negationSentences.where((s) => s.$1 == focus).firstOrNull ?? r.sample(negationSentences);
  const ask = 'اختار أداة النفي اللي تكمّل الجملة';
  return Question(
    type: 'ar_negation', mode: QMode.choice, skill: 'negation:$answer', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle(['لَمْ', 'لَنْ']), answer: answer,
    hint: 'لَمْ لحاجة ماحصلتش في الماضي (أَمْسِ)، ولَنْ لحاجة مش هتحصل بعدين (غَدًا) ☝️',
    speakHint: 'لم للماضي، ولن للمستقبل',
    sayRight: sentence.replaceFirst('___', answer),
  );
}

// ---------------------------------------------------------------- علامات الترقيم

/// (الجملة من غير علامة في الآخر، العلامة).
const punctSentences = [
  ('ذَهَبْتُ إِلَى الْمَدْرَسَةِ', '.'), ('الْقِطُّ يَنَامُ تَحْتَ الشَّجَرَةِ', '.'), ('أُحِبُّ أُمِّي وَأَبِي', '.'),
  ('مَا أَجْمَلَ الْبَحْرَ', '!'), ('مَا أَكْبَرَ الْفِيلَ', '!'), ('مَا أَحْلَى الْعَسَلَ', '!'),
  ('أَيْنَ تَسْكُنُ', '؟'), ('هَلْ أَكَلْتَ الْفَطُورَ', '؟'), ('لِمَاذَا تَضْحَكُ', '؟'),
];

const _punctNames = {'.': 'نقطة', '!': 'علامة تعجب', '؟': 'علامة استفهام'};

/// أنهي علامة في آخر الجملة؟ الاختيار مكتوب باسمه والعلامة جنبه.
Question arPunct(int lv, Rng r, {String? focus}) {
  final (sentence, mark) = punctSentences.where((s) => s.$1 == focus).firstOrNull ?? r.sample(punctSentences);
  String label(String m) => '${_punctNames[m]} ( $m )';
  const ask = 'أنهي علامة نحطها في آخر الجملة؟';
  return Question(
    type: 'ar_punct', mode: QMode.choice, skill: 'punct:$mark', numeric: false, wide: true,
    ask: ask, speak: ask, clips: [say(ask), say(sentence)],
    visuals: [WordLineVisual.text('$sentence ___', big: true)],
    choices: r.shuffle([for (final m in _punctNames.keys) label(m)]), answer: label(mark),
    choiceSay: {for (final m in _punctNames.keys) label(m): _punctNames[m]!},
    hint: 'النقطة في آخر الجملة العادية، وعلامة التعجب بعد مَا أَجْمَلَ، وعلامة الاستفهام بعد السؤال ☝️',
    speakHint: 'النقطة للجملة العادية، والتعجب بعد ما أجمل، والاستفهام بعد السؤال',
    sayRight: sentence,
  );
}

// ---------------------------------------------------------------- الهمزة المتطرفة بعد المد

/// (الكلمة من غير آخر حرف، مشكولة، صورة) — كلها آخرها همزة على السطر بعد ألف المد.
const hamzaWords = [
  ('سما', 'سَمَاءٌ', '🌌'), ('ما', 'مَاءٌ', '💧'), ('دوا', 'دَوَاءٌ', '💊'), ('شتا', 'شِتَاءٌ', '⛄'),
  ('هوا', 'هَوَاءٌ', '🌬️'), ('غدا', 'غَدَاءٌ', '🍽️'), ('بنا', 'بِنَاءٌ', '🏗️'), ('صحرا', 'صَحْرَاءُ', '🏜️'),
];

Question arHamza(int lv, Rng r, {String? focus}) {
  final (plain, full, pic) = hamzaWords.where((w) => w.$2 == focus).firstOrNull ?? r.sample(hamzaWords);
  const ask = 'كمّل الكلمة بالحرف الصح';
  return Question(
    type: 'ar_hamza', mode: QMode.choice, skill: 'hamza:end', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask. $full', clips: [say(ask), say(full)],
    // «سما؟» كانت بتتقري كأنها سؤال — الخانة خط
    visuals: [EmojiVisual(pic), BigLetterVisual('$plain _')],
    choices: r.shuffle(lv <= 1 ? ['ء', 'ة'] : ['ء', 'أ', 'ة']), answer: 'ء',
    choiceSay: const {'ء': 'همزة', 'أ': 'ألف عليها همزة', 'ة': 'تاء مربوطة'},
    hint: 'بعد ألف المد الهمزة بتتكتب لوحدها على السطر: سَمَاء ☝️',
    speakHint: 'بعد ألف المد الهمزة بتتكتب لوحدها على السطر',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- الجملة الاسمية والفعلية

/// (الجملة، اسمية؟) — الاسمية أولها اسم، والفعلية أولها فعل.
const sentenceKinds = [
  ('الشَّمْسُ مُشْرِقَةٌ.', true), ('الْوَلَدُ نَشِيطٌ.', true), ('الْحَدِيقَةُ جَمِيلَةٌ.', true), ('أَبِي طَبِيبٌ.', true),
  ('ذَهَبَ أَحْمَدُ إِلَى الْمَدْرَسَةِ.', false), ('يَلْعَبُ الْأَطْفَالُ.', false), ('شَرِبَتْ سَارَةُ اللَّبَنَ.', false),
  ('نَامَ الطِّفْلُ.', false),
];

Question arSentenceKind(int lv, Rng r, {String? focus}) {
  final (sentence, nominal) = sentenceKinds.where((s) => s.$1 == focus).firstOrNull ?? r.sample(sentenceKinds);
  const ask = 'الجملة دي اسمية ولا فعلية؟';
  return Question(
    type: 'ar_sentenceKind', mode: QMode.choice, skill: 'sentenceKind:${nominal ? 'n' : 'v'}', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(sentence)],
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: const ['جملة اسمية', 'جملة فعلية'], answer: nominal ? 'جملة اسمية' : 'جملة فعلية',
    hint: 'بص على أول كلمة: لو اسم تبقى اسمية، ولو فعل تبقى فعلية ☝️',
    speakHint: 'بص على أول كلمة، لو اسم تبقى اسمية، ولو فعل تبقى فعلية',
    sayRight: sentence,
  );
}
