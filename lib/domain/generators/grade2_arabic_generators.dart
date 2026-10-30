/// دروس تانية ابتدائي (الترم الأول) اللي مكانتش في التطبيق: ذلك وتلك، ظرف الزمان والمكان،
/// الأمر والنهي، الحروف المتشابهة في النطق، والأسماء الموصولة (tool/SCHOOL_CURRICULUM_INDEX.md).
///
/// الكلمات مشكولة زي كتب المدرسة. الأمثلة من عندنا مش من الكتاب، ومختارة واضحة:
/// كل سؤال ليه إجابة واحدة بس صح بالمعنى أو بالقاعدة. محتاجة مراجعة مدرّس عربي.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

T _focused<T>(List<T> pool, Rng r, String? focus, String Function(T) key) =>
    pool.where((x) => key(x) == focus).firstOrNull ?? r.sample<T>(pool);

// ---------------------------------------------------------------- ذلك وتلك

/// (صورة، الكلمة، مؤنث؟) — كلمات فصحى بتاء مربوطة للمؤنث، من غير مؤنث مجازي ملخبط.
const farThings = [
  ('🦁', 'أَسَدٌ', false), ('🐘', 'فِيلٌ', false), ('🏠', 'بَيْتٌ', false), ('🌙', 'قَمَرٌ', false),
  ('🐪', 'جَمَلٌ', false), ('⛰️', 'جَبَلٌ', false), ('🕌', 'مَسْجِدٌ', false), ('🚌', 'أُتُوبِيسٌ', false),
  ('🌳', 'شَجَرَةٌ', true), ('🚗', 'سَيَّارَةٌ', true), ('⭐', 'نَجْمَةٌ', true), ('🦒', 'زَرَافَةٌ', true),
  ('✈️', 'طَائِرَةٌ', true), ('🐄', 'بَقَرَةٌ', true), ('🚢', 'سَفِينَةٌ', true), ('🌹', 'وَرْدَةٌ', true),
];

/// اسم الإشارة للبعيد (ذلك / تلك)، ومن المستوى التاني مع القريب (هذا / هذه) — المسافة مكتوبة تحت الصورة.
/// (صورة، جمع العاقل) لـ هؤلاء وأولئك — درس تالتة.
const farPeople = [
  ('👦👦👦', 'أَوْلَادٌ'), ('👧👧👧', 'بَنَاتٌ'), ('🧑‍🏫🧑‍🏫', 'مُعَلِّمُونَ'), ('🧑‍⚕️🧑‍⚕️', 'أَطِبَّاءُ'),
  ('🧑‍🎓🧑‍🎓🧑‍🎓', 'طُلَّابٌ'), ('🧑‍🌾🧑‍🌾', 'فَلَّاحُونَ'),
];

/// هؤلاء للقريب وأولئك للبعيد مع جمع الناس. focus = 'plural' (درس تالتة)، ومن المستوى التالت بتطلع لوحدها.
Question _farPlural(int lv, Rng r) {
  final (pic, word) = r.sample(farPeople);
  final far = r.chance(.5);
  final right = '${far ? 'أُولَئِكَ' : 'هَؤُلَاءِ'} $word';
  final ask = far ? 'الناس دول بعاد. نقول إيه؟' : 'الناس دول قريبين. نقول إيه؟';
  return Question(
    type: 'ar_far', mode: QMode.choice, skill: 'far:plural${far ? 'Far' : 'Near'}', numeric: false, wide: true,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [EmojiVisual(pic, caption: far ? '🔭 بعيد' : '👇 قريب')],
    choices: r.shuffle([for (final d in ['هَؤُلَاءِ', 'أُولَئِكَ', if (lv >= 2) 'ذَلِكَ']) '$d $word']),
    answer: right,
    hint: 'للجمع: هَؤُلَاءِ للقريب، وأُولَئِكَ للبعيد 👉',
    speakHint: 'للجمع، هؤلاء للقريب، وأولئك للبعيد',
    sayRight: right,
  );
}

