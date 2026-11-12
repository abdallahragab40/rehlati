import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles().where((l) => l.uid.startsWith('p6-t1-'))) l.id: l};

  test('every grade 6 term 1 lesson has an explanation', () {
    var count = 0;
    for (final book in schoolBooks.where((b) => b.grade == 'p6' && b.term == 1)) {
      for (var u = 0; u < book.units.length; u++) {
        for (var l = 0; l < book.units[u].lessons.length; l++) {
          expect(lessons[lessonId(book, u, l)]?.title, book.units[u].lessons[l].title);
          count++;
        }
      }
    }
    expect(count, lessons.length);
  });

  test('the 29 existing lessons keep the keys used by saved child results', () {
    const original = {
      'arabic': [
        ['الاسم النكرة والاسم المعرفة', 'الهمزة المتوسطة على الألف', 'أنواع المعارف'],
        ['الأسماء الخمسة وعلاماتها الإعرابية', 'الهمزة المتوسطة على الياء (النبرة)', 'أنواع الخبر'],
        ['كان وأخواتها', 'الهمزة المتوسطة على الواو', 'إن وأخواتها'],
      ],
      'math': [
        ['قابلية القسمة والعوامل الأولية', 'العامل المشترك الأكبر والمضاعف المشترك الأصغر'],
        ['خط الأعداد ومقارنة الأعداد', 'القيمة المطلقة'],
        ['التعبيرات والمقادير الجبرية', 'ترتيب العمليات والأسس'],
        ['حل المعادلات والمتباينات'],
        ['العلاقة بين متغيرين'],
        ['تمثيل البيانات'],
        ['الوسط الحسابي والوسيط والمنوال', 'المدى'],
      ],
      'english': [
        ['Present simple'],
        ['Present continuous', 'Nature'],
        ['Jobs', "can, can't, able to"],
        ['Materials', 'should, must'],
        ['Travel', 'Past simple'],
      ],
    };
    var count = 0;
    for (final subject in original.entries) {
      final book = schoolBooks.singleWhere((b) => b.id == 'p6-t1-${subject.key}');
      for (final (u, titles) in subject.value.indexed) {
        for (final (l, title) in titles.indexed) {
          final lesson = schoolLessonAt('school:${book.id}:u${u + 1}:l${l + 1}');
          expect(lesson?.title, title);
          expect(lesson?.ready, isTrue, reason: title);
          count++;
        }
      }
    }
    expect(count, 29);
  });

  test('the book unit «Water Savers» is a new English unit at the end', () {
    final book = schoolBooks.singleWhere((b) => b.id == 'p6-t1-english');
    expect(book.units.last.title, 'Water Savers');
    expect(book.units.last.lessons.every((l) => l.explainOnly), isTrue);
  });

  test('negative numbers use the maths minus «−», not a hyphen', () {
    for (final l in lessons.values.where((l) => l.uid.startsWith('p6-t1-math/'))) {
      for (final t in l.tasks) {
        // خط الأعداد بيكتب علاماته بنفسه ('-3')، فإجابته مستثناة
        for (final s in [t.ask, if (t.kind != TaskKind.line) t.answer, ...t.items, for (final (a, b) in t.pairs) ...[a, b]]) {
          expect(s, isNot(matches(RegExp(r'(^|[\s(|])-\d'))), reason: '${l.uid}: $s');
        }
      }
    }
  });

  test('the map records the seven maths units and their 33 lessons', () {
    final map = jsonDecode(File('tool/curriculum/p6-t1.json').readAsStringSync()) as Map<String, dynamic>;
    final math = (map['books'] as List).cast<Map<String, dynamic>>().singleWhere((b) => b['book'] == 'p6-t1-math');
    final units = (math['units'] as List).cast<Map<String, dynamic>>();
    expect(units, hasLength(7));
    final entries = [for (final u in units) ...(u['lessons'] as List).cast<Map<String, dynamic>>()];
    expect(entries, hasLength(33));
    for (final e in entries) {
      expect(e['pages'], matches(RegExp(r'^\d+(–\d+)?$')));
      expect(e['app'], isNotEmpty, reason: e['title'] as String);
    }
  });
}
