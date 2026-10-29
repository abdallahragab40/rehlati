import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/guide_content.dart';
import 'package:rehlati/core/utils/arabic.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/parent/guide_screen.dart';
import 'package:rehlati/features/quran/quran_check_screen.dart';

void main() {
  test('learning time is shown in minutes, then hours', () {
    expect(fmtTime(5 * 60000), '٥ دقايق');
    expect(fmtTime(75 * 60000), 'ساعة و١٥ دقيقة');
    expect(fmtTime(120 * 60000), 'ساعتين');
  });

  test('skill labels drop the type prefix', () {
    expect(skillLabel('add:7+2'), '٧+٢');
    expect(skillLabel('ar_alphabet'), 'ar_alphabet');
  });

  test('guide bold markup alternates plain and bold spans', () {
    final span = richGuide('اضغط **جرّب** هنا', const TextStyle());
    final parts = span.children!.cast<TextSpan>();
    expect(parts.map((s) => s.text), ['اضغط ', 'جرّب', ' هنا']);
    expect(parts[1].style?.fontWeight, FontWeight.w800);
  });

  test('the guide\'s stage counts match the app', () {
    final text = [
      for (final s in guideSections)
        for (final b in s.body) ...switch (b) { GP(:final text) => [text], GList(:final items) => items },
    ].join('\n');
    for (final (w, word) in [('math', 'مرحلة'), ('arabic', 'مرحلة'), ('english', 'مرحلة'), ('games', 'لعبة'), ('deen', 'مراحل'), ('discover', 'مراحل'), ('write', 'مراحل')]) {
      expect(text, contains('${ar(worldStages[w]!.length)} $word'), reason: '$w has ${worldStages[w]!.length} stages');
    }
  });

  test('every guide section has a body and balanced bold markers', () {
    for (final s in guideSections) {
      expect(s.body, isNotEmpty, reason: s.title);
      final texts = [
        for (final b in s.body) ...switch (b) { GP(:final text) => [text], GList(:final items) => items },
      ];
      for (final t in texts) {
        expect('**'.allMatches(t).length.isEven, isTrue, reason: t);
      }
    }
  });

  test('quran check tells encoding differences from real ones', () {
    expect(compareAyah('أَلَمْ نَجْعَلِ', 'أَلَمْ نَجْعَلِ'), AyahMatch.exact);
    // نفس الحروف، علامة مختلفة (تنوين بميم صغيرة)
    expect(compareAyah('أَوْتَادًا', 'أَوْتَادًۭا'), AyahMatch.marksOnly);
    expect(compareAyah('أَوْتَادًا', 'أَوْتَارًا'), AyahMatch.different);
    expect(compareAyah('قُلْ هُوَ', 'قُلْ'), AyahMatch.different);
  });
}
