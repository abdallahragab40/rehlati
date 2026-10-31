/// دروس حساب رابعة ابتدائي (tool/SCHOOL_CURRICULUM_INDEX.md): التقريب، الجمع والطرح بإعادة التسمية،
/// تحويل وحدات القياس، الضرب كعلاقة وخواصه، العوامل والمضاعفات، الضرب والقسمة الطويلة، ترتيب العمليات،
/// الكسور، الكسور العشرية، والهندسة (الزوايا والخطوط والمثلثات والأشكال الرباعية).
///
/// الأعداد الكبيرة مكتوبة ومش بتتنطق (choiceSay فاضي) — السؤال بس اللي بيتقال.
library;

import 'dart:math' as math;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

Map<Object, String> _silent(Iterable<String> xs) => {for (final x in xs) x: ''};

/// سؤال اختيار بأرقام مكتوبة: السؤال ثابت بيتقال، والاختيارات من غير صوت.
/// [speak] لو السؤال فيه أعداد: جملة ثابتة بتتقال والأعداد مكتوبة بس (وإلا كل مسألة محتاجة تسجيل لوحدها).
Question _q(String type, String skill, String ask, List<Visual> visuals, List<String> choices, String answer, Rng r,
        {required String hint, required String speakHint, bool big = true, String? speak}) =>
    Question(
      type: type, mode: QMode.choice, skill: skill, numeric: false, bigChoices: big, wide: !big,
      ask: ask, speak: speak ?? ask, clips: [say(speak ?? ask)],
      visuals: visuals,
      choices: r.shuffle(choices.toSet().toList()), answer: answer, choiceSay: _silent(choices),
      hint: hint, speakHint: speakHint, clipsHint: [say(speakHint)],
    );

/// تلات اختيارات مختلفة: الصح واتنين من [wrong] (بعد شيل المكرر والسالب).
List<String> _three(int answer, Iterable<int> wrong) =>
    [ar(answer), ...{for (final w in wrong) if (w != answer && w >= 0) w}.take(2).map(ar)];

// ---------------------------------------------------------------- التقريب

Question roundLarge(int lv, Rng r, {String? focus}) {
  final n = r.rnd(1000, lv <= 2 ? 9999 : 99999);
  final place = r.sample(lv <= 1 ? [10, 100] : [10, 100, 1000]);
  final down = n ~/ place * place, up = down + place;
  final answer = n % place >= place ~/ 2 ? up : down;
  final name = {10: 'عشرة', 100: 'مئة', 1000: 'ألف'}[place]!;
  return _q('roundLarge', 'round:$place', 'قرّب العدد ده لأقرب $name', [BigLetterVisual(ar(n))],
      _three(answer, [answer == up ? down : up, answer + place * 10, n]), ar(answer), r,
      hint: 'بص على الرقم اللي على يمين خانة الـ$name: ٥ أو أكتر نطلع، أقل ننزل ☝️',
      speakHint: 'بص على الرقم اللي بعد الخانة: خمسة أو أكتر نطلع، وأقل ننزل');
}

// ---------------------------------------------------------------- الجمع والطرح بإعادة التسمية

Question bigAddSub(int lv, Rng r, {String? focus}) {
  final digits = lv <= 2 ? 3 : 4;
  final lo = math.pow(10, digits - 1).toInt(), hi = math.pow(10, digits).toInt() - 1;
  if (lv >= 3 && r.chance(.3)) {
    // مسألة خطوتين
    final money = r.rnd(20, 90) * 10, spent = r.rnd(5, money ~/ 10 - 2) * 10, got = r.rnd(5, 40) * 10;
    final answer = money - spent + got;
    return _q('bigAddSub', 'addsub:steps',
        'مع سارة ${ar(money)} جنيه، صرفت ${ar(spent)} وبعدين أخدت ${ar(got)}. بقى معاها كام؟', const [],
        _three(answer, [money - spent, money + spent + got, answer + 100]), ar(answer), r, big: false, speak: 'اقرا المسألة وحلها',
        hint: 'خطوة خطوة: ${ar(money)} − ${ar(spent)} = ${ar(money - spent)}، وبعدين + ${ar(got)} ☝️',
        speakHint: 'خطوة خطوة: اطرح الأول وبعدين اجمع');
  }
  final add = r.chance(.5);
  var a = r.rnd(lo, hi), b = r.rnd(lo, hi);
  if (!add && b > a) (a, b) = (b, a);
  if (add && a + b > 99999) b = lo;
  final answer = add ? a + b : a - b;
  return _q('bigAddSub', 'addsub:${add ? 'add' : 'sub'}', add ? 'اجمع' : 'اطرح',
      [ExprVisual([ExprTile(a), ExprOp(add ? '+' : '−'), ExprTile(b), const ExprOp('='), const ExprTile(null)])],
      _three(answer, [answer + 10, answer - 10, answer + 100, answer - 100]), ar(answer), r,
      hint: 'ابدأ من الآحاد، ولو احتجت سلّف من الخانة اللي بعدها ☝️', speakHint: 'ابدأ من الآحاد، ولو احتجت سلف من الخانة اللي بعدها');
}

