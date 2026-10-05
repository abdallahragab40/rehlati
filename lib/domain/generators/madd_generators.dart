/// قسم المدود (جوه عالم العربي) — منقول من js/madd.js.
///
/// المقطع = حرف + حركة + حرف المد (المد دايمًا آخر حرف)، فـ"بَا" = ب + فتحة + ا.
library;

import '../../content/madd.dart';
import '../../core/utils/rng.dart';
import '../progress/progress_data.dart';
import '../question.dart';

const maddLetters = ['ا', 'و', 'ي'];
const maddGroup = 'madd';
const maddGroupName = '⭐ المدود';

MaddType maddType(String key) => maddTypes.firstWhere((t) => t.key == key);

/// م + ُ + و = مُو
String buildSyl(String cons, String key) => cons + maddType(key).harakaMark + maddType(key).maddLetter;

/// مُو ← مُ
String baseOf(String syl) => syl.substring(0, syl.length - 1);

String saySyl(String syl) => maddSay[syl] ?? syl;

/// بنضمن ترتيب الرموز الموحّد (حرف ثم حركة ثم حرف مد).
String normalizeSyl(String syl, String key) => buildSyl(syl[0], key);

/// موضع حرف المد جوه الكلمة.
int maddIndexIn(MaddWord w) => w.w.indexOf(w.madd) + w.madd.length - 1;

/// إعدادات مرحلة مدود: الأنواع المسموحة وأنواع الألعاب.
class MaddStage {
  const MaddStage({required this.lesson, required this.types, required this.kinds});

  /// alif/waw/yaa = درس نوع واحد، والباقي: types/complete/compose/find/read.
  final String lesson;
  final List<String> types;
  final List<String> kinds;
}

typedef _Kind = Question Function(String type, MaddStage cfg, int lv, Rng r, String? focus, MaddStats stats);

String _pickType(MaddStage cfg, String? focus, Rng r) =>
    (focus != null && cfg.types.contains(focus)) ? focus : r.sample(cfg.types);

/// السهل الأول؛ ولو الطفل أتقن النوع نفتح كل الأمثلة.
String _pickSyl(String key, int lv, MaddStats stats, Rng r) {
  final ex = maddType(key).examples;
  return normalizeSyl(r.sample((!stats.mastered(key) && lv <= 1) ? ex.sublist(0, 3) : ex), key);
}

MaddWord _pickWord(int lv, String? focus, Rng r) {
  final pool = maddWords.where((w) => w.lvl <= (lv >= 4 ? 2 : 1)).toList();
  return pool.where((w) => w.plain == focus).firstOrNull ?? r.sample<MaddWord>(pool);
}

MaddTextVisual _sylHl(String syl, String key, {bool big = false, bool pop = false, String? say}) =>
    MaddTextVisual(syl, hl: syl.length - 1, typeKey: key, big: big, pop: pop, say: say);

MaddTextVisual _wordHl(MaddWord w, {bool pop = false}) =>
    MaddTextVisual(w.w, hl: maddIndexIn(w), typeKey: w.type, big: true, pop: pop, say: w.w);

