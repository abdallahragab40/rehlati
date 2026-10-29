/// اختبار تحديد المستوى: جولة من ١٠ أسئلة لكل مادة، سؤالين من كل درجة من الحضانة لرابعة ابتدائي.
///
/// الدرجة بتتحسب لو السؤالين اتجاوبوا صح من أول محاولة (التخمين في السؤالين ≈ ١ من ٩).
/// الطفل بيوصل لآخر درجة قبل أول درجة وقع فيها؛ الدرجات اللي عدّاها بتفتح مراحلها
/// وبتحدد مستوى البداية في المادة ([Settings.worldLevel]). مراحل الاختبار مش على الخريطة ولا في الرحلة.
library;

import 'dart:ui' show Color;

import '../core/utils/rng.dart';
import 'progress/progress_data.dart';
import 'question.dart';
import 'stages.dart';

class PlacementRung {
  const PlacementRung(this.label, this.questions, this.opens, this.level);

  /// للنتيجة: "تانية ابتدائي".
  final String label;

  /// سؤالين: (المرحلة، المستوى).
  final List<(String, int)> questions;

  /// المراحل اللي بتتفتح لو الطفل عدّى الدرجة دي.
  final List<String> opens;

  /// مستوى البداية في المادة (١–٣).
  final int level;
}

/// عالم ← الدرجات بالترتيب. المراحل اللي فيها كلها بمولّد عادي (مفيش مدود).
const placementLadders = {
  'math': [
    PlacementRung('الحضانة', [('counting', 1), ('chooseNumber', 1)], ['counting', 'chooseNumber'], 1),
    PlacementRung('أولى ابتدائي', [('addition', 3), ('subtraction', 3)], ['addition', 'subtraction'], 2),
    PlacementRung('تانية ابتدائي', [('tensOnes', 2), ('add100', 2)], ['tensOnes', 'add100'], 3),
    PlacementRung('تالتة ابتدائي', [('times2510', 3), ('times34', 3)], ['mulGroups', 'times2510', 'times34'], 3),
    PlacementRung('رابعة ابتدائي وأكبر', [('divisionExact', 3), ('fractionOfNumber', 2)],
        ['divisionExact', 'fractionOfNumber'], 3),
  ],
  'arabic': [
    PlacementRung('الحضانة', [('ar_pick', 1), ('ar_match', 1)], ['ar_pick', 'ar_match'], 1),
    PlacementRung('أولى ابتدائي', [('ar_build', 2), ('ar_haraka', 1)], ['ar_build', 'ar_haraka'], 2),
    PlacementRung('تانية ابتدائي', [('ar_tanween', 2), ('ar_sukun', 2)], ['ar_tanween', 'ar_sukun'], 3),
    PlacementRung('تالتة ابتدائي', [('ar_wordType', 3), ('ar_number', 2)], ['ar_wordType', 'ar_number'], 3),
    PlacementRung('رابعة ابتدائي وأكبر', [('ar_sentence', 2), ('ar_reading', 3)], ['ar_sentence', 'ar_reading'], 3),
  ],
  'english': [
    PlacementRung('الحضانة', [('en_pick', 1), ('en_match', 1)], ['en_pick', 'en_match'], 1),
    PlacementRung('أولى ابتدائي', [('en_word', 2), ('en_complete', 2)], ['en_word', 'en_complete'], 2),
    PlacementRung('تانية ابتدائي', [('en_cvc', 2), ('en_a_an', 2)], ['en_cvc', 'en_a_an'], 3),
    PlacementRung('تالتة ابتدائي', [('en_plural', 3), ('en_isare', 2)], ['en_plural', 'en_isare'], 3),
    PlacementRung('رابعة ابتدائي وأكبر', [('en_questions', 3), ('en_reading', 3)], ['en_questions', 'en_reading'], 3),
  ],
};

/// مراحل الاختبار — في [packs] عشان الشاشة والمحرك يلاقوها، بس مش في [worldStages].
final placementStages = [
  for (final (world, name, lang) in [('math', 'تحديد المستوى في الحساب', 'ar'), ('arabic', 'تحديد المستوى في العربي', 'ar'), ('english', 'Level check', 'en')])
    Stage(
      id: 'place_$world', world: world, n: 0, icon: '🎯', name: name, base: 1, color: const Color(0xFF3F51B5),
      lang: lang, count: 10,
      // مولّد احتياطي (للاختبارات): سؤال من الدرجة اللي على قد المستوى — الجولة الحقيقية بيعملها المحرك
      gen: (lv, r, {focus}) => _fromLadder(world, lv, r),
    ),
];

Question _fromLadder(String world, int lv, Rng r) {
  final rung = placementLadders[world]![(lv - 1).clamp(0, 4)];
  final (id, level) = r.sample(rung.questions);
  return packs[id]!.gen!(level, r);
}

bool isPlacement(String stageId) => stageId.startsWith('place_');

/// أسئلة الجولة بالترتيب: سؤالين من كل درجة، من الأسهل للأصعب.
List<Question> placementRound(String world, Rng r) => [
      for (final rung in placementLadders[world]!)
        for (final (id, level) in rung.questions) packs[id]!.gen!(level, r),
    ];

/// آخر درجة عدّاها (السؤالين صح من أول مرة) قبل أول درجة وقع فيها — -1 لو ماعدّاش الأولى.
int placementReached(List<bool> firstTry) {
  var reached = -1;
  for (var i = 0; i + 1 < firstTry.length; i += 2) {
    if (!(firstTry[i] && firstTry[i + 1])) break;
    reached = i ~/ 2;
  }
  return reached;
}

/// يفتح مراحل الدرجات اللي عدّاها ويحدد مستوى البداية — ويرجّع أعلى مرحلة اتفتحت (للنتيجة).
Stage? applyPlacement(ProgressData p, String world, int reached) {
  final ladder = placementLadders[world]!;
  p.settings.worldLevel[world] = reached < 0 ? 1 : ladder[reached].level;
  Stage? top;
  for (var i = 0; i <= reached; i++) {
    for (final id in ladder[i].opens) {
      if (!p.unlocked.contains(id)) p.unlocked.add(id);
    }
    top = packs[ladder[i].opens.first];
  }
  return top;
}

String placementLabel(String world, int reached) => reached < 0 ? 'لسه بيبدأ' : placementLadders[world]![reached].label;
