import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/fade_generators.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';

void main() {
  test('marks fade in three steps', () {
    expect(fadeMarks('كَلْبٌ', 0), 'كَلْبٌ');
    expect(fadeMarks('كَلْبٌ', 1), 'كَلب');
    expect(fadeMarks('كَلْبٌ', 2), 'كلب');
    // الحركة قبل حرف المد بتتشال في الخطوة التانية، والباقي بيفضل
    expect(fadeMarks('سَرِير', 1), 'سَرير');
    expect(fadeMarks('سَاعَة', 1), 'ساعَة');
    expect(fadeMarks('زَهْرَةٌ', 1), 'زَهرَة');
  });

  test('every fading word is fully vowelled and has its own picture', () {
    final emojis = {for (final w in fadeWords) w.$2};
    expect(emojis, hasLength(fadeWords.length));
    for (final (w, _) in fadeWords) {
      expect(fadeMarks(w, 2), isNot(w), reason: w);
    }
  });

  test('each step shows the word at its own level and says the full word', () {
    for (final (id, step) in [('ar_fade_full', 0), ('ar_fade_less', 1), ('ar_fade_none', 2)]) {
      final r = Rng.seeded(step);
      for (var i = 0; i < 40; i++) {
        final q = makeQuestion(id, 2, r, progress: ProgressData());
        expect(q.choices, contains(q.answer));
        if (q.choiceSay.isNotEmpty) {
          for (final c in q.choices) {
            expect(fadeMarks(q.choiceSay[c]!, step), c);
          }
        }
        if (step == 2) expect('${q.answer}${q.choices.join()}', isNot(matches(RegExp('[ً-ْ]'))));
      }
    }
  });

  test('the fading steps open one after another after sukun', () {
    final p = ProgressData();
    expect(p.isUnlocked('ar_fade_full'), isFalse);
    expect(packs['ar_fade_full']!.after, 'ar_sukun');
  });
}
