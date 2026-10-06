/// مولّدات عالم الحساب — منقولة من js/games/*.js بنفس المنطق.
library;

import 'dart:math' as math;

import '../../content/math_data.dart';
import '../../core/audio/voice_lines.dart';
import '../../core/utils/arabic.dart';
import '../../core/utils/rng.dart';
import '../question.dart';

List<int> _range(int from, int to) => [for (var i = from; i <= to; i++) i];

/// لعبة العد.
Question counting(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), max = math.min(l.max, 10);
  final ii = r.rnd(0, countItems.length - 1), it = countItems[ii];
  // تعلّم متكيّف: لو الطفل بيغلط في عدد معيّن نرجّعه (نسخة الويب كانت بتتجاهل focus هنا)
  final f = int.tryParse(focus ?? '');
  final n = (f != null && f >= 1 && f <= max) ? f : r.rnd(1, max);
  return Question(
    type: 'counting', mode: QMode.choice, skill: 'count:$n',
    clips: ['q$ii'], clipsHint: ['count_with_me', ..._range(1, n).map(nk)],
    ask: it.question, speak: it.question,
    visuals: [PicsVisual(it.emoji, n)],
    choices: r.numberChoices(n, l.choices, 1, max),
    answer: n,
    hint: 'عُدّ معي بإصبعك واحدة واحدة 👆',
    speakHint: 'نعد مع بعض: ${arList(_range(1, n))}',
  );
}

/// لعبة اختر الرقم.
Question chooseNumber(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), max = math.min(l.max, 10);
  final ii = r.rnd(0, countItems.length - 1), it = countItems[ii];
  final n = r.rnd(1, max);
  return Question(
    type: 'chooseNumber', mode: QMode.choice,
    clips: ['q$ii', 'pick_number'], clipsHint: ['count_with_me', ..._range(1, n).map(nk)],
    ask: 'اختار الرقم الصحيح', speak: '${it.question} اختار الرقم الصحيح',
    visuals: [PicsVisual(it.emoji, n)],
    choices: r.numberChoices(n, l.choices, 1, math.max(max, n + 2)),
    answer: n,
    hint: 'عُدّ الصور ثم دوّر على نفس الرقم 🔍',
    speakHint: 'نعد مع بعض: ${arList(_range(1, n))}',
  );
}

/// لعبة العدد التالي.
Question nextNumber(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), n = r.rnd(1, l.max - 1), a = n + 1;
  final counted = <int>{math.max(1, n - 2), math.max(1, n - 1), n}.toList();
  return Question(
    type: 'nextNumber', mode: QMode.choice,
    ask: 'ما العدد التالي؟', speak: 'إيه الرقم اللي بعد ${arNum(n)}؟',
    visuals: [ExprVisual([ExprTile(n), const ExprOp('←'), const ExprTile(null)])],
    choices: r.numberChoices(a, l.choices, 1, l.max),
    answer: a,
    hint: 'بعد ${ar(n)} بواحد 👉',
    speakHint: 'عُد من الأول: ${arList(counted)} وبعدين؟',
    clipsHint: ['count_from_start', ...counted.map(nk), 'and_then'],
  );
}

/// لعبة العدد السابق.
Question previousNumber(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), n = r.rnd(2, l.max), a = n - 1;
  return Question(
    type: 'previousNumber', mode: QMode.choice,
    ask: 'ما العدد السابق؟', speak: 'إيه الرقم اللي قبل ${arNum(n)}؟',
    visuals: [ExprVisual([const ExprTile(null), const ExprOp('←'), ExprTile(n)])],
    choices: r.numberChoices(a, l.choices, 1, l.max),
    answer: a,
    hint: 'قبل ${ar(n)} بواحد 👈',
    speakHint: 'الرقم اللي قبل ${arNum(n)} بواحد',
  );
}

