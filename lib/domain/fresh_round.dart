/// جولة من غير تكرار: السؤال مايتكررش جوه الجولة، والسؤال اللي الطفل حلّه قبل كده مابيرجعش في
/// المحتوى الجديد. المراجعة المقصودة ([review]) بس هي اللي بتعيد أسئلة اتشافت، وبتتكتب «مراجعة».
///
/// لما أسئلة المستوى تخلص بنطلع للمستوى اللي بعده (لحد ٤). لو الجديد كله خلص بترجع قايمة أقصر،
/// ولو مفيش ولا سؤال جديد بترجع فاضية والشاشة بتقول كده بوضوح بدل ما تعيد أسئلة من غير ما تقول.
library;

import 'dart:math' as math;

import 'placement.dart';
import 'question.dart';
import 'question_key.dart';
import 'stages.dart';

/// المراحل اللي بتمنع التكرار: كل مراحل التعلّم. الألعاب والرسم بالصباع تكرارها هو اللعب نفسه،
/// واختبار المستوى ليه ترتيبه الخاص.
bool tracksRepeats(Stage s) =>
    (s.gen != null || s.madd != null) && !s.isLearn && !const {'games', 'write'}.contains(s.world) && !isPlacement(s.id);

/// المستوى الأعلى في المولّدات.
const maxLevel = 4;

/// [make] بياخد المستوى ويرجّع سؤال جديد. [seen] السؤال اتحل قبل كده (البصمة في سجل الطفل).
List<Question> drawRound({
  required int count,
  required int level,
  required Question Function(int level) make,
  required bool Function(Question q) seen,
  bool review = false,
  int tries = 30,
}) {
  final out = <Question>[];
  final inRound = <int>{};

  Question? find(int pref, {required bool allowSeen}) {
    // المستوى المطلوب الأول، وبعدين اللي فوقه، وبعدين اللي تحته لحد مستوى الجولة
    final levels = [for (var l = pref; l <= maxLevel; l++) l, for (var l = level; l < pref; l++) l];
    for (final lv in levels) {
      for (var t = 0; t < tries; t++) {
        final q = make(lv);
        if (isActivity(q)) return q;
        if (inRound.contains(questionKey(q))) continue;
        if (!allowSeen && seen(q)) continue;
        return q;
      }
    }
    return null;
  }

  for (var i = 0; i < count; i++) {
    // تدرّج لطيف داخل الجولة: آخر سؤالين أصعب قليلًا
    final pref = i >= count - 2 ? math.min(level + 1, maxLevel) : level;
    // المراجعة: الجديد أولًا لو فيه، وإلا سؤال اتشاف قبل كده
    final q = find(pref, allowSeen: false) ?? (review ? find(pref, allowSeen: true) : null);
    if (q == null) break;
    out.add(q);
    if (!isActivity(q)) inRound.add(questionKey(q));
  }
  return out;
}
