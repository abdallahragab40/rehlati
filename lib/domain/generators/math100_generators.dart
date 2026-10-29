/// مولّدات الأعداد لحد ١٠٠ — أولى وتانية ابتدائي: الآحاد والعشرات، العد بالقفز، المقارنة،
/// والجمع والطرح بالأرقام. المستوى بيحدد نوع المسألة (من غير حمل ← بحمل).
///
/// النطق متركّب من مقاطع (الرقم لوحده + "زائد" + …) بدل جملة لكل مسألة — التوليفات بالآلاف.
library;

import 'dart:math' as math;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// الإجابة + المشتتات المغرية بالترتيب (لو جوه المدى)، وبعدين أرقام قريبة.
List<int> _choices(Rng r, int answer, List<int> tempting, int count, {int min = 0, int max = 100}) {
  final set = <int>{answer};
  for (final c in tempting) {
    if (set.length >= count) break;
    if (c >= min && c <= max) set.add(c);
  }
  var guard = 0;
  while (set.length < count && guard++ < 80) {
    final c = answer + r.sample<int>(const [-2, -1, 1, 2, -10, 10]);
    if (c >= min && c <= max) set.add(c);
  }
  return r.shuffle(set.toList());
}

int _count(int lv) => lv <= 2 ? 3 : 4;

/// آحاد وعشرات: عيدان العشرات والمكعبات ← العدد، أو العدد ← كام عشرة.
Question tensOnes(int lv, Rng r, {String? focus}) {
  final t = r.rnd(1, lv <= 2 ? 5 : 9), o = r.rnd(lv == 1 ? 1 : 0, 9);
  final n = t * 10 + o;
  // من المستوى التاني: أحيانًا العكس — العدد مكتوب والطفل يقول فيه كام عشرة
  if (lv >= 2 && r.chance(.4)) {
    return Question(
      type: 'tensOnes', mode: QMode.choice, skill: 'tens:$n',
      ask: 'العدد ${ar(n)} فيه كام عشرة؟',
      speak: 'العدد ${arNum(n)} فيه كام عشرة؟',
      clips: [say('العدد'), say(arNum(n)), say('فيه كام عشرة؟')],
      visuals: [ExprVisual([ExprTile(n, mid: true)])],
      choices: _choices(r, t, [o, t + 1, t - 1], _count(lv), min: 0, max: 9),
      answer: t,
      hint: 'رقم العشرات هو الرقم اللي على الشمال 👈',
      speakHint: 'العشرات هي الرقم اللي على الشمال',
      okMsg: '⭐ ${ar(n)} = ${ar(t)} عشرات و ${ar(o)} آحاد',
    );
  }
  return Question(
    type: 'tensOnes', mode: QMode.choice, skill: 'tens:$n',
    ask: 'كام عشرة وكام واحد؟ اختار العدد',
    speak: 'العود فيه عشرة. عُد العشرات والآحاد واختار العدد',
    visuals: [TensOnesVisual(t, o)],
    // قلب الرقمين (٣٤ ← ٤٣) أشهر غلطة
    choices: _choices(r, n, [if (o > 0) o * 10 + t, n + 10, n - 10, n + 1], _count(lv), min: 1, max: 99),
    answer: n,
    hint: 'كل عود = ١٠. عُد العيدان بالعشرات وبعدين زوّد المكعبات 👆',
    speakHint: 'كل عود بعشرة. عُد العيدان بالعشرات، وبعدين زوّد المكعبات',
    okMsg: '⭐ ${ar(t)} عشرات و ${ar(o)} آحاد = ${ar(n)}',
  );
}

