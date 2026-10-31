/// دروس حساب خامسة ابتدائي (tool/SCHOOL_CURRICULUM_INDEX.md): الكسور العشرية لحد جزء من ألف وعملياتها،
/// التعبيرات والمعادلات، الكسور بمقامات مختلفة وضربها وقسمتها، المستوى الإحداثي، الحجم، والقطاعات الدائرية.
///
/// الأعداد مكتوبة ومش بتتنطق (choiceSay فاضي) — السؤال جملة ثابتة بتتقال.
library;

import 'dart:math' as math;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

Question _q(String type, String skill, String ask, List<Visual> visuals, List<String> choices, String answer, Rng r,
        {required String hint, required String speakHint, bool big = true, String? speak, ChoiceLook look = ChoiceLook.text}) =>
    Question(
      type: type, mode: QMode.choice, skill: skill, numeric: false, bigChoices: big, wide: !big, look: look,
      ask: ask, speak: speak ?? ask, clips: [say(speak ?? ask)],
      visuals: visuals,
      choices: r.shuffle(choices.toSet().toList()), answer: answer, choiceSay: {for (final c in choices) c: ''},
      hint: hint, speakHint: speakHint, clipsHint: [say(speakHint)],
    );

/// [n] ÷ ١٠^[scale] مكتوب بفاصلة عشرية ومن غير أصفار زيادة: _fmt(3450, 3) = ٣٫٤٥.
String decimalText(int n, int scale) {
  if (scale <= 0) return ar(n * math.pow(10, -scale).toInt());
  final p = math.pow(10, scale).toInt();
  final frac = (n % p).toString().padLeft(scale, '0').replaceFirst(RegExp(r'0+$'), '');
  return frac.isEmpty ? ar(n ~/ p) : '${ar(n ~/ p)}٫${ar(frac)}';
}

// ---------------------------------------------------------------- الكسور العشرية

const _decPlaces = ['الأعشار', 'الأجزاء من مئة', 'الأجزاء من ألف'];

/// focus: place / round / addsub / powers / mul.
Question decimals5(int lv, Rng r, {String? focus}) {
  final kind = ['place', 'round', 'addsub', 'powers', 'mul'].contains(focus)
      ? focus!
      : r.sample(['place', 'round', 'addsub', if (lv >= 2) 'powers', if (lv >= 2) 'mul']);
  switch (kind) {
    case 'place':
      final n = r.rnd(1000, 9999);
      final digits = [n ~/ 100 % 10, n ~/ 10 % 10, n % 10];
      final i = r.rnd(0, 2);
      return _q('decimals5', 'dec5:place', 'الرقم اللي في خانة ${_decPlaces[i]} كام؟', [BigLetterVisual('${ar(n ~/ 1000)}٫${ar((n % 1000).toString().padLeft(3, '0'))}')],
          [ar(digits[i]), ...{for (final d in digits) if (d != digits[i]) ar(d)}, ar((digits[i] + 1) % 10)].take(3).toList(),
          ar(digits[i]), r,
          speak: 'دور على الرقم في الخانة المطلوبة',
          hint: 'بعد الفاصلة: الأعشار، وبعدها الأجزاء من مئة، وبعدها الأجزاء من ألف ☝️',
          speakHint: 'بعد الفاصلة الأعشار، وبعدها الأجزاء من مئة، وبعدها الأجزاء من ألف');
    case 'round':
      var n = r.rnd(1001, 9999);
      while (n % 100 == 50 || n % 100 == 0) {
        n = r.rnd(1001, 9999);
      }
      final down = n ~/ 100 * 100, up = down + 100;
      final ans = n % 100 >= 50 ? up : down;
      return _q('decimals5', 'dec5:round', 'قرّب لأقرب جزء من عشرة', [BigLetterVisual(decimalText(n, 3))],
          [decimalText(ans, 3), decimalText(ans == up ? down : up, 3), decimalText(n ~/ 10 * 10, 3)], decimalText(ans, 3), r,
          hint: 'بص على رقم الأجزاء من مئة: ٥ أو أكتر نطلع، أقل ننزل ☝️', speakHint: 'بص على رقم الأجزاء من مئة');
    case 'powers':
      final n = r.rnd(11, 999); // جزء من مئة
      final k = r.rnd(1, lv >= 3 ? 3 : 2);
      final times = r.chance(.5);
      final p = math.pow(10, k).toInt();
      final ans = times ? decimalText(n * p, 2) : decimalText(n, 2 + k);
      final wrong = [
        times ? decimalText(n * p * 10, 2) : decimalText(n, 3 + k),
        times ? decimalText(n * p ~/ 10, 2) : decimalText(n, 1 + k),
      ];
      return _q('decimals5', 'dec5:powers', times ? 'اضرب في ${ar(p)}' : 'اقسم على ${ar(p)}',
          [ExprVisual([ExprTile(decimalText(n, 2)), ExprOp(times ? '×' : '÷'), ExprTile(p), const ExprOp('='), const ExprTile(null)])],
          [ans, ...wrong], ans, r, speak: times ? 'الضرب في قوى العشرة' : 'القسمة على قوى العشرة',
          hint: times ? 'الفاصلة بتتنقل لليمين بعدد الأصفار ☝️' : 'الفاصلة بتتنقل للشمال بعدد الأصفار ☝️',
          speakHint: 'الفاصلة بتتنقل بعدد الأصفار');
    case 'mul':
      final n = r.rnd(11, 99), w = r.rnd(2, 9); // n أعشار
      final ans = decimalText(n * w, 1);
      return _q('decimals5', 'dec5:mul', 'اضرب الكسر العشري في العدد',
          [ExprVisual([ExprTile(decimalText(n, 1)), const ExprOp('×'), ExprTile(w), const ExprOp('='), const ExprTile(null)])],
          [ans, decimalText(n * w, 2), decimalText(n * w, 0)], ans, r,
          hint: 'اضرب من غير الفاصلة، وبعدين حط فاصلة برقم واحد من اليمين ☝️', speakHint: 'اضرب من غير الفاصلة وبعدين حطها');
    default:
      final add = r.chance(.5);
      var a = r.rnd(101, 999), b = r.rnd(101, 999);
      if (!add && b > a) (a, b) = (b, a);
      if (a == b) a += 7;
      final n = add ? a + b : a - b;
      final ans = decimalText(n, 2);
      return _q('decimals5', 'dec5:${add ? 'add' : 'sub'}', add ? 'اجمع' : 'اطرح',
          [ExprVisual([ExprTile(decimalText(a, 2)), ExprOp(add ? '+' : '−'), ExprTile(decimalText(b, 2)), const ExprOp('='), const ExprTile(null)])],
          [ans, decimalText(n + 10, 2), decimalText(n - 10 > 0 ? n - 10 : n + 100, 2)], ans, r,
          hint: 'رتّب الفاصلة تحت الفاصلة، واجمع أو اطرح خانة خانة ☝️', speakHint: 'رتب الفاصلة تحت الفاصلة');
  }
}

