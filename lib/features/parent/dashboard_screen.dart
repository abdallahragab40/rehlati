/// لوحة ولي الأمر — منقولة من Shell.dashboard في js/shell.js.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../achievements/achievements_screen.dart';
import '../quran/quran_repository.dart';
import 'avatar.dart';

String fmtTime(int ms) {
  final m = (ms / 60000).round();
  return m < 60 ? '${ar(m)} دقيقة' : '${ar(m ~/ 60)} ساعة و${ar(m % 60)} دقيقة';
}

String fmtDate(int? ts) {
  if (ts == null) return '—';
  final d = DateTime.fromMillisecondsSinceEpoch(ts);
  String two(int v) => '$v'.padLeft(2, '0');
  return ar('${d.day}/${d.month} ${two(d.hour)}:${two(d.minute)}');
}

/// اسم المهارة بشكل مقروء: "add:7+2" ← "٧+٢".
String skillLabel(String skill) {
  final i = skill.indexOf(':');
  return ar(i < 0 ? skill : skill.substring(i + 1));
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final total = p.correct + p.wrong;
    final acc = total == 0 ? 0 : (p.correct / total * 100).round();
    // أسماء السور من الكاش (ولو مش متحمّلة وفيه نت بتتجاب) — لو فشلت بنعرض الرقم
    final names = {for (final c in ref.watch(quranChaptersProvider).value ?? const []) c.number: c.name};

    Widget h3(String t) => Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 6),
          child: Text(t, style: kidText(19)),
        );

    return ScreenFrame(
      onBack: () => context.pop(),
      title: 'لوحة ولي الأمر',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('👨‍👩‍👦 لوحة ولي الأمر', style: kidText(24)),
          const SizedBox(height: 10),
          const _ChildRow(),
          const SizedBox(height: 6),
          _Stats(tiles: [
            (ar(p.stars), 'نجمة'),
            (ar(p.games), 'لعبة'),
            ('${ar(acc)}٪', 'دقة الإجابات'),
            (ar(p.correct), 'صح'),
            (ar(p.wrong), 'غلط'),
            (fmtTime(p.timeMs), 'وقت التعلّم'),
          ]),
          h3('🗺️ العوالم'),
          _Table(header: const ['العالم', 'النجوم', 'الإنجاز'], rows: [
            for (final w in worlds)
              [
                '${w.icon} ${w.name}',
                '${'⭐' * p.starsIn(w.id).clamp(0, 5)} ${ar(p.starsIn(w.id))}',
                w.id == 'quran'
                    ? '${ar(p.quran.keys.map((k) => k.split(':').first).toSet().length)} سور'
                    : '${ar(p.worldPct(w.id))}٪',
              ],
          ]),
          h3('🧠 مهارات محتاجة تدريب'),
          _WeakSkills(p),
          h3('📖 سور تحتاج مراجعة'),
          NoteBox(Text(p.surahsNeedingReview.isEmpty
              ? 'مفيش سور متأخرة في المراجعة'
              : p.surahsNeedingReview.map((s) => names[s] ?? 'سورة رقم ${ar(s)}').join(' • '))),
          h3('🏆 الإنجازات'),
          BadgeGrid(earned: p.achievements, small: true),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text('آخر نشاط: ${fmtDate(p.lastActivity)}',
                style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('📘 دليل الوالدين', onTap: () => context.push('/guide')),
            KidButton('🔍 التحقق من نص القرآن', kind: BtnKind.go, onTap: () => context.push('/quran-check')),
            KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.pop()),
          ]),
        ]),
      ),
    );
  }
}

class _ChildRow extends ConsumerStatefulWidget {
  const _ChildRow();