/// لعبة السابق والتالي: الرقم في النص، والطفل يحط السابق (يمين) والتالي (شمال).
Question neighbors(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  final n = r.rnd(2, l.max - 1); // لازم يكون ليه سابق وتالي جوه المدى
  final prev = n - 1, next = n + 1;
  // الاختيارات: الإجابتان + مشتتات قريبة (الرقم نفسه مشتت ممتاز)
  final set = <int>{prev, next};
  final extra = l.choices >= 4 ? 3 : 2;
  for (final c in [n, n - 2, n + 2, n - 3, n + 3]) {
    if (set.length < 2 + extra && c >= 1 && c <= l.max && c != prev && c != next) set.add(c);
  }
  return Question(
    type: 'neighbors', mode: QMode.order, rtlSlots: true,
    ask: 'مين السابق ومين التالي؟',
    speak: 'الرقم ${arNum(n)}. مين الرقم اللي قبله ومين الرقم اللي بعده؟',
    orderHint: 'اضغط السابق الأول (يمين) وبعدين التالي (شمال)',
    visuals: [
      ExprVisual([
        const ExprCaption('السابق', ExprTile(null)),
        const ExprOp('←'),
        ExprCaption('الرقم', ExprTile(n, mid: true)),
        const ExprOp('←'),
        const ExprCaption('التالي', ExprTile(null)),
      ], fillFromPicked: true),
    ],
    items: r.shuffle(<Object>[...set]),
    answer: <Object>[prev, next],
    hint: 'السابق أقل بواحد 👈 والتالي أكبر بواحد 👉',
    speakHint: 'السابق أقل بواحد، والتالي أكبر بواحد',
    okMsg: '⭐ أحسنت! ${ar(prev)} ثم ${ar(n)} ثم ${ar(next)}',
    sayRight: '${arNum(prev)} ، ${arNum(n)} ، ${arNum(next)}',
  );
}

/// لعبة أكمل التسلسل.
Question sequence(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv), step = r.sample(l.steps);
  const len = 5;
  final start = step == 1 ? r.rnd(1, math.max(1, l.max - 4)) : step;
  final seq = [for (var i = 0; i < len; i++) start + i * step];
  final hole = r.rnd(1, len - 2);
  final a = seq[hole];
  final parts = <ExprPart>[];
  for (var i = 0; i < len; i++) {
    if (i > 0) parts.add(const ExprOp('•', separator: true));
    parts.add(ExprTile(i == hole ? null : seq[i]));
  }
  return Question(
    type: 'sequence', mode: QMode.choice, skill: 'seq:$step',
    ask: 'أكمل التسلسل',
    speak: 'أكمل التسلسل: ${[for (var i = 0; i < len; i++) i == hole ? 'كام' : arNum(seq[i])].join('، ')}',
    visuals: [ExprVisual(parts)],
    choices: r.numberChoices(a, l.choices, 1, math.max(a + 5, l.max)),
    answer: a,
    hint: step == 1 ? 'عُدّ بالترتيب: اللي بعد الرقم ده بواحد 👆' : 'بنقفز ${ar(step)} في كل مرة 👆',
    speakHint: step == 1 ? 'بنزود واحد في كل مرة' : 'بنزود ${arNum(step)} في كل مرة',
  );
}

/// لعبة أكمل الجدول (١ إلى ٢٠).
Question completeTable(int lv, Rng r, {String? focus}) {
  const max = 20;
  final holeCount = const [2, 3, 4, 5][lv.clamp(1, 4) - 1];
  final holes = <int>{};
  while (holes.length < holeCount) {
    holes.add(r.rnd(1, max));
  }
  final sorted = holes.toList()..sort();
  // الاختيارات: الأرقام الناقصة + مشتّت واحد في المستويات الأعلى
  final opts = <Object>[...sorted];
  if (lv >= 3) {
    int d;
    var guard = 0;
    do {
      d = r.rnd(1, max);
    } while (holes.contains(d) && guard++ < 40);
    opts.add(d);
  }
  return Question(
    type: 'completeTable', mode: QMode.grid,
    clips: ['complete_table'],
    ask: 'أكمل الجدول', speak: 'أكمل الجدول، إيه الأرقام الناقصة؟',
    visuals: [
      TableVisual([for (var v = 1; v <= max; v++) holes.contains(v) ? null : '$v'], kind: TableKind.numbers),
    ],
    items: r.shuffle(opts),
    answer: sorted,
    hint: 'عُدّ من أول الصف لحد الخانة الفاضية 👆',
    speakHint: 'عُد من أول الصف لحد الخانة الفاضية',
  );
}

