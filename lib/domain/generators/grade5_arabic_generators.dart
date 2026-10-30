/// دروس عربي خامسة ابتدائي (tool/SCHOOL_CURRICULUM_INDEX.md): المفعول به بأنواعه، همزة القطع وألف الوصل،
/// الهمزة المتطرفة (على السطر والألف والواو والياء)، المفعول لأجله والمطلق والظرف، والاسم المجرور والمضاف إليه.
///
/// الأمثلة من عندنا ومشكولة، وكل سؤال ليه إجابة واحدة بس. محتاجة مراجعة مدرّس عربي.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// جملة بخانة، والاختيارات نفس الكلمة بآخر مختلف (الإعراب).
Question _blank(String type, String skill, String ask, String sentence, String answer, List<String> choices, Rng r,
        {required String hint, required String speakHint}) =>
    Question(
      type: type, mode: QMode.choice, skill: skill, numeric: false, bigChoices: true,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [WordLineVisual.text(sentence, big: true)],
      choices: r.shuffle([...choices]), answer: answer,
      hint: hint, speakHint: speakHint,
      sayRight: sentence.replaceFirst('___', answer),
    );

// ---------------------------------------------------------------- المفعول به

/// (الجملة، الصح، الاختيارات، النوع) — single (مفرد وجمع تكسير بالفتحة)، fem (جمع مؤنث سالم بالكسرة)،
/// dual (المثنى وجمع المذكر السالم بالياء).
const mafoolSentences = [
  ('قَرَأَ أَحْمَدُ ___.', 'الْكِتَابَ', ['الْكِتَابَ', 'الْكِتَابُ', 'الْكِتَابِ'], 'single'),
  ('شَرِبَ الطِّفْلُ ___.', 'اللَّبَنَ', ['اللَّبَنَ', 'اللَّبَنُ', 'اللَّبَنِ'], 'single'),
  ('زَرَعَ الْفَلَّاحُ ___.', 'الْأَشْجَارَ', ['الْأَشْجَارَ', 'الْأَشْجَارُ', 'الْأَشْجَارِ'], 'single'),
  ('شَكَرَ الْمُدِيرُ ___.', 'الْمُعَلِّمَاتِ', ['الْمُعَلِّمَاتِ', 'الْمُعَلِّمَاتُ', 'الْمُعَلِّمَاتَ'], 'fem'),
  ('كَتَبَتْ سَارَةُ ___.', 'الْكَلِمَاتِ', ['الْكَلِمَاتِ', 'الْكَلِمَاتُ', 'الْكَلِمَاتَ'], 'fem'),
  ('كَرَّمَتِ الْمَدْرَسَةُ ___.', 'الطَّالِبَاتِ', ['الطَّالِبَاتِ', 'الطَّالِبَاتُ', 'الطَّالِبَاتَ'], 'fem'),
  ('كَافَأَ الْمُدِيرُ ___.', 'الْفَائِزِينَ', ['الْفَائِزِينَ', 'الْفَائِزُونَ'], 'dual'),
  ('شَاهَدْتُ ___ يَلْعَبَانِ.', 'الطِّفْلَيْنِ', ['الطِّفْلَيْنِ', 'الطِّفْلَانِ'], 'dual'),
  ('احْتَرَمَ التَّلَامِيذُ ___.', 'الْمُعَلِّمِينَ', ['الْمُعَلِّمِينَ', 'الْمُعَلِّمُونَ'], 'dual'),
  ('قَابَلْتُ ___ أَمْسِ.', 'الصَّدِيقَيْنِ', ['الصَّدِيقَيْنِ', 'الصَّدِيقَانِ'], 'dual'),
];

const _mafoolHints = {
  'single': 'المفعول به منصوب بالفتحة: قَرَأَ أَحْمَدُ الْكِتَابَ ☝️',
  'fem': 'جمع المؤنث السالم بيتنصب بالكسرة مش بالفتحة: شَكَرَ الْمُدِيرُ الْمُعَلِّمَاتِ ☝️',
  'dual': 'المثنى وجمع المذكر السالم بيتنصبوا بالياء: الطِّفْلَيْنِ، الْمُعَلِّمِينَ ☝️',
};

