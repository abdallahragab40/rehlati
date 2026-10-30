/// سجل المراحل المركزي — منقول من js/worlds.js.
///
/// أي عالم جديد = بيانات + مولّدات + قائمة مراحل هنا. المحرك والواجهة والنجوم مشتركين.
library;

import 'dart:math' as math;
import 'dart:ui' show Color;

import '../content/language_data.dart';
import '../content/math_data.dart';
import '../core/features.dart';
import '../core/utils/rng.dart';
import 'generators/arabic_generators.dart';
import 'generators/basics_generators.dart';
import 'generators/deen_generators.dart';
import 'generators/english_more_generators.dart';
import 'generators/fade_generators.dart';
import 'generators/grade2_arabic_generators.dart';
import 'generators/school_english_generators.dart';
import 'generators/school_math_generators.dart';
import 'generators/term2_arabic_generators.dart';
import 'generators/en_primary_generators.dart';
import 'generators/english_generators.dart';
import 'generators/games_generators.dart';
import 'generators/grammar_generators.dart';
import 'generators/harakat_generators.dart';
import 'generators/life_generators.dart';
import 'generators/madd_generators.dart';
import 'generators/math100_generators.dart';
import 'generators/math_generators.dart';
import 'generators/sukun_generators.dart';
import 'generators/upper_primary_generators.dart';
import 'generators/mul_generators.dart';
import 'generators/reading_generators.dart';
import 'placement.dart';
import 'generators/play_generators.dart';
import 'generators/puzzle_generators.dart';
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
  WorldMeta(id: 'deen', icon: '🕌', name: 'الدين والأخلاق', color: Color(0xFF3BAF7A), tone: Color(0xFF23855A),
      title: '🕌 عالم الدين والأخلاق', desc: 'الأذكار والوضوء والصلاة وقصص الأنبياء'),
  WorldMeta(id: 'math', icon: '🧮', name: 'الحساب', color: Color(0xFF7A5CFF), tone: Color(0xFF5B3FD6),
      title: '🔢 عالم الحساب', desc: 'الأرقام والجمع والطرح'),
  WorldMeta(id: 'arabic', icon: '🔤', name: 'العربي', color: Color(0xFFFF9F1C), tone: Color(0xFFCC7A00),
      title: '🔤 عالم العربي', desc: 'الحروف والمدود والكلمات والقراءة'),
  WorldMeta(id: 'english', icon: '🇬🇧', name: 'English', color: Color(0xFF4CB8FF), tone: Color(0xFF1E86CC),
      title: '🇬🇧 English World', desc: 'Letters, words and sounds'),
  WorldMeta(id: 'write', icon: '✍️', name: 'الكتابة', color: Color(0xFF8A6CFF), tone: Color(0xFF6448D9),
      title: '✍️ عالم الكتابة', desc: 'ارسم الأرقام والحروف والكلمات بصباعك'),
  WorldMeta(id: 'discover', icon: '🌍', name: 'اكتشف', color: Color(0xFF36A3D9), tone: Color(0xFF1F7FB0),
      title: '🌍 عالم اكتشف', desc: 'الحيوانات والفصول والنبات والحواس'),
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
    this.fromGrade,
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

  /// أول مرحلة في مجموعة الابتدائي بتتفتح من الأول لطفل في الصف ده أو أعلى ([schoolGrades]).
  final String? fromGrade;

  /// السن المناسب للعبة (عالم الألعاب بس) — الخريطة والرحلة بيقدّموا المناسب لسن الطفل.
  (int, int)? get ages => gameAges[id];

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

