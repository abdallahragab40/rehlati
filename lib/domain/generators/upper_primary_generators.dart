/// أول حزمة تدريب لسن ٩–١٢: القسمة من غير باقي والكسور العادية.
library;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

int _divisor(int lv, Rng r, String? focus) {
  final max = lv <= 2 ? 5 : 10;
  final requested = int.tryParse(focus ?? '');
  return requested != null && requested >= 2 && requested <= max ? requested : r.rnd(2, max);
}

Question divisionExact(int lv, Rng r, {String? focus}) {
  final divisor = _divisor(lv, r, focus);
  final quotient = r.rnd(1, lv <= 2 ? 5 : 10);
  final total = divisor * quotient;
  return Question(
    type: 'divisionExact', mode: QMode.choice, skill: 'division:$divisor',
    ask: '${ar(total)} ÷ ${ar(divisor)} = ؟',
    speak: '${arNum(total)} على ${arNum(divisor)} يساوي كام؟',
    clips: [say(arNum(total)), say('على'), say(arNum(divisor)), say('يساوي كام؟')],
    visuals: [ExprVisual([ExprTile(total), const ExprOp('÷'), ExprTile(divisor), const ExprOp('='), const ExprTile(null)])],
    choices: r.numberChoices(quotient, lv <= 2 ? 3 : 4, 1, 12), answer: quotient,
    hint: '${ar(divisor)} × ؟ = ${ar(total)}. استخدم جدول الضرب عشان تقسم.',
    speakHint: 'القسمة عكس الضرب. دوّر في الجدول على الناتج',
  );
}

Question divisionMissing(int lv, Rng r, {String? focus}) {
  final divisor = _divisor(lv, r, focus);
  final quotient = r.rnd(1, lv <= 2 ? 5 : 10);
  final total = divisor * quotient;
  return Question(
    type: 'divisionMissing', mode: QMode.choice, skill: 'division_missing:$divisor',
    ask: '؟ ÷ ${ar(divisor)} = ${ar(quotient)}',
    speak: 'كام على ${arNum(divisor)} يساوي ${arNum(quotient)}؟',
    clips: [say('كام على'), say(arNum(divisor)), 'eq', say(arNum(quotient))],
    visuals: [ExprVisual([const ExprTile(null), const ExprOp('÷'), ExprTile(divisor), const ExprOp('='), ExprTile(quotient)])],
    choices: r.numberChoices(total, lv <= 2 ? 3 : 4, 1, 100), answer: total,
    hint: 'اضرب ${ar(divisor)} × ${ar(quotient)} عشان تلاقي العدد اللي قسمناه.',
    speakHint: 'اضرب المقسوم عليه في ناتج القسمة',
  );
}

Question fractionOfNumber(int lv, Rng r, {String? focus}) {
  final denominator = _divisor(lv, r, focus);
  final numerator = lv <= 2 ? 1 : r.rnd(1, denominator - 1);
  final unit = r.rnd(2, lv <= 2 ? 5 : 10);
  final total = denominator * unit;
  final answer = numerator * unit;
  return Question(
    type: 'fractionOfNumber', mode: QMode.choice, skill: 'fraction_of:$denominator',
    ask: 'احسب ${ar(numerator)} على ${ar(denominator)} من العدد ${ar(total)}',
    speak: 'احسب ${arNum(numerator)} على ${arNum(denominator)} من العدد ${arNum(total)}',
    clips: [say('احسب'), say(arNum(numerator)), say('على'), say(arNum(denominator)), say('من العدد'), say(arNum(total))],
    visuals: [CaptionVisual('نقسم ${ar(total)} إلى ${ar(denominator)} أجزاء متساوية، وناخد ${ar(numerator)} منها.')],
    choices: r.numberChoices(answer, lv <= 2 ? 3 : 4, 1, 100), answer: answer,
    hint: '${ar(total)} ÷ ${ar(denominator)} = ${ar(unit)} في الجزء الواحد، وبعدين نضرب × ${ar(numerator)}.',
    speakHint: 'اقسم العدد على المقام، وبعدين اضرب في البسط',
  );
}

String fractionSay(String value) {
  final parts = value.split('/').map(int.parse).toList();
  return '${arNum(parts[0])} على ${arNum(parts[1])}';
}

Question fractionEquivalent(int lv, Rng r, {String? focus}) {
  final denominator = _divisor(lv, r, focus);
  final numerator = lv <= 2 ? 1 : r.rnd(1, denominator - 1);
  final factor = r.rnd(2, lv <= 2 ? 3 : 5);
  final n = numerator * factor, d = denominator * factor;
  final answer = '$n/$d';
  // نفس المقام: البسط المضروب بس هو اللي يكافئ الكسر
  final choices = r.shuffle([answer, '${n - 1}/$d', '${n + 1}/$d', '$n/${d + 1}']);
  return Question(
    type: 'fractionEquivalent', mode: QMode.choice, skill: 'fraction_equivalent:$denominator', numeric: false,
    look: ChoiceLook.fraction,
    ask: 'اختار الكسر اللي يساوي ${ar(numerator)} على ${ar(denominator)}',
    speak: 'اختار الكسر اللي يساوي ${arNum(numerator)} على ${arNum(denominator)}',
    clips: [say('اختار الكسر اللي يساوي'), say(arNum(numerator)), say('على'), say(arNum(denominator))],
    choices: choices, answer: answer,
    choiceSay: {for (final c in choices) c: fractionSay(c)},
    hint: 'اضرب البسط والمقام في نفس العدد. هنا × ${ar(factor)}.',
    speakHint: 'الكسر المكافئ: اضرب البسط والمقام في نفس العدد',
  );
}
