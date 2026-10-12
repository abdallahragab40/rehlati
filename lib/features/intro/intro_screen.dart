/// شاشات الترحيب — بتظهر مرة واحدة بس، أول ما التطبيق يتفتح بعد التثبيت، قبل شاشة الاسم والعمر.
/// شاشة البداية بتاعة النظام (لون السما والأيقونة) بتفضل في كل فتحة — iOS بيطلبها دايمًا.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/stages.dart';

/// الترحيب اتشاف على الجهاز ده؟ للجهاز كله مش لكل طفل — الأخ التاني بيدخل على الاسم والعمر على طول.
class IntroController extends Notifier<bool> {
  static const key = 'rehlati.intro.v1';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(key) ?? false;

  Future<void> done() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(key, true);
  }
}

final introSeenProvider = NotifierProvider<IntroController, bool>(IntroController.new);

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _count = 3;
  final _pages = PageController();
  int _page = 0;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    ref.read(sfxProvider).pad(_page);
    if (_page == _count - 1) {
      ref.read(introSeenProvider.notifier).done();
    } else {
      _pages.nextPage(duration: Motion.reduced ? 1.ms : 380.ms, curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _count - 1;
    return Scaffold(
      body: SkyBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                children: [
                  Align(
                    alignment: AlignmentDirectional.topEnd,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                      // في آخر صفحة "يلا نبدأ" بيعمل نفس الحاجة — المكان بيفضل محجوز عشان الصفحة ماتتنطش
                      child: Visibility.maintain(
                        visible: !last,
                        child: Pressable3D(
                          onTap: () => ref.read(introSeenProvider.notifier).done(),
                          radius: 999,
                          depth: 4,
                          shadowColor: AppColors.shadow,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                          child: Text('تخطّي', style: kidText(16, color: AppColors.inkSoft)),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView(
                      controller: _pages,
                      onPageChanged: (i) => setState(() => _page = i),
                      children: const [_Welcome(), _Worlds(), _Stars()],
                    ),
                  ),
                  _Dots(page: _page, count: _count),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 14, 24, 22),
                    child: KidButton(
                      last ? '🎒 يلا نبدأ الرحلة' : 'التالي',
                      kind: last ? BtnKind.go : BtnKind.primary,
                      onTap: _next,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// صفحة واحدة: رسمة كبيرة، عنوان، وسطر شرح — بتتمرر لو الشاشة قصيرة أو الخط كبير.
class _Page extends StatelessWidget {
  const _Page({required this.art, required this.title, required this.text});
  final Widget art;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: box.maxHeight),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            art,
            SizedBox(height: context.clampVw(18, 5, 30)),
            Text(
                  title,
                  textAlign: TextAlign.center,
                  style: kidText(context.clampVw(26, 7, 40), color: Colors.white, height: 1.3).copyWith(
                    shadows: const [Shadow(color: Color(0x4D1B3557), offset: Offset(0, 3))],
                  ),
                )
                .anim()
                .fadeIn(delay: 120.ms, duration: 300.ms)
                .slideY(begin: .3, end: 0, duration: 420.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: HeroText(text, size: context.clampVw(16, 4.4, 22)),
            ).anim().fadeIn(delay: 240.ms, duration: 300.ms),
          ],
        ),
      ),
    ),
  );
}

class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => _Page(
    art: Column(
      children: [
        const Banner3D('رحلتي التعليمية').anim().scaleXY(begin: .6, end: 1, duration: 520.ms, curve: Curves.elasticOut),
        SizedBox(height: context.clampVw(14, 4, 26)),
        ExcludeSemantics(
          child: Text('🦁', style: TextStyle(fontSize: context.clampVw(96, 30, 150), height: 1))
              // الأسد بيتنطط بهدوء
              .anim(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: 0, end: -12, duration: 900.ms, curve: Curves.easeInOut),
        ),
      ],
    ),
    title: 'أهلاً بيك يا بطل!',
    text: 'أنا الأسد صاحبك، وهنلعب ونتعلم سوا كل يوم',
  );
}

class _Worlds extends StatelessWidget {
  const _Worlds();

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(68, 18, 104);
    final item = size + 28;
    final gap = context.clampVw(8, 2.5, 16);
    return _Page(
      // ٣ فوق و٢ تحت على أي عرض
      art: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: item * 3 + gap * 2),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: gap,
          runSpacing: 14,
          children: [
            for (final (i, w) in worlds.indexed)
              SizedBox(
                    width: item,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: size,
                          height: size,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: w.color,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: w.tone, offset: const Offset(0, 6))],
                          ),
                          child: ExcludeSemantics(
                            child: Text(w.icon, style: TextStyle(fontSize: size * .48, height: 1)),
                          ),
                        ),
                        const SizedBox(height: 10),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(w.name, maxLines: 1, style: kidText(context.clampVw(14, 3.6, 18), color: Colors.white)),
                        ),
                      ],
                    ),
                  )
                  // العوالم بتطلع واحد ورا التاني
                  .anim()
                  .fadeIn(delay: (i * 90).ms, duration: 220.ms)
                  .scaleXY(begin: .5, end: 1, duration: 460.ms, curve: Curves.easeOutBack),
          ],
        ),
      ),
      title: 'خمس عوالم مستنياك',
      text: 'قرآن وحساب وعربي وإنجليزي وألعاب — اختار اللي تحبه',
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars();

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(70, 22, 112);
    return _Page(
      art: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                // النجوم أيقونة مش إيموجي: ⭐ الكبيرة مابتترسمش على أندرويد (Impeller)
                child:
                    (i == 1
                            ? Text('🏆', style: TextStyle(fontSize: size * 1.3, height: 1))
                            : Icon(
                                Icons.star_rounded,
                                size: size,
                                color: AppColors.gold,
                                shadows: const [Shadow(color: AppColors.goldDark, offset: Offset(0, 5))],
                              ))
                        .anim()
                        .fadeIn(delay: (i * 120).ms, duration: 200.ms)
                        .scaleXY(begin: .3, end: 1, duration: 600.ms, curve: Curves.elasticOut),
              ),
          ],
        ),
      ),
      title: 'اجمع النجوم واكسب الكؤوس',
      text: 'كل إجابة صح بنجمة وبتفتح مراحل جديدة، وبابا وماما بيتابعوا تقدّمك',
    );
  }
}

/// نقط الصفحات — الحالية أعرض.
class _Dots extends StatelessWidget {
  const _Dots({required this.page, required this.count});
  final int page;
  final int count;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'صفحة ${ar(page + 1)} من ${ar(count)}',
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: 250.ms,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == page ? 28 : 12,
            height: 12,
            decoration: BoxDecoration(
              color: i == page ? AppColors.gold : Colors.white.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
      ],
    ),
  );
}