  @override
  ConsumerState<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends ConsumerState<_ChildRow> {
  String? _note;

  Future<void> _editName() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: ref.read(progressProvider).name),
    );
    if (name != null) ref.read(progressProvider.notifier).update((p) => p.name = name.trim());
  }

  Future<void> _pickPhoto() async {
    setState(() => _note = '⏳ بنجهّز الصورة…');
    final err = await ref.read(avatarProvider.notifier).pick();
    if (!mounted) return;
    setState(() => _note = err == null ? null : '⚠️ $err');
    if (err == null) ref.read(sfxProvider).good();
  }

  Future<void> _clearPhoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        content: Text('ترجّع الصورة الافتراضية؟', style: kidText(18, weight: FontWeight.w700)),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
          TextButton(onPressed: () => c.pop(true), child: const Text('أيوه')),
        ],
      ),
    );
    if (ok == true) await ref.read(avatarProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(progressProvider.select((p) => p.name));
    final custom = ref.watch(avatarProvider) != null;
    final kb = ref.read(avatarProvider.notifier).sizeKB;
    Widget small(String label, VoidCallback onTap) => Pressable3D(
          onTap: onTap,
          radius: 16,
          depth: 4,
          shadowColor: AppColors.shadow,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Text(label, style: kidText(14)),
        );
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ChildAvatar(size: context.clampVw(76, 22, 104)),
      const SizedBox(width: 14),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name.isNotEmpty ? name : 'بدون اسم', style: kidText(20)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: [
            small('✏️ الاسم', _editName),
            small(custom ? '📷 تغيير الصورة' : '📷 إضافة صورة الطفل', _pickPhoto),
            if (custom) small('🗑️ رجّع الافتراضية', _clearPhoto),
          ]),
          const SizedBox(height: 6),
          Text(
            _note ??
                (custom
                    ? 'صورة الطفل محفوظة على الجهاز ده بس (${ar(kb)} كيلوبايت) — مابتترفعش لأي مكان.'
                    : 'دي الصورة الافتراضية. ضيف صورة الطفل — هتتحفظ على الجهاز ده بس ومابتترفعش لأي مكان.'),
            style: kidText(13.5, weight: FontWeight.w700, color: AppColors.inkSoft, height: 1.5),
          ),
        ]),
      ),
    ]);
  }
}

class _Stats extends StatelessWidget {
  const _Stats({required this.tiles});
  final List<(String, String)> tiles;

  @override
  Widget build(BuildContext context) => TileWrap(
        minTileWidth: 100,
        children: [
          for (final (value, label) in tiles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                FittedBox(child: Text(value, style: kidText(28, height: 1.2))),
                Text(label, style: kidText(13, weight: FontWeight.w700, color: AppColors.inkSoft)),
              ]),
            ),
        ],
      );
}

class _Table extends StatelessWidget {
  const _Table({required this.header, required this.rows});
  final List<String> header;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    TableRow row(List<String> cells, {bool head = false}) => TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.line, width: 2))),
          children: [
            for (final c in cells)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(c,
                    style: head
                        ? kidText(13, weight: FontWeight.w700, color: AppColors.inkSoft)
                        : kidText(15, weight: FontWeight.w600)),
              ),
          ],
        );
    return Table(
      columnWidths: const {0: FlexColumnWidth(1.4), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1)},
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [row(header, head: true), for (final r in rows) row(r)],
    );
  }
}

class _WeakSkills extends StatelessWidget {
  const _WeakSkills(this.p);
  final ProgressData p;

  @override
  Widget build(BuildContext context) {
    final weak = p.weakest(5);
    if (weak.isEmpty) return const NoteBox(Text('مفيش مهارات متعثّرة — ما شاء الله'));
    return _Table(header: const ['المرحلة', 'المهارة', 'الأخطاء'], rows: [
      for (final w in weak)
        [
          packs[w.pack] != null ? '${packs[w.pack]!.icon} ${packs[w.pack]!.name}' : w.pack,
          skillLabel(w.skill),
          '${ar(w.misses)} مرات',
        ],
    ]);
  }
}

/// الدايالوج بيملك الـ controller بتاعه (نفس سبب بوابة الأهل).
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('اسم الطفل', style: kidText(20)),
        content: TextField(
          controller: _ctrl,
          autofocus: true,
          maxLength: 20,
          style: kidText(20, weight: FontWeight.w700),
          onSubmitted: (v) => context.pop(v),
        ),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text('إلغاء')),
          FilledButton(onPressed: () => context.pop(_ctrl.text), child: const Text('حفظ')),
        ],
      );
}
