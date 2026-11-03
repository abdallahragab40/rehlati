/// شرح دروس المدرسة: قبل جولة الأسئلة، الدرس بيتشرح في بطاقات — تمهيد، اكتشف المعلومة، مثال بخطوات،
/// «جرّب بنفسك» بأنشطة (اختار، المس، رتّب، وصّل، صنّف)، نشاط في البيت، «تأكد من فهمك»، وملخص
/// (docs/CURRICULUM_LESSONS_PLAN.md).
///
/// المحتوى ملفات JSON في assets/lessons/ — ملف لكل كتاب (`p1-t1-math.json`). كل درس ليه:
/// - `uid` ثابت (`p1-t1-math/count`) — تقدّم الطفل في الشرح بيتسجّل بيه، فمايتأثرش لو الطبعة غيّرت الترتيب.
/// - `key` مكانه في الكتاب (`u1:l2`) — بيوصّله بجولة أسئلة الدرس ونتيجتها.
/// الملفات دي هي اللي هتنزل من السيرفر بعدين للمحتوى المدفوع، فمفيش نص شرح في الكود.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/school_curriculum.dart';
import '../core/features.dart';
import 'progress/progress_data.dart';
import 'question.dart';
import 'school_lessons.dart';

const lessonsDir = 'assets/lessons/';

/// مجاني: أول درس في كل وحدة (عينة للأسرة قبل الاشتراك). الباقي من المحتوى الكامل.
enum LessonAccess { free, premium }

/// مسودة لسه المدرّس ماراجعهاش، أو اتراجعت وجاهزة للنشر.
enum LessonReview { draft, reviewed }

class LessonContent {
  const LessonContent({
    required this.uid,
    required this.id,
    required this.title,
    required this.goal,
    required this.version,
    required this.review,
    required this.access,
    required this.blocks,
  });

  /// المعرّف الثابت (`p1-t1-arabic/ba`) — مفتاح [ProgressData.lessonLogs].
  final String uid;

  /// مفتاح الدرس في دروس المدرسة (`school:p1-t1-math:u1:l2`).
  final String id;

  /// لازم يطابق اسم الدرس في lib/content/school_curriculum.dart — عشان لو الكتاب اتغيّر ترتيبه نعرف.
  final String title;
  final String goal;

  /// بيزيد مع كل تعديل في محتوى الدرس.
  final int version;
  final LessonReview review;
  final LessonAccess access;
  final List<LessonBlock> blocks;

  /// الطفل يقدر يفتح الشرح: مجاني أو المحتوى الكامل مفتوح ([paidLessonsOpen])، واتراجع أو المسودات ظاهرة.
  bool get open =>
      (access == LessonAccess.free || paidLessonsOpen) && (review == LessonReview.reviewed || draftLessonsVisible);

  Iterable<LessonTask> get tasks => [for (final b in blocks.whereType<TryBlock>()) ...b.tasks];
}

sealed class LessonBlock {
  const LessonBlock();
}

/// بطاقة: نص بيتقال، ومرئية اختيارية، وجملة إنجليزي بزرار 🔊 لدروس الإنجليزي.
class LessonCard {
  const LessonCard({required this.text, this.say, this.en, this.visual});
  final String text;

  /// اللي بيتنطق لو مختلف عن [text]: أجزاء بالترتيب، والحرف أو المقطع لوحده (بَ) بيتقال
  /// من مقاطع التعليم المشكولة (lib/core/audio/teaching.dart).
  final List<String>? say;
  final String? en;
  final Visual? visual;

  /// النص أو أجزاؤه — اللي Speech.speak بياخده.
  Object get spoken => say ?? text;
}

/// 🤔 تمهيد — موقف أو صورة تفتح الفضول، وسؤال من غير إجابة.
class HookBlock extends LessonBlock {
  const HookBlock(this.card, {this.ask});
  final LessonCard card;
  final String? ask;
}