/// ألعاب التفكير والآداب والحركة في آخر عالم الألعاب، كل نوع بعنوان على الخريطة.
/// مفتوحة كلها زي باقي الألعاب. «مين بيقول كده؟» محتاجة الصوت.
final _play = [
  for (final (i, (id, icon, name, color, gen, group, count)) in <(String, String, String, int, Generator, String, int?)>[
    ('oddOne', '🤔', 'مين الغريب؟', 0xFF7A4FD1, oddOne, 'think', null),
    ('shadow', '👤', 'ظل الصورة', 0xFF4A5568, shadow, 'think', null),
    if (voiceEnabled) ('animalSound', '🐮', 'مين بيقول كده؟', 0xFF36B37E, animalSound, 'think', null),
    ('opposite', '🔄', 'الأضداد', 0xFFE05FA8, opposite, 'think', null),
    ('storyOrder', '📚', 'رتّب الحكاية', 0xFFE89B2B, storyOrder, 'think', 6),
    ('category', '🗂️', 'صنّف', 0xFF1FAE9B, category, 'think', null),
    ('missingPic', '🖼️', 'الصورة الناقصة', 0xFF4C9BFF, missingPic, 'think', null),
    ('cups', '🐱', 'فين القطة؟', 0xFFFF7A45, cups, 'think', 5),
    ('cleanSteps', '🧼', 'غسل الإيدين والوضوء', 0xFF2FA3C9, cleanSteps, 'values', 5),
    ('manner', '✅', 'ده يصح ولا لأ؟', 0xFF36B37E, manner, 'values', null),
    ('dragSort', '🧺', 'ودّي الحاجة مكانها', 0xFFC0782B, dragSort, 'move', 4),
    ('maze', '🐰', 'متاهة الأرنب', 0xFF5FBF5F, maze, 'move', 4),
    ('lights', '🚦', 'كرر الألوان', 0xFFC06BE8, lights, 'move', null),
    ('sudoku', '🔢', 'سودوكو', 0xFF5B3FD6, sudoku, 'puzzle', 3),
    ('hanoi', '🗼', 'برج هانوي', 0xFFD2693C, hanoi, 'puzzle', 3),
    ('slide', '🔲', 'البازل المنزلق', 0xFF2B8A9E, slide, 'puzzle', 3),
    ('numberSeq', '➡️', 'كمّل المتتالية', 0xFF3F8FD6, numberSeq, 'puzzle', 8),
  ].indexed)
    Stage(
      id: id, world: 'games', n: _games.length + i + 1, icon: icon, name: name, base: 1, color: Color(color),
      gen: gen, count: count, group: group, groupName: playGroups[group],
    ),
];

/// السن المناسب لكل مرحلة في العوالم المفتوحة (من، لحد). المرحلة بتفضل مفتوحة لأي سن —
/// ده ترتيب وعرض بس.
const gameAges = <String, (int, int)>{
  'balloons': (3, 8),
  'memoryNum': (4, 9),
  'listenNum': (3, 6),
  'race': (5, 9),
  'puzzle': (5, 9),
  'colorNum': (4, 9),
  'pattern': (3, 8),
  'letterHunt': (4, 7),
  'rhythm': (3, 12),
  'shapes': (3, 6),
  'sizeOrder': (3, 6),
  'clock': (6, 10),
  'oddOne': (3, 7),
  'shadow': (3, 6),
  'animalSound': (3, 5),
  'opposite': (3, 6),
  'storyOrder': (4, 8),
  'category': (3, 6),
  'missingPic': (4, 8),
  'cups': (3, 12),
  'cleanSteps': (4, 9),
  'manner': (3, 8),
  'dragSort': (3, 7),
  'maze': (4, 12),
  'lights': (4, 12),
  'traceNum': (3, 6),
  'traceAr': (4, 7),
  'traceForms': (5, 8),
  'traceWord': (6, 9),
  'traceEn': (5, 8),
  'deen_dua': (3, 12),
  'deen_repeat': (3, 10),
  'deen_wudu': (5, 12),
  'deen_salah': (6, 12),
  'deen_pillars': (5, 12),
  'deen_prophets': (5, 12),
  'deen_morals': (4, 10),
  'deen_calendar': (6, 12),
  'disc_habitat': (3, 8),
  'disc_seasons': (4, 9),
  'disc_plant': (5, 10),
  'disc_senses': (3, 8),
  'disc_health': (3, 9),
  'sudoku': (6, 12),
  'hanoi': (7, 12),
  'slide': (7, 12),
  'numberSeq': (8, 12),
};

/// العوالم اللي كل مراحلها مفتوحة من الأول — ألعاب ونشاطات مش منهج بالترتيب.
const openWorlds = {'games', 'deen', 'discover', 'write'};

