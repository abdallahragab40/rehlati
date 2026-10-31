/// دروس حساب سادسة ابتدائي (tool/SCHOOL_CURRICULUM_INDEX.md): قابلية القسمة والتحليل لعوامل أولية، الأعداد
/// الصحيحة والقيمة المطلقة، المقادير الجبرية والأسس والمتباينات، الإحصاء (المتوسط والوسيط والمنوال والمدى)،
/// النسبة والمعدل والنسبة المئوية، قسمة الكسور، المستوى الإحداثي بأرباعه، ومساحات المضلعات ومساحة السطح.
///
/// الأعداد السالبة بتتكتب بالكلام («سالب ٣») عشان علامة السالب ماتتقلبش في الكتابة من اليمين.
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

List<String> _three(int answer, Iterable<int> wrong) =>
    [ar(answer), ...{for (final w in wrong) if (w != answer && w >= 0) w}.take(2).map(ar)];

/// عدد صحيح بالكلام: «سالب ٣»، «صفر»، «٣».
String intWord(int n) => n < 0 ? 'سالب ${ar(-n)}' : (n == 0 ? 'صفر' : ar(n));

const _readProblem = 'اقرا المسألة وحلها';

// ---------------------------------------------------------------- قابلية القسمة

List<int> primeFactors(int n) {
  final out = <int>[];
  for (var d = 2; n > 1; d++) {
    while (n % d == 0) {
      out.add(d);
      n ~/= d;
    }
  }
  return out;
}

Question divisibility(int lv, Rng r, {String? focus}) {
  if (focus != 'prime' && r.chance(.5)) {
    final d = r.sample([2, 3, 5, 9, 10]);
    final right = d * r.rnd(11, 60);
    final wrong = <int>{};
    while (wrong.length < 2) {
      final x = r.rnd(20, 600);
      if (x % d != 0) wrong.add(x);
    }
    return _q('divisibility', 'div:$d', 'أنهي عدد يقبل القسمة على ${ar(d)}؟', const [], [ar(right), ...wrong.map(ar)], ar(right), r,
        speak: 'أنهي عدد يقبل القسمة؟',
        hint: switch (d) {
          2 => 'آحاده زوجي ☝️',
          3 => 'مجموع أرقامه يقبل القسمة على ٣ ☝️',
          5 => 'آحاده صفر أو ٥ ☝️',
          9 => 'مجموع أرقامه يقبل القسمة على ٩ ☝️',
          _ => 'آحاده صفر ☝️',
        },
        speakHint: 'افتكر قاعدة قابلية القسمة');
  }
  final n = r.sample([12, 18, 20, 24, 28, 30, 36, 40, 45, 48, 60]);
  final fs = primeFactors(n);
  String show(List<int> xs) => xs.map(ar).join(' × ');
  final merged = [fs[0] * fs[1], ...fs.skip(2)];
  final wrongProduct = [...fs.take(fs.length - 1), fs.last == 2 ? 3 : 2];
  return _q('divisibility', 'div:prime', 'التحليل لعوامل أولية للعدد ${ar(n)}؟', const [],
      [show(fs), show(merged), show(wrongProduct)], show(fs), r, big: false,
      speak: 'اختار التحليل لعوامل أولية',
      hint: 'كل العوامل لازم تبقى أولية، وحاصل ضربها = ${ar(n)} ☝️', speakHint: 'كل العوامل أولية، وحاصل ضربها يساوي العدد');
}

// ---------------------------------------------------------------- الأعداد الصحيحة