// ---------------------------------------------------------------- تحويل الوحدات

/// (الوحدة الكبيرة، الصغيرة، كام صغيرة في الكبيرة).
const unitPairs = [
  ('متر', 'سنتيمتر', 100), ('كيلومتر', 'متر', 1000), ('كيلوجرام', 'جرام', 1000), ('لتر', 'ملليلتر', 1000),
  ('ساعة', 'دقيقة', 60), ('يوم', 'ساعة', 24), ('دقيقة', 'ثانية', 60), ('سنتيمتر', 'ملليمتر', 10),
];

/// الساعة مكتوبة «٣:٤٥».
String clockText(int minutes) => '${ar(minutes ~/ 60)}:${ar((minutes % 60).toString().padLeft(2, '0'))}';

/// الوقت المنقضي: من ساعة لساعة، مع عبور الساعة. المدة كام دقيقة؟ أو خلص الساعة كام؟
Question _elapsed(int lv, Rng r) {
  // ساعة ١٢ زي ساعة الحيطة (من ١ لـ ١٠ والنهاية مابتعديش ١٢:٥٩)
  final start = r.rnd(1, 10) * 60 + r.rnd(0, 11) * 5;
  final dur = lv <= 2 ? r.rnd(2, 11) * 5 + 20 : r.rnd(5, 20) * 5;
  final end = start + dur;
  if (r.chance(.5)) {
    return _q('unitConvert', 'unit:elapsed', 'بدأ الفيلم الساعة ${clockText(start)} وخلص الساعة ${clockText(end)}. مدته كام دقيقة؟',
        const [], _three(dur, [dur + 60, (dur - 60).abs(), dur + 5]), ar(dur), r, big: false, speak: 'اقرا المسألة وحلها',
        hint: 'عدّ من ${clockText(start)} لحد الساعة اللي بعدها، وبعدين كمّل للنهاية ☝️', speakHint: 'عد لحد الساعة اللي بعدها وبعدين كمل');
  }
  final wrong = [end + 60, end - 60, start + dur % 60 + (dur ~/ 60) * 100];
  return _q('unitConvert', 'unit:elapsed', 'خرجت سارة الساعة ${clockText(start)} ورجعت بعد ${ar(dur)} دقيقة. رجعت الساعة كام؟',
      const [], [clockText(end), ...{for (final w in wrong) if (w != end && w > 0 && w % 60 < 60) clockText(w)}.take(2)], clockText(end), r,
      big: false, speak: 'اقرا المسألة وحلها',
      hint: 'الساعة فيها ٦٠ دقيقة: زوّد الدقايق، ولو عدّت ٦٠ زوّد ساعة ☝️', speakHint: 'الساعة فيها ستين دقيقة');
}

