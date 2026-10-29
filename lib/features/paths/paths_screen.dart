/// مسارات التعلّم: قايمة المسارات، وأسابيع ودروس المسار للطفل، وكارت لوحة ولي الأمر.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/paths.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../parent/parent_gate.dart';
import '../world_map/world_map_screen.dart';

/// النشاط اتفتح من مسار؟ (الرجوع بيودّي للمسار، فالزرار بيقول كده)
bool fromPath(BuildContext context) => GoRouter.maybeOf(context)?.state.uri.queryParameters['from'] == 'path';

/// "درس ٣ من ١٦" أو "خلّصت المسار".
String pathStatus(LearningPath path, ProgressData p) {
  final cur = path.current(p);
  if (cur == null) return 'خلّصت المسار 🎉';
  return 'درس ${ar(path.lessons.indexOf(cur) + 1)} من ${ar(path.lessons.length)}';
}

class PathsScreen extends ConsumerWidget {
  const PathsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    return ScreenFrame(
      onBack: () => context.back(),
      title: 'مسارات التعلّم',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('🎒 مسارات التعلّم', textAlign: TextAlign.center, style: kidText(context.clampVw(24, 6.4, 30))),
          const SizedBox(height: 4),
          Text('درس صغير كل يوم، خطوة ورا خطوة',
              textAlign: TextAlign.center, style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          for (final path in learningPaths)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: worldMeta(path.world).color.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(children: [
                Text(path.icon, style: const TextStyle(fontSize: 40)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(path.name, style: kidText(19)),
                    Text(pathStatus(path, p), style: kidText(14, color: AppColors.inkSoft)),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: path.lessonsDone(p) / path.lessons.length,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(8),
                      color: worldMeta(path.world).tone,
                      backgroundColor: AppColors.paper,
                    ),
                  ]),
                ),
                const SizedBox(width: 10),
                KidButton(path.started(p) ? '▶️ كمّل' : '▶️ يلا',
                    kind: BtnKind.go, onTap: () => context.push('/path/${path.id}')),
              ]),
            ),
          const SizedBox(height: 4),
          Center(child: KidButton('🏠 الرئيسية', kind: BtnKind.ghost, onTap: () => context.go('/'))),
        ]),
      ),
    );
  }
}

class PathScreen extends ConsumerStatefulWidget {
  const PathScreen({super.key, required this.id});
  final String id;

  @override
  ConsumerState<PathScreen> createState() => _PathScreenState();
}

class _PathScreenState extends ConsumerState<PathScreen> {
  String? _say;

  /// تخطّي خطوة — لولي الأمر بس (سؤال الأهل الأول)، زي تخطّي مرحلة من الخريطة.
  Future<void> _skip(LearningPath path, Stage s) async {
    if (!await askParent(context) || !mounted) return;
    ref.read(progressProvider.notifier).update((p) => skipPathStep(p, path, s.id));
    setState(() => _say = 'تمام ⏭️ اتخطّينا "${s.name}" — وتفضل متاحة للعب');
  }