Question integers(int lv, Rng r, {String? focus}) {
  final kind = focus == 'abs'
      ? 'abs'
      : focus == 'numberLine'
          ? r.sample(['read', 'compare'])
          : r.sample(['read', 'compare', 'abs', if (lv >= 2) 'opposite']);
  switch (kind) {
    case 'read':
      final n = r.rnd(-5, 5);
      return _q('integers', 'int:read', 'النقطة أ بتمثل أنهي عدد؟', [NumberLineVisual(-5, 5, n)],
          [intWord(n), intWord(-n == n ? 1 : -n), intWord(n + 1)], intWord(n), r, big: false,
          hint: 'الأعداد السالبة على شمال الصفر، والموجبة على يمينه ☝️', speakHint: 'السالب على شمال الصفر، والموجب على يمينه');
    case 'compare':
      final a = r.rnd(-9, 9);
      var b = r.rnd(-9, 9);
      while (b == a) {
        b = r.rnd(-9, 9);
      }
      final bigger = r.chance(.5);
      return _q('integers', 'int:compare', bigger ? 'أنهي عدد أكبر؟' : 'أنهي عدد أصغر؟', const [], [intWord(a), intWord(b)],
          intWord(bigger ? math.max(a, b) : math.min(a, b)), r, big: false,
          hint: 'على خط الأعداد اللي على اليمين أكبر: سالب ٢ أكبر من سالب ٥ ☝️', speakHint: 'على خط الأعداد اللي على اليمين أكبر');
    case 'abs':
      final n = r.rnd(-20, 20);
      final answer = n.abs();
      return _q('integers', 'int:abs', 'القيمة المطلقة للعدد ${intWord(n)} كام؟', const [], [ar(answer), answer == 0 ? ar(1) : intWord(-answer), ar(answer + 2)], ar(answer), r,
          big: false, speak: 'احسب القيمة المطلقة',
          hint: 'القيمة المطلقة = بعد العدد عن الصفر، ومش سالبة (ممكن صفر) ☝️', speakHint: 'القيمة المطلقة بعد العدد عن الصفر');
    default:
      final n = r.rnd(1, 15) * (r.chance(.5) ? 1 : -1);
      return _q('integers', 'int:opposite', 'معكوس العدد ${intWord(n)} إيه؟', const [], [intWord(-n), intWord(n), ar(0)], intWord(-n), r,
          big: false, speak: 'إيه معكوس العدد؟',
          hint: 'المعكوس على نفس البعد من الصفر في الناحية التانية ☝️', speakHint: 'المعكوس على نفس البعد من الصفر في الناحية التانية');
  }
}

// ---------------------------------------------------------------- المقادير الجبرية

Question algebra6(int lv, Rng r, {String? focus}) {
  final kind = switch (focus) {
    'power' => 'power',
    'expression' => 'equiv',
    'solve' => r.sample(['inequality', 'twoStep']),
    'variables' => r.sample(['independent', 'dependent', 'value']),
    _ => r.sample(['power', 'equiv', 'inequality', 'twoStep']),
  };
  switch (kind) {
    case 'independent':
    case 'dependent':
    case 'value':
      final price = r.rnd(2, 12), count = r.rnd(3, 9);
      final context = CaptionVisual('سعر الكراسة ${ar(price)} جنيه. بنختار عدد الكراسات، والتكلفة بتتغير حسب العدد.');
      if (kind == 'value') {
        return _q('algebra6', 'alg:value', 'تكلفة ${ar(count)} كراسات كام جنيه؟', [context],
            _three(price * count, [price + count, price * (count + 1), price]), ar(price * count), r,
            speak: _readProblem,
            hint: 'التكلفة = سعر الكراسة × عدد الكراسات ☝️', speakHint: _readProblem);
      }
      final independent = kind == 'independent';
      final answer = independent ? 'عدد الكراسات' : 'التكلفة الكلية';
      return _q('algebra6', 'alg:$kind', independent ? 'أنهي متغير مستقل؟' : 'أنهي متغير تابع؟', [context],
          ['عدد الكراسات', 'التكلفة الكلية', 'سعر الكراسة الثابت'], answer, r, big: false, speak: _readProblem,
          hint: 'عدد الكراسات مستقل بنختاره، والتكلفة تابعة ليه. سعر الكراسة ثابت ☝️',
          speakHint: _readProblem);
    case 'power':
      final b = r.rnd(2, 5), e = r.rnd(2, b <= 3 ? 4 : 3);
      final v = math.pow(b, e).toInt();
      return _q('algebra6', 'alg:power', 'احسب قيمة القوة', [BigLetterVisual('${ar(b)} أُس ${ar(e)}')],
          _three(v, [b * e, v + b, b + e]), ar(v), r,
          hint: '${ar(b)} أُس ${ar(e)} = ${List.filled(e, ar(b)).join(' × ')} ☝️', speakHint: 'الأس بيقول نضرب العدد في نفسه كام مرة');
    case 'equiv':
      final a = r.rnd(2, 6), b = r.rnd(1, 9);
      final right = '${ar(a)}ن + ${ar(a * b)}';
      return _q('algebra6', 'alg:equiv', 'أنهي مقدار يكافئ المقدار ده؟', [BigLetterVisual('${ar(a)}(ن + ${ar(b)})')],
          [right, '${ar(a)}ن + ${ar(b)}', 'ن + ${ar(a * b)}'], right, r, big: false,
          hint: 'خاصية التوزيع: اضرب ${ar(a)} في كل حد جوه القوس ☝️', speakHint: 'اضرب العدد اللي بره في كل حد جوه القوس');
    case 'inequality':
      final k = r.rnd(3, 12);
      final right = k + r.rnd(1, 5);
      final wrong = [k, k - r.rnd(1, k)];
      return _q('algebra6', 'alg:inequality', 'أنهي عدد يحقق المتباينة؟', [BigLetterVisual('ن > ${ar(k)}')],
          _three(right, wrong), ar(right), r,
          hint: 'ن > ${ar(k)} يعني ن أكبر من ${ar(k)} (و${ar(k)} نفسها مش منهم) ☝️', speakHint: 'العلامة دي معناها أكبر من');
    default:
      final a = r.rnd(2, 5), x = r.rnd(2, 9), b = r.rnd(1, 9);
      return _q('algebra6', 'alg:twoStep', 'أوجد قيمة ن', [BigLetterVisual('${ar(a)}ن + ${ar(b)} = ${ar(a * x + b)}')],
          _three(x, [x + 1, (a * x + b) ~/ a, a * x]), ar(x), r,
          hint: 'اطرح ${ar(b)} من الناحيتين، وبعدين اقسم على ${ar(a)} ☝️', speakHint: 'اطرح الأول، وبعدين اقسم');
  }
}

