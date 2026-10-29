/// مولّدات الحركات (أولى ابتدائي): الفتحة والضمة والكسرة على الحرف.
///
/// المقاطع (بَ بُ بِ) بتتنطق من مقاطع التعليم المشكولة (lib/core/audio/teaching.dart).
/// الألف مش موجودة هنا: أَ أُ إِ همزة، مش صوت الألف.
library;

import '../../content/language_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/rng.dart';
import '../question.dart';
import 'arabic_generators.dart' show arPool;

/// (العلامة، اسمها).
const harakat = [('َ', 'فتحة'), ('ُ', 'ضمة'), ('ِ', 'كسرة')];

const _names = ['فتحة', 'ضمة', 'كسرة'];

const _hint = 'الفتحة شَرطة فوق الحرف، والكسرة شَرطة تحته، والضمة واو صغيرة فوقه ☝️';

List<Letter> _pool(int lv) => arPool(lv).where((l) => l.letter != 'أ').toList();

/// الحركة: الضعيفة لو فيه (التعلّم المتكيّف)، وإلا عشوائي.
(String, String) _haraka(Rng r, String? focus) =>
    harakat.where((h) => h.$2 == focus).firstOrNull ?? r.sample(harakat);

/// ١ — إيه الحركة؟ مقطع كبير والطفل يختار اسم الحركة.
Question arHaraka(int lv, Rng r, {String? focus}) {
  final l = r.sample(_pool(lv));
  final (mark, name) = _haraka(r, focus);
  final syl = '${l.letter}$mark';
  return Question(
    type: 'ar_haraka', mode: QMode.choice, skill: 'haraka:$name', numeric: false,
    ask: 'إيه الحركة اللي على الحرف؟',
    speak: 'إيه الحركة اللي على الحرف؟',
    visuals: [BigLetterVisual(syl)],
    choices: r.shuffle([..._names]),
    answer: name,
    hint: _hint,
    // بعد الإجابة الصح بيسمع المقطع نفسه
    sayRight: syl,
  );
}

/// ٢ — اختار الحرف اللي عليه ضمة: نفس الحرف بالتلات حركات، واحدة بس صح.
Question arHarakaPick(int lv, Rng r, {String? focus}) {
  final l = r.sample(_pool(lv));
  final (mark, name) = _haraka(r, focus);
  return Question(
    type: 'ar_haraka_pick', mode: QMode.choice, skill: 'haraka:$name', numeric: false, bigChoices: true,
    ask: 'اختار الحرف اللي عليه $name',
    speak: 'اختار الحرف اللي عليه $name',
    clips: [say('اختار الحرف اللي عليه'), say(name)],
    visuals: [BigLetterVisual(l.letter)],
    choices: r.shuffle([for (final (m, _) in harakat) '${l.letter}$m']),
    answer: '${l.letter}$mark',
    hint: _hint,
    sayRight: '${l.letter}$mark',
  );
}

/// ٣ — اسمع واختار المقطع (محتاجة الصوت). من المستوى التالت: حرف تاني بنفس الحركة كمان.
Question arSyllable(int lv, Rng r, {String? focus}) {
  final pool = _pool(lv);
  final l = r.sample(pool);
  final (mark, name) = _haraka(r, focus);
  final syl = '${l.letter}$mark';
  final other = r.sample(pool.where((x) => x.letter != l.letter).toList());
  return Question(
    type: 'ar_syllable', mode: QMode.choice, skill: 'syl:$name', numeric: false, bigChoices: true,
    ask: 'اسمع المقطع كويس… واختاره 👂',
    speak: syl,
    clips: [say(syl)],
    visuals: [ListenVisual(syl)],
    choices: r.shuffle([
      for (final (m, _) in harakat) '${l.letter}$m',
      if (lv >= 3) '${other.letter}$mark',
    ]),
    answer: syl,
    hint: 'اضغط 🔊 واسمع تاني: بص على الحرف وعلى الحركة',
    speakHint: 'اسمع تاني بالراحة',
    sayRight: syl,
  );
}