/// اللعبة مناسبة لسن الطفل؟ من غير سن (أو مرحلة مش لعبة) = أيوه.
bool fitsAge(Stage s, int? age) {
  final a = s.ages;
  return age == null || a == null || (age >= a.$1 && age <= a.$2);
}

const playGroups = {
  'think': '🧠 ألعاب الذكاء',
  'values': '🌟 آداب ونضافة',
  'move': '🏃 العب وحرّك',
  'puzzle': '🧩 ألغاز وتحديات',
};

/// مجموعة مراحل جديدة: أول مرحلة ممكن تتفتح بعد [after] أو من صف [fromGrade]، والباقي بالترتيب.
/// رقم المرحلة ([Stage.n]) بيتظبط لما العالم يتجمّع ([_numbered]).
List<Stage> _grp(
  String world,
  String group,
  String groupName,
  int color,
  List<(String, String, String, int, Generator)> defs, {
  String? after,
  String? fromGrade,
  String lang = 'ar',
  Map<String, int> counts = const {},
}) =>
    [
      for (final (i, (id, icon, name, base, gen)) in defs.indexed)
        Stage(
          id: id, world: world, n: i + 1, icon: icon, name: name, base: base, color: Color(color), gen: gen,
          lang: lang, group: group, groupName: groupName, count: counts[id],
          after: i == 0 ? after : null, fromGrade: i == 0 ? fromGrade : null,
        ),
    ];

/// أشكال الحرف في أول الكلمة ووسطها وآخرها — بعد الحركات وقبل المدود.
final _forms = _grp('arabic', 'forms', 'شكل الحرف في الكلمة', 0xFFE8825C, [
  ('ar_forms', '🔠', 'أشكال الحرف', 1, arForms),
  ('ar_position', '📍', 'الحرف فين في الكلمة؟', 1, arPosition),
], after: 'ar_table', fromGrade: 'p1');

/// الشمسية والقمرية بعد السكون والتنوين والشدّة.
final _al = _grp('arabic', 'al', 'الشمسية والقمرية', 0xFFD9822B, [
  ('ar_al', '☀️', 'اللام الشمسية والقمرية', 2, arAl),
], after: 'ar_sukun', fromGrade: 'p1');

/// من التشكيل للقراءة العادية بعد السكون والتنوين: نفس الكلمات بتشكيل كامل، وبعدين أقل، وبعدين من غيره.
/// بتتفتح بعد "فين الحرف الساكن؟" بس (مش من الصف) — التدرّج محتاج الطفل يعرف السكون والتنوين الأول.
final _fade = _grp('arabic', 'fade', 'من التشكيل للقراءة العادية', 0xFFB5651D, [
  ('ar_fade_full', '🔤', 'اقرأ الكلمة المشكولة', 2, fadeGen('ar_fade_full', 0)),
  ('ar_fade_less', '🌗', 'تشكيل أقل', 2, fadeGen('ar_fade_less', 1)),
  ('ar_fade_none', '📖', 'اقرأ من غير تشكيل', 2, fadeGen('ar_fade_none', 2)),
], after: 'ar_sukun');

/// قواعد أولى وتانية ابتدائي من كتاب الوزارة (الترمين) — بتتفتح بعد الشمسية والقمرية.
/// مش بالصف: طفل تانية جديد يبدأ بالتنوين والسكون الأول، والدروس دي متاحة له من «دروس المدرسة».
final _ar2 = _grp('arabic', 'ar2', 'قواعد أولى وتانية ابتدائي', 0xFF9C4A8B, [
  ('ar_far', '🔭', 'ذلك وتلك', 2, arFar),
  ('ar_adverb', '⏰', 'ظرف الزمان والمكان', 2, arAdverb),
  ('ar_command', '📣', 'الأمر والنهي', 2, arCommand),
  ('ar_similar', '👂', 'الحروف المتشابهة في النطق', 2, arSimilar),
  ('ar_relative', '🔗', 'الأسماء الموصولة', 2, arRelative),
  // الترم التاني
  ('ar_pronoun', '🙋', 'الضمائر', 2, arPronoun),
  ('ar_tense', '⏳', 'الماضي والمضارع', 2, arTense),
  ('ar_taa', '🔚', 'التاء المربوطة والمفتوحة', 2, arTaa),
  ('ar_style', '❗', 'النداء والتعجب والاستفهام', 2, arStyle),
  ('ar_particles', '🔗', 'حروف الجر والعطف', 2, arParticles),
], after: 'ar_al');

