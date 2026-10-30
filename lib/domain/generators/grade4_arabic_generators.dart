/// دروس عربي رابعة ابتدائي (tool/SCHOOL_CURRICULUM_INDEX.md): علامات الاسم، دخول حروف (فـ بـ كـ لـ)
/// على المعرّف بـ «ال»، المبتدأ والخبر، حروف تُنطق ولا تُكتب، الألف اللينة، والفعل والفاعل.
///
/// الأمثلة من عندنا ومشكولة، وكل سؤال ليه إجابة واحدة بس. محتاجة مراجعة مدرّس عربي.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

T _pickFocus<T>(List<T> pool, Rng r, String? focus, String Function(T) key) =>
    pool.where((x) => key(x) == focus).firstOrNull ?? r.sample<T>(pool);

// ---------------------------------------------------------------- علامات الاسم

/// (الكلمة أو العبارة، العلامة) — كل واحدة فيها علامة واحدة بس (الاسم بعد حرف الجر ممنوع من الصرف).
const nounSignWords = [
  ('الشَّمْسُ', 'أل'), ('الْقَمَرُ', 'أل'), ('الْحَدِيقَةُ', 'أل'), ('الْكِتَابُ', 'أل'),
  ('وَلَدٌ', 'التنوين'), ('شَجَرَةٌ', 'التنوين'), ('قَلَمًا', 'التنوين'), ('بَيْتٍ', 'التنوين'),
  ('إِلَى مِصْرَ', 'حرف الجر'), ('مِنْ أَحْمَدَ', 'حرف الجر'), ('فِي أَسْوَانَ', 'حرف الجر'), ('إِلَى مَكَّةَ', 'حرف الجر'),
];

Question arNounSigns(int lv, Rng r, {String? focus}) {
  final (word, sign) = _pickFocus(nounSignWords, r, focus, (w) => w.$1);
  const ask = 'الاسم هنا عرفناه بأنهي علامة؟';
  return Question(
    type: 'ar_nounSigns', mode: QMode.choice, skill: 'nounSign:$sign', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(word)],
    visuals: [BigLetterVisual(word)],
    choices: r.shuffle(['أل', 'التنوين', 'حرف الجر']), answer: sign,
    hint: 'من علامات الاسم: يبدأ بـ «ال»، أو آخره تنوين، أو قبله حرف جر ☝️',
    speakHint: 'من علامات الاسم: ال في أوله، أو التنوين في آخره، أو حرف جر قبله',
    sayRight: word,
  );
}

// ---------------------------------------------------------------- دخول حروف على «ال»

const alWords = ['البيت', 'القلم', 'الشجرة', 'المدرسة', 'الكتاب', 'الليل', 'اللبن', 'الحديقة'];

/// بـ وكـ وفـ: الألف بتفضل (بالقلم). لِـ: الألف بتتشال (للقلم)، ولو الكلمة أولها لام بتتشال لام كمان (لليل).
String alWith(String prefix, String word) {
  if (prefix != 'ل') return '$prefix$word';
  return word.startsWith('الل') ? 'ل${word.substring(2)}' : 'ل${word.substring(1)}';
}

Question arAlPrefix(int lv, Rng r, {String? focus}) {
  final word = _pickFocus(alWords, r, focus, (w) => w);
  final prefix = lv <= 1 ? r.sample(['ب', 'ل']) : r.sample(['ب', 'ك', 'ف', 'ل', 'ل']);
  final right = alWith(prefix, word);
  // الغلط: الألف اتشالت مع غير اللام، أو فضلت مع اللام
  final wrong = prefix == 'ل'
      ? ['ل$word', if (word.startsWith('الل')) 'ل${word.substring(1)}' else 'ل${word.substring(2)}']
      : ['$prefix${word.substring(1)}', '$prefix $word'];
  final choices = {right, ...wrong}.toList();
  const ask = 'اختار الكتابة الصح';
  return Question(
    type: 'ar_alPrefix', mode: QMode.choice, skill: 'alPrefix:$prefix', numeric: false, wide: true,
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [BigLetterVisual('$prefixـ + $word')],
    choices: r.shuffle(choices), answer: right,
    // الكتابات الغلط مش كلام بيتقري
    choiceSay: {for (final c in choices) c: ''},
    hint: 'مع بـ وكـ وفـ الألف بتفضل (بالقلم)، ومع لِـ الألف بتتشال (للقلم) ☝️',
    speakHint: 'مع الباء والكاف والفاء الألف بتفضل، ومع اللام الألف بتتشال',
    sayRight: right,
  );
}

