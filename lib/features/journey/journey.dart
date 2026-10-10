/// "رحلة النهاردة": شاشة الطفل، وكارت ولي الأمر.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/quran_config.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/fx_layer.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../quran/quran_repository.dart';
import '../world_map/world_map_screen.dart';

/// النشاط اتفتح من الرحلة؟ (الرجوع بيودّي للرحلة، فالزرار بيقول كده)
bool fromJourney(BuildContext context) => GoRouter.maybeOf(context)?.state.uri.queryParameters['from'] == 'journey';

/// يعمل رحلة النهاردة لو لسه ما اتعملتش — السور المتأخرة بتدخل بس لو نصها على الجهاز.
Future<void> ensureTodayJourney(WidgetRef ref) async {
  final n = ref.read(progressProvider.notifier);
  if (n.data.todayJourney != null) return;
  final repo = ref.read(quranRepositoryProvider);
  final ready = <int>{
    for (final s in n.data.surahsNeedingReview)
      if (await repo.isCached(s)) s,
  };
  if (n.data.todayJourney != null) return;
  n.update((p) => p.journey = planJourney(
        p,
        day: ProgressData.dayKey(ProgressData.clock()),
        quranReady: ready,
        minutesLeft: p.limitLeft,
      ));
}

String stepRoute(JourneyStep s) {
  final stage = s.stage;
  final path = stage != null ? stageRoute(stage) : '/quran/${s.surah}/review';
  return '$path?from=journey';
}

/// اسم الخطوة للطفل.
String stepTitle(JourneyStep s, Map<int, String> surahNames) {
  if (s.stage case final st?) return '${st.icon} ${st.name}';
  return '📖 مراجعة ${surahNames[s.surah] ?? 'سورة رقم ${ar(s.surah ?? 0)}'}';
}

/// كلمة صغيرة للطفل جنب الخطوة.
String stepTag(StepKind k) => switch (k) {
      StepKind.start => 'أول خطوة 🌱',
      StepKind.warm => 'تسخين 🔥',
      StepKind.practice => 'تدريب 💪',
      StepKind.improve => 'تحسين ⭐',
      StepKind.fresh => 'جديد ✨',
      StepKind.quran => 'مراجعة 📖',
    };

/// ليه الخطوة دي اتختارت — لولي الأمر.
String stepReason(StepKind k) => switch (k) {
      StepKind.start => 'أول مرحلة متاحة — لسه مفيش تقدّم نختار منه',
      StepKind.warm => 'تسخين بمرحلة بيعرفها كويس (ميداليتين أو أكتر)',
      StepKind.practice => 'فيها أخطاء اتكررت — الأسئلة بترجّع المهارة الضعيفة تلقائيًا',
      StepKind.improve => 'اتلعبت ولسه ما خدتش ٣ ميداليات',
      StepKind.fresh => 'مرحلة اتفتحت ولسه ما اتلعبتش',
      StepKind.quran => 'السورة اتحفظت ولسه ما اتراجعتش، ونصها على الجهاز',
    };

Map<int, String> _surahNames(WidgetRef ref) =>
    {for (final c in ref.watch(quranChaptersProvider).value ?? const <QuranChapter>[]) c.number: c.name};

class JourneyScreen extends ConsumerStatefulWidget {
  const JourneyScreen({super.key});

