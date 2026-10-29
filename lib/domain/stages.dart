/// سجل المراحل المركزي — منقول من js/worlds.js.
///
/// أي عالم جديد = بيانات + مولّدات + قائمة مراحل هنا. المحرك والواجهة والنجوم مشتركين.
library;

import 'dart:ui' show Color;

import '../content/language_data.dart';
import '../content/math_data.dart';
import '../core/features.dart';
import '../core/utils/rng.dart';
import 'generators/arabic_generators.dart';
import 'generators/english_generators.dart';
import 'generators/games_generators.dart';
import 'generators/harakat_generators.dart';
import 'generators/madd_generators.dart';
import 'generators/math100_generators.dart';
import 'generators/math_generators.dart';
import 'progress/progress_data.dart';
import 'question.dart';

typedef Generator = Question Function(int lv, Rng r, {String? focus});

class WorldMeta {
  const WorldMeta({
    required this.id,
    required this.icon,
    required this.name,
    required this.color,
    required this.tone,
    required this.title,
    required this.desc,
  });
  final String id;
  final String icon;
  final String name;
  final Color color;
  final Color tone;
  final String title;
  final String desc;
}

/// ترتيب العوالم في رحلة الصفحة الرئيسية.
const worlds = [
  WorldMeta(id: 'quran', icon: '📖', name: 'القرآن الكريم', color: Color(0xFF2FC9B4), tone: Color(0xFF1C8E7F),
      title: '📖 عالم القرآن', desc: 'استماع وترديد وحفظ ومراجعة'),
  WorldMeta(id: 'math', icon: '🧮', name: 'الحساب', color: Color(0xFF7A5CFF), tone: Color(0xFF5B3FD6),
      title: '🔢 عالم الحساب', desc: 'الأرقام والجمع والطرح'),
  WorldMeta(id: 'arabic', icon: '🔤', name: 'العربي', color: Color(0xFFFF9F1C), tone: Color(0xFFCC7A00),
      title: '🔤 عالم العربي', desc: 'الحروف والمدود والكلمات والقراءة'),
  WorldMeta(id: 'english', icon: '🇬🇧', name: 'English', color: Color(0xFF4CB8FF), tone: Color(0xFF1E86CC),
      title: '🇬🇧 English World', desc: 'Letters, words and sounds'),
  WorldMeta(id: 'games', icon: '🎮', name: 'ألعاب', color: Color(0xFFFF6B6B), tone: Color(0xFFD23F3F),
      title: '🎮 عالم الألعاب', desc: 'بالونات وذاكرة وسباق وتلوين'),
];

WorldMeta worldMeta(String id) => worlds.firstWhere((w) => w.id == id);

class Stage {
  const Stage({
    required this.id,
    required this.world,
    required this.n,
    required this.icon,
    required this.name,
    required this.base,
    required this.color,
    this.gen,
    this.learnItems,
    this.lang = 'ar',
    this.after,
    this.group,
    this.groupName,
    this.madd,
    this.count,
  });

  final String id;
  final String world;

  /// رقم المرحلة داخل العالم (١…).
  final int n;
  final String icon;
  final String name;

  /// أقل مستوى للمرحلة.
  final int base;
  final Color color;
  final Generator? gen;

  /// مراحل لوحة الحروف (تعلّم) مالهاش مولّد.
  final List<Letter>? learnItems;
  final String lang;

  /// المرحلة دي بتتفتح كمان لما المرحلة [after] تتنجح (٨٠٪+).
  final String? after;

  /// مجموعة مراحل جوه العالم (زي المدود) بعنوان بيظهر مرة على الخريطة.
  final String? group;
  final String? groupName;

  /// إعدادات المدود — المرحلة دي بتفتح على شاشة درس قبل اللعب.
  final MaddStage? madd;

  /// عدد أسئلة الجولة لو مختلف عن الافتراضي (الجدول الفاضي = ٣).
  final int? count;

  bool get isLearn => learnItems != null;
  bool get isMadd => madd != null;
  bool get isEnglish => lang == 'en';
}