Question arFar(int lv, Rng r, {String? focus}) {
  if (focus == 'plural' || (focus == null && lv >= 3 && r.chance(.35))) return _farPlural(lv, r);
  final (pic, word, fem) = _focused(farThings, r, focus, (x) => x.$2);
  final far = lv <= 1 || r.chance(.6);
  String phrase(String d) => '$d $word';
  final right = phrase(far ? (fem ? 'تِلْكَ' : 'ذَلِكَ') : (fem ? 'هَذِهِ' : 'هَذَا'));
  final options = lv <= 1 ? ['ذَلِكَ', 'تِلْكَ'] : ['ذَلِكَ', 'تِلْكَ', 'هَذَا', 'هَذِهِ'];
  final ask = far ? 'الحاجة دي بعيدة. نقول إيه؟' : 'الحاجة دي قريبة. نقول إيه؟';
  return Question(
    type: 'ar_far', mode: QMode.choice, skill: 'far:${far ? 'far' : 'near'}${fem ? 'F' : 'M'}', numeric: false, wide: true,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [EmojiVisual(pic, caption: far ? '🔭 بعيد' : '👇 قريب')],
    choices: r.shuffle([for (final d in options) phrase(d)]),
    answer: right,
    hint: 'للبعيد: ذَلِكَ للمذكر وتِلْكَ للمؤنث. للقريب: هَذَا وهَذِهِ 👉',
    speakHint: 'للبعيد ذلك للمذكر وتلك للمؤنث، وللقريب هذا وهذه',
    sayRight: right,
  );
}

// ---------------------------------------------------------------- ظرف الزمان والمكان

const timeAdverbs = ['صَبَاحًا', 'مَسَاءً', 'لَيْلًا', 'نَهَارًا', 'ظُهْرًا', 'أَمْسِ', 'غَدًا', 'الْآنَ'];
const placeAdverbs = ['فَوْقَ', 'تَحْتَ', 'أَمَامَ', 'خَلْفَ', 'يَمِينَ', 'يَسَارَ', 'بَيْنَ', 'عِنْدَ'];

/// (الجملة بخانة، الظرف الصح، زمان؟) — الزمان مالوش مضاف إليه وجمل المكان فيها اسم بعد الخانة،
/// فالاختيارات من النوع التاني غلط في الحالتين.
const adverbSentences = [
  ('أَذْهَبُ إِلَى الْمَدْرَسَةِ _____.', 'صَبَاحًا', true),
  ('نَنَامُ _____ بَعْدَ الْعَشَاءِ.', 'لَيْلًا', true),
  ('سَأَزُورُ جَدِّي _____.', 'غَدًا', true),
  ('لَعِبْتُ الْكُرَةَ _____.', 'أَمْسِ', true),
  ('يَجْلِسُ الْقِطُّ _____ الْكُرْسِيِّ.', 'تَحْتَ', false),
  ('تَطِيرُ الطَّائِرَةُ _____ السَّحَابِ.', 'فَوْقَ', false),
  ('يَقِفُ التِّلْمِيذُ _____ السَّبُّورَةِ.', 'أَمَامَ', false),
  ('جَلَسْتُ _____ أَبِي وَأُمِّي.', 'بَيْنَ', false),
];