/// focus: single / fem / dual.
Question arMafool(int lv, Rng r, {String? focus}) {
  final pool = mafoolSentences.where((s) => s.$4 == focus).toList();
  final (sentence, answer, choices, kind) = r.sample(pool.isEmpty ? mafoolSentences : pool);
  return _blank('ar_mafool', 'mafool:$kind', 'اختار المفعول به بالشكل الصح', sentence, answer, choices, r,
      hint: _mafoolHints[kind]!, speakHint: 'المفعول به منصوب، ركز في آخر الكلمة');
}

// ---------------------------------------------------------------- همزة القطع وألف الوصل

/// (الكلمة من غير أول حرف، الكلمة مشكولة، أول حرف).
const hamzaQatWords = [
  ('كل', 'أَكَلَ', 'أ'), ('خذ', 'أَخَذَ', 'أ'), ('رنب', 'أَرْنَبٌ', 'أ'), ('حمد', 'أَحْمَدُ', 'أ'),
  ('سلام', 'إِسْلَامٌ', 'إ'), ('بريق', 'إِبْرِيقٌ', 'إ'), ('كرام', 'إِكْرَامٌ', 'إ'),
  ('ستخرج', 'اسْتَخْرَجَ', 'ا'), ('نتصر', 'انْتَصَرَ', 'ا'), ('جتمع', 'اجْتَمَعَ', 'ا'), ('كتب', 'اُكْتُبْ', 'ا'),
  ('بن', 'ابْنٌ', 'ا'), ('سم', 'اسْمٌ', 'ا'),
];

