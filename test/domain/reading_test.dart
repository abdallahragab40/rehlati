import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/generators/reading_generators.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';

/// اقرأ وافهم: الإجابة في القطعة، والاختيارات الغلط مش فيها.
void main() {
  test('every passage has three questions; answers are distinct from the wrong choices', () {
    for (final p in [...arPassages, ...enPassages]) {
      expect(p.questions.length, 3, reason: p.title);
      for (final (q, answer, wrong) in p.questions) {
        expect(wrong.length, 2, reason: q);
        expect({answer, ...wrong}.length, 3, reason: q);
      }
    }
  });

  test('wrong choices never appear in their passage, so only reading decides', () {
    // مقصودة: "يطول" في القطعة بس عن الليل، والسؤال عن النهار — بتختبر القراية بدقة
    const traps = {'يطول'};
    for (final p in [...arPassages, ...enPassages]) {
      for (final (q, _, wrong) in p.questions) {
        for (final w in wrong.where((w) => !traps.contains(w))) {
          expect(p.text.contains(w), isFalse, reason: '"$w" is in "${p.title}" ($q)');
        }
      }
    }
  });

  test('the passage is shown with its question; "why" questions only from level 3', () {
    final r = Rng.seeded(71);
    for (final (gen, pool, en) in [(arReading, arPassages, false), (enReading, enPassages, true)]) {
      for (var lv = 1; lv <= 4; lv++) {
        for (var i = 0; i < 200; i++) {
          final q = gen(lv, r);
          final v = q.visuals.single as PassageVisual;
          final p = pool.firstWhere((x) => x.title == v.title);
          expect(v.ltr, en);
          final index = p.questions.indexWhere((x) => x.$1 == q.ask);
          expect(index, isNot(-1));
          if (lv <= 2) expect(index, lessThan(2));
          expect(q.answer, p.questions[index].$2);
          expect(q.choices.where((c) => c == q.answer).length, 1);
        }
      }
    }
  });

  test('reading closes the 9–12 Arabic and English groups', () {
    expect(worldStages['arabic']!.last.id, 'ar_reading');
    expect(worldStages['english']!.last.id, 'en_reading');
    expect([packs['ar_reading']!.group, packs['en_reading']!.group], ['grammar', 'enP4']);
  });
}
