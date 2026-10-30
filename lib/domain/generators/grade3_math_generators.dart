/// دروس حساب تالتة ابتدائي اللي مكانتش في التطبيق (tool/SCHOOL_CURRICULUM_INDEX.md):
/// الآلاف، المساحة والمحيط، استراتيجيات الضرب، والتمثيل بالنقاط.
///
/// الأعداد الكبيرة مكتوبة ومش بتتنطق (الاختيارات ليها choiceSay فاضي) — السؤال بس اللي بيتقال.
library;

import 'dart:math' as math;

import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

/// اختيارات مكتوبة بس: الأعداد بالأرقام العربي ومن غير صوت.
Map<Object, String> _silent(Iterable<int> xs) => {for (final x in xs) ar(x): ''};

// ---------------------------------------------------------------- الآلاف

const _places = ['الآحاد', 'العشرات', 'المئات', 'آحاد الألوف', 'عشرات الألوف', 'مئات الألوف'];

/// الأرقام في الخانات، الصيغة الممتدة، والمقارنة. المستوى بيحدد الحجم: آلاف، عشرات آلاف، مئات آلاف.
Question thousands(int lv, Rng r, {String? focus}) {
  final digits = switch (lv) { <= 1 => 4, 2 => 5, _ => 6 };
  final n = r.rnd(math.pow(10, digits - 1).toInt(), math.pow(10, digits).toInt() - 1);
  final ds = [for (var i = 0; i < digits; i++) n ~/ math.pow(10, i).toInt() % 10];
  final kind = r.rnd(0, 2);
  if (kind == 0) {
    final i = r.rnd(math.max(0, digits - 3), digits - 1);
    final ask = 'الرقم اللي في خانة ${_places[i]} كام؟';
    return Question(
      type: 'thousands', mode: QMode.choice, skill: 'place:${_places[i]}',
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [BigLetterVisual(ar(n))],
      choices: r.numberChoices(ds[i], 4, 0, 9), answer: ds[i],
      hint: 'عُدّ الخانات من اليمين: آحاد، عشرات، مئات، وبعدين الألوف ☝️',
      speakHint: 'عد الخانات من اليمين، آحاد وعشرات ومئات، وبعدين الألوف',
      clipsHint: [say('عد الخانات من اليمين، آحاد وعشرات ومئات، وبعدين الألوف')],
    );
  }
  if (kind == 1) {
    final parts = [for (var i = digits - 1; i >= 0; i--) if (ds[i] > 0) ds[i] * math.pow(10, i).toInt()];
    // الغلط: رقمين متبادلين، أو خانة زيادة أو ناقصة
    final wrong = <int>{
      if (ds[0] != ds[1]) n - ds[0] - ds[1] * 10 + ds[0] * 10 + ds[1],
      n + math.pow(10, digits - 2).toInt(),
      n - math.pow(10, digits - 2).toInt(),
    }..removeWhere((x) => x == n);
    final options = [n, ...wrong.take(2)];
    const ask = 'أنهي عدد ده؟';
    return Question(
      type: 'thousands', mode: QMode.choice, skill: 'expanded:$digits', numeric: false, wide: true,
      ask: ask, speak: ask, clips: [say(ask)],
      visuals: [BigLetterVisual(parts.map(ar).join(' + '))],
      choices: r.shuffle(options.map(ar).toList()), answer: ar(n), choiceSay: _silent(options),
      hint: 'اكتب كل جزء في خانته من الشمال لليمين ☝️', speakHint: 'اكتب كل جزء في خانته',
      clipsHint: [say('اكتب كل جزء في خانته')],
    );
  }
  var m = n;
  while (m == n) {
    m = r.chance(.5) ? n + r.rnd(-9, 9) * math.pow(10, r.rnd(0, digits - 2)).toInt() : r.rnd(n ~/ 2, math.min(n * 2, math.pow(10, digits).toInt() - 1));
  }
  m = m.clamp(math.pow(10, digits - 1).toInt(), math.pow(10, digits).toInt() - 1);
  if (m == n) m = n == math.pow(10, digits).toInt() - 1 ? n - 1 : n + 1;
  final bigger = r.chance(.5);
  final ask = bigger ? 'أنهي عدد أكبر؟' : 'أنهي عدد أصغر؟';
  final answer = bigger ? math.max(n, m) : math.min(n, m);
  return Question(
    type: 'thousands', mode: QMode.choice, skill: 'compare:$digits', numeric: false, bigChoices: true,
    ask: ask, speak: ask, clips: [say(ask)],
    choices: r.shuffle([ar(n), ar(m)]), answer: ar(answer), choiceSay: _silent([n, m]),
    hint: 'قارن من أكبر خانة على الشمال، ولو زي بعض روح للي بعدها ☝️',
    speakHint: 'قارن من أكبر خانة، ولو زي بعض روح للي بعدها',
    clipsHint: [say('قارن من أكبر خانة، ولو زي بعض روح للي بعدها')],
  );
}