class _Def {
  const _Def(this.id, this.icon, this.name, this.base, this.color,
      {this.gen, this.learn, this.lang = 'ar', this.count});
  final String id, icon, name;
  final int base;
  final int color;
  final Generator? gen;
  final List<Letter>? learn;
  final String lang;
  final int? count;
}

List<Stage> _register(String world, List<_Def> defs) => [
      for (var i = 0; i < defs.length; i++)
        Stage(
          id: defs[i].id, world: world, n: i + 1, icon: defs[i].icon, name: defs[i].name,
          base: defs[i].base, color: Color(defs[i].color), gen: defs[i].gen,
          learnItems: defs[i].learn, lang: defs[i].lang, count: defs[i].count,
        ),
    ];

final _math = _register('math', [
  _Def('counting', '🔢', 'العد', 1, palette[0], gen: counting),
  _Def('chooseNumber', '🎯', 'اختر الرقم', 1, palette[1], gen: chooseNumber),
  _Def('nextNumber', '➡️', 'العدد التالي', 1, palette[2], gen: nextNumber),
  _Def('previousNumber', '⬅️', 'العدد السابق', 1, palette[3], gen: previousNumber),
  _Def('neighbors', '↔️', 'السابق والتالي', 2, palette[4], gen: neighbors),
  _Def('sequence', '🔗', 'أكمل التسلسل', 2, palette[5], gen: sequence),
  _Def('completeTable', '🧮', 'أكمل الجدول', 2, palette[6], gen: completeTable),
  _Def('emptyTable', '🗒️', 'الجدول الفاضي', 2, palette[7], gen: emptyTable, count: 3),
  _Def('ascending', '📈', 'ترتيب تصاعدي', 2, palette[8], gen: ascending),
  _Def('descending', '📉', 'ترتيب تنازلي', 3, palette[9], gen: descending),
  _Def('comparison', '⚖️', 'أكبر وأصغر', 2, palette[10], gen: comparison),
  _Def('addition', '➕', 'الجمع', 3, palette[11], gen: addition),
  _Def('subtraction', '➖', 'الطرح', 3, palette[12], gen: subtraction),
]);

final _arabic = _register('arabic', [
  const _Def('ar_learn', '🔤', 'تعرّف على الحروف', 1, 0xFFFF9F1C, learn: arLetters),
  const _Def('ar_pick', '🎯', 'اختر الحرف', 1, 0xFFFFB443, gen: arPick),
  const _Def('ar_match', '🖼️', 'الحرف والصورة', 1, 0xFFFF8A5C, gen: arMatch),
  const _Def('ar_table', '🔡', 'أكمل جدول الحروف', 2, 0xFFFF9A4D, gen: arTable),
  const _Def('ar_build', '🧩', 'كوّن الكلمة', 2, 0xFFE8745C, gen: arBuild),
  const _Def('ar_compose', '➕', 'الحروف والكلمة', 2, 0xFFE8825C, gen: arCompose),
  const _Def('ar_analyze', '🔍', 'حلّل الكلمة', 3, 0xFFDB6F3E, gen: arAnalyze),
  const _Def('ar_connect', '🪢', 'وصّل الكلمة بحروفها', 3, 0xFFD4652F, gen: arConnect),
  const _Def('ar_complete', '✏️', 'أكمل الكلمة', 2, 0xFFD98324, gen: arComplete),
  const _Def('ar_choose_word', '📖', 'اختر الكلمة', 3, 0xFFC96A1F, gen: arChooseWord),
  const _Def('ar_match_word', '🔗', 'الكلمة والصورة', 3, 0xFFB8571A, gen: arMatchWord),
]);