// ---------------------------------------------------------------- التعبيرات والمعادلات

Question equations(int lv, Rng r, {String? focus}) {
  final kind = r.sample(['add', 'sub', if (lv >= 2) 'mul', if (lv >= 2) 'eval']);
  List<String> three(int a, Iterable<int> w) => [ar(a), ...{for (final x in w) if (x != a && x >= 0) x}.take(2).map(ar)];
  switch (kind) {
    case 'mul':
      final a = r.rnd(2, 9), x = r.rnd(2, 12);
      return _q('equations', 'eq:mul', 'أوجد قيمة ن', [BigLetterVisual('${ar(a)} × ن = ${ar(a * x)}')],
          three(x, [a * x - a, x + 1, a * x]), ar(x), r,
          hint: 'اقسم: ${ar(a * x)} ÷ ${ar(a)} ☝️', speakHint: 'المجهول في الضرب بنجيبه بالقسمة');
    case 'eval':
      final a = r.rnd(2, 6), b = r.rnd(1, 9), n = r.rnd(2, 9);
      return _q('equations', 'eq:eval', 'احسب قيمة التعبير', [BigLetterVisual('${ar(a)} × ن + ${ar(b)}'), CaptionVisual('لما ن = ${ar(n)}')],
          three(a * n + b, [a * (n + b), a + n + b, a * n]), ar(a * n + b), r,
          hint: 'حط ${ar(n)} مكان ن، واضرب الأول وبعدين اجمع ☝️', speakHint: 'حط العدد مكان ن، واضرب الأول');
    case 'sub':
      final x = r.rnd(10, 60), b = r.rnd(2, x - 1);
      return _q('equations', 'eq:sub', 'أوجد قيمة ن', [BigLetterVisual('ن − ${ar(b)} = ${ar(x - b)}')],
          three(x, [x - 2 * b, x + 1, b]), ar(x), r,
          hint: 'المجهول في الطرح بنجيبه بالجمع: ${ar(x - b)} + ${ar(b)} ☝️', speakHint: 'المجهول في الطرح بنجيبه بالجمع');
    default:
      final a = r.rnd(2, 40), x = r.rnd(2, 40);
      return _q('equations', 'eq:add', 'أوجد قيمة ن', [BigLetterVisual('ن + ${ar(a)} = ${ar(a + x)}')],
          three(x, [a + x + a, x + 1, a]), ar(x), r,
          hint: 'المجهول في الجمع بنجيبه بالطرح: ${ar(a + x)} − ${ar(a)} ☝️', speakHint: 'المجهول في الجمع بنجيبه بالطرح');
  }
}