// ---------------------------------------------------------------- المبتدأ والخبر

/// (المبتدأ، الخبر، النوع) — single / dual / plural.
const nominalPairs = [
  ('الْجَوُّ', 'جَمِيلٌ', 'single'), ('الْمُعَلِّمُ', 'مُخْلِصٌ', 'single'), ('الْحَدِيقَةُ', 'وَاسِعَةٌ', 'single'),
  ('الطَّالِبَانِ', 'مُجْتَهِدَانِ', 'dual'), ('الْبِنْتَانِ', 'سَعِيدَتَانِ', 'dual'), ('الْفَرِيقَانِ', 'قَوِيَّانِ', 'dual'),
  ('الْمُعَلِّمُونَ', 'مُخْلِصُونَ', 'plural'), ('اللَّاعِبُونَ', 'مُسْتَعِدُّونَ', 'plural'), ('الْمُهَنْدِسُونَ', 'مَاهِرُونَ', 'plural'),
];

/// خبر الكلمة دي بالمفرد والمثنى والجمع (لسؤال المطابقة).
const _khabarForms = {
  'مُجْتَهِدَانِ': ['مُجْتَهِدٌ', 'مُجْتَهِدَانِ', 'مُجْتَهِدُونَ'],
  'سَعِيدَتَانِ': ['سَعِيدَةٌ', 'سَعِيدَتَانِ', 'سَعِيدَاتٌ'],
  'قَوِيَّانِ': ['قَوِيٌّ', 'قَوِيَّانِ', 'أَقْوِيَاءُ'],
  'مُخْلِصُونَ': ['مُخْلِصٌ', 'مُخْلِصَانِ', 'مُخْلِصُونَ'],
  'مُسْتَعِدُّونَ': ['مُسْتَعِدٌّ', 'مُسْتَعِدَّانِ', 'مُسْتَعِدُّونَ'],
  'مَاهِرُونَ': ['مَاهِرٌ', 'مَاهِرَانِ', 'مَاهِرُونَ'],
};

/// أنهي كلمة المبتدأ أو الخبر؟ ومع المثنى والجمع: الخبر اللي يناسب المبتدأ. focus: single / dual / plural.
Question arMubtada(int lv, Rng r, {String? focus}) {
  final pool = nominalPairs.where((p) => p.$3 == focus).toList();
  final (mubtada, khabar, kind) = r.sample(pool.isEmpty ? nominalPairs : pool);
  if (kind != 'single' && r.chance(.5)) {
    return Question(
      type: 'ar_mubtada', mode: QMode.choice, skill: 'mubtada:agree$kind', numeric: false, bigChoices: true,
      ask: 'اختار الخبر اللي يناسب المبتدأ', speak: 'اختار الخبر اللي يناسب المبتدأ',
      clips: [say('اختار الخبر اللي يناسب المبتدأ')],
      visuals: [WordLineVisual.text('$mubtada ___.', big: true)],
      choices: r.shuffle([..._khabarForms[khabar]!]), answer: khabar,
      hint: 'الخبر زي المبتدأ: مثنى مع المثنى (ـانِ)، وجمع مع الجمع (ـونَ) ☝️',
      speakHint: 'الخبر زي المبتدأ، مثنى مع المثنى وجمع مع الجمع',
      sayRight: '$mubtada $khabar.',
    );
  }
  final wantMubtada = r.chance(.5);
  final ask = wantMubtada ? 'أنهي كلمة هي المبتدأ؟' : 'أنهي كلمة هي الخبر؟';
  return Question(
    type: 'ar_mubtada', mode: QMode.choice, skill: 'mubtada:$kind', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask), say('$mubtada $khabar.')],
    visuals: [WordLineVisual.text('$mubtada $khabar.', big: true)],
    choices: r.shuffle([mubtada, khabar]), answer: wantMubtada ? mubtada : khabar,
    hint: 'المبتدأ اسم في أول الجملة بنتكلم عنه، والخبر بيكمّل المعنى ☝️',
    speakHint: 'المبتدأ اسم في أول الجملة، والخبر بيكمل المعنى',
    sayRight: wantMubtada ? mubtada : khabar,
  );
}

// ---------------------------------------------------------------- حروف تُنطق ولا تُكتب

