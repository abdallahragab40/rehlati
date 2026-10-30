/// رسم مرئيات السؤال (كانت HTML في الويب).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/dashed_box.dart';
import '../../domain/question.dart';
import '../madd/madd_style.dart';
import 'basics_modes.dart';
import 'play_modes.dart';
import 'tap_count.dart';

class VisualView extends StatelessWidget {
  const VisualView(
    this.visual, {
    super.key,
    this.ltr = false,
    this.picked = const [],
  });
  final Visual visual;
  final bool ltr;

  /// القيم اللي الطفل حطّها في خانات الجدول لحد دلوقتي.
  final List<Object> picked;

  @override
  Widget build(BuildContext context) {
    final dir = ltr ? TextDirection.ltr : TextDirection.rtl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: switch (visual) {
        // الصور بتتعد باللمس
        PicsVisual v => TapCountScope(child: _Pics(v)),
        ExprVisual v => TapCountScope(child: _Expr(v, picked: v.fillFromPicked ? picked : const [])),
        BigLetterVisual v => Directionality(
          textDirection: dir,
          child: Text(
            v.text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(76, 22, 130), height: 1.1),
          ),
        ),
        CaptionVisual v => Directionality(
          textDirection: dir,
          child: Text(
            v.text,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(20, 5.4, 28)),
          ),
        ),
        WordLineVisual v => Directionality(
          textDirection: dir,
          child: _WordLine(v),
        ),
        LetterChipsVisual v => _LetterChips(v),
        TableVisual v => _Table(v, picked),
        MaddTextVisual v => MaddTextView(v),
        ListenVisual v => Center(child: ListenButton(v.say, en: v.en)),
        ShapeVisual v => ShapeView(v),
        QueueVisual v => QueueView(v),
        PairsVisual v => PairsView(v),
        CoinsVisual v => CoinsView(v),
        PicGraphVisual v => PicGraphView(v),
        BarGraphVisual v => BarGraphView(v),
        PrepVisual v => PrepView(v),
        ComposeVisual v => ComposeView(v),
        GridAreaVisual v => GridAreaView(v),
        DotPlotVisual v => DotPlotView(v),
        PlantVisual v => PlantView(v),
        EmojiVisual v => EmojiView(v),
        OppositeVisual v => Center(child: OppositePic(v.spec, size: context.clampVw(130, 36, 170))),
        PatternVisual v => _Pattern(v),
        ClockVisual v => Center(child: ClockFace(hour: v.hour, minute: v.minute, size: context.clampVw(150, 44, 210))),
        TensOnesVisual v => _TensOnes(v),
        GroupsVisual v => TapCountScope(child: _Groups(v)),
        MoneyVisual v => _Money(v),
        PassageVisual v => _Passage(v),
      },
    );
  }
}

/// قطعة القراءة: كارت فاتح، العنوان فوق، والنص بخط مريح للقراية الطويلة.
class _Passage extends StatelessWidget {
  const _Passage(this.v);
  final PassageVisual v;

  @override
  Widget build(BuildContext context) => Directionality(
        textDirection: v.ltr ? TextDirection.ltr : TextDirection.rtl,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            border: Border.all(color: AppColors.line, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v.title, style: kidText(context.clampVw(17, 4.6, 22), color: AppColors.grape)),
            const SizedBox(height: 6),
            Text(v.text, style: kidText(context.clampVw(17, 4.6, 22), weight: FontWeight.w600, height: 1.7)),
          ]),
        ),
      );
}

/// الجنيه عملة دهبي، والورق مستطيلات بلون لكل فئة ومكتوب عليها قيمتها — رسم تعليمي مش صورة الفلوس.
class _Money extends StatelessWidget {
  const _Money(this.v);
  final MoneyVisual v;

  static const _colors = {
    5: Color(0xFF4FA37A), 10: Color(0xFFE0728A), 20: Color(0xFF3F8F5A),
    50: Color(0xFF8B6BB8), 100: Color(0xFF4C8FC9),
  };

