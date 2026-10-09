import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/math_data.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/fx_layer.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/engine/game_engine.dart';
import 'games_modes.dart';
import 'modes.dart';
import 'result_view.dart';

/// شاشة اللعب — بتبدأ جولة للمرحلة وبتعرض النتيجة في الآخر.
class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key, required this.stageId});
  final String stageId;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  final _keys = <String, GlobalKey>{};
  StreamSubscription<GameFx>? _sub;
  final _lionKey = GlobalKey();

  GlobalKey _keyFor(String anchor) => _keys.putIfAbsent(anchor, GlobalKey.new);

  @override
  void initState() {
    super.initState();
    final engine = ref.read(gameProvider.notifier);
    _sub = engine.fx.listen(_onFx);
    // الجولة بتبدأ بعد أول frame عشان الـ provider يكون جاهز
    WidgetsBinding.instance.addPostFrameCallback((_) => engine.start(widget.stageId));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  /// نفس UI.correct / UI.wrong في الويب: ومضة، نجوم، رسالة، كونفيتي.
  void _onFx(GameFx e) {
    final fx = ref.read(fxProvider);
    switch (e) {
      case FxCorrect(:final anchor, :final firstTry, :final streak):
        final at = FxController.centerOf(anchor == null ? _lionKey : _keys[anchor]);
        final big = firstTry && streak >= 3;
        fx
          ..flash(ok: true)
          ..burst(at, big ? 18 : (firstTry ? 10 : 5), big ? '🎉' : '⭐');
        if (firstTry) {
          fx
            ..popMsg(big ? '🔥 ${ar(streak)} على التوالي!' : ref.read(rngProvider).sample(praise), big: big)
            ..flyStars(at, n: big ? 3 : 1);
        }
        if (big) {
          fx
            ..confetti(26)
            ..sparkle(at);
        }
      case FxWrong(:final gentle):
        // المدود: تشجيع لطيف من غير ومضة حمرا
        if (gentle) {
          fx.popMsg('💪');
        } else {
          fx
            ..flash(ok: false)
            ..popMsg(ref.read(rngProvider).sample(const ['😔', '🙁', '💭']), sad: true);
        }
      case FxFill(:final anchor):
        fx.burst(FxController.centerOf(_keys[anchor]), 3, '✨');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(gameProvider);
    final engine = ref.read(gameProvider.notifier);
    ref.listen(gameProvider.select((s) => s?.timeUp ?? false), (_, up) {
      if (up) context.pushReplacement('/timeup');
    });
    if (s == null || s.timeUp) return ScreenFrame(onBack: () => context.back(), child: const SizedBox());

    final result = s.result;
    if (result != null) {
      return ScreenFrame(
        onBack: () => context.back(),
        title: s.stage.name,
        child: ResultView(result: result, engine: engine),
      );
    }

    return ScreenFrame(
      onBack: () => context.back(),
      title: 'المستوى ${ar(s.level)}',
      child: Column(
        children: [
          _Dots(s),
          // السباق والبازل برّه كارت السؤال عشان يفضلوا طول الجولة: العدّاء بيتحرك
          // لقدام فعلًا، والقطع اللي ظهرت ماتتعادش مع كل سؤال
          if (s.q.track || s.q.puzzle != null) _RoundProgress(s),
          QCard(
            key: ValueKey('q${s.idx}-${s.stage.id}'),
            shakeTick: s.shakeTick,
            child: QuestionBody(s: s, engine: engine, keyFor: _keyFor),
          ),
          const SizedBox(height: 6),
          LionMascot(key: _lionKey, mood: s.lion, tick: s.lionTick),
          SpeechBubble(s.bubble, kind: s.bubbleKind),
        ],
      ),
    );
  }
}

class _RoundProgress extends StatelessWidget {
  const _RoundProgress(this.s);
  final GameSession s;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 6))],
        ),
        child: s.q.track ? RaceTrack(s) : PuzzleGrid(pic: s.q.puzzle!, open: s.solved),
      );
}

class _Dots extends StatelessWidget {
  const _Dots(this.s);
  final GameSession s;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            for (var i = 0; i < s.total; i++)
              AnimatedScale(
                scale: i == s.idx ? 1.35 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: switch (s.dots[i]) {
                      DotState.done => AppColors.gold,
                      DotState.miss => AppColors.coral,
                      DotState.pending => i == s.idx ? AppColors.paper : const Color(0x8CFFFFFF),
                    },
                  ),
                ),
              ),
          ],
        ),
      );
}
