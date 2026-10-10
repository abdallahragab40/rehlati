/// تقرير الأسبوع في لوحة ولي الأمر — منقول من weekCard في js/shell.js.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';

import '../../content/quran_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../journey/journey.dart';
import '../parent/dashboard_screen.dart' show fmtTime;
import '../profiles/profiles.dart' show childName;
import '../quran/quran_repository.dart';

/// اسم العالم في التقرير ('pg' = أنشطة دليل ولي الأمر).
String worldLabel(String id) => id == 'pg' ? '❤️ السلوكيات' : '${worldMeta(id).icon} ${worldMeta(id).name}';

/// أيام الأسبوع بترتيب DateTime.weekday (الإثنين = ١).
const _dayAr = ['إثنين', 'ثلاثاء', 'أربعاء', 'خميس', 'جمعة', 'سبت', 'أحد'];

int? _acc(({int stars, int correct, int wrong, int games, int ms, int days}) w) =>
    w.correct + w.wrong == 0 ? null : (w.correct / (w.correct + w.wrong) * 100).round();

/// اتحسّن في إيه ومحتاج إيه — بالمقارنة مع الأسبوع اللي فات، بس لو كان فيه تدريب كفاية.
(List<String>, List<String>) weekNotes(ProgressData p) {
  final now = p.weekSum(), prev = p.weekSum(1);
  final up = <String>[], need = <String>[];
  if (!enoughHistory(prev)) {
    up.add('لسه مفيش تدريب كفاية الأسبوع اللي فات عشان نقارن بيه');
    if (now.days > 0 && now.days < 4) need.add('اللعب كان ${ar(now.days)} أيام بس — المواظبة أهم من الوقت الطويل');
    return (up, need);
  }
  void cmp(String label, int a, int b) {
    if (a == 0 && b == 0) return;
    if (a > b * 1.1) {
      up.add('$label زادت (${ar(a)} بعد ${ar(b)})');
    } else if (b > 0 && a < b * .85) {
      need.add('$label قلّت (${ar(a)} بعد ${ar(b)})');
    }
  }

  cmp('النجوم', now.stars, prev.stars);
  cmp('الألعاب', now.games, prev.games);
  cmp('أيام اللعب', now.days, prev.days);
  final a1 = _acc(now), a0 = _acc(prev);
  if (a1 != null && a0 != null) {
    if (a1 >= a0 + 5) up.add('دقة الإجابات اتحسّنت (${ar(a1)}٪ بعد ${ar(a0)}٪)');
    if (a1 <= a0 - 5) need.add('دقة الإجابات نزلت (${ar(a1)}٪ بعد ${ar(a0)}٪)');
  }
  if (now.days < 4) need.add('اللعب كان ${ar(now.days)} أيام بس — المواظبة أهم من الوقت الطويل');
  return (up, need);
}

class WeekCard extends ConsumerWidget {
  const WeekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final days = p.week(), now = p.weekSum();
    final peak = math.max(1, days.map((d) => d.$2.stars).fold(0, math.max));
    final acc = _acc(now);
    final (up, need) = weekNotes(p);
    final small = kidText(11, color: AppColors.inkSoft);
    final empty = now.days == 0 && now.ms == 0;
    final byWorld = p.weekWorlds().entries.where((e) => e.value >= 30000).toList()..sort((a, b) => b.value - a.value);
    final due = [for (final id in p.dueForReview) ?packs[id]];
    final tips = practiceSuggestions(p);
    final names = {for (final c in ref.watch(quranChaptersProvider).value ?? const <QuranChapter>[]) c.number: c.name};

