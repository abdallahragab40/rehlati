import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/question.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles().where((l) => l.uid.startsWith('p2-t1-'))) l.id: l};

  test('every grade 2 term 1 lesson has an explanation', () {
    for (final book in schoolBooks.where((b) => b.grade == 'p2' && b.term == 1)) {
      for (var u = 0; u < book.units.length; u++) {
        for (var l = 0; l < book.units[u].lessons.length; l++) {
          expect(lessons[lessonId(book, u, l)]?.title, book.units[u].lessons[l].title);
        }
      }
    }
  });

  test('the 32 existing lessons keep the keys used by saved child results', () {
    const original = {
      'arabic': [
        ['المفرد والمثنى', 'تحليل الكلمات إلى مقاطع', 'أسماء الإشارة'],
        ['ذلك – تلك', 'اللام الشمسية واللام القمرية', 'ظرف الزمان وظرف المكان'],
        ['الأمر والنهي', 'الحروف المتشابهة في النطق', 'الأسماء الموصولة'],
      ],
      'math': [
        ['التمثيل البياني بالصور', 'التمثيل البياني بالأعمدة'],
        ['الجمع والطرح', 'مسائل كلامية'],
        ['الأعداد من ٣ أرقام'],
        ['الجمع والطرح بإعادة التجميع', 'تقدير نواتج الجمع والطرح'],
        ['الأشكال الهندسية', 'قياس الأطوال'],
        ['الكتلة', 'الوقت'],
      ],
      'english': [
        ['Classroom things', 'Short vowels a, e, i'],
        ['Colors, shapes and numbers', 'Numbers 11–20'],
        ['Classroom actions', 'First sounds'],
        ['My family', 'Long vowels o, u and th'],
        ['My home', 'sh and th'],
        ['Rooms at home', 'ch'],
      ],
    };
    for (final subject in original.entries) {
      final book = schoolBooks.singleWhere((b) => b.id == 'p2-t1-${subject.key}');
      for (final (u, titles) in subject.value.indexed) {
        for (final (l, title) in titles.indexed) {
          expect(schoolLessonAt('school:${book.id}:u${u + 1}:l${l + 1}')?.title, title);
        }
      }
    }
  });

  test('math answers agree with the displayed expressions and matching pairs', () {
    var checked = 0;
    int calculate(int a, String op, int b) => op == '+' ? a + b : a - b;
    for (final l in lessons.values.where((l) => l.uid.startsWith('p2-t1-math/'))) {
      for (final t in l.tasks) {
        if (t.visual case ExprVisual(:final parts) when t.kind == TaskKind.choice) {
          final a = (parts[0] as ExprTile).value! as int;
          final op = (parts[1] as ExprOp).op;
          final b = (parts[2] as ExprTile).value! as int;
          expect(int.parse(t.answer), calculate(a, op, b), reason: '${l.uid}: $a $op $b');
          checked++;
        }
        for (final (left, right) in t.pairs) {
          final m = RegExp(r'^(\d+) ([+−]) (\d+)$').firstMatch(left);
          if (m == null || int.tryParse(right) == null) continue;
          expect(int.parse(right), calculate(int.parse(m[1]!), m[2]!, int.parse(m[3]!)), reason: l.uid);
          checked++;
        }
      }
    }
    // أنشطة «المس» و«رتّب» وخط الأعداد بتتحسب في lesson_content_test (number-line jumps…)
    expect(checked, greaterThan(40));
  });

  test('regrouping practice starts with carrying and borrowing', () {
    final lesson = schoolLessonAt('school:p2-t1-math:u4:l1')!;
    expect(lesson.items.map((i) => i.minLevel), everyElement(greaterThanOrEqualTo(4)));
  });

  test('the new math map records all nine chapters and separates legacy extras', () {
    final map = jsonDecode(File('tool/curriculum/p2-t1.json').readAsStringSync()) as Map<String, dynamic>;
    final math = (map['books'] as List).cast<Map<String, dynamic>>().singleWhere((b) => b['book'] == 'p2-t1-math');
    final units = (math['units'] as List).cast<Map<String, dynamic>>();
    expect(
      units.where((u) => !['تطبيقات إضافية', 'مهارات إضافية محفوظة من الفهرس السابق'].contains(u['title'])),
      hasLength(9),
    );
    for (final unit in units) {
      for (final e in (unit['lessons'] as List).cast<Map<String, dynamic>>()) {
        if (e['kind'] == 'supplement') {
          expect(e['pages'], isNull);
          expect(e['note'], isNotEmpty);
        } else {
          expect(e['pages'], matches(RegExp(r'^\d+–\d+$')));
        }
      }
    }
  });

  test('the bar graph lesson shows columns with a positive scale', () {
    final lesson = lessons['school:p2-t1-math:u1:l2']!;
    expect(lesson.blocks.whereType<ExplainBlock>().map((b) => b.card.visual).whereType<BarGraphVisual>(), isNotEmpty);
    final graph =
        visualFromJson({
              'barGraph': [
                ['⚽', 6],
                ['🎨', 4],
              ],
              'scale': 2,
            })
            as BarGraphVisual;
    expect(graph.scale, 2);
    expect(graph.rows, [('⚽', 6), ('🎨', 4)]);
    for (final bad in [
      {'barGraph': <List<Object>>[], 'scale': 1},
      {
        'barGraph': [
          ['⚽', 6],
        ],
        'scale': 0,
      },
      {
        'barGraph': [
          ['⚽', -1],
        ],
        'scale': 1,
      },
    ]) {
      expect(() => visualFromJson(bad), throwsFormatException);
    }
  });
}