/// العد بالقفز: ١٠، ٢٠، ٣٠… وبعدين ١٣، ٢٣… وبالخمسات والاتنينات.
Question skipCount(int lv, Rng r, {String? focus}) {
  const len = 5;
  final step = switch (lv) { 1 || 2 => 10, 3 => r.sample(const [5, 10]), _ => r.sample(const [2, 5, 10]) };
  final start = switch (lv) {
    1 => 10,
    2 => r.rnd(1, 9) + (r.chance(.5) ? 0 : 10),
    _ => step * r.rnd(1, step == 2 ? 20 : 6),
  };
  final seq = [for (var i = 0; i < len; i++) start + i * step];
  final hole = r.rnd(1, len - 1);
  final a = seq[hole];
  final parts = <ExprPart>[];
  for (var i = 0; i < len; i++) {
    if (i > 0) parts.add(const ExprOp('•', separator: true));
    parts.add(ExprTile(i == hole ? null : seq[i]));
  }
  return Question(
    type: 'skipCount', mode: QMode.choice, skill: 'skip:$step',
    ask: 'أكمل العد',
    speak: 'أكمل العد: ${[for (var i = 0; i < len; i++) i == hole ? 'كام' : arNum(seq[i])].join('، ')}',
    clips: [say('أكمل العد'), for (var i = 0; i < len; i++) say(i == hole ? 'كام' : arNum(seq[i]))],
    visuals: [ExprVisual(parts)],
    // لو نسي يقفز بيزود واحد بس
    choices: _choices(r, a, [a - step + 1, a + step, a + 1], _count(lv), min: 1, max: 100),
    answer: a,
    hint: 'بنقفز ${ar(step)} في كل مرة 🦘',
    speakHint: 'بنزود ${arNum(step)} في كل مرة',
  );
}

/// المقارنة لحد ١٠٠: العشرات الأول، ولو زي بعض الآحاد.
Question compare100(int lv, Rng r, {String? focus}) {
  int two() => r.rnd(10, 99);
  var a = two(), b = two();
  switch (lv) {
    case 1: // عشرات مختلفة
      while (a ~/ 10 == b ~/ 10) {
        b = two();
      }
    case 2: // نفس العشرات — الفرق في الآحاد
      b = (a ~/ 10) * 10 + r.rnd(0, 9);
    default: // ومنها نفس الرقمين مقلوبين (٣٤ و ٤٣)
      if (r.chance(.35) && a % 10 != 0 && a % 10 != a ~/ 10) b = (a % 10) * 10 + a ~/ 10;
  }
  if (r.chance(.15)) b = a;
  final ans = a > b ? '>' : (a < b ? '<' : '=');
  return Question(
    type: 'compare100', mode: QMode.choice, skill: 'cmp100:${a ~/ 10 == b ~/ 10 ? 'ones' : 'tens'}',
    ask: 'اختار العلامة الصحيحة',
    speak: 'قارن بين ${arNum(a)} وبين ${arNum(b)}. اختار العلامة الصحيحة',
    // "و" لوحدها بتتقري اسم حرف (واو)، فـ "وبين" كلمة كاملة
    clips: [say('قارن بين'), say(arNum(a)), say('وبين'), say(arNum(b)), 'pick_sign'],
    visuals: [ExprVisual([ExprTile(a), const ExprTile(null), ExprTile(b)])],
    choices: const ['>', '<', '='], answer: ans,
    hint: 'قارن العشرات الأول، ولو زي بعض قارن الآحاد 🐊',
    speakHint: 'قارن رقم العشرات الأول. لو زي بعض، قارن الآحاد',
  );
}

/// المسألة: أرقامها والإجابة والمشتت المغري.
typedef _Sum = ({int a, int b, int ans, List<int> tempting});