/// focus: elapsed (الوقت المنقضي بس).
Question unitConvert(int lv, Rng r, {String? focus}) {
  if (focus == 'elapsed' || (focus == null && lv >= 3 && r.chance(.3))) return _elapsed(lv, r);
  final (big, small, k) = r.sample(lv <= 1 ? unitPairs.where((p) => p.$3 <= 100).toList() : unitPairs);
  final n = r.rnd(2, 9);
  final toSmall = lv <= 2 || r.chance(.6);
  final answer = toSmall ? n * k : n;
  final ask = toSmall ? '${ar(n)} $big = كام $small؟' : '${ar(n * k)} $small = كام $big؟';
  final wrong = toSmall ? [n * k * 10, n * k ~/ 10, n + k] : [n * 10, n * k, n + 1];
  return _q('unitConvert', 'unit:$big', ask, [CaptionVisual('١ $big = ${ar(k)} $small')], _three(answer, wrong), ar(answer), r,
      speak: toSmall ? 'حوّل من $big لـ $small' : 'حوّل من $small لـ $big',
      hint: toSmall ? 'من الكبير للصغير بنضرب في ${ar(k)} ☝️' : 'من الصغير للكبير بنقسم على ${ar(k)} ☝️',
      speakHint: toSmall ? 'من الكبير للصغير بنضرب' : 'من الصغير للكبير بنقسم');
}

// ---------------------------------------------------------------- الضرب كعلاقة وخواصه

Question mulCompare(int lv, Rng r, {String? focus}) {
  if (r.chance(.5)) {
    final a = r.rnd(2, 9), times = r.rnd(2, lv <= 1 ? 5 : 9);
    return _q('mulCompare', 'mul:times', 'مع أحمد ${ar(a)} أقلام، ومع سارة ${ar(times)} أمثال أحمد. مع سارة كام قلم؟', const [],
        _three(a * times, [a + times, a * times + a, a * times - a]), ar(a * times), r, big: false, speak: 'اقرا المسألة وحلها',
        hint: '«${ar(times)} أمثال» يعني نضرب: ${ar(a)} × ${ar(times)} ☝️', speakHint: 'كذا أمثال يعني نضرب');
  }
  final a = r.rnd(2, 12);
  return switch (r.rnd(0, 2)) {
    0 => _q('mulCompare', 'mul:identity', 'خاصية العنصر المحايد',
        [ExprVisual([ExprTile(a), const ExprOp('×'), const ExprTile(1), const ExprOp('='), const ExprTile(null)])],
        _three(a, [a + 1, 1, 0]), ar(a), r, hint: 'أي عدد × ١ = نفسه ☝️', speakHint: 'أي عدد في واحد يساوي نفسه'),
    1 => _q('mulCompare', 'mul:zero', 'الضرب في صفر',
        [ExprVisual([ExprTile(a), const ExprOp('×'), const ExprTile(0), const ExprOp('='), const ExprTile(null)])],
        _three(0, [a, 1, a * 10]), ar(0), r, hint: 'أي عدد × ٠ = ٠ ☝️', speakHint: 'أي عدد في صفر يساوي صفر'),
    _ => () {
        final b = r.rnd(2, 9);
        return _q('mulCompare', 'mul:commutative', 'خاصية الإبدال',
            [ExprVisual([ExprTile(a), const ExprOp('×'), ExprTile(b), const ExprOp('='), ExprTile(b), const ExprOp('×'), const ExprTile(null)])],
            _three(a, [b, a + b, a * b]), ar(a), r, hint: 'لو بدّلنا مكان العددين الناتج مايتغيرش ☝️',
            speakHint: 'لو بدلنا مكان العددين الناتج مايتغيرش');
      }(),
  };
}

// ---------------------------------------------------------------- العوامل والمضاعفات

bool _prime(int n) => n > 1 && [for (var d = 2; d * d <= n; d++) d].every((d) => n % d != 0);

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

