import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/content/guide_content.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/parent/guide_screen.dart';
import 'package:rehlati/features/quran/quran_check_screen.dart';

void main() {
  test('learning time is shown in minutes, then hours', () {
    expect(fmtTime(5 * 60000), '٥ دقيقة');
    expect(fmtTime(75 * 60000), '١ ساعة و١٥ دقيقة');
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
