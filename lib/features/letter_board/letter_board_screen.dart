import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../content/language_data.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/features.dart';
import '../../core/nav.dart';
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
  bool _done = false;

  Stage get pack => packs[widget.stageId]!;
  bool get en => pack.isEnglish;

  void _say(int i) {
    final it = pack.learnItems![i];
    en
        ? ref.read(speechProvider).speakEn('${it.letter} . ${it.word}')
        : ref.read(speechProvider).speak(sayLetter(it));
  }

  void _show(int i) {
    final items = pack.learnItems!;
    final progress = ref.read(progressProvider.notifier);
    progress.update((p) => p.markLearned(pack.id, items[i].letter));
    _say(i);
    _reveal(items[i]);

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

  /// كارت الحرف بيطلع فوق الشاشة (على الموبايل كان بيظهر تحت الجدول بره الشاشة):
  /// الحرف بينط، الصورة بتتمايل، والحرف ملوّن جوه الكلمة. أي ضغطة بتقفله.
  void _reveal(Letter it) {
    final dir = en ? TextDirection.ltr : TextDirection.rtl;
    final calm = MediaQuery.disableAnimationsOf(context);
    final at = it.word.indexOf(it.letter);
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: en ? 'Close' : 'اقفل',
      barrierColor: const Color(0x800C1C30),
      transitionDuration: 380.ms,
      transitionBuilder: (_, a, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: a, child: child),
      ),
      pageBuilder: (c, _, _) => GestureDetector(
        onTap: () => Navigator.of(c).pop(),
        child: Center(
          child: Container(
            width: c.clampVw(300, 80, 380),
            padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(36),
              border: Border.all(color: pack.color, width: 6),
              boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 12))],
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Directionality(
                textDirection: dir,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(it.letter, style: kidText(c.clampVw(96, 26, 140), color: pack.color, height: 1.1))
                      .animate()
                      .scaleXY(begin: .2, end: 1, delay: 120.ms, duration: 700.ms, curve: Curves.elasticOut),
                  calm
                      ? Text(it.emoji, style: TextStyle(fontSize: c.clampVw(64, 18, 90)))
                      : Text(it.emoji, style: TextStyle(fontSize: c.clampVw(64, 18, 90)))
                          .animate()
                          .moveY(begin: 40, end: 0, delay: 300.ms, duration: 500.ms, curve: Curves.easeOutBack)
                          .fadeIn(duration: 200.ms)
                          .then()
                          .shake(hz: 3, rotation: .08, duration: 700.ms),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(style: kidText(c.clampVw(30, 8, 40)), children: [
                      if (!en) TextSpan(text: '${it.letter} مثل '),
                      if (at < 0)
                        TextSpan(text: it.word)
                      else ...[
                        TextSpan(text: it.word.substring(0, at)),
                        TextSpan(text: it.letter, style: TextStyle(color: pack.color)),
                        TextSpan(text: it.word.substring(at + it.letter.length)),
                      ],
                    ]),
                  ).animate().fadeIn(delay: 500.ms, duration: 300.ms),
                  const SizedBox(height: 12),
                  Text(en ? 'Tap to close' : 'اضغط في أي مكان', style: kidText(13, color: AppColors.inkSoft)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = pack.learnItems!;
    final seen = ref.watch(progressProvider.select((p) => p.learned(pack.id).length));
    final learned = ref.read(progressProvider).learned(pack.id);
    final meta = worldMeta(pack.world);
    final dir = en ? TextDirection.ltr : TextDirection.rtl;

    return ScreenFrame(
      onBack: () => context.back(),
      title: pack.name,
      child: Column(children: [
        const SizedBox(height: 6),
        Banner3D('${pack.icon} ${pack.name}', color: pack.color, tone: meta.tone, ink: Colors.white),
        const SizedBox(height: 6),
        HeroText(voiceEnabled
            ? (en ? 'Tap a letter to hear it' : 'اضغط على أي حرف تسمعه')
            : (en ? 'Tap a letter to see it' : 'اضغط على أي حرف تشوفه')),
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
