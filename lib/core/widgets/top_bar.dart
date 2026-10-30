import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion.dart';
import '../../domain/progress/progress_controller.dart';
import '../../features/parent/parent_gate.dart';
import '../../features/settings/settings_sheet.dart';
import '../theme/app_theme.dart';
import '../utils/arabic.dart';
import 'fx_layer.dart';
import 'kid_widgets.dart';

/// الشريط العلوي: رجوع، عدّاد النجوم (بينبض مع كل نجمة)، العنوان، ولي الأمر، الإعدادات.
class TopBar extends ConsumerWidget {
  const TopBar({super.key, this.onBack, this.title, this.parent = false});
  final VoidCallback? onBack;
  final String? title;

  /// زرار لوحة ولي الأمر (ورا السؤال) — في الرئيسية بس، عشان الأهل يلاقوها.
  final bool parent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars = ref.watch(progressProvider.select((p) => p.stars));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconBubbleButton('↩', onTap: onBack!, label: 'رجوع'),
            const SizedBox(width: 10),
          ],
          Semantics(
            label: countOf(stars, starWord),
            child: ExcludeSemantics(
              child: StarTarget(
                child: Pill(
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('⭐', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 6),
                    Text(ar(stars)),
                  ]),
                )
                    // النبضة بتستنى النجمة الطايرة توصل (FxController.flyStars)
                    .anim(key: ValueKey(stars))
                    .scaleXY(delay: 680.ms, begin: 1, end: 1.35, duration: 160.ms, curve: Curves.easeOut)
                    .then()
                    .scaleXY(begin: 1, end: 1 / 1.35, duration: 380.ms, curve: Curves.elasticOut),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: title == null
                ? const SizedBox()
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Pill(child: Text(title!, overflow: TextOverflow.ellipsis, maxLines: 1)),
                  ),
          ),
          const SizedBox(width: 10),
          if (parent) ...[
            // الاسم جنب الأيقونة على الشاشات العريضة بس — على الموبايل الأيقونة لوحدها عشان العنوان يفضل باين
            MediaQuery.sizeOf(context).width >= 520
                ? Pressable3D(
                    onTap: () => openParentArea(context),
                    radius: 999,
                    depth: 4,
                    shadowColor: AppColors.shadow,
                    semanticLabel: 'ولي الأمر',
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: SizedBox(
                      height: 48,
                      child: Center(widthFactor: 1, child: ExcludeSemantics(child: Text('👨‍👩‍👦 ولي الأمر', style: kidText(16)))),
                    ),
                  )
                : IconBubbleButton('👨‍👩‍👦', onTap: () => openParentArea(context), label: 'ولي الأمر'),
            const SizedBox(width: 10),
          ],
          IconBubbleButton('⚙️', onTap: () => showSettingsSheet(context), label: 'الإعدادات'),
        ],
      ),
    );
  }
}

/// إطار كل شاشة: سما، شريط علوي، ومحتوى متوسّط بعرض أقصى (للتابلت).
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    super.key,
    required this.child,
    this.onBack,
    this.title,
    this.background,
    this.scroll = true,
    this.parent = false,
  });
  final Widget child;
  final VoidCallback? onBack;
  final String? title;
  final bool parent;

  /// مشهد متحرك ورا المحتوى (خرائط العوالم).
  final Widget? background;
  final bool scroll;

  @override
  Widget build(BuildContext context) {
    final pad = context.clampVw(12, 3, 22);
    final body = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxContentWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Column(
            children: [
              TopBar(onBack: onBack, title: title, parent: parent),
              Expanded(
                child: scroll
                    ? SingleChildScrollView(padding: const EdgeInsets.only(bottom: 28), child: child)
                    : child,
              ),
            ],
          ),
        ),
      ),
    );
    return Scaffold(
      body: SkyBackground(
        child: Stack(children: [
          if (background != null) Positioned.fill(child: background!),
          SafeArea(child: body),
        ]),
      ),
    );
  }
}
