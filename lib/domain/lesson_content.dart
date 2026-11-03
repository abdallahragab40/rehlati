/// شرح دروس المدرسة: قبل جولة الأسئلة، الدرس بيتشرح في بطاقات — شرح، مثال بخطوات،
/// «جرّب معايا» بأسئلة فيها سبب الإجابة، نشاط في البيت، وملخص (docs/CURRICULUM_LESSONS_PLAN.md).
///
/// المحتوى ملفات JSON في assets/lessons/ — ملف لكل كتاب (`p1-t1-math.json`)، وكل درس بمفتاحه
/// جوه الكتاب (`u1:l2`)، فبيتربط بنفس مفتاح الدرس في نتايج الطفل. الملفات دي هي اللي هتنزل من
/// السيرفر بعدين للمحتوى المدفوع، فمفيش نص شرح في الكود.
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/school_curriculum.dart';
import '../core/features.dart';
import 'question.dart';
import 'school_lessons.dart';

const lessonsDir = 'assets/lessons/';

/// مجاني: أول درس في كل وحدة (عينة للأسرة قبل الاشتراك). الباقي من المحتوى الكامل.
enum LessonAccess { free, premium }

class LessonContent {
  const LessonContent({required this.id, required this.title, required this.goal, required this.access, required this.blocks});

  /// مفتاح الدرس في دروس المدرسة (`school:p1-t1-math:u1:l2`).
  final String id;

  /// لازم يطابق اسم الدرس في lib/content/school_curriculum.dart — عشان لو الكتاب اتغيّر ترتيبه نعرف.
  final String title;
  final String goal;
  final LessonAccess access;
  final List<LessonBlock> blocks;

  /// الطفل يقدر يفتح الشرح: مجاني، أو المحتوى الكامل مفتوح ([paidLessonsOpen]).
  bool get open => access == LessonAccess.free || paidLessonsOpen;
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

/// 💡 اشرح لي — بطاقة واحدة.
class ExplainBlock extends LessonBlock {
  const ExplainBlock(this.card, {this.title});
  final String? title;
  final LessonCard card;
}

/// 👣 شوف المثال — خطوات بتتكشف واحدة واحدة.
class ExampleBlock extends LessonBlock {
  const ExampleBlock(this.title, this.steps);
  final String title;
  final List<LessonCard> steps;
}

/// ✋ جرّب معايا — أسئلة اختيار، وبعد الإجابة الصح بيظهر السبب.
class TryBlock extends LessonBlock {
  const TryBlock(this.questions);
  final List<TryQuestion> questions;
}

class TryQuestion {
  const TryQuestion({required this.ask, required this.choices, required this.answer, required this.why, this.say, this.visual, this.en = false});
  final String ask;
  final List<String>? say;
  final Visual? visual;
  final List<String> choices;
  final String answer;

  /// ليه دي الإجابة — بيظهر ويتقال بعد ما الطفل يختارها.
  final String why;

  /// الاختيارات بالإنجليزي (من الشمال، وبتتنطق إنجليزي).
  final bool en;
}

/// 🏠 نشاط بعيد عن الشاشة — لولي الأمر.
class ActivityBlock extends LessonBlock {
  const ActivityBlock(this.text);
  final String text;
}

/// ⭐ ملخص الدرس — آخر بطاقة، وبعدها التدريب.
class SummaryBlock extends LessonBlock {
  const SummaryBlock(this.points);
  final List<String> points;
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
  final access = switch (j['access']) {
    null => l == 1 ? LessonAccess.free : LessonAccess.premium,
    'free' => LessonAccess.free,
    'premium' => LessonAccess.premium,
    final a => throw FormatException('$key: access $a'),
  };
  return LessonContent(
    id: lessonId(book, u - 1, l - 1),
    title: j['title'] as String,
    goal: j['goal'] as String,
    access: access,
    blocks: [for (final b in j['blocks'] as List) _block(key, (b as Map).cast<String, dynamic>())],
  );
}

LessonBlock _block(String key, Map<String, dynamic> j) => switch (j['type']) {
      'explain' => ExplainBlock(_card(j), title: j['title'] as String?),
      'example' => ExampleBlock(j['title'] as String, [for (final s in j['steps'] as List) _card((s as Map).cast())]),
      'try' => TryBlock([for (final q in j['questions'] as List) _question((q as Map).cast())]),
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

TryQuestion _question(Map<String, dynamic> j) => TryQuestion(
      ask: j['ask'] as String,
      say: _say(j['say']),
      visual: j['visual'] == null ? null : visualFromJson((j['visual'] as Map).cast()),
      choices: [for (final c in j['choices'] as List) '$c'],
      answer: '${j['answer']}',
      why: j['why'] as String,
      en: j['en'] as bool? ?? false,
    );

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

/// كل الشروح الموجودة ← بمفتاح الدرس.
Future<Map<String, LessonContent>> loadLessons(AssetBundle bundle) async {
  final manifest = await AssetManifest.loadFromAssetBundle(bundle);
  final files = manifest.listAssets().where((a) => a.startsWith(lessonsDir) && a.endsWith('.json'));
  return {
    for (final f in files)
      for (final l in parseLessonBook(await bundle.loadString(f))) l.id: l,
  };
}

final lessonsProvider = FutureProvider<Map<String, LessonContent>>((ref) => loadLessons(rootBundle));
