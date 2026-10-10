/// لوحة ولي الأمر — منقولة من Shell.dashboard في js/shell.js.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/audio/audio_providers.dart';
import '../../core/nav.dart';
import '../../core/reminder.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/stages.dart';
import '../achievements/achievements_screen.dart';
import '../achievements/rank_widgets.dart';
import '../daily/week_card.dart';
import '../madd/madd_dashboard_card.dart';
import '../parent_guide/pg_screens.dart';
import '../journey/journey.dart';
import '../profiles/profiles.dart';
import '../quran/quran_download.dart';
import '../quran/quran_repository.dart';
import 'avatar.dart';
import 'backup_card.dart';
import 'mastery_card.dart';

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
      onBack: () => context.back(),
      title: 'لوحة ولي الأمر',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('👨‍👩‍👦 لوحة ولي الأمر', style: kidText(24)),
          const StorageIssueNote(),
          const SizedBox(height: 10),
          const _ChildRow(),
          const SizedBox(height: 6),
          RankBar(stars: p.stars),
          const SizedBox(height: 14),
          _Stats(tiles: [
            (ar(p.stars), 'نجمة'),
            (ar(p.games), 'لعبة'),
            ('${ar(acc)}٪', 'دقة الإجابات'),
            (ar(p.correct), 'صح'),
            (ar(p.wrong), 'غلط'),
            (fmtTime(p.timeMs), 'وقت التعلّم'),
          ]),
          h3('👧👦 الأطفال'),
          const _ChildrenCard(),
          h3('🧭 رحلة النهاردة'),
          const JourneyParentCard(),
          h3('📅 تقرير الأسبوع'),
          const WeekCard(),
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
          h3('🟦 المدود'),
          MaddDashboardCard(p),
          h3('⭐ السلوكيات التي تعمل عليها'),
          const PgGoalsList(),
          h3('🌱 حالة المراحل'),
          const MasteryCard(),
          h3('🧠 مهارات محتاجة تدريب'),
          _WeakSkills(p),
          h3('📖 سور تحتاج مراجعة'),
          NoteBox(Text(p.surahsNeedingReview.isEmpty
              ? 'مفيش سور متأخرة في المراجعة'
              : p.surahsNeedingReview.map((s) => names[s] ?? 'سورة رقم ${ar(s)}').join(' • '))),
          h3('📥 القرآن من غير نت'),
          const QuranDownloadCard(),
          h3('💾 نسخة احتياطية'),
          const BackupCard(),
          h3('⏰ تذكير يومي'),
          const _ReminderCard(),
          h3('🏆 الإنجازات'),
          BadgeGrid(earned: p.achievements, small: true),
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Text('آخر نشاط: ${fmtDate(p.lastActivity)}',
                style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ),
          const SizedBox(height: 16),
          Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 4, children: [
            KidButton('❤️ دليل ولي الأمر', onTap: () => context.push('/pg')),
            KidButton('📘 دليل الوالدين', kind: BtnKind.ghost, onTap: () => context.push('/guide')),
            KidButton('🔍 التحقق من نص القرآن', kind: BtnKind.go, onTap: () => context.push('/quran-check')),
            KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back()),
          ]),
        ]),
      ),
    );
  }
}

/// مشكلة في حفظ التقدّم — بتفضل ظاهرة لحد ما ولي الأمر يقفلها.
class StorageIssueNote extends ConsumerWidget {
  const StorageIssueNote({super.key});

  static String message(StorageIssue issue) => switch (issue) {
        StorageIssue.saveFailed =>
          '⚠️ آخر تقدّم ماتحفظش على الجهاز — غالبًا المساحة مليانة. فضّي مساحة والتقدّم هيتحفظ مع اللعبة الجاية.',
        StorageIssue.restoredBackup =>
          '⚠️ ملف التقدّم كان فيه مشكلة، فرجّعنا آخر نسخة سليمة. ممكن آخر شوية نجوم يكونوا مش موجودين.',
        StorageIssue.unreadable =>
          '⚠️ ملف التقدّم ماتقريش فبدأنا من جديد. النسخة القديمة لسه محفوظة على الجهاز ومامسحناهاش.',
        StorageIssue.newerVersion =>
          '⚠️ التقدّم ده اتحفظ بنسخة أحدث من التطبيق. حدّث التطبيق — النسخة الأصلية محفوظة على الجهاز.',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final issue = ref.watch(storageIssueProvider);
    if (issue == null) return const SizedBox.shrink();
    return NoteBox(Row(children: [
      Expanded(child: Text(message(issue))),
      TextButton(
        onPressed: ref.read(storageIssueProvider.notifier).dismiss,
        child: Text('تمام', style: kidText(15, color: AppColors.grape)),
      ),
    ]));
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
          // ٤٨ نقطة على الأقل — أصغر هدف لمس مريح
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36),
            child: Center(widthFactor: 1, child: Text(label, style: kidText(14))),
          ),
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