Question arHamzaQat(int lv, Rng r, {String? focus}) {
  final (rest, full, first) = hamzaQatWords.where((w) => w.$2 == focus).firstOrNull ?? r.sample(hamzaQatWords);
  const ask = 'أول الكلمة: همزة قطع ولا ألف وصل؟';
  return Question(
    type: 'ar_hamzaQat', mode: QMode.choice, skill: 'hamzaQat:$first', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask. $full', clips: [say(ask), say(full)],
    // «_» على اليمين = أول الكلمة
    visuals: [BigLetterVisual('_$rest')],
    choices: r.shuffle(['أ', 'إ', 'ا']), answer: first,
    choiceSay: const {'أ': 'همزة قطع فوق الألف', 'إ': 'همزة قطع تحت الألف', 'ا': 'ألف وصل'},
    hint: 'همزة القطع بتتنطق دايمًا (أَكَلَ، إِسْلَام)، وألف الوصل بتسقط لما نوصل الكلام (وَاكْتُبْ، وَاسْتَخْرَجَ) ☝️',
    speakHint: 'همزة القطع بتتنطق دايما، وألف الوصل بتسقط لما نوصل الكلام',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- الهمزة المتطرفة

/// (الكلمة من غير آخرها، الكلمة مشكولة، الهمزة، مكانها) — line / alif / waw / yaa،
/// والهمزة بتتكتب على حسب حركة الحرف اللي قبلها.
const hamzaEndWords = [
  ('شي', 'شَيْءٌ', 'ء', 'line'), ('دف', 'دِفْءٌ', 'ء', 'line'), ('جز', 'جُزْءٌ', 'ء', 'line'), ('ضو', 'ضَوْءٌ', 'ء', 'line'),
  ('بد', 'بَدَأَ', 'أ', 'alif'), ('قر', 'قَرَأَ', 'أ', 'alif'), ('ملج', 'مَلْجَأٌ', 'أ', 'alif'), ('نب', 'نَبَأٌ', 'أ', 'alif'),
  ('لؤل', 'لُؤْلُؤٌ', 'ؤ', 'waw'), ('التباط', 'التَّبَاطُؤُ', 'ؤ', 'waw'), ('تكاف', 'تَكَافُؤٌ', 'ؤ', 'waw'), ('يجر', 'يَجْرُؤُ', 'ؤ', 'waw'),
  ('شاط', 'شَاطِئٌ', 'ئ', 'yaa'), ('قار', 'قَارِئٌ', 'ئ', 'yaa'), ('داف', 'دَافِئٌ', 'ئ', 'yaa'), ('مبتد', 'مُبْتَدِئٌ', 'ئ', 'yaa'),
];

/// focus: line / alif / waw / yaa.
Question arHamzaEnd(int lv, Rng r, {String? focus}) {
  final pool = hamzaEndWords.where((w) => w.$4 == focus).toList();
  final (plain, full, hamza, kind) = r.sample(pool.isEmpty ? hamzaEndWords : pool);
  const ask = 'الهمزة في آخر الكلمة بتتكتب إزاي؟';
  return Question(
    type: 'ar_hamzaEnd', mode: QMode.choice, skill: 'hamzaEnd:$kind', numeric: false, bigChoices: true,
    ask: ask, speak: '$ask $full', clips: [say(ask), say(full)],
    visuals: [BigLetterVisual('$plain _')],
    choices: r.shuffle(['ء', 'أ', 'ؤ', 'ئ']), answer: hamza,
    choiceSay: const {'ء': 'على السطر', 'أ': 'على الألف', 'ؤ': 'على الواو', 'ئ': 'على الياء'},
    hint: 'بص على حركة الحرف اللي قبلها: سكون ← ء، فتحة ← أ، ضمة ← ؤ، كسرة ← ئ ☝️',
    speakHint: 'بص على حركة الحرف اللي قبلها',
    sayRight: full,
  );
}

// ---------------------------------------------------------------- المفاعيل والظرف

/// (الجملة، الكلمة، نوعها) — bih / ajlih / mutlaq / zarf.
const mafaeelSentences = [
  ('وَقَفَ التَّلَامِيذُ احْتِرَامًا لِلْمُعَلِّمِ.', 'احْتِرَامًا', 'ajlih'),
  ('سَافَرَ أَبِي طَلَبًا لِلرِّزْقِ.', 'طَلَبًا', 'ajlih'),
  ('ذَاكَرْتُ رَغْبَةً فِي النَّجَاحِ.', 'رَغْبَةً', 'ajlih'),
  ('فَرِحَ الطِّفْلُ فَرَحًا كَبِيرًا.', 'فَرَحًا', 'mutlaq'),
  ('جَرَى اللَّاعِبُ جَرْيًا سَرِيعًا.', 'جَرْيًا', 'mutlaq'),
  ('نَامَ أَخِي نَوْمًا عَمِيقًا.', 'نَوْمًا', 'mutlaq'),
  ('سَافَرْنَا صَبَاحًا.', 'صَبَاحًا', 'zarf'),
  ('جَلَسَ الْقِطُّ تَحْتَ الشَّجَرَةِ.', 'تَحْتَ', 'zarf'),
  ('قَرَأَ أَحْمَدُ الْقِصَّةَ.', 'الْقِصَّةَ', 'bih'),
  ('أَكَلَ الْوَلَدُ تُفَّاحَةً.', 'تُفَّاحَةً', 'bih'),
];

const _mafaeelNames = {'bih': 'مفعول به', 'ajlih': 'مفعول لأجله', 'mutlaq': 'مفعول مطلق', 'zarf': 'ظرف'};

/// الكلمة دي في الجملة إيه؟ focus: ajlih / mutlaq / zarf — الدرس بيختار جمله أكتر.
Question arMafaeel(int lv, Rng r, {String? focus}) {
  final mine = mafaeelSentences.where((s) => s.$3 == focus).toList();
  final (sentence, word, kind) = r.sample(mine.isNotEmpty && r.chance(.6) ? mine : mafaeelSentences);
  const ask = 'الكلمة اللي تحت الجملة إعرابها إيه؟';
  return Question(
    type: 'ar_mafaeel', mode: QMode.choice, skill: 'mafaeel:$kind', numeric: false,
    ask: ask, speak: ask, clips: [say(ask), say(sentence)],
    visuals: [WordLineVisual.text(sentence, big: true), CaptionVisual('الكلمة: «$word»')],
    choices: r.shuffle(_mafaeelNames.values.toList()), answer: _mafaeelNames[kind]!,
    hint: 'المفعول لأجله بيقول «ليه؟»، والمطلق مصدر من نفس الفعل، والظرف بيقول «إمتى؟» أو «فين؟»، والمفعول به اللي وقع عليه الفعل ☝️',
    speakHint: 'المفعول لأجله بيقول ليه، والمطلق مصدر من نفس الفعل، والظرف بيقول إمتى أو فين',
    sayRight: sentence,
  );
}

// ---------------------------------------------------------------- الاسم المجرور والمضاف إليه

/// (الجملة، الصح، الاختيارات، النوع) — jar (بعد حرف جر) / idafa (مضاف إليه).
const majrurSentences = [
  ('ذَهَبْتُ إِلَى ___.', 'الْمَدْرَسَةِ', ['الْمَدْرَسَةِ', 'الْمَدْرَسَةُ', 'الْمَدْرَسَةَ'], 'jar'),
  ('نَظَرْتُ إِلَى ___.', 'النُّجُومِ', ['النُّجُومِ', 'النُّجُومُ', 'النُّجُومَ'], 'jar'),
  ('أَخَذْتُ الْكِتَابَ مِنَ ___.', 'الْمَكْتَبَةِ', ['الْمَكْتَبَةِ', 'الْمَكْتَبَةُ', 'الْمَكْتَبَةَ'], 'jar'),
  ('سَلَّمْتُ عَلَى ___.', 'الْمُعَلِّمِينَ', ['الْمُعَلِّمِينَ', 'الْمُعَلِّمُونَ'], 'jar'),
  ('اسْتَمَعْتُ إِلَى ___.', 'الطَّالِبَيْنِ', ['الطَّالِبَيْنِ', 'الطَّالِبَانِ'], 'jar'),
  ('هَذَا كِتَابُ ___.', 'الطَّالِبِ', ['الطَّالِبِ', 'الطَّالِبُ', 'الطَّالِبَ'], 'idafa'),
  ('هَذِهِ حَدِيقَةُ ___.', 'الْمَدْرَسَةِ', ['الْمَدْرَسَةِ', 'الْمَدْرَسَةُ', 'الْمَدْرَسَةَ'], 'idafa'),
  ('قَرَأْتُ قِصَصَ ___.', 'الْأَطْفَالِ', ['الْأَطْفَالِ', 'الْأَطْفَالُ', 'الْأَطْفَالَ'], 'idafa'),
  ('هَذَا فَصْلُ ___.', 'الْمُعَلِّمِينَ', ['الْمُعَلِّمِينَ', 'الْمُعَلِّمُونَ'], 'idafa'),
  ('أَعْجَبَنِي رَسْمُ ___.', 'الْبِنْتَيْنِ', ['الْبِنْتَيْنِ', 'الْبِنْتَانِ'], 'idafa'),
];

/// focus: jar / idafa.
Question arMajrur(int lv, Rng r, {String? focus}) {
  final pool = majrurSentences.where((s) => s.$4 == focus).toList();
  final (sentence, answer, choices, kind) = r.sample(pool.isEmpty ? majrurSentences : pool);
  final jar = kind == 'jar';
  return _blank('ar_majrur', 'majrur:$kind', jar ? 'اختار الاسم المجرور بالشكل الصح' : 'اختار المضاف إليه بالشكل الصح',
      sentence, answer, choices, r,
      hint: '${jar ? 'الاسم بعد حرف الجر' : 'المضاف إليه'} مجرور: بالكسرة، والمثنى وجمع المذكر السالم بالياء ☝️',
      speakHint: 'مجرور بالكسرة، والمثنى وجمع المذكر السالم بالياء');
}
