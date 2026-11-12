import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/lesson_content.dart';
import 'package:rehlati/domain/question_key.dart';

import 'lesson_content_test.dart' show allLessonFiles;

/// النشاط بكل محتواه: السؤال والاختيارات والإجابة والمرئية.
String taskSig(LessonTask t) => [
      t.kind.name,
      t.ask.replaceAll(RegExp(r'\s+'), ' ').trim(),
      ([...t.choices]..sort()).join('|'),
      t.answer,
      ([...t.items]..sort()).join('|'),
      ([...t.answers]..sort()).join('|'),
      ([for (final (a, b) in t.pairs) '$a=$b']..sort()).join('|'),
      ([for (final (g, xs) in t.groups) '$g:${([...xs]..sort()).join(',')}']..sort()).join('|'),
      t.glyph,
      '${t.lo}-${t.hi}',
      if (t.visual case final v?) visualSig(v),
    ].join('§');

/// مفتاح متساهل للتنبيه بس: من غير تشكيل، والألف والهمزة والياء والتاء المربوطة موحّدة.
/// مابيدمجش حاجة — «الطيورَ» و«الطيورِ» سؤالين مختلفين، فالمراجع هو اللي يقرر.
String loose(String s) => s
    .replaceAll(RegExp('[ً-ْٰـ]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ى', 'ي')
    .replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[؟?!.،,:؛…«»"()\-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();

void main() {
  final lessons = allLessonFiles();
  final where = <String, List<String>>{};
  for (final l in lessons) {
    for (final t in l.tasks) {
      where.putIfAbsent(taskSig(t), () => []).add(l.uid);
    }
  }

  test('no activity is repeated word for word, in the same lesson or another one', () {
    final repeats = {for (final e in where.entries) if (e.value.length > 1) e.key.split('§')[1]: e.value};
    expect(repeats, isEmpty, reason: 'write a new activity for each lesson instead: $repeats');
  });

  test('activities that look alike once marks are removed are listed for a reviewer', () {
    final byLoose = <String, Set<String>>{};
    for (final sig in where.keys) {
      byLoose.putIfAbsent(loose(sig), () => {}).add(sig);
    }
    final similar = byLoose.values.where((s) => s.length > 1).toList();
    for (final s in similar) {
      // ignore: avoid_print
      print('looks alike, check by hand: ${s.map((x) => x.split('§')[1]).join(' / ')}');
    }
    // معلومة مش فشل: الاختلاف في الحركة بس ممكن يكون هو الدرس نفسه
    expect(similar.length, lessThan(20));
  });
}
