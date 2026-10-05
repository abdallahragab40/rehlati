/// أنواع بيانات دليل ولي الأمر ❤️ — المحتوى في parent_guide_data.g.dart (من data/parent-*.js في الويب).
///
/// اللغة محايدة: "قد يحدث بسبب" — مفيش تشخيص ومفيش لوم على الطفل.
library;

export 'parent_guide_data.g.dart';

class PgStep {
  const PgStep(this.t, {this.say});
  final String t;

  /// جملة تقولها للطفل في الخطوة دي.
  final String? say;
}

class PgGame {
  const PgGame(this.q, this.opts, this.ok);

  /// الموقف — {name} بتتبدّل باسم الطفل.
  final String q;

  /// الاختيارات: (النص، صح ولا لأ).
  final List<(String, bool)> opts;
  final String ok;
}

class PgBehavior {
  const PgBehavior({
    required this.id,
    required this.icon,
    required this.title,
    required this.cat,
    this.alt,
    required this.tags,
    required this.what,
    required this.why,
    required this.steps,
    required this.phrases,
    required this.avoid,
    required this.teach,
    required this.calm,
    this.calmSay,
    this.help,
    this.game,
  });

  final String id, icon, title, cat;

  /// اسم أقصر للبحث والنتايج.
  final String? alt;
  final List<String> tags;
  final String what;
  final List<String> why;
  final List<PgStep> steps;
  final List<String> phrases;
  final List<String> avoid;

  /// (بدل ❌، علّمه ✅)
  final List<(String, String)> teach;
  final List<String> calm;
  final String? calmSay;
  final String? help;
  final PgGame? game;

  String get label => alt ?? title;
}

class PgCategory {
  const PgCategory(this.id, this.icon, this.name);
  final String id, icon, name;
}
