/// دروس المدرسة جوه اللعب: درس من كتاب الوزارة أو امتحان وحدة بيبقى جولة عادية في GameScreen،
/// أسئلتها من مراحل الدرس (lib/content/school_curriculum.dart).
///
/// المفتاح: `school:<الكتاب>:u<الوحدة>` للامتحان، و`…:l<الدرس>` للدرس — بيتخزّن في [ProgressData.school].
library;

import 'dart:math' as math;

import '../content/school_curriculum.dart';
import '../core/utils/rng.dart';
import 'progress/progress_data.dart';
import 'question.dart';
import 'stages.dart';
import 'worksheet.dart';

const schoolPrefix = 'school:';

bool isSchool(String id) => id.startsWith(schoolPrefix);

/// أسئلة درس، وأسئلة امتحان الوحدة.
const lessonQuestions = 10, examQuestions = 12;

/// الكتاب بتاع الصف والترم والمادة، لو موجود.
SchoolBook? schoolBook(String grade, int term, String subject) =>
    schoolBooks.where((b) => b.grade == grade && b.term == term && b.subject == subject).firstOrNull;

String lessonId(SchoolBook b, int unit, int lesson) => '$schoolPrefix${b.id}:u${unit + 1}:l${lesson + 1}';

String unitExamId(SchoolBook b, int unit) => '$schoolPrefix${b.id}:u${unit + 1}';

/// جولة مدرسة: درس واحد أو امتحان وحدة (كل دروسها الجاهزة).
class SchoolRound {
  const SchoolRound({required this.id, required this.book, required this.unit, required this.lessons, required this.exam});
  final String id;
  final SchoolBook book;
  final SchoolUnit unit;
  final List<SchoolLesson> lessons;
  final bool exam;

  String get title => exam ? 'امتحان: ${unit.title}' : lessons.single.title;
  int get count => exam ? examQuestions : lessonQuestions;
}

SchoolRound? schoolRound(String id) {
  if (!isSchool(id)) return null;
  final parts = id.substring(schoolPrefix.length).split(':');
  if (parts.length < 2) return null;
  final book = schoolBooks.where((b) => b.id == parts[0]).firstOrNull;
  final u = int.tryParse(parts[1].substring(1));
  if (book == null || u == null || u < 1 || u > book.units.length) return null;
  final unit = book.units[u - 1];
  if (parts.length == 2) {
    final ready = unit.lessons.where((l) => l.ready).toList();
    return ready.isEmpty ? null : SchoolRound(id: id, book: book, unit: unit, lessons: ready, exam: true);
  }
  final l = int.tryParse(parts[2].substring(1));
  if (l == null || l < 1 || l > unit.lessons.length || !unit.lessons[l - 1].ready) return null;
  return SchoolRound(id: id, book: book, unit: unit, lessons: [unit.lessons[l - 1]], exam: false);
}

/// كل الدروس الجاهزة وامتحانات الوحدات — للاختبارات وأداة الصوت.
List<String> allSchoolRoundIds() => [
      for (final b in schoolBooks)
        for (var u = 0; u < b.units.length; u++) ...[
          for (var l = 0; l < b.units[u].lessons.length; l++)
            if (b.units[u].lessons[l].ready) lessonId(b, u, l),
          if (b.units[u].lessons.any((l) => l.ready)) unitExamId(b, u),
        ],
    ];

/// مرحلة على مقاس الجولة عشان GameScreen والنتيجة (العنوان واللون والعالم).
Stage? schoolStage(String id) {
  final r = schoolRound(id);
  if (r == null) return null;
  final w = worldMeta(r.book.subject);
  return Stage(
    id: id,
    world: w.id,
    n: 0,
    icon: r.exam ? '📋' : '📚',
    name: r.title,
    base: 1,
    color: w.color,
    lang: r.book.subject == 'english' ? 'en' : 'ar',
  );
}

/// المرحلة بالمفتاح — من العوالم أو من دروس المدرسة.
Stage? stageById(String id) => packs[id] ?? schoolStage(id);

/// أسئلة الجولة: الامتحان بيلف على الدروس بالدور، والدرس بيلف على مراحله.
List<Question> schoolQuestions(SchoolRound round, ProgressData p, Rng r, {int? count, bool Function(Question)? keep}) {
  final lessons = r.shuffle(round.lessons);
  final items = [for (final l in lessons) r.shuffle(l.items)];
  final n = count ?? round.count;
  final out = <Question>[], seen = <String>{};
  for (var i = 0; out.length < n && i < n * 12; i++) {
    final li = items[i % items.length];
    final it = li[(i ~/ items.length) % li.length];
    final stage = packs[it.stage]!;
    final q = makeQuestion(it.stage, math.max(roundLevel(p, stage), it.minLevel), r, focus: it.focus, progress: p);
    if (keep != null && !keep(q)) continue;
    // نفس السؤال مرتين ورا بعض بيضايق — بنسمح بيه بس لو الدرس ضيق (حرف واحد مثلًا) وخلصت المحاولات
    if (!seen.add('${q.type}|${q.ask}|${q.answer}|${q.choices.join(',')}') && i < n * 6) continue;
    out.add(q);
  }
  return out;
}

/// ورقة عمل للدرس أو للوحدة: صفحة واحدة من الأسئلة اللي تتحل بالقلم. فاضية لو مفيش كفاية.
List<WorksheetSection> schoolWorksheet(String id, ProgressData p, Rng r) {
  final round = schoolRound(id), stage = schoolStage(id);
  if (round == null || stage == null) return const [];
  final qs = schoolQuestions(round, p, r, count: worksheetPerSection, keep: printable);
  return qs.length < 4 ? const [] : [WorksheetSection(stage, qs)];
}