/// focus: factors / multiples / gcf / common.
Question factors(int lv, Rng r, {String? focus}) {
  final kind = switch (focus) {
    'gcf' || 'common' => focus!,
    'multiples' => r.sample(['multiple', if (lv >= 2) 'common']),
    'factors' => r.sample(['factor', 'prime', if (lv >= 2) 'gcf']),
    _ => r.sample(['factor', 'prime', 'multiple', if (lv >= 2) 'gcf', if (lv >= 2) 'common']),
  };
  switch (kind) {
    case 'factor':
      final n = r.sample([12, 18, 20, 24, 30, 36]);
      final fs = [for (var d = 2; d < n; d++) if (n % d == 0) d];
      final right = r.sample(fs);
      final not = r.shuffle([for (var d = 2; d < n; d++) if (n % d != 0) d]).take(2);
      return _q('factors', 'factors:factor', 'أنهي عدد من عوامل ${ar(n)}؟', const [], [ar(right), ...not.map(ar)], ar(right), r,
          hint: 'العامل بيقسم العدد من غير باقي ☝️', speakHint: 'العامل بيقسم العدد من غير باقي');
    case 'prime':
      final primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29].where((p) => lv >= 2 || p < 20).toList();
      final right = r.sample(primes);
      final composites = r.shuffle([for (var n = 4; n <= 30; n++) if (!_prime(n)) n]).take(2);
      return _q('factors', 'factors:prime', 'أنهي عدد أولي؟', const [], [ar(right), ...composites.map(ar)], ar(right), r,
          hint: 'العدد الأولي ليه عاملين بس: ١ ونفسه ☝️', speakHint: 'العدد الأولي ليه عاملين بس، واحد ونفسه');
    case 'gcf':
      final g = r.sample([2, 3, 4, 5, 6]);
      var a = g * r.rnd(2, 6), b = g * r.rnd(2, 6);
      while (_gcd(a, b) != g || a == b) {
        a = g * r.rnd(2, 6);
        b = g * r.rnd(2, 6);
      }
      return _q('factors', 'factors:gcf', 'العامل المشترك الأكبر للعددين ${ar(a)} و${ar(b)} كام؟', const [],
          _three(g, [g * 2, 1, math.min(a, b)]), ar(g), r, speak: 'احسب العامل المشترك الأكبر',
          hint: 'اكتب عوامل كل عدد، وخد أكبر عامل موجود في الاتنين ☝️', speakHint: 'اكتب عوامل كل عدد، وخد أكبر عامل مشترك');
    case 'common':
      final pairs = [(2, 3), (3, 4), (4, 6), (2, 5), (3, 5), (4, 5)];
      final (a, b) = r.sample(pairs);
      final lcm = a * b ~/ _gcd(a, b);
      return _q('factors', 'factors:common', 'أصغر مضاعف مشترك للعددين ${ar(a)} و${ar(b)}؟', const [],
          _three(lcm, [a * b + a, lcm + b, lcm * 2]), ar(lcm), r, speak: 'احسب أصغر مضاعف مشترك',
          hint: 'اكتب مضاعفات كل عدد لحد ما تلاقي أول عدد في الاتنين ☝️', speakHint: 'اكتب مضاعفات كل عدد لحد أول عدد مشترك');
    default:
      final n = r.rnd(3, 9), k = r.rnd(2, 9);
      final right = n * k;
      final not = r.shuffle([for (var x = n + 1; x < n * 10; x++) if (x % n != 0) x]).take(2);
      return _q('factors', 'factors:multiple', 'أنهي عدد من مضاعفات ${ar(n)}؟', const [], [ar(right), ...not.map(ar)], ar(right), r,
          hint: 'المضاعف = ${ar(n)} × عدد صحيح ☝️', speakHint: 'المضاعف هو العدد مضروب في عدد صحيح');
  }
}

// ---------------------------------------------------------------- الضرب والقسمة الطويلة

/// focus: mul / div.
Question longMulDiv(int lv, Rng r, {String? focus}) {
  final mul = focus == 'mul' || (focus != 'div' && r.chance(.5));
  if (mul) {
    final a = r.rnd(12, lv <= 2 ? 99 : 99), b = lv >= 3 && r.chance(.5) ? r.rnd(11, 30) : r.rnd(2, 9);
    final answer = a * b;
    return _q('longMulDiv', 'long:mul${b > 9 ? '2' : '1'}', 'اضرب',
        [ExprVisual([ExprTile(a), const ExprOp('×'), ExprTile(b), const ExprOp('='), const ExprTile(null)])],
        _three(answer, [answer + b, answer - a, answer + 10]), ar(answer), r,
        hint: 'جزّئ العدد: ${ar(a)} = ${ar(a ~/ 10 * 10)} + ${ar(a % 10)}، واضرب كل جزء ☝️',
        speakHint: 'جزئ العدد لعشرات وآحاد، واضرب كل جزء');
  }
  final d = r.rnd(2, 9), q = r.rnd(3, lv <= 2 ? 12 : 25), rem = r.rnd(0, d - 1);
  final n = d * q + rem;
  String say(int qq, int rr) => rr == 0 ? ar(qq) : '${ar(qq)} والباقي ${ar(rr)}';
  final right = say(q, rem);
  final options = {right, say(q + 1, rem == 0 ? 1 : rem - 1), say(q - 1, rem + d < 10 ? rem + d : rem), say(q, (rem + 1) % d)};
  return _q('longMulDiv', 'long:div', 'اقسم',
      [ExprVisual([ExprTile(n), const ExprOp('÷'), ExprTile(d), const ExprOp('='), const ExprTile(null)])],
      options.take(3).toList(), right, r, big: false,
      hint: 'كام مرة ${ar(d)} في ${ar(n)}؟ واللي يفضل هو الباقي (لازم أصغر من ${ar(d)}) ☝️',
      speakHint: 'كام مرة المقسوم عليه في العدد، واللي يفضل هو الباقي');
}

