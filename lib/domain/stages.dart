/// سجل المراحل المركزي — منقول من js/worlds.js.
///
/// أي عالم جديد = بيانات + مولّدات + قائمة مراحل هنا. المحرك والواجهة والنجوم مشتركين.
library;

import 'dart:ui' show Color;

import '../content/language_data.dart';
import '../content/math_data.dart';
import '../core/utils/rng.dart';
import 'generators/arabic_generators.dart';
import 'generators/english_generators.dart';
import 'generators/math_generators.dart';
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
      title: '🔤 عالم العربي', desc: 'الحروف والكلمات والقراءة'),
  WorldMeta(id: 'english', icon: '🇬🇧', name: 'English', color: Color(0xFF4CB8FF), tone: Color(0xFF1E86CC),
      title: '🇬🇧 English World', desc: 'Letters, words and sounds'),
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

  bool get isLearn => learnItems != null;
  bool get isEnglish => lang == 'en';
}

class _Def {
  const _Def(this.id, this.icon, this.name, this.base, this.color, {this.gen, this.learn, this.lang = 'ar'});
  final String id, icon, name;
  final int base;
  final int color;
  final Generator? gen;
  final List<Letter>? learn;
  final String lang;
}

List<Stage> _register(String world, List<_Def> defs) => [
      for (var i = 0; i < defs.length; i++)
        Stage(
          id: defs[i].id, world: world, n: i + 1, icon: defs[i].icon, name: defs[i].name,
          base: defs[i].base, color: Color(defs[i].color), gen: defs[i].gen,
          learnItems: defs[i].learn, lang: defs[i].lang,
        ),
    ];

final _math = _register('math', [
  _Def('counting', '🔢', 'العد', 1, palette[0], gen: counting),
  _Def('chooseNumber', '🎯', 'اختر الرقم', 1, palette[1], gen: chooseNumber),
  _Def('nextNumber', '➡️', 'العدد التالي', 1, palette[2], gen: nextNumber),
  _Def('previousNumber', '⬅️', 'العدد السابق', 1, palette[3], gen: previousNumber),
  _Def('sequence', '🔗', 'أكمل التسلسل', 2, palette[4], gen: sequence),
  _Def('completeTable', '🧮', 'أكمل الجدول', 2, palette[5], gen: completeTable),
  _Def('ascending', '📈', 'ترتيب تصاعدي', 2, palette[6], gen: ascending),
  _Def('descending', '📉', 'ترتيب تنازلي', 3, palette[7], gen: descending),
  _Def('comparison', '⚖️', 'أكبر وأصغر', 2, palette[8], gen: comparison),
  _Def('addition', '➕', 'الجمع', 3, palette[9], gen: addition),
  _Def('subtraction', '➖', 'الطرح', 3, palette[10], gen: subtraction),
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

/// world -> ترتيب مراحله.
final Map<String, List<Stage>> worldStages = {
  'math': _math,
  'arabic': _arabic,
  'english': _english,
};

/// id -> المرحلة.
final Map<String, Stage> packs = {
  for (final list in worldStages.values)
    for (final s in list) s.id: s,
};

/// المراحل المفتوحة من الأول.
const initiallyUnlocked = ['counting', 'ar_learn', 'en_learn'];
