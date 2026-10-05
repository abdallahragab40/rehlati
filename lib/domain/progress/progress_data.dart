/// ملف تقدّم الطفل — نفس شكل JSON بتاع نسخة الويب (rehlati.math.v1) عشان المنطق يتنقل زي ما هو.
///
/// الكلاس ده منطق صافي من غير تخزين ولا Riverpod — سهل يتختبر.
library;

import 'dart:math' as math;

import '../stages.dart';
import 'extras.dart';

export 'extras.dart';

class Settings {
  Settings({this.speech = true, this.sfx = true, this.dev = false});

  factory Settings.fromJson(Map<String, dynamic> j) => Settings(
        speech: j['speech'] as bool? ?? true,
        sfx: j['sfx'] as bool? ?? true,
        dev: j['dev'] as bool? ?? false,
      );

  bool speech;
  bool sfx;

  /// فتح كل المراحل — للتجربة بس.
  bool dev;

  Map<String, dynamic> toJson() => {'speech': speech, 'sfx': sfx, 'dev': dev};
}

class ProgressData {
  ProgressData({
    this.name = '',
    this.stars = 0,
    this.correct = 0,
    this.wrong = 0,
    this.games = 0,
    this.timeMs = 0,
    this.lastActivity,
    this.lastStage,
    List<String>? unlocked,
    Map<String, int>? best,
    Map<String, int>? starsBy,
    Map<String, int>? quran,
    Map<String, List<String>>? learn,
    Map<String, int>? skills,
    List<String>? achievements,
    Settings? settings,
    MaddStats? madd,
    Map<String, PgGoal>? pgFocus,
  })  : unlocked = unlocked ?? [...initiallyUnlocked],
        best = best ?? {},
        starsBy = starsBy ?? {},
        quran = quran ?? {},
        learn = learn ?? {},
        skills = skills ?? {},
        achievements = achievements ?? [],
        settings = settings ?? Settings(),
        madd = madd ?? MaddStats(),
        pgFocus = pgFocus ?? {};

  static const schemaVersion = 1;

  String name;
  int stars;
  int correct;
  int wrong;
  int games;
  int timeMs;
  int? lastActivity;
  String? lastStage;
  final List<String> unlocked;

  /// أحسن ميداليات لكل مرحلة (١–٣).
  final Map<String, int> best;

  /// النجوم مقيّدة على كل عالم عشان مجموع العوالم يساوي الإجمالي.
  final Map<String, int> starsBy;

  /// "سورة:نشاط" -> نجوم.
  final Map<String, int> quran;

  /// لوحة الحروف: الحروف اللي الطفل فتحها.
  final Map<String, List<String>> learn;

  /// "مرحلة|مهارة" -> عدد الأخطاء (التعلّم المتكيّف).
  final Map<String, int> skills;
  final List<String> achievements;
  final Settings settings;

  /// إحصائيات قسم المدود (progress.madd في الويب).
  final MaddStats madd;

  /// أهداف دليل ولي الأمر (progress.parentGuide.focus في الويب).
  final Map<String, PgGoal> pgFocus;

  // ---------------------------------------------------------------- JSON

