/// "رحلة النهاردة": تسلسل قصير من المراحل المفتوحة — تسخين، تدريب على نقطة ضعف،
/// وبعدين حاجة جديدة (أو مراجعة سورة). منطق صافي من غير واجهة — سهل يتختبر.
library;

import 'dart:math' as math;

import 'progress/progress_data.dart';
import 'school.dart';
import 'stages.dart';

/// نوع الخطوة — بيحدد السبب اللي بيظهر لولي الأمر.
enum StepKind {
  /// أول مرحلة لطفل جديد.
  start,

  /// تسخين بمرحلة الطفل بيعرفها كويس.
  warm,

  /// مرحلة ميعاد مراجعتها جه (جدول ١ / ٣ / ٧ أيام).
  review,

  /// مرحلة فيها أخطاء اتكررت — المحرك بيرجّع المهارة الضعيفة تلقائيًا.
  practice,

  /// مرحلة اتلعبت بس لسه ما خدتش ٣ ميداليات.
  improve,

  /// مرحلة اتفتحت ولسه ما اتلعبتش.
  fresh,

  /// سورة اتحفظت ومحتاجة مراجعة (والنص على الجهاز).
  quran,
}

class JourneyStep {
  JourneyStep(this.kind, this.target, {this.done = false, this.skipped = false});

  final StepKind kind;

  /// `stage:ID` أو `quran:SURAH:review`.
  final String target;
  bool done;

  /// الطفل اتخطّاها — الرحلة بتكمّل من غيرها، ولو لعبها بعدين بتبقى done.
  bool skipped;

  /// اتلعبت أو اتخطّت — الرحلة عدّت عليها.
  bool get passed => done || skipped;

  Stage? get stage => target.startsWith('stage:') ? packs[target.substring(6)] : null;
  int? get surah => target.startsWith('quran:') ? int.tryParse(target.split(':')[1]) : null;
  String get world => stage?.world ?? 'quran';

  factory JourneyStep.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return JourneyStep(
      StepKind.values.firstWhere((k) => k.name == m['kind'], orElse: () => StepKind.warm),
      '${m['target'] ?? ''}',
      done: m['done'] == true,
      skipped: m['skipped'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'kind': kind.name, 'target': target, 'done': done, 'skipped': skipped};
}

class Journey {
  Journey(this.day, this.steps, {this.rewarded = false, this.celebrated = false});

  /// مفتاح اليوم (ProgressData.dayKey) — رحلة لكل طفل في اليوم.
  final String day;
  final List<JourneyStep> steps;

  /// نجوم الختام اتدّت (مرة واحدة بس).
  bool rewarded;

  /// الاحتفال اتعرض للطفل.
  bool celebrated;

  /// كل الخطوات اتلعبت — ده بس اللي بيدّي نجوم الختام.
  bool get complete => steps.isNotEmpty && steps.every((s) => s.done);

  /// الرحلة خلصت: كل خطوة اتلعبت أو اتخطّت.
  bool get finished => steps.isNotEmpty && steps.every((s) => s.passed);
  int get doneCount => steps.where((s) => s.done).length;
  int get skippedCount => steps.where((s) => s.skipped && !s.done).length;
  int get passedCount => steps.where((s) => s.passed).length;
  JourneyStep? get next => steps.where((s) => !s.passed).firstOrNull;

  static const bonusStars = 3;

