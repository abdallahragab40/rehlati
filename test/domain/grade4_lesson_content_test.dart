import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles().where((l) => l.uid.startsWith('p4-t1-'))) l.id: l};

  test('every grade 4 term 1 lesson has an explanation', () {
    var count = 0;
    for (final book in schoolBooks.where((b) => b.grade == 'p4' && b.term == 1)) {
      for (var u = 0; u < book.units.length; u++) {
        for (var l = 0; l < book.units[u].lessons.length; l++) {
          expect(lessons[lessonId(book, u, l)]?.title, book.units[u].lessons[l].title);
          count++;
        }
      }
    }
    expect(count, lessons.length);
  });

  test('the 37 existing lessons keep the keys used by saved child results', () {
    const original = {
      'arabic': [
        ['أنواع الكلمة وعلامات الاسم', 'دخول فـ بـ كـ لـ على «ال»', 'المفرد والمثنى والجمع'],
        ['الضمائر', 'علامات الترقيم', 'ركنا الجملة الاسمية'],
        ['المبتدأ والخبر المثنى', 'حروف تُنطق ولا تُكتب', 'المبتدأ والخبر جمع المذكر السالم'],
      ],
      'math': [
        ['الأعداد الكبيرة والقيمة المكانية', 'مقارنة وترتيب الأعداد', 'قواعد التقريب'],
        ['الجمع والطرح بإعادة التسمية', 'المسائل متعددة الخطوات'],
        ['الطول والكتلة والسعة', 'قياس الوقت والوقت المنقضي'],
        ['المحيط', 'المساحة', 'أبعاد مجهولة والأشكال المركبة'],
        ['المقارنة باستخدام الضرب', 'خواص الضرب وأنماطه'],
        ['العوامل والأعداد الأولية', 'المضاعفات'],
        ['الضرب في عدد من رقم أو رقمين', 'القسمة على عدد من رقم واحد'],
        ['ترتيب العمليات'],
      ],
      'english': [
        ['Present simple', 'My senses'],
        ["don't, doesn't, Do, Does", 'Places'],
        ['bigger, taller', 'Animals'],
        ['next to, between', 'in, on, under'],
        ['Jobs', 'the biggest, the tallest'],
        ['Reading: Kind Words'],
      ],
    };
    var count = 0;
    for (final subject in original.entries) {
      final book = schoolBooks.singleWhere((b) => b.id == 'p4-t1-${subject.key}');
      for (final (u, titles) in subject.value.indexed) {
        for (final (l, title) in titles.indexed) {
          final lesson = schoolLessonAt('school:${book.id}:u${u + 1}:l${l + 1}');
          expect(lesson?.title, title);
          expect(lesson?.ready, isTrue, reason: title);
          count++;
        }
      }
    }
    expect(count, 37);
  });

  test('products, divisions, «احسب» answers and remainders add up', () {
    int calc(int a, String op, int b) => switch (op) {
          '+' => a + b,
          '−' => a - b,
          '×' => a * b,
          _ => a ~/ b,
        };
    var checked = 0;
    final pair = RegExp(r'^(\d+) ([×÷]) (\d+)$');
    final ask = RegExp(r'^احسب: (\d+) ([+−×÷]) (\d+)$');
    final division = RegExp(r'(\d+) ÷ (\d+)');
    final withRemainder = RegExp(r'^(\d+) والباقي (\d+)$');
    for (final l in lessons.values.where((l) => l.uid.startsWith('p4-t1-math/'))) {
      for (final t in l.tasks) {
        for (final (left, right) in t.pairs) {
          if (pair.firstMatch(left) case final m? when int.tryParse(right) != null) {
            final (a, op, b) = (int.parse(m[1]!), m[2]!, int.parse(m[3]!));
            if (op == '÷') expect(a % b, 0, reason: '${l.uid}: $left');
            expect(int.parse(right), calc(a, op, b), reason: '${l.uid}: $left');
            checked++;
          }
        }
        if (ask.firstMatch(t.ask) case final m?) {
          final (a, op, b) = (int.parse(m[1]!), m[2]!, int.parse(m[3]!));
          expect(int.parse(t.answer), calc(a, op, b), reason: '${l.uid}: ${t.ask}');
          checked++;
        }
        if (withRemainder.firstMatch(t.answer) case final r?) {
          final m = division.firstMatch(t.ask)!;
          final (n, d) = (int.parse(m[1]!), int.parse(m[2]!));
          expect((int.parse(r[1]!), int.parse(r[2]!)), (n ~/ d, n % d), reason: '${l.uid}: ${t.ask}');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(40));
  });

  test('the map records the eight maths units with their pages', () {
    final map = jsonDecode(File('tool/curriculum/p4-t1.json').readAsStringSync()) as Map<String, dynamic>;
    final math = (map['books'] as List).cast<Map<String, dynamic>>().singleWhere((b) => b['book'] == 'p4-t1-math');
    final units = (math['units'] as List).cast<Map<String, dynamic>>();
    expect(units, hasLength(8));
    final entries = [for (final u in units) ...(u['lessons'] as List).cast<Map<String, dynamic>>()];
    expect(entries, hasLength(50));
    for (final e in entries) {
      expect(e['pages'], matches(RegExp(r'^\d+(–\d+)?$')));
      expect(e['app'], isNotEmpty, reason: e['title'] as String);
    }
  });
}