/// قراءة جمل قصيرة بصورة وسؤال، بعد قراءة كلمات المدود.
final _shortRead = _grp('arabic', 'shortRead', 'أقرأ جمل قصيرة', 0xFFC96A1F, [
  ('ar_short_read', '📖', 'اقرأ الجملة', 2, arShortRead),
], after: 'madd_read', fromGrade: 'p1');

/// مفاهيم لغوية للصغيرين: هذا وهذه ومجموعات الكلمات.
final _concepts = _grp('arabic', 'concepts', 'كلمات ومعاني', 0xFFB8571A, [
  ('ar_this', '👉', 'هذا ولا هذه؟', 1, arThis),
  ('ar_groups', '🗂️', 'كلمات من نفس المجموعة', 1, arGroups),
], after: 'ar_match_word');

/// أساسيات الأعداد (KG2 وأولى ابتدائي) بعد مراحل الحساب الأصلية.
final _mathBasics = _grp('math', 'basics', 'أساسيات الأعداد', 0xFF8A6CFF, [
  ('ordinals', '🥇', 'الأول والتاني والتالت', 1, ordinals),
  ('zeroEvenOdd', '🧦', 'الصفر والزوجي والفردي', 1, zeroEvenOdd),
  ('geometry', '🔷', 'الأشكال الهندسية', 1, geometry),
  ('measure', '📏', 'تقيل وطويل وأكتر', 1, measure),
  ('calendar', '📅', 'الأيام والشهور والفصول', 1, calendar),
  ('numBonds', '🧩', 'تحليل العدد', 1, numBonds),
  ('coins', '🪙', 'الجنيه ونصه وربعه', 1, coins),
  ('picGraph', '📊', 'عدّ وقارن بالصور', 1, picGraph),
  ('wordProblem', '📝', 'مسائل بالصور', 2, wordProblem),
], after: 'chooseNumber');

/// حساب أولى ابتدائي (الترم الأول) من كتاب الوزارة — بعد «مسائل بالصور»، حتى للتقدّم القديم.
final _math1 = _grp('math', 'math1', 'حساب أولى ابتدائي', 0xFF7A5CFF, [
  ('position', '↔️', 'من اليمين ومن الشمال', 1, position),
  ('threeNumbers', '🧮', 'حساب ثلاثة أعداد', 2, threeNumbers),
], after: 'wordProblem');

/// حساب تانية ابتدائي (الترم الأول) من كتاب الوزارة — بعد الجمع لحد ١٠٠.
/// مش بالصف: طفل تانية جديد يبدأ بالآحاد والعشرات، والدروس دي متاحة له من «دروس المدرسة».
final _math2 = _grp('math', 'math2', 'حساب تانية ابتدائي', 0xFF5B6BE0, [
  ('hundreds', '💯', 'الأعداد لحد ١٠٠٠', 2, hundreds),
  ('rounding', '🎯', 'التقريب والتقدير', 2, rounding),
  ('barGraph', '📊', 'التمثيل بالأعمدة', 2, barGraph),
], after: 'add100');

/// Phonics بعد ما الطفل يعرف الحروف: الصوت مش الاسم، وبعدين تجميع كلمات CVC.
final _phonics = _grp('english', 'phonics', 'Phonics • Letter sounds', 0xFF2E9BD6, [
  ('en_phonics', '🔊', 'Letter sounds', 1, enPhonics),
  ('en_firstsound', '👂', 'First sound', 1, enFirstSound),
  ('en_blend', '🧩', 'Sound it out', 2, enBlend),
], after: 'en_pick', lang: 'en');

/// مفردات وجمل يومية.
final _enWords = _grp('english', 'enWords', 'Words & phrases', 0xFF3A8FD1, [
  ('en_shapes', '🔷', 'Shapes', 1, enShapesGame),
  ('en_body', '👂', 'My body', 1, enBodyGame),
  ('en_family', '👨‍👩‍👧', 'My family', 1, enFamilyGame),
  ('en_sight', '👀', 'Sight words', 2, enSight),
  ('en_phrases', '💬', 'What do you say?', 2, enPhrase),
], after: 'en_word', lang: 'en');

