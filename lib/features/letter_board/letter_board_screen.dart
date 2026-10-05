import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/stages.dart';

/// شاشة تعلّم الحروف — يستخدمها العربي و English بنفس الكود.
class LetterBoardScreen extends ConsumerStatefulWidget {
  const LetterBoardScreen({super.key, required this.stageId});
  final String stageId;

  @override
  ConsumerState<LetterBoardScreen> createState() => _LetterBoardScreenState();
}

class _LetterBoardScreenState extends ConsumerState<LetterBoardScreen> {
  int? _shown;
  bool _done = false;

  Stage get pack => packs[widget.stageId]!;
  bool get en => pack.isEnglish;

  void _say(int i) {
    final it = pack.learnItems![i];
    en
        ? ref.read(speechProvider).speakEn('${it.letter} . ${it.word}')
        : ref.read(speechProvider).speak('${it.letter} . ${it.letter} مثل ${it.word}');
  }

  void _show(int i) {
    final items = pack.learnItems!;
    final progress = ref.read(progressProvider.notifier);
    progress.update((p) => p.markLearned(pack.id, items[i].letter));
    setState(() => _shown = i);
    _say(i);

    // نجمة لما يخلص كل الحروف — مرة واحدة
    final p = progress.data;
    if (p.learned(pack.id).length >= items.length && (p.best[pack.id] ?? 0) == 0) {
      progress.update((p) => p
        ..addResult(pack.id, 1, 1)
        ..addStar(3, pack.world)
        ..unlockNext(pack.id));
      ref.read(sfxProvider).win();
      setState(() => _done = true);
      progress.checkRewards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = pack.learnItems!;
    final seen = ref.watch(progressProvider.select((p) => p.learned(pack.id).length));
    final learned = ref.read(progressProvider).learned(pack.id);
    final meta = worldMeta(pack.world);
    final dir = en ? TextDirection.ltr : TextDirection.rtl;
    final shown = _shown == null ? null : items[_shown!];

    return ScreenFrame(
      onBack: () => context.pop(),
      title: pack.name,
      child: Column(children: [
        const SizedBox(height: 6),
        Banner3D('${pack.icon} ${pack.name}', color: pack.color, tone: meta.tone, ink: Colors.white),
        const SizedBox(height: 6),
        HeroText(en ? 'Tap a letter to hear it' : 'اضغط على أي حرف تسمعه'),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Directionality(
            textDirection: dir,
            child: GridView.extent(
              maxCrossAxisExtent: 78,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (var i = 0; i < items.length; i++)
                  Pressable3D(
                    onTap: () => _show(i),
                    radius: 20,
                    depth: 5,
                    color: learned.contains(items[i].letter) ? AppColors.mint : AppColors.paper,
                    shadowColor: learned.contains(items[i].letter) ? const Color(0xFF1C8E7F) : AppColors.shadow,
                    child: Center(
                      child: Text(items[i].letter,
                          style: kidText(context.clampVw(26, 7, 36),
                              color: learned.contains(items[i].letter) ? Colors.white : AppColors.ink)),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (shown != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: QCard(
              key: ValueKey(_shown),
              child: Directionality(
                textDirection: dir,
                child: Column(children: [
                  Text(shown.letter, style: kidText(context.clampVw(76, 22, 130), height: 1.1)),
                  Text(shown.emoji, style: TextStyle(fontSize: context.clampVw(50, 14, 80), height: 1.2)),
                  Padding(
                    padding: const EdgeInsets.only(top: 6, bottom: 12),
                    child: Text(en ? shown.word : '${shown.letter} مثل ${shown.word}',
                        style: kidText(context.clampVw(20, 5.4, 28))),
                  ),
                  KidButton(en ? '🔊 Listen' : '🔊 اسمع', onTap: () => _say(_shown!)),
                ]),
              ),
            ),
          ),
        SpeechBubble(
          _done
              ? (en ? 'All letters done! ⭐' : 'خلّصت كل الحروف! ⭐')
              : (en ? '${ar(seen)} / ${ar(items.length)} letters' : 'اتعلمت ${ar(seen)} من ${ar(items.length)} حرف'),
          kind: _done ? BubbleKind.ok : BubbleKind.plain,
        ).animate(key: ValueKey(_done)).fadeIn(),
      ]),
    );
  }
}
