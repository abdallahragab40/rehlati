/// دروس الترم التاني لعربي أولى وتانية (tool/SCHOOL_CURRICULUM_INDEX.md):
/// الضمائر (أنا ونحن، أنتَ وأنتِ، هو وهي، ضمائر الغائب)، الماضي والمضارع، التاء المربوطة والمفتوحة،
/// الأساليب (النداء والتعجب والاستفهام)، وحروف الجر والعطف.
///
/// كل مرحلة فيها كذا درس: [focus] بيختار الدرس (من «دروس المدرسة»)، ومن غيره المستوى بيحدد.
/// الأمثلة من عندنا ومشكولة، وكل جملة ليها إجابة واحدة بس. محتاجة مراجعة مدرّس عربي.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// جملة بخانة واختيارات: السؤال بس اللي بيتقال، والجملة كاملة بتتقال لما يجاوب صح.
Question _blank(String type, String skill, String ask, String sentence, String answer, List<String> choices, Rng r,
        {required String hint, required String speakHint, Map<Object, String> choiceSay = const {}, String? reply}) =>
    Question(
      type: type, mode: QMode.choice, skill: skill, numeric: false, bigChoices: true,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [WordLineVisual.text(sentence, big: true), if (reply != null) CaptionVisual('— $reply')],
      choices: r.shuffle([...choices]), answer: answer, choiceSay: choiceSay,
      hint: hint, speakHint: speakHint,
      sayRight: sentence.replaceFirst('___', answer),
    );

// ---------------------------------------------------------------- الضمائر

/// (الدرس، الضمائر اللي بتتختار، الجمل، التلميح).
const pronounSets = {
  'ana': (
    ['أَنَا', 'نَحْنُ'],
    [
      ('___ أَلْعَبُ بِالْكُرَةِ.', 'أَنَا'), ('___ نَلْعَبُ بِالْكُرَةِ.', 'نَحْنُ'), ('___ أَقْرَأُ قِصَّةً.', 'أَنَا'),
      ('___ نَذْهَبُ إِلَى الْمَدْرَسَةِ.', 'نَحْنُ'), ('___ أُحِبُّ أُمِّي.', 'أَنَا'), ('___ نَرْسُمُ لَوْحَةً.', 'نَحْنُ'),
    ],
    'أَنَا لواحد والفعل أوله أ (أَلْعَبُ)، ونَحْنُ لأكتر من واحد والفعل أوله ن (نَلْعَبُ) ☝️',
    'أنا لواحد والفعل أوله ألف، ونحن لأكتر من واحد والفعل أوله نون',
  ),
  'anta': (
    ['أَنْتَ', 'أَنْتِ'],
    [
      ('___ تِلْمِيذٌ مُجْتَهِدٌ.', 'أَنْتَ'), ('___ تِلْمِيذَةٌ مُجْتَهِدَةٌ.', 'أَنْتِ'), ('___ تَكْتُبِينَ الدَّرْسَ.', 'أَنْتِ'),
      ('___ تَكْتُبُ الدَّرْسَ.', 'أَنْتَ'), ('___ طَبِيبَةٌ.', 'أَنْتِ'), ('___ طَبِيبٌ.', 'أَنْتَ'),
    ],
    'أَنْتَ (فتحة) للولد، وأَنْتِ (كسرة) للبنت ☝️',
    'أنتَ بالفتحة للولد، وأنتِ بالكسرة للبنت',
  ),
  'huwa': (
    ['هُوَ', 'هِيَ'],
    [
      ('___ يَلْعَبُ فِي الْحَدِيقَةِ.', 'هُوَ'), ('___ تَلْعَبُ فِي الْحَدِيقَةِ.', 'هِيَ'), ('___ وَلَدٌ نَشِيطٌ.', 'هُوَ'),
      ('___ بِنْتٌ نَشِيطَةٌ.', 'هِيَ'), ('___ يَشْرَبُ اللَّبَنَ.', 'هُوَ'), ('___ تَشْرَبُ اللَّبَنَ.', 'هِيَ'),
    ],
    'هُوَ للولد (يَلْعَبُ)، وهِيَ للبنت (تَلْعَبُ) ☝️',
    'هو للولد، وهي للبنت',
  ),
  'ghaib': (
    ['هُوَ', 'هِيَ', 'هُمَا', 'هُمْ', 'هُنَّ'],
    [
      ('___ يَلْعَبُ.', 'هُوَ'), ('___ تَلْعَبُ.', 'هِيَ'), ('___ يَلْعَبَانِ.', 'هُمَا'), ('___ يَلْعَبُونَ.', 'هُمْ'),
      ('___ يَلْعَبْنَ.', 'هُنَّ'), ('___ يَكْتُبُونَ الدَّرْسَ.', 'هُمْ'), ('___ يَكْتُبْنَ الدَّرْسَ.', 'هُنَّ'),
      ('___ تَكْتُبَانِ الدَّرْسَ.', 'هُمَا'),
    ],
    'هُوَ وهِيَ لواحد، هُمَا لاتنين (ـانِ)، هُمْ للولاد (ـونَ)، هُنَّ للبنات (ـنَ) ☝️',
    'هو وهي لواحد، هما لاتنين، هم للولاد، هن للبنات',
  ),
};