// ---------------------------------------------------------------- الكسور

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// الكسرين قيمتهم واحدة؟ (عشان الاختيار الغلط مايبقاش مكافئ للصح).
bool _same(String a, String b) {
  final x = a.split('/').map(int.parse).toList(), y = b.split('/').map(int.parse).toList();
  return x[0] * y[1] == y[0] * x[1];
}

Question _frac(String skill, String ask, List<Visual> visuals, String answer, List<String> wrong, Rng r,
    {required String hint, required String speakHint}) {
  final options = [answer, ...{for (final w in wrong) if (!_same(w, answer) && !w.startsWith('0/')) w}.take(2)];
  return _q('fractions5', skill, ask, visuals, options, answer, r, look: ChoiceLook.fraction, hint: hint, speakHint: speakHint);
}

/// focus: addsub / mul / div.
/// عدد كسري مكتوب: «٢ و ٣/٤»، أو كسر بس، أو صحيح بس.
String mixedText(int whole, int n, int d) =>
    n == 0 ? ar(whole) : (whole == 0 ? '${ar(n)}/${ar(d)}' : '${ar(whole)} و ${ar(n)}/${ar(d)}');

/// جمع وطرح الأعداد الكسرية، والطرح فيه «استلاف» واحد صحيح. من المستوى التالت بمقامات مختلفة.
Question _mixedAddSub(int lv, Rng r) {
  const pairs = [(2, 4), (3, 6), (4, 8), (2, 3), (3, 4)];
  final (d1, d2) = lv >= 3 ? r.sample(pairs) : (() { final d = r.sample([4, 5, 6, 8, 10]); return (d, d); })();
  final l = d1 * d2 ~/ _gcd(d1, d2);
  final w1 = r.rnd(2, 6), w2 = r.rnd(1, w1 - 1), n1 = r.rnd(1, d1 - 1), n2 = r.rnd(1, d2 - 1);
  final a = w1 * l + n1 * l ~/ d1, b = w2 * l + n2 * l ~/ d2;
  final add = r.chance(.5);
  final total = add ? a + b : a - b;
  final ans = mixedText(total ~/ l, total % l, l);
  // الغلط: نسيان الواحد اللي اتنقل، أو جمع البسط مع المقامات
  final wrong = [
    mixedText(total ~/ l + (add ? -1 : 1), total % l, l),
    mixedText(total ~/ l + 1, total % l, l),
    if (total % l != 0) mixedText(total ~/ l, (total % l + 1) % l, l),
  ];
  return _q('fractions5', 'frac5:mixed${add ? 'Add' : 'Sub'}', add ? 'اجمع العددين الكسريين' : 'اطرح العددين الكسريين',
      [BigLetterVisual('${mixedText(w1, n1, d1)} ${add ? '+' : '−'} ${mixedText(w2, n2, d2)}')],
      [ans, ...{for (final w in wrong) if (w != ans) w}.take(2)], ans, r, big: false,
      hint: add
          ? 'اجمع الصحيح مع الصحيح والكسر مع الكسر، ولو الكسر بقى أكبر من واحد زوّد الصحيح ☝️'
          : 'اطرح الصحيح من الصحيح والكسر من الكسر، ولو الكسر الأول أصغر استلف واحد صحيح ☝️',
      speakHint: 'الصحيح مع الصحيح، والكسر مع الكسر');
}

