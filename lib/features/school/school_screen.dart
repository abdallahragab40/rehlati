/// دروس المدرسة: الصف والترم والمادة، وتحت كل وحدة دروسها من كتاب الوزارة وامتحانها.
/// الدرس بيفتح جولة عادية من مراحل التطبيق اللي بتدرّب عليه، وولي الأمر يقدر يطبع منه ورقة عمل.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/school_curriculum.dart';
import '../../core/nav.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../core/widgets/top_bar.dart';
import '../../domain/progress/progress_controller.dart';
import '../../domain/progress/progress_data.dart';
import '../../domain/school_lessons.dart';
import '../parent/parent_gate.dart';
import '../parent/worksheet_card.dart';

/// الصفوف اللي ليها كتب في التطبيق.
const schoolScreenGrades = [('p1', 'أولى'), ('p2', 'تانية'), ('p3', 'تالتة'), ('p4', 'رابعة')];

const _subjects = [('arabic', '🔤 عربي'), ('math', '🧮 حساب'), ('english', '🇬🇧 English')];

/// الترم من التاريخ: من فبراير لحد يوليو التاني، والباقي الأول.
int currentTerm(DateTime now) => now.month >= 2 && now.month <= 7 ? 2 : 1;

/// الدروس تنفع الطفل ده؟ أولى لرابعة، أو من ٦ لـ ١٠ سنين لو الصف مش متحدد.
bool schoolFits(ProgressData p) =>
    p.grade != null ? schoolScreenGrades.any((g) => g.$1 == p.grade) : (p.age ?? 0) >= 6 && (p.age ?? 0) <= 10;

class SchoolScreen extends ConsumerStatefulWidget {
  const SchoolScreen({super.key});

  @override
  ConsumerState<SchoolScreen> createState() => _SchoolScreenState();
}

class _SchoolScreenState extends ConsumerState<SchoolScreen> {
  late String _grade = () {
    final p = ref.read(progressProvider);
    if (schoolScreenGrades.any((g) => g.$1 == p.grade)) return p.grade!;
    return switch (p.age ?? 6) { <= 6 => 'p1', 7 => 'p2', 8 => 'p3', _ => 'p4' };
  }();
  late int _term = currentTerm(ProgressData.clock());
  String _subject = 'arabic';

