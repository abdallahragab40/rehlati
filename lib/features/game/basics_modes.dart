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
          Text('🏁', style: _emoji(size)),
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