  factory ProgressData.fromJson(Map<String, dynamic> j) {
    Map<String, int> ints(Object? o) =>
        o is Map ? {for (final e in o.entries) '${e.key}': (e.value as num).toInt()} : {};
    List<String> strs(Object? o) => o is List ? [for (final v in o) '$v'] : [];
    return ProgressData(
      name: j['name'] as String? ?? '',
      stars: (j['stars'] as num?)?.toInt() ?? 0,
      correct: (j['correct'] as num?)?.toInt() ?? 0,
      wrong: (j['wrong'] as num?)?.toInt() ?? 0,
      games: (j['games'] as num?)?.toInt() ?? 0,
      timeMs: (j['timeMs'] as num?)?.toInt() ?? 0,
      lastActivity: (j['lastActivity'] as num?)?.toInt(),
      lastStage: j['lastStage'] as String?,
      unlocked: j['unlocked'] == null ? null : strs(j['unlocked']),
      best: ints(j['best']),
      starsBy: ints(j['starsBy']),
      quran: ints(j['quran']),
      learn: j['learn'] is Map
          ? {for (final e in (j['learn'] as Map).entries) '${e.key}': strs(e.value)}
          : {},
      skills: ints(j['skills']),
      achievements: strs(j['achievements']),
      settings: j['settings'] is Map ? Settings.fromJson((j['settings'] as Map).cast<String, dynamic>()) : null,
      madd: MaddStats.fromJson(j['madd']),
      pgFocus: (j['parentGuide'] is Map && (j['parentGuide'] as Map)['focus'] is Map)
          ? {
              for (final e in ((j['parentGuide'] as Map)['focus'] as Map).entries)
                '${e.key}': PgGoal.fromJson(e.value),
            }
          : {},
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'stars': stars,
        'correct': correct,
        'wrong': wrong,
        'games': games,
        'timeMs': timeMs,
        'lastActivity': lastActivity,
        'lastStage': lastStage,
        'unlocked': unlocked,
        'best': best,
        'starsBy': starsBy,
        'quran': quran,
        'learn': learn,
        'skills': skills,
        'achievements': achievements,
        'settings': settings.toJson(),
        'madd': madd.toJson(),
        'parentGuide': {
          'focus': {for (final e in pgFocus.entries) e.key: e.value.toJson()},
        },
      };

  // ---------------------------------------------------------------- التقدّم

  int _now() => DateTime.now().millisecondsSinceEpoch;

  bool isUnlocked(String id) {
    if (settings.dev || unlocked.contains(id)) return true;
    // مرحلة ليها after بتتفتح أول ما المرحلة دي تتنجح (٨٠٪+) — بتشتغل للتقدّم القديم كمان
    final after = packs[id]?.after;
    return after != null && (best[after] ?? 0) >= 2;
  }

  /// يفتح المرحلة اللي بعد دي في نفس العالم — ويرجّعها لو اتفتحت جديد.
  Stage? unlockNext(String id) {
    final pack = packs[id];
    if (pack == null) return null;
    final order = worldStages[pack.world]!;
    final i = order.indexWhere((s) => s.id == id);
    if (i < 0 || i + 1 >= order.length) return null;
    final next = order[i + 1];
    if (unlocked.contains(next.id)) return null;
    unlocked.add(next.id);
    return next;
  }

  /// النجمة بتتسجّل فورًا مع كل إجابة صح عشان الطفل يشوفها بتزيد.
  void addStar(int n, [String? world]) {
    stars += n;
    if (world != null) starsBy[world] = (starsBy[world] ?? 0) + n;
    lastActivity = _now();
  }

  /// كل إجابة تتحسب لحظتها — لو الطفل ساب الجولة في النص، اللي عمله ما يضيعش.
  void addAnswer({required bool ok}) {
    ok ? correct++ : wrong++;
    lastActivity = _now();
  }

  void addResult(String id, int correctCount, int total) {
    games++;
    lastActivity = _now();
    final medals = correctCount == total ? 3 : (correctCount / total >= .8 ? 2 : 1);
    best[id] = math.max(best[id] ?? 0, medals);
    lastStage = id;
  }

  /// مستوى الطفل = أعلى مستوى وصلت إليه المراحل المفتوحة، أو ٤ لو خلّص كل المراحل.
  int level([String? world]) {
    final ids = world != null ? (worldStages[world] ?? const <Stage>[]) : packs.values.toList();
    var lv = 1;
    for (final s in ids) {
      if (isUnlocked(s.id)) lv = math.max(lv, s.base);
    }
    return ids.isNotEmpty && ids.every((s) => (best[s.id] ?? 0) > 0) ? 4 : lv;
  }

  /// نسبة إنجاز عالم (٠–١٠٠) — للخريطة ولوحة ولي الأمر.
  int worldPct(String world) {
    if (world == 'quran') return quranPct;
    final ids = worldStages[world] ?? const <Stage>[];
    if (ids.isEmpty) return 0;
    final got = ids.fold<int>(0, (s, st) => s + math.min(best[st.id] ?? 0, 3));
    return (got / (ids.length * 3) * 100).round();
  }

  int starsIn(String world) => starsBy[world] ?? 0;

  void addTime(int ms) {
    timeMs += ms;
    lastActivity = _now();
  }

  /// لوحة الحروف — يرجّع true لو الحرف ده جديد.
  bool markLearned(String packId, String letter) {
    final seen = learn.putIfAbsent(packId, () => []);
    if (seen.contains(letter)) return false;
    seen.add(letter);
    return true;
  }

  List<String> learned(String packId) => learn[packId] ?? const [];

  // ---------------------------------------------------------------- القرآن

  static const quranModes = ['listen', 'repeat', 'memorize', 'review'];
  static const quranSurahCount = 37; // جزء عمّ: ٧٨–١١٤

  bool quranDone(int surah, String mode) => (quran['$surah:$mode'] ?? 0) > 0;

  /// النشاط بيدّي نجومه مرة واحدة — إعادته مابتزوّدش العدّاد تاني.
  void quranMark(int surah, String mode, int starsWanted) {
    final k = '$surah:$mode';
    final have = quran[k] ?? 0;
    if (starsWanted <= have) return;
    quran[k] = starsWanted;
    addStar(starsWanted - have, 'quran');
  }

  int surahStars(int surah) => quranModes.where((m) => quranDone(surah, m)).length;

  /// نسبة حقيقية: الأنشطة المكتملة من ٣٧ × ٤ (الويب كان بيستخدم النجوم × ٤).
  int get quranPct => (quran.values.where((v) => v > 0).length / (quranSurahCount * 4) * 100).round();

  /// سور فيها حفظ من غير مراجعة.
  List<int> get surahsNeedingReview {
    final out = <int>{};
    for (final k in quran.keys) {
      final s = int.parse(k.split(':').first);
      if (quranDone(s, 'memorize') && !quranDone(s, 'review')) out.add(s);
    }
    return out.toList()..sort();
  }

  // ---------------------------------------------------------------- التعلّم المتكيّف

  static String _skillKey(String pack, String skill) => '$pack|$skill';

  void miss(String pack, String? skill) {
    if (skill == null) return;
    final k = _skillKey(pack, skill);
    skills[k] = math.min((skills[k] ?? 0) + 1, 6);
  }

  void hit(String pack, String? skill) {
    if (skill == null) return;
    final k = _skillKey(pack, skill);
    final v = skills[k];
    if (v == null) return;
    if (v - 1 <= 0) {
      skills.remove(k);
    } else {
      skills[k] = v - 1;
    }
  }

  /// أضعف مهارة في المرحلة دي (لو الطفل غلط فيها مرتين أو أكتر) — الجزء اللي بعد أول ":".
  String? focus(String pack) {
    final mine = skills.entries.where((e) => e.key.startsWith('$pack|') && e.value >= 2).toList()
      ..sort((a, b) => b.value - a.value);
    if (mine.isEmpty) return null;
    final skill = mine.first.key.split('|')[1];
    final i = skill.indexOf(':');
    final f = i < 0 ? '' : skill.substring(i + 1);
    return f.isEmpty ? null : f;
  }

  /// أكتر المهارات اللي محتاجة تدريب — للوحة ولي الأمر.
  List<({String pack, String skill, int misses})> weakest([int n = 5]) {
    final list = skills.entries.where((e) => e.value >= 2).toList()..sort((a, b) => b.value - a.value);
    return [
      for (final e in list.take(n))
        (pack: e.key.split('|')[0], skill: e.key.split('|')[1], misses: e.value),
    ];
  }
}