/// ظرف زمان ولا مكان؟ ومن المستوى التاني: الظرف اللي يكمّل الجملة.
Question arAdverb(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.5)) {
    final (sentence, answer, time) = _focused(adverbSentences, r, focus, (s) => s.$2);
    final others = r.shuffle([...time ? placeAdverbs : timeAdverbs]).take(2);
    return Question(
      type: 'ar_adverb', mode: QMode.choice, skill: 'adverb:$answer', numeric: false, bigChoices: true,
      ask: 'اختار الظرف اللي يكمّل الجملة', speak: 'اختار الظرف اللي يكمّل الجملة',
      clips: [say('اختار الظرف اللي يكمّل الجملة')],
      visuals: [WordLineVisual.text(sentence, big: true)],
      choices: r.shuffle([answer, ...others]),
      answer: answer,
      hint: time ? 'الجملة محتاجة وقت: إمتى؟ ⏰' : 'الجملة محتاجة مكان: فين؟ 📍',
      speakHint: time ? 'الجملة محتاجة وقت، إمتى؟' : 'الجملة محتاجة مكان، فين؟',
      sayRight: sentence.replaceFirst('_____', answer),
    );
  }
  final time = focus != null ? timeAdverbs.contains(focus) : r.chance(.5);
  final word = focus != null && (timeAdverbs.contains(focus) || placeAdverbs.contains(focus))
      ? focus
      : r.sample(time ? timeAdverbs : placeAdverbs);
  const ask = 'الكلمة دي ظرف زمان ولا ظرف مكان؟';
  return Question(
    type: 'ar_adverb', mode: QMode.choice, skill: 'adverb:$word', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(word)],
    visuals: [BigLetterVisual(word)],
    choices: const ['ظرف زمان', 'ظرف مكان'],
    answer: time ? 'ظرف زمان' : 'ظرف مكان',
    hint: 'ظرف الزمان بيقول إمتى (صَبَاحًا، غَدًا)، وظرف المكان بيقول فين (فَوْقَ، تَحْتَ) ☝️',
    speakHint: 'ظرف الزمان بيقول إمتى، وظرف المكان بيقول فين',
    sayRight: word,
  );
}

// ---------------------------------------------------------------- الأمر والنهي

/// جمل أمر ونهي للمخاطب المفرد.
const commandSentences = [
  ('اِجْلِسْ فِي مَكَانِكَ.', true), ('اِغْسِلْ يَدَيْكَ.', true), ('اِقْرَأْ قِصَّةً.', true),
  ('رَتِّبْ غُرْفَتَكَ.', true), ('نَظِّفْ أَسْنَانَكَ.', true), ('سَاعِدْ أُمَّكَ.', true),
  ('لَا تَلْعَبْ فِي الشَّارِعِ.', false), ('لَا تَرْمِ الْوَرَقَ عَلَى الْأَرْضِ.', false), ('لَا تَكْذِبْ.', false),
  ('لَا تَصْرُخْ فِي الْفَصْلِ.', false), ('لَا تَضْرِبْ أَخَاكَ.', false), ('لَا تَتَأَخَّرْ عَنِ الْمَدْرَسَةِ.', false),
];

/// (الأمر، النهي، المضارع).
const commandVerbs = [
  ('اِلْعَبْ', 'لَا تَلْعَبْ', 'يَلْعَبُ'), ('اِجْلِسْ', 'لَا تَجْلِسْ', 'يَجْلِسُ'), ('اُكْتُبْ', 'لَا تَكْتُبْ', 'يَكْتُبُ'),
  ('اِرْسُمْ', 'لَا تَرْسُمْ', 'يَرْسُمُ'), ('اِشْرَبْ', 'لَا تَشْرَبْ', 'يَشْرَبُ'), ('اُدْخُلْ', 'لَا تَدْخُلْ', 'يَدْخُلُ'),
  ('اِفْتَحْ', 'لَا تَفْتَحْ', 'يَفْتَحُ'), ('اِسْمَعْ', 'لَا تَسْمَعْ', 'يَسْمَعُ'),
];