// ---------------------------------------------------------------- الإحصاء

/// المتوسط والوسيط والمنوال والمدى لبيانات صغيرة. focus: center / spread.
Question statistics(int lv, Rng r, {String? focus}) {
  final kind = focus == 'spread' ? 'range' : r.sample(['mean', 'median', 'mode', if (focus != 'center') 'range']);
  // ٥ قيم مختلفة إلا في المنوال، والمجموع بيقبل القسمة على ٥
  var data = r.shuffle([for (final v in {for (var i = 0; i < 20; i++) r.rnd(1, 20)}.take(5)) v]);
  while (data.length < 5) {
    data = r.shuffle([for (final v in {for (var i = 0; i < 20; i++) r.rnd(1, 20)}.take(5)) v]);
  }
  if (kind == 'mean') {
    final fix = data.reduce((a, b) => a + b) % 5;
    data[0] = data[0] - fix <= 0 ? data[0] + 5 - fix : data[0] - fix;
  }
  if (kind == 'mode') data[4] = data[1];
  final sorted = [...data]..sort();
  final shown = CaptionVisual('البيانات: ${data.map(ar).join('، ')}');
  final sum = data.reduce((a, b) => a + b);
  switch (kind) {
    case 'mean':
      final m = sum ~/ 5;
      return _q('statistics', 'stat:mean', 'الوسط الحسابي (المتوسط) كام؟', [shown], _three(m, [sorted[2], m + 1, sum]), ar(m), r,
          hint: 'اجمع القيم (${ar(sum)}) واقسم على عددها (٥) ☝️', speakHint: 'اجمع القيم واقسم على عددها');
    case 'median':
      return _q('statistics', 'stat:median', 'الوسيط كام؟', [shown], _three(sorted[2], [data[2], sorted[1], sorted[3]]), ar(sorted[2]), r,
          hint: 'رتّب القيم: ${sorted.map(ar).join('، ')}، والوسيط اللي في النص ☝️', speakHint: 'رتب القيم، والوسيط اللي في النص');
    case 'mode':
      return _q('statistics', 'stat:mode', 'المنوال كام؟', [shown], _three(data[1], [sorted.first, sorted.last, sorted[2]]), ar(data[1]), r,
          hint: 'المنوال القيمة اللي اتكررت أكتر ☝️', speakHint: 'المنوال القيمة اللي اتكررت أكتر');
    default:
      final range = sorted.last - sorted.first;
      return _q('statistics', 'stat:range', 'المدى كام؟', [shown], _three(range, [sorted.last, sorted.first + sorted.last, range + 1]),
          ar(range), r,
          hint: 'المدى = أكبر قيمة − أصغر قيمة = ${ar(sorted.last)} − ${ar(sorted.first)} ☝️', speakHint: 'المدى أكبر قيمة ناقص أصغر قيمة');
  }
}

// ---------------------------------------------------------------- النسبة والمعدل والنسبة المئوية

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

String ratioText(int a, int b) => '${ar(a)} : ${ar(b)}';