  @override
  Widget build(BuildContext context) {
    final w = context.clampVw(92, 24, 120);
    Widget piece(int p) => p == 1
        ? Container(
            width: w * .45,
            height: w * .45,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2))],
            ),
            child: Text(ar(1), style: kidText(w * .2)),
          )
        : Container(
            width: w,
            height: w * .5,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _colors[p] ?? AppColors.grape,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 2))],
            ),
            child: Text('${ar(p)} جنيه', style: kidText(w * .17, color: Colors.white)),
          );
    return Semantics(
      label: v.pounds.map((p) => '${ar(p)} جنيه').join('، '),
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 10,
          children: [for (final p in v.pounds) piece(p)],
        ),
      ),
    );
  }
}

/// المجموعات المتساوية: علبة لكل مجموعة، والعلب بتنزل سطر جديد لو المكان ضيق.
class _Groups extends StatelessWidget {
  const _Groups(this.v);
  final GroupsVisual v;

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(22, 6, 32);
    return Semantics(
      label: '${ar(v.groups)} مجموعات، في كل مجموعة ${ar(v.each)} ${v.emoji}',
      child: ExcludeSemantics(
        child: Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
          for (var g = 0; g < v.groups; g++)
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.paper2,
                border: Border.all(color: AppColors.line, width: 2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: (size + 6) * 3),
                child: Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 2, children: [
                  for (var i = 0; i < v.each; i++)
                    TapCountItem(id: (g, i), child: Text(v.emoji, style: TextStyle(fontSize: size))),
                ]),
              ),
            ),
        ]),
      ),
    );
  }
}

/// عيدان العشرات (١٠ مكعبات فوق بعض) على الشمال، والآحاد مكعبات لوحدها على اليمين.
class _TensOnes extends StatelessWidget {
  const _TensOnes(this.v);
  final TensOnesVisual v;

  @override
  Widget build(BuildContext context) {
    final cube = context.clampVw(12, 3.2, 18);
    Widget block(Color c) => Container(
          width: cube,
          height: cube,
          margin: const EdgeInsets.all(.5),
          decoration: BoxDecoration(color: c, border: Border.all(color: const Color(0x331B3557)), borderRadius: BorderRadius.circular(2)),
        );
    return Semantics(
      label: '${ar(v.tens)} عشرات و ${ar(v.ones)} آحاد',
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(alignment: WrapAlignment.center, crossAxisAlignment: WrapCrossAlignment.end, spacing: 18, runSpacing: 12, children: [
            Wrap(spacing: 6, children: [
              for (var i = 0; i < v.tens; i++) Column(mainAxisSize: MainAxisSize.min, children: [for (var j = 0; j < 10; j++) block(AppColors.grape)]),
            ]),
            if (v.ones > 0)
              SizedBox(
                width: (cube + 1) * 3,
                child: Wrap(alignment: WrapAlignment.center, children: [for (var i = 0; i < v.ones; i++) block(AppColors.gold)]),
              ),
          ]),
        ),
      ),
    );
  }
}

class _Pics extends StatelessWidget {
  const _Pics(this.v);
  final PicsVisual v;

  @override
  Widget build(BuildContext context) {
    final size = v.big
        ? context.clampVw(60, 17, 96)
        : context.clampVw(34, 9, 52);
    return Semantics(
      label: ar(v.count),
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: context.clampVw(4, 1.6, 10),
            runSpacing: 4,
            children: [
              for (var i = 0; i < v.count; i++)
                TapCountItem(
                      id: i,
                      enabled: v.goneFrom == null || i < v.goneFrom!,
                      child: _item(v.emoji, size, gone: v.goneFrom != null && i >= v.goneFrom!),
                    )
                    .anim(delay: (i * 40).ms)
                    .fadeIn(duration: 350.ms)
                    .moveY(begin: -18, end: 0, duration: 350.ms)
                    .scaleXY(begin: .6, end: 1, duration: 350.ms),
            ],
          ),
        ),
      ),
    );
  }

  /// الصورة المشطوبة في الطرح: باهتة ورمادي وعليها ✖.
  Widget _item(String e, double size, {required bool gone}) {
    final t = Text(e, style: TextStyle(fontSize: size, height: 1.05));
    if (!gone) return t;
    return Stack(
      alignment: Alignment.center,
      children: [
        Opacity(
          opacity: .3,
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix(_grey),
            child: t,
          ),
        ),
        Text(
          '✖',
          style: TextStyle(fontSize: size * .8, color: AppColors.coral),
        ),
      ],
    );
  }
}