  factory Journey.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return Journey(
      '${m['day'] ?? ''}',
      [
        for (final s in (m['steps'] is List ? m['steps'] as List : const []))
          JourneyStep.fromJson(s),
      ]..removeWhere((s) => s.stage == null && s.surah == null),
      rewarded: m['rewarded'] == true,
      celebrated: m['celebrated'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'steps': [for (final s in steps) s.toJson()],
        'rewarded': rewarded,
        'celebrated': celebrated,
      };
}

/// العوالم اللي ممكن تدخل الرحلة، بالترتيب.
const journeyWorlds = ['math', 'arabic', 'english', 'games', 'quran'];

/// يخطط رحلة النهاردة من التقدّم المحفوظ بس.
///
/// [quranReady]: السور اللي نصها على الجهاز — سورة مش متنزّلة مابتدخلش الرحلة.
/// [minutesLeft]: الوقت الفاضل من حد اليوم (null = مفيش حد) — الرحلة بتقصر على قده.
Journey planJourney(ProgressData p, {required String day, Set<int> quranReady = const {}, int? minutesLeft}) {
  final off = p.settings.journeyOff;
  final seed = day.codeUnits.fold<int>(0, (h, c) => (h * 31 + c) & 0x3fffffff);

  // مراحل لعب مفتوحة (لوحة الحروف مش جولة بنتيجة فمابتدخلش)،
  // من غير اللي ولي الأمر اتخطّاها والطفل لسه ما لعبهاش، ومن غير ألعاب مش لسنه
  final candidates = [
    for (final w in journeyWorlds)
      if (w != 'quran' && !off.contains(w))
        for (final s in worldStages[w] ?? const <Stage>[])
          if (!s.isLearn && p.isUnlocked(s.id) && (p.best[s.id] != null || !p.skipped.contains(s.id)) && fitsAge(s, p.age)) s,
  ];
  final used = <String>{};
  int medals(Stage s) => p.best[s.id] ?? 0;

  // طفل في الابتدائي: البداية والجديد من أعلى صف مفتوح مش أكبر من صفه — مايبدأش بالعد وهو في رابعة.
  // من غير صف (أو في الحضانة) الاختيار زي ما هو.
  final grade = schoolGrades.indexOf(p.schoolGrade ?? '');
  int fit(Stage s) {
    final g = schoolGrades.indexOf(stageGrade(s) ?? '');
    return g <= grade ? g : -100;
  }

  Iterable<Stage> suited(Iterable<Stage> from) {
    if (grade < 0 || from.isEmpty) return from;
    final best = from.map(fit).reduce(math.max);
    return from.where((s) => fit(s) == best);
  }

  /// اختيار ثابت لنفس اليوم من وسط قايمة.
  Stage? pick(Iterable<Stage> from, [int salt = 0]) {
    final list = from.where((s) => !used.contains(s.id)).toList();
    if (list.isEmpty) return null;
    final s = list[(seed + salt) % list.length];
    used.add(s.id);
    return s;
  }

  JourneyStep stageStep(StepKind k, Stage s) => JourneyStep(k, 'stage:${s.id}');

  // ١) مراجعة ميعادها جه، وإلا تسخين بمرحلة بيعرفها، ولطفل جديد أول مرحلة متاحة
  JourneyStep? warm;
  final due = [for (final id in p.dueForReview) ?packs[id]].where(candidates.contains);
  if (due.firstOrNull case final s?) {
    used.add(s.id);
    warm = stageStep(StepKind.review, s);
  } else if (pick(candidates.where((s) => medals(s) >= 2)) ?? pick(candidates.where((s) => medals(s) >= 1), 1)
      case final s?) {
    warm = stageStep(StepKind.warm, s);
  } else if (suited(candidates).firstOrNull case final s?) {
    used.add(s.id);
    warm = stageStep(StepKind.start, s);
  }

  // ٢) تدريب: أكتر مرحلة فيها أخطاء متكررة، وإلا مرحلة لسه ما كملتش ميدالياتها
  JourneyStep? practice;
  for (final w in p.weakest(20)) {
    final s = packs[w.pack.split(':').first];
    if (s != null && candidates.contains(s) && used.add(s.id)) {
      practice = stageStep(StepKind.practice, s);
      break;
    }
  }
  if (practice == null) {
    final weak = candidates.where((s) => medals(s) == 1 || medals(s) == 2).toList()
      ..sort((a, b) => medals(a) - medals(b));
    if (pick(weak.take(3), 2) case final s?) practice = stageStep(StepKind.improve, s);
  }

  // ٣) جديد: سورة متأخرة في المراجعة ونصها جاهز، وإلا مرحلة جديدة من عالم تاني
  JourneyStep? fresh;
  final review = p.surahsNeedingReview.where(quranReady.contains);
  if (!off.contains('quran') && review.isNotEmpty) {
    fresh = JourneyStep(StepKind.quran, 'quran:${review.first}:review');
  } else {
    final seen = {for (final s in [warm, practice].nonNulls) s.world};
    final unplayed = candidates.where((s) => medals(s) == 0);
    final s = pick(suited(unplayed.where((s) => !seen.contains(s.world) && !used.contains(s.id))), 3) ??
        pick(suited(unplayed.where((s) => !used.contains(s.id))), 3);
    if (s != null) fresh = stageStep(StepKind.fresh, s);
  }

  final steps = [warm, practice, fresh].nonNulls.toList();
  // وقت قليل: الرحلة بتقصر — التدريب أهم حاجة، وبعده الجديد
  final room = minutesLeft == null ? 3 : (minutesLeft ~/ 4).clamp(1, 3);
  for (final k in [StepKind.warm, StepKind.start, StepKind.fresh, StepKind.quran, StepKind.improve, StepKind.review]) {
    if (steps.length <= room) break;
    steps.removeWhere((s) => s.kind == k);
  }
  return Journey(day, steps.take(room).toList());
}