  @override
  ConsumerState<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends ConsumerState<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ensureTodayJourney(ref);
      if (mounted) _celebrateOnce();
    });
  }

  /// الاحتفال بيظهر مرة واحدة لما الطفل يرجع للرحلة بعد آخر خطوة.
  void _celebrateOnce() {
    final j = ref.read(progressProvider).todayJourney;
    if (j == null || !j.complete || j.celebrated) return;
    ref.read(progressProvider.notifier).update((p) => p.todayJourney?.celebrated = true);
    ref.read(fxProvider)
      ..confetti(40)
      ..popMsg('🎉 خلّصت رحلة النهاردة!', big: true);
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    final j = p.todayJourney;
    final names = _surahNames(ref);
    return ScreenFrame(
      onBack: () => context.back(),
      title: 'رحلة النهاردة',
      child: QCard(
        child: j == null
            ? const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()))
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text('🧭 رحلة النهاردة', textAlign: TextAlign.center, style: kidText(context.clampVw(24, 6.4, 30))),
                const SizedBox(height: 4),
                Text(
                  j.steps.isEmpty
                      ? 'مفيش أنشطة للرحلة النهاردة — اطلب من بابا أو ماما يختاروا العوالم'
                      : j.complete
                          ? 'خلّصت كل الخطوات! ⭐ +${ar(Journey.bonusStars)}'
                          : 'خطوة ${ar(j.doneCount + 1)} من ${ar(j.steps.length)}',
                  textAlign: TextAlign.center,
                  style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 14),
                for (final (i, s) in j.steps.indexed)
                  _StepTile(
                    index: i,
                    step: s,
                    title: stepTitle(s, names),
                    current: identical(s, j.next),
                    onGo: () => context.push(p.limitReached ? '/timeup' : stepRoute(s)),
                  ),
                if (j.complete) ...[
                  const SizedBox(height: 6),
                  const LionMascot(emoji: '🏆', mood: LionMood.cheer),
                  const SpeechBubble('شاطر! تقدر تكمّل تلعب اللي تحبه من العوالم 🗺️', kind: BubbleKind.ok),
                ],
                const SizedBox(height: 10),
                Center(child: KidButton('🏠 الرئيسية', kind: BtnKind.ghost, onTap: () => context.go('/'))),
              ]),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({required this.index, required this.step, required this.title, required this.current, required this.onGo});
  final int index;
  final JourneyStep step;
  final String title;
  final bool current;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: step.done ? const Color(0xFFE3F8EC) : (current ? const Color(0xFFFFF3CF) : AppColors.paper2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(children: [
          Text(step.done ? '✅' : ar(index + 1), style: kidText(24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: kidText(18)),
              Text(stepTag(step.kind), style: kidText(13, color: AppColors.inkSoft)),
            ]),
          ),
          if (current) KidButton('▶️ يلا', kind: BtnKind.go, onTap: onGo),
        ]),
      );
}

/// كارت لوحة ولي الأمر: خطوات النهاردة وأسبابها، والعوالم اللي تدخل الرحلة.
class JourneyParentCard extends ConsumerWidget {
  const JourneyParentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final j = p.todayJourney;
    final names = _surahNames(ref);
    final body = kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (j == null)
        Text('الرحلة بتتعمل أول ما الطفل يفتحها النهاردة، من المراحل المفتوحة بس.', style: body)
      else if (j.steps.isEmpty)
        Text('مفيش مراحل متاحة في العوالم المختارة.', style: body)
      else
        for (final s in j.steps)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text.rich(TextSpan(children: [
              TextSpan(text: '${s.done ? '✅' : '⏳'} ${stepTitle(s, names)}\n', style: kidText(15.5)),
              TextSpan(text: stepReason(s.kind), style: body),
            ])),
          ),
      const SizedBox(height: 8),
      Text('العوالم اللي تدخل الرحلة:', style: kidText(15)),
      const SizedBox(height: 4),
      Wrap(spacing: 6, runSpacing: 4, children: [
        for (final w in journeyWorlds)
          FilterChip(
            label: Text('${worldMeta(w).icon} ${worldMeta(w).name}'),
            selected: !p.settings.journeyOff.contains(w),
            onSelected: (on) => ref.read(progressProvider.notifier).update((p) {
              on ? p.settings.journeyOff.remove(w) : p.settings.journeyOff.add(w);
              // لو لسه ما بدأش رحلة النهاردة، نعيد تخطيطها بالعوالم الجديدة
              if (p.todayJourney?.doneCount == 0) p.journey = null;
            }),
          ),
      ]),
      const SizedBox(height: 6),
      Text('السور المتأخرة في المراجعة بتدخل الرحلة بس لو نصها متنزّل على الجهاز.', style: body),
    ]);
  }
}
