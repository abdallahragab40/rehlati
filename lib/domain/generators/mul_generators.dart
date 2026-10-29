/// مولّدات الضرب (تانية وتالتة ابتدائي): المجموعات المتساوية، وبعدين جدول الضرب
/// على مراحل (٢ و ٥ و ١٠ ← ٣ و ٤ ← ٦ لـ ٩ ← كله).
///
/// النطق متركّب من مقاطع زي الجمع لحد ١٠٠: الرقم + "في" + الرقم + "يساوي كام؟".
library;

import '../../content/math_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// الإجابة + المشتتات المغرية (لو جوه المدى ومختلفة)، وبعدين أرقام قريبة.
List<int> _choices(Rng r, int answer, List<int> tempting, int count, {int max = 100}) {
  final set = <int>{answer};
  for (final c in tempting) {
    if (set.length >= count) break;
    if (c >= 1 && c <= max) set.add(c);
  }
  var guard = 0;
  while (set.length < count && guard++ < 80) {
    final c = answer + r.sample<int>(const [-2, -1, 1, 2]);
    if (c >= 1 && c <= max) set.add(c);
  }
  return r.shuffle(set.toList());
}

/// المجموعات المتساوية: عدد المجموعات × اللي في كل مجموعة = الكل.
Question mulGroups(int lv, Rng r, {String? focus}) {
  final g = r.rnd(2, lv <= 2 ? 3 : 4), n = r.rnd(2, lv <= 2 ? 4 : 5);
  final it = r.sample(countItems);
  final total = g * n;
  return Question(
    type: 'mulGroups', mode: QMode.choice, skill: 'groups:$g×$n',
    ask: lv >= 2 ? '${ar(g)} × ${ar(n)} = كام؟' : 'كام ${it.emoji} في كل المجموعات؟',
    speak: 'عدد المجموعات ${arNum(g)}، وفي كل مجموعة ${arNum(n)}. كام الكل؟',
    clips: [say('عدد المجموعات'), say(arNum(g)), say('وفي كل مجموعة'), say(arNum(n)), say('كام الكل؟')],
    visuals: [GroupsVisual(it.emoji, g, n)],
    // الغلطة المشهورة: جمع الرقمين بدل الضرب
    choices: _choices(r, total, [g + n, total + n, total - n], lv <= 2 ? 3 : 4, max: 25),
    answer: total,
    hint: 'كل مجموعة فيها ${ar(n)}. عُد بالقفز: ${[for (var i = 1; i <= g; i++) ar(n * i)].join('، ')} ☝️',
    speakHint: 'عُد بالقفز، مجموعة مجموعة',
    okMsg: '⭐ ${ar(g)} × ${ar(n)} = ${ar(total)}',
  );
}

/// سؤال من جدول الضرب: الجدول من [tables]، والرقم التاني لحد ٥ في الأول ولحد ١٠ بعدين.
/// من المستوى التالت الترتيب بيتقلب (٤ × ٣ زي ٣ × ٤)، والرابع فيه عامل ناقص (٣ × ؟ = ١٨).
Question _times(String type, List<int> tables, int lv, Rng r, String? focus) {
  final t = tables.contains(int.tryParse(focus ?? '')) ? int.parse(focus!) : r.sample(tables);
  final b = r.rnd(1, lv <= 2 ? 5 : 10);
  final swap = lv >= 3 && r.chance(.5);
  final (x, y) = swap ? (b, t) : (t, b);
  final p = x * y;
  if (lv >= 4 && r.chance(.4)) {
    return Question(
      type: type, mode: QMode.choice, skill: 'times:$t',
      ask: '${ar(x)} × ؟ = ${ar(p)}',
      speak: '${arNum(x)} في كام يساوي ${arNum(p)}؟',
      clips: [say(arNum(x)), say('في كام'), 'eq', say(arNum(p))],
      visuals: [ExprVisual([ExprTile(x), const ExprOp('×'), const ExprTile(null), const ExprOp('='), ExprTile(p)])],
      choices: _choices(r, y, [y + 1, y - 1, p - x], 4, max: 10),
      answer: y,
      hint: 'دوّر في جدول ${ar(x)} على ${ar(p)} 🔍',
      speakHint: 'دوّر في الجدول على الناتج',
    );
  }
  return Question(
    type: type, mode: QMode.choice, skill: 'times:$t',
    ask: '${ar(x)} × ${ar(y)} = ؟',
    speak: '${arNum(x)} في ${arNum(y)} يساوي كام؟',
    clips: [say(arNum(x)), say('في'), say(arNum(y)), say('يساوي كام؟')],
    visuals: [ExprVisual([ExprTile(x), const ExprOp('×'), ExprTile(y), const ExprOp('='), const ExprTile(null)])],
    // جمع بدل ضرب، أو جار في الجدول (واحدة زيادة أو ناقصة)
    choices: _choices(r, p, [x + y, p + x, p - x, p + y], lv <= 2 ? 3 : 4),
    answer: p,
    hint: switch (y) {
      1 => 'أي عدد × ١ = نفسه ☝️',
      <= 5 => 'الضرب جمع متكرر: ${List.filled(y, ar(x)).join(' + ')} ☝️',
      _ => 'الضرب جمع متكرر — عُد بالقفز ${ar(x)} ${ar(x)} ☝️',
    },
    speakHint: 'الضرب جمع متكرر',
  );
}

Question times2510(int lv, Rng r, {String? focus}) => _times('times2510', const [2, 5, 10], lv, r, focus);
Question times34(int lv, Rng r, {String? focus}) => _times('times34', const [3, 4], lv, r, focus);
Question times6789(int lv, Rng r, {String? focus}) => _times('times6789', const [6, 7, 8, 9], lv, r, focus);
Question timesAll(int lv, Rng r, {String? focus}) => _times('timesAll', const [2, 3, 4, 5, 6, 7, 8, 9, 10], lv, r, focus);
