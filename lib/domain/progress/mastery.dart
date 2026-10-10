/// إتقان كل مرحلة ومواعيد مراجعتها — منفصل عن النجوم وعن جولة واحدة ناجحة.
///
/// القواعد (افتراضات منتج قابلة للتعديل، مش نتايج تعلّم مثبتة):
/// - بنعدّ الإجابات الصح من أول محاولة في الجولات العادية بس — "تدريب على الأخطاء" إعادة.
/// - أول جولة في اليوم بس هي اللي بتحرّك خانة المراجعة: ٨٠٪+ ← خانة أعلى، أقل ← خانة أقل
///   (مش من الأول). المراجعة الجاية بعد ١ / ٣ / ٧ أيام حسب الخانة.
/// - تفويت ميعاد المراجعة مابيعاقبش: الخانة بتفضل زي ما هي لحد الجولة الجاية.
/// - "متقن" = آخر خانة + ٣ جولات على الأقل + دقة آخر الجولات ٨٠٪+.
library;

import 'dart:math' as math;

enum MasteryState { fresh, practicing, review, mastered }

class SkillRecord {
  SkillRecord({this.rounds = 0, this.ok = 0, this.tries = 0, this.box = 0, this.last, this.due, List<int>? recent})
      : recent = recent ?? [];

  /// جولات عادية خلصت (مرات التعرّض).
  int rounds;

  /// إجابات صح من أول محاولة / عدد الأسئلة — على كل الجولات.
  int ok, tries;

  /// خانة المراجعة ٠–٣.
  int box;

  /// آخر يوم اتلعبت، ويوم المراجعة الجاية (مفاتيح أيام YYYY-MM-DD).
  String? last, due;

  /// دقة آخر ٣ جولات (٪) من أول محاولة.
  final List<int> recent;

  static const maxBox = 3;
  static const intervals = [1, 1, 3, 7];
  static const goodPct = 80;

  /// [today] و [addDays] من بره عشان الأيام تبقى بتوقيت الجهاز ومتختبرة.
  void addRound({required int firstTryOk, required int total, required String today, required String Function(int) addDays}) {
    if (total <= 0) return;
    final pct = (firstTryOk * 100 / total).round();
    rounds++;
    ok += firstTryOk;
    tries += total;
    recent.add(pct);
    if (recent.length > 3) recent.removeAt(0);
    // جولة تانية في نفس اليوم مابتسرّعش المراجعة ولا بتعاقب
    if (last == today) return;
    box = pct >= goodPct ? math.min(box + 1, maxBox) : math.max(box - 1, 0);
    last = today;
    due = addDays(intervals[box]);
  }

  bool get struggling => recent.length >= 2 && recent.skip(recent.length - 2).every((p) => p < 60);

  int get recentPct => recent.isEmpty ? 0 : (recent.reduce((a, b) => a + b) / recent.length).round();

  MasteryState state(String today) {
    if (rounds == 0) return MasteryState.fresh;
    if (box >= 1 && due != null && due!.compareTo(today) <= 0) return MasteryState.review;
    if (box >= maxBox && rounds >= 3 && recentPct >= goodPct) return MasteryState.mastered;
    return MasteryState.practicing;
  }

  factory SkillRecord.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    int n(String k) => (m[k] as num?)?.toInt() ?? 0;
    return SkillRecord(
      rounds: n('rounds'),
      ok: n('ok'),
      tries: n('tries'),
      box: n('box').clamp(0, maxBox),
      last: m['last'] as String?,
      due: m['due'] as String?,
      recent: [for (final v in (m['recent'] is List ? m['recent'] as List : const [])) (v as num).toInt()],
    );
  }

  Map<String, dynamic> toJson() =>
      {'rounds': rounds, 'ok': ok, 'tries': tries, 'box': box, 'last': last, 'due': due, 'recent': recent};
}
