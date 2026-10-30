/// رسومات الأساسيات: الأقلام بأطوالها، المجموعات، الفلوس الصغيرة، الأشكال، الطابور،
/// الأزواج، الرسم البياني بالصور، والنبات بأجزائه.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../domain/question.dart';
import 'games_modes.dart';

TextStyle _emoji(double size) => TextStyle(fontSize: size, height: 1.1);

// ---------------------------------------------------------------- 📏 قلم بطوله

/// قلم أفقي بطول [len] من ٧ — المقارنة بتبدأ من نفس النقطة.
class BarChoice extends StatelessWidget {
  const BarChoice(this.len, {super.key});
  final int len;

  @override
  Widget build(BuildContext context) {
    final unit = context.clampVw(26, 6.5, 32);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SizedBox(
        width: unit * 7 + 20,
        height: 34,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: unit * len,
              height: 22,
              decoration: BoxDecoration(color: const Color(0xFFFFC43D), borderRadius: BorderRadius.circular(6)),
            ),
            CustomPaint(size: const Size(16, 22), painter: _TipPainter()),
          ]),
        ),
      ),
    );
  }
}

class _TipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      // القلم بيبدأ من اليمين، فسنّه على الشمال
      Path()
        ..moveTo(size.width, 0)
        ..lineTo(0, size.height / 2)
        ..lineTo(size.width, size.height)
        ..close(),
      Paint()..color = const Color(0xFFF2D7B0),
    );
    canvas.drawCircle(Offset(size.width * .2, size.height / 2), 2.5, Paint()..color = AppColors.ink);
  }

  @override
  bool shouldRepaint(_TipPainter old) => false;
}

// ---------------------------------------------------------------- 🍎 مجموعة

/// "🍎|4" ← ٤ صور في شبكة صغيرة.
class GroupChoice extends StatelessWidget {
  const GroupChoice(this.spec, {super.key});
  final String spec;

  @override
  Widget build(BuildContext context) {
    final [e, n] = spec.split('|');
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: context.clampVw(130, 34, 170)),
      child: Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 2, children: [
        for (var i = 0; i < int.parse(n); i++) Text(e, style: _emoji(context.clampVw(24, 6.4, 30))),
      ]),
    );
  }
}

// ---------------------------------------------------------------- 🪙 الفلوس الصغيرة

/// عملة (ربع، نص، جنيه) دايرة، وورقة (٥، ١٠) مستطيل — بالرقم مكتوب عليها.
class CoinChoice extends StatelessWidget {
  const CoinChoice(this.kind, {super.key, this.size = 64});
  final String kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (label, color, note) = switch (kind) {
      'q' => ('ربع\nجنيه', const Color(0xFFC9A34A), false),
      'h' => ('نص\nجنيه', const Color(0xFFB8B8B8), false),
      '1' => ('1\nجنيه', const Color(0xFFD9B44A), false),
      '5' => ('5 جنيه', const Color(0xFF8FB3E0), true),
      _ => ('10 جنيه', const Color(0xFFE0A38F), true),
    };
    return Container(
      width: note ? size * 1.7 : size,
      height: note ? size * .85 : size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: note ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: note ? BorderRadius.circular(8) : null,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))],
      ),
      child: Text(ar(label), textAlign: TextAlign.center, style: kidText(size * .2, color: AppColors.ink, height: 1.1)),
    );
  }
}

class CoinsView extends StatelessWidget {
  const CoinsView(this.v, {super.key});
  final CoinsVisual v;

  @override
  Widget build(BuildContext context) => Wrap(alignment: WrapAlignment.center, spacing: 10, runSpacing: 10, children: [
        for (final (i, c) in v.coins.indexed)
          CoinChoice(c, size: context.clampVw(66, 17, 80)).anim().fadeIn(delay: (i * 90).ms, duration: 250.ms),
      ]);
}

// ---------------------------------------------------------------- 🔷 شكل كبير

class ShapeView extends StatelessWidget {
  const ShapeView(this.v, {super.key});
  final ShapeVisual v;