final Map<String, _Kind> _kinds = {
  // اختر حرف المد: بَ _ ← ا ← بَا
  'letter': (type, cfg, lv, r, focus, stats) {
    final key = _pickType(cfg, focus, r), t = maddType(key);
    final syl = _pickSyl(key, lv, stats, r), base = baseOf(syl);
    final extra = (lv >= 3 || stats.mastered(key)) ? [r.sample(const ['ن', 'ر', 'ك'])] : <String>[];
    return Question(
      type: type, mode: QMode.choice, skill: 'madd:$key', mtype: key, gentle: true,
      ask: 'اختر حرف المد', speak: '${saySyl(base)} . اختر حرف المد',
      visuals: [WordLineVisual.letters([base, null], big: true)],
      revealVisuals: [_sylHl(syl, key, big: true, pop: true)],
      choices: r.shuffle(<Object>[...maddLetters, ...extra]), answer: t.maddLetter,
      hint: 'انظر إلى الحركة: ${t.harakaWord} 👆', speakHint: 'انظر إلى الحركة. هذه ${t.harakaWord}',
      okMsg: '⭐ ممتاز! $syl — ${t.name} 👏', sayRight: saySyl(syl),
    );
  },

  // اسمع واختر
  'listen': (type, cfg, lv, r, focus, stats) {
    final key = _pickType(cfg, focus, r), t = maddType(key);
    final syl = _pickSyl(key, lv, stats, r);
    return Question(
      type: type, mode: QMode.choice, skill: 'madd:$key', mtype: key, gentle: true, bigChoices: true,
      ask: 'اسمع ثم اختر', speak: saySyl(syl),
      visuals: [ListenVisual(saySyl(syl))],
      choices: r.shuffle(<Object>[for (final x in maddTypes) buildSyl(syl[0], x.key)]), answer: syl,
      hint: 'اضغط 🔊 واسمع مرة أخرى 👂', speakHint: saySyl(syl),
      okMsg: '⭐ ممتاز! هذا ${t.name} 👏',
    );
  },

  // ما نوع المد؟
  'type': (type, cfg, lv, r, focus, stats) {
    final key = _pickType(cfg, focus, r), t = maddType(key);
    final syl = _pickSyl(key, lv, stats, r);
    return Question(
      type: type, mode: QMode.choice, skill: 'madd:$key', mtype: key, gentle: true, wide: true,
      ask: 'ما نوع المد؟', speak: '${saySyl(syl)} . ما نوع المد؟',
      visuals: [MaddTextVisual(syl, big: true)],
      revealVisuals: [_sylHl(syl, key, big: true, pop: true)],
      choices: r.shuffle(<Object>[for (final x in maddTypes) x.label]), answer: t.label,
      hint: 'انظر إلى الحرف الأخير في المقطع 👀', speakHint: 'انظر إلى الحرف الأخير في المقطع',
      okMsg: 'لأن $syl فيها ${t.harakaWord} وبعدها ${t.letterWord}.', sayRight: saySyl(syl),
    );
  },

  // كوّن المقطع: بَ ثم ا
  'compose': (type, cfg, lv, r, focus, stats) {
    final key = _pickType(cfg, focus, r), t = maddType(key);
    final syl = _pickSyl(key, lv, stats, r), base = baseOf(syl);
    final items = <Object>[base, t.maddLetter];
    if (lv >= 3) items.add(r.sample(maddLetters.where((l) => l != t.maddLetter).toList()));
    return Question(
      type: type, mode: QMode.order, numeric: false, rtlSlots: true, skill: 'madd:$key', mtype: key,
      gentle: true, bigChoices: true,
      ask: 'كوّن المقطع', speak: 'كوّن المقطع ${saySyl(syl)}',
      orderHint: 'اضغط البطاقتين بالترتيب من اليمين',
      visuals: [MaddTextVisual(syl)],
      items: r.shuffle(items), answer: <Object>[base, t.maddLetter],
      hint: 'ابدأ بـ $base ثم أضف حرف المد', speakHint: 'ابدأ بالحرف المتحرك ثم أضف حرف المد',
      okMsg: 'أحسنت! كوّنت $syl ⭐', sayRight: saySyl(syl),
    );
  },

  // صنّف المدود: الصناديق الثلاثة — كل نوع بيظهر مرة على الأقل
  'sort': (type, cfg, lv, r, focus, stats) {
    final n = lv >= 3 ? 6 : 4;
    final all = [for (final t in maddTypes) t.key];
    final keys = [...all, ...r.shuffle([...all, ...all]).take(n - all.length)];
    final used = <String, Set<String>>{};
    final cards = r.shuffle([
      for (final k in keys)
        () {
          final ex = maddType(k).examples.where((e) => !(used[k] ?? const {}).contains(normalizeSyl(e, k))).toList();
          final syl = normalizeSyl(r.sample(ex), k);
          (used[k] ??= {}).add(syl);
          return SortCard(syl, saySyl(syl), k);
        }(),
    ]);
    return Question(
      type: type, mode: QMode.sort, skill: 'madd:sort', gentle: true,
      ask: 'ضع كل مقطع في صندوقه', speak: 'ضع كل مقطع في الصندوق المناسب',
      orderHint: 'اضغط المقطع ثم اضغط الصندوق (أو اسحبه)',
      boxes: [for (final t in maddTypes) SortBox(t.key, t.label)],
      sortCards: cards,
      hint: 'انظر إلى حرف المد في آخر المقطع 👀', speakHint: 'انظر إلى حرف المد في آخر المقطع',
    );
  },

  // اقرأ المقطع — مفيش إجابة غلط
  'read': (type, cfg, lv, r, focus, stats) {
    final key = _pickType(cfg, focus, r);
    final syl = _pickSyl(key, lv, stats, r);
    return Question(
      type: type, mode: QMode.read, skill: 'madd:$key', mtype: key, gentle: true,
      ask: 'اقرأ المقطع', speak: 'اقرأ معي. ${saySyl(syl)}',
      visuals: [_sylHl(syl, key, big: true, say: saySyl(syl))],
      hint: 'اقرأ معي 🗣️ — هل تستطيع قراءتها؟', yes: 'نعم، قرأتها ⭐',
    );
  },

  // أين المد في الكلمة؟
  'find': (type, cfg, lv, r, focus, stats) {
    final w = _pickWord(lv, focus, r), t = maddType(w.type);
    final pool = {...w.parts, baseOf(w.madd), w.madd}.where((p) => p != w.madd).toList();
    final wrong = r.shuffle(pool).take(2);
    return Question(
      type: type, mode: QMode.choice, skill: 'madd_word:${w.plain}', mword: w.plain, mtype: w.type,
      gentle: true, bigChoices: true,
      ask: 'أين المد؟', speak: '${w.w} . أين المد؟',
      visuals: [PicsVisual(w.e, 1), MaddTextVisual(w.w, big: true, say: w.w)],
      revealVisuals: [PicsVisual(w.e, 1), _wordHl(w, pop: true)],
      choices: r.shuffle(<Object>[w.madd, ...wrong]), answer: w.madd,
      hint: 'ابحث عن المقطع الذي فيه حرف المد 🔎', speakHint: 'ابحث عن المقطع الذي فيه حرف المد',
      okMsg: 'أحسنت! وجدت ${t.name} ⭐', sayRight: w.w,
    );
  },

  // ما نوع المد في الكلمة؟
  'wordtype': (type, cfg, lv, r, focus, stats) {
    final w = _pickWord(lv, focus, r), t = maddType(w.type);
    return Question(
      type: type, mode: QMode.choice, skill: 'madd_word:${w.plain}', mword: w.plain, mtype: w.type,
      gentle: true, wide: true,
      ask: 'ما نوع المد في الكلمة؟', speak: '${w.w} . ما نوع المد في الكلمة؟',
      visuals: [PicsVisual(w.e, 1), MaddTextVisual(w.w, big: true, say: w.w)],
      choices: r.shuffle(<Object>[for (final x in maddTypes) x.label]), answer: t.label,
      hint: 'انظر إلى الحرف الذي بعد الحركة 👀', speakHint: 'انظر إلى الحرف الذي بعد الحركة',
      okMsg: 'ممتاز! هذا ${t.name} 👏', sayRight: w.w,
    );
  },

  // اقرأ الكلمة
  'wordread': (type, cfg, lv, r, focus, stats) {
    final w = _pickWord(lv, focus, r);
    return Question(
      type: type, mode: QMode.read, skill: 'madd_word:${w.plain}', mword: w.plain, mtype: w.type, gentle: true,
      ask: 'اقرأ الكلمة', speak: 'اقرأ معي. ${w.w}',
      visuals: [if (w.pic) PicsVisual(w.e, 1, big: true), _wordHl(w)],
      hint: 'اقرأ معي 🗣️ — هل تستطيع قراءتها؟', yes: 'نعم، قرأتها ⭐',
    );
  },

  // من الصورة إلى الكلمة
  'wordpic': (type, cfg, lv, r, focus, stats) {
    final pics = maddWords.where((x) => x.pic).toList();
    final w = pics.where((x) => x.plain == focus).firstOrNull ?? r.sample<MaddWord>(pics);
    final wrong = r.shuffle(pics.where((x) => x.w != w.w).toList()).take(2).map((x) => x.w);
    return Question(
      type: type, mode: QMode.choice, skill: 'madd_word:${w.plain}', mword: w.plain, mtype: w.type,
      gentle: true, bigChoices: true, wide: true,
      ask: 'اختر الكلمة المناسبة للصورة', speak: 'اختر الكلمة المناسبة للصورة',
      visuals: [PicsVisual(w.e, 1, big: true)],
      choices: r.shuffle(<Object>[w.w, ...wrong]), answer: w.w,
      hint: 'اقرأ الكلمات ببطء 📖', speakHint: 'اقرأ الكلمات ببطء',
      okMsg: 'أحسنت! ${w.w} ⭐', sayRight: w.w,
    );
  },
};