/// 💡 اكتشف المعلومة — فكرة واحدة في البطاقة.
class ExplainBlock extends LessonBlock {
  const ExplainBlock(this.card, {this.title});
  final String? title;
  final LessonCard card;
}

/// 👣 شاهد التطبيق — خطوات بتتكشف واحدة واحدة.
class ExampleBlock extends LessonBlock {
  const ExampleBlock(this.title, this.steps);
  final String title;
  final List<LessonCard> steps;
}

/// ✋ جرّب بنفسك، أو ✅ تأكد من فهمك ([check]) — الأخيرة بتقيس: الطفل حلّها كلها من أول مرة؟
class TryBlock extends LessonBlock {
  const TryBlock(this.tasks, {this.check = false});
  final List<LessonTask> tasks;
  final bool check;
}

/// اختار إجابة، المس كل الصح، رتّب، وصّل، صنّف، ارسم بصباعك، اختار على خط الأعداد.
enum TaskKind { choice, pick, order, match, sort, trace, line }

class LessonTask {
  const LessonTask({
    required this.kind,
    required this.ask,
    required this.hint,
    required this.why,
    this.say,
    this.visual,
    this.en = false,
    this.choices = const [],
    this.answer = '',
    this.items = const [],
    this.answers = const [],
    this.pairs = const [],
    this.groups = const [],
    this.glyph = '',
    this.lo = 0,
    this.hi = 10,
    this.hints = const {},
    this.help,
  });

  final TaskKind kind;
  final String ask;
  final List<String>? say;
  final Visual? visual;

  /// النصوص بالإنجليزي (من الشمال).
  final bool en;

  /// اختار: الاختيارات والإجابة.
  final List<String> choices;
  final String answer;

  /// المس: كل العناصر و[answers] الصح منها. رتّب: [items] بالترتيب الصح (بتظهر متلخبطة).
  final List<String> items;
  final List<String> answers;

  /// وصّل: كل زوج (يمين، شمال).
  final List<(String, String)> pairs;

  /// صنّف: اسم كل مجموعة وعناصرها.
  final List<(String, List<String>)> groups;

  /// ارسم: الحرف أو الرقم اللي الطفل يمشي عليه بصباعه.
  final String glyph;

  /// خط الأعداد: من [lo] لـ [hi]، والإجابة في [answer].
  final int lo, hi;

  /// التلميح لما الطفل يغلط — بيقول فين اللخبطة، مش الإجابة.
  final String hint;

  /// تلميح لغلطة معيّنة (اختيار أو عنصر) بدل [hint].
  final Map<String, String> hints;

  /// مثال أبسط بيظهر لو الطفل غلط مرتين.
  final LessonCard? help;

  /// ليه دي الإجابة — بيظهر ويتقال بعد الحل.
  final String why;

  String hintFor(String? wrong) => hints[wrong] ?? hint;
}

/// 📖 قصة استماع — صفحات بتتقلب واحدة واحدة، كل صفحة جملة بصورة وبتتقال.
class StoryBlock extends LessonBlock {
  const StoryBlock(this.title, this.pages);
  final String title;
  final List<LessonCard> pages;
}

/// 🎵 نشيد — سطور بتتقال كلها مرة، وكل سطر يتسمع لوحده عشان الطفل يردد.
class PoemBlock extends LessonBlock {
  const PoemBlock(this.title, this.lines);
  final String title;
  final List<String> lines;
}

/// 👀 اقرا وبعدين اسمع — الطفل يقرا الكلمة أو الجملة لوحده، وبعدين يدوس 🔊 يتأكد.
class ReadBlock extends LessonBlock {
  const ReadBlock(this.title, this.items);
  final String title;
  final List<LessonCard> items;
}

/// 🏠 طبّق خارج الشاشة — لولي الأمر.
class ActivityBlock extends LessonBlock {
  const ActivityBlock(this.text);
  final String text;
}

