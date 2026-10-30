import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/domain/stages.dart';

/// أرقام المراحل محفوظة في تقدّم كل طفل (الفتح والميداليات والإتقان والرحلة والنسخ الاحتياطية).
/// تغيير اسم مرحلة أو مسحها بيضيّع تقدّم الأطفال فيها من غير ما حد ياخد باله — فالقايمة دي
/// متثبّتة. مرحلة جديدة تتضاف هنا في مكانها.
const frozen = {
  'math': ['counting', 'chooseNumber', 'nextNumber', 'previousNumber', 'neighbors', 'sequence', 'completeTable', 'emptyTable', 'ascending', 'descending', 'comparison', 'addition', 'subtraction', 'ordinals', 'zeroEvenOdd', 'geometry', 'measure', 'calendar', 'numBonds', 'coins', 'picGraph', 'wordProblem', 'position', 'threeNumbers', 'composeShapes', 'tensOnes', 'skipCount', 'compare100', 'add100', 'sub100', 'hundreds', 'rounding', 'barGraph', 'mulGroups', 'times2510', 'times34', 'times6789', 'timesAll', 'moneyCount', 'moneyChange', 'clockQuarter', 'divisionExact', 'divisionMissing', 'fractionOfNumber', 'fractionEquivalent'],
  'arabic': ['ar_learn', 'ar_pick', 'ar_match', 'ar_table', 'ar_build', 'ar_compose', 'ar_analyze', 'ar_connect', 'ar_complete', 'ar_choose_word', 'ar_match_word', 'ar_this', 'ar_groups', 'ar_haraka', 'ar_haraka_pick', 'ar_forms', 'ar_position', 'madd_alif', 'madd_waw', 'madd_yaa', 'madd_types', 'madd_complete', 'madd_compose', 'madd_find', 'madd_read', 'madd_mamdoud', 'ar_short_read', 'ar_tanween', 'ar_marks', 'ar_sukun', 'ar_shadda', 'ar_al', 'ar_fade_full', 'ar_fade_less', 'ar_fade_none', 'ar_far', 'ar_adverb', 'ar_command', 'ar_similar', 'ar_relative', 'ar_pronoun', 'ar_tense', 'ar_taa', 'ar_style', 'ar_particles', 'ar_wordType', 'ar_number', 'ar_gender', 'ar_opposite', 'ar_sentence', 'ar_reading'],
  'english': ['en_learn', 'en_pick', 'en_match', 'en_case', 'en_circle', 'en_pairs', 'en_friends', 'en_table', 'en_complete', 'en_word', 'en_numbers', 'en_colors', 'en_animals', 'en_daily', 'en_shapes', 'en_body', 'en_family', 'en_sight', 'en_phrases', 'en_prep', 'en_days', 'en_feelings', 'en_weather', 'en_seasons', 'en_months', 'en_rooms', 'en_places', 'en_transport', 'en_clothes', 'en_sports', 'en_actions', 'en_pronouns', 'en_count100', 'en_sounds', 'en_cvc', 'en_a_an', 'en_plural', 'en_isare', 'en_questions', 'en_sentence', 'en_reading'],
  'deen': ['deen_dua', 'deen_repeat', 'deen_wudu', 'deen_salah', 'deen_pillars', 'deen_prophets', 'deen_morals', 'deen_calendar'],
  'discover': ['disc_habitat', 'disc_seasons', 'disc_plant', 'disc_senses', 'disc_health'],
  'write': ['traceNum', 'traceAr', 'traceForms', 'traceWord', 'traceEn'],
  'games': ['balloons', 'memoryNum', 'race', 'puzzle', 'colorNum', 'pattern', 'letterHunt', 'rhythm', 'shapes', 'sizeOrder', 'clock', 'oddOne', 'shadow', 'opposite', 'storyOrder', 'category', 'missingPic', 'cups', 'cleanSteps', 'manner', 'dragSort', 'maze', 'lights', 'sudoku', 'hanoi', 'slide', 'numberSeq'],
};

/// المراحل اللي اتنشرت في ١.٠.٠: لازم تفضل موجودة وبنفس ترتيبها بين بعض. المجموعات الجديدة
/// ممكن تدخل بينها، لأن التقدّم المحفوظ أرقام مراحل مش أماكن، والمراحل الجديدة بتتفتح بـ after.
const shipped = {
  'math': ['counting', 'chooseNumber', 'nextNumber', 'previousNumber', 'neighbors', 'sequence', 'completeTable', 'emptyTable', 'ascending', 'descending', 'comparison', 'addition', 'subtraction'],
  'arabic': ['ar_learn', 'ar_pick', 'ar_match', 'ar_table', 'ar_build', 'ar_compose', 'ar_analyze', 'ar_connect', 'ar_complete', 'ar_choose_word', 'ar_match_word', 'madd_alif', 'madd_waw', 'madd_yaa', 'madd_types', 'madd_complete', 'madd_compose', 'madd_find', 'madd_read', 'madd_mamdoud'],
  'english': ['en_learn', 'en_pick', 'en_match', 'en_case', 'en_circle', 'en_pairs', 'en_friends', 'en_table', 'en_complete', 'en_word', 'en_numbers', 'en_colors', 'en_animals', 'en_daily'],
  'games': ['balloons', 'memoryNum', 'race', 'puzzle', 'colorNum', 'pattern', 'letterHunt', 'rhythm', 'shapes', 'sizeOrder', 'clock'],
};

/// مراحل مستنية الصوت — بتظهر لما voiceEnabled يتفتح، ومش جزء من القايمة الثابتة.
const voiceOnly = {'listenNum', 'animalSound', 'ar_syllable', 'ar_tanween_listen', 'en_phonics', 'en_firstsound', 'en_blend'};

void main() {
  test('stage ids and their order within each world are stable', () {
    final now = {
      for (final e in worldStages.entries) e.key: [for (final s in e.value) if (!voiceOnly.contains(s.id)) s.id],
    };
    expect(now, frozen);
  });

  test('stages from the released version keep their order between them', () {
    for (final e in shipped.entries) {
      final ids = [for (final s in worldStages[e.key]!) s.id];
      expect([for (final id in ids) if (e.value.contains(id)) id], e.value, reason: e.key);
    }
  });

  test('every new stage between released ones still opens from released progress', () {
    // مرحلة جديدة جوه عالم بترتيب: لازم تتفتح بـ after أو من المرحلة اللي قبلها (unlockNext)
    for (final w in ['math', 'arabic', 'english']) {
      final list = worldStages[w]!;
      for (final (i, s) in list.indexed) {
        if (i == 0 || shipped[w]!.contains(s.id)) continue;
        final prevShipped = shipped[w]!.contains(list[i - 1].id);
        if (prevShipped && s.group != list[i - 1].group) {
          expect(s.after, isNotNull, reason: '${s.id} sits after a released stage, so it needs an "after"');
        }
      }
    }
  });

  test('the stages unlocked from the start still exist', () {
    expect(initiallyUnlocked.every(packs.containsKey), isTrue);
    expect(voiceEnabled || voiceOnly.isNotEmpty, isTrue);
  });
}
