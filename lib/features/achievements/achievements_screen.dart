import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/badges.dart';
import '../../domain/progress/progress_controller.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final got = ref.watch(progressProvider.select((p) => [...p.achievements]));
    return ScreenFrame(
      onBack: () => context.pop(),
      title: '🏆 إنجازاتي',
      child: QCard(
        child: Column(children: [
          Text('🏆 إنجازاتي', style: kidText(26)),
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

/// شبكة الإنجازات — بتتعرض هنا وفي لوحة ولي الأمر.
class BadgeGrid extends StatelessWidget {
  const BadgeGrid({super.key, required this.earned, this.small = false});
  final List<String> earned;
  final bool small;

  @override
  Widget build(BuildContext context) => GridView.extent(
        maxCrossAxisExtent: small ? 96 : 120,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .9,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
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
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