/// ⭐ ملخص الدرس — آخر بطاقة، وبعدها التدريب.
class SummaryBlock extends LessonBlock {
  const SummaryBlock(this.points);
  final List<String> points;
}

// ---------------------------------------------------------------- حالة الطفل في الدرس

enum LessonStatus {
  /// لسه مافتحش الشرح.
  none,

  /// بدأ ووقف في النص.
  started,

  /// خلّص الشرح من غير ما يثبت إنه فهم لوحده.
  watched,

  /// خلّص بس احتاج مساعدة (غلط) ولسه ماجابش ٨٠٪ في التدريب — للمراجعة.
  helped,

  /// حل «تأكد من فهمك» كله صح من أول مرة، أو جاب ٨٠٪ أو أكتر في جولة التدريب.
  mastered,
}

LessonStatus lessonStatus(ProgressData p, LessonContent c) {
  final log = p.lessonLogs[c.uid];
  if (log == null) return LessonStatus.none;
  if (log.independent || (p.school[c.id] ?? 0) >= 80) return LessonStatus.mastered;
  if (!log.done) return LessonStatus.started;
  return log.mistakes > 0 ? LessonStatus.helped : LessonStatus.watched;
}

// ---------------------------------------------------------------- JSON

/// كتاب واحد: `{"book": "p1-t1-math", "edition": "2026_2027", "lessons": [...]}`.
/// أي حاجة غلط في الملف بترمي [FormatException] — الاختبارات بتمسكها قبل ما توصل للطفل.
List<LessonContent> parseLessonBook(String source) {
  final j = jsonDecode(source) as Map<String, dynamic>;
  final bookId = j['book'] as String;
  final book = schoolBooks.where((b) => b.id == bookId).firstOrNull;
  if (book == null) throw FormatException('unknown book $bookId');
  return [
    for (final l in j['lessons'] as List) _lesson(book, (l as Map).cast<String, dynamic>()),
  ];
}

LessonContent _lesson(SchoolBook book, Map<String, dynamic> j) {
  final key = j['key'] as String;
  final m = RegExp(r'^u(\d+):l(\d+)$').firstMatch(key);
  if (m == null) throw FormatException('bad lesson key $key');
  final u = int.parse(m[1]!), l = int.parse(m[2]!);
  final uid = j['uid'] as String;
  if (!uid.startsWith('${book.id}/')) throw FormatException('$key: uid $uid is not in ${book.id}');
  return LessonContent(
    uid: uid,
    id: lessonId(book, u - 1, l - 1),
    title: j['title'] as String,
    goal: j['goal'] as String,
    version: (j['version'] as num).toInt(),
    review: switch (j['review']) {
      'draft' => LessonReview.draft,
      'reviewed' => LessonReview.reviewed,
      final r => throw FormatException('$key: review $r'),
    },
    access: switch (j['access']) {
      null => l == 1 ? LessonAccess.free : LessonAccess.premium,
      'free' => LessonAccess.free,
      'premium' => LessonAccess.premium,
      final a => throw FormatException('$key: access $a'),
    },
    blocks: [for (final b in j['blocks'] as List) _block(key, (b as Map).cast<String, dynamic>())],
  );
}

LessonBlock _block(String key, Map<String, dynamic> j) => switch (j['type']) {
      'hook' => HookBlock(_card(j), ask: j['ask'] as String?),
      'explain' => ExplainBlock(_card(j), title: j['title'] as String?),
      'example' => ExampleBlock(j['title'] as String, [for (final s in j['steps'] as List) _card((s as Map).cast())]),
      'try' || 'check' => TryBlock(
          [for (final q in j['tasks'] as List) _task(key, (q as Map).cast())],
          check: j['type'] == 'check',
        ),
      'story' => StoryBlock(j['title'] as String, [for (final s in j['pages'] as List) _card((s as Map).cast())]),
      'poem' => PoemBlock(j['title'] as String, _strs(j['lines'])),
      'read' => ReadBlock(j['title'] as String, [for (final s in j['items'] as List) _card((s as Map).cast())]),
      'activity' => ActivityBlock(j['text'] as String),
      'summary' => SummaryBlock([for (final p in j['points'] as List) p as String]),
      final t => throw FormatException('$key: block type $t'),
    };