const _grey = <double>[
  .2126, .7152, .0722, 0, 0, //
  .2126, .7152, .0722, 0, 0,
  .2126, .7152, .0722, 0, 0,
  0, 0, 0, 1, 0,
];

/// بلاطة رقم (.num-tile) — فاضية = حدود متقطعة و"؟".
class NumTile extends StatelessWidget {
  const NumTile(this.value, {super.key, this.mid = false, this.filled = false, this.next = false});
  final Object? value;

  /// الرقم اللي في النص (السابق والتالي): أبيض بحدود بنفسجي.
  final bool mid;

  /// إجابة الطفل اتحطت هنا (أخضر).
  final bool filled;

  /// الخانة الفاضية اللي عليها الدور (حدود بنفسجي).
  final bool next;

  @override
  Widget build(BuildContext context) {
    final style = kidText(context.clampVw(38, 11, 62), height: 1.25);
    final box = BoxConstraints(minWidth: context.clampVw(62, 16, 92));
    const pad = EdgeInsets.symmetric(horizontal: 10, vertical: 2);
    if (value == null) {
      return DashedBox(
        color: next ? AppColors.grape : AppColors.line,
        constraints: box,
        padding: pad,
        child: Text(
          '؟',
          textAlign: TextAlign.center,
          style: style.copyWith(color: AppColors.grape),
        ),
      );
    }
    return Container(
      constraints: box,
      padding: pad,
      decoration: BoxDecoration(
        color: filled ? AppColors.mint : (mid ? AppColors.paper : AppColors.paper2),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: filled ? AppColors.mint : (mid ? AppColors.grape : AppColors.line), width: 4),
      ),
      child: Text(ar(value), textAlign: TextAlign.center, style: filled ? style.copyWith(color: Colors.white) : style),
    );
  }
}

/// التعبيرات دايمًا من اليمين (العُرف في الكتب العربية).
class _Expr extends StatelessWidget {
  const _Expr(this.v, {this.picked = const []});
  final ExprVisual v;

  /// إجابات الطفل اللي بتملا الخانات الفاضية بالترتيب (من اليمين).
  final List<Object> picked;

  @override
  Widget build(BuildContext context) {
    final opSize = context.clampVw(30, 8, 46);
    // الخانة الفاضية رقم k بتاخد picked[k] لو الطفل وصلها
    var blank = 0;
    Widget tile(ExprTile t) {
      if (t.value != null || !v.fillFromPicked) return NumTile(t.value, mid: t.mid);
      final k = blank++;
      if (k >= picked.length) return NumTile(null, next: k == picked.length);
      return NumTile(picked[k], filled: true).anim().scaleXY(begin: 1.18, end: 1, duration: 300.ms);
    }

    // سطر واحد دايمًا — لو مش واسع كفاية بيصغر بدل ما يتكسر على كذا سطر
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          // خانات بعناوين: الأسهم تتراصّ مع البلاطات مش مع العناوين
          crossAxisAlignment: v.parts.any((p) => p is ExprCaption) ? CrossAxisAlignment.end : CrossAxisAlignment.center,
          spacing: context.clampVw(8, 2.6, 18),
          children: [
            for (final (pi, p) in v.parts.indexed)
              switch (p) {
                ExprTile t => tile(t),
                ExprCaption c => Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(c.caption, style: kidText(context.clampVw(12, 3.2, 15), color: AppColors.inkSoft)),
                    const SizedBox(height: 5),
                    if (c.inner case final ExprTile t) tile(t),
                  ]),
                ExprOp o => Opacity(
                  opacity: o.separator ? .45 : 1,
                  child: Text(
                    o.op,
                    style: kidText(
                      o.separator ? opSize * .55 : opSize,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ),
                ExprSide s => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // مجموعة واحدة لقارئ الشاشة ("٣ 🍓") بدل ما يقرا كل صورة لوحدها — زي _Pics
                    Semantics(
                      label: '${ar(s.count)} ${s.emoji}',
                      child: ExcludeSemantics(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 150),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (var i = 0; i < s.count; i++)
                                TapCountItem(
                                  id: (pi, i),
                                  child: Text(
                                    s.emoji,
                                    style: TextStyle(
                                      fontSize: context.clampVw(22, 6, 34),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (s.number != null) ...[
                      const SizedBox(height: 4),
                      NumTile(s.number),
                    ],
                  ],
                ),
              },
          ],
        ),
      ),
    );
  }
}

