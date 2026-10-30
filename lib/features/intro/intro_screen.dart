/// شاشات الترحيب — بتظهر مرة واحدة بس، أول ما التطبيق يتفتح بعد التثبيت، قبل شاشة الاسم والعمر.
/// بعدها "مين معانا؟": ولي الأمر (ورا السؤال) بيتعرّف على لوحته ويضيف طفله، والطفل بيدخل على طول.
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
import '../parent/parent_gate.dart';

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

/// ولي الأمر اختار يضيف طفله من الترحيب ← بعد الاسم والعمر تفتح لوحته بدل الرئيسية.
/// في الذاكرة بس: لو التطبيق اتقفل في النص الطفل بيبدأ عادي.
class ParentSetupController extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool v) => state = v;
}

final parentSetupProvider = NotifierProvider<ParentSetupController, bool>(ParentSetupController.new);

enum _Step { slides, role, parent }

class IntroScreen extends ConsumerStatefulWidget {
  const IntroScreen({super.key});

  @override
  ConsumerState<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends ConsumerState<IntroScreen> {
  static const _count = 3;
  final _pages = PageController();
  int _page = 0;
  _Step _step = _Step.slides;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    ref.read(sfxProvider).pad(_page);
    if (_page == _count - 1) {
      setState(() => _step = _Step.role);
    } else {
      _pages.nextPage(duration: Motion.reduced ? 1.ms : 380.ms, curve: Curves.easeOutCubic);
    }
  }

  Future<void> _asParent() async {
    if (await askParent(context) && mounted) setState(() => _step = _Step.parent);
  }

  void _addChild() {
    ref.read(parentSetupProvider.notifier).set(true);
    ref.read(introSeenProvider.notifier).done();
  }

  @override
  Widget build(BuildContext context) {
    // رجوع النظام (أندرويد) بيرجع خطوة بدل ما يقفل التطبيق
    return PopScope(
      canPop: _step == _Step.slides,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step = _step == _Step.parent ? _Step.role : _Step.slides);
      },
      child: switch (_step) {
        _Step.slides => _slides(context),
        _Step.role => _RoleChoice(onParent: _asParent, onKid: () => ref.read(introSeenProvider.notifier).done()),
        _Step.parent => _ParentWelcome(onAdd: _addChild, onBack: () => setState(() => _step = _Step.role)),
      },
    );
  }

  Widget _slides(BuildContext context) {
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
                          onTap: () => setState(() => _step = _Step.role),
                          radius: 999,
                          depth: 4,
                          shadowColor: AppColors.shadow,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7), // ٤٨ نقطة مع العمق
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

/// خلفية شاشات "مين معانا؟" وترحيب ولي الأمر: سما ومحتوى بيتمرر في النص.
class _StepFrame extends StatelessWidget {
  const _StepFrame({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SkyBackground(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
            ),
          ),
        ),
      ),
    ),
  );
}

/// مين معانا دلوقتي؟ ولي الأمر أو الطفل — مرة واحدة بس، والتبديل بعد كده من زرار الرئيسية.
class _RoleChoice extends StatelessWidget {
  const _RoleChoice({required this.onParent, required this.onKid});
  final VoidCallback onParent, onKid;