// ---------------------------------------------------------------- ترتيب العمليات

Question orderOps(int lv, Rng r, {String? focus}) {
  final a = r.rnd(2, 9), b = r.rnd(2, 6), c = r.rnd(2, 6);
  if (lv >= 2 && r.chance(.5)) {
    final answer = (a + b) * c;
    return _q('orderOps', 'ops:paren', 'احسب: الأقواس الأول',
        [ExprVisual([const ExprOp('('), ExprTile(a), const ExprOp('+'), ExprTile(b), const ExprOp(')'), const ExprOp('×'), ExprTile(c), const ExprOp('='), const ExprTile(null)])],
        _three(answer, [a + b * c, answer + c, answer - 1]), ar(answer), r,
        hint: 'اللي جوه الأقواس الأول: ${ar(a + b)} × ${ar(c)} ☝️', speakHint: 'اللي جوه الأقواس الأول');
  }
  final answer = a + b * c;
  return _q('orderOps', 'ops:mulFirst', 'احسب: الضرب قبل الجمع',
      [ExprVisual([ExprTile(a), const ExprOp('+'), ExprTile(b), const ExprOp('×'), ExprTile(c), const ExprOp('='), const ExprTile(null)])],
      _three(answer, [(a + b) * c, answer + 1, a * b + c]), ar(answer), r,
      hint: 'الضرب الأول: ${ar(b)} × ${ar(c)} = ${ar(b * c)}، وبعدين نجمع ☝️', speakHint: 'الضرب قبل الجمع');
}

// ---------------------------------------------------------------- الكسور

/// كسر بالأرقام العربي «٣/٧» (بيتعرض صح جوه سطر من اليمين).
String _f(int n, int d) => '$n/$d';