/// كلمات وجمل كتاب Connect (أولى الترم التاني وتانية) — بعد My family، حتى للتقدّم القديم.
final _enSchool = _grp('english', 'enSchool', 'Words from school • Grades 1–2', 0xFF2F7FC4, [
  ('en_prep', '📦', 'in, on, under', 1, enPrep),
  ('en_days', '📅', 'Days of the week', 1, enDaysGame),
  ('en_feelings', '😀', 'Feelings', 1, enFeelingsGame),
  ('en_weather', '☀️', 'Weather', 1, enWeatherGame),
  ('en_seasons', '🍂', 'Seasons', 1, enSeasonsGame),
  ('en_months', '🗓️', 'Months', 2, enMonthsGame),
  ('en_rooms', '🏠', 'Rooms at home', 1, enRoomsGame),
  ('en_places', '🏥', 'Places', 1, enPlacesGame),
  ('en_transport', '🚌', 'Transportation', 1, enTransportGame),
  ('en_clothes', '👕', 'Clothes', 1, enClothesGame),
  ('en_sports', '⚽', 'Sports', 1, enSportsGame),
  ('en_actions', '✍️', 'Classroom actions', 1, enActionsGame),
  ('en_pronouns', '🙋', 'I, he, she, it, they', 1, enPronouns),
  ('en_count100', '💯', 'Numbers to 100', 1, enCount100),
  ('en_sounds', '🔤', 'Blends and long vowels', 2, enSounds),
], after: 'en_family', lang: 'en');

/// 🕌 الدين والأخلاق — مفتوح كله.
final _deen = [
  ..._grp('deen', 'adhkar', '🤲 الأذكار', 0xFF3BAF7A, [
    ('deen_dua', '🤲', 'الذكر المناسب', 1, deenDua),
    ('deen_repeat', '🗣️', 'ردّد الذكر', 1, deenRepeat),
  ], counts: {'deen_repeat': 5}),
  ..._grp('deen', 'worship', '🕌 الوضوء والصلاة', 0xFF2FA3C9, [
    ('deen_wudu', '💧', 'خطوات الوضوء', 1, deenWudu),
    ('deen_salah', '🕌', 'خطوات الصلاة', 1, deenSalah),
    ('deen_pillars', '☪️', 'أركان الإسلام والإيمان', 1, deenPillars),
  ], counts: {'deen_wudu': 5, 'deen_salah': 5}),
  ..._grp('deen', 'stories', '📜 قصص وأخلاق', 0xFFE89B2B, [
    ('deen_prophets', '📜', 'قصص الأنبياء', 1, deenProphets),
    ('deen_morals', '💛', 'الصدق والأمانة', 1, deenMorals),
    ('deen_calendar', '🌙', 'الشهور الهجرية والأعياد', 1, deenCalendar),
  ]),
];

/// 🌍 اكتشف — مفتوح كله.
final _discover = _grp('discover', 'discover', '🌍 اكتشف الدنيا', 0xFF36A3D9, [
  ('disc_habitat', '🐾', 'الحيوان بيعيش فين؟', 1, discHabitat),
  ('disc_seasons', '🍂', 'الفصول الأربعة', 1, discSeasons),
  ('disc_plant', '🌱', 'أجزاء النبات', 1, discPlant),
  ('disc_senses', '👃', 'الحواس الخمس', 1, discSenses),
  ('disc_health', '🥦', 'أكل يقوّيني', 1, discHealth),
]);

/// ✍️ الكتابة — نفس لوحة الرسم للأرقام والحروف والكلمات. مفتوح كله.
final _write = [
  ..._grp('write', 'writeAr', '✍️ بالعربي', 0xFFFF9F1C, [
    ('traceNum', '✍️', 'ارسم الرقم', 1, traceNum),
    ('traceAr', '✍️', 'ارسم الحرف', 1, traceAr),
    ('traceForms', '🔠', 'الحرف في الكلمة', 1, traceForms),
    ('traceWord', '📝', 'اكتب كلمة', 1, traceWord),
  ], counts: {'traceNum': 4, 'traceAr': 4, 'traceForms': 4, 'traceWord': 3}),
  ..._grp('write', 'writeEn', '✍️ English', 0xFF4CB8FF, [
    ('traceEn', '✍️', 'Trace the letter', 1, traceEn),
  ], lang: 'en', counts: {'traceEn': 4}),
];

