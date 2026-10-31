import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/domain/worksheet.dart';

void main() {
  ProgressData played() {
    final p = ProgressData(grade: 'p1');
    for (final w in ['math', 'arabic', 'english']) {
      for (final s in worldStages[w]!.take(4)) {
        p.unlocked.add(s.id);
        p.best[s.id] = 2;
      }
    }
    return p;
  }

  test('a child who has not played gets no worksheet', () {
    expect(buildWorksheet(ProgressData(), Rng.seeded(1)), isEmpty);
  });

  test('every section fills a page with distinct pen-and-paper questions', () {
    final sheet = buildWorksheet(played(), Rng.seeded(2));
    expect(sheet, hasLength(worksheetSections));
    for (final s in sheet) {
      expect(s.questions, hasLength(worksheetPerSection), reason: s.stage.id);
      expect(s.questions.every(printable), isTrue, reason: s.stage.id);
      expect(s.questions.map((q) => '${q.ask}|${q.answer}|${q.choices}').toSet().length, greaterThan(1), reason: s.stage.id);
    }
  });

  test('weak skills come first', () {
    final p = played();
    final weak = worldStages['arabic']![2].id;
    p.miss(weak, 'x:y');
    p.miss(weak, 'x:y');
    expect(worksheetStages(p, Rng.seeded(3)).first.id, weak);
  });

  test('locked stages never reach the worksheet', () {
    final p = played();
    final locked = worldStages['math']!.last.id;
    p.miss(locked, 'x:y');
    p.miss(locked, 'x:y');
    expect(worksheetStages(p, Rng.seeded(4)).map((s) => s.id), isNot(contains(locked)));
  });

  test('listening questions are not printable', () {
    const q = Question(
      type: 't',
      mode: QMode.choice,
      ask: 'اسمع واختار',
      speak: '',
      hint: '',
      choices: ['أ', 'ب'],
      answer: 'أ',
    );
    expect(printable(q), isFalse);
    expect(answerLetter(const Question(type: 't', mode: QMode.choice, ask: '', speak: '', hint: '', choices: [3, 5], answer: 5)), 'ب');
  });
}