/// الضمير اللي يكمّل الجملة. focus: ana / anta / huwa / ghaib.
Question arPronoun(int lv, Rng r, {String? focus}) {
  final key = pronounSets.containsKey(focus)
      ? focus!
      : r.sample(switch (lv) { <= 1 => ['ana', 'huwa'], 2 => ['ana', 'anta', 'huwa'], _ => pronounSets.keys.toList() });
  final (all, sentences, hint, speakHint) = pronounSets[key]!;
  final (sentence, answer) = r.sample(sentences);
  final choices = all.length <= 3 ? all : [answer, ...r.shuffle(all.where((x) => x != answer).toList()).take(3)];
  return _blank('ar_pronoun', 'pronoun:$key', 'اختار الضمير اللي يكمّل الجملة', sentence, answer, choices, r,
      hint: hint, speakHint: speakHint);
}

// ---------------------------------------------------------------- الماضي والمضارع

/// (ماضٍ، مضارع).
const tensePairs = [
  ('كَتَبَ', 'يَكْتُبُ'), ('لَعِبَ', 'يَلْعَبُ'), ('شَرِبَ', 'يَشْرَبُ'), ('ذَهَبَ', 'يَذْهَبُ'),
  ('رَسَمَ', 'يَرْسُمُ'), ('أَكَلَ', 'يَأْكُلُ'), ('جَلَسَ', 'يَجْلِسُ'), ('نَامَ', 'يَنَامُ'),
];

/// الفعل ماضٍ ولا مضارع؟ ومن المستوى التاني: «أَمْسِ» و«الْآنَ» بيحددوا الفعل اللي يكمّل الجملة.
Question arTense(int lv, Rng r, {String? focus}) {
  final (past, present) = tensePairs.where((p) => p.$1 == focus).firstOrNull ?? r.sample(tensePairs);
  if (lv >= 2 && r.chance(.5)) {
    final now = r.chance(.5);
    final sentence = now ? 'الْآنَ ___ أَحْمَدُ.' : 'أَمْسِ ___ أَحْمَدُ.';
    return _blank('ar_tense', 'tense:$past', 'اختار الفعل اللي يكمّل الجملة', sentence, now ? present : past, [past, present], r,
        hint: 'أَمْسِ = حصل وخلص (ماضٍ)، الْآنَ = بيحصل دلوقتي (مضارع) ☝️', speakHint: 'أمس يعني ماضي، والآن يعني مضارع');
  }
  final isPast = r.chance(.5);
  final word = isPast ? past : present;
  const ask = 'الفعل ده ماضٍ ولا مضارع؟';
  return Question(
    type: 'ar_tense', mode: QMode.choice, skill: 'tense:$past', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(word)],
    visuals: [BigLetterVisual(word)],
    choices: const ['فعل ماضٍ', 'فعل مضارع'], answer: isPast ? 'فعل ماضٍ' : 'فعل مضارع',
    hint: 'الماضي حصل وخلص (كَتَبَ)، والمضارع بيحصل دلوقتي وأوله حرف زي يـ (يَكْتُبُ) ☝️',
    speakHint: 'الماضي حصل وخلص، والمضارع بيحصل دلوقتي',
    sayRight: word,
  );
}

