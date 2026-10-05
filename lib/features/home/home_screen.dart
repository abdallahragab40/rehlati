import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/badges.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/stages.dart';
import '../parent/avatar.dart';

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
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(speechProvider).speak('أهلاً يا بطل! اختار عالم وابدأ المغامرة', clips: ['welcome']),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    return ScreenFrame(
      title: 'المستوى ${ar(p.level())}',
      child: Column(
        children: [
          const SizedBox(height: 6),
          const Banner3D('رحلتي التعليمية'),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 14,
            runSpacing: 8,
            children: [
              ChildAvatar(size: context.clampVw(76, 22, 104)),
              Text(
                'أهلاً يا ${p.name.isNotEmpty ? p.name : 'بطل'}!',
                style: kidText(context.clampVw(22, 6, 32), color: Colors.white)
                    .copyWith(shadows: const [Shadow(color: Color(0x4D1B3557), offset: Offset(0, 3))]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const HeroText('اختار عالم وابدأ المغامرة'),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: _JourneyNode('🏠 البداية')),
                  for (final w in worlds) ...[
                    const _JourneyLine(),
                    _WorldCard(
                      world: w,
                      stars: p.starsIn(w.id),
                      pct: p.worldPct(w.id),
                      onTap: () => context.push(w.id == 'quran' ? '/quran' : '/world/${w.id}'),
                    ),
                  ],
                ],
              ),
            ),
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

class _JourneyNode extends StatelessWidget {
  const _JourneyNode(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [BoxShadow(color: AppColors.goldDark, offset: Offset(0, 5))],
        ),
        child: Text(text, style: kidText(17, color: const Color(0xFF4A2B00))),
      );
}

class _JourneyLine extends StatelessWidget {
  const _JourneyLine();

  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 8,
          height: 22,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(color: const Color(0x8CFFFFFF), borderRadius: BorderRadius.circular(99)),
        ),
      );
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world, required this.stars, required this.pct, required this.onTap});
  final WorldMeta world;
  final int stars;
  final int pct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: 28,
        depth: 8,
        shadowColor: AppColors.shadow,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        semanticLabel: '${world.name}، ${ar(stars)} نجمة',
        child: Row(children: [
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: world.color, borderRadius: BorderRadius.circular(24)),
            child: Text(world.icon, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(world.name, style: kidText(context.clampVw(20, 5.2, 25), height: 1.25)),
              Text(world.desc,
                  style: kidText(context.clampVw(13, 3.4, 16), weight: FontWeight.w600, color: AppColors.inkSoft)),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: pct / 100,
                  minHeight: 8,
                  color: world.color,
                  backgroundColor: AppColors.line,
                ),
              ),
            ]),
          ),
          const SizedBox(width: 12),
          Text('⭐ ${ar(stars)}', style: kidText(15, color: AppColors.inkSoft)),
        ]),
      );
}