/// الجملة أمر ولا نهي؟ ومن المستوى التاني: اختار الأمر أو النهي من تلات صيغ لنفس الفعل.
Question arCommand(int lv, Rng r, {String? focus}) {
  if (lv >= 2 && r.chance(.5)) {
    final (amr, nahy, mudari) = _focused(commandVerbs, r, focus, (v) => v.$1);
    final wantNahy = r.chance(.5);
    final ask = wantNahy ? 'أنهي كلمة نهي؟' : 'أنهي كلمة أمر؟';
    final answer = wantNahy ? nahy : amr;
    return Question(
      type: 'ar_command', mode: QMode.choice, skill: 'command:$amr', numeric: false, bigChoices: true,
      ask: ask, speak: ask, clips: [say(ask)],
      choices: r.shuffle([amr, nahy, mudari]),
      answer: answer,
      hint: 'الأمر بنطلب بيه حاجة (اِلْعَبْ)، والنهي بنمنع بيه حاجة وأوله لَا (لَا تَلْعَبْ) ☝️',
      speakHint: 'الأمر بنطلب بيه حاجة، والنهي بنمنع بيه حاجة وأوله لا',
      sayRight: answer,
    );
  }
  final (sentence, amr) = _focused(commandSentences, r, focus, (s) => s.$1);
  const ask = 'الجملة دي أمر ولا نهي؟';
  return Question(
    type: 'ar_command', mode: QMode.choice, skill: 'command:${amr ? 'amr' : 'nahy'}', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(sentence)],
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: const ['أمر', 'نهي'],
    answer: amr ? 'أمر' : 'نهي',
    hint: 'النهي أوله لَا وبيمنع حاجة، والأمر بيطلب حاجة ☝️',
    speakHint: 'النهي أوله لا وبيمنع حاجة، والأمر بيطلب حاجة',
    sayRight: sentence,
  );
}

// ---------------------------------------------------------------- الحروف المتشابهة في النطق

/// (الكلمة من غير تشكيل، مشكولة للصوت، صورة، الحرف الصح، الحرف اللي بيتلخبط معاه) —
/// الحرف الصح بيظهر مرة واحدة بس في الكلمة.
const similarLetterWords = [
  ('صيف', 'صَيْفٌ', '☀️', 'ص', 'س'), ('سمك', 'سَمَكٌ', '🐟', 'س', 'ص'), ('صقر', 'صَقْرٌ', '🦅', 'ص', 'س'),
  ('سيارة', 'سَيَّارَةٌ', '🚗', 'س', 'ص'), ('تفاح', 'تُفَّاحٌ', '🍎', 'ت', 'ط'), ('طائرة', 'طَائِرَةٌ', '✈️', 'ط', 'ت'),
  ('تمر', 'تَمْرٌ', '🌴', 'ت', 'ط'), ('طبيب', 'طَبِيبٌ', '🩺', 'ط', 'ت'), ('دب', 'دُبٌّ', '🐻', 'د', 'ض'),
  ('ضرس', 'ضِرْسٌ', '🦷', 'ض', 'د'), ('بيض', 'بَيْضٌ', '🥚', 'ض', 'د'), ('وردة', 'وَرْدَةٌ', '🌹', 'د', 'ض'),
  ('ذرة', 'ذُرَةٌ', '🌽', 'ذ', 'ز'), ('زرافة', 'زَرَافَةٌ', '🦒', 'ز', 'ذ'), ('كلب', 'كَلْبٌ', '🐶', 'ك', 'ق'),
  ('قلم', 'قَلَمٌ', '✏️', 'ق', 'ك'), ('قمر', 'قَمَرٌ', '🌙', 'ق', 'ك'), ('كتاب', 'كِتَابٌ', '📕', 'ك', 'ق'),
  ('حصان', 'حِصَانٌ', '🐴', 'ح', 'ه'), ('هدية', 'هَدِيَّةٌ', '🎁', 'ه', 'ح'), ('عنب', 'عِنَبٌ', '🍇', 'ع', 'أ'),
  ('أسد', 'أَسَدٌ', '🦁', 'أ', 'ع'), ('نظارة', 'نَظَّارَةٌ', '👓', 'ظ', 'ض'), ('ضوء', 'ضَوْءٌ', '💡', 'ض', 'ظ'),
];