// ---------------------------------------------------------------- التاء المربوطة والمفتوحة

/// (الكلمة من غير آخر حرف، الكلمة مشكولة، صورة، الحرف الأخير).
const taaWords = [
  ('شجر', 'شَجَرَةٌ', '🌳', 'ة'), ('مدرس', 'مَدْرَسَةٌ', '🏫', 'ة'), ('ورد', 'وَرْدَةٌ', '🌹', 'ة'), ('سمك', 'سَمَكَةٌ', '🐟', 'ة'),
  ('فراش', 'فَرَاشَةٌ', '🦋', 'ة'), ('كر', 'كُرَةٌ', '⚽', 'ة'), ('بقر', 'بَقَرَةٌ', '🐄', 'ة'), ('سيار', 'سَيَّارَةٌ', '🚗', 'ة'),
  ('بي', 'بَيْتٌ', '🏠', 'ت'), ('بن', 'بِنْتٌ', '👧', 'ت'), ('زي', 'زَيْتٌ', '🫒', 'ت'), ('حو', 'حُوتٌ', '🐋', 'ت'),
  ('صو', 'صَوْتٌ', '🔊', 'ت'), ('وق', 'وَقْتٌ', '⏰', 'ت'), ('نبا', 'نَبَاتٌ', '🌱', 'ت'), ('بنا', 'بَنَاتٌ', '👭', 'ت'),
];

/// كمّل الكلمة بـ ة ولا ت؟ ومن المستوى التاني: التاء في آخر الكلمة مربوطة ولا مفتوحة؟
Question arTaa(int lv, Rng r, {String? focus}) {
  final (plain, full, pic, last) = taaWords.where((w) => w.$2 == focus).firstOrNull ?? r.sample(taaWords);
  const hint = 'التاء المربوطة (ة) بتتنطق هاء لما نقف عليها: شَجَرَهْ. المفتوحة (ت) بتفضل تاء: بَيْتْ ☝️';
  const speakHint = 'المربوطة بتتنطق هاء لما نقف عليها، والمفتوحة بتفضل تاء';
  if (lv >= 2 && r.chance(.5)) {
    const ask = 'التاء في آخر الكلمة دي مربوطة ولا مفتوحة؟';
    return Question(
      type: 'ar_taa', mode: QMode.choice, skill: 'taa:$last', numeric: false,
      ask: ask, speak: ask, clips: [say(ask), say(full)],
      visuals: [EmojiVisual(pic), BigLetterVisual(full)],
      choices: const ['تاء مربوطة', 'تاء مفتوحة'], answer: last == 'ة' ? 'تاء مربوطة' : 'تاء مفتوحة',
      hint: hint, speakHint: speakHint, sayRight: full,
    );
  }
  const ask = 'كمّل الكلمة: ة ولا ت؟';
  return Question(
    type: 'ar_taa', mode: QMode.choice, skill: 'taa:$last', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask $full', clips: [say(ask), say(full)],
    visuals: [EmojiVisual(pic), BigLetterVisual('$plainـ؟')],
    choices: r.shuffle(['ة', 'ت']), answer: last,
    hint: hint, speakHint: speakHint, sayRight: full,
  );
}

// ---------------------------------------------------------------- الأساليب