  @override
  Widget build(BuildContext context) {
    Widget card(String icon, String title, String sub, VoidCallback onTap, {Color color = AppColors.paper}) => Pressable3D(
      onTap: onTap,
      color: color,
      radius: 28,
      depth: 7,
      shadowColor: AppColors.shadow,
      semanticLabel: title,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: ExcludeSemantics(
        child: Row(
          children: [
            Text(icon, style: TextStyle(fontSize: context.clampVw(46, 12, 60), height: 1)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: kidText(context.clampVw(22, 5.8, 26))),
                  const SizedBox(height: 4),
                  Text(sub, style: kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.55)),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return _StepFrame(
      children: [
        const Center(child: Banner3D('رحلتي التعليمية')),
        const SizedBox(height: 18),
        Text(
          'مين معانا دلوقتي؟',
          textAlign: TextAlign.center,
          style: kidText(context.clampVw(26, 7, 36), color: Colors.white, height: 1.3).copyWith(
            shadows: const [Shadow(color: Color(0x4D1B3557), offset: Offset(0, 3))],
          ),
        ),
        const SizedBox(height: 18),
        card(
          '👨‍👩‍👦',
          'أنا ولي الأمر',
          'ضيف طفلك، وتابع نجومه والمهارات اللي محتاجة تدريب، وحدد وقت اللعب كل يوم.',
          onParent,
          color: const Color(0xFFFFF3CF),
        ).anim().fadeIn(duration: 250.ms).slideY(begin: .3, end: 0, duration: 450.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 14),
        card('🦁', 'أنا البطل', 'يلا نلعب ونتعلم ونجمع نجوم!', onKid)
            .anim()
            .fadeIn(delay: 110.ms, duration: 250.ms)
            .slideY(begin: .3, end: 0, duration: 450.ms, curve: Curves.easeOutBack),
        const SizedBox(height: 16),
        const HeroText('ولي الأمر يقدر يدخل لوحته في أي وقت من زرار 👨‍👩‍👦 فوق في الصفحة الرئيسية', size: 15),
      ],
    );
  }
}

/// ترحيب ولي الأمر: إيه اللي هيقدر يتابعه (مع مثال واضح إنه مش بيانات حقيقية)، وبعدين يضيف طفله.
class _ParentWelcome extends StatelessWidget {
  const _ParentWelcome({required this.onAdd, required this.onBack});
  final VoidCallback onAdd, onBack;

  @override
  Widget build(BuildContext context) {
    final body = kidText(15, weight: FontWeight.w600, height: 1.6);
    Widget point(String icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 34, child: Text(icon, style: const TextStyle(fontSize: 22))),
          Expanded(child: Text(text, style: body)),
        ],
      ),
    );
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(child: Text(value, style: kidText(22, height: 1.2))),
          Text(label, style: kidText(12, weight: FontWeight.w700, color: AppColors.inkSoft)),
        ],
      ),
    );

    return _StepFrame(
      children: [
        QCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('👋 أهلاً بيك يا ولي الأمر', textAlign: TextAlign.center, style: kidText(24)),
              const SizedBox(height: 6),
              Text(
                'من لوحة ولي الأمر هتقدر:',
                textAlign: TextAlign.center,
                style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 14),
              point('📊', 'تشوف تقدّم كل طفل: النجوم ودقة الإجابات ووقت التعلّم وتقرير الأسبوع.'),
              point('🧠', 'تعرف المهارات اللي محتاجة تدريب والسور اللي محتاجة مراجعة.'),
              point('⏳', 'تحدد وقت اللعب في اليوم، وتشغّل تذكير يومي.'),
              point('❤️', 'تلاقي دليل للتربية الهادية: تتصرّف إزاي لما طفلك يضرب أو يعند أو يعيط.'),
              point('🔒', 'كل ده على الجهاز ده بس، من غير حساب ولا تسجيل دخول.'),
              const SizedBox(height: 4),
              // مثال ثابت عشان ولي الأمر يشوف شكل المتابعة قبل ما يكون فيه تقدّم — مش بيانات طفل
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.paper2,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.line, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Pill(
                        color: AppColors.noteBg,
                        child: Text('مثال توضيحي', style: kidText(13, color: AppColors.noteInk)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [stat(ar(120), 'نجمة'), stat('${ar(85)}٪', 'دقة الإجابات'), stat(countOf(40, minuteWord), 'وقت التعلّم')]),
                    const SizedBox(height: 10),
                    Text('🧠 محتاج تدريب: ${ar('7+2')} • b و d', style: kidText(14, weight: FontWeight.w700)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'هتلاقي اللوحة بعد كده من زرار 👨‍👩‍👦 فوق في الصفحة الرئيسية. بتسأل سؤال حساب بسيط الأول عشان الطفل مايدخلهاش لوحده.',
                textAlign: TextAlign.center,
                style: kidText(13.5, weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.6),
              ),
              const SizedBox(height: 16),
              KidButton('➕ ضيف طفلك', kind: BtnKind.go, onTap: onAdd),
              const SizedBox(height: 6),
              KidButton('رجوع', kind: BtnKind.ghost, onTap: onBack),
            ],
          ),
        ),
      ],
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