/// لعبة الجدول الفاضي: الجدول كله فاضي، والطفل يملاه بالترتيب من ١ (لحد ١٠ أو ٢٠).
Question emptyTable(int lv, Rng r, {String? focus}) {
  final max = lv <= 2 ? 10 : 20;
  final nums = [for (var i = 1; i <= max; i++) i];
  return Question(
    type: 'emptyTable', mode: QMode.grid,
    clips: ['complete_table'],
    ask: 'املأ الجدول بالترتيب',
    speak: 'املأ الجدول من واحد لحد ${arNum(max)}',
    orderHint: 'اضغط الأرقام بالترتيب: واحد، اتنين، تلاتة… لحد ${ar(max)}',
    visuals: [TableVisual(List<String?>.filled(max, null), kind: TableKind.numbers)],
    items: r.shuffle(<Object>[...nums]),
    answer: nums,
    hint: 'ابدأ من ${ar(1)} وكمّل بالترتيب 👆',
    speakHint: 'ابدأ من واحد وكمّل بالترتيب',
  );
}

/// لعبة ترتيب تصاعدي.
Question ascending(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  final set = <int>{};
  while (set.length < 4) {
    set.add(r.rnd(1, l.max));
  }
  final nums = r.shuffle(set.toList());
  return Question(
    type: 'ascending', mode: QMode.order, rtlSlots: true,
    orderHint: 'اضغط الأرقام بالترتيب من اليمين',
    clips: ['sort_asc', ...nums.map(nk)],
    ask: 'رتّب من الأصغر للأكبر',
    speak: 'رتب الأرقام من الأصغر للأكبر: ${arList(nums)}',
    items: nums, answer: [...nums]..sort(),
    hint: 'ابدأ بالرقم الأصغر 🐣',
    speakHint: 'دوّر على أصغر رقم فاضل واضغط عليه',
  );
}

/// لعبة ترتيب تنازلي.
Question descending(int lv, Rng r, {String? focus}) {
  final q = ascending(lv, r);
  final nums = q.items.cast<int>();
  return Question(
    type: 'descending', mode: QMode.order, rtlSlots: true,
    orderHint: q.orderHint,
    clips: ['sort_desc', ...nums.map(nk)],
    ask: 'رتّب من الأكبر للأصغر',
    speak: 'رتب الأرقام من الأكبر للأصغر: ${arList(nums)}',
    items: q.items, answer: [...nums]..sort((a, b) => b - a),
    hint: 'ابدأ بالرقم الأكبر 🦁',
    speakHint: 'دوّر على أكبر رقم فاضل واضغط عليه',
  );
}

/// لعبة أكبر / أصغر / يساوي.
///
/// التعبير بيتعرض من اليمين (a يمين و b شمال)، والعلامات `<` `>` بتتعكس
/// تلقائيًا في النص العربي (bidi mirroring) فالطفل بيشوف العلامة صح بصريًا.
Question comparison(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  final a = r.rnd(1, l.max);
  final b = r.chance(.25) ? a : r.rnd(1, l.max);
  final ans = a > b ? '>' : (a < b ? '<' : '=');
  final ExprVisual visual;
  if (lv <= 2) {
    final it = r.sample(countItems);
    visual = ExprVisual([ExprSide(it.emoji, a, number: a), const ExprTile(null), ExprSide(it.emoji, b, number: b)]);
  } else {
    visual = ExprVisual([ExprTile(a), const ExprTile(null), ExprTile(b)]);
  }
  return Question(
    type: 'comparison', mode: QMode.choice, skill: 'cmp:$a$ans$b',
    clips: [say('${arNum(a)} ... و ... ${arNum(b)}'), 'pick_sign'],
    ask: 'اختار العلامة الصحيحة',
    speak: '${arNum(a)} ... و ... ${arNum(b)}. اختار العلامة الصحيحة: أكبر من، أصغر من، ولا يساوي؟',
    visuals: [visual],
    choices: const ['>', '<', '='], answer: ans,
    hint: 'الفم المفتوح يتجه ناحية الرقم الأكبر 🐊',
    speakHint: 'بُقّ التمساح بيفتح ناحية الرقم الكبير. ${arNum(a)} و ${arNum(b)}',
    clipsHint: ['croc', say('${arNum(a)} ... و ... ${arNum(b)}')],
  );
}

