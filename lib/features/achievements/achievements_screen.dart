import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/badges.dart';
import '../../domain/progress/progress_controller.dart';
import 'rank_widgets.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final got = ref.watch(progressProvider.select((p) => [...p.achievements]));
    final stars = ref.watch(progressProvider.select((p) => p.stars));
    Widget h3(String t) => Align(
          alignment: AlignmentDirectional.centerStart,
          child: Padding(padding: const EdgeInsets.only(top: 16, bottom: 8), child: Text(t, style: kidText(19))),
        );
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🏆 إنجازاتي',
      child: QCard(
        child: Column(children: [
          Text('🏆 إنجازاتي', style: kidText(26)),
          const SizedBox(height: 8),
          RankBar(stars: stars),
          h3('🏅 مراحل التقدّم'),
          CupsGrid(stars: stars),
          h3('⭐ الإنجازات'),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text('${ar(got.length)} من ${ar(badges.length)}',
                style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          BadgeGrid(earned: got),
        ]),
      ),
    );
  }
}

class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.earned, this.small = false});
  final List<String> earned;
  final bool small;

  @override
  Widget build(BuildContext context) => TileWrap(
        minTileWidth: small ? 84 : 100,
        children: [
          for (final b in badges)
            Opacity(
              opacity: earned.contains(b.id) ? 1 : .55,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: earned.contains(b.id) ? const Color(0x29FFC43D) : AppColors.paper2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: earned.contains(b.id) ? AppColors.gold : AppColors.line, width: 3),
                ),
                child: Column(children: [
                  Text(earned.contains(b.id) ? b.icon : '🔒', style: TextStyle(fontSize: small ? 24 : 30)),
                  const SizedBox(height: 4),
                  Text(b.name,
                      textAlign: TextAlign.center,
                      style: kidText(small ? 11 : 12.5, weight: FontWeight.w700, height: 1.35)),
                ]),
              ),
            ),
        ],
      );
}
