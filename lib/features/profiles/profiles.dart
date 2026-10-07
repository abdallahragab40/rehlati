/// الإخوات على نفس الجهاز: شاشة البداية (الاسم والعمر) واختيار الطفل.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../parent/avatar.dart';
import '../parent/parent_gate.dart';

/// كل الأطفال (id، التقدّم) — النشط بقيمته الحية والباقي من التخزين.
final childrenProvider = Provider<List<(String, ProgressData)>>((ref) {
  final active = ref.watch(progressProvider);
  final repo = ref.read(progressRepositoryProvider);
  return [for (final id in repo.ids) (id, id == repo.activeId ? active : repo.load(id))];
});

String childName(ProgressData p) => p.name.isNotEmpty ? p.name : 'بطل';

/// أول مرة (أو طفل جديد): الاسم والعمر — العمر بيحدد أقل مستوى للأسئلة.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late final _name = TextEditingController(text: ref.read(progressProvider).name);
  late int? _age = ref.read(progressProvider).age;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _done() {
    ref.read(progressProvider.notifier).update((p) {
      p
        ..name = _name.text.trim()
        ..age = _age ?? 4
        ..setupDone = true;
    });
    ref.read(speechProvider).speak(sayWelcome, clips: ['welcome']);
  }

  @override
  Widget build(BuildContext context) {
    final siblings = ref.watch(childrenProvider).length;
    return ScreenFrame(
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
            Text(siblings > 1 ? '👋 بطل جديد!' : '👋 أهلاً بيكم في رحلتي', textAlign: TextAlign.center, style: kidText(24)),
            const SizedBox(height: 6),
            Text('خطوة صغيرة لولي الأمر قبل ما نبدأ',
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
            Text('اسم الطفل', style: kidText(17)),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              textAlign: TextAlign.center,
              maxLength: 20,
              style: kidText(22),
              decoration: InputDecoration(
                hintText: 'مثلاً: يوسف',
                counterText: '',
                filled: true,
                fillColor: AppColors.paper2,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),
            Text('عنده كام سنة؟', style: kidText(17)),
            const SizedBox(height: 8),
            Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
              for (final a in [4, 5, 6])
                Pressable3D(
                  onTap: () => setState(() => _age = a),
                  color: _age == a ? AppColors.gold : AppColors.paper2,
                  radius: 22,
                  depth: 5,
                  shadowColor: AppColors.shadow,
                  semanticLabel: '${ar(a)} سنين',
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(children: [
                    Text(ar(a), style: kidText(30, height: 1.2)),
                    Text('سنين', style: kidText(12, color: AppColors.inkSoft)),
                  ]),
                ),
            ]),
            const SizedBox(height: 8),
            Text('الأسئلة بتبدأ على قد سنه، وبتصعب أو تسهل لوحدها حسب إجاباته.',
                textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            const SizedBox(height: 18),
            KidButton('🚀 يلا نبدأ', kind: BtnKind.go, onTap: _done),
            if (siblings > 1) ...[
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
                onTap: () async {
                  if (id != active) await ref.read(progressProvider.notifier).switchTo(id);
                  if (context.mounted) context.pop();
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
