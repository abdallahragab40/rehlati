/// لوحة ولي الأمر: شرح دروس المدرسة — أتقن لوحده، شاف الشرح، محتاج مراجعة، ونشاط البيت.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../domain/lesson_content.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/school_lessons.dart';

class LessonsParentCard extends ConsumerWidget {
  const LessonsParentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final lessons = [...?ref.watch(lessonsProvider).value?.values];
    final body = kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft);
    final by = <LessonStatus, List<LessonContent>>{};
    for (final c in lessons) {
      by.putIfAbsent(lessonStatus(p, c), () => []).add(c);
    }
    int n(LessonStatus s) => by[s]?.length ?? 0;
    final activities = lessons.where((c) => p.lessonLogs[c.uid]?.activity == true).length;
    String where(LessonContent c) => '${schoolRound(c.id)?.book.subject == 'english' ? '🇬🇧' : '📖'} ${c.title}';

    if (lessons.every((c) => lessonStatus(p, c) == LessonStatus.none)) {
      return Text('لسه ماشافش شرح أي درس. الدروس اللي ليها شرح مكتوب عليها «📖 اشرح لي» في دروس المدرسة.', style: body);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('✅ أتقن لوحده: ${ar(n(LessonStatus.mastered))}', style: kidText(15)),
      Text('👀 شاف الشرح: ${ar(n(LessonStatus.watched))}', style: kidText(15)),
      Text('🔁 محتاج مراجعة: ${ar(n(LessonStatus.helped))}', style: kidText(15)),
      if (n(LessonStatus.started) > 0) Text('⏸️ بدأ ولسه ماخلّصش: ${ar(n(LessonStatus.started))}', style: kidText(15)),
      Text('🏠 عمل نشاط البيت: ${ar(activities)}', style: kidText(15)),
      if (by[LessonStatus.helped] case final review?) ...[
        const SizedBox(height: 6),
        Text('محتاج مراجعة: ${review.map(where).join(' • ')}', style: body),
      ],
      const SizedBox(height: 6),
      Text(
        '«أتقن لوحده» يعني حل «تأكد من فهمك» كله صح من أول مرة، أو جاب ٨٠٪ أو أكتر في تدريب الدرس. '
        '«محتاج مراجعة» يعني احتاج تلميحات في الشرح ولسه ماوصلش للـ ٨٠٪.',
        style: body,
      ),
    ]);
  }
}