/// الحرف زي ما بيتكتب في الاختيار: الهاء لوحدها شبه رقم ٥، فبتتكتب «هـ» زي كتب المدرسة.
String _letterLabel(String l) => l == 'ه' ? 'هـ' : l;

/// كمّل الكلمة بالحرف الصح من حرفين صوتهم قريب. الكلمة بتتسمع، والصورة بتساعد لو الصوت مقفول.
Question arSimilar(int lv, Rng r, {String? focus}) {
  final (plain, full, pic, right, wrong) = _focused(similarLetterWords, r, focus, (w) => w.$1);
  final at = plain.indexOf(right);
  final shown = '${plain.substring(0, at)}ـ؟ـ${plain.substring(at + right.length)}'
      .replaceAll(RegExp('^ـ'), '')
      .replaceAll(RegExp(r'ـ$'), '');
  const ask = 'كمّل الكلمة بالحرف الصح';
  final choices = [_letterLabel(right), _letterLabel(wrong)];
  return Question(
    type: 'ar_similar', mode: QMode.choice, skill: 'similar:$right$wrong', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask. $full', clips: [say(ask), say(full)],
    visuals: [EmojiVisual(pic), BigLetterVisual(shown)],
    choices: r.shuffle(choices),
    answer: _letterLabel(right),
    // الحرف بيتنطق باسمه (مقطع التعليم) حتى لو مكتوب «هـ»
    choiceSay: {for (final c in choices) c: c.replaceAll('ـ', '')},
    hint: 'قول الكلمة بصوت عالي بالراحة: $full — صوت $right غير صوت $wrong 👂',
    speakHint: 'قول الكلمة بالراحة. $full',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- الأسماء الموصولة

/// (الجملة بخانة، الاسم الموصول) — الَّذِي للمفرد المذكر، الَّتِي للمفردة المؤنثة، الَّذِينَ لجمع المذكر.
const relativeSentences = [
  ('جَاءَ الْوَلَدُ _____ نَجَحَ.', 'الَّذِي'),
  ('رَأَيْتُ الْقِطَّ _____ يَلْعَبُ فِي الْحَدِيقَةِ.', 'الَّذِي'),
  ('هَذَا هُوَ الْقَلَمُ _____ كَتَبْتُ بِهِ.', 'الَّذِي'),
  ('هَذِهِ هِيَ الْبِنْتُ _____ رَسَمَتِ اللَّوْحَةَ.', 'الَّتِي'),
  ('أَكَلْتُ التُّفَّاحَةَ _____ اشْتَرَتْهَا أُمِّي.', 'الَّتِي'),
  ('قَرَأْتُ الْقِصَّةَ _____ فِي الْكِتَابِ.', 'الَّتِي'),
  ('شَكَرَ الْمُعَلِّمُ التَّلَامِيذَ _____ نَجَحُوا.', 'الَّذِينَ'),
  ('فَازَ اللَّاعِبُونَ _____ تَدَرَّبُوا كَثِيرًا.', 'الَّذِينَ'),
  ('أُحِبُّ الْأَصْدِقَاءَ _____ يُسَاعِدُونَنِي.', 'الَّذِينَ'),
];

Question arRelative(int lv, Rng r, {String? focus}) {
  final (sentence, answer) = _focused(relativeSentences, r, focus, (s) => s.$1);
  const ask = 'اختار الاسم الموصول اللي يكمّل الجملة';
  return Question(
    type: 'ar_relative', mode: QMode.choice, skill: 'relative:$answer', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle(['الَّذِي', 'الَّتِي', 'الَّذِينَ']),
    answer: answer,
    hint: 'الَّذِي للمفرد المذكر، والَّتِي للمفردة المؤنثة، والَّذِينَ للجمع ☝️',
    speakHint: 'الذي للمفرد المذكر، والتي للمفردة المؤنثة، والذين للجمع',
    sayRight: sentence.replaceFirst('_____', answer),
  );
}