    Widget note(String text, Color bg, Color fg) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
          child: Text(text, style: kidText(14, weight: FontWeight.w700, color: fg, height: 1.7)),
        );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('تقرير ${childName(p)} — آخر ٧ أيام', style: kidText(16)),
        const SizedBox(height: 6),
        // نجوم كل يوم من آخر ٧ أيام
        Semantics(
          label: 'نجوم الأسبوع: ${days.map((d) => ar(d.$2.stars)).join('، ')}',
          child: ExcludeSemantics(
            child: SizedBox(
              height: 120,
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                for (final (d, log) in days)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: math.max(.04, log.stars / peak),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.grape.withValues(alpha: .85),
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              ),
                            ),
                          ),
                        ),
                        Text(log.stars > 0 ? ar(log.stars) : '', style: small),
                        Text(_dayAr[d.weekday - 1], style: small),
                      ]),
                    ),
                  ),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(spacing: 14, runSpacing: 8, children: [
          for (final t in [
            '⭐ ${ar(now.stars)} نجمة',
            '🎮 ${ar(now.games)} لعبة',
            '⏱️ ${fmtTime(now.ms)}',
            '📆 ${ar(now.days)} أيام نشاط',
            if (acc != null) '🎯 دقة من أول محاولة ${ar(acc)}٪',
          ])
            Text(t, style: kidText(14)),
        ]),
        if (byWorld.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('⏱️ ${[for (final e in byWorld) '${worldLabel(e.key)} ${fmtTime(e.value)}'].join(' • ')}', style: kidText(13.5)),
        ],
        if (due.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('🔁 جاهز للمراجعة: ${due.map((s) => '${s.icon} ${s.name}').join('، ')}', style: kidText(13.5)),
        ],
        if (empty)
          note('لسه مفيش نشاط في آخر ٧ أيام — أول جولة هتظهر هنا.', AppColors.paper, AppColors.inkSoft)
        else ...[
          note('✅ اتحسّن: ${up.isEmpty ? 'الأسبوع ماشي زي اللي قبله — تمام' : up.join(' • ')}',
              const Color(0xFFE4F7E8), const Color(0xFF1B6B2F)),
          note('💡 محتاج: ${need.isEmpty ? 'مفيش حاجة واضحة — كمّلوا كده' : need.join(' • ')}',
              const Color(0xFFFFF1D6), const Color(0xFF7A5200)),
        ],
        if (tips.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('🎯 تتدرّبوا على إيه دلوقتي', style: kidText(15)),
          for (final t in tips)
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
              decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(16)),
              child: Row(children: [
                Expanded(
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '${stepTitle(t, names)}\n', style: kidText(14.5)),
                    TextSpan(text: stepReason(t.kind), style: kidText(12.5, weight: FontWeight.w600, color: AppColors.inkSoft)),
                  ])),
                ),
                TextButton(
                  onPressed: () => context.push(stepRoute(t, journey: false)),
                  child: Text('تدرّب دلوقتي', style: kidText(14, color: AppColors.grape)),
                ),
              ]),
            ),
        ],
        const SizedBox(height: 8),
        Text('المجهود = الوقت وأيام النشاط • الإنجاز = النجوم والميداليات • الإتقان = مراجعات ناجحة على أيام متباعدة',
            style: kidText(12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        const SizedBox(height: 12),
        _Stepper(
          label: '🎯 هدف اليوم',
          value: '${ar(p.settings.goal)} ⭐',
          onMinus: () => ref.read(progressProvider.notifier).update((p) => p.settings.goal = (p.settings.goal - 5).clamp(5, 100)),
          onPlus: () => ref.read(progressProvider.notifier).update((p) => p.settings.goal = (p.settings.goal + 5).clamp(5, 100)),
        ),
        const SizedBox(height: 10),
        _Stepper(
          label: '⏱️ حد وقت اللعب',
          value: p.settings.limitMin == 0 ? 'مفيش' : '${ar(p.settings.limitMin)} دقيقة',
          onMinus: () =>
              ref.read(progressProvider.notifier).update((p) => p.settings.limitMin = (p.settings.limitMin - 5).clamp(0, 180)),
          onPlus: () =>
              ref.read(progressProvider.notifier).update((p) => p.settings.limitMin = (p.settings.limitMin + 5).clamp(0, 180)),
        ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onMinus, required this.onPlus});
  final String label, value;
  final VoidCallback onMinus, onPlus;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(child: Text(label, style: kidText(14, color: AppColors.inkSoft))),
          IconButton(onPressed: onMinus, icon: const Icon(Icons.remove), tooltip: 'أقل'),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 70),
            child: Text(value, textAlign: TextAlign.center, style: kidText(15)),
          ),
          IconButton(onPressed: onPlus, icon: const Icon(Icons.add), tooltip: 'أكتر'),
        ]),
      );
}