  @override
  Widget build(BuildContext context) =>
      Center(child: ShapeIcon('${v.shape}|blue', size: context.clampVw(120, 32, 160)));
}

// ---------------------------------------------------------------- 🏁 الطابور

class QueueView extends StatelessWidget {
  const QueueView(this.v, {super.key});
  final QueueVisual v;

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(44, 11, 58);
    // من اليمين: العلم وبعده الأول — زي القراية
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(spacing: 6, children: [
          if (v.flag) Text('🏁', style: _emoji(size)),
          for (final e in v.items) Text(e, style: _emoji(size)),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- 🧦 الأزواج

/// الصور اتنين اتنين فوق بعض، والفردي بيفضل واحد لوحده بعلامة.
class PairsView extends StatelessWidget {
  const PairsView(this.v, {super.key});
  final PairsVisual v;

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(30, 8, 40);
    final pairs = v.count ~/ 2, single = v.count.isOdd;
    Widget cell(List<Widget> c, {bool alone = false}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: alone ? AppColors.noBg : AppColors.paper2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: alone ? AppColors.coral : AppColors.line, width: 2),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: c),
        );
    return Semantics(
      label: '${ar(v.count)} ${v.emoji}',
      child: ExcludeSemantics(
        child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
          for (var i = 0; i < pairs; i++) cell([Text(v.emoji, style: _emoji(size)), Text(v.emoji, style: _emoji(size))]),
          if (single) cell([Text(v.emoji, style: _emoji(size)), Text('❓', style: _emoji(size * .7))], alone: true),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- 📊 الرسم البياني

class PicGraphView extends StatelessWidget {
  const PicGraphView(this.v, {super.key});
  final PicGraphVisual v;

  @override
  Widget build(BuildContext context) {
    final size = context.clampVw(30, 8, 38);
    final top = v.rows.map((r) => r.$2).reduce(math.max);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(18)),
        child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, spacing: 14, children: [
          for (final (e, n) in v.rows)
            Column(mainAxisSize: MainAxisSize.min, children: [
              SizedBox(height: (top - n) * size * 1.12),
              for (var i = 0; i < n; i++) Text(e, style: _emoji(size)),
              Container(width: size * 1.3, height: 4, color: AppColors.inkSoft),
            ]),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- 📐 الزوايا والخطوط

class AngleView extends StatelessWidget {
  const AngleView(this.v, {super.key});
  final AngleVisual v;

  @override
  Widget build(BuildContext context) {
    final w = context.clampVw(220, 56, 260);
    return Center(
      child: Semantics(label: 'زاوية', child: CustomPaint(size: Size(w, w * .62), painter: _AnglePainter(v.degrees))),
    );
  }
}

class _AnglePainter extends CustomPainter {
  _AnglePainter(this.degrees);
  final int degrees;

  @override
  void paint(Canvas canvas, Size size) {
    // الرأس تحت في النص، وضلع أفقي لليمين والتاني بالزاوية
    final o = Offset(size.width * (degrees > 90 ? .55 : .25), size.height - 8);
    final len = math.min(size.width * .7, size.height * 1.1);
    final rad = degrees * math.pi / 180;
    final arm = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(o, o + Offset(len * .95, 0), arm);
    canvas.drawLine(o, o + Offset(math.cos(rad) * len * .9, -math.sin(rad) * len * .9), arm);
    final arc = Paint()
      ..color = AppColors.grape
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    const r = 34.0;
    if (degrees == 90) {
      canvas.drawRect(Rect.fromLTWH(o.dx, o.dy - 22, 22, 22), arc);
    } else {
      canvas.drawArc(Rect.fromCircle(center: o, radius: r), 0, -rad, false, arc);
    }
  }

  @override
  bool shouldRepaint(_AnglePainter old) => old.degrees != degrees;
}

class LinesView extends StatelessWidget {
  const LinesView(this.v, {super.key});
  final LinesVisual v;

  @override
  Widget build(BuildContext context) {
    final w = context.clampVw(220, 56, 260);
    return Center(
      child: Semantics(label: 'خطين', child: CustomPaint(size: Size(w, w * .62), painter: _LinesPainter(v.kind))),
    );
  }
}

class _LinesPainter extends CustomPainter {
  _LinesPainter(this.kind);
  final int kind;

  @override
  void paint(Canvas canvas, Size size) {
    final a = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final b = Paint()
      ..color = AppColors.grape
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height;
    switch (kind) {
      case 0:
        canvas.drawLine(Offset(w * .1, h * .3), Offset(w * .9, h * .15), a);
        canvas.drawLine(Offset(w * .1, h * .8), Offset(w * .9, h * .65), b);
      case 1:
        canvas.drawLine(Offset(w * .1, h * .55), Offset(w * .9, h * .55), a);
        canvas.drawLine(Offset(w * .5, h * .05), Offset(w * .5, h * .95), b);
        canvas.drawRect(Rect.fromLTWH(w * .5, h * .55 - 16, 16, 16), Paint()
          ..color = AppColors.inkSoft
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      default:
        canvas.drawLine(Offset(w * .1, h * .85), Offset(w * .9, h * .15), a);
        canvas.drawLine(Offset(w * .15, h * .3), Offset(w * .85, h * .7), b);
    }
  }

  @override
  bool shouldRepaint(_LinesPainter old) => old.kind != kind;
}

// ---------------------------------------------------------------- 🟩 المساحة والمحيط

class GridAreaView extends StatelessWidget {
  const GridAreaView(this.v, {super.key});
  final GridAreaVisual v;

  @override
  Widget build(BuildContext context) {
    final maxW = context.clampVw(260, 66, 320);
    final unit = math.min(maxW / v.cols, 34.0);
    return Center(
      child: Semantics(
        label: v.sides == null ? 'شكل من ${ar(v.cells.length)} مربعات' : 'مستطيل طوله ${ar(v.sides!.$1)} وعرضه ${ar(v.sides!.$2)}',
        child: CustomPaint(size: Size(v.cols * unit + 40, v.rows * unit + 36), painter: _GridAreaPainter(v, unit)),
      ),
    );
  }
}

class _GridAreaPainter extends CustomPainter {
  _GridAreaPainter(this.v, this.unit);
  final GridAreaVisual v;
  final double unit;

  @override
  void paint(Canvas canvas, Size size) {
    final ox = 20.0, oy = 8.0;
    Rect cell(int x, int y) => Rect.fromLTWH(ox + x * unit, oy + (v.rows - 1 - y) * unit, unit, unit);
    final fill = Paint()..color = const Color(0xFF9CDB6B);
    for (final (x, y) in v.cells) {
      canvas.drawRect(cell(x, y), fill);
    }
    if (v.grid) {
      final line = Paint()
        ..color = AppColors.line
        ..strokeWidth = 1.5;
      for (var x = 0; x <= v.cols; x++) {
        canvas.drawLine(Offset(ox + x * unit, oy), Offset(ox + x * unit, oy + v.rows * unit), line);
      }
      for (var y = 0; y <= v.rows; y++) {
        canvas.drawLine(Offset(ox, oy + y * unit), Offset(ox + v.cols * unit, oy + y * unit), line);
      }
    }
    // حدود الشكل نفسه
    final edge = Paint()
      ..color = AppColors.ink
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final set = v.cells.toSet();
    for (final (x, y) in v.cells) {
      final r = cell(x, y);
      if (!set.contains((x, y + 1))) canvas.drawLine(r.topLeft, r.topRight, edge);
      if (!set.contains((x, y - 1))) canvas.drawLine(r.bottomLeft, r.bottomRight, edge);
      if (!set.contains((x - 1, y))) canvas.drawLine(r.topLeft, r.bottomLeft, edge);
      if (!set.contains((x + 1, y))) canvas.drawLine(r.topRight, r.bottomRight, edge);
    }
    if (v.sides case (final w, final h)) {
      void label(String t, Offset at) {
        final tp = TextPainter(
          text: TextSpan(text: t, style: kidText(18, color: AppColors.ink)),
          textDirection: TextDirection.rtl,
        )..layout();
        tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      }

      label(ar(w), Offset(ox + w * unit / 2, oy + v.rows * unit + 14));
      label(ar(h), Offset(ox - 11, oy + (v.rows - h) * unit + h * unit / 2));
    }
  }

  @override
  bool shouldRepaint(_GridAreaPainter old) => old.v != v || old.unit != unit;
}

// ---------------------------------------------------------------- ⚫ التمثيل بالنقاط

class DotPlotView extends StatelessWidget {
  const DotPlotView(this.v, {super.key});
  final DotPlotVisual v;

  @override
  Widget build(BuildContext context) {
    final top = v.rows.map((r) => r.$2).reduce(math.max);
    const dot = 22.0;
    return Semantics(
      label: [for (final (n, c) in v.rows) '${ar(n)}: ${ar(c)}'].join('، '),
      child: ExcludeSemantics(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(18)),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  for (final (_, c) in v.rows)
                    SizedBox(
                      width: 46,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(height: (top - c) * (dot + 4)),
                        for (var i = 0; i < c; i++)
                          Container(
                            width: dot,
                            height: dot,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(color: AppColors.grape, shape: BoxShape.circle),
                          ),
                      ]),
                    ),
                ]),
                Container(width: 46.0 * v.rows.length, height: 3, color: AppColors.inkSoft),
                Row(children: [
                  for (final (n, _) in v.rows)
                    SizedBox(width: 46, child: Text(ar(n), textAlign: TextAlign.center, style: kidText(18))),
                ]),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 🔺 تكوين أشكال

/// القطع ملوّنة بحدود واضحة. متفرّقة: كل قطعة بتتزق بعيد عن نص الشكل.
class ComposeView extends StatelessWidget {
  const ComposeView(this.v, {super.key});
  final ComposeVisual v;

  @override
  Widget build(BuildContext context) {
    final side = context.clampVw(200, 50, 240);
    return Center(
      child: Semantics(
        label: 'شكل من ${ar(v.pieces.length)} قطع',
        child: CustomPaint(size: Size(side, side * .85), painter: _ComposePainter(v)),
      ),
    );
  }
}

class _ComposePainter extends CustomPainter {
  _ComposePainter(this.v);
  final ComposeVisual v;

  static const _fills = [Color(0xFFFFC44D), Color(0xFF6EC6FF), Color(0xFFFF8A80), Color(0xFF9CDB6B), Color(0xFFC59BFF)];

  @override
  void paint(Canvas canvas, Size size) {
    final all = [for (final p in v.pieces) ...p];
    final minX = all.map((p) => p.$1).reduce(math.min), maxX = all.map((p) => p.$1).reduce(math.max);
    final minY = all.map((p) => p.$2).reduce(math.min), maxY = all.map((p) => p.$2).reduce(math.max);
    final cx = (minX + maxX) / 2, cy = (minY + maxY) / 2;
    // التفريق: كل قطعة بتبعد عن النص بنسبة من حجم الشكل
    final gap = v.apart ? .35 * math.max(maxX - minX, maxY - minY) : 0.0;
    List<(double, double)> moved(List<(double, double)> piece) {
      if (gap == 0) return piece;
      final px = piece.map((p) => p.$1).reduce((a, b) => a + b) / piece.length;
      final py = piece.map((p) => p.$2).reduce((a, b) => a + b) / piece.length;
      final dx = px - cx, dy = py - cy, d = math.sqrt(dx * dx + dy * dy);
      return d == 0 ? piece : [for (final p in piece) (p.$1 + dx / d * gap, p.$2 + dy / d * gap)];
    }

    final pieces = [for (final p in v.pieces) moved(p)];
    final pts = [for (final p in pieces) ...p];
    final x0 = pts.map((p) => p.$1).reduce(math.min), x1 = pts.map((p) => p.$1).reduce(math.max);
    final y0 = pts.map((p) => p.$2).reduce(math.min), y1 = pts.map((p) => p.$2).reduce(math.max);
    final scale = math.min((size.width - 16) / (x1 - x0), (size.height - 16) / (y1 - y0));
    final ox = (size.width - (x1 - x0) * scale) / 2, oy = (size.height - (y1 - y0) * scale) / 2;
    Offset at((double, double) p) => Offset(ox + (p.$1 - x0) * scale, size.height - oy - (p.$2 - y0) * scale);
    final border = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeJoin = StrokeJoin.round;
    for (final (i, piece) in pieces.indexed) {
      final path = Path()..addPolygon([for (final p in piece) at(p)], true);
      canvas.drawPath(path, Paint()..color = _fills[i % _fills.length]);
      canvas.drawPath(path, border);
    }
  }

  @override
  bool shouldRepaint(_ComposePainter old) => old.v != v;
}

// ---------------------------------------------------------------- 📦 in / on / under

/// الحاجة جوه المكان (نصها التحتاني ورا المكان)، أو فوقه لازقة فيه، أو تحته.
class PrepView extends StatelessWidget {
  const PrepView(this.v, {super.key});
  final PrepVisual v;

  @override
  Widget build(BuildContext context) {
    final big = context.clampVw(110, 26, 140), small = big * .5;
    final w = big * 1.3, h = big * 1.75;
    final placeTop = switch (v.prep) { 'under' => 0.0, _ => h - big };
    final thingTop = switch (v.prep) {
      'in' => placeTop - small * .45,
      'on' => placeTop - small * .92,
      _ => big * .98,
    };
    Widget at(double top, String e, double size) => Positioned(
          top: top,
          left: 0,
          right: 0,
          child: Text(e, textAlign: TextAlign.center, style: _emoji(size)),
        );
    return Semantics(
      label: '${v.thing} ${v.prep} ${v.place}',
      child: ExcludeSemantics(
        child: SizedBox(
          width: w,
          height: h,
          // في «in» المكان بيترسم فوق الحاجة عشان تبان طالعة منه
          child: Stack(clipBehavior: Clip.none, children: [
            if (v.prep == 'in') ...[at(thingTop, v.thing, small), at(placeTop, v.place, big)]
            else ...[at(placeTop, v.place, big), at(thingTop, v.thing, small)],
          ]),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 📊 الأعمدة

/// أعمدة ملوّنة على شبكة بخطوط كل [BarGraphVisual.scale]، والأرقام على اليمين، والصور تحت.
class BarGraphView extends StatelessWidget {
  const BarGraphView(this.v, {super.key});
  final BarGraphVisual v;

  static const _colors = [Color(0xFFE5534B), Color(0xFFF2B233), Color(0xFFF08A24), Color(0xFF8E5CD9), Color(0xFFE0457B)];

  @override
  Widget build(BuildContext context) {
    final top = (v.rows.map((r) => r.$2).reduce(math.max) / v.scale).ceil() + 1;
    const unit = 26.0, bar = 42.0, gap = 18.0, axis = 34.0;
    final width = axis + v.rows.length * (bar + gap) + gap / 2;
    return Semantics(
      label: [for (final (e, n) in v.rows) '$e ${ar(n)}'].join('، '),
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 12, 10, 6),
            decoration: BoxDecoration(color: AppColors.paper2, borderRadius: BorderRadius.circular(18)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              CustomPaint(
                size: Size(width, top * unit + 8),
                painter: _BarsPainter(v, top, unit, bar, gap, axis, _colors),
              ),
              const SizedBox(height: 4),
              Directionality(
                textDirection: TextDirection.rtl,
                child: SizedBox(
                  width: width,
                  child: Row(children: [
                    const SizedBox(width: axis + gap / 2),
                    for (final (e, _) in v.rows)
                      SizedBox(
                        width: bar + gap,
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(width: bar, child: Text(e, textAlign: TextAlign.center, style: _emoji(30))),
                        ),
                      ),
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _BarsPainter extends CustomPainter {
  _BarsPainter(this.v, this.top, this.unit, this.bar, this.gap, this.axis, this.colors);
  final BarGraphVisual v;
  final int top;
  final double unit, bar, gap, axis;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.height;
    final line = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1.5;
    // الأرقام على اليمين (زي القراية) والخطوط ناحية الشمال
    for (var t = 0; t <= top; t++) {
      final y = base - t * unit;
      canvas.drawLine(Offset(0, y), Offset(size.width - axis, y), line..color = t == 0 ? AppColors.inkSoft : AppColors.line);
      final tp = TextPainter(
        text: TextSpan(text: ar(t * v.scale), style: kidText(14, weight: FontWeight.w700, color: AppColors.inkSoft)),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(size.width - axis + 6, y - tp.height / 2));
    }
    for (final (i, (_, n)) in v.rows.indexed) {
      final right = size.width - axis - gap / 2 - i * (bar + gap);
      final h = n / v.scale * unit;
      canvas.drawRRect(
        RRect.fromRectAndCorners(Rect.fromLTWH(right - bar, base - h, bar, h), topLeft: const Radius.circular(6), topRight: const Radius.circular(6)),
        Paint()..color = colors[i % colors.length],
      );
    }
  }

  @override
  bool shouldRepaint(_BarsPainter old) => old.v != v;
}

// ---------------------------------------------------------------- 🌱 النبات

class PlantView extends StatelessWidget {
  const PlantView(this.v, {super.key});
  final PlantVisual v;

  @override
  Widget build(BuildContext context) {
    final side = context.clampVw(190, 50, 240);
    return Center(
      child: Semantics(
        label: 'نبات',
        child: CustomPaint(size: Size(side, side * 1.15), painter: _PlantPainter(v.highlight)),
      ),
    );
  }
}

class _PlantPainter extends CustomPainter {
  _PlantPainter(this.highlight);
  final String? highlight;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height, cx = w / 2, ground = h * .7;
    // الأرض
    canvas.drawRect(Rect.fromLTWH(0, ground, w, h - ground), Paint()..color = const Color(0xFFC89B6D));
    final root = Paint()
      ..color = const Color(0xFF8B5E3C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final dx in [-.12, -.05, .04, .11]) {
      canvas.drawPath(
        Path()
          ..moveTo(cx, ground)
          ..quadraticBezierTo(cx + w * dx * .5, ground + h * .1, cx + w * dx, ground + h * .2),
        root,
      );
    }
    // الساق
    canvas.drawLine(Offset(cx, ground), Offset(cx, h * .2), Paint()
      ..color = const Color(0xFF3F9A3F)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    // ورقتين
    final leaf = Paint()..color = const Color(0xFF5CC85C);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx - w * .14, h * .48), width: w * .24, height: h * .09), leaf);
    canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * .14, h * .4), width: w * .24, height: h * .09), leaf);
    // الثمرة
    canvas.drawCircle(Offset(cx + w * .14, h * .56), w * .055, Paint()..color = const Color(0xFFFF6B6B));
    // الزهرة
    final petal = Paint()..color = const Color(0xFFFF9FD0);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawCircle(Offset(cx + math.cos(a) * w * .07, h * .17 + math.sin(a) * w * .07), w * .05, petal);
    }
    canvas.drawCircle(Offset(cx, h * .17), w * .045, Paint()..color = const Color(0xFFFFC43D));

    final at = switch (highlight) {
      'root' => Offset(cx + w * .02, ground + h * .14),
      'stem' => Offset(cx, h * .62),
      'leaf' => Offset(cx - w * .14, h * .48),
      'flower' => Offset(cx, h * .17),
      'fruit' => Offset(cx + w * .14, h * .56),
      _ => null,
    };
    if (at != null) {
      canvas.drawCircle(at, w * .11, Paint()
        ..color = AppColors.grape
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4);
      // سهم من الشمال
      final from = Offset(w * .04, at.dy);
      final to = Offset(at.dx - w * .12, at.dy);
      final arrow = Paint()
        ..color = AppColors.grape
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(from, to, arrow)
        ..drawLine(to, to + const Offset(-10, -8), arrow)
        ..drawLine(to, to + const Offset(-10, 8), arrow);
    }
  }

  @override
  bool shouldRepaint(_PlantPainter old) => old.highlight != highlight;
}
