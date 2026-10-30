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
import '../../domain/school.dart';
import '../../domain/stages.dart';
import '../achievements/achievements_screen.dart';
import '../achievements/rank_widgets.dart';
import '../daily/week_card.dart';
import '../madd/madd_dashboard_card.dart';
import '../parent_guide/pg_screens.dart';
import '../journey/journey.dart';
import '../paths/paths_screen.dart';
import '../profiles/profiles.dart';
import '../quran/quran_download.dart';
import '../quran/quran_repository.dart';
import 'avatar.dart';
import 'backup_card.dart';
import 'credits_card.dart';
import 'mastery_card.dart';

String fmtTime(int ms) {
  final m = (ms / 60000).round();
  if (m < 60) return countOf(m, minuteWord);
  final h = countOf(m ~/ 60, hourWord);
  return m % 60 == 0 ? h : '$h و${countOf(m % 60, minuteWord)}';
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

/// تبويبات اللوحة: التقدّم أول حاجة، والدليل والإعدادات كل واحد لوحده.
enum DashTab { progress, guide, settings }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.tab = DashTab.progress});

  /// التبويب اللي بتفتح عليه (للاختبارات).
  final DashTab tab;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late DashTab _tab = widget.tab;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(progressProvider.select((p) => p.name));
    // "لسارة" بتتوصل، والاسم اللاتيني محتاج "لـ" قبله
    final to = name.isEmpty ? 'للطفل' : RegExp('^[\u0600-\u06FF]').hasMatch(name) ? 'ل$name' : 'لـ$name';
    return ScreenFrame(
      onBack: () => context.back(),
      title: 'لوحة ولي الأمر',
      child: QCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('👨‍👩‍👦 لوحة ولي الأمر', style: kidText(24)),
          const StorageIssueNote(),
          const SizedBox(height: 10),
          // من غير ما يدوّر على زرار الرجوع: الجهاز بيرجع للطفل على الرئيسية
          KidButton('🧒 سلّم الجهاز $to', kind: BtnKind.go, onTap: () => context.go('/')),
          const SizedBox(height: 12),
          _TabBar(tab: _tab, onPick: (t) => setState(() => _tab = t)),
          switch (_tab) {
            DashTab.progress => const _ProgressTab(),
            DashTab.guide => const _GuideTab(),
            DashTab.settings => const _SettingsTab(),
          },
          const SizedBox(height: 16),
          Center(child: KidButton('رجوع', kind: BtnKind.ghost, onTap: () => context.back())),
        ]),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.tab, required this.onPick});
  final DashTab tab;
  final ValueChanged<DashTab> onPick;

  @override
  Widget build(BuildContext context) => Row(children: [
        for (final (i, (t, label)) in const [
          (DashTab.progress, '📊 التقدّم'),
          (DashTab.guide, '❤️ الدليل'),
          (DashTab.settings, '⚙️ الإعدادات'),
        ].indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              selected: t == tab,
              child: Pressable3D(
                onTap: () => onPick(t),
                color: t == tab ? AppColors.gold : AppColors.paper2,
                radius: 18,
                depth: 4,
                shadowColor: AppColors.shadow,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                // ٤٨ نقطة على الأقل — أصغر هدف لمس مريح
                child: SizedBox(
                  height: 48,
                  child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Text(label, maxLines: 1, style: kidText(16)))),
                ),
              ),
            ),
          ),
        ],
      ]);
}

Widget _h3(String t) => Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 6),
      child: Text(t, style: kidText(19)),
    );