/// كلمة كاملة، أو كلمة بحرف ناقص — الحروف حوالين الخانة بتفضل موصولة (RichText).
class _WordLine extends StatelessWidget {
  const _WordLine(this.v);
  final WordLineVisual v;

  @override
  Widget build(BuildContext context) {
    final style = kidText(
      v.big || v.word != null
          ? context.clampVw(34, 9, 54)
          : context.clampVw(30, 8, 46),
    );
    if (v.word != null) {
      return Text(v.word!, textAlign: TextAlign.center, style: style);
    }
    final letters = v.letters!;
    final hole = letters.indexOf(null);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: letters.sublist(0, hole).join()),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: DashedBox(
                color: AppColors.grape,
                radius: 14,
                constraints: const BoxConstraints(minWidth: 48),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  v.word == null &&
                          Directionality.of(context) == TextDirection.ltr
                      ? '?'
                      : '؟',
                  textAlign: TextAlign.center,
                  style: style.copyWith(color: AppColors.grape),
                ),
              ),
            ),
          ),
          TextSpan(text: letters.sublist(hole + 1).join()),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LetterChips extends StatelessWidget {
  const _LetterChips(this.v);
  final LetterChipsVisual v;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    for (var i = 0; i < v.letters.length; i++) {
      if (i > 0) {
        chips.add(
          Text(
            '+',
            style: kidText(
              context.clampVw(22, 6, 32),
              color: AppColors.inkSoft,
            ),
          ),
        );
      }
      chips.add(
        Container(
          constraints: BoxConstraints(minWidth: context.clampVw(48, 13, 66)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.paper2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line, width: 4),
          ),
          child: Text(
            v.letters[i],
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(30, 8, 44), height: 1.3),
          ),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }
}

/// جدول ١–٢٠ أو الحروف — الخانات الفاضية بتتملا بالترتيب، واللي عليها الدور بتنبض.
class _Table extends StatelessWidget {
  const _Table(this.v, this.picked);
  final TableVisual v;
  final List<Object> picked;

  @override
  Widget build(BuildContext context) {
    final (cols, maxW, dir, font) = switch (v.kind) {
      TableKind.numbers => (
        5,
        440.0,
        TextDirection.rtl,
        context.clampVw(19, 5.4, 28),
      ),
      TableKind.arLetters => (
        7,
        500.0,
        TextDirection.rtl,
        context.clampVw(19, 5, 27),
      ),
      TableKind.enLetters => (
        6,
        480.0,
        TextDirection.ltr,
        context.clampVw(17, 4.6, 24),
      ),
    };
    final gap = context.clampVw(5, 1.6, 10);
    var slot = 0;
    final cells = <Widget>[];
    for (final c in v.cells) {
      if (c != null) {
        cells.add(
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.paper2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(ar(c), style: kidText(font, color: AppColors.inkSoft)),
          ),
        );
        continue;
      }
      final k = slot++;
      if (k < picked.length) {
        cells.add(
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              ar(picked[k]),
              style: kidText(font, color: Colors.white),
            ),
          ).anim().scaleXY(begin: 1.18, end: 1, duration: 300.ms),
        );
      } else if (k == picked.length) {
        cells.add(
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grape, width: 3),
                ),
              )
              .anim(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.08, duration: 650.ms),
        );
      } else {
        cells.add(
          const DashedBox(
            color: AppColors.line,
            width: 3,
            radius: 16,
            dash: 6,
            gap: 5,
            child: SizedBox.expand(),
          ),
        );
      }
    }
    return Directionality(
      textDirection: dir,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: gap,
          crossAxisSpacing: gap,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ),
    );
  }
}