/// focus: ratio / equiv / rate / percent.
Question ratios(int lv, Rng r, {String? focus}) {
  final kind = ['ratio', 'equiv', 'rate', 'percent'].contains(focus) ? focus! : r.sample(['ratio', 'equiv', 'rate', 'percent']);
  switch (kind) {
    case 'rate':
      final n = r.rnd(2, 9), price = r.rnd(2, 15);
      return _q('ratios', 'ratio:rate', '${ar(n)} أقلام بـ ${ar(n * price)} جنيه. سعر القلم الواحد كام؟', const [],
          _three(price, [n * price - n, price + 1, n]), ar(price), r, big: false, speak: _readProblem,
          hint: 'معدل الوحدة: ${ar(n * price)} ÷ ${ar(n)} ☝️', speakHint: 'اقسم التمن على عدد الحاجات');
    case 'percent':
      final p = r.sample([10, 20, 25, 50, 75]), total = r.sample([40, 60, 80, 120, 200]);
      final ans = total * p ~/ 100;
      return _q('ratios', 'ratio:percent', '${ar(p)}٪ من ${ar(total)} = كام؟', const [], _three(ans, [p, total - ans, ans * 2]), ar(ans), r,
          speak: 'احسب النسبة المئوية من العدد',
          hint: '${ar(p)}٪ = ${ar(p)} من ١٠٠، يعني ${ar(total)} × ${ar(p)} ÷ ١٠٠ ☝️', speakHint: 'النسبة المئوية جزء من مية');
    case 'equiv':
      final a = r.rnd(1, 5), b = r.rnd(2, 7), k = r.rnd(2, 6);
      if (a == b) return ratios(lv, r, focus: focus);
      return _q('ratios', 'ratio:equiv', 'كمّل النسبة المتكافئة', [ExprVisual([ExprTile(a), const ExprOp(':'), ExprTile(b), const ExprOp('='), ExprTile(a * k), const ExprOp(':'), const ExprTile(null)])],
          _three(b * k, [b + k, a * k, b * k + 1]), ar(b * k), r,
          hint: 'اتضرب ${ar(a)} في ${ar(k)}، فاضرب ${ar(b)} في ${ar(k)} ☝️', speakHint: 'اضرب الحدين في نفس العدد');
    default:
      final g = r.rnd(2, 6), a = r.rnd(1, 5), b = r.rnd(2, 7);
      if (_gcd(a, b) != 1 || a == b) return ratios(lv, r, focus: 'ratio');
      return _q('ratios', 'ratio:simplest', 'في الفصل ${ar(a * g)} ولد و${ar(b * g)} بنت. نسبة الأولاد للبنات في أبسط صورة؟', const [],
          [ratioText(a, b), ratioText(b, a), ratioText(a + 1, b)], ratioText(a, b), r, big: false, speak: _readProblem,
          hint: 'اقسم العددين على ${ar(g)}، والأولاد الأول ☝️', speakHint: 'اقسم العددين على أكبر عامل مشترك');
  }
}

// ---------------------------------------------------------------- قسمة الكسور

bool _same(String a, String b) {
  final x = a.split('/').map(int.parse).toList(), y = b.split('/').map(int.parse).toList();
  return x[0] * y[1] == y[0] * x[1];
}

Question fractionDiv6(int lv, Rng r, {String? focus}) {
  final b = r.rnd(2, 8), d = r.rnd(2, 8), a = r.rnd(1, b - 1), c = r.rnd(1, d - 1);
  final ans = '${a * d}/${b * c}';
  final wrong = ['${a * c}/${b * d}', '${b * c}/${a * d}', '${a * d}/${b * d}'];
  final options = [ans, ...{for (final w in wrong) if (!_same(w, ans)) w}.take(2)];
  if (options.length < 2) return fractionDiv6(lv, r, focus: focus);
  return _q('fractionDiv6', 'fracdiv', 'اقسم الكسرين',
      [ExprVisual([ExprTile('$a/$b'), const ExprOp('÷'), ExprTile('$c/$d'), const ExprOp('='), const ExprTile(null)])],
      options, ans, r, look: ChoiceLook.fraction,
      hint: 'اضرب في مقلوب الكسر التاني: ${ar(a)}/${ar(b)} × ${ar(d)}/${ar(c)} ☝️', speakHint: 'اضرب في مقلوب الكسر التاني');
}

// ---------------------------------------------------------------- المستوى الإحداثي بأرباعه

const _quadrants = ['الربع الأول', 'الربع الثاني', 'الربع الثالث', 'الربع الرابع'];

