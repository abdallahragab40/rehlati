/// رسم مرئيات السؤال (كانت HTML في الويب).
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/dashed_box.dart';
import '../../domain/question.dart';
import '../madd/madd_style.dart';
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
        ListenVisual v => Center(child: ListenButton(v.say)),
      },
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
                    .animate(delay: (i * 40).ms)
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
      return NumTile(picked[k], filled: true).animate().scaleXY(begin: 1.18, end: 1, duration: 300.ms);
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
                    ConstrainedBox(
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
          ).animate().scaleXY(begin: 1.18, end: 1, duration: 300.ms),
        );
      } else if (k == picked.length) {
        cells.add(
          Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.grape, width: 3),
                ),
              )
              .animate(onPlay: (c) => c.repeat(reverse: true))
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