final _english = _register('english', [
  const _Def('en_learn', '🔤', 'Learn letters', 1, 0xFF4CB8FF, learn: enLetters, lang: 'en'),
  const _Def('en_pick', '🎯', 'Choose letter', 1, 0xFF5FA8F5, gen: enPick, lang: 'en'),
  const _Def('en_match', '🖼️', 'Letter & picture', 1, 0xFF6C8FF0, gen: enMatch, lang: 'en'),
  const _Def('en_case', '🔠', 'Big & small', 1, 0xFF66A6F2, gen: enCase, lang: 'en'),
  const _Def('en_circle', '⭕', 'Circle the letter', 1, 0xFF5FA0EF, gen: enCircle, lang: 'en'),
  const _Def('en_pairs', '🔗', 'Match big & small', 2, 0xFF6E96EE, gen: enPairs, lang: 'en'),
  const _Def('en_friends', '🤝', 'Find the friends', 2, 0xFF6B90F0, gen: enFriends, lang: 'en'),
  const _Def('en_table', '🔤', 'Complete alphabet', 2, 0xFF7389EA, gen: enTable, lang: 'en'),
  const _Def('en_complete', '✏️', 'Complete word', 2, 0xFF7A7CE8, gen: enComplete, lang: 'en'),
  const _Def('en_word', '📖', 'Choose word', 2, 0xFF4C9BE0, gen: enWord, lang: 'en'),
  _Def('en_numbers', '🔢', 'Numbers', 2, 0xFF3F8FD6, gen: enNumbersGame, lang: 'en'),
  _Def('en_colors', '🎨', 'Colors', 2, 0xFF3583CC, gen: enColorsGame, lang: 'en'),
  _Def('en_animals', '🐘', 'Animals', 3, 0xFF2B77BF, gen: enAnimalsGame, lang: 'en'),
  _Def('en_daily', '💬', 'Everyday words', 3, 0xFF216BB2, gen: enDailyGame, lang: 'en'),
]);

/// عالم الألعاب — كله مفتوح من الأول (ألعاب مش مناهج). "اسمع واختار" محتاجة صوت.
final _games = _register('games', [
  const _Def('balloons', '🎈', 'فرقع البالونة', 1, 0xFFFF6B6B, gen: balloons),
  const _Def('memoryNum', '🧠', 'الرقم وصاحبه', 1, 0xFF7A4FD1, gen: memoryNum),
  if (voiceEnabled) const _Def('listenNum', '👂', 'اسمع واختار', 1, 0xFF4C9BFF, gen: listenNum),
  const _Def('race', '🏁', 'سباق الأرقام', 2, 0xFF36B37E, gen: race),
  const _Def('puzzle', '🧩', 'بازل الصورة', 2, 0xFFE89B2B, gen: puzzle, count: 4),
  const _Def('colorNum', '🎨', 'لوّن بالأرقام', 1, 0xFFE05FA8, gen: colorNum, count: 1),
  const _Def('pattern', '🔁', 'اتبع النمط', 1, 0xFF1FAE9B, gen: pattern),
  const _Def('letterHunt', '🔤', 'صيد الحروف', 1, 0xFFFF9F1C, gen: letterHunt),
  const _Def('rhythm', '🥁', 'كرر الإيقاع', 1, 0xFFC06BE8, gen: rhythm),
  const _Def('shapes', '🔺', 'الأشكال والألوان', 1, 0xFF4CB8FF, gen: shapes),
  const _Def('sizeOrder', '📏', 'رتّب بالحجم', 1, 0xFF5FBF5F, gen: sizeOrder),
  const _Def('clock', '🕐', 'كام الساعة', 3, 0xFF7A5CFF, gen: clock),
]);

/// المدود بتتضاف في آخر عالم العربي من غير ما نلمس مراحله الأصلية (appendStages في الويب).
/// أول مرحلة بس بتتفتح بعد "أكمل جدول الحروف"؛ الباقي بالترتيب.
final _madd = [
  for (final (i, (id, icon, name, base, color, cfg)) in maddStageDefs.indexed)
    Stage(
      id: id, world: 'arabic', n: _arabic.length + i + 1, icon: icon, name: name, base: base,
      color: Color(color), madd: cfg, group: maddGroup, groupName: maddGroupName,
      after: i == 0 ? 'ar_table' : null,
    ),
];