/// جمع وطرح بنفس المقام، الأعداد الكسرية، المقارنة، وضرب كسر في عدد. focus: addsub / compare / times.
Question fractionOps(int lv, Rng r, {String? focus}) {
  final kind = ['addsub', 'compare', 'times', 'mixed'].contains(focus)
      ? focus!
      : r.sample(['addsub', 'compare', if (lv >= 2) 'times', if (lv >= 2) 'mixed']);
  final d = r.sample([4, 5, 6, 7, 8, 9, 10]);
  switch (kind) {
    case 'compare':
      final a = r.rnd(1, d - 1);
      var b = r.rnd(1, d - 1);
      while (b == a) {
        b = r.rnd(1, d - 1);
      }
      final bigger = r.chance(.5);
      final answer = (bigger ? math.max(a, b) : math.min(a, b));
      return Question(
        type: 'fractionOps', mode: QMode.choice, skill: 'frac:compare', numeric: false, look: ChoiceLook.fraction,
        ask: bigger ? 'أنهي كسر أكبر؟' : 'أنهي كسر أصغر؟', speak: bigger ? 'أنهي كسر أكبر؟' : 'أنهي كسر أصغر؟',
        clips: [say(bigger ? 'أنهي كسر أكبر؟' : 'أنهي كسر أصغر؟')],
        choices: r.shuffle([_f(a, d), _f(b, d)]), answer: _f(answer, d),
        choiceSay: {_f(a, d): '', _f(b, d): ''},
        hint: 'نفس المقام: اللي بسطه أكبر يبقى أكبر ☝️', speakHint: 'نفس المقام، اللي بسطه أكبر يبقى أكبر',
        clipsHint: [say('نفس المقام، اللي بسطه أكبر يبقى أكبر')],
      );
    case 'times':
      final n = r.rnd(1, d - 1), k = r.rnd(2, 5);
      final options = {_f(n * k, d), _f(n * k, d * k), _f(n + k, d)}.toList();
      return Question(
        type: 'fractionOps', mode: QMode.choice, skill: 'frac:times', numeric: false, look: ChoiceLook.fraction,
        ask: 'اضرب الكسر في العدد', speak: 'اضرب الكسر في العدد', clips: [say('اضرب الكسر في العدد')],
        visuals: [ExprVisual([ExprTile(k), const ExprOp('×'), ExprTile(_f(n, d)), const ExprOp('='), const ExprTile(null)])],
        choices: r.shuffle(options), answer: _f(n * k, d), choiceSay: {for (final o in options) o: ''},
        hint: 'بنضرب البسط بس، والمقام زي ما هو ☝️', speakHint: 'بنضرب البسط بس، والمقام زي ما هو',
        clipsHint: [say('بنضرب البسط بس، والمقام زي ما هو')],
      );
    case 'mixed':
      final whole = r.rnd(1, 3), n = r.rnd(1, d - 1);
      final improper = whole * d + n;
      final options = {_f(improper, d), _f(whole + n, d), _f(whole * n, d)}.toList();
      return Question(
        type: 'fractionOps', mode: QMode.choice, skill: 'frac:mixed', numeric: false, look: ChoiceLook.fraction,
        ask: 'العدد الكسري ده يساوي أنهي كسر؟', speak: 'العدد الكسري ده يساوي أنهي كسر؟',
        clips: [say('العدد الكسري ده يساوي أنهي كسر؟')],
        visuals: [BigLetterVisual('${ar(whole)} و ${ar(n)}/${ar(d)}')],
        choices: r.shuffle(options), answer: _f(improper, d), choiceSay: {for (final o in options) o: ''},
        hint: '${ar(whole)} صحيح = ${ar(whole * d)}/${ar(d)}، ونزوّد ${ar(n)} ☝️',
        speakHint: 'حول الصحيح لكسر بنفس المقام وزود البسط', clipsHint: [say('حول الصحيح لكسر بنفس المقام وزود البسط')],
      );
    default:
      final add = r.chance(.5);
      var a = r.rnd(1, d - 1), b = r.rnd(1, d - 1);
      if (add) {
        while (a + b > d) {
          b = r.rnd(1, d - a);
        }
      } else {
        if (b > a) (a, b) = (b, a);
        if (a == b) a = a == d - 1 ? a : a + 1;
        if (a == b) b = b - 1;
      }
      final n = add ? a + b : a - b;
      final options = {_f(n, d), _f(n, add ? d * 2 : d + 1), _f(add ? n + 1 : n + 2, d)}.toList();
      return Question(
        type: 'fractionOps', mode: QMode.choice, skill: 'frac:${add ? 'add' : 'sub'}', numeric: false, look: ChoiceLook.fraction,
        ask: add ? 'اجمع الكسرين' : 'اطرح الكسرين', speak: add ? 'اجمع الكسرين' : 'اطرح الكسرين',
        clips: [say(add ? 'اجمع الكسرين' : 'اطرح الكسرين')],
        visuals: [ExprVisual([ExprTile(_f(a, d)), ExprOp(add ? '+' : '−'), ExprTile(_f(b, d)), const ExprOp('='), const ExprTile(null)])],
        choices: r.shuffle(options), answer: _f(n, d), choiceSay: {for (final o in options) o: ''},
        hint: 'نفس المقام: بنجمع أو نطرح البسط بس، والمقام زي ما هو ☝️', speakHint: 'نفس المقام، بنحسب البسط بس',
        clipsHint: [say('نفس المقام، بنحسب البسط بس')],
      );
  }
}

// ---------------------------------------------------------------- الكسور العشرية