/// اتبع النمط: صف العناصر وفي الآخر "؟" بتنبض.
class _Pattern extends StatelessWidget {
  const _Pattern(this.v);
  final PatternVisual v;

  @override
  Widget build(BuildContext context) {
    final box = context.clampVw(46, 13, 64);
    Widget cell(Widget child, {bool q = false}) => Container(
          width: box,
          height: box,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: q ? Colors.white : AppColors.paper2,
            borderRadius: BorderRadius.circular(18),
            border: q ? Border.all(color: AppColors.grape, width: 4) : null,
          ),
          child: child,
        );
    final hole = cell(Text('؟', style: kidText(box * .55, color: AppColors.grape)), q: true)
        .anim(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.08, duration: 800.ms);
    // سطر واحد دايمًا — لو مش واسع كفاية بيصغر بدل ما "؟" تنزل لوحدها تحت
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(spacing: context.clampVw(6, 2, 12), children: [
          for (final (i, e) in v.items.indexed)
            if (i == v.hole)
              hole
            else
              cell(Text(e, style: TextStyle(fontSize: box * .55)))
                  .anim()
                  .fadeIn(delay: (i * 70).ms, duration: 250.ms)
                  .scaleXY(begin: .6, end: 1, duration: 300.ms, curve: Curves.easeOutBack),
          if (v.hole == null) hole,
        ]),
      ),
    );
  }
}

/// ساعة بعقارب — نفس clockFace في الويب: العقرب القصير للساعة والطويل البنفسجي للدقايق.
class ClockFace extends StatelessWidget {
  const ClockFace({super.key, required this.hour, required this.minute, this.size = 180});
  final int hour, minute;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'ساعة',
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: AppColors.shadow, offset: Offset(0, 6))],
          ),
          child: CustomPaint(size: Size.square(size), painter: _ClockPainter(hour, minute)),
        ),
      );
}

class _ClockPainter extends CustomPainter {
  _ClockPainter(this.h, this.m);
  final int h, m;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100; // الرسمة على مربع ١٠٠×١٠٠ زي الـ SVG
    const c = Offset(50, 50);
    canvas.scale(k);
    canvas
      ..drawCircle(c, 47, Paint()..color = Colors.white)
      ..drawCircle(c, 47, Paint()
        ..color = AppColors.grape
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);
    for (var i = 0; i < 12; i++) {
      final a = (i * 30 - 90) * math.pi / 180;
      final tp = TextPainter(
        text: TextSpan(text: ar(i == 0 ? 12 : i), style: kidText(9, weight: FontWeight.w700, color: const Color(0xFF4A5568))),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(50 + 38 * math.cos(a) - tp.width / 2, 50 + 38 * math.sin(a) - tp.height / 2));
    }
    void hand(double deg, double len, double w, Color col) {
      final a = (deg - 90) * math.pi / 180;
      canvas.drawLine(c, Offset(50 + len * math.cos(a), 50 + len * math.sin(a)), Paint()
        ..color = col
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round);
    }

    hand((h % 12) * 30 + m * .5, 24, 5, const Color(0xFF2D3748));
    hand(m * 6.0, 34, 3, AppColors.grape);
    canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFF2D3748));
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.h != h || old.m != m;
}
