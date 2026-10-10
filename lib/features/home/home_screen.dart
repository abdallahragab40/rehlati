import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion.dart';
import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/badges.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../achievements/rank_widgets.dart';
import '../parent/avatar.dart';
import '../profiles/profiles.dart';

/// خريطة الرحلة — الصفحة الرئيسية (Shell.home).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(progressProvider).setupDone) ref.read(speechProvider).speak(sayWelcome, clips: ['welcome']);
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    if (!p.setupDone) return const SetupScreen();
    final siblings = ref.watch(childrenProvider).length > 1;
    return ScreenFrame(
      title: 'المستوى ${ar(p.level())}',
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Banner3D('رحلتي التعليمية'),
          const SizedBox(height: 14),
          // الصورة جنب التحية والسطر اللي تحتها — مجموعة واحدة في النص
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: siblings ? () => showChildPicker(context) : null,
                child: Semantics(
                  button: siblings,
                  label: siblings ? 'غيّر الطفل' : null,
                  child: Stack(clipBehavior: Clip.none, children: [
                    ChildAvatar(size: context.clampVw(76, 22, 104)),
                    if (siblings)
                      const PositionedDirectional(
                        bottom: -4,
                        end: -4,
                        child: CircleAvatar(radius: 15, backgroundColor: AppColors.paper, child: Text('🔄', style: TextStyle(fontSize: 15))),
                      ),
                  ]),
                ),
              ),
              SizedBox(width: context.clampVw(14, 3.5, 20)),
              Flexible(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أهلاً يا ${p.name.isNotEmpty ? p.name : 'بطل'}!',
                      style: kidText(context.clampVw(24, 6.4, 34), color: Colors.white, height: 1.3)
                          .copyWith(shadows: const [Shadow(color: Color(0x4D1B3557), offset: Offset(0, 3))]),
                    ),
                    const HeroText('اختار عالم وابدأ المغامرة', align: TextAlign.start),
                  ],
                ),
              ),
            ],
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(children: [
              const SizedBox(height: 16),
              _DailyStrip(p),
              const SizedBox(height: 12),
              _JourneyButton(p),
              const SizedBox(height: 12),
              RankBar(stars: p.stars),
              const SizedBox(height: 18),
              // كروت العوالم: عمودين، وعمود واحد على الموبايلات الضيقة
              LayoutBuilder(
                builder: (context, box) => TileWrap(
                  minTileWidth: box.maxWidth <= 430 ? box.maxWidth : 260,
                  maxColumns: 2,
                  spacing: context.clampVw(10, 2.5, 16),
                  children: [
                    for (final (i, w) in worlds.indexed)
                      _WorldCard(
                        world: w,
                        stars: p.starsIn(w.id),
                        pct: p.worldPct(w.id),
                        narrow: box.maxWidth <= 430,
                        // خلص وقت اللعب النهاردة ← شاشة الراحة
                        onTap: () => context.push(p.limitReached ? '/timeup' : (w.id == 'quran' ? '/quran' : '/world/${w.id}')),
                      )
                          // الكروت بتدخل واحد ورا التاني
                          .anim()
                          .fadeIn(delay: (150 + i * 110).ms, duration: 250.ms)
                          .slideY(begin: .35, end: 0, duration: 520.ms, curve: Curves.easeOutBack),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('🏆 إنجازاتي (${ar(p.achievements.length)} / ${ar(badges.length)})',
                kind: BtnKind.ghost, onTap: () => context.push('/achievements')),
            KidButton('🧒 أتعلم أتصرف إزاي؟', kind: BtnKind.ghost, onTap: () => context.push('/pg/kids')),
          ]),
          const SizedBox(height: 8),
          const LionMascot(),
        ],
      ),
    );
  }
}

/// زرار "رحلة النهاردة" — بيورّي الطفل وصل لفين فيها.
class _JourneyButton extends StatelessWidget {
  const _JourneyButton(this.p);
  final ProgressData p;

