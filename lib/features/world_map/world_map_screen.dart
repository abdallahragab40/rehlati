import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/school.dart';
import '../../domain/stages.dart';
import '../parent/parent_gate.dart';
import '../scenes/world_scene.dart';

/// خريطة أي عالم — نفس الكود للحساب والعربي و English.
class WorldMapScreen extends ConsumerStatefulWidget {
  const WorldMapScreen({super.key, required this.world});
  final String world;

  @override
  ConsumerState<WorldMapScreen> createState() => _WorldMapScreenState();
}

class _WorldMapScreenState extends ConsumerState<WorldMapScreen> {
  String? _say;
  BubbleKind _sayKind = BubbleKind.no;
  int _sadTick = 0;

  /// عالم الألعاب: الألعاب اللي مش لسن الطفل مستخبية ورا زرار.
  bool _showAll = false;

  void _open(Stage s) {
    final p = ref.read(progressProvider);
    if (p.limitReached) {
      context.push('/timeup');
      return;
    }
    if (!p.isUnlocked(s.id)) {
      final en = widget.world == 'english';
      setState(() {
        _say = en ? 'This stage is locked 🔒 Finish the one before it first' : 'المرحلة دي مقفولة 🔒 خلّص اللي قبلها الأول';
        _sayKind = BubbleKind.no;
        _sadTick++;
      });
      ref.read(sfxProvider).bad();
      en
          ? ref.read(speechProvider).speakEn('This stage is locked. Finish the one before it first.')
          : ref.read(speechProvider).speak(sayLocked, clips: ['locked']);
      return;
    }
    context.push(stageRoute(s));
  }

  /// تخطّي مرحلة — لولي الأمر بس (سؤال الأهل الأول).
  Future<void> _skip(Stage s) async {
    if (!await askParent(context) || !mounted) return;
    ref.read(progressProvider.notifier).update((p) => p.skipStage(s.id));
    setState(() {
      _say = 'تمام ⏭️ اتخطّينا "${s.name}" وفتحنا اللي بعدها — وتفضل متاحة للعب';
      _sayKind = BubbleKind.ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meta = worldMeta(widget.world);
    final p = ref.watch(progressProvider);
    final all = worldStages[widget.world]!;
    // عالم الألعاب والسن معروف: المناسب لسنه الأول، والباقي ورا زرار "ألعاب تانية"
    final age = openWorlds.contains(widget.world) ? p.age : null;
    final fit = [for (final s in all) if (fitsAge(s, age)) s];
    final rest = [for (final s in all) if (!fitsAge(s, age)) s];
    final stages = [...fit, if (_showAll) ...rest];
    return ScreenFrame(
      onBack: () => context.back(),
      title: 'المستوى ${ar(p.level(widget.world))}',
      background: sceneBackground(widget.world),
      child: Column(children: [
        const SizedBox(height: 6),
        Banner3D(meta.title, color: meta.color, tone: meta.tone, ink: Colors.white),
        const SizedBox(height: 6),
        HeroText(widget.world == 'english' ? 'Pick a game and start' : 'اختار لعبة وابدأ المغامرة'),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Stack(children: [
            // المسار المتقطّع في النص
            Positioned.fill(
              child: Center(child: CustomPaint(size: const Size(14, double.infinity), painter: _PathPainter())),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 26),
              child: Column(children: [
                if (age != null) _GroupHeader('🎯 ألعاب مناسبة لسن ${ar(age)} ${yearsWord(age)}'),
                for (var i = 0; i < stages.length; i++) ...[
                  if (age != null && i == fit.length) ...[
                    _MoreGames(shown: true, count: rest.length, onTap: () => setState(() => _showAll = false)),
                    const _GroupHeader('🎮 ألعاب لسن تاني'),
                  ],
                  // عنوان مجموعة (زي المدود) بيظهر مرة قبل أول مرحلة فيها
                  if (stages[i].group != null &&
                      (i == 0 || i == fit.length || stages[i - 1].group != stages[i].group))
                    _GroupHeader(stages[i].groupName ?? ''),
                  // المراحل بتتعرّج يمين وشمال — عرض الكارت min(300, 86%)
                  LayoutBuilder(
                    builder: (context, box) => Align(
                      alignment: i.isEven ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
                      child: SizedBox(
                        width: (box.maxWidth * .86).clamp(0, 300),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _StageCard(
                            stage: stages[i],
                            number: i + 1,
                            open: p.isUnlocked(stages[i].id),
                            medals: p.best[stages[i].id] ?? 0,
                            skipped: p.skipped.contains(stages[i].id),
                            onTap: () => _open(stages[i]),
                            onSkip: p.canSkip(stages[i].id) ? () => _skip(stages[i]) : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (rest.isNotEmpty && !_showAll)
                  _MoreGames(shown: false, count: rest.length, onTap: () => setState(() => _showAll = true)),
              ]),
            ),
          ]),
        ),
        const _DevRow(),
        LionMascot(
          mood: _say == null ? LionMood.idle : (_sayKind == BubbleKind.ok ? LionMood.cheer : LionMood.sad),
          tick: _sadTick,
        ),
        if (_say != null) SpeechBubble(_say!, kind: _sayKind),
      ]),
    );
  }
}

class _PathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x99FFFFFF);
    for (var y = 0.0; y < size.height; y += 38) {
      canvas.drawRRect(RRect.fromLTRBR(0, y, 14, y + 20, const Radius.circular(7)), paint);
    }
  }

  @override
  bool shouldRepaint(_PathPainter oldDelegate) => false;
}

class _StageCard extends StatelessWidget {
  const _StageCard({
    required this.stage,
    required this.number,
    required this.open,
    required this.medals,
    required this.skipped,
    required this.onTap,
    this.onSkip,
  });
  final Stage stage;

  /// ترتيبها على الخريطة (عالم الألعاب بيقدّم المناسب للسن، فممكن يختلف عن [Stage.n]).
  final int number;
  final bool open;
  final int medals;

  /// ولي الأمر اتخطّاها — بتبان ⏭️ لحد ما الطفل ياخد فيها ميدالية.
  final bool skipped;
  final VoidCallback onTap;

  /// زرار ⏭️ لولي الأمر — null لو المرحلة مايتخطّاش.
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final card = Pressable3D(
      onTap: onTap,
      radius: 26,
      shadowColor: AppColors.shadow,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      semanticLabel: '${stage.name}${open ? '' : '، مقفولة'}${skipped && medals == 0 ? '، اتخطّت' : ''}',
      child: Row(children: [
        Container(
          width: 62,
          height: 62,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: stage.color, borderRadius: BorderRadius.circular(20)),
          child: Text(open ? stage.icon : '🔒', style: const TextStyle(fontSize: 30)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('المرحلة ${ar(number)}', style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft)),
            Directionality(
              textDirection: stage.isEnglish ? TextDirection.ltr : TextDirection.rtl,
              child: Text(stage.name, style: kidText(context.clampVw(17, 4.4, 21), height: 1.25)),
            ),
            if (medals == 0 && skipped)
              Text('⏭️ اتخطّت', style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft))
            else
              Text(medals > 0 ? '⭐' * medals : '☆☆☆', style: const TextStyle(fontSize: 14, letterSpacing: 1)),
          ]),
        ),
        if (onSkip != null) const SizedBox(width: 48),
      ]),
    );
    if (open && onSkip != null) {
      // فوق الكارت مش جواه — زرار لوحده لقارئ الشاشة وللمس، في المكان الفاضي آخر الصف
      return Stack(children: [
        card,
        PositionedDirectional(
          top: 0,
          bottom: 7,
          end: 10,
          child: Center(
            child: Pressable3D(
              onTap: onSkip,
              radius: 999,
              depth: 4,
              color: AppColors.paper2,
              shadowColor: AppColors.shadow,
              padding: const EdgeInsets.all(11),
              semanticLabel: 'تخطّي المرحلة — لولي الأمر',
              child: const Text('⏭️', style: TextStyle(fontSize: 22)),
            ),
          ),
        ),
      ]);
    }
    if (open) return card;
    // مقفولة: باهتة ورمادي (filter: saturate(.25))
    return Opacity(
      opacity: .75,
      child: ColorFiltered(colorFilter: ColorFilter.matrix(saturation(.25)), child: card),
    );
  }
}