// ---------------------------------------------------------------- المساحة والمحيط

List<(int, int)> _rect(int w, int h, [int dx = 0, int dy = 0]) => [
      for (var y = 0; y < h; y++)
        for (var x = 0; x < w; x++) (x + dx, y + dy),
    ];

/// المساحة بعدّ المربعات، والمحيط بجمع الأضلاع. من المستوى التالت المستطيل بأطواله من غير شبكة،
/// ومن الرابع: مستطيل مساحته وطوله معروفين — عرضه كام؟ focus: area / perimeter.
Question areaPerimeter(int lv, Rng r, {String? focus}) {
  final area = focus == 'area' || (focus != 'perimeter' && r.chance(.5));
  final w = r.rnd(2, lv <= 1 ? 5 : 8), h = r.rnd(2, lv <= 1 ? 4 : 6);
  if (lv >= 4 && r.chance(.35)) {
    final total = area ? w * h : 2 * (w + h);
    final ask = area ? 'مستطيل مساحته ${ar(total)} وطوله ${ar(w)}. عرضه كام؟' : 'مستطيل محيطه ${ar(total)} وطوله ${ar(w)}. عرضه كام؟';
    return Question(
      type: 'areaPerimeter', mode: QMode.choice, skill: 'ap:missing${area ? 'A' : 'P'}',
      ask: ask, speak: 'فكّر: العرض كام؟', clips: [say('فكّر: العرض كام؟')],
      visuals: [GridAreaVisual(w, h, _rect(w, h), grid: false, sides: (w, h))],
      choices: r.numberChoices(h, 4, 1, 12), answer: h,
      hint: area ? 'المساحة = الطول × العرض، فالعرض = ${ar(total)} ÷ ${ar(w)} ☝️' : 'المحيط = ٢ × (الطول + العرض) ☝️',
      speakHint: area ? 'المساحة الطول في العرض' : 'المحيط مرتين الطول زائد العرض',
      clipsHint: [say(area ? 'المساحة الطول في العرض' : 'المحيط مرتين الطول زائد العرض')],
    );
  }
  final labelled = lv >= 3 && r.chance(.5);
  // شكل حرف L من المستوى التاني للمساحة بس (المحيط بيتحسب للمستطيل)
  final cells = area && !labelled && lv >= 2 && r.chance(.4) && w >= 3 && h >= 3
      ? [..._rect(w, h ~/ 2), ..._rect(w ~/ 2 + 1, h - h ~/ 2, 0, h ~/ 2)]
      : _rect(w, h);
  final answer = area ? cells.length : 2 * (w + h);
  final ask = area
      ? (labelled ? 'مساحة المستطيل كام؟' : 'مساحة الشكل كام مربع؟')
      : (labelled ? 'محيط المستطيل كام؟' : 'محيط المستطيل كام وحدة؟');
  return Question(
    type: 'areaPerimeter', mode: QMode.choice, skill: 'ap:${area ? 'area' : 'perimeter'}',
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [GridAreaVisual(w, h, cells, grid: !labelled, sides: labelled ? (w, h) : null)],
    choices: r.numberChoices(answer, 4, 1, answer + 12), answer: answer,
    hint: area ? 'المساحة = عدد المربعات جوه الشكل (أو الطول × العرض) 🟩' : 'المحيط = مجموع أطوال الأضلاع الأربعة 📏',
    speakHint: area ? 'المساحة عدد المربعات جوه الشكل' : 'المحيط مجموع أطوال الأضلاع',
    clipsHint: [say(area ? 'المساحة عدد المربعات جوه الشكل' : 'المحيط مجموع أطوال الأضلاع')],
  );
}