/// نفس المرحلة بترتيبها الجديد في العالم.
Stage _at(Stage s, int n) => Stage(
      id: s.id, world: s.world, n: n, icon: s.icon, name: s.name, base: s.base, color: s.color, gen: s.gen,
      learnItems: s.learnItems, lang: s.lang, after: s.after, group: s.group, groupName: s.groupName,
      madd: s.madd, count: s.count, fromGrade: s.fromGrade,
    );

List<Stage> _numbered(List<Stage> list) => [for (final (i, s) in list.indexed) _at(s, i + 1)];

/// المدود بتتضاف في آخر عالم العربي من غير ما نلمس مراحله الأصلية (appendStages في الويب).
/// أول مرحلة بس بتتفتح بعد "أكمل جدول الحروف"؛ الباقي بالترتيب.
final _madd = [
  for (final (i, (id, icon, name, base, color, cfg)) in maddStageDefs.indexed)
    Stage(
      id: id, world: 'arabic', n: _arabic.length + i + 1, icon: icon, name: name, base: base,
      color: Color(color), madd: cfg, group: maddGroup, groupName: maddGroupName,
      after: i == 0 ? 'ar_table' : null,
      fromGrade: i == 0 ? 'p1' : null,
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
      fromGrade: i == 0 ? 'p1' : null,
    ),
];

/// السكون والتنوين (أولى ابتدائي، الترم التاني) بعد الحركات. أول مرحلة بتتفتح بعد
/// "الحرف وحركته"، أو من تانية ابتدائي. "اسمع واختار التنوين" محتاجة الصوت.
final _sukun = [
  for (final (i, (id, icon, name, base, color, gen)) in <(String, String, String, int, int, Generator)>[
    ('ar_tanween', '✌️', 'التنوين', 1, 0xFFBC4A1A, arTanween),
    ('ar_marks', '🔍', 'حركة ولا تنوين؟', 2, 0xFFB04216, arMarks),
    ('ar_sukun', '🔵', 'فين الحرف الساكن؟', 2, 0xFFA43A12, arSukun),
    if (voiceEnabled) ('ar_tanween_listen', '👂', 'اسمع واختار التنوين', 2, 0xFF98320E, arTanweenListen),
    ('ar_shadda', 'بّ', 'الشدّة', 2, 0xFF8C2A0A, arShadda),
  ].indexed)
    Stage(
      id: id, world: 'arabic', n: _arabic.length + _madd.length + _harakat.length + i + 1, icon: icon, name: name,
      base: base, color: Color(color), gen: gen, group: 'sukun', groupName: 'السكون والتنوين والشدّة',
      after: i == 0 ? 'ar_haraka_pick' : null,
      fromGrade: i == 0 ? 'p2' : null,
    ),
];

/// القواعد والفهم لسن ٩–١٢ في آخر عالم العربي. أول مرحلة بتتفتح من رابعة ابتدائي،
/// أو بعد "فين الحرف الساكن؟"، والباقي بالترتيب.
final _grammar = [
  for (final (i, (id, icon, name, base, gen)) in <(String, String, String, int, Generator)>[
    ('ar_wordType', '🏷️', 'اسم ولا فعل ولا حرف؟', 2, arWordType),
    ('ar_number', '👥', 'مفرد ولا مثنى ولا جمع؟', 2, arNumber),
    ('ar_gender', '🚻', 'مذكر ولا مؤنث؟', 2, arGender),
    ('ar_opposite', '↔️', 'عكس الكلمة', 2, arOpposite),
    ('ar_sentence', '📝', 'كمّل الجملة', 2, arSentence),
    ('ar_reading', '📰', 'اقرأ وافهم', 2, arReading),
  ].indexed)
    Stage(
      id: id, world: 'arabic', n: _arabic.length + _madd.length + _harakat.length + _sukun.length + i + 1,
      icon: icon, name: name, base: base, color: const Color(0xFF8E3B6F), gen: gen,
      group: 'grammar', groupName: 'القواعد والفهم • ٩–١٢ سنة',
      after: i == 0 ? 'ar_sukun' : null, fromGrade: i == 0 ? 'p4' : null,
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
      fromGrade: i == 0 ? 'p2' : null,
    ),
];

