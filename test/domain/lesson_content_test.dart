import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/school_lessons.dart';

/// كل الشروح من assets/lessons/ — من الملفات مباشرة.
List<LessonContent> allLessonFiles() => [
      for (final f in Directory('assets/lessons').listSync().whereType<File>().where((f) => f.path.endsWith('.json')))
        ...parseLessonBook(f.readAsStringSync()),
    ];

void main() {
  final lessons = allLessonFiles();

  test('the grade 1 term 1 pilot is there', () {
    final books = {for (final l in lessons) schoolRound(l.id)!.book.id};
    expect(books, containsAll(['p1-t1-math', 'p1-t1-arabic', 'p1-t1-english']));
    expect(lessons.length, greaterThanOrEqualTo(23));
  });

  test('every explanation belongs to a ready lesson with the same title', () {
    final ids = <String>{};
    for (final l in lessons) {
      expect(ids.add(l.id), isTrue, reason: 'duplicate ${l.id}');
      final round = schoolRound(l.id);
      expect(round, isNotNull, reason: l.id);
      expect(round!.exam, isFalse, reason: l.id);
      // لو الكتاب اتغيّر ترتيبه، الشرح مايروحش لدرس تاني من غير ما نعرف
      expect(round.lessons.single.title, l.title, reason: l.id);
    }
  });

  test('every lesson follows the lesson checklist', () {
    for (final l in lessons) {
      final why = '${l.id} ${l.title}';
      expect(l.goal.trim(), isNotEmpty, reason: why);
      expect(l.blocks.first, isA<ExplainBlock>(), reason: '$why starts with an explanation');
      expect(l.blocks.last, isA<SummaryBlock>(), reason: '$why ends with the summary');
      expect(l.blocks.whereType<ExampleBlock>(), isNotEmpty, reason: '$why has a worked example');
      expect(l.blocks.whereType<ActivityBlock>(), isNotEmpty, reason: '$why has an activity away from the screen');
      final tries = [for (final b in l.blocks.whereType<TryBlock>()) ...b.questions];
      expect(tries.length, greaterThanOrEqualTo(3), reason: '$why: at least 3 guided questions');
      for (final b in l.blocks.whereType<ExampleBlock>()) {
        expect(b.steps.length, greaterThanOrEqualTo(2), reason: why);
      }
      for (final b in l.blocks.whereType<SummaryBlock>()) {
        expect(b.points, isNotEmpty, reason: why);
      }
    }
  });

  test('guided questions have one right answer among distinct choices, and say why', () {
    for (final l in lessons) {
      for (final q in [for (final b in l.blocks.whereType<TryBlock>()) ...b.questions]) {
        final why = '${l.id}: ${q.ask}';
        expect(q.choices.length, greaterThanOrEqualTo(2), reason: why);
        expect(q.choices.toSet(), hasLength(q.choices.length), reason: '$why: repeated choice');
        expect(q.choices, contains(q.answer), reason: why);
        expect(q.why.trim(), isNotEmpty, reason: why);
      }
    }
  });

  test('a missing number in a number bond is the one that completes it', () {
    for (final l in lessons.where((l) => l.title.startsWith('مكونات العدد'))) {
      for (final q in [for (final b in l.blocks.whereType<TryBlock>()) ...b.questions]) {
        final parts = (q.visual! as ExprVisual).parts;
        final a = (parts[0] as ExprTile).value! as int, total = (parts[4] as ExprTile).value! as int;
        expect(int.parse(q.answer), total - a, reason: '${l.id}: $a + ? = $total');
      }
    }
  });

  test('the first lesson of a unit is free, the rest is the full content', () {
    for (final l in lessons) {
      final lessonNo = int.parse(l.id.split(':l').last);
      expect(l.access, lessonNo == 1 ? LessonAccess.free : LessonAccess.premium, reason: l.id);
      // لحد الاشتراك كله مفتوح
      expect(l.open, isTrue);
    }
  });

  test('broken files are refused, not shown half-read', () {
    String book(String block) => '{"book": "p1-t1-math", "lessons": [{"key": "u1:l1", "title": "كم العدد؟", "goal": "x", '
        '"blocks": [$block]}]}';
    expect(() => parseLessonBook(book('{"type": "video"}')), throwsFormatException);
    expect(() => parseLessonBook(book('{"type": "explain", "text": "x", "visual": {"hologram": 1}}')), throwsFormatException);
    expect(() => parseLessonBook(book('{"type": "explain", "text": "x", "visual": {"expr": [{"x": 1}]}}')), throwsFormatException);
    expect(() => parseLessonBook('{"book": "p9-t1-math", "lessons": []}'), throwsFormatException);
    expect(
      () => parseLessonBook('{"book": "p1-t1-math", "lessons": [{"key": "lesson1", "title": "x", "goal": "x", "blocks": []}]}'),
      throwsFormatException,
    );
  });

  test('visuals and spoken parts read from JSON', () {
    final [l] = parseLessonBook('{"book": "p1-t1-arabic", "lessons": [{"key": "u1:l2", "title": "حرف الباء", "goal": "x", '
        '"access": "free", "blocks": ['
        '{"type": "explain", "text": "بَ بُ", "say": ["مع الفتحة", "بَ"], "visual": {"expr": [["🍎", 2], "+", 1, "=", null]}},'
        '{"type": "explain", "text": "x", "say": "جملة"}]}]}');
    expect(l.id, 'school:p1-t1-arabic:u1:l2');
    expect(l.access, LessonAccess.free);
    final first = (l.blocks[0] as ExplainBlock).card;
    expect(first.spoken, ['مع الفتحة', 'بَ']);
    final parts = (first.visual! as ExprVisual).parts;
    expect(parts[0], isA<ExprSide>().having((s) => s.count, 'count', 2));
    expect(parts[2], isA<ExprTile>().having((t) => t.value, 'value', 1));
    expect(parts[4], isA<ExprTile>().having((t) => t.value, 'value', null));
    expect((l.blocks[1] as ExplainBlock).card.spoken, ['جملة']);
  });

  test('finished explanations are saved with the progress', () {
    final p = ProgressData(name: 'x')..explained.add('school:p1-t1-math:u1:l1');
    final back = ProgressData.fromJson(p.toJson());
    expect(back.explained, {'school:p1-t1-math:u1:l1'});
    expect(ProgressData.fromJson(ProgressData(name: 'x').toJson()).explained, isEmpty);
  });

  testWidgets('the app finds the lesson files in its assets', (tester) async {
    final loaded = await tester.runAsync(() => loadLessons(rootBundle));
    expect(loaded!.keys.toSet(), {for (final l in lessons) l.id});
  });
}
