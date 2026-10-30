/// ورقة عمل تتطبع: أسئلة من المراحل اللي الطفل محتاج يتدرّب عليها، ومركّزة على المهارة اللي بيغلط فيها.
/// بس الأسئلة اللي تنفع على ورق: اختيار من نصوص، من غير صوت أو سحب أو لعب.
library;

import '../core/utils/rng.dart';
import 'progress/progress_data.dart';
import 'question.dart';
import 'stages.dart';

class WorksheetSection {
  const WorksheetSection(this.stage, this.questions);
  final Stage stage;
  final List<Question> questions;
}

/// أسئلة كل قسم (صفحة واحدة: عمودين × ٤ صفوف).
const worksheetPerSection = 8;

/// أقصى عدد أقسام (صفحات).
const worksheetSections = 3;

/// السؤال ينفع يتحل بالقلم؟ اختيار من نصوص، ومرئياته كلها بتترسم من غير صوت ولا لمس.
bool printable(Question q) =>
    q.mode == QMode.choice &&
    q.look == ChoiceLook.text &&
    q.choices.length >= 2 &&
    q.answer != null &&
    !RegExp('اسمع|سمعت|👂|[Ll]isten|hear').hasMatch(q.ask) &&
    // القطعة الطويلة مش هتتقري في خانة صغيرة، والمقطع اللي عليه 🔊 محتاج الصوت
    q.visuals.every((v) => v is! ListenVisual && v is! TableVisual && v is! PassageVisual && !(v is MaddTextVisual && v.say != null));

/// المراحل بالترتيب: مهارات ضعيفة، متعثّرة، ميعاد مراجعتها جه، اتلعبت من غير ٣ ميداليات.
/// مراحل مفتوحة بس، وفيها أسئلة تتطبع.
List<Stage> worksheetStages(ProgressData p, Rng r) {
  final ids = <String>[
    for (final w in p.weakest(10)) w.pack.split(':').first,
    for (final e in p.mastery.entries) if (e.value.struggling) e.key,
    ...p.dueForReview,
    for (final e in p.best.entries) if (e.value < 3) e.key,
    for (final e in p.best.entries) e.key,
  ];
  final out = <Stage>[];
  for (final id in ids.toSet()) {
    final s = packs[id];
    if (s == null || s.gen == null || s.isLearn || !p.isUnlocked(id)) continue;
    // المرحلة اللي أغلب أسئلتها صوت أو لعب مش هتملا صفحة
    final sample = [for (var i = 0; i < 12; i++) makeQuestion(id, roundLevel(p, s), r, progress: p)];
    if (sample.where(printable).length < 4) continue;
    out.add(s);
    if (out.length == worksheetSections) break;
  }
  return out;
}

/// الورقة كلها — كل مرة بتطلع أسئلة جديدة. الأسئلة مختلفة جوه القسم (من غير تكرار نفس السؤال).
List<WorksheetSection> buildWorksheet(ProgressData p, Rng r) => [
      for (final s in worksheetStages(p, r)) WorksheetSection(s, _questions(p, s, r)),
    ];

List<Question> _questions(ProgressData p, Stage s, Rng r) {
  final level = roundLevel(p, s), focus = p.focus(s.id);
  final out = <Question>[], seen = <String>{};
  for (var tries = 0; out.length < worksheetPerSection && tries < 120; tries++) {
    // نص الأسئلة على المهارة الضعيفة، والباقي مراجعة عامة
    final q = makeQuestion(s.id, level, r, focus: focus != null && tries.isEven ? focus : null, progress: p);
    if (printable(q) && seen.add('${q.ask}|${q.visuals.length}|${q.answer}|${q.choices.join(',')}')) out.add(q);
  }
  return out;
}

/// حروف الاختيارات: أ ب ج بالعربي، a b c في أسئلة الإنجليزي.
List<String> choiceLetters(Question q) => q.ltr ? const ['a', 'b', 'c', 'd', 'e', 'f'] : const ['أ', 'ب', 'ج', 'د', 'هـ', 'و'];

/// حرف الاختيار الصح — مفتاح الإجابات لولي الأمر.
String answerLetter(Question q) {
  final i = q.choices.indexWhere((c) => '$c' == '${q.answer}');
  return i < 0 || i >= choiceLetters(q).length ? '؟' : choiceLetters(q)[i];
}