class _ProgressTab extends ConsumerWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    final total = p.correct + p.wrong;
    final acc = total == 0 ? 0 : (p.correct / total * 100).round();
    // أسماء السور من الكاش (ولو مش متحمّلة وفيه نت بتتجاب) — لو فشلت بنعرض الرقم
    final names = {for (final c in ref.watch(quranChaptersProvider).value ?? const []) c.number: c.name};

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 14),
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
      _h3('👧👦 الأطفال'),
      const _ChildrenCard(),
      _h3('🧭 رحلة النهاردة'),
      const JourneyParentCard(),
      _h3('🎒 مسارات التعلّم'),
      const PathsParentCard(),
      _h3('📅 تقرير الأسبوع'),
      const WeekCard(),
      _h3('🧠 مهارات محتاجة تدريب'),
      _WeakSkills(p),
      _h3('📖 سور تحتاج مراجعة'),
      NoteBox(Text(p.surahsNeedingReview.isEmpty
          ? 'مفيش سور متأخرة في المراجعة'
          : p.surahsNeedingReview.map((s) => names[s] ?? 'سورة رقم ${ar(s)}').join(' • '))),
      _h3('🗺️ العوالم'),
      _Table(header: const ['العالم', 'النجوم', 'الإنجاز'], rows: [
        for (final w in worlds)
          [
            '${w.icon} ${w.name}',
            '${'⭐' * p.starsIn(w.id).clamp(0, 5)} ${ar(p.starsIn(w.id))}',
            w.id == 'quran'
                ? countOf(p.quran.keys.map((k) => k.split(':').first).toSet().length, surahWord)
                : '${ar(p.worldPct(w.id))}٪',
          ],
      ]),
      _h3('🟦 المدود'),
      MaddDashboardCard(p),
      _h3('🌱 حالة المراحل'),
      const MasteryCard(),
      _h3('🏆 الإنجازات'),
      BadgeGrid(earned: p.achievements, small: true),
      Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Text('آخر نشاط: ${fmtDate(p.lastActivity)}',
            style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
      ),
    ]);
  }
}

class _GuideTab extends StatelessWidget {
  const _GuideTab();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 14),
        _LinkCard(
          icon: '❤️',
          title: 'دليل ولي الأمر',
          sub: 'طفلك بيضرب أو بيعند أو بيعيط؟ اكتب اللي بيحصل وخد خطوات هادية تتصرّف بيها.',
          onTap: () => context.push('/pg'),
        ),
        _LinkCard(
          icon: '📘',
          title: 'إزاي تستخدم التطبيق',
          sub: 'العوالم، النجوم وفتح المراحل، عالم القرآن، والأرقام اللي تبص عليها في اللوحة.',
          onTap: () => context.push('/guide'),
        ),
        _h3('⭐ السلوكيات التي تعمل عليها'),
        const PgGoalsList(),
      ]);
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _h3('🎯 اختبار تحديد المستوى'),
        const _PlacementCard(),
        _h3('🧑 شكل التطبيق'),
        const _LookCard(),
        _h3('⏰ تذكير يومي'),
        const _ReminderCard(),
        _h3('📥 القرآن من غير نت'),
        const QuranDownloadCard(),
        const SizedBox(height: 8),
        Center(child: KidButton('🔍 التحقق من نص القرآن', kind: BtnKind.go, onTap: () => context.push('/quran-check'))),
        _h3('💾 نسخة احتياطية'),
        const BackupCard(),
        _h3('ℹ️ المصادر والتراخيص'),
        const CreditsCard(),
      ]);
}

/// كارت بيفتح شاشة تانية: أيقونة وعنوان وسطر شرح.
class _LinkCard extends StatelessWidget {
  const _LinkCard({required this.icon, required this.title, required this.sub, required this.onTap});
  final String icon, title, sub;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Pressable3D(
          onTap: onTap,
          color: AppColors.paper2,
          radius: 20,
          depth: 5,
          shadowColor: AppColors.shadow,
          semanticLabel: title,
          padding: const EdgeInsets.all(14),
          child: ExcludeSemantics(
            child: Row(children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: kidText(18)),
                  const SizedBox(height: 2),
                  Text(sub, style: kidText(14, weight: FontWeight.w600, color: AppColors.inkSoft, height: 1.5)),
                ]),
              ),
              const Text('‹', style: TextStyle(fontSize: 28, color: AppColors.inkSoft)),
            ]),
          ),
        ),
      );
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

  Future<void> _editAge() async {
    final age = await showDialog<int>(
      context: context,
      builder: (_) => _AgeDialog(initial: ref.read(progressProvider).age),
    );
    if (age != null) ref.read(progressProvider.notifier).update((p) => p.age = age);
  }

  Future<void> _editGrade() async {
    final p = ref.read(progressProvider);
    final grade = await showDialog<String>(
      context: context,
      builder: (_) => _GradeDialog(initial: p.grade, usual: usualGrade(p.age)),
    );
    // '' = ولي الأمر شال الصف
    if (grade != null) ref.read(progressProvider.notifier).update((p) => p.grade = grade.isEmpty ? null : grade);
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
            small('🎂 السن', _editAge),
            small('🏫 الصف', _editGrade),
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
          countOf(w.misses, timesWord),
        ],
    ]);
  }
}

