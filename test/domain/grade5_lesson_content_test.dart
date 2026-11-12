import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles().where((l) => l.uid.startsWith('p5-t1-'))) l.id: l};

  test('every grade 5 term 1 lesson has an explanation', () {
    var count = 0;
    for (final book in schoolBooks.where((b) => b.grade == 'p5' && b.term == 1)) {
      for (var u = 0; u < book.units.length; u++) {
        for (var l = 0; l < book.units[u].lessons.length; l++) {
          expect(lessons[lessonId(book, u, l)]?.title, book.units[u].lessons[l].title);
          count++;
        }
      }
    }
    expect(count, lessons.length);
  });

  test('the 32 existing lessons keep the keys used by saved child results', () {
    const original = {
      'arabic': [
        ['المفعول به', 'همزة القطع وألف الوصل', 'المفعول به: المفرد وجمع التكسير'],
        ['المفعول به: جمع المؤنث السالم', 'الهمزة المتطرفة على السطر', 'المفعول به: المثنى وجمع المذكر السالم'],
        ['المفعول لأجله', 'الهمزة المتطرفة على الألف', 'إعراب ظرفي الزمان والمكان'],
      ],
      'math': [
        ['الكسور العشرية حتى جزء من الألف', 'مقارنة وتقريب الكسور العشرية', 'جمع وطرح الكسور العشرية'],
        ['التعبيرات والمعادلات والمتغيرات', 'العوامل الأولية والعامل المشترك الأكبر', 'المضاعفات والمضاعف المشترك الأصغر'],
        ['الضرب في عدد من رقمين'],
        ['القسمة وتقدير خارج القسمة'],
        ['الضرب والقسمة على قوى العدد ١٠', 'ضرب الكسور العشرية', 'الكسور العشرية والنظام المتري'],
        ['ترتيب العمليات والأقواس', 'الأنماط العددية'],
      ],
      'english': [
        ['always, sometimes, never', 'Food'],
        ['a, an, some, any', 'My body'],
        ["Did you…? I didn't", 'Weather'],
        ['in, on, at (time)', 'Places'],
        ['bigger, taller'],
        ['Reading: The Talking Earth'],
      ],
    };
    var count = 0;
    for (final subject in original.entries) {
      final book = schoolBooks.singleWhere((b) => b.id == 'p5-t1-${subject.key}');
      for (final (u, titles) in subject.value.indexed) {
        for (final (l, title) in titles.indexed) {
          final lesson = schoolLessonAt('school:${book.id}:u${u + 1}:l${l + 1}');
          expect(lesson?.title, title);
          expect(lesson?.ready, isTrue, reason: title);
          count++;
        }
      }
    }
    expect(count, 32);
  });

  test('decimal and whole-number answers add up', () {
    double n(String s) => double.parse(s.replaceAll('٫', '.'));
    double calc(double a, String op, double b) => switch (op) {
          '+' => a + b,
          '−' => a - b,
          '×' => a * b,
          _ => a / b,
        };
    const number = r'(\d+(?:٫\d+)?)';
    final pair = RegExp('^$number ([+−×÷]) $number\$');
    final ask = RegExp('^احسب: $number ([+−×÷]) $number\$');
    var checked = 0;
    // دروس «تقدير» بتوصّل العملية بتقديرها، مش بناتجها بالظبط
    for (final l in lessons.values.where((l) => l.uid.startsWith('p5-t1-math/') && !l.title.contains('تقدير'))) {
      for (final t in l.tasks) {
        for (final (left, right) in t.pairs) {
          if (pair.firstMatch(left) case final m? when RegExp(r'^\d+(٫\d+)?$').hasMatch(right)) {
            expect(n(right), closeTo(calc(n(m[1]!), m[2]!, n(m[3]!)), 1e-9), reason: '${l.uid}: $left');
            checked++;
          }
        }
        if (ask.firstMatch(t.ask) case final m?) {
          expect(n(t.answer), closeTo(calc(n(m[1]!), m[2]!, n(m[3]!)), 1e-9), reason: '${l.uid}: ${t.ask}');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(50));
  });

  test('decimals are written with the Arabic separator, never a Latin point', () {
    for (final l in lessons.values.where((l) => l.uid.startsWith('p5-t1-math/'))) {
      for (final t in l.tasks) {
        for (final s in [t.ask, t.answer, ...t.items, for (final (a, b) in t.pairs) ...[a, b]]) {
          expect(s, isNot(matches(RegExp(r'\d\.\d'))), reason: '${l.uid}: $s');
        }
      }
    }
  });

  test('the map records the six maths units and their 46 lessons', () {
    final map = jsonDecode(File('tool/curriculum/p5-t1.json').readAsStringSync()) as Map<String, dynamic>;
    final math = (map['books'] as List).cast<Map<String, dynamic>>().singleWhere((b) => b['book'] == 'p5-t1-math');
    final units = (math['units'] as List).cast<Map<String, dynamic>>();
    expect(units, hasLength(6));
    final entries = [for (final u in units) ...(u['lessons'] as List).cast<Map<String, dynamic>>()];
    expect(entries, hasLength(46));
    for (final e in entries) {
      expect(e['pages'], matches(RegExp(r'^\d+(–\d+)?$')));
      expect(e['app'], isNotEmpty, reason: e['title'] as String);
    }
  });
}