  @override
  Widget build(BuildContext context) {
    final path = pathById(widget.id)!;
    final p = ref.watch(progressProvider);
    final cur = path.current(p);
    return ScreenFrame(
      onBack: () => context.back(),
      title: path.name,
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('${path.icon} ${path.name}', textAlign: TextAlign.center, style: kidText(context.clampVw(24, 6.4, 30))),
          const SizedBox(height: 4),
          Text(pathStatus(path, p),
              textAlign: TextAlign.center, style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
          if (cur == null) ...[
            const SizedBox(height: 8),
            const LionMascot(emoji: '🏆', mood: LionMood.cheer),
          ],
          for (final (wi, w) in path.weeks.indexed) ...[
            const SizedBox(height: 14),
            Text('الأسبوع ${ar(wi + 1)}: ${w.title}', style: kidText(18)),
            const SizedBox(height: 6),
            for (final l in w.lessons)
              _LessonTile(
                path: path,
                lesson: l,
                done: path.lessonDone(p, l),
                current: identical(l, cur),
                progress: p,
                onGo: (stage) => context.push(p.limitReached ? '/timeup' : '${stageRoute(stage)}?from=path'),
                onSkip: (stage) => _skip(path, stage),
              ),
          ],
          if (_say != null) ...[
            const SizedBox(height: 6),
            SpeechBubble(_say!, kind: BubbleKind.ok),
          ],
          const SizedBox(height: 10),
          Center(child: KidButton('🏠 الرئيسية', kind: BtnKind.ghost, onTap: () => context.go('/'))),
        ]),
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.path,
    required this.lesson,
    required this.done,
    required this.current,
    required this.progress,
    required this.onGo,
    required this.onSkip,
  });
  final LearningPath path;
  final PathLesson lesson;
  final bool done, current;
  final ProgressData progress;
  final ValueChanged<Stage> onGo;

  /// ⏭️ لولي الأمر — الخطوة بتتحسب للدرس من غير ما الطفل يلعبها.
  final ValueChanged<Stage> onSkip;

  @override
  Widget build(BuildContext context) {
    final n = path.lessons.indexOf(lesson) + 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFE3F8EC) : (current ? const Color(0xFFFFF3CF) : AppColors.paper2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(done ? '✅' : (current ? ar(n) : '🔒'), style: kidText(22)),
          const SizedBox(width: 12),
          Expanded(child: Text(lesson.title, style: kidText(17, color: done || current ? AppColors.ink : AppColors.inkSoft))),
        ]),
        // الدرس الحالي بس بيورّي أنشطته — اللي بعده مقفول لحد ما ده يخلص
        if (current)
          for (final id in lesson.stages)
            if (packs[id] case final s?)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 34, top: 8),
                child: Row(children: [
                  Expanded(
                    child: Text(
                      '${path.stepDone(progress, lesson, id) ? '✅' : (path.stepSkipped(progress, lesson, id) ? '⏭️' : '⬜')} ${s.icon} ${s.name}',
                      style: kidText(16),
                    ),
                  ),
                  if (!path.stepDone(progress, lesson, id)) KidButton('▶️ يلا', kind: BtnKind.go, onTap: () => onGo(s)),
                  if (!path.stepDone(progress, lesson, id) && !path.stepSkipped(progress, lesson, id)) ...[
                    const SizedBox(width: 6),
                    Pressable3D(
                      onTap: () => onSkip(s),
                      radius: 999,
                      depth: 4,
                      color: AppColors.paper2,
                      shadowColor: AppColors.shadow,
                      padding: const EdgeInsets.all(11),
                      semanticLabel: 'تخطّي الخطوة — لولي الأمر',
                      child: const Text('⏭️', style: TextStyle(fontSize: 20)),
                    ),
                  ],
                ]),
              ),
      ]),
    );
  }
}

/// كارت لوحة ولي الأمر: فين الطفل في كل مسار، وهدف الأسبوع اللي هو فيه.
class PathsParentCard extends ConsumerWidget {
  const PathsParentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final body = kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final path in learningPaths)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${path.icon} ${path.name} (${path.ages}): ${pathStatus(path, p)}', style: kidText(15)),
            if (path.skippedCount(p) > 0) Text('⏭️ خطوات اتخطّيتها: ${ar(path.skippedCount(p))}', style: body),
            if (path.current(p) case final l?)
              Text('الأسبوع ${ar(path.weeks.indexOf(path.weekOf(l)) + 1)} — ${path.weekOf(l).goal}', style: body),
          ]),
        ),
      Text(
        'كل مسار ٤ أسابيع، ٤ دروس في الأسبوع. الدرس بيخلص لما الطفل ينجح (٨٠٪+) في كل نشاط فيه، '
        'والدروس بتتفتح بالترتيب. لو نشاط صعب قوي تقدر تتخطّاه بـ ⏭️ (بسؤال الأهل)، ويفضل متاح للعب.',
        style: body,
      ),
    ]);
  }
}