/// الجمع لحد ١٠٠: عشرات ← رقمين + رقم ← رقمين + رقمين ← بحمل.
Question add100(int lv, Rng r, {String? focus}) {
  final _Sum m;
  switch (lv) {
    case 1:
      final a = r.rnd(1, 8) * 10, b = r.rnd(1, (100 - a) ~/ 10) * 10;
      m = (a: a, b: b, ans: a + b, tempting: [a + b + 10, a + b - 10]);
    case 2:
      final a = r.rnd(1, 9) * 10 + r.rnd(0, 8), b = r.rnd(1, 9 - a % 10);
      m = (a: a, b: b, ans: a + b, tempting: [a + b * 10, a + b + 1]);
    case 3:
      final a = r.rnd(1, 7) * 10 + r.rnd(0, 8);
      final b = r.rnd(1, 8 - a ~/ 10) * 10 + r.rnd(0, 9 - a % 10);
      m = (a: a, b: b, ans: a + b, tempting: [a + b + 10, a + b - 10]);
    default: // بحمل: الآحاد مجموعها ١٠ أو أكتر
      final a = r.rnd(1, 7) * 10 + r.rnd(2, 9);
      final b = r.rnd(1, math.max(1, 8 - a ~/ 10)) * 10 + r.rnd(10 - a % 10, 9);
      m = (a: a, b: b, ans: a + b, tempting: [a + b - 10, a + b + 1]);
  }
  return Question(
    type: 'add100', mode: QMode.choice, skill: 'add100:${lv >= 4 ? 'carry' : 'plain'}',
    ask: '${ar(m.a)} + ${ar(m.b)} = ؟',
    speak: '${arNum(m.a)} زائد ${arNum(m.b)} يساوي كام؟',
    clips: [say(arNum(m.a)), say('زائد'), say(arNum(m.b)), say('يساوي كام؟')],
    visuals: [ExprVisual([ExprTile(m.a), const ExprOp('+'), ExprTile(m.b), const ExprOp('='), const ExprTile(null)])],
    choices: _choices(r, m.ans, m.tempting, _count(lv), min: 1, max: 100),
    answer: m.ans,
    hint: lv >= 4 ? 'اجمع الآحاد الأول — لو طلعوا ١٠ أو أكتر، زوّد عشرة على العشرات ☝️' : 'اجمع الآحاد مع الآحاد، والعشرات مع العشرات ☝️',
    speakHint: 'اجمع الآحاد مع الآحاد، والعشرات مع العشرات',
  );
}

/// الطرح لحد ١٠٠: عشرات ← رقمين − رقم ← رقمين − رقمين ← باستلاف.
Question sub100(int lv, Rng r, {String? focus}) {
  final _Sum m;
  switch (lv) {
    case 1:
      final a = r.rnd(2, 9) * 10, b = r.rnd(1, a ~/ 10 - 1) * 10;
      m = (a: a, b: b, ans: a - b, tempting: [a - b + 10, a - b - 10]);
    case 2:
      final a = r.rnd(1, 9) * 10 + r.rnd(1, 9), b = r.rnd(1, a % 10);
      m = (a: a, b: b, ans: a - b, tempting: [a - b * 10, a - b - 1]);
    case 3:
      final a = r.rnd(2, 9) * 10 + r.rnd(1, 9);
      final b = r.rnd(1, a ~/ 10 - 1) * 10 + r.rnd(0, a % 10);
      m = (a: a, b: b, ans: a - b, tempting: [a - b + 10, a - b - 10]);
    default: // باستلاف: آحاد الأول أصغر من آحاد التاني
      final a = r.rnd(3, 9) * 10 + r.rnd(0, 7);
      final b = r.rnd(1, a ~/ 10 - 2) * 10 + r.rnd(a % 10 + 1, 9);
      // الغلطة المشهورة: طرح الرقم الصغير من الكبير في الآحاد
      final wrong = (a ~/ 10 - b ~/ 10) * 10 + (b % 10 - a % 10);
      m = (a: a, b: b, ans: a - b, tempting: [wrong, a - b + 10]);
  }
  return Question(
    type: 'sub100', mode: QMode.choice, skill: 'sub100:${lv >= 4 ? 'borrow' : 'plain'}',
    ask: '${ar(m.a)} − ${ar(m.b)} = ؟',
    speak: '${arNum(m.a)} ناقص ${arNum(m.b)} يساوي كام؟',
    clips: [say(arNum(m.a)), say('ناقص'), say(arNum(m.b)), say('يساوي كام؟')],
    visuals: [ExprVisual([ExprTile(m.a), const ExprOp('−'), ExprTile(m.b), const ExprOp('='), const ExprTile(null)])],
    choices: _choices(r, m.ans, m.tempting, _count(lv), min: 0, max: 99),
    answer: m.ans,
    hint: lv >= 4 ? 'الآحاد مش كفاية؟ استلف عشرة من العشرات 🤝' : 'اطرح الآحاد من الآحاد، والعشرات من العشرات ☝️',
    speakHint: 'اطرح الآحاد من الآحاد، والعشرات من العشرات',
  );
}
