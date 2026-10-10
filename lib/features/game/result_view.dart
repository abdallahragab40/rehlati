import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../journey/journey.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/fx_layer.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/progress/progress_controller.dart';
import '../parent/avatar.dart';
import '../world_map/world_map_screen.dart';

/// شاشة النتيجة: الدرجة، النجوم، المرحلة اللي اتفتحت، والتدريب على الأخطاء.
class ResultView extends ConsumerStatefulWidget {
  const ResultView({super.key, required this.result, required this.engine});
  final GameResult result;
  final GameEngine engine;

  @override
  ConsumerState<ResultView> createState() => _ResultViewState();
}

class _ResultViewState extends ConsumerState<ResultView> {
  GameResult get r => widget.result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fx = ref.read(fxProvider);
      if (r.good) {
        fx
          ..confetti(60)
          ..popMsg('🎉 أحسنت!', big: true);
      } else {
        fx.confetti(10);
      }
      ref.read(speechProvider).speak([
        r.good ? 'أحسنت يا بطل' : 'محاولة حلوة، نجرب تاني',
        'جبت ${arNum(r.correct)} من ${arNum(r.total)}',
        if (r.unlocked != null) sayUnlocked(r.unlocked!.name),
        if (r.mistakes.isNotEmpty) 'تعالى نتدرب على الحاجات اللي محتاجة شوية تدريب',
      ], clips: [
        r.good ? 'well_done' : 'nice_try', 'got', nk(r.correct), 'of', nk(r.total),
        if (r.unlocked != null) 'unlocked',
        if (r.mistakes.isNotEmpty) 'practice',
      ]);
      _goal();
    });
  }

  /// هدف اليوم اتحقق لأول مرة النهاردة — احتفال صغير مرة واحدة بس.
  void _goal() {
    var first = false;
    ref.read(progressProvider.notifier).update((p) => first = p.celebrateGoal());
    if (!first) return;
    final streak = ref.read(progressProvider).streak;
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      ref.read(fxProvider)
        ..confetti(70)
        ..popMsg('🎯 خلّصت هدف النهاردة! 🔥 ${ar(streak)} يوم', big: true);
    });
    // الويب بينطقها فوق إعلان النتيجة؛ هنا بنستنى الإعلان يخلص
    final speech = ref.read(speechProvider);
    void after() {
      if (speech.speaking.value) return;
      speech.speaking.removeListener(after);
      if (mounted) speech.speak(sayGoalDone);
    }
    speech.speaking.addListener(after);
  }

  @override
  Widget build(BuildContext context) {
    final unlocked = r.unlocked;
    return QCard(
      child: Column(
        children: [
          if (r.good)
            const ChildAvatar(size: 130)
                .animate()
                .moveY(begin: 0, end: -26, duration: 190.ms)
                .then()
                .moveY(begin: 0, end: 26, duration: 360.ms, curve: Curves.bounceOut)
          else
            const LionMascot(emoji: '🐣', mood: LionMood.cheer),
          const SizedBox(height: 6),
          Text(r.good ? 'أحسنت يا بطل! 🎉' : 'كمان شوية ومتقنها 💪',
              textAlign: TextAlign.center, style: kidText(context.clampVw(24, 6.4, 34))),
          if (!r.practice) _Medals(r.correct == r.total ? 3 : (r.good ? 2 : 1)),
          Directionality(
            textDirection: TextDirection.ltr,
            // الدرجة بتعدّ من صفر لحد النتيجة
            child: TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: r.correct),
              duration: Duration(milliseconds: 250 + r.correct * 90),
              builder: (_, v, _) => Text('${ar(v)} / ${ar(r.total)}',
                  style: kidText(context.clampVw(52, 16, 86), color: AppColors.grape, height: 1.1)),
            ),
          ),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Wrap(alignment: WrapAlignment.center, spacing: 2, children: [
              for (var i = 0; i < r.total; i++)
                Text(i < r.correct ? '⭐' : '☆', style: TextStyle(fontSize: context.clampVw(20, 5.4, 28)))
                    .animate()
                    .scaleXY(delay: (300 + i * 90).ms, begin: 0, end: 1, duration: 450.ms, curve: Curves.elasticOut),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text('نسبة النجاح ${ar(r.pct)}٪',
                style: kidText(context.clampVw(16, 4.2, 20), weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          if (unlocked != null)
            SpeechBubble('🔓 فتحت مرحلة جديدة: ${unlocked.icon} ${unlocked.name}', kind: BubbleKind.ok),
          if (r.mistakes.isNotEmpty) const SpeechBubble('تعالى نتدرب على الحاجات اللي محتاجة شوية تدريب ❤️'),
          // جولتين صعاب ورا بعض ← المحرك بيبدأ الجولة الجاية من أسهل مستوى
          if (!r.practice && ref.watch(progressProvider).struggling(r.stage.id))
            const SpeechBubble('المرة الجاية هنبدأ أسهل شوية — خطوة خطوة ❤️'),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              if (r.mistakes.isNotEmpty) KidButton('❤️ تدريب على الأخطاء', kind: BtnKind.train, onTap: widget.engine.trainMistakes),
              KidButton('🔁 العب تاني', onTap: widget.engine.replay),
              if (unlocked != null)
                KidButton('▶️ المرحلة التالية', kind: BtnKind.go, onTap: () => context.pushReplacement(stageRoute(unlocked))),
              fromJourney(context)
                  ? KidButton('🧭 كمّل الرحلة', kind: BtnKind.go, onTap: () => context.back())
                  : KidButton('🗺️ الخريطة', kind: BtnKind.ghost, onTap: () => context.back()),
            ],
          ),
        ],
      ),
    );
  }
}

/// ميداليات الجولة (١–٣): بتنزل واحدة ورا التانية، والمكسوبة بتلمع.
class _Medals extends StatelessWidget {
  const _Medals(this.won);
  final int won;

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(44, 12, 60);
    return Semantics(
      label: '${ar(won)} من ${ar(3)} ميداليات',
      child: ExcludeSemantics(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 1 ? 14 : 0), // اللي في النص أعلى شوية
              child: (i < won
                      ? Text('🏅', style: TextStyle(fontSize: size))
                          .animate()
                          .shimmer(delay: (1400 + i * 260).ms, duration: 900.ms, color: Colors.white70)
                      : Opacity(
                          opacity: .35,
                          child: ColorFiltered(
                            colorFilter: ColorFilter.matrix(saturation(0)),
                            child: Text('🏅', style: TextStyle(fontSize: size)),
                          ),
                        ))
                  .animate()
                  .moveY(delay: (600 + i * 260).ms, begin: -60, end: 0, duration: 550.ms, curve: Curves.bounceOut)
                  .fadeIn(duration: 150.ms)
                  .rotate(begin: -.08, end: 0, duration: 550.ms),
            ),
        ]),
      ),
    );
  }
}
