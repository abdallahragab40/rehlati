import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/features.dart';
import 'package:rehlati/domain/stages.dart';

/// أرقام المراحل محفوظة في تقدّم كل طفل (الفتح والميداليات والإتقان والرحلة والنسخ الاحتياطية).
/// تغيير اسم مرحلة أو مسحها بيضيّع تقدّم الأطفال فيها من غير ما حد ياخد باله — فالقايمة دي
/// متثبّتة. مرحلة جديدة تتضاف هنا (وفي آخر عالمها عشان الترتيب القديم مايتغيرش).
const frozen = {
  'math': ['counting', 'chooseNumber', 'nextNumber', 'previousNumber', 'neighbors', 'sequence', 'completeTable', 'emptyTable', 'ascending', 'descending', 'comparison', 'addition', 'subtraction', 'tensOnes', 'skipCount', 'compare100', 'add100', 'sub100', 'mulGroups', 'times2510', 'times34', 'times6789', 'timesAll', 'moneyCount', 'moneyChange', 'clockQuarter', 'divisionExact', 'divisionMissing', 'fractionOfNumber', 'fractionEquivalent'],
  'arabic': ['ar_learn', 'ar_pick', 'ar_match', 'ar_table', 'ar_build', 'ar_compose', 'ar_analyze', 'ar_connect', 'ar_complete', 'ar_choose_word', 'ar_match_word', 'madd_alif', 'madd_waw', 'madd_yaa', 'madd_types', 'madd_complete', 'madd_compose', 'madd_find', 'madd_read', 'madd_mamdoud', 'ar_haraka', 'ar_haraka_pick', 'ar_tanween', 'ar_marks', 'ar_sukun', 'ar_wordType', 'ar_number', 'ar_gender', 'ar_opposite', 'ar_sentence', 'ar_reading'],
  'english': ['en_learn', 'en_pick', 'en_match', 'en_case', 'en_circle', 'en_pairs', 'en_friends', 'en_table', 'en_complete', 'en_word', 'en_numbers', 'en_colors', 'en_animals', 'en_daily', 'en_cvc', 'en_a_an', 'en_plural', 'en_isare', 'en_questions', 'en_sentence', 'en_reading'],
  'games': ['balloons', 'memoryNum', 'race', 'puzzle', 'colorNum', 'pattern', 'letterHunt', 'rhythm', 'shapes', 'sizeOrder', 'clock'],
};

void main() {
  test('stage ids and their order within each world are stable', () {
    final now = {for (final e in worldStages.entries) e.key: [for (final s in e.value) s.id]};
    // مراحل مستنية الصوت (زي listenNum) بتظهر لما voiceEnabled يتفتح — ومش جزء من القايمة الثابتة
    if (voiceEnabled) {
      now['games']!.remove('listenNum');
      now['arabic']!
        ..remove('ar_syllable')
        ..remove('ar_tanween_listen');
    }
    expect(now, frozen);
  });

  test('the stages unlocked from the start still exist', () {
    expect(initiallyUnlocked.every(packs.containsKey), isTrue);
  });
}