/// جدول الضرب (تانية وتالتة ابتدائي) بعد الأعداد لحد ١٠٠. أول مرحلة بتتفتح كمان بعد
/// "العد بالقفز" — الجدول عد بالقفز أصلًا.
final _mul = [
  for (final (i, (id, icon, name, base, color, gen)) in <(String, String, String, int, int, Generator)>[
    ('mulGroups', '🧺', 'المجموعات المتساوية', 2, 0xFF2F9E8F, mulGroups),
    ('times2510', '✖️', 'جدول ٢ و ٥ و ١٠', 2, 0xFF28907F, times2510),
    ('times34', '✖️', 'جدول ٣ و ٤', 2, 0xFF22826F, times34),
    ('times6789', '✖️', 'جدول ٦ لـ ٩', 2, 0xFF1C745F, times6789),
    ('timesAll', '🏆', 'جدول الضرب كله', 3, 0xFF16664F, timesAll),
  ].indexed)
    Stage(
      id: id, world: 'math', n: _math.length + _math100.length + i + 1, icon: icon, name: name, base: base,
      color: Color(color), gen: gen, group: 'mul', groupName: 'جدول الضرب',
      after: i == 0 ? 'skipCount' : null,
      fromGrade: i == 0 ? 'p3' : null,
    ),
];

/// الفلوس والساعة (تانية وتالتة ابتدائي) بعد جدول الضرب. أول مرحلة بتتفتح كمان بعد
/// "الجمع لحد ١٠٠" — عدّ الفلوس جمع.
final _life = [
  for (final (i, (id, icon, name, base, color, gen)) in <(String, String, String, int, int, Generator)>[
    ('moneyCount', '💰', 'عدّ الفلوس', 2, 0xFFD08A1E, moneyCount),
    ('moneyChange', '🧾', 'الباقي كام؟', 2, 0xFFC27C14, moneyChange),
    ('clockQuarter', '⏰', 'الساعة بالربع والدقايق', 2, 0xFFB46E0A, clockQuarter),
  ].indexed)
    Stage(
      id: id, world: 'math', n: _math.length + _math100.length + _mul.length + i + 1, icon: icon, name: name,
      base: base, color: Color(color), gen: gen, group: 'life', groupName: 'الفلوس والساعة',
      after: i == 0 ? 'add100' : null,
      fromGrade: i == 0 ? 'p2' : null,
    ),
];

/// أول حزمة تدريب لسن ٩–١٢؛ بعد المراحل القديمة للحفاظ على التقدّم.
final _upperPrimary = [
  for (final (i, (id, icon, name, gen)) in <(String, String, String, Generator)>[
    ('divisionExact', '➗', 'القسمة من غير باقي', divisionExact),
    ('divisionMissing', '🔍', 'العدد الناقص في القسمة', divisionMissing),
    ('fractionOfNumber', '🍉', 'كسر من عدد', fractionOfNumber),
    ('fractionEquivalent', '⚖️', 'الكسور المتكافئة', fractionEquivalent),
  ].indexed)
    Stage(
      id: id, world: 'math', n: _math.length + _math100.length + _mul.length + _life.length + i + 1,
      icon: icon, name: name, base: 1, color: const Color(0xFF3968A8), gen: gen,
      group: 'upperPrimary', groupName: 'القسمة والكسور • ٩–١٢ سنة',
      after: i == 0 ? 'timesAll' : null, fromGrade: i == 0 ? 'p4' : null,
    ),
];