/// ٠٫٣٧ بالأرقام العربي وفاصلة عشرية.
String arDecimal(int hundredths, {bool tenths = false}) {
  final whole = hundredths ~/ 100, frac = hundredths % 100;
  final digits = tenths ? '${frac ~/ 10}' : frac.toString().padLeft(2, '0');
  return '${ar(whole)}٫${ar(digits)}';
}

Question decimals(int lv, Rng r, {String? focus}) {
  final kind = r.sample(['toDecimal', 'compare', if (lv >= 2) 'add']);
  switch (kind) {
    case 'compare':
      final a = r.rnd(1, 99), b = r.rnd(1, 99);
      if (a == b) return decimals(lv, r, focus: focus);
      final bigger = r.chance(.5);
      final ans = bigger ? math.max(a, b) : math.min(a, b);
      return _q('decimals', 'dec:compare', bigger ? 'أنهي عدد أكبر؟' : 'أنهي عدد أصغر؟', const [],
          [arDecimal(a), arDecimal(b)], arDecimal(ans), r,
          hint: 'قارن الأعشار الأول، ولو زي بعض قارن الأجزاء من مئة ☝️', speakHint: 'قارن الأعشار الأول، وبعدين الأجزاء من مئة');
    case 'add':
      final a = r.rnd(1, 8) * 10, b = r.rnd(1, 9 - a ~/ 10) * 10 + r.rnd(0, 9);
      final ans = a + b;
      return _q('decimals', 'dec:add', 'اجمع الكسرين العشريين', [BigLetterVisual('${arDecimal(a, tenths: true)} + ${arDecimal(b)}')],
          [arDecimal(ans), arDecimal(a ~/ 10 + b), arDecimal(ans + 10)], arDecimal(ans), r,
          hint: '${arDecimal(a, tenths: true)} = ${arDecimal(a)}، وبعدين نجمع الأجزاء من مئة ☝️',
          speakHint: 'حول الأعشار لأجزاء من مئة وبعدين اجمع');
    default:
      final tenths = lv <= 1 || r.chance(.4);
      final n = tenths ? r.rnd(1, 9) * 10 : r.rnd(1, 99);
      final shown = tenths ? '${ar(n ~/ 10)} على ١٠' : '${ar(n)} على ١٠٠';
      final right = arDecimal(n, tenths: tenths);
      // الغلط: الرقم في الخانة الغلط
      final wrong = tenths
          ? ['${ar(n ~/ 10)}٫٠', '٠٫٠${ar(n ~/ 10)}']
          : ['${ar(n ~/ 10)}٫${ar(n % 10)}', '${ar(n)}٫٠'];
      return _q('decimals', 'dec:${tenths ? 'tenths' : 'hundredths'}', 'اكتب الكسر ده كسر عشري', [BigLetterVisual(shown)],
          [right, ...wrong], right, r,
          hint: tenths ? 'الأعشار في أول خانة بعد الفاصلة ☝️' : 'الأجزاء من مئة في خانتين بعد الفاصلة ☝️',
          speakHint: tenths ? 'الأعشار في أول خانة بعد الفاصلة' : 'الأجزاء من مئة في خانتين بعد الفاصلة');
  }
}

// ---------------------------------------------------------------- الهندسة

const _angleKinds = ['زاوية حادة', 'زاوية قائمة', 'زاوية منفرجة'];

/// المثلثات: (النقط، النوع حسب الزوايا).
const _triangles = [
  ([(0.0, 0.0), (4.0, 0.0), (0.0, 3.0)], 'مثلث قائم الزاوية'),
  ([(0.0, 0.0), (4.0, 0.0), (2.0, 3.4)], 'مثلث حاد الزوايا'),
  ([(0.0, 0.0), (5.0, 0.0), (-1.5, 1.6)], 'مثلث منفرج الزاوية'),
  ([(0.0, 0.0), (3.0, 0.0), (3.0, 3.0)], 'مثلث قائم الزاوية'),
  ([(0.0, 0.0), (5.0, 0.0), (6.5, 1.8)], 'مثلث منفرج الزاوية'),
];