Question quadrants(int lv, Rng r, {String? focus}) {
  if (r.chance(.5)) {
    var x = r.rnd(-4, 4), y = r.rnd(-4, 4);
    while (x == 0 || y == 0) {
      x = r.rnd(-4, 4);
      y = r.rnd(-4, 4);
    }
    final q = x > 0 ? (y > 0 ? 0 : 3) : (y > 0 ? 1 : 2);
    return _q('quadrants', 'quad:which', 'النقطة أ في أنهي ربع؟', [CoordVisual([('أ', x, y)], lo: -4, hi: 4)], _quadrants, _quadrants[q], r,
        big: false,
        hint: 'الربع الأول فوق على اليمين، والتاني فوق على الشمال، والتالت تحت على الشمال، والرابع تحت على اليمين ☝️',
        speakHint: 'الأول فوق يمين، والتاني فوق شمال، والتالت تحت شمال، والرابع تحت يمين');
  }
  final y = r.rnd(-4, 4), x1 = r.rnd(-4, 0), x2 = r.rnd(1, 4);
  final horizontal = r.chance(.5);
  final pts = horizontal ? [('أ', x1, y), ('ب', x2, y)] : [('أ', y, x1), ('ب', y, x2)];
  final dist = x2 - x1;
  return _q('quadrants', 'quad:distance', 'المسافة بين النقطتين أ و ب كام وحدة؟', [CoordVisual(pts, lo: -4, hi: 4)],
      _three(dist, [dist + 1, x2, (x1).abs()]), ar(dist), r,
      hint: 'عدّ المربعات بين النقطتين، أو اجمع بعد كل نقطة عن المحور ☝️', speakHint: 'عد الوحدات بين النقطتين');
}

// ---------------------------------------------------------------- المساحات ومساحة السطح

/// متوازي أضلاع، مثلث، شبه منحرف، ومساحة سطح متوازي مستطيلات. focus: area / surface.
Question area6(int lv, Rng r, {String? focus}) {
  final kind = focus == 'surface' ? 'surface' : r.sample(['parallelogram', 'triangle', 'trapezoid', if (focus != 'area') 'surface']);
  switch (kind) {
    case 'triangle':
      final b = r.rnd(2, 8) * 2, h = r.rnd(3, 9);
      return _q('area6', 'area:triangle', 'مساحة المثلث كام؟',
          [ComposeVisual([[(0.0, 0.0), (b.toDouble(), 0.0), (b * .35, h.toDouble())]]), CaptionVisual('القاعدة ${ar(b)} والارتفاع ${ar(h)}')],
          _three(b * h ~/ 2, [b * h, b + h, b * h ~/ 2 + b]), ar(b * h ~/ 2), r,
          hint: 'مساحة المثلث = ½ × القاعدة × الارتفاع ☝️', speakHint: 'نص القاعدة في الارتفاع');
    case 'trapezoid':
      final a = r.rnd(3, 8), b = a + r.rnd(1, 3) * 2, h = r.rnd(2, 7);
      final ans = (a + b) * h ~/ 2;
      return _q('area6', 'area:trapezoid', 'مساحة شبه المنحرف كام؟',
          [
            ComposeVisual([[(0.0, 0.0), (b.toDouble(), 0.0), ((b + a) / 2, h.toDouble()), ((b - a) / 2, h.toDouble())]]),
            CaptionVisual('القاعدتين ${ar(a)} و${ar(b)} والارتفاع ${ar(h)}'),
          ],
          _three(ans, [(a + b) * h, a * b, ans + h]), ar(ans), r,
          hint: 'المساحة = ½ × (مجموع القاعدتين) × الارتفاع ☝️', speakHint: 'نص مجموع القاعدتين في الارتفاع');
    case 'surface':
      final l = r.rnd(2, 5), w = r.rnd(2, 4), h = r.rnd(2, 4);
      final ans = 2 * (l * w + l * h + w * h);
      return _q('area6', 'area:surface', 'مساحة السطح الكلية للصندوق كام وحدة مربعة؟', [BoxVisual(l, w, h)],
          _three(ans, [l * w * h, l * w + l * h + w * h, ans + 2]), ar(ans), r,
          hint: 'مساحة السطح = مجموع مساحات الأوجه الستة = ٢ × (طع + طل + عل) ☝️', speakHint: 'اجمع مساحات الأوجه الستة');
    default:
      final b = r.rnd(3, 10), h = r.rnd(2, 8);
      return _q('area6', 'area:parallelogram', 'مساحة متوازي الأضلاع كام؟',
          [
            ComposeVisual([[(0.0, 0.0), (b.toDouble(), 0.0), (b + 1.5, h.toDouble()), (1.5, h.toDouble())]]),
            CaptionVisual('القاعدة ${ar(b)} والارتفاع ${ar(h)}'),
          ],
          _three(b * h, [2 * (b + h), b * h ~/ 2, b + h]), ar(b * h), r,
          hint: 'مساحة متوازي الأضلاع = القاعدة × الارتفاع ☝️', speakHint: 'القاعدة في الارتفاع');
  }
}
