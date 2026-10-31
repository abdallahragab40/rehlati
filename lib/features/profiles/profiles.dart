/// الإخوات على نفس الجهاز: شاشة البداية (الاسم والمرحلة) واختيار الطفل.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/school.dart';
import '../intro/intro_screen.dart';
import '../parent/avatar.dart';
import '../parent/parent_gate.dart';

String childName(ProgressData p) => p.name.isNotEmpty ? p.name : 'بطل';

/// ملاحظة لولي الأمر تحت اختيار المرحلة: المحتوى اللي هيتعرض للطفل.
String gradeHint(String? grade) => switch (grade) {
      null => 'المحتوى كله بيتعرض على قد المرحلة اللي تختارها، وتقدر تغيّرها بعدين من لوحة ولي الأمر.',
      'kg1' => 'الحروف والأرقام والألوان والألعاب السهلة، من أسهل مستوى — والأحسن تقعد جنبه أول كام مرة.',
      'kg2' => 'الحروف والأرقام لحد ٢٠ وأساسيات الأعداد، ومسارات القراءة والأرقام الأولى.',
      'p1' || 'p2' || 'p3' => 'دروس كتاب الوزارة بتاعة ${gradeName(grade)}، ومراحل صفه مفتوحة من الأول.',
      _ => 'دروس كتاب الوزارة بتاعة ${gradeName(grade)}، والقواعد والكسور ومراحل صفه مفتوحة من الأول، بشكل الكبار.',
    };

/// أزرار المرحلة: KG1 لسادسة — صف واحد لو فيه مكان، وإلا صفين — من غير ما الزرار يصغر عن هدف لمس مريح.
class GradePicker extends StatelessWidget {
  const GradePicker({super.key, required this.selected, required this.onPick, this.missing = false});

  final String? selected;
  final ValueChanged<String> onPick;

  /// ولي الأمر داس "يلا نبدأ" من غير ما يختار — الأزرار بتتعلّم بإطار أحمر.
  final bool missing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, c) {
        const gap = 8.0;
        final perRow = c.maxWidth >= schoolGrades.length * 72 ? schoolGrades.length : (schoolGrades.length / 2).ceil();
        Widget button(String g) => Pressable3D(
              onTap: () => onPick(g),
              color: selected == g ? AppColors.gold : (missing ? AppColors.noBg : AppColors.paper2),
              radius: 22,
              depth: 5,
              shadowColor: missing ? AppColors.coral : AppColors.shadow,
              semanticLabel: gradeName(g),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [
                FittedBox(child: Text(gradeShort(g), style: kidText(22, height: 1.3))),
                Text(isKg(g) ? 'حضانة' : 'ابتدائي', style: kidText(12, color: AppColors.inkSoft)),
              ]),
            );
        return Column(children: [
          for (var i = 0; i < schoolGrades.length; i += perRow) ...[
            if (i > 0) const SizedBox(height: gap),
            Row(children: [
              for (final (j, g) in schoolGrades.skip(i).take(perRow).indexed) ...[
                if (j > 0) const SizedBox(width: gap),
                Expanded(child: button(g)),
              ],
            ]),
          ],
        ]);
      });
}

/// الاسم لازم حرفين على الأقل بعد ما نشيل المسافات — null لو تمام، وإلا رسالة الخطأ.
String? nameProblem(String name) => switch (name.trim().length) {
      0 => 'اكتب اسم الطفل الأول ✏️',
      1 => 'الاسم قصير قوي — اكتب حرفين على الأقل',
      _ => null,
    };

