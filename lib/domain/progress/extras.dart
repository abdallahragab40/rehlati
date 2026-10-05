/// أجزاء ملف التقدّم الخاصة بالمدود ودليل ولي الأمر — نفس شكل JSON في الويب
/// (progress.madd و progress.parentGuide).
library;

class OkTries {
  OkTries([this.ok = 0, this.tries = 0]);
  int ok, tries;

  factory OkTries.fromJson(Object? j) =>
      j is Map ? OkTries((j['ok'] as num?)?.toInt() ?? 0, (j['tries'] as num?)?.toInt() ?? 0) : OkTries();
  Map<String, dynamic> toJson() => {'ok': ok, 'tries': tries};
}

/// إحصائيات المدود: محاولات كل نوع وكل كلمة، والأنواع اللي محتاجة مراجعة، والمراحل اللي بدأت.
class MaddStats {
  MaddStats({
    Map<String, OkTries>? types,
    Map<String, OkTries>? words,
    Set<String>? review,
    Set<String>? started,
    Set<String>? lessons,
    Map<String, int>? rounds,
  })  : types = types ?? {},
        words = words ?? {},
        review = review ?? {},
        started = started ?? {},
        lessons = lessons ?? {},
        rounds = rounds ?? {};

  final Map<String, OkTries> types;
  final Map<String, OkTries> words;
  final Set<String> review;
  final Set<String> started;
  final Set<String> lessons;
  final Map<String, int> rounds;

  /// الويب بيخزّن المجموعات كـ {key: 1}.
  static Set<String> _set(Object? o) => o is Map ? {for (final e in o.entries) if (e.value != null && e.value != 0) '${e.key}'} : {};
  static Map<String, dynamic> _setJson(Set<String> s) => {for (final k in s) k: 1};

  factory MaddStats.fromJson(Object? j) {
    if (j is! Map) return MaddStats();
    Map<String, OkTries> ot(Object? o) => o is Map ? {for (final e in o.entries) '${e.key}': OkTries.fromJson(e.value)} : {};
    return MaddStats(
      types: ot(j['types']),
      words: ot(j['words']),
      review: _set(j['review']),
      started: _set(j['started']),
      lessons: _set(j['lessons']),
      rounds: j['rounds'] is Map
          ? {for (final e in (j['rounds'] as Map).entries) '${e.key}': (e.value as num).toInt()}
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'types': {for (final e in types.entries) e.key: e.value.toJson()},
        'words': {for (final e in words.entries) e.key: e.value.toJson()},
        'review': _setJson(review),
        'started': _setJson(started),
        'lessons': _setJson(lessons),
        'rounds': rounds,
      };

  /// إتقان نوع مد = ١٠ محاولات على الأقل ونسبة نجاح ٩٠٪.
  bool mastered(String key) {
    final t = types[key];
    return t != null && t.tries >= 10 && t.ok / t.tries >= .9;
  }

  static bool wordMastered(OkTries? w) => w != null && w.ok >= 2 && w.ok / w.tries >= .8;

  /// يتسجّل مرة واحدة لكل سؤال (أول محاولة).
  void record({String? type, String? word, String? stageId, required bool ok}) {
    void bump(Map<String, OkTries> m, String k) {
      final o = m.putIfAbsent(k, OkTries.new);
      o.tries++;
      if (ok) o.ok++;
    }

    if (type != null) bump(types, type);
    if (word != null) bump(words, word);
    if (stageId != null) started.add(stageId);
  }
}

/// هدف في دليل ولي الأمر: متابعة ٧ أيام.
class PgGoal {
  PgGoal({required this.start, List<bool>? days, this.paused = false}) : days = days ?? List.filled(PgGoal.length, false);

  static const length = 7;
  final int start;
  final List<bool> days;
  bool paused;

  int get done => days.where((d) => d).length;

  factory PgGoal.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    final raw = m['days'] is List ? (m['days'] as List) : const [];
    return PgGoal(
      start: (m['start'] as num?)?.toInt() ?? 0,
      days: [for (var i = 0; i < length; i++) i < raw.length && raw[i] == true],
      paused: m['paused'] == true,
    );
  }

  Map<String, dynamic> toJson() => {'start': start, 'days': days, 'paused': paused};
}
