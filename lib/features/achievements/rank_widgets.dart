/// شريط الكأس وشبكة الكؤوس — منقولين من Rewards.rankBar و Rewards.screen في الويب.
library;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/ranks.dart';

/// الكأس الحالي، والتقدّم ناحية اللي بعده — في الرئيسية ولوحة ولي الأمر والإنجازات.
class RankBar extends StatelessWidget {
  const RankBar({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    final r = rankOf(stars), nx = nextRank(stars), pct = rankPct(stars);
    return Semantics(
      label: '${r.name}، ${nx == null ? 'أعلى مرحلة' : 'فاضل ${countOf(starsToNext(stars), starWord)} على ${nx.name}'}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(24),
            border: BorderDirectional(end: BorderSide(color: r.color, width: 8)),
            boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 6))],
          ),
          child: Row(children: [
            Container(
              width: 58,
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: Color.lerp(Colors.white, r.color, .16), borderRadius: BorderRadius.circular(18)),
              child: Text(r.icon, style: const TextStyle(fontSize: 34)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.name, style: kidText(context.clampVw(16, 4.2, 20), color: r.color)),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(value: pct / 100, minHeight: 11, color: r.color, backgroundColor: AppColors.line),
                ),
                const SizedBox(height: 4),
                Text(
                  nx != null
                      ? 'فاضل ${countOf(starsToNext(stars), starWord)} على ${nx.icon} ${nx.name}'
                      : 'وصلت لأعلى مرحلة — ما شاء الله 🎉',
                  style: kidText(12.5, weight: FontWeight.w700, color: AppColors.inkSoft),
                ),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

/// كل الكؤوس: اللي اتفتح باللون، والباقي مقفول بعدد نجومه.
class CupsGrid extends StatelessWidget {
  const CupsGrid({super.key, required this.stars});
  final int stars;

  @override
  Widget build(BuildContext context) {
    final got = rankIndex(stars);
    return TileWrap(minTileWidth: 96, children: [
      for (final (i, r) in ranks.indexed)
        Opacity(
          opacity: i <= got ? 1 : .55,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            decoration: BoxDecoration(
              color: i <= got ? Color.lerp(Colors.white, r.color, .12) : AppColors.paper2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: i <= got ? r.color : AppColors.line, width: 3),
            ),
            child: Column(children: [
              Text(i <= got ? r.icon : '🔒', style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 3),
              Text(r.name, textAlign: TextAlign.center, style: kidText(12.5, height: 1.35)),
              Text('${ar(r.at)} ⭐', style: kidText(11.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
            ]),
          ),
        ),
    ]);
  }
}