/// الأشكال الرباعية: (النقط، الاسم، أسماء غلط أكيد). المربع مستطيل ومتوازي أضلاع كمان، فمش بيتحطوا جنبه.
const _quads = [
  ([(0.0, 0.0), (3.0, 0.0), (3.0, 3.0), (0.0, 3.0)], 'مربع', ['شبه منحرف']),
  ([(0.0, 0.0), (5.0, 0.0), (5.0, 2.5), (0.0, 2.5)], 'مستطيل', ['مربع', 'شبه منحرف']),
  ([(0.0, 0.0), (4.0, 0.0), (5.5, 2.5), (1.5, 2.5)], 'متوازي أضلاع', ['مستطيل', 'مربع']),
  ([(0.0, 0.0), (6.0, 0.0), (4.5, 2.5), (1.5, 2.5)], 'شبه منحرف', ['مستطيل', 'مربع']),
];

/// الزوايا (النوع والقياس)، الخطوط (متوازية ومتعامدة ومتقاطعة)، المثلثات، والأشكال الرباعية.
/// focus: angles / lines / shapes.
Question geometry4(int lv, Rng r, {String? focus}) {
  final kind = switch (focus) {
    'angles' => r.sample(['angleType', if (lv >= 2) 'angleMeasure']),
    'lines' => 'lines',
    'shapes' => r.sample(['triangle', 'quad']),
    _ => r.sample(['angleType', 'lines', 'triangle', 'quad', if (lv >= 2) 'angleMeasure']),
  };
  switch (kind) {
    case 'angleMeasure':
      final deg = r.sample([30, 45, 60, 90, 120, 150]);
      final options = [deg, ...r.shuffle([30, 45, 60, 90, 120, 150].where((x) => (x - deg).abs() >= 30).toList()).take(2)]
          .map((x) => '${ar(x)}°')
          .toList();
      return _q('geometry4', 'geo:measure', 'قياس الزاوية دي تقريبًا كام؟', [AngleVisual(deg)], options, '${ar(deg)}°', r,
          hint: 'الزاوية القائمة ٩٠°: لو أصغر منها تبقى حادة، ولو أكبر تبقى منفرجة ☝️',
          speakHint: 'قارنها بالزاوية القائمة تسعين درجة');
    case 'lines':
      const names = ['خطان متوازيان', 'خطان متعامدان', 'خطان متقاطعان'];
      final i = r.rnd(0, 2);
      return _q('geometry4', 'geo:lines', 'الخطين دول إيه؟', [LinesVisual(i)], names, names[i], r, big: false,
          hint: 'المتوازيان عمرهم ما يتقابلوا، والمتعامدان بيعملوا زاوية قائمة ☝️',
          speakHint: 'المتوازيان مابيتقابلوش، والمتعامدان بيعملوا زاوية قائمة');
    case 'triangle':
      final (pts, name) = r.sample(_triangles);
      return _q('geometry4', 'geo:triangle', 'المثلث ده نوعه إيه؟', [ComposeVisual([pts])],
          ['مثلث قائم الزاوية', 'مثلث حاد الزوايا', 'مثلث منفرج الزاوية'], name, r, big: false,
          hint: 'بص على أكبر زاوية: قائمة ولا أصغر ولا أكبر من القائمة؟ ☝️', speakHint: 'بص على أكبر زاوية في المثلث');
    case 'quad':
      final (pts, name, wrong) = r.sample(_quads);
      return _q('geometry4', 'geo:quad', 'الشكل الرباعي ده اسمه إيه؟', [ComposeVisual([pts])], [name, ...wrong], name, r, big: false,
          hint: 'بص على الأضلاع: متساوية؟ متوازية؟ والزوايا قائمة؟ ☝️', speakHint: 'بص على الأضلاع والزوايا');
    default:
      final deg = r.sample([25, 40, 60, 75, 90, 90, 110, 130, 150, 165]);
      final name = deg < 90 ? _angleKinds[0] : (deg == 90 ? _angleKinds[1] : _angleKinds[2]);
      return _q('geometry4', 'geo:angleType', 'الزاوية دي نوعها إيه؟', [AngleVisual(deg)], _angleKinds, name, r, big: false,
          hint: 'القائمة ٩٠° زي ركن الكتاب، والحادة أصغر منها، والمنفرجة أكبر ☝️',
          speakHint: 'القائمة زي ركن الكتاب، والحادة أصغر، والمنفرجة أكبر');
  }
}