/// جمل التصنيف: (الجملة، الأسلوب).
const styleSentences = [
  ('يَا أَحْمَدُ، تَعَالَ.', 'نداء'), ('يَا أُمِّي، أُحِبُّكِ.', 'نداء'), ('يَا سَارَةُ، اِجْلِسِي.', 'نداء'),
  ('مَا أَجْمَلَ الْحَدِيقَةَ!', 'تعجب'), ('مَا أَكْبَرَ الْفِيلَ!', 'تعجب'), ('مَا أَحْلَى الْعَسَلَ!', 'تعجب'),
  ('أَيْنَ قَلَمِي؟', 'استفهام'), ('مَتَى نُسَافِرُ؟', 'استفهام'), ('كَيْفَ حَالُكَ؟', 'استفهام'), ('لِمَاذَا تَضْحَكُ؟', 'استفهام'),
];

/// أسئلة الاستفهام بخانة، والرد بيحدد أداة واحدة بس: (السؤال، الرد، الأداة).
const questionWordSentences = [
  ('___ تَسْكُنُ؟', 'أَسْكُنُ فِي الْقَاهِرَةِ.', 'أَيْنَ'), ('___ الْكِتَابُ؟', 'الْكِتَابُ عَلَى الْمَكْتَبِ.', 'أَيْنَ'),
  ('___ تَنَامُ؟', 'أَنَامُ فِي اللَّيْلِ.', 'مَتَى'), ('___ تَذْهَبُ إِلَى الْمَدْرَسَةِ؟', 'أَذْهَبُ صَبَاحًا.', 'مَتَى'),
  ('___ حَالُكَ؟', 'أَنَا بِخَيْرٍ.', 'كَيْفَ'), ('___ تَذْهَبُ إِلَى النَّادِي؟', 'أَذْهَبُ بِالدَّرَّاجَةِ.', 'كَيْفَ'),
  ('___ تَبْكِي؟', 'لِأَنِّي وَقَعْتُ.', 'لِمَاذَا'), ('___ تَأْكُلُ الْخُضَارَ؟', 'لِأَنَّهُ مُفِيدٌ.', 'لِمَاذَا'),
];

const _styleWords = {'nida': 'نداء', 'taajjub': 'تعجب', 'istifham': 'استفهام'};

/// نوع الأسلوب (نداء، تعجب، استفهام)، أو الأداة اللي تكمّل الجملة. focus: nida / taajjub / istifham.
Question arStyle(int lv, Rng r, {String? focus}) {
  final key = _styleWords.containsKey(focus) ? focus! : r.sample(_styleWords.keys.toList());
  const hint = 'النداء بـ يَا، والتعجب بـ مَا أَفْعَلَ وآخره !، والاستفهام سؤال وآخره ؟ ☝️';
  const speakHint = 'النداء بيا، والتعجب بما أفعل، والاستفهام سؤال';
  if (r.chance(lv <= 1 ? .4 : .5)) {
    // نص الجمل من أسلوب الدرس ونصها من التانيين — عشان الإجابة ماتبقاش هي هي كل مرة
    final pool = r.chance(.5) ? styleSentences.where((s) => s.$2 == _styleWords[key]).toList() : styleSentences;
    final (sentence, style) = r.sample(pool);
    const ask = 'الجملة دي أسلوب إيه؟';
    return Question(
      type: 'ar_style', mode: QMode.choice, skill: 'style:$key', numeric: false,
      ask: ask, speak: ask, clips: [say(ask), say(sentence)],
      visuals: [WordLineVisual.text(sentence, big: true)],
      choices: r.shuffle(['نداء', 'تعجب', 'استفهام']), answer: style,
      hint: hint, speakHint: speakHint, sayRight: sentence,
    );
  }
  switch (key) {
    case 'istifham':
      final (q, reply, word) = r.sample(questionWordSentences);
      final choices = lv <= 1 ? [word, ...r.shuffle(['أَيْنَ', 'مَتَى', 'كَيْفَ', 'لِمَاذَا'].where((x) => x != word).toList()).take(1)] : ['أَيْنَ', 'مَتَى', 'كَيْفَ', 'لِمَاذَا'];
      return _blank('ar_style', 'style:$key', 'اقرا الرد واختار أداة الاستفهام', q, word, choices, r, reply: reply,
          hint: 'أَيْنَ للمكان، مَتَى للوقت، كَيْفَ للحال، لِمَاذَا للسبب ☝️',
          speakHint: 'أين للمكان، متى للوقت، كيف للحال، لماذا للسبب');
    case 'taajjub':
      final (s, _) = r.sample(styleSentences.where((s) => s.$2 == 'تعجب').toList());
      return _blank('ar_style', 'style:$key', 'اختار اللي يكمّل جملة التعجب', s.replaceFirst('مَا ', '___ '), 'مَا',
          ['مَا', 'يَا', 'هَلْ'], r, hint: hint, speakHint: speakHint);
    default:
      final (s, _) = r.sample(styleSentences.where((s) => s.$2 == 'نداء').toList());
      return _blank('ar_style', 'style:$key', 'اختار حرف النداء', s.replaceFirst('يَا ', '___ '), 'يَا', ['يَا', 'مَا', 'هَلْ'], r,
          hint: hint, speakHint: speakHint);
  }
}

