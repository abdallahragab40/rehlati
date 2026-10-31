/// تقرير ولي الأمر: اقتراحات التدريب وقواعد المقارنة بالأسبوع اللي فات.
library;

import 'progress/progress_data.dart';
import 'school.dart';
import 'stages.dart';

/// لحد ٣ اقتراحات، كل واحد بسببه (StepKind) — من الأنشطة المفتوحة بس.
/// الترتيب: مراجعة ميعادها جه، أخطاء متكررة أو تعثّر، سورة محتاجة مراجعة، مرحلة جديدة.
List<JourneyStep> practiceSuggestions(ProgressData p) {
  final out = <JourneyStep>[];
  final seen = <String>{};
  void add(StepKind k, String target) {
    if (out.length < 3 && seen.add(target)) out.add(JourneyStep(k, target));
  }

  bool playable(String id) => packs[id] != null && !packs[id]!.isLearn && p.isUnlocked(id);

  for (final id in p.dueForReview.where(playable).take(2)) {
    add(StepKind.review, 'stage:$id');
  }
  final weak = [
    for (final w in p.weakest(10)) w.pack.split(':').first,
    for (final e in p.mastery.entries) if (e.value.struggling) e.key,
  ];
  if (weak.where(playable).firstOrNull case final id?) add(StepKind.practice, 'stage:$id');
  if (p.surahsNeedingReview.firstOrNull case final s?) add(StepKind.quran, 'quran:$s:review');
  // الجديد: أول مرحلة ما اتلعبتش من أعلى صف مفتوح مش أكبر من صف الطفل (طفل في رابعة مايتقترحلوش العد)
  final grade = gradeIndex(p.grade);
  int fit(Stage s) {
    final g = gradeIndex(stageGrade(s));
    return grade < 0 ? 0 : (g <= grade ? g : -100);
  }

  final fresh = [
    for (final list in worldStages.values)
      for (final s in list)
        if (playable(s.id) && (p.best[s.id] ?? 0) == 0) s,
  ];
  if (fresh.isNotEmpty) {
    final best = fresh.map(fit).reduce((a, b) => a > b ? a : b);
    add(StepKind.fresh, 'stage:${fresh.firstWhere((s) => fit(s) == best).id}');
  }
  return out;
}

/// أسبوع فيه تدريب كفاية يتقارن بيه: يومين نشاط و٢٠ إجابة على الأقل.
bool enoughHistory(({int stars, int correct, int wrong, int games, int ms, int days}) w) =>
    w.days >= 2 && w.correct + w.wrong >= 20;