  @override
  Widget build(BuildContext context) {
    final j = p.todayJourney;
    final status = j == null || j.steps.isEmpty
        ? ''
        : j.complete
            ? ' ✅'
            : ' (${ar(j.doneCount)} / ${ar(j.steps.length)})';
    return KidButton('🧭 رحلة النهاردة$status',
        kind: BtnKind.go, onTap: () => context.push(p.limitReached ? '/timeup' : '/journey'));
  }
}

/// الهدف اليومي + سلسلة الأيام — فوق كروت العوالم.
class _DailyStrip extends StatelessWidget {
  const _DailyStrip(this.p);
  final ProgressData p;

  @override
  Widget build(BuildContext context) {
    final st = p.streak, goal = p.settings.goal, got = p.todayStars, left = p.limitLeft;
    final note = p.goalDone
        ? '🎉 خلّصت هدف النهاردة — أي نجمة زيادة مكسب!'
        : 'فاضل ${ar((goal - got).clamp(0, goal))} نجمة';
    return Semantics(
      label: 'سلسلة ${ar(st)} يوم، هدف اليوم ${ar(got)} من ${ar(goal)} نجمة',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 6))],
          ),
          child: IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                constraints: const BoxConstraints(minWidth: 86, maxWidth: 110),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: st > 0 ? const Color(0xFFFFE8D6) : AppColors.paper2,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(st > 0 ? '🔥' : '🌱', style: const TextStyle(fontSize: 26, height: 1)),
                  Text(ar(st), style: kidText(26, height: 1.1)),
                  Text('${st == 1 ? 'يوم' : 'أيام'} متتالية',
                      textAlign: TextAlign.center, style: kidText(11.5, color: AppColors.inkSoft)),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    Expanded(child: Text('🎯 هدف اليوم', style: kidText(14.5))),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text('${ar(got)} / ${ar(goal)} ⭐', style: kidText(14.5)),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: p.goalPct / 100,
                      minHeight: 14,
                      color: p.goalDone ? AppColors.mint : AppColors.gold,
                      backgroundColor: AppColors.line,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('$note${left != null ? ' • باقي ${ar(left)} دقيقة لعب' : ''}',
                      style: kidText(12.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// كارت عالم أفقي ومضغوط: أيقونة جنب النص، وشريط لون على الطرف.
class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world, required this.stars, required this.pct, required this.onTap, this.narrow = false});
  final WorldMeta world;
  final int stars;
  final int pct;
  final bool narrow;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: 24,
        depth: 6,
        shadowColor: AppColors.shadow,
        border: BorderDirectional(end: BorderSide(color: world.color, width: 8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        semanticLabel: '${world.name}، ${ar(stars)} نجمة، ${ar(pct)}٪',
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: world.color, borderRadius: BorderRadius.circular(17)),
            child: MediaQuery.disableAnimationsOf(context)
                ? Text(world.icon, style: const TextStyle(fontSize: 27))
                // الأيقونة بتطفو وتتمايل بهدوء — كل عالم بسرعته عشان مايتحركوش زي بعض
                : Text(world.icon, style: const TextStyle(fontSize: 27))
                    .anim(onPlay: (c) => c.repeat(reverse: true))
                    .moveY(begin: -3, end: 3, duration: (1300 + world.id.length * 90).ms, curve: Curves.easeInOut)
                    .rotate(begin: -.02, end: .02, duration: (1300 + world.id.length * 90).ms),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(world.name, style: kidText(context.clampVw(17, 4, 21), height: 1.2)),
              const SizedBox(height: 2),
              Text(world.desc,
                  maxLines: narrow ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: kidText(context.clampVw(11.5, 2.9, 13.5), weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.4)),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(value: pct / 100, minHeight: 7, color: world.color, backgroundColor: AppColors.line),
              ),
            ]),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFFFF3CF), borderRadius: BorderRadius.circular(999)),
            child: Text('⭐ ${ar(stars)}', style: kidText(13, color: const Color(0xFF7A5200))),
          ),
        ]),
      );
}
