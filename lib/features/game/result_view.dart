import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/fx_layer.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
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
        if (r.unlocked != null) 'وفتحت مرحلة جديدة: ${r.unlocked!.name}',
        if (r.mistakes.isNotEmpty) 'تعالى نتدرب على الحاجات اللي محتاجة شوية تدريب',
      ], clips: [
        r.good ? 'well_done' : 'nice_try', 'got', nk(r.correct), 'of', nk(r.total),
        if (r.unlocked != null) 'unlocked',
        if (r.mistakes.isNotEmpty) 'practice',
      ]);
    });
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
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text('${ar(r.correct)} / ${ar(r.total)}',
                style: kidText(context.clampVw(52, 16, 86), color: AppColors.grape, height: 1.1)),
          ),
          Text('${'⭐' * r.correct}${'☆' * (r.total - r.correct)}',
              textAlign: TextAlign.center, style: TextStyle(fontSize: context.clampVw(20, 5.4, 28), letterSpacing: 3)),
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Text('نسبة النجاح ${ar(r.pct)}٪',
                style: kidText(context.clampVw(16, 4.2, 20), weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          if (unlocked != null)
            SpeechBubble('🔓 فتحت مرحلة جديدة: ${unlocked.icon} ${unlocked.name}', kind: BubbleKind.ok),
          if (r.mistakes.isNotEmpty) const SpeechBubble('تعالى نتدرب على الحاجات اللي محتاجة شوية تدريب ❤️'),
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
              KidButton('🗺️ الخريطة', kind: BtnKind.ghost, onTap: () => context.pop()),
            ],
          ),
        ],
      ),
    );
  }
}