LessonCard _card(Map<String, dynamic> j) => LessonCard(
      text: j['text'] as String,
      say: _say(j['say']),
      en: j['en'] as String?,
      visual: j['visual'] == null ? null : visualFromJson((j['visual'] as Map).cast()),
    );

/// قوايم المحتوى مابتتغيّرش — لو حاجة حاولت تلخبطها في مكانها، بتفشل بدل ما تبوّظ الدرس.
List<String> _strs(Object? v) => List.unmodifiable([for (final s in (v as List?) ?? const []) '$s']);

/// النشاط ومعاه التأكد إنه يتحل: الإجابة موجودة، ومفيش عنصر مكرر يلخبط.
LessonTask _task(String key, Map<String, dynamic> j) {
  final kind = TaskKind.values.byName(j['kind'] as String? ?? 'choice');
  final t = LessonTask(
    kind: kind,
    ask: j['ask'] as String,
    say: _say(j['say']),
    visual: j['visual'] == null ? null : visualFromJson((j['visual'] as Map).cast()),
    en: j['en'] as bool? ?? false,
    choices: _strs(j['choices']),
    answer: '${j['answer'] ?? ''}',
    items: _strs(j['items']),
    answers: _strs(j['answers']),
    pairs: List.unmodifiable([for (final p in (j['pairs'] as List?) ?? const []) ('${(p as List)[0]}', '${p[1]}')]),
    groups: List.unmodifiable([
      for (final g in (j['groups'] as List?) ?? const []) ('${(g as Map)['name']}', _strs(g['items'])),
    ]),
    glyph: j['glyph'] as String? ?? '',
    lo: (j['lo'] as num?)?.toInt() ?? 0,
    hi: (j['hi'] as num?)?.toInt() ?? 10,
    hint: j['hint'] as String,
    hints: {for (final e in ((j['hints'] as Map?) ?? const {}).entries) '${e.key}': '${e.value}'},
    help: j['help'] == null ? null : _card((j['help'] as Map).cast()),
    why: j['why'] as String,
  );
  bool unique(List<String> l) => l.toSet().length == l.length;
  final ok = switch (kind) {
    TaskKind.choice => t.choices.length >= 2 && unique(t.choices) && t.choices.contains(t.answer),
    TaskKind.pick => unique(t.items) && t.answers.isNotEmpty && t.answers.every(t.items.contains) &&
        t.answers.length < t.items.length,
    // العناصر ممكن تتكرر (حروف «باب») — الطفل بيختار بالنص مش بالمكان
    TaskKind.order => t.items.length >= 2,
    TaskKind.match => t.pairs.length >= 2 &&
        unique([for (final p in t.pairs) p.$1]) &&
        unique([for (final p in t.pairs) p.$2]),
    TaskKind.sort => t.groups.length >= 2 &&
        t.groups.every((g) => g.$2.isNotEmpty) &&
        unique([for (final g in t.groups) ...g.$2]),
    TaskKind.trace => t.glyph.isNotEmpty,
    TaskKind.line => t.lo < t.hi && t.hi - t.lo <= 20 && (int.tryParse(t.answer) ?? t.lo - 1) >= t.lo &&
        int.parse(t.answer) <= t.hi,
  };
  if (!ok) throw FormatException('$key: ${kind.name} task "${t.ask}" cannot be solved as written');
  return t;
}

/// `"say": "جملة"` أو `"say": ["جملة", "بَ", "بُ"]`.
List<String>? _say(Object? v) => switch (v) {
      null => null,
      String t => [t],
      List<Object?> l => [for (final t in l) t as String],
      _ => throw FormatException('say $v'),
    };