/// "ألعاب تانية (١٢)" — الألعاب اللي سنها مختلف، مستخبية لحد ما حد يطلبها.
class _MoreGames extends StatelessWidget {
  const _MoreGames({required this.shown, required this.count, required this.onTap});
  final bool shown;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: KidButton(shown ? '🔼 خبّي الألعاب التانية' : '🎮 ألعاب تانية (${ar(count)})', kind: BtnKind.ghost, onTap: onTap),
      );
}

/// المسار اللي المرحلة بتفتح عليه: لوحة حروف، درس مدود، أو لعب على طول.
String stageRoute(Stage s) => s.isLearn ? '/learn/${s.id}' : (s.isMadd ? '/madd/${s.id}' : '/play/${s.id}');

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.name);
  final String name;

  @override
  Widget build(BuildContext context) => Container(
        width: 300,
        margin: const EdgeInsets.only(top: 6, bottom: 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 5))],
        ),
        child: Text(name, textAlign: TextAlign.center, style: kidText(context.clampVw(16, 4.4, 20))),
      );
}

/// مفتاح "فتح كل المراحل (للتطوير)" — بقى جوه شاشة المستوى زي الويب،
/// بس تشغيله بيسأل سؤال الأهل عشان الطفل مايدخلش مراحل أصعب من مستواه.
class _DevRow extends ConsumerWidget {
  const _DevRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dev = ref.watch(progressProvider.select((p) => p.settings.dev));
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xBFFFFFFF),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 4))],
      ),
      child: Row(children: [
        Expanded(child: Text('🔓 فتح كل المراحل (للتطوير)', style: kidText(15, color: AppColors.inkSoft))),
        Switch(
          value: dev,
          activeTrackColor: AppColors.grassDark,
          onChanged: (v) async {
            if (v && !await askParent(context)) return;
            ref.read(progressProvider.notifier).update((p) => p.settings.dev = v);
          },
        ),
      ]),
    );
  }
}
