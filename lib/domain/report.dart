/// تقرير ولي الأمر: اقتراحات التدريب وقواعد المقارنة بالأسبوع اللي فات.
library;

import 'progress/progress_data.dart';
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
  for (final list in worldStages.values) {
    if (list.where((s) => playable(s.id) && (p.best[s.id] ?? 0) == 0).firstOrNull case final s?) {
      add(StepKind.fresh, 'stage:${s.id}');
      break;
    }
  }
  return out;
}

/// أسبوع فيه تدريب كفاية يتقارن بيه: يومين نشاط و٢٠ إجابة على الأقل.
bool enoughHistory(({int stars, int correct, int wrong, int games, int ms, int days}) w) =>
    w.days >= 2 && w.correct + w.wrong >= 20;
