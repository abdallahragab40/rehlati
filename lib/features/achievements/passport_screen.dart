/// جواز رحلتي: صفحة لكل عالم وفيها أختامه. الختم الجاي مكتوب تحته الطفل محتاج إيه عشان ياخده،
/// والصفحة بتفتح العالم نفسه.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/passport.dart';
import '../../domain/progress/progress_controller.dart';
import '../profiles/profiles.dart' show childName;

class PassportScreen extends ConsumerWidget {
  const PassportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final pages = passport(p);
    return ScreenFrame(
      onBack: () => context.back(),
      title: '🛂 جواز رحلتي',
      child: QCard(
        child: Column(children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1F4E8C), Color(0xFF2B6CB0)]),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(children: [
              Text('🛂 جواز رحلتي', style: kidText(26, color: AppColors.gold)),
              Text(childName(p), style: kidText(22, color: Colors.white)),
              const SizedBox(height: 4),
              Text('${countOf(stampCount(p), stampWord)} من ${ar(stampTotal)}',
                  style: kidText(15, weight: FontWeight.w700, color: const Color(0xFFCFE3FF))),
            ]),
          ),
          const SizedBox(height: 10),
          Text('كل عالم بلد في رحلتك — العب فيه وخد أختامه 🌍',
              textAlign: TextAlign.center, style: kidText(16, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 10),
          TileWrap(minTileWidth: 150, maxColumns: 3, children: [for (final page in pages) _Page(page)]),
        ]),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.page);
  final PassportPage page;

  @override
  Widget build(BuildContext context) {
    final w = page.world;
    final next = page.stamps < stampAt.length ? stampAt[page.stamps] : null;
    return Pressable3D(
      onTap: () => context.push(w.id == 'quran' ? '/quran' : '/world/${w.id}'),
      color: const Color(0xFFFFFBEF),
      radius: 20,
      depth: 5,
      shadowColor: AppColors.shadow,
      semanticLabel: '${w.name}، ${ar(page.stamps)} من ${ar(stampAt.length)} أختام',
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      child: ExcludeSemantics(
        child: Column(children: [
          Text('${w.icon} ${w.name}', textAlign: TextAlign.center, style: kidText(16, color: w.tone)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < stampAt.length; i++)
              Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: _Stamp(w.icon, w.color, i, got: i < page.stamps)),
          ]),
          const SizedBox(height: 6),
          Text(
            next == null ? '🏅 أتقنتها!' : (page.stamps == 0 ? 'العب أول مرحلة' : 'الختم الجاي عند ${ar(next)}٪'),
            textAlign: TextAlign.center,
            style: kidText(12.5, weight: FontWeight.w700, color: AppColors.inkSoft),
          ),
          Text('${ar(page.pct)}٪', style: kidText(12, weight: FontWeight.w600, color: AppColors.inkSoft)),
        ]),
      ),
    );
  }
}

/// ختم دايري مايل شوية — والمش متختوم دايرة متقطعة باهتة.
class _Stamp extends StatelessWidget {
  const _Stamp(this.icon, this.color, this.i, {required this.got});
  final String icon;
  final Color color;
  final int i;
  final bool got;

  @override
  Widget build(BuildContext context) {
    const size = 40.0;
    if (!got) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.line, width: 2)),
        child: Center(child: Text(ar(i + 1), style: kidText(14, color: AppColors.line))),
      );
    }
    return Transform.rotate(
      angle: (i - 1) * math.pi / 14,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: .12),
          border: Border.all(color: color, width: 3),
        ),
        child: Center(child: Text(i == stampAt.length - 1 ? '🏅' : icon, style: const TextStyle(fontSize: 18))),
      ),
    );
  }
}