// ---------------------------------------------------------------- حروف الجر والعطف

/// (الجملة، الحرف) — من للبداية، إلى للنهاية، في للمكان من جوه.
const jarrSentences = [
  ('ذَهَبْتُ ___ الْمَدْرَسَةِ.', 'إِلَى'), ('وَصَلْنَا ___ الْبَيْتِ.', 'إِلَى'), ('خَرَجْتُ ___ الْبَيْتِ.', 'مِنْ'),
  ('نَزَلَ الْقِطُّ ___ الشَّجَرَةِ.', 'مِنْ'), ('السَّمَكُ ___ الْمَاءِ.', 'فِي'), ('الْقَلَمُ ___ الْحَقِيبَةِ.', 'فِي'),
];

/// (الجملة، الحرف) — و للاتنين مع بعض، أو لواحد بس منهم.
const atfSentences = [
  ('جَاءَ أَحْمَدُ ___ عَلِيٌّ مَعًا.', 'وَ'), ('أَبِي ___ أُمِّي يُحِبَّانِنِي.', 'وَ'), ('سَافَرَ أَحْمَدُ ___ أُخْتُهُ مَعًا.', 'وَ'),
  ('هَلْ تَشْرَبُ عَصِيرًا ___ لَبَنًا؟', 'أَوْ'), ('اِخْتَرْ قَلَمًا أَحْمَرَ ___ أَزْرَقَ.', 'أَوْ'),
  ('نَلْعَبُ الْكُرَةَ الْيَوْمَ ___ غَدًا؟', 'أَوْ'),
];

/// حرف الجر أو العطف اللي يكمّل الجملة. focus: jarr / atf.
Question arParticles(int lv, Rng r, {String? focus}) {
  final jarr = focus == 'jarr' || (focus != 'atf' && r.chance(.5));
  if (jarr) {
    final (s, a) = r.sample(jarrSentences);
    return _blank('ar_particles', 'particle:jarr', 'اختار حرف الجر اللي يكمّل الجملة', s, a, ['مِنْ', 'إِلَى', 'فِي'], r,
        hint: 'مِنْ = بداية المشوار، إِلَى = آخره، فِي = جوه المكان ☝️',
        speakHint: 'من بداية المشوار، إلى آخره، في جوه المكان',
        // «فِي» لوحدها مشكولة بتتمد في التسجيل (فِييي)
        choiceSay: const {'فِي': 'في'});
  }
  final (s, a) = r.sample(atfSentences);
  return _blank('ar_particles', 'particle:atf', 'اختار حرف العطف اللي يكمّل الجملة', s, a, ['وَ', 'أَوْ'], r,
      hint: 'وَ = الاتنين مع بعض، أَوْ = واحد بس منهم ☝️', speakHint: 'و يعني الاتنين مع بعض، وأو يعني واحد بس');
}