/// مرئية من مرئيات الأسئلة (lib/features/game/visuals.dart) بمفتاح نوعها:
/// `{"pics": "🐱", "n": 5}`، `{"expr": [3, "+", 2, "=", null]}`، `{"line": [0, 10, 4]}` …
Visual visualFromJson(Map<String, dynamic> j) {
  int n(String k) => (j[k] as num).toInt();
  List<int> ints(String k) => [for (final v in j[k] as List) (v as num).toInt()];
  List<String> strs(String k) => [for (final v in j[k] as List) '$v'];
  return switch (j.keys.first) {
    'emoji' => EmojiVisual(j['emoji'] as String, caption: j['caption'] as String?),
    'pics' => PicsVisual(j['pics'] as String, n('n'), goneFrom: (j['gone'] as num?)?.toInt(), big: j['big'] as bool? ?? false),
    'letter' => BigLetterVisual(j['letter'] as String),
    'caption' => CaptionVisual(j['caption'] as String),
    'word' => WordLineVisual.text(j['word'] as String, big: true),
    'missing' => WordLineVisual.letters([for (final v in j['missing'] as List) v as String?], big: true),
    'chips' => LetterChipsVisual(strs('chips')),
    'tensOnes' => TensOnesVisual(ints('tensOnes')[0], ints('tensOnes')[1]),
    'line' => NumberLineVisual(ints('line')[0], ints('line')[1], ints('line')[2]),
    'clock' => ClockVisual(ints('clock')[0], ints('clock')[1]),
    'expr' => ExprVisual([for (final p in j['expr'] as List) _exprPart(p)]),
    'shape' => ShapeVisual(j['shape'] as String),
    'queue' => QueueVisual(strs('queue'), flag: j['flag'] as bool? ?? true),
    'pairs' => PairsVisual(j['pairs'] as String, n('n')),
    'pattern' => PatternVisual(strs('pattern'), hole: (j['hole'] as num?)?.toInt()),
    'listen' => ListenVisual(j['listen'] as String, en: j['en'] as bool? ?? false),
    'passage' => PassageVisual(j['title'] as String, j['passage'] as String, ltr: j['ltr'] as bool? ?? false),
    'money' => MoneyVisual(ints('money')),
    'groups' => GroupsVisual(j['groups'] as String, n('g'), n('each')),
    'graph' => PicGraphVisual([for (final r in j['graph'] as List) ('${(r as List)[0]}', (r[1] as num).toInt())]),
    'prep' => PrepVisual(j['thing'] as String, j['place'] as String, j['prep'] as String),
    final k => throw FormatException('visual $k'),
  };
}

/// رقم ← بلاطة، null ← خانة «؟»، علامة ← +/−/=، و`["🍎", 3]` ← صور فوق رقمها.
ExprPart _exprPart(Object? p) => switch (p) {
      null => const ExprTile(null),
      num v => ExprTile(v.toInt()),
      String op => ExprOp(op),
      [String emoji, num count] => ExprSide(emoji, count.toInt(), number: count.toInt()),
      _ => throw FormatException('expr part $p'),
    };

// ---------------------------------------------------------------- التحميل

/// كل الشروح الموجودة ← بمفتاح الدرس في دروس المدرسة.
///
/// دلوقتي من ملفات التطبيق. لما المحتوى ينزل من السيرفر، نفس [parseLessonBook] بيقرا الملف المتنزّل.
Future<Map<String, LessonContent>> loadLessons(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final files = manifest.listAssets().where((a) => a.startsWith(lessonsDir) && a.endsWith('.json'));
  return {
    for (final f in files)
      for (final l in parseLessonBook(await bundle.loadString(f))) l.id: l,
  };
}

final lessonsProvider = FutureProvider<Map<String, LessonContent>>((ref) => loadLessons(rootBundle));