/// أول مرة (أو طفل جديد، أو تقدّم قديم ناقصه الاسم أو المرحلة): الاسم والمرحلة الاتنين إجباري،
/// ولو حاجة ناقصة بيظهر toast ومايكملش. المرحلة بتحدد المحتوى اللي بيتعرض ومستوى الأسئلة.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final _name = TextEditingController(text: ref.read(progressProvider).name);
  late String? _grade = ref.read(progressProvider).grade;
  final _nameFocus = FocusNode();

  /// بعد أول محاولة ناقصة: الخانة الناقصة بتتعلّم بالأحمر لحد ما تتملا.
  bool _tried = false;

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _done() {
    final nameIssue = nameProblem(_name.text);
    if (nameIssue != null || _grade == null) {
      setState(() => _tried = true);
      showToast(
        context,
        // الاتنين ناقصين: رسالة واحدة بالاتنين — وإلا الناقص بس (الاسم القصير ليه رسالته)
        _name.text.trim().isEmpty && _grade == null
            ? 'اكتب اسم الطفل واختار المرحلة الدراسية عشان نبدأ'
            : (nameIssue ?? 'اختار المرحلة الدراسية الأول 🎒'),
        kind: ToastKind.warn,
      );
      ref.read(sfxProvider).bad();
      if (nameIssue != null) _nameFocus.requestFocus();
      return;
    }
    final parent = ref.read(parentSetupProvider);
    final router = parent ? GoRouter.of(context) : null;
    ref.read(progressProvider.notifier).update((p) {
      p
        ..name = _name.text.trim()
        ..grade = _grade
        ..setupDone = true;
    });
    if (router != null) {
      // ولي الأمر جاي من الترحيب: يكمّل على لوحته (الرئيسية بتستنى تحتها)
      ref.read(parentSetupProvider.notifier).set(false);
      router.push('/parent');
    } else {
      ref.read(speechProvider).speak(sayWelcome, clips: ['welcome']);
    }
  }

  @override
  Widget build(BuildContext context) {
    final siblings = ref.watch(childrenProvider).length;
    // تقدّم قديم ناقصه الاسم أو المرحلة: مفيش رجوع ولا إلغاء — الإلغاء كان هيمسح تقدّمه
    final returning = ref.watch(progressProvider.select((p) => p.setupDone));
    final nameMissing = _tried && nameProblem(_name.text) != null;
    final gradeMissing = _tried && _grade == null;
    return ScreenFrame(
      // أول طفل: يرجع لـ"مين معانا؟" (الأخ التاني ليه زرار إلغاء تحت)
      onBack: siblings > 1 || returning ? null : () => ref.read(introSeenProvider.notifier).back(),
      child: Column(children: [
        const SizedBox(height: 10),
        const Banner3D('رحلتي التعليمية'),
        const SizedBox(height: 18),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(30),
            boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 8))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(returning ? '👋 نكمّل الرحلة!' : (siblings > 1 ? '👋 بطل جديد!' : '👋 أهلاً بيكم في رحلتي'),
                textAlign: TextAlign.center, style: kidText(24)),
            const SizedBox(height: 6),
            Text(returning ? 'محتاجين الاسم والمرحلة الدراسية عشان نعرض المحتوى المناسب' : 'خطوة صغيرة لولي الأمر قبل ما نبدأ',
                textAlign: TextAlign.center, style: kidText(15, weight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                // اختيار صورة من المعرض ورا سؤال الأهل — زي لوحة ولي الأمر (قواعد قسم الأطفال)
                onTap: () async {
                  if (await askParent(context)) await ref.read(avatarProvider.notifier).pick();
                },
                child: Column(children: [
                  const ChildAvatar(size: 92),
                  const SizedBox(height: 4),
                  Text('📷 صورة (اختياري)', style: kidText(13, color: AppColors.grape)),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            Text('اسم الطفل *', style: kidText(17)),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.done,
              // الخطأ الأحمر بيروح أول ما الاسم يبقى تمام
              onChanged: (_) {
                if (_tried) setState(() {});
              },
              textAlign: TextAlign.center,
              maxLength: 20,
              style: kidText(22),
              // المثال كان بيتقري كأنه اسم مكتوب والناس بتحاول تمسحه — فالخانة شكلها خانة كتابة
              // والكلام اللي جواها باهت، والمثال تحتها
              decoration: InputDecoration(
                hintText: 'اكتب الاسم هنا',
                hintStyle: kidText(18, weight: FontWeight.w500, color: AppColors.inkSoft.withValues(alpha: .45)),
                prefixIcon: const Icon(Icons.edit_rounded, color: AppColors.inkSoft),
                counterText: '',
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: nameMissing ? AppColors.coral : AppColors.line, width: nameMissing ? 2.5 : 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: AppColors.grape, width: 2.5),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text('مثلاً: يوسف أو مريم',
                textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 16),
            Text('في سنة كام؟ *', style: kidText(17)),
            const SizedBox(height: 8),
            GradePicker(
              selected: _grade,
              missing: gradeMissing,
              onPick: (g) {
                ref.read(sfxProvider).pad(schoolGrades.indexOf(g) % 3);
                setState(() => _grade = g);
              },
            ),
            const SizedBox(height: 8),
            Text(gradeHint(_grade),
                textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            KidButton('🚀 يلا نبدأ', kind: BtnKind.go, onTap: _done),
            if (siblings > 1 && !returning) ...[
              const SizedBox(height: 6),
              KidButton('إلغاء', kind: BtnKind.ghost, onTap: () async {
                final id = ref.read(activeChildProvider);
                await ref.read(progressProvider.notifier).removeChild(id);
                await AvatarController.delete(id);
              }),
            ],
          ]),
        ),
      ]),
    );
  }
}

/// اختيار الطفل من الصفحة الرئيسية — التبديل من غير بوابة الأهل، الإضافة والمسح من لوحة ولي الأمر.
Future<void> showChildPicker(BuildContext context) => showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C0C1C30),
      builder: (_) => const _ChildPicker(),
    );

class _ChildPicker extends ConsumerWidget {
  const _ChildPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kids = ref.watch(childrenProvider);
    final active = ref.watch(activeChildProvider);
    return Dialog(
      backgroundColor: AppColors.paper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('مين بيلعب دلوقتي؟', style: kidText(22)),
          const SizedBox(height: 14),
          for (final (id, p) in kids)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Pressable3D(
                // نقفل القايمة الأول: لو فضلت مفتوحة وقت ما الرئيسية بتتبني للطفل الجديد،
                // childrenProvider بيبلّغها في نص البناء (ظهر على أندرويد)
                onTap: () async {
                  final progress = ref.read(progressProvider.notifier);
                  context.pop();
                  if (id != active) await progress.switchTo(id);
                },
                color: id == active ? const Color(0xFFFFF3CF) : AppColors.paper2,
                radius: 22,
                depth: 5,
                shadowColor: AppColors.shadow,
                semanticLabel: childName(p),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Text(id == active ? '✅' : '🧒', style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(childName(p), style: kidText(20))),
                  Text('⭐ ${ar(p.stars)}', style: kidText(16, color: const Color(0xFF7A5200))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}