// ---------------------------------------------------------------- استراتيجيات الضرب

/// الضرب في مضاعفات ١٠، خاصية التوزيع والتجميع، وتقدير الناتج. focus: tens / props / estimate.
Question mulStrategies(int lv, Rng r, {String? focus}) {
  final kind = ['tens', 'props', 'estimate'].contains(focus) ? focus! : r.sample(['tens', 'props', if (lv >= 2) 'estimate']);
  switch (kind) {
    case 'tens':
      final a = r.rnd(2, 9), b = r.rnd(2, 9);
      final ans = a * b * 10;
      final options = {ans, a * b, ans + 10, ans - 10}.where((x) => x > 0).take(3).toList();
      const ask = 'احسب: الضرب في مضاعفات العشرة';
      return Question(
        type: 'mulStrategies', mode: QMode.choice, skill: 'mul:tens', numeric: false, bigChoices: true,
        ask: ask, speak: ask, clips: [say(ask)],
        visuals: [ExprVisual([ExprTile(a), const ExprOp('×'), ExprTile(b * 10), const ExprOp('='), const ExprTile(null)])],
        choices: r.shuffle(options.map(ar).toList()), answer: ar(ans), choiceSay: _silent(options),
        hint: '${ar(a)} × ${ar(b)} = ${ar(a * b)}، وبعدين حط صفر ☝️', speakHint: 'اضرب من غير الصفر، وبعدين حط صفر',
        clipsHint: [say('اضرب من غير الصفر، وبعدين حط صفر')],
      );
    case 'estimate':
      final a = r.rnd(12, 89), b = r.rnd(2, 9);
      final rounded = (a + 5) ~/ 10 * 10, ans = rounded * b;
      final options = {ans, ans + 10 * b, ans - 10 * b}.where((x) => x > 0).toList();
      const ask = 'قدّر الناتج: قرّب لأقرب عشرة واضرب';
      return Question(
        type: 'mulStrategies', mode: QMode.choice, skill: 'mul:estimate', numeric: false, bigChoices: true,
        ask: ask, speak: ask, clips: [say(ask)],
        visuals: [ExprVisual([ExprTile(a), const ExprOp('×'), ExprTile(b), const ExprOp('≈'), const ExprTile(null)])],
        choices: r.shuffle(options.map(ar).toList()), answer: ar(ans), choiceSay: _silent(options),
        hint: '${ar(a)} تقريبًا ${ar(rounded)}، و${ar(rounded)} × ${ar(b)} = ${ar(ans)} ☝️',
        speakHint: 'قرب لأقرب عشرة، وبعدين اضرب', clipsHint: [say('قرب لأقرب عشرة، وبعدين اضرب')],
      );
    default:
      // التوزيع: ٦ × ٧ = (٦ × ٥) + (٦ × ؟)، أو التجميع: ٥ × ٢ × ٧ = ١٠ × ؟
      if (r.chance(.5)) {
        final a = r.rnd(3, 9), b = r.rnd(6, 9), part = 5;
        return Question(
          type: 'mulStrategies', mode: QMode.choice, skill: 'mul:distributive',
          ask: 'كمّل: خاصية التوزيع', speak: 'كمّل: خاصية التوزيع', clips: [say('كمّل: خاصية التوزيع')],
          // سطر واحد بيصغر لو طويل — النص الكبير كان بيتكسر على سطرين والأقواس بتتلخبط
          visuals: [
            ExprVisual([
              ExprTile(a), const ExprOp('×'), ExprTile(b), const ExprOp('='),
              const ExprOp('('), ExprTile(a), const ExprOp('×'), ExprTile(part), const ExprOp(')'), const ExprOp('+'),
              const ExprOp('('), ExprTile(a), const ExprOp('×'), const ExprTile(null), const ExprOp(')'),
            ]),
          ],
          choices: r.numberChoices(b - part, 3, 1, 9), answer: b - part,
          hint: '${ar(b)} = ${ar(part)} + ${ar(b - part)} ☝️', speakHint: 'فكك العدد التاني لجزأين',
          clipsHint: [say('فكك العدد التاني لجزأين')],
        );
      }
      final c = r.rnd(2, 9);
      return Question(
        type: 'mulStrategies', mode: QMode.choice, skill: 'mul:associative',
        ask: 'كمّل: خاصية التجميع', speak: 'كمّل: خاصية التجميع', clips: [say('كمّل: خاصية التجميع')],
        visuals: [
          ExprVisual([
            const ExprTile(5), const ExprOp('×'), const ExprTile(2), const ExprOp('×'), ExprTile(c), const ExprOp('='),
            const ExprTile(10), const ExprOp('×'), const ExprTile(null),
          ]),
        ],
        choices: r.numberChoices(c, 3, 1, 10), answer: c,
        hint: '${ar(5)} × ${ar(2)} = ${ar(10)}، والباقي زي ما هو ☝️', speakHint: 'اضرب الخمسة في الاتنين الأول',
        clipsHint: [say('اضرب الخمسة في الاتنين الأول')],
      );
  }
}