/// لعبة الجمع.
Question addition(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  // التعلّم المتكيّف: لو الطفل بيغلط في مسألة، نرجّع مسائل شبهها
  final f = focus?.split('+').map(int.tryParse).toList();
  final f0 = f?.first;
  final a = (f0 != null && f0 >= 1 && f0 <= l.sumMax - 1) ? f0 : r.rnd(1, math.max(1, l.sumMax - 1));
  final b = r.rnd(1, l.sumMax - a);
  final ans = a + b;
  final ExprVisual visual;
  if (lv <= 3) {
    final it = r.sample(countItems);
    visual = ExprVisual([
      ExprSide(it.emoji, a), const ExprOp('+'), ExprSide(it.emoji, b), const ExprOp('='), const ExprTile(null),
    ]);
  } else {
    visual = ExprVisual([ExprTile(a), const ExprOp('+'), ExprTile(b), const ExprOp('='), const ExprTile(null)]);
  }
  return Question(
    type: 'addition', mode: QMode.choice, skill: 'add:$a+$b',
    ask: lv <= 2 ? 'كم العدد كله؟' : '${ar(a)} + ${ar(b)} = ؟',
    speak: '${arNum(a)} زائد ${arNum(b)} يساوي كام؟',
    visuals: [visual],
    choices: r.numberChoices(ans, l.choices, 1, l.sumMax + 2), answer: ans,
    hint: 'عُدّ المجموعتين مع بعض 🤝',
    speakHint: 'عُد المجموعتين مع بعض: ${arList(_range(1, math.min(ans, 20)))}',
    clipsHint: ['count_both', ..._range(1, math.min(ans, 20)).map(nk)],
  );
}

/// لعبة الطرح.
Question subtraction(int lv, Rng r, {String? focus}) {
  final l = levelSpec(lv);
  final f = focus?.split('-').map(int.tryParse).toList();
  final f0 = f?.first;
  final a = (f0 != null && f0 >= 2 && f0 <= l.sumMax) ? f0 : r.rnd(2, l.sumMax);
  final b = r.rnd(1, a - 1);
  final ans = a - b;
  final it = r.sample(countItems);
  final expr = ExprVisual([ExprTile(a), const ExprOp('−'), ExprTile(b), const ExprOp('='), const ExprTile(null)]);
  return Question(
    type: 'subtraction', mode: QMode.choice, skill: 'sub:$a-$b',
    ask: lv <= 3 ? 'كم ${it.emoji} باقي؟' : '${ar(a)} − ${ar(b)} = ؟',
    speak: '${arNum(a)} ناقص ${arNum(b)} يساوي كام؟',
    visuals: lv <= 3 ? [PicsVisual(it.emoji, a, goneFrom: a - b), expr] : [expr],
    choices: r.numberChoices(ans, l.choices, 0, l.sumMax), answer: ans,
    hint: 'عُدّ اللي فاضل من غير المشطوب ✖',
    speakHint: 'عُد اللي فاضل بس، من غير المشطوب. ${arNum(a)} شيلنا منهم ${arNum(b)}',
    clipsHint: ['count_left', say('${arNum(a)} شيلنا منهم ${arNum(b)}')],
  );
}