/// سؤال من نوع معيّن — [type] = "madd_alif:letter".
Question maddQuestion(String stageId, String kind, MaddStage cfg, int lv, Rng r, String? focus, MaddStats stats) =>
    _kinds[kind]!('$stageId:$kind', cfg, lv, r, focus, stats);

/// المراحل الثمانية (= المستويات ١–٨ في مواصفات الويب).
const _all = ['alif', 'waw', 'yaa'];
const maddStageDefs = <(String, String, String, int, int, MaddStage)>[
  ('madd_alif', '🟦', 'المد بالألف', 1, 0xFF2D9CDB, MaddStage(lesson: 'alif', types: ['alif'], kinds: ['letter', 'compose', 'read'])),
  ('madd_waw', '🟩', 'المد بالواو', 1, 0xFF2E9E57, MaddStage(lesson: 'waw', types: ['waw'], kinds: ['letter', 'compose', 'read'])),
  ('madd_yaa', '🟨', 'المد بالياء', 1, 0xFFC98A00, MaddStage(lesson: 'yaa', types: ['yaa'], kinds: ['letter', 'compose', 'read'])),
  ('madd_types', '🔎', 'ما نوع المد؟', 2, 0xFF7A5CFF, MaddStage(lesson: 'types', types: _all, kinds: ['listen', 'type', 'sort'])),
  ('madd_complete', '✏️', 'أكمل المقطع', 2, 0xFFE05FA8, MaddStage(lesson: 'complete', types: _all, kinds: ['letter', 'listen', 'type'])),
  ('madd_compose', '🧩', 'كوّن المقطع', 2, 0xFFFF7A59, MaddStage(lesson: 'compose', types: _all, kinds: ['compose', 'sort', 'read'])),
  ('madd_find', '🕵️', 'اكتشف المد في الكلمة', 3, 0xFF1FAE9B, MaddStage(lesson: 'find', types: _all, kinds: ['find', 'wordtype'])),
  ('madd_read', '📖', 'اقرأ كلمات المدود', 3, 0xFF4C6FFF, MaddStage(lesson: 'read', types: _all, kinds: ['wordread', 'wordpic', 'wordtype'])),
];