/// الحركات (أولى ابتدائي) بعد المدود في آخر عالم العربي. أول مرحلة بتتفتح كمان بعد
/// "أكمل جدول الحروف" زي المدود. "اسمع واختار المقطع" محتاجة الصوت.
final _harakat = [
  for (final (i, (id, icon, name, base, color, gen)) in <(String, String, String, int, int, Generator)>[
    ('ar_haraka', '✍️', 'اسم الحركة', 1, 0xFFE0662E, arHaraka),
    ('ar_haraka_pick', '🔎', 'الحرف وحركته', 1, 0xFFD45A26, arHarakaPick),
    if (voiceEnabled) ('ar_syllable', '👂', 'اسمع واختار المقطع', 2, 0xFFC84E1E, arSyllable),
  ].indexed)
    Stage(
      id: id, world: 'arabic', n: _arabic.length + _madd.length + i + 1, icon: icon, name: name, base: base,
      color: Color(color), gen: gen, group: 'harakat', groupName: 'الحركات',
      after: i == 0 ? 'ar_table' : null,
    ),
];

/// الأعداد لحد ١٠٠ (أولى وتانية ابتدائي) في آخر عالم الحساب من غير ما نلمس مراحله الأصلية.
/// أول مرحلة بتتفتح كمان بعد "الجمع"، والباقي بالترتيب.
final _math100 = [
  for (final (i, (id, icon, name, base, color, gen)) in <(String, String, String, int, int, Generator)>[
    ('tensOnes', '🧱', 'الآحاد والعشرات', 1, 0xFF6A4CE0, tensOnes),
    ('skipCount', '🦘', 'العد بالقفز', 1, 0xFF5E44D0, skipCount),
    ('compare100', '🐊', 'المقارنة لحد ١٠٠', 2, 0xFF533CC0, compare100),
    ('add100', '➕', 'الجمع لحد ١٠٠', 2, 0xFF4834B0, add100),
    ('sub100', '➖', 'الطرح لحد ١٠٠', 2, 0xFF3D2CA0, sub100),
  ].indexed)
    Stage(
      id: id, world: 'math', n: _math.length + i + 1, icon: icon, name: name, base: base,
      color: Color(color), gen: gen, group: 'math100', groupName: 'الأعداد لحد ١٠٠',
      after: i == 0 ? 'addition' : null,
    ),
];

/// world -> ترتيب مراحله.
final Map<String, List<Stage>> worldStages = {
  'math': [..._math, ..._math100],
  'arabic': [..._arabic, ..._madd, ..._harakat],
  'english': _english,
  'games': _games,
};

/// id -> المرحلة.
final Map<String, Stage> packs = {
  for (final list in worldStages.values)
    for (final s in list) s.id: s,
};

/// العوالم اللي ليها مستوى لكل مادة في لوحة ولي الأمر — الألعاب مش مادة.
const subjectWorlds = ['math', 'arabic', 'english'];

/// المراحل المفتوحة من الأول.
const initiallyUnlocked = ['counting', 'ar_learn', 'en_learn'];

/// السؤال الجاي لأي نوع: id مرحلة ("counting"، "madd_alif") أو نوع لعبة مدود ("madd_alif:letter").
/// "تدريب على الأخطاء" بيستخدم النوع الكامل عشان يرجّع نفس قيود المرحلة.
Question makeQuestion(String type, int lv, Rng r, {String? focus, required ProgressData progress}) {
  final i = type.indexOf(':');
  final stage = packs[i < 0 ? type : type.substring(0, i)]!;
  final cfg = stage.madd;
  if (cfg == null) return stage.gen!(lv, r, focus: focus);
  // من غير صوت مفيش "اسمع ثم اختر" — بنختار نوع تاني من نفس المرحلة
  final kinds = voiceEnabled ? cfg.kinds : cfg.kinds.where((k) => k != 'listen').toList();
  var kind = i < 0 ? r.sample(kinds) : type.substring(i + 1);
  if (!kinds.contains(kind)) kind = r.sample(kinds);
  return maddQuestion(stage.id, kind, cfg, lv, r, focus, progress.madd);
}
