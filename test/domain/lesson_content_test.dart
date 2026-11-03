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
    final books = {for (final l in lessons) bookOfLesson(l.id)!.id};
    expect(books, containsAll(['p1-t1-math', 'p1-t1-arabic', 'p1-t1-english']));
    expect(lessons.length, greaterThanOrEqualTo(23));
  });

  test('every explanation belongs to a ready lesson with the same title, under a stable id', () {
    final ids = <String>{}, uids = <String>{};
    for (final l in lessons) {
      expect(ids.add(l.id), isTrue, reason: 'duplicate ${l.id}');
      expect(uids.add(l.uid), isTrue, reason: 'duplicate uid ${l.uid}');
      expect(l.uid, matches(RegExp(r'^p\d-t\d-[a-z]+/[a-z0-9-]+$')), reason: l.uid);
      final lesson = schoolLessonAt(l.id);
      expect(lesson, isNotNull, reason: l.id);
      // درس بجولة أسئلة، أو درس شرح بس (استماع، نشيد، قراءة)
      expect(lesson!.ready || lesson.explainOnly, isTrue, reason: l.id);
      // لو الكتاب اتغيّر ترتيبه، الشرح مايروحش لدرس تاني من غير ما نعرف
      expect(lesson.title, l.title, reason: l.id);
      expect(l.version, greaterThanOrEqualTo(1), reason: l.id);
    }
  });

  test('every lesson follows the lesson checklist', () {
    for (final l in lessons) {
      final why = '${l.id} ${l.title}';
      expect(l.goal.trim(), isNotEmpty, reason: why);
      expect(l.blocks.first, isA<HookBlock>(), reason: '$why starts with a hook');
      expect(l.blocks.whereType<ExplainBlock>(), isNotEmpty, reason: '$why explains');
      expect(l.blocks.last, isA<SummaryBlock>(), reason: '$why ends with the summary');
      // مثال محلول، أو قصة أو نشيد أو قراءة في دروس الاستماع والقراءة
      expect(l.blocks.where((b) => b is ExampleBlock || b is StoryBlock || b is PoemBlock || b is ReadBlock), isNotEmpty,
          reason: '$why has an example, a story, a song or reading');
      expect(l.blocks.whereType<ActivityBlock>(), isNotEmpty, reason: '$why has an activity away from the screen');
      final tries = l.blocks.whereType<TryBlock>();
      // «جرّب بنفسك» فيه نشاط مش «اختار» بس، و«تأكد من فهمك» بيقيس بعده
      expect(tries.where((b) => !b.check).expand((b) => b.tasks).where((t) => t.kind != TaskKind.choice), isNotEmpty,
          reason: '$why has a hands-on task');
      expect(tries.where((b) => b.check).expand((b) => b.tasks).length, greaterThanOrEqualTo(2), reason: '$why checks');
      expect(l.blocks.indexWhere((b) => b is TryBlock && b.check), greaterThan(l.blocks.indexWhere((b) => b is TryBlock && !b.check)),
          reason: '$why checks after trying');
      for (final b in l.blocks.whereType<ExampleBlock>()) {
        expect(b.steps.length, greaterThanOrEqualTo(2), reason: why);
      }
    }
  });

  test('every task has a hint for a mistake and a reason for the answer', () {
    for (final l in lessons) {
      for (final t in l.tasks) {
        final why = '${l.id}: ${t.ask}';
        expect(t.hint.trim(), isNotEmpty, reason: why);
        expect(t.why.trim(), isNotEmpty, reason: why);
        // تلميح لغلطة معيّنة لازم يكون لحاجة غلط فعلًا
        final wrongs = switch (t.kind) {
          TaskKind.choice => t.choices.where((c) => c != t.answer),
          TaskKind.pick => t.items.where((i) => !t.answers.contains(i)),
          _ => null,
        };
        if (wrongs != null) expect(wrongs.toSet().containsAll(t.hints.keys), isTrue, reason: '$why: ${t.hints.keys}');
        // التلميح مايقولش الإجابة
        if (t.kind == TaskKind.choice) expect(t.hint, isNot(contains('هي ${t.answer}')), reason: why);
      }
    }
  });

  test('a missing number in a number bond is the one that completes it', () {
    for (final l in lessons.where((l) => l.title.startsWith('مكونات العدد'))) {
      for (final t in l.tasks.where((t) => t.kind == TaskKind.choice)) {
        final parts = (t.visual! as ExprVisual).parts;
        final a = (parts[0] as ExprTile).value! as int, total = (parts[4] as ExprTile).value! as int;
        expect(int.parse(t.answer), total - a, reason: '${l.id}: $a + ? = $total');
      }
      for (final t in l.tasks.where((t) => t.kind == TaskKind.match)) {
        final total = l.tasks.map((t) => t.visual).whereType<ExprVisual>().first.parts[4] as ExprTile;
        for (final (a, b) in t.pairs) {
          expect(int.parse(a) + int.parse(b), total.value, reason: '${l.id}: $a + $b');
        }
      }
    }
  });

  test('building a word uses its letters in order', () {
    for (final l in lessons.where((l) => l.id.contains('-arabic:') && l.title.startsWith('حرف'))) {
      for (final t in l.tasks.where((t) => t.kind == TaskKind.order)) {
        final word = (t.visual! as EmojiVisual).caption!;
        expect(t.items.join(), word, reason: '${l.id}: ${t.items} → $word');
      }
    }
  });

  test('the first lesson of a unit is free, the rest is the full content; all are drafts for now', () {
    for (final l in lessons) {
      final lessonNo = int.parse(l.id.split(':l').last);
      expect(l.access, lessonNo == 1 ? LessonAccess.free : LessonAccess.premium, reason: l.id);
      // لحد الاشتراك ومراجعة المدرّس، كله مفتوح
      expect(l.open, isTrue);
    }
  });

  group('broken files are refused, not shown half-read', () {
    String book(String block, {String uid = 'p1-t1-math/x'}) =>
        '{"book": "p1-t1-math", "lessons": [{"uid": "$uid", "key": "u1:l1", "title": "كم العدد؟", "goal": "x", '
        '"version": 1, "review": "draft", "blocks": [$block]}]}';
    String task(String fields) => '{"type": "try", "tasks": [{"ask": "x", "hint": "h", "why": "w", $fields}]}';

    test('unknown blocks and visuals', () {
      expect(() => parseLessonBook(book('{"type": "video"}')), throwsFormatException);
      expect(() => parseLessonBook(book('{"type": "explain", "text": "x", "visual": {"hologram": 1}}')), throwsFormatException);
      expect(() => parseLessonBook(book('{"type": "explain", "text": "x", "visual": {"expr": [{"x": 1}]}}')),
          throwsFormatException);
      expect(() => parseLessonBook('{"book": "p9-t1-math", "lessons": []}'), throwsFormatException);
    });

    test('keys, ids and review', () {
      expect(() => parseLessonBook(book('', uid: 'p1-t1-arabic/x')), throwsFormatException);
      expect(
        () => parseLessonBook('{"book": "p1-t1-math", "lessons": [{"uid": "p1-t1-math/x", "key": "lesson1", "title": "x", '
            '"goal": "x", "version": 1, "review": "draft", "blocks": []}]}'),
        throwsFormatException,
      );
      expect(() => parseLessonBook(book('').replaceFirst('"draft"', '"maybe"')), throwsFormatException);
    });

    test('tasks that cannot be solved', () {
      expect(() => parseLessonBook(book(task('"choices": ["1", "2"], "answer": "3"'))), throwsFormatException);
      expect(() => parseLessonBook(book(task('"choices": ["1", "1"], "answer": "1"'))), throwsFormatException);
      expect(() => parseLessonBook(book(task('"kind": "pick", "items": ["a", "b"], "answers": ["c"]'))), throwsFormatException);
      expect(() => parseLessonBook(book(task('"kind": "pick", "items": ["a", "b"], "answers": ["a", "b"]'))),
          throwsFormatException);
      expect(() => parseLessonBook(book(task('"kind": "order", "items": ["a"]'))), throwsFormatException);
      expect(() => parseLessonBook(book(task('"kind": "match", "pairs": [["a", "1"], ["b", "1"]]'))), throwsFormatException);
      expect(
        () => parseLessonBook(book(task('"kind": "sort", "groups": [{"name": "x", "items": ["a"]}, {"name": "y", "items": ["a"]}]'))),
        throwsFormatException,
      );
      expect(() => parseLessonBook(book(task('"kind": "drag"'))), throwsArgumentError);
    });
  });

  test('visuals, spoken parts and task details read from JSON', () {
    final [l] = parseLessonBook('{"book": "p1-t1-arabic", "lessons": [{"uid": "p1-t1-arabic/ba", "key": "u1:l2", '
        '"title": "حرف الباء", "goal": "x", "version": 3, "review": "reviewed", "access": "free", "blocks": ['
        '{"type": "hook", "text": "قصة", "ask": "سؤال؟"},'
        '{"type": "explain", "text": "بَ بُ", "say": ["مع الفتحة", "بَ"], "visual": {"expr": [["🍎", 2], "+", 1, "=", null]}},'
        '{"type": "check", "tasks": [{"kind": "match", "ask": "وصّل", "pairs": [["ب", "🦆"], ["م", "🍌"]], "hint": "h", '
        '"hints": {"🍌": "مش ده"}, "help": {"text": "أسهل"}, "why": "w"}]}]}]}');
    expect(l.id, 'school:p1-t1-arabic:u1:l2');
    expect(l.uid, 'p1-t1-arabic/ba');
    expect((l.version, l.review, l.access), (3, LessonReview.reviewed, LessonAccess.free));
    expect((l.blocks[0] as HookBlock).ask, 'سؤال؟');
    final card = (l.blocks[1] as ExplainBlock).card;
    expect(card.spoken, ['مع الفتحة', 'بَ']);
    final parts = (card.visual! as ExprVisual).parts;
    expect(parts[0], isA<ExprSide>().having((s) => s.count, 'count', 2));
    expect(parts[4], isA<ExprTile>().having((t) => t.value, 'value', null));
    final check = l.blocks[2] as TryBlock;
    expect(check.check, isTrue);
    final t = check.tasks.single;
    expect(t.pairs, [('ب', '🦆'), ('م', '🍌')]);
    expect(t.hintFor('🍌'), 'مش ده');
    expect(t.hintFor('🦆'), 'h');
    expect(t.help!.text, 'أسهل');
  });

  group('what the parent sees about a lesson', () {
    final c = lessons.first;
    ProgressData progress([LessonLog? log, int? practice]) => ProgressData(
          name: 'x',
          lessonLogs: {c.uid: ?log},
          school: {c.id: ?practice},
        );

    test('not opened, stopped halfway, watched', () {
      expect(lessonStatus(progress(), c), LessonStatus.none);
      expect(lessonStatus(progress(LessonLog(page: 3)), c), LessonStatus.started);
      expect(lessonStatus(progress(LessonLog(done: true)), c), LessonStatus.watched);
    });

    test('needed help until the practice round reaches 80%', () {
      expect(lessonStatus(progress(LessonLog(done: true, mistakes: 2)), c), LessonStatus.helped);
      expect(lessonStatus(progress(LessonLog(done: true, mistakes: 2), 70), c), LessonStatus.helped);
      expect(lessonStatus(progress(LessonLog(done: true, mistakes: 2), 80), c), LessonStatus.mastered);
    });

    test('mastered alone: the check was right first time', () {
      expect(lessonStatus(progress(LessonLog(done: true, independent: true)), c), LessonStatus.mastered);
      // الإتقان بيفضل حتى لو رجع يشوف الشرح تاني
      expect(lessonStatus(progress(LessonLog(page: 2, independent: true)), c), LessonStatus.mastered);
    });

    test('the lesson record is saved with the progress', () {
      final p = progress(LessonLog(page: 4, done: true, activity: true, mistakes: 1, independent: true, current: 2, checkMiss: true));
      final back = ProgressData.fromJson(p.toJson()).lessonLogs[c.uid]!;
      expect((back.page, back.done, back.activity, back.mistakes, back.independent, back.current, back.checkMiss),
          (4, true, true, 1, true, 2, true));
      expect(ProgressData.fromJson(ProgressData(name: 'x').toJson()).lessonLogs, isEmpty);
    });
  });

  testWidgets('the app finds the lesson files in its assets', (tester) async {
    final loaded = await tester.runAsync(() => loadLessons(rootBundle));
    expect(loaded!.keys.toSet(), {for (final l in lessons) l.id});
  });
}