// ---------------------------------------------------------------- التمثيل بالنقاط

/// عدد الكتب اللي قراها كل طفل: كل نقطة = طفل. «كام نقطة فوق ٣؟» و«أنهي رقم عليه أكتر نقط؟».
Question dotPlot(int lv, Rng r, {String? focus}) {
  final counts = [for (var i = 0; i < 5; i++) r.rnd(0, lv <= 1 ? 4 : 6)];
  final top = counts.reduce(math.max);
  // أكتر نقط لازم تبقى في رقم واحد بس
  if (counts.where((c) => c == top).length > 1) counts[counts.indexOf(top)] = top + 1;
  final rows = [for (var i = 0; i < 5; i++) (i + 1, counts[i])];
  const caption = 'كل نقطة = طفل، والرقم = عدد الكتب اللي قراها';
  if (r.chance(.5)) {
    final i = r.rnd(0, 4);
    final ask = 'كام طفل قرا ${ar(i + 1)} ${i == 0 ? 'كتاب' : 'كتب'}؟';
    return Question(
      type: 'dotPlot', mode: QMode.choice, skill: 'dots:read',
      ask: ask, speak: 'كام نقطة فوق الرقم ${arNum(i + 1)}؟',
      visuals: [const CaptionVisual(caption), DotPlotVisual(rows)],
      choices: r.numberChoices(counts[i], 3, 0, 8), answer: counts[i],
      hint: 'عُدّ النقط اللي فوق الرقم ${ar(i + 1)} 👆', speakHint: 'عد النقط اللي فوق الرقم',
    );
  }
  final most = counts.indexOf(counts.reduce(math.max)) + 1;
  const ask = 'أنهي عدد كتب قراه أكتر أطفال؟';
  return Question(
    type: 'dotPlot', mode: QMode.choice, skill: 'dots:most',
    ask: ask, speak: ask, clips: [say(ask)],
    visuals: [const CaptionVisual(caption), DotPlotVisual(rows)],
    choices: r.shuffle([most, ...r.shuffle([1, 2, 3, 4, 5].where((x) => x != most).toList()).take(2)]), answer: most,
    hint: 'دوّر على العمود اللي فيه أكتر نقط ⚫', speakHint: 'دور على العمود اللي فيه أكتر نقط',
    clipsHint: [say('دور على العمود اللي فيه أكتر نقط')],
  );
}