/// (الكتابة الصح مشكولة للصوت، الصح من غير تشكيل، الغلط اللي بيتكتب زي ما بيتنطق).
const hiddenAlifWords = [
  ('هَذَا', 'هذا', 'هاذا'), ('هَذِهِ', 'هذه', 'هاذه'), ('ذَلِكَ', 'ذلك', 'ذالك'), ('لَكِنْ', 'لكن', 'لاكن'),
  ('هَؤُلَاءِ', 'هؤلاء', 'هاؤلاء'), ('أُولَئِكَ', 'أولئك', 'أولائك'), ('الرَّحْمَنُ', 'الرحمن', 'الرحمان'),
  ('اللَّهُ', 'الله', 'اللاه'),
];

Question arHiddenAlif(int lv, Rng r, {String? focus}) {
  final (full, right, wrong) = _pickFocus(hiddenAlifWords, r, focus, (w) => w.$2);
  const ask = 'اسمع الكلمة واختار كتابتها الصح';
  return Question(
    type: 'ar_hiddenAlif', mode: QMode.choice, skill: 'hiddenAlif:$right', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask. $full', clips: [say(ask), say(full)],
    visuals: [ListenVisual(full)],
    choices: r.shuffle([right, wrong]), answer: right,
    choiceSay: {right: '', wrong: ''},
    hint: 'فيه كلمات فيها ألف بتتنطق ومش بتتكتب: هذا، ذلك، لكن، هؤلاء ☝️',
    speakHint: 'فيه كلمات فيها ألف بتتنطق ومش بتتكتب',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- الألف اللينة

/// (الكلمة من غير آخرها، الكلمة كاملة مشكولة، الآخر، النوع) — harf / ism / fiil.
const layyinaWords = [
  ('إل', 'إِلَى', 'ى', 'harf'), ('عل', 'عَلَى', 'ى', 'harf'), ('حت', 'حَتَّى', 'ى', 'harf'), ('بل', 'بَلَى', 'ى', 'harf'),
  ('م', 'مَا', 'ا', 'harf'), ('ل', 'لَا', 'ا', 'harf'), ('إذ', 'إِذَا', 'ا', 'harf'), ('كل', 'كَلَّا', 'ا', 'harf'),
  ('عص', 'عَصَا', 'ا', 'ism'), ('فت', 'فَتَى', 'ى', 'ism'), ('هد', 'هُدَى', 'ى', 'ism'), ('مستشف', 'مُسْتَشْفَى', 'ى', 'ism'),
  ('مصطف', 'مُصْطَفَى', 'ى', 'ism'), ('دني', 'دُنْيَا', 'ا', 'ism'), ('هداي', 'هَدَايَا', 'ا', 'ism'),
  ('دع', 'دَعَا', 'ا', 'fiil'), ('نج', 'نَجَا', 'ا', 'fiil'), ('سم', 'سَمَا', 'ا', 'fiil'), ('رم', 'رَمَى', 'ى', 'fiil'),
  ('مش', 'مَشَى', 'ى', 'fiil'), ('بن', 'بَنَى', 'ى', 'fiil'), ('أعط', 'أَعْطَى', 'ى', 'fiil'),
];

const _layyinaHints = {
  'harf': 'إِلَى وعَلَى وحَتَّى وبَلَى بالياء (ى)، وباقي الحروف بالألف (ا) ☝️',
  'ism': 'لو الكلمة أكتر من ٣ حروف بتتكتب ى، إلا لو قبلها ياء (دُنْيَا). الثلاثي: نرجّعه للمثنى (عَصَوَان ← ا، فَتَيَان ← ى) ☝️',
  'fiil': 'نرجّع الفعل للمضارع: يَدْعُو ← دَعَا بالألف، يَرْمِي ← رَمَى بالياء. والأكتر من ٣ حروف بالياء ☝️',
};

/// الألف اللينة في آخر الكلمة: ا ولا ى؟ focus: harf / ism / fiil.
Question arAlifLayyina(int lv, Rng r, {String? focus}) {
  final kind = _layyinaHints.containsKey(focus) ? focus! : r.sample(_layyinaHints.keys.toList());
  final (plain, full, last, _) = r.sample(layyinaWords.where((w) => w.$4 == kind).toList());
  const ask = 'كمّل الكلمة: ا ولا ى؟';
  return Question(
    type: 'ar_alifLayyina', mode: QMode.choice, skill: 'layyina:$kind', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask $full', clips: [say(ask), say(full)],
    visuals: [BigLetterVisual('$plain _')],
    choices: r.shuffle(['ا', 'ى']), answer: last,
    choiceSay: const {'ا': 'ألف', 'ى': 'ألف مقصورة'},
    hint: _layyinaHints[kind]!,
    speakHint: 'فكر في نوع الكلمة وأصلها',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- الفعل والفاعل

/// (الجملة، الفعل، الفاعل، النوع) — single (مفرد، تكسير، مؤنث سالم) / dual (مثنى، جمع مذكر سالم).
const verbalSentences = [
  ('ذَهَبَ أَحْمَدُ إِلَى الْمَدْرَسَةِ.', 'ذَهَبَ', 'أَحْمَدُ', 'single'),
  ('كَتَبَ الْأَوْلَادُ الدَّرْسَ.', 'كَتَبَ', 'الْأَوْلَادُ', 'single'),
  ('نَجَحَتِ الطَّالِبَاتُ فِي الِامْتِحَانِ.', 'نَجَحَتِ', 'الطَّالِبَاتُ', 'single'),
  ('زَرَعَ الْفَلَّاحُ الْقَمْحَ.', 'زَرَعَ', 'الْفَلَّاحُ', 'single'),
  ('لَعِبَ الطِّفْلَانِ فِي الْحَدِيقَةِ.', 'لَعِبَ', 'الطِّفْلَانِ', 'dual'),
  ('حَضَرَ الْمُعَلِّمُونَ مُبَكِّرًا.', 'حَضَرَ', 'الْمُعَلِّمُونَ', 'dual'),
  ('فَازَ اللَّاعِبُونَ بِالْكَأْسِ.', 'فَازَ', 'اللَّاعِبُونَ', 'dual'),
  ('رَسَمَتِ الْبِنْتَانِ لَوْحَةً.', 'رَسَمَتِ', 'الْبِنْتَانِ', 'dual'),
];

/// الفعل بيفضل مفرد مع الفاعل المثنى والجمع: (الجملة بخانة، الصح، الاختيارات).
const verbAgreement = [
  ('___ التِّلْمِيذَانِ فِي الِامْتِحَانِ.', 'نَجَحَ', ['نَجَحَ', 'نَجَحَا', 'نَجَحُوا']),
  ('___ اللَّاعِبُونَ الْمُبَارَاةَ.', 'كَسَبَ', ['كَسَبَ', 'كَسَبُوا', 'كَسَبَا']),
  ('___ الْعُمَّالُ الْبَيْتَ.', 'بَنَى', ['بَنَى', 'بَنَوْا', 'بَنَيَا']),
  ('___ الطَّالِبَتَانِ الْقِصَّةَ.', 'قَرَأَتِ', ['قَرَأَتِ', 'قَرَأَتَا', 'قَرَأْنَ']),
];

/// مين الفعل ومين الفاعل؟ ومن درس «إفراد الفعل»: الفعل المناسب للفاعل المثنى والجمع.
/// focus: single / dual / agree.
Question arFail(int lv, Rng r, {String? focus}) {
  if (focus == 'agree' || (focus == null && lv >= 3 && r.chance(.35))) {
    final (sentence, answer, choices) = r.sample(verbAgreement);
    const ask = 'اختار الفعل المناسب للفاعل';
    return Question(
      type: 'ar_fail', mode: QMode.choice, skill: 'fail:agree', numeric: false, bigChoices: true,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [WordLineVisual.text(sentence, big: true)],
      choices: r.shuffle([...choices]), answer: answer,
      hint: 'الفعل بيفضل مفرد حتى لو الفاعل مثنى أو جمع: نَجَحَ التِّلْمِيذَانِ ☝️',
      speakHint: 'الفعل بيفضل مفرد حتى لو الفاعل مثنى أو جمع',
      sayRight: sentence.replaceFirst('___', answer),
    );
  }
  final pool = verbalSentences.where((s) => s.$4 == focus).toList();
  final (sentence, verb, subject, _) = r.sample(pool.isEmpty ? verbalSentences : pool);
  final wantSubject = lv <= 1 || r.chance(.7);
  final ask = wantSubject ? 'مين الفاعل في الجملة؟' : 'أنهي كلمة هي الفعل؟';
  final words = sentence.replaceAll('.', '').split(' ').where((w) => !['إِلَى', 'فِي'].contains(w)).toList();
  return Question(
    type: 'ar_fail', mode: QMode.choice, skill: 'fail:${wantSubject ? 'subject' : 'verb'}', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask), say(sentence)],
    visuals: [WordLineVisual.text(sentence, big: true)],
    choices: r.shuffle(words.take(3).toList()), answer: wantSubject ? subject : verb,
    hint: 'الجملة الفعلية بتبدأ بفعل، والفاعل هو اللي عمل الفعل ☝️',
    speakHint: 'الجملة الفعلية بتبدأ بفعل، والفاعل هو اللي عمل الفعل',
    sayRight: wantSubject ? subject : verb,
  );
}
