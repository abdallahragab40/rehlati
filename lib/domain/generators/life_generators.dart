/// مولّدات الفلوس والساعة (تانية وتالتة ابتدائي): عدّ الجنيهات، الباقي، والساعة بالربع
/// وبعدين بالخمس دقايق بالكلام المصري (والتلت، والنص إلا خمسة، إلا عشرة…).
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// الإجابة + المشتتات المغرية، وبعدين أرقام قريبة.
List<int> _choices(Rng r, int answer, List<int> tempting, int count, {int max = 100}) {
  final set = <int>{answer};
  for (final c in tempting) {
    if (set.length >= count) break;
    if (c >= 0 && c <= max) set.add(c);
  }
  var guard = 0;
  while (set.length < count && guard++ < 80) {
    final c = answer + r.sample<int>(const [-5, -1, 1, 5, 10, -10]);
    if (c >= 0 && c <= max) set.add(c);
  }
  return r.shuffle(set.toList());
}

/// الورق والعملات حسب المستوى (بالجنيه).
List<int> _money(int lv) => switch (lv) { 1 => [1, 5], 2 => [1, 5, 10], 3 => [5, 10, 20, 50], _ => [1, 5, 10, 20, 50] };

/// عدّ الفلوس: كام جنيه كلهم؟ (المجموع لحد ٢٠ ← ٥٠ ← ١٠٠).
Question moneyCount(int lv, Rng r, {String? focus}) {
  final max = const [20, 50, 100, 100][lv.clamp(1, 4) - 1];
  final kinds = _money(lv);
  final pieces = <int>[];
  final want = r.rnd(2, lv <= 2 ? 4 : 5);
  var guard = 0;
  while (pieces.length < want && guard++ < 50) {
    final p = r.sample(kinds);
    if (pieces.fold(0, (s, x) => s + x) + p <= max) pieces.add(p);
  }
  if (pieces.length < 2) pieces.add(1);
  pieces.sort((a, b) => b - a);
  final total = pieces.fold(0, (s, x) => s + x);
  return Question(
    type: 'moneyCount', mode: QMode.choice, skill: 'money:${pieces.length}',
    ask: 'كام جنيه كلهم؟',
    speak: 'كام جنيه كلهم؟',
    visuals: [MoneyVisual(pieces)],
    // عدّ الورق بدل قيمته، أو نسيان ورقة
    choices: _choices(r, total, [pieces.length, total - pieces.last, total - pieces.first], lv <= 2 ? 3 : 4),
    answer: total,
    hint: 'ابدأ بالفلوس الكبيرة وبعدين زوّد الصغيرة: ${pieces.map(ar).join(' + ')} 💰',
    speakHint: 'ابدأ بالفلوس الكبيرة وبعدين زوّد الصغيرة',
  );
}

/// الباقي: دفعت ورقة واشتريت حاجة، الباقي كام؟
Question moneyChange(int lv, Rng r, {String? focus}) {
  final paid = const [10, 20, 50, 100][lv.clamp(1, 4) - 1];
  final price = lv <= 2 ? r.rnd(1, paid - 1) : r.rnd(paid ~/ 5, paid - 1);
  final change = paid - price;
  return Question(
    type: 'moneyChange', mode: QMode.choice, skill: 'change:$paid',
    ask: 'الباقي كام؟',
    speak: 'معاك ${arNum(paid)} جنيه، واشتريت حاجة بـ ${arNum(price)} جنيه. الباقي كام؟',
    clips: [say('معاك'), say(arNum(paid)), say('جنيه، واشتريت حاجة بـ'), say(arNum(price)), say('جنيه. الباقي كام؟')],
    visuals: [MoneyVisual([paid]), CaptionVisual('🏷️ السعر ${ar(price)} جنيه')],
    choices: _choices(r, change, [price, change + 1, change - 1, change + 10], lv <= 2 ? 3 : 4),
    answer: change,
    hint: 'اطرح السعر من اللي معاك: ${ar(paid)} − ${ar(price)} 🧾',
    speakHint: 'اطرح السعر من اللي معاك',
  );
}

/// الساعة بالكلام المصري: ٣ والربع، ٣ والنص إلا خمسة، ٤ إلا تلت… ("والنص" زي ساعة عالم الألعاب)
String clockTime(int h, int m) {
  final next = h % 12 + 1;
  return switch (m) {
    0 => '${ar(h)} تمام',
    5 => '${ar(h)} وخمسة',
    10 => '${ar(h)} وعشرة',
    15 => '${ar(h)} والربع',
    20 => '${ar(h)} والتلت',
    25 => '${ar(h)} والنص إلا خمسة',
    30 => '${ar(h)} والنص',
    35 => '${ar(h)} والنص وخمسة',
    40 => '${ar(next)} إلا تلت',
    45 => '${ar(next)} إلا ربع',
    50 => '${ar(next)} إلا عشرة',
    _ => '${ar(next)} إلا خمسة',
  };
}

/// الساعة بالربع (والربع، والنص، إلا ربع)، ومن المستوى التالت بالخمس دقايق.
Question clockQuarter(int lv, Rng r, {String? focus}) {
  int minute() => lv <= 2 ? r.sample(const [0, 15, 30, 45]) : 5 * r.rnd(0, 11);
  final h = r.rnd(1, 12), m = minute();
  final ans = clockTime(h, m);
  // المشتتات: "والربع" و"إلا ربع" لنفس الساعة، والساعة اللي قبل أو بعد
  final set = <String>{ans, if (m == 15) clockTime(h, 45), if (m == 45) clockTime(h, 15), clockTime(h % 12 + 1, m)};
  var guard = 0;
  while (set.length < 4 && guard++ < 60) {
    set.add(clockTime(r.rnd(1, 12), minute()));
  }
  return Question(
    type: 'clockQuarter', mode: QMode.choice, skill: 'time:$m', numeric: false, wide: true,
    ask: 'كام الساعة؟', speak: 'كام الساعة؟',
    visuals: [ClockVisual(h, m)],
    choices: r.shuffle(set.take(lv <= 2 ? 3 : 4).toList()),
    answer: ans,
    hint: m >= 40 ? 'العقرب الطويل قرّب على ١٢ — يبقى الساعة الجاية "إلا" ⏰' : 'العقرب القصير = الساعة، والطويل = الدقايق ⏰',
    speakHint: 'العقرب القصير يقول الساعة، والطويل يقول الدقايق',
    sayRight: ans,
  );
}
