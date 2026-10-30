/// تدرّج إزالة التشكيل: نفس الكلمات بتتقري مشكولة كاملة، وبعدين بتشكيل أقل، وبعدين من غير تشكيل —
/// زي ما القراية بتتعلّم في الكتاب. كل خطوة مرحلة لوحدها، والخطوة الجاية بتتفتح لما الطفل ينجح (٨٠٪+).
///
/// الكلمات من مراحل السكون والمدود: تشكيلها متراجع ومتسجّل بصوت مشكول، فالنطق دايمًا صح حتى لو
/// الكلمة ظاهرة من غير تشكيل. صوت الكلمة مابيتقالش في السؤال (ده تمرين قراية) — بس في التلميح.
library;

import '../../content/madd_data.g.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';
import 'sukun_generators.dart';

/// (الكلمة مشكولة كاملة، صورتها). دار ودين برّه: صورهم (🏠 🕌) بتتلخبط مع بيت.
final fadeWords = <(String, String)>[
  for (final s in sukunWords) (s.word, s.emoji),
  for (final m in maddWords)
    if (m.pic && m.plain != 'دار' && m.plain != 'دين') (m.w, m.e),
];

const _sukun = 'ْ';
const _tanween = {'ً', 'ٌ', 'ٍ'};
const _harakat = {'َ', 'ُ', 'ِ'};
const _maddLetters = {'ا', 'و', 'ي'};

/// [step] ٠ = التشكيل كامل. ١ = من غير السكون والتنوين، ومن غير الحركة اللي قبل حرف المد
/// (الحرف نفسه بيقول الصوت). ٢ = من غير أي تشكيل. الشدّة بتفضل لحد الخطوة الأخيرة.
String fadeMarks(String word, int step) {
  if (step <= 0) return word;
  final chars = word.split('');
  final out = StringBuffer();
  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];
    final mark = c.codeUnitAt(0) >= 0x064B && c.codeUnitAt(0) <= 0x0652;
    if (!mark) {
      out.write(c);
      continue;
    }
    if (step >= 2 || c == _sukun || _tanween.contains(c)) continue;
    // حركة قبل حرف مد من نفس نوعها (بَا، بُو، بِي) — الحرف اللي بعدها بيقولها
    if (_harakat.contains(c) && i + 1 < chars.length && _maddLetters.contains(chars[i + 1])) continue;
    out.write(c);
  }
  return out.toString();
}

/// مولّد خطوة من خطوات التدرّج: نص الأسئلة من الكلمة للصورة، ونصها من الصورة للكلمة.
Question Function(int lv, Rng r, {String? focus}) fadeGen(String type, int step) => (lv, r, {focus}) {
      final (full, emoji) = fadeWords.where((w) => w.$1 == focus).firstOrNull ?? r.sample(fadeWords);
      final shown = fadeMarks(full, step);
      if (r.chance(.5)) {
        return Question(
          type: type, mode: QMode.choice, skill: 'fade:$full',
          ask: 'أنهي صورة للكلمة دي؟', speak: 'أنهي صورة للكلمة دي؟',
          clips: [say('أنهي صورة للكلمة دي؟')],
          visuals: [WordLineVisual.text(shown, big: true)],
          choices: r.textChoices(emoji, [for (final w in fadeWords) w.$2], 3),
          answer: emoji,
          // التلميح بيوري الكلمة بتشكيلها الكامل — نفس فكرة الكتاب
          hint: 'اقرا الكلمة بالراحة: $full',
          speakHint: 'اقرا الكلمة بالراحة: $full',
          clipsHint: [say('اقرا الكلمة بالراحة'), say(full)],
        );
      }
      final choices = r.textChoices(full, [for (final w in fadeWords) w.$1], 3);
      return Question(
        type: type, mode: QMode.choice, skill: 'fade:$full',
        ask: 'اختار الكلمة الصحيحة', speak: 'اختار الكلمة الصحيحة',
        visuals: [PicsVisual(emoji, 1, big: true)],
        choices: [for (final c in choices) fadeMarks(c, step)],
        // الطفل لو اختار كلمة بتتقال بتشكيلها الكامل (المقطع المسجّل)
        choiceSay: {for (final c in choices) fadeMarks(c, step): c},
        answer: shown, wide: true,
        hint: 'اقرا الكلمات بالراحة',
        speakHint: 'اقرا الكلمات بالراحة',
      );
    };