/// focus: addsub / mul / div / mixed.
Question fractions5(int lv, Rng r, {String? focus}) {
  if (focus == 'mixed') return _mixedAddSub(lv, r);
  final kind = ['addsub', 'mul', 'div'].contains(focus) ? focus! : r.sample(['addsub', if (lv >= 2) 'mul', if (lv >= 2) 'div']);
  switch (kind) {
    case 'mul':
      final b = r.rnd(2, 6), d = r.rnd(2, 6), a = r.rnd(1, b - 1), c = r.rnd(1, d - 1);
      return _frac('frac5:mul', 'اضرب الكسرين',
          [ExprVisual([ExprTile('$a/$b'), const ExprOp('×'), ExprTile('$c/$d'), const ExprOp('='), const ExprTile(null)])],
          '${a * c}/${b * d}', ['${a * c}/${b + d}', '${a + c}/${b * d}', '${a * d}/${b * c}'], r,
          hint: 'البسط × البسط، والمقام × المقام ☝️', speakHint: 'البسط في البسط، والمقام في المقام');
    case 'div':
      final d = r.rnd(2, 8), n = r.rnd(2, 6);
      if (r.chance(.5)) {
        return _frac('frac5:div', 'اقسم كسر الوحدة على العدد',
            [ExprVisual([ExprTile('1/$d'), const ExprOp('÷'), ExprTile(n), const ExprOp('='), const ExprTile(null)])],
            '1/${d * n}', ['$n/$d', '1/${d + n}', '${d * n}/1'], r,
            hint: 'لو قسمنا ${ar(1)}/${ar(d)} على ${ar(n)} كل جزء بيصغر: المقام × ${ar(n)} ☝️', speakHint: 'المقام بيتضرب في العدد');
      }
      return _q('fractions5', 'frac5:divWhole', 'اقسم العدد على كسر الوحدة',
          [ExprVisual([ExprTile(n), const ExprOp('÷'), ExprTile('1/$d'), const ExprOp('='), const ExprTile(null)])],
          [ar(n * d), ar(n + d), ar(n * d * 2)], ar(n * d), r,
          hint: 'كام ${ar(1)}/${ar(d)} في ${ar(n)}؟ في كل واحد صحيح ${ar(d)} ☝️', speakHint: 'كام جزء في كل واحد صحيح');
    default:
      const pairs = [(2, 4), (2, 3), (3, 6), (4, 8), (2, 5), (3, 4), (2, 6), (4, 6), (3, 5)];
      final (d1, d2) = r.sample(pairs);
      final l = d1 * d2 ~/ _gcd(d1, d2);
      var a = r.rnd(1, d1 - 1), b = r.rnd(1, d2 - 1);
      final add = r.chance(.5);
      // في الطرح الكسر الأول لازم يبقى أكبر
      if (!add && a * l ~/ d1 <= b * l ~/ d2) {
        a = d1 - 1;
        b = 1;
        if (a * l ~/ d1 <= b * l ~/ d2) return fractions5(lv, r, focus: 'addsub');
      }
      final n = add ? a * l ~/ d1 + b * l ~/ d2 : a * l ~/ d1 - b * l ~/ d2;
      return _frac('frac5:${add ? 'add' : 'sub'}', add ? 'اجمع الكسرين' : 'اطرح الكسرين',
          [ExprVisual([ExprTile('$a/$d1'), ExprOp(add ? '+' : '−'), ExprTile('$b/$d2'), const ExprOp('='), const ExprTile(null)])],
          '$n/$l', [add ? '${a + b}/${d1 + d2}' : '${(a - b).abs()}/${(d1 - d2).abs() == 0 ? d1 : (d1 - d2).abs()}', '${add ? a + b : (a - b).abs() + 1}/$l', '$n/${d1 * d2 * 2}'], r,
          hint: 'وحّد المقامات الأول: المقام المشترك ${ar(l)} ☝️', speakHint: 'وحد المقامات الأول، وبعدين احسب البسط');
  }
}

// ---------------------------------------------------------------- المستوى الإحداثي

const _pointNames = ['أ', 'ب', 'ج', 'د'];

String coordText(int x, int y) => '(${ar(x)}، ${ar(y)})';

Question coordinates(int lv, Rng r, {String? focus}) {
  final pts = <(int, int)>{};
  while (pts.length < 3) {
    pts.add((r.rnd(0, 6), r.rnd(0, 6)));
  }
  final list = pts.toList();
  if (r.chance(.5)) {
    final (x, y) = list.first;
    final wrong = [if (x != y) coordText(y, x), coordText(x + 1, y), coordText(x, y == 0 ? 1 : y - 1)];
    return _q('coordinates', 'coord:read', 'إحداثيات النقطة أ؟', [CoordVisual([('أ', x, y)])], [coordText(x, y), ...wrong],
        coordText(x, y), r, big: false,
        hint: 'الأول بنمشي على المحور الأفقي (س)، وبعدين نطلع لفوق (ص) ☝️', speakHint: 'الأول المحور الأفقي، وبعدين نطلع لفوق');
  }
  final i = r.rnd(0, 2);
  final (x, y) = list[i];
  return _q('coordinates', 'coord:find', 'أنهي نقطة إحداثياتها ${coordText(x, y)}؟',
      [CoordVisual([for (var k = 0; k < 3; k++) (_pointNames[k], list[k].$1, list[k].$2)])], _pointNames.take(3).toList(), _pointNames[i], r,
      speak: 'دور على النقطة اللي إحداثياتها مكتوبة',
      hint: 'امشي ${ar(x)} على المحور الأفقي، وبعدين ${ar(y)} لفوق ☝️', speakHint: 'امشي على المحور الأفقي الأول، وبعدين لفوق');
}