/// English للابتدائي بعد مراحل English الأصلية: أولى لتالتة (بعد "Choose word"، أو من أولى)،
/// وبعدين رابعة لسادسة (بعد "One or many?"، أو من رابعة).
final _enPrimary = [
  for (final (i, (id, icon, name, base, gen, group, groupName, after, from))
      in <(String, String, String, int, Generator, String, String, String?, String?)>[
    ('en_cvc', '📖', 'Read the word', 1, enCvc, 'enP1', 'Primary English • Grades 1–3', 'en_word', 'p1'),
    ('en_a_an', '🅰️', 'a or an?', 2, enAAn, 'enP1', 'Primary English • Grades 1–3', null, null),
    ('en_plural', '👯', 'One or many?', 2, enPlural, 'enP1', 'Primary English • Grades 1–3', null, null),
    ('en_isare', '✍️', 'is, are or am?', 2, enIsAre, 'enP4', 'English grammar • Ages 9–12', 'en_plural', 'p4'),
    ('en_questions', '❓', 'Question words', 2, enQuestions, 'enP4', 'English grammar • Ages 9–12', null, null),
    ('en_sentence', '📝', 'Complete the sentence', 2, enSentence, 'enP4', 'English grammar • Ages 9–12', null, null),
    ('en_reading', '📰', 'Read and answer', 2, enReading, 'enP4', 'English grammar • Ages 9–12', null, null),
  ].indexed)
    Stage(
      id: id, world: 'english', n: _english.length + i + 1, icon: icon, name: name, base: base,
      color: const Color(0xFF1F5FA8), gen: gen, lang: 'en', group: group, groupName: groupName,
      after: after, fromGrade: from,
    ),
];

/// world -> ترتيب مراحله.
final Map<String, List<Stage>> worldStages = {
  // المراحل اللي اتنشرت قبل كده (الحساب والعربي والمدود و English الأصليين) فاضلة بنفس ترتيبها
  // بين بعض — المجموعات الجديدة بتدخل بينها في مكانها في المنهج (stage_ids_test.dart)
  'math': _numbered([..._math, ..._mathBasics, ..._math1, ..._math100, ..._math2, ..._mul, ..._life, ..._upperPrimary]),
  'arabic': _numbered([
    ..._arabic, ..._concepts, ..._harakat, ..._forms, ..._madd, ..._shortRead, ..._sukun, ..._al, ..._fade, ..._ar2, ..._grammar,
  ]),
  'english': _numbered([..._english, if (voiceEnabled) ..._phonics, ..._enWords, ..._enSchool, ..._enPrimary]),
  'deen': _numbered(_deen),
  'discover': _numbered(_discover),
  'write': _numbered(_write),
  'games': [..._games, ..._play],
};

/// id -> المرحلة — ومعاها مراحل اختبار تحديد المستوى (مش على الخريطة).
final Map<String, Stage> packs = {
  for (final list in worldStages.values)
    for (final s in list) s.id: s,
  for (final s in placementStages) s.id: s,
};

/// العوالم اللي ليها مستوى لكل مادة في لوحة ولي الأمر — الألعاب مش مادة.
const subjectWorlds = ['math', 'arabic', 'english'];

/// صف المرحلة: صف أول مرحلة في مجموعتها ([Stage.fromGrade])، و null لمراحل الحضانة.
String? stageGrade(Stage s) => s.group == null ? null : _groupGrade[s.group];

final _groupGrade = {
  for (final list in worldStages.values)
    for (final s in list)
      if (s.group != null && s.fromGrade != null) s.group!: s.fromGrade!,
};

/// المراحل المفتوحة من الأول.
const initiallyUnlocked = ['counting', 'ar_learn', 'en_learn'];

/// السؤال الجاي لأي نوع: id مرحلة ("counting"، "madd_alif") أو نوع لعبة مدود ("madd_alif:letter").
/// "تدريب على الأخطاء" بيستخدم النوع الكامل عشان يرجّع نفس قيود المرحلة.
/// مستوى جولة المرحلة دي للطفل ده (المحرك وورقة العمل).
/// آخر جولتين ضعاف في المرحلة ← أسهل مستوى ليها، حتى لو تحت مستوى السن.
/// عالم الألعاب: المستوى من السن (الألعاب كلها مفتوحة، فمستوى العالم مابيقولش حاجة عن الطفل).
int roundLevel(ProgressData p, Stage stage) => p.struggling(stage.id)
    ? stage.base
    : openWorlds.contains(stage.world)
        ? math.max(stage.base, p.gamesLevel)
        : math.min(math.max(stage.base, math.min(p.level(stage.world), stage.base + 1)), 4);

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
