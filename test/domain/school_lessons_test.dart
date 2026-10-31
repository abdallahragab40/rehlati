import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/core/utils/rng.dart';
import 'package:rehlati/domain/engine/game_engine.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/school_lessons.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/domain/worksheet.dart';
import 'package:rehlati/features/school/school_screen.dart';

import 'engine_test.dart' show correctIndex, makeContainer;

void main() {
  test('every lesson points at real stages that make questions', () {
    for (final b in schoolBooks) {
      for (final u in b.units) {
        for (final l in u.lessons) {
          for (final it in l.items) {
            final s = packs[it.stage];
            expect(s, isNotNull, reason: '${b.id} ${l.title}: ${it.stage}');
            expect(s!.gen != null || s.isMadd, isTrue, reason: '${it.stage} has no questions');
            expect(s.isLearn, isFalse, reason: it.stage);
          }
        }
      }
    }
  });

  test('there is a book for each grade, term and subject', () {
    for (final g in schoolScreenGrades) {
      for (final t in [1, 2]) {
        for (final s in ['arabic', 'math', 'english']) {
          expect(schoolBook(g.$1, t, s), isNotNull, reason: '${g.$1} t$t $s');
        }
      }
    }
  });

  test('ids find their lesson or unit exam, and bad ids find nothing', () {
    final book = schoolBook('p1', 1, 'arabic')!;
    final lesson = schoolRound(lessonId(book, 0, 1))!;
    expect(lesson.exam, isFalse);
    expect(lesson.title, 'حرف الباء');
    final exam = schoolRound(unitExamId(book, 0))!;
    expect(exam.exam, isTrue);
    expect(exam.lessons, hasLength(8));
    expect(schoolStage(unitExamId(book, 0))!.name, 'امتحان: أسرتي');
    for (final bad in ['school:', 'school:nope:u1', 'school:${book.id}:u9', 'school:${book.id}:u1:l99', 'counting']) {
      expect(schoolRound(bad), isNull, reason: bad);
    }
    // درس «قريبًا» مالوش جولة
    final p2 = schoolBook('p2', 1, 'arabic')!;
    final soon = p2.units[1].lessons.indexWhere((l) => !l.ready);
    expect(schoolRound(lessonId(p2, 1, soon)), isNull);
  });

  test('every ready lesson and exam makes a full round at every age', () {
    for (final id in allSchoolRoundIds()) {
      final round = schoolRound(id)!;
      for (final age in [6, 7, 8, 9, 10, 11, 12]) {
        final qs = schoolQuestions(round, ProgressData(age: age), Rng.seeded(id.hashCode + age));
        expect(qs, hasLength(round.count), reason: '$id age $age');
      }
    }
  });

  test('a letter lesson asks about its letter', () {
    final book = schoolBook('p1', 1, 'arabic')!;
    // الظاء: آخر الحروف في المستوى ١ ومع ذلك لازم تطلع
    final unit = book.units.indexWhere((u) => u.lessons.any((l) => l.title == 'حرف الظاء'));
    final l = book.units[unit].lessons.indexWhere((l) => l.title == 'حرف الظاء');
    final qs = schoolQuestions(schoolRound(lessonId(book, unit, l))!, ProgressData(age: 6), Rng.seeded(4));
    for (final q in qs) {
      expect(q.skill, anyOf('ar_letter:ظ', 'form:ظ'), reason: q.ask);
    }
  });

  test('a number-bond lesson stays on its number', () {
    final book = schoolBook('p1', 1, 'math')!;
    final l = book.units[0].lessons.indexWhere((l) => l.title == 'مكونات العدد ٨');
    final qs = schoolQuestions(schoolRound(lessonId(book, 0, l))!, ProgressData(age: 6), Rng.seeded(2));
    expect(qs.map((q) => q.skill).toSet(), {'bond:8'});
  });

  test('worksheets come from the lesson, and lessons made of sound only say so', () {
    final book = schoolBook('p1', 1, 'math')!;
    final sheet = schoolWorksheet(lessonId(book, 2, 0), ProgressData(age: 6), Rng.seeded(1));
    expect(sheet, hasLength(1));
    expect(sheet.single.questions.length, worksheetPerSection);
    expect(sheet.single.questions.every(printable), isTrue);
    expect(sheet.single.stage.name, 'الجمع');
  });

  test('school results survive saving', () {
    final p = ProgressData()..recordSchool('school:p1-t1-math:u1:l1', 7, 10);
    p.recordSchool('school:p1-t1-math:u1:l1', 5, 10);
    final back = ProgressData.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
    expect(back.school, {'school:p1-t1-math:u1:l1': 70});
  });

  test('a lesson round in the engine records its score and nothing else', () async {
    final c = await makeContainer();
    final id = lessonId(schoolBook('p1', 1, 'math')!, 2, 0);
    final engine = c.read(gameProvider.notifier)..start(id);
    final s = c.read(gameProvider)!;
    expect(s.stage.name, 'الجمع');
    expect(s.total, lessonQuestions);
    for (var i = 0; i < s.total; i++) {
      final cur = c.read(gameProvider)!;
      for (var t = 0; t < 40 && (cur.idx != i || cur.locked); t++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      engine.answer(correctIndex(c.read(gameProvider)!.q));
    }
    for (var t = 0; t < 40 && c.read(gameProvider)!.result == null; t++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    final p = c.read(progressProvider);
    expect(c.read(gameProvider)!.result, isNotNull);
    expect(p.school[id], 100);
    expect(p.best.containsKey(id), isFalse, reason: 'not a stage');
    expect(stageById(id), isNotNull);
  });

  test('the term follows the school calendar', () {
    expect(currentTerm(DateTime(2026, 10, 30)), 1);
    expect(currentTerm(DateTime(2027, 1, 10)), 1);
    expect(currentTerm(DateTime(2027, 3, 1)), 2);
  });
}