// ---------------------------------------------------------------- الحجم

Question volume(int lv, Rng r, {String? focus}) {
  final l = r.rnd(2, lv <= 1 ? 4 : 6), w = r.rnd(2, 4), h = r.rnd(2, lv <= 1 ? 3 : 5);
  final v = l * w * h;
  if (lv >= 3 && r.chance(.4)) {
    return _q('volume', 'vol:missing', 'صندوق حجمه ${ar(v)} وحدة مكعبة، طوله ${ar(l)} وعرضه ${ar(w)}. ارتفاعه كام؟',
        [BoxVisual(l, w, h, labels: false)], [ar(h), ar(h + 1), ar(v ~/ l)], ar(h), r, big: false,
        speak: 'اقرا المسألة وحلها',
        hint: 'الارتفاع = الحجم ÷ (الطول × العرض) = ${ar(v)} ÷ ${ar(l * w)} ☝️', speakHint: 'الارتفاع يساوي الحجم على الطول في العرض');
  }
  return _q('volume', 'vol:count', 'حجم الصندوق كام وحدة مكعبة؟', [BoxVisual(l, w, h)],
      [ar(v), ar(l + w + h), ar(l * w), ar(v + l * w)], ar(v), r,
      hint: 'الحجم = الطول × العرض × الارتفاع = ${ar(l)} × ${ar(w)} × ${ar(h)} ☝️', speakHint: 'الحجم يساوي الطول في العرض في الارتفاع');
}

// ---------------------------------------------------------------- القطاعات الدائرية

/// الألوان وأسماءها — نفس ترتيب ألوان PieView.
const pieColors = ['الأحمر', 'الأزرق', 'الأصفر', 'الأخضر'];

/// تقسيمات الدايرة بالأتمان، وأكبر قطاع فيها واحد بس.
const _piePatterns = [[4, 2, 2], [4, 2, 1, 1], [6, 1, 1], [6, 2], [2, 4, 1, 1]];
const _pieWords = {1: 'تُمن', 2: 'ربع', 4: 'نص', 6: 'تلات أرباع'};

Question pieChart(int lv, Rng r, {String? focus}) {
  final sizes = r.shuffle([...r.sample(_piePatterns)]);
  final visual = PieVisual(sizes);
  final names = pieColors.take(sizes.length).toList();
  final kind = r.sample(['biggest', 'part', if (lv >= 2) 'count']);
  final top = sizes.indexOf(sizes.reduce(math.max));
  const caption = CaptionVisual('اللون المفضل لتلاميذ الفصل');
  switch (kind) {
    case 'biggest':
      return _q('pieChart', 'pie:biggest', 'أنهي لون اختاره أكتر تلاميذ؟', [caption, visual], names, names[top], r, big: false,
          hint: 'أكبر قطاع في الدايرة هو الأكتر ☝️', speakHint: 'أكبر قطاع في الدايرة هو الأكتر');
    case 'count':
      final total = r.sample([8, 16, 40, 80]);
      final i = r.rnd(0, sizes.length - 1);
      final ans = total * sizes[i] ~/ 8;
      return _q('pieChart', 'pie:count', 'لو الفصل فيه ${ar(total)} تلميذ، كام واحد اختار ${names[i]}؟', [caption, visual],
          [ar(ans), ar(ans * 2 == total ? total : ans * 2), ar(sizes[i])], ar(ans), r, big: false,
          speak: 'اقرا السؤال وبص على الدايرة',
          hint: 'القطاع ده ${_pieWords[sizes[i]]} الدايرة، يعني ${_pieWords[sizes[i]]} العدد ☝️', speakHint: 'القطاع جزء من الدايرة، يعني نفس الجزء من العدد');
    default:
      final i = r.rnd(0, sizes.length - 1);
      final ans = _pieWords[sizes[i]]!;
      return _q('pieChart', 'pie:part', 'اللون ${names[i]} أخد قد إيه من الدايرة؟', [caption, visual],
          [ans, ...r.shuffle(_pieWords.values.where((w) => w != ans).toList()).take(2)], ans, r, big: false,
          speak: 'اللون ده أخد قد إيه من الدايرة؟',
          hint: 'الدايرة كلها ٨ أتمان: نصها ٤ وربعها ٢ ☝️', speakHint: 'الدايرة كلها تمن أتمان');
  }
}