/// الإخوات: تبديل، إضافة، ومسح — جوه لوحة ولي الأمر عشان الطفل مايمسحش أخوه بالغلط.
class _ChildrenCard extends ConsumerWidget {
  const _ChildrenCard();

  Future<void> _remove(BuildContext context, WidgetRef ref, String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('تمسح $name؟', style: kidText(20)),
        content: Text('هيتمسح كل تقدّمه ونجومه. مفيش رجوع.', style: kidText(16, weight: FontWeight.w600)),
        actions: [
          TextButton(onPressed: () => c.pop(false), child: const Text('لا')),
          TextButton(onPressed: () => c.pop(true), child: const Text('امسح', style: TextStyle(color: AppColors.coral))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(progressProvider.notifier).removeChild(id);
    await AvatarController.delete(id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kids = ref.watch(childrenProvider);
    final active = ref.watch(activeChildProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final (id, p) in kids)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: id == active ? const Color(0xFFFFF3CF) : AppColors.paper2,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Text(id == active ? '✅' : '🧒', style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),
            Expanded(
              child: Text('${childName(p)}${p.age != null ? ' • ${ar(p.age)} سنين' : ''} • ⭐ ${ar(p.stars)}',
                  style: kidText(16)),
            ),
            if (id != active)
              TextButton(
                onPressed: () => ref.read(progressProvider.notifier).switchTo(id),
                child: Text('بدّل', style: kidText(15, color: AppColors.grape)),
              ),
            if (kids.length > 1)
              IconButton(
                tooltip: 'امسح',
                onPressed: () => _remove(context, ref, id, childName(p)),
                icon: const Text('🗑️', style: TextStyle(fontSize: 18)),
              ),
          ]),
        ),
      Center(
        child: KidButton('➕ إضافة طفل', kind: BtnKind.ghost, onTap: () async {
          final router = GoRouter.of(context);
          await ref.read(progressProvider.notifier).addChild();
          router.go('/'); // الصفحة الرئيسية بتفتح على شاشة الاسم والعمر
        }),
      ),
    ]);
  }
}

class _ReminderCard extends ConsumerStatefulWidget {
  const _ReminderCard();

  @override
  ConsumerState<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends ConsumerState<_ReminderCard> {
  String? _note;

  Future<void> _set(int? minute) async {
    final kids = ref.read(childrenProvider);
    final greeting = kids.length > 1 ? 'أبطال' : childName(ref.read(progressProvider));
    final ok = await ref.read(reminderProvider.notifier).set(minute, greeting: greeting);
    if (mounted) setState(() => _note = ok ? null : '⚠️ الإشعارات مقفولة — افتحها لتطبيق رحلتي من إعدادات الجهاز');
  }

  Future<void> _pickTime() async {
    final m = ref.read(reminderProvider) ?? 17 * 60;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (t != null) await _set(t.hour * 60 + t.minute);
  }

  @override
  Widget build(BuildContext context) {
    final m = ref.watch(reminderProvider);
    final time = m == null ? null : TimeOfDay(hour: m ~/ 60, minute: m % 60).format(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text(m == null ? 'مقفول' : 'كل يوم الساعة ${ar(time)}',
              style: kidText(16, weight: FontWeight.w700)),
        ),
        Switch(
          value: m != null,
          activeTrackColor: AppColors.grassDark,
          onChanged: (v) => v ? _pickTime() : _set(null),
        ),
      ]),
      if (m != null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: _pickTime, child: Text('⏰ غيّر الساعة', style: kidText(15, color: AppColors.grape))),
        ),
      if (_note != null) NoteBox(Text(_note!)),
    ]);
  }
}