/// شكل الكبار: من غير الأسد والتلة الخضرا — تلقائي من سن ٩، وولي الأمر يقدر يغيّره.
class _LookCard extends ConsumerWidget {
  const _LookCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = ref.watch(progressProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: 6, runSpacing: 4, children: [
        for (final (v, label) in [(null, 'حسب السن'), (true, 'شكل الكبار'), (false, 'شكل الصغار')])
          ChoiceChip(
            label: Text(label),
            selected: p.settings.grownUp == v,
            onSelected: (_) => ref.read(progressProvider.notifier).update((p) => p.settings.grownUp = v),
          ),
      ]),
      const SizedBox(height: 4),
      Text(
        'شكل الكبار من غير الأسد والرسوم، للأطفال من ٩ سنين وفوق. "حسب السن" بيختاره لوحده '
        '(دلوقتي: ${p.grownUpLook ? 'شكل الكبار' : 'شكل الصغار'}).',
        style: kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft),
      ),
    ]);
  }
}

/// اختبار قصير (١٠ أسئلة) لكل مادة: بيفتح المراحل اللي على قد الطفل وبيحدد مستوى البداية.
class _PlacementCard extends StatelessWidget {
  const _PlacementCard();

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
          'ادّي الجهاز للطفل يجاوب ١٠ أسئلة بتصعب تدريجيًا. على قد ما يوصل، المراحل المناسبة بتتفتح '
          'ومستوى البداية في المادة بيتظبط. مابيقفلش حاجة كانت مفتوحة.',
          style: kidText(14.5, weight: FontWeight.w600, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final (world, label) in [('math', '🧮 الحساب'), ('arabic', '🔤 العربي'), ('english', '🇬🇧 English')])
            KidButton(label, kind: BtnKind.ghost, onTap: () => context.push('/play/place_$world')),
        ]),
      ]);
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

/// Dialog مش AlertDialog: AlertDialog بيقيس المحتوى بـ IntrinsicWidth، و AgePicker جواه LayoutBuilder.
class _AgeDialog extends StatelessWidget {
  const _AgeDialog({required this.initial});
  final int? initial;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('عنده كام سنة؟', textAlign: TextAlign.center, style: kidText(20)),
            const SizedBox(height: 12),
            AgePicker(selected: initial, onPick: (a) => context.pop(a)),
            const SizedBox(height: 10),
            Text('السن بيحدد مستوى البداية بس — التقدّم والنجوم مابيتغيروش.',
                textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            TextButton(onPressed: () => context.pop(), child: const Text('إلغاء')),
          ]),
        ),
      );
}

/// الصف الدراسي اختياري ومنفصل عن السن — بيتخزّن دلوقتي عشان المحتوى الجاي يمشي على المنهج.
class _GradeDialog extends StatelessWidget {
  const _GradeDialog({required this.initial, required this.usual});
  final String? initial;

  /// الصف المعتاد للسن — بيتعلّم بنجمة كاقتراح.
  final String? usual;

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('في سنة كام؟', textAlign: TextAlign.center, style: kidText(20)),
            const SizedBox(height: 12),
            Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
              for (final g in schoolGrades)
                ChoiceChip(
                  label: Text(g == usual ? '${gradeName(g)} ⭐' : gradeName(g), style: kidText(15)),
                  selected: g == initial,
                  onSelected: (_) => context.pop(g),
                ),
            ]),
            const SizedBox(height: 10),
            Text('⭐ = الصف المعتاد لسنه. الصف بيفتح من الأول مراحل الابتدائي المناسبة (زي جدول الضرب من تالتة).',
                textAlign: TextAlign.center, style: kidText(13, weight: FontWeight.w600, color: AppColors.inkSoft)),
            if (initial != null) TextButton(onPressed: () => context.pop(''), child: const Text('مش عايز أحدد')),
            TextButton(onPressed: () => context.pop(), child: const Text('إلغاء')),
          ]),
        ),
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
              child: Text('${childName(p)}${p.age != null ? ' • ${ageText(p.age!)}' : ''}'
                  '${p.grade != null ? ' • ${gradeName(p.grade!)}' : ''} • ⭐ ${ar(p.stars)}',
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
