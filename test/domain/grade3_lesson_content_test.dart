import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

void main() {
  final lessons = {for (final l in allLessonFiles().where((l) => l.uid.startsWith('p3-t1-'))) l.id: l};

  test('every grade 3 term 1 lesson has an explanation', () {
    var count = 0;
    for (final book in schoolBooks.where((b) => b.grade == 'p3' && b.term == 1)) {
      for (var u = 0; u < book.units.length; u++) {
        for (var l = 0; l < book.units[u].lessons.length; l++) {
          expect(lessons[lessonId(book, u, l)]?.title, book.units[u].lessons[l].title);
          count++;
        }
      }
    }
    expect(count, lessons.length);
  });

  test('the 39 existing lessons keep the keys used by saved child results', () {
    const original = {
      'arabic': [
        ['أدوات الاستفهام', 'المقاطع الصوتية', 'هؤلاء – أولئك'],
        ['المفرد والمثنى والجمع', 'التنوين', 'أسلوب النفي (لم – لن)'],
        ['حروف الجر (عن – على)', 'التاء المفتوحة والمربوطة', 'حروف العطف (ثم – ف)'],
      ],
      'math': [
        ['الأنماط', 'التمثيل البياني بالأعمدة', 'التمثيل البياني بالنقاط', 'قياس الأطوال'],
        ['الآلاف', 'المصفوفات ومفهوم الضرب', 'خاصية الإبدال في الضرب'],
        ['مضاعفات ٢ و٣ و٤', 'مضاعفات ٥ و١٠', 'الوقت', 'مفهوم القسمة', 'العلاقة بين الضرب والقسمة'],
        ['المضلعات والأشكال الرباعية', 'المساحة'],
        ['المحيط والمساحة', 'الضرب في مضاعفات ١٠'],
        ['الضرب في ٩', 'مقارنة وترتيب الأعداد', 'الجمع والطرح', 'السعة'],
      ],
      'english': [
        ['Greetings', 'I am, you are, he is'],
        ['Family', 'my, his, her'],
        ['Places', 'in, on, under', 'Past tense: walked, played'],
        ['Feelings', 'Past simple stories'],
        ['Actions'],
      ],
    };
    var count = 0;
    for (final subject in original.entries) {
      final book = schoolBooks.singleWhere((b) => b.id == 'p3-t1-${subject.key}');
      for (final (u, titles) in subject.value.indexed) {
        for (final (l, title) in titles.indexed) {
          final lesson = schoolLessonAt('school:${book.id}:u${u + 1}:l${l + 1}');
          expect(lesson?.title, title);
          expect(lesson?.ready, isTrue, reason: title);
          count++;
        }
      }
    }
    expect(count, 39);
  });

  test('products, divisions and remainders add up', () {
    var checked = 0;
    final product = RegExp(r'^(\d+) × (\d+)$');
    final division = RegExp(r'(\d+) ÷ (\d+)');
    final withRemainder = RegExp(r'^(\d+) والباقي (\d+)$');
    for (final l in lessons.values.where((l) => l.uid.startsWith('p3-t1-math/'))) {
      for (final t in l.tasks) {
        for (final (left, right) in t.pairs) {
          if (product.firstMatch(left) case final m? when int.tryParse(right) != null) {
            expect(int.parse(right), int.parse(m[1]!) * int.parse(m[2]!), reason: '${l.uid}: $left');
            checked++;
          }
        }
        // «فيه باقي ولا لأ؟»
        for (final (name, items) in t.groups) {
          if (name != 'فيه باقي' && name != 'مفيش باقي') continue;
          for (final item in items) {
            final m = division.firstMatch(item)!;
            expect(int.parse(m[1]!) % int.parse(m[2]!) != 0, name == 'فيه باقي', reason: '${l.uid}: $item');
            checked++;
          }
        }
        // «أي إجابة صح لـ 15 ÷ 4؟» → «3 والباقي 3»
        if (withRemainder.firstMatch(t.answer) case final a?) {
          final m = division.firstMatch(t.ask)!;
          final (n, d) = (int.parse(m[1]!), int.parse(m[2]!));
          expect((int.parse(a[1]!), int.parse(a[2]!)), (n ~/ d, n % d), reason: '${l.uid}: ${t.ask}');
          checked++;
        }
      }
    }
    expect(checked, greaterThan(15));
  });

  test('the map records all ten maths chapters and keeps legacy lessons apart', () {
    final map = jsonDecode(File('tool/curriculum/p3-t1.json').readAsStringSync()) as Map<String, dynamic>;
    final math = (map['books'] as List).cast<Map<String, dynamic>>().singleWhere((b) => b['book'] == 'p3-t1-math');
    final units = (math['units'] as List).cast<Map<String, dynamic>>();
    expect(units.where((u) => (u['title'] as String).startsWith('الفصل')), hasLength(10));
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
}
