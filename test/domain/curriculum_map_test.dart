import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/school_curriculum.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/school_lessons.dart';

import 'lesson_content_test.dart' show allLessonFiles;

/// سجل كتب الوزارة (tool/curriculum/books-2026-2027.json) وخرايط الدروس (tool/curriculum/p1-t1.json وأي
/// `p*-t*.json` يتضاف بعدين): كل خريطة لازم تفضل مطابقة للتطبيق وللشرح الموجود.
void main() {
  Map<String, dynamic> read(String path) => jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final registry = read('tool/curriculum/books-2026-2027.json');
  final maps = [
    for (final f in Directory('tool/curriculum').listSync().whereType<File>())
      if (RegExp(r'p\d-t\d\.json$').hasMatch(f.path)) read(f.path),
  ];
  final explained = {for (final l in allLessonFiles()) l.id: l};

  test('every registry book has a source link and its app book exists', () {
    for (final b in (registry['books'] as List).cast<Map<String, dynamic>>()) {
      expect(b['url'], startsWith('https://elearnningcontent.blob.core.windows.net/elearnningcontent/2026_2027/'));
      expect(b['checked'], matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
      if (b['app_book'] case final String id) {
        expect(schoolBooks.any((s) => s.id == id), isTrue, reason: id);
      }
    }
  });

  test('grade 1 term 1 has a map', () => expect(maps.map((m) => '${m['grade']}-t${m['term']}'), contains('p1-t1')));

  for (final book in [for (final m in maps) ...(m['books'] as List).cast<Map<String, dynamic>>()]) {
    final id = book['book'] as String;
    final sb = schoolBooks.firstWhere((b) => b.id == id);
    final entries = [
      for (final u in (book['units'] as List).cast<Map<String, dynamic>>())
        ...(u['lessons'] as List).cast<Map<String, dynamic>>(),
    ];

    test('$id: the map points at real app lessons and covers all of them', () {
      expect((registry['books'] as List).map((b) => b['url']), contains(book['url']), reason: 'url in the registry');
      final covered = <String>{};
      for (final e in entries) {
        for (final key in (e['app'] as List).cast<String>()) {
          final m = RegExp(r'^u(\d+):l(\d+)$').firstMatch(key)!;
          final lessonKey = lessonId(sb, int.parse(m[1]!) - 1, int.parse(m[2]!) - 1);
          expect(schoolLessonAt(lessonKey), isNotNull, reason: '${e['title']} → $key');
          covered.add(lessonKey);
        }
      }
      final ready = {
        for (var u = 0; u < sb.units.length; u++)
          for (var l = 0; l < sb.units[u].lessons.length; l++)
            if (sb.units[u].lessons[l].ready || sb.units[u].lessons[l].explainOnly) lessonId(sb, u, l),
      };
      expect(ready.difference(covered), isEmpty, reason: 'app lessons missing from the map');
    });

    test('$id: each status matches the explanations that exist', () {
      for (final e in entries) {
        final keys = [
          for (final key in (e['app'] as List).cast<String>())
            () {
              final m = RegExp(r'^u(\d+):l(\d+)$').firstMatch(key)!;
              return lessonId(sb, int.parse(m[1]!) - 1, int.parse(m[2]!) - 1);
            }(),
        ];
        final found = [for (final k in keys) explained[k]];
        if (e['exam'] case final String u) {
          final exam = 'school:$id:$u';
          expect(schoolRound(exam)?.exam, isTrue, reason: '${e['title']} → $exam');
          expect(e['status'], 'exam_in_app', reason: e['title'] as String);
          continue;
        }
        final want = keys.isEmpty
            ? 'not_in_app'
            : found.every((c) => c != null)
                ? (found.every((c) => c!.review == LessonReview.reviewed) ? 'reviewed' : 'explained')
                : (found.any((c) => c != null) ? 'partly_explained' : 'indexed');
        expect(e['status'], want, reason: '${e['title']} — run: python3 tool/curriculum_status.py');
      }
    });
  }
}