  @override
  Widget build(BuildContext context) {
    final p = ref.watch(progressProvider);
    final book = schoolBook(_grade, _term, _subject);
    Widget chips<T>(List<(T, String)> options, T value, void Function(T) pick) => Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final (v, label) in options)
              ChoiceChip(
                label: Text(label, style: kidText(15, weight: FontWeight.w700)),
                selected: v == value,
                onSelected: (_) => setState(() => pick(v)),
              ),
          ],
        );

    return ScreenFrame(
      onBack: () => context.back(),
      title: '📚 دروس المدرسة',
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        QCard(
          child: Column(children: [
            chips(schoolScreenGrades, _grade, (v) => _grade = v),
            const SizedBox(height: 6),
            chips(const [(1, 'الترم الأول'), (2, 'الترم التاني')], _term, (v) => _term = v),
            const SizedBox(height: 6),
            chips(_subjects, _subject, (v) => _subject = v),
          ]),
        ),
        const SizedBox(height: 10),
        const HeroText('دروس كتاب الوزارة — ذاكر الدرس، وفي آخر كل وحدة امتحان 📋', size: 15),
        const SizedBox(height: 10),
        if (book == null)
          const NoteBox(Text('الكتاب ده لسه مش موجود'))
        else
          for (var u = 0; u < book.units.length; u++) ...[
            _UnitCard(book: book, unit: u, results: p.school),
            const SizedBox(height: 12),
          ],
      ]),
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.book, required this.unit, required this.results});
  final SchoolBook book;
  final int unit;
  final Map<String, int> results;

  @override
  Widget build(BuildContext context) {
    final u = book.units[unit];
    final exam = unitExamId(book, unit);
    final hasExam = u.lessons.any((l) => l.ready);
    final dir = book.subject == 'english' ? TextDirection.ltr : TextDirection.rtl;
    return QCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('الوحدة ${ar(unit + 1)}', style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft)),
        Directionality(textDirection: dir, child: Text(u.title, style: kidText(21))),
        const SizedBox(height: 10),
        TileWrap(minTileWidth: 150, maxColumns: 3, children: [
          for (var l = 0; l < u.lessons.length; l++)
            _LessonTile(lesson: u.lessons[l], id: lessonId(book, unit, l), pct: results[lessonId(book, unit, l)], dir: dir),
        ]),
        if (hasExam) ...[
          const SizedBox(height: 10),
          KidButton(
            '📋 امتحان الوحدة${results[exam] == null ? '' : ' — ${ar(results[exam]!)}٪'}',
            kind: BtnKind.go,
            onTap: () => _open(context, exam),
          ),
        ],
      ]),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({required this.lesson, required this.id, required this.pct, required this.dir});
  final SchoolLesson lesson;
  final String id;
  final int? pct;
  final TextDirection dir;

  @override
  Widget build(BuildContext context) {
    final ready = lesson.ready;
    final status = !ready ? 'قريبًا' : (pct == null ? 'ذاكر الدرس' : '${pct! >= 80 ? '✅' : '🔁'} ${ar(pct!)}٪');
    return Opacity(
      opacity: ready ? 1 : .55,
      child: Pressable3D(
        onTap: ready ? () => _open(context, id) : () {},
        color: ready ? AppColors.paper : AppColors.paper2,
        radius: 18,
        depth: ready ? 5 : 2,
        shadowColor: AppColors.shadow,
        semanticLabel: '${lesson.title}، $status',
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        child: ExcludeSemantics(
          child: Column(children: [
            Directionality(
              textDirection: dir,
              child: Text(lesson.title, textAlign: TextAlign.center, style: kidText(15.5, height: 1.35)),
            ),
            const SizedBox(height: 4),
            Text(status, style: kidText(12.5, weight: FontWeight.w700, color: AppColors.inkSoft)),
          ]),
        ),
      ),
    );
  }
}

/// الدرس أو الامتحان: يلعبه الطفل، أو ولي الأمر يطبع منه ورقة عمل.
Future<void> _open(BuildContext context, String id) => showDialog<void>(
      context: context,
      barrierColor: const Color(0x8C0C1C30),
      builder: (c) => Consumer(
        builder: (c, ref, _) {
          final round = schoolRound(id)!;
          return Dialog(
            backgroundColor: AppColors.paper,
            insetPadding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Text(round.exam ? '📋' : '📚', textAlign: TextAlign.center, style: const TextStyle(fontSize: 44)),
                Directionality(
                  textDirection: round.book.subject == 'english' ? TextDirection.ltr : TextDirection.rtl,
                  child: Text(round.title, textAlign: TextAlign.center, style: kidText(22)),
                ),
                const SizedBox(height: 4),
                Text(
                  round.exam
                      ? '${countOf(round.count, questionWord)} من كل دروس الوحدة'
                      : '${countOf(round.count, questionWord)} على الدرس',
                  textAlign: TextAlign.center,
                  style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft),
                ),
                const SizedBox(height: 16),
                KidButton(round.exam ? '▶️ ابدأ الامتحان' : '▶️ ذاكر الدرس', kind: BtnKind.go, onTap: () {
                  Navigator.of(c).pop();
                  final p = ref.read(progressProvider);
                  context.push(p.limitReached ? '/timeup' : '/play/$id');
                }),
                const SizedBox(height: 8),
                KidButton('📝 ورقة عمل (لولي الأمر)', kind: BtnKind.ghost, onTap: () async {
                  if (!await askParent(c) || !c.mounted) return;
                  final p = ref.read(progressProvider);
                  final sheet = schoolWorksheet(id, p, Rng());
                  if (sheet.isEmpty) {
                    ScaffoldMessenger.of(c).showSnackBar(
                      const SnackBar(content: Text('الدرس ده أغلب أسئلته بالصوت أو باللعب — مفيش كفاية أسئلة تتطبع')),
                    );
                    return;
                  }
                  Navigator.of(c).pop();
                  if (context.mounted) await showWorksheet(context, p, sheet, ProgressData.clock());
                }),
              ]),
            ),
          );
        },
      ),
    );