// ---------------------------------------------------------------- التعلّم المتكيّف الخاص بالمدود

/// أخطاء نوع مد معيّن عبر كل مراحل المدود.
int maddMissFor(ProgressData p, String key) => p.skills.entries
    .where((e) => e.key.startsWith('madd_') && e.key.endsWith('|madd:$key'))
    .fold(0, (sum, e) => sum + e.value);

/// أضعف نوع (٣ أخطاء أو أكتر) — بيفتح "تدريب صغير" قبل الدرس.
String? maddWeakType(ProgressData p) {
  final worst = [
    for (final t in maddTypes) (key: t.key, n: maddMissFor(p, t.key)),
  ].where((x) => x.n >= 3).toList()
    ..sort((a, b) => b.n - a.n);
  return worst.firstOrNull?.key;
}

List<String> maddReviewList(ProgressData p) =>
    [for (final t in maddTypes) if (p.madd.review.contains(t.key) || maddMissFor(p, t.key) >= 3) t.key];

/// بعد التدريب الصغير: نخفّف عداد الأخطاء بدل ما نمسحه — لسه بنراقبه.
void maddEaseMisses(ProgressData p, String key) {
  for (final k in p.skills.keys.toList()) {
    if (k.startsWith('madd_') && k.endsWith('|madd:$key') && p.skills[k]! > 1) p.skills[k] = 1;
  }
  p.madd.review.remove(key);
}
