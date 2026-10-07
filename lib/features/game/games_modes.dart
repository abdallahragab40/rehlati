/// واجهات عالم الألعاب: البالونات، التلوين بالأرقام، الإيقاع، السباق، البازل، والأشكال.
/// منقولة من css/game.css و renderQuestion في js/app.js.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/generators/games_generators.dart';
import '../../domain/question.dart';
import '../scenes/art.dart';
import 'modes.dart';

const _balloonColors = [
  Color(0xFFFF6B6B), Color(0xFFFFC43D), Color(0xFF4CC9A7), Color(0xFF4C9BFF),
  Color(0xFFC06BE8), Color(0xFFFF9F45), Color(0xFF2FC9B4),
];

// ---------------------------------------------------------------- 🎈 البالونات

/// بالونات بتطلع من تحت لفوق وتتمايل، وكل واحدة بسرعتها. الطفل يفرقع الصح.
/// "تقليل الحركة": البالونات واقفة في صف.
class BalloonSky extends StatefulWidget {
  const BalloonSky({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  State<BalloonSky> createState() => _BalloonSkyState();
}

class _BalloonSkyState extends State<BalloonSky> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);

  /// لكل بالونة: مكانها الأفقي، مدة الطلعة، بدايتها في المسار، ومدة التمايل.
  late final List<(double, double, double, double)> _paths;

  @override
  void initState() {
    super.initState();
    final n = widget.s.q.choices.length;
    final r = math.Random(widget.s.idx * 97 + n);
    _paths = [
      for (var i = 0; i < n; i++)
        (
          (4 + i * (92 / n) + r.nextDouble() * 4) / 100,
          5 + r.nextDouble() * 3,
          r.nextDouble() * 8, // بداية مختلفة: البالونات متوزّعة من أول لحظة
          2.2 + r.nextDouble() * 1.6,
        ),
    ];
    _ticker = createTicker((d) {
      final t = d.inMicroseconds / 1e6;
      if (t - _t.value >= 1 / 30) _t.value = t;
    })..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  Widget _balloon(int i, double width) {
    final s = widget.s, q = s.q;
    final v = q.choices[i];
    final popped = s.rightAnchor == 'c$i';
    final wrong = s.wrongAnchor == 'c$i';
    Widget b = Balloon(ar(v), _balloonColors[i % _balloonColors.length], width: width);
    if (popped) {
      b = b
          .animate()
          .scaleXY(begin: 1, end: 1.35, duration: 160.ms)
          .then()
          .scaleXY(begin: 1, end: .1, duration: 240.ms)
          .fadeOut(duration: 240.ms);
    } else if (wrong) {
      b = b.animate(key: ValueKey(s.wrongTick)).shakeX(hz: 5, amount: 8, duration: 400.ms);
    } else if (s.hintTarget == v) {
      b = b.animate(onPlay: (c) => c.repeat(reverse: true)).scaleXY(begin: 1, end: 1.12, duration: 450.ms);
    }
    return KeyedSubtree(
      key: widget.keyFor('c$i'),
      child: GestureDetector(
        onTap: s.locked ? null : () => widget.engine.answer(i),
        child: Semantics(button: true, label: '$v', child: b),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = context.clampVw(56, 15, 76);
    final n = widget.s.q.choices.length;
    if (MediaQuery.disableAnimationsOf(context)) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [for (var i = 0; i < n; i++) _balloon(i, width)],
      );
    }
    final h = (MediaQuery.sizeOf(context).height * .38).clamp(230.0, 310.0);
    final balloonH = width * 104 / 64;
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        height: h,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCDEBFF), Color(0xFFEAF7FF), Color(0xFFDFF3DD)],
            stops: [0, .7, 1],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, box) => ValueListenableBuilder<double>(
            valueListenable: _t,
            builder: (_, t, _) => Stack(clipBehavior: Clip.none, children: [
              for (var i = 0; i < n; i++)
                Builder(builder: (_) {
                  final (left, dur, start, sway) = _paths[i];
                  final p = ((t + start) / dur) % 1;
                  final dx = 14 * math.sin(2 * math.pi * (t + start) / (sway * 2));
                  return Positioned(
                    left: (box.maxWidth - width) * left + dx,
                    bottom: -balloonH + (h + balloonH) * p,
                    child: _balloon(i, width),
                  );
                }),
            ]),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- 🎨 لوّن بالأرقام

class ColorGame extends StatelessWidget {
  const ColorGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q;
    final colorOf = {for (final p in q.pots) p.n: Color(p.color)};
    final cell = context.clampVw(13, 3.6, 17);
    return Column(children: [
      Text(q.hint,
          textAlign: TextAlign.center,
          style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      Container(
        constraints: const BoxConstraints(maxWidth: 340),
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(16)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: GridView.count(
            crossAxisCount: q.paintCols,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < q.paintCells.length; i++)
                KeyedSubtree(
                  key: keyFor('p$i'),
                  child: _cell(i, colorOf, cell),
                ),
            ],
          ),
        ),
      ),
      Wrap(alignment: WrapAlignment.center, spacing: 14, runSpacing: 10, children: [
        for (final p in q.pots) _pot(context, p),
      ]),
    ]);
  }

  Widget _cell(int i, Map<int, Color> colorOf, double font) {
    final n = s.q.paintCells[i];
    final painted = s.painted.contains(i);
    Widget c = GestureDetector(
      onTap: painted || s.locked ? null : () => engine.colorPaint(i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: painted ? colorOf[n] : (s.wrongAnchor == 'p$i' ? AppColors.noBg : Colors.white),
          borderRadius: BorderRadius.circular(8),
        ),
        child: painted ? null : Text(ar(n), style: kidText(font, color: AppColors.inkSoft)),
      ),
    );
    if (painted) c = c.animate().scaleXY(begin: .6, end: 1, duration: 300.ms, curve: Curves.easeOutBack);
    if (s.wrongAnchor == 'p$i') c = c.animate(key: ValueKey(s.wrongTick)).shakeX(hz: 5, amount: 5, duration: 350.ms);
    return Semantics(button: !painted, label: painted ? 'متلوّنة' : 'خانة رقم $n', child: c);
  }

  Widget _pot(BuildContext context, PaintPot p) {
    final sel = s.paintSel == p.n;
    final d = context.clampVw(54, 15, 68);
    final pot = Pressable3D(
      onTap: s.locked ? null : () => engine.colorSelect(p.n),
      color: Color(p.color),
      radius: d,
      depth: 5,
      border: Border.all(color: sel ? AppColors.ink : Colors.white, width: sel ? 5 : 4),
      semanticLabel: '${p.name} رقم ${ar(p.n)}',
      child: SizedBox.square(
        dimension: d,
        child: Center(child: Text(ar(p.n), style: kidText(d * .42, color: Colors.white))),
      ),
    );
    return AnimatedSlide(
      offset: Offset(0, sel ? -.08 : 0),
      duration: const Duration(milliseconds: 180),
      child: pot,
    );
  }
}

// ---------------------------------------------------------------- 🥁 كرر الإيقاع

class RhythmGame extends StatelessWidget {
  const RhythmGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q;
    final size = context.clampVw(78, 22, 104);
    return Column(children: [
      // نقطة لكل نبضة — بتنوّر مع كل ضغطة صح
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 10, children: [
          for (var i = 0; i < q.beats.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              transform: Matrix4.diagonal3Values(i < s.picked.length ? 1.3 : 1, i < s.picked.length ? 1.3 : 1, 1),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < s.picked.length ? AppColors.grass : AppColors.line,
              ),
            ),
        ]),
      ),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: context.clampVw(10, 3, 18), children: [
          for (final p in q.pads)
            KeyedSubtree(
              key: keyFor('pad${p.k}'),
              child: _pad(p, size),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      KidButton('▶️ اسمع تاني', kind: BtnKind.ghost, onTap: s.rhythmLock || s.locked ? null : engine.rhythmPlay),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(q.hint,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      ),
    ]);
  }

  Widget _pad(RhythmPad p, double size) {
    final lit = s.padLit == p.k;
    final pad = Pressable3D(
      onTap: () => engine.rhythmTap(p.k),
      color: Color(p.color),
      radius: 26,
      depth: 7,
      semanticLabel: p.name,
      child: SizedBox.square(dimension: size, child: Center(child: Text(p.icon, style: TextStyle(fontSize: size * .44)))),
    );
    if (!lit) return pad;
    // الطبلة بتنوّر وتنط مع كل دقة (عرض الإيقاع أو ضغطة الطفل)
    return pad
        .animate(key: ValueKey(s.padTick))
        .scaleXY(begin: 1, end: 1.08, duration: 90.ms)
        .tint(color: Colors.white, begin: 0, end: .35, duration: 90.ms)
        .then()
        .scaleXY(begin: 1, end: 1 / 1.08, duration: 160.ms)
        .tint(color: Colors.white, begin: .35, end: 0, duration: 160.ms);
  }
}

// ---------------------------------------------------------------- 🏁 السباق

/// الطفل بيتقدّم مع كل إجابة صح، والسلحفاة بتمشي مع كل سؤال.
class RaceTrack extends StatelessWidget {
  const RaceTrack(this.s, {super.key});
  final GameSession s;

  @override
  Widget build(BuildContext context) {
    final me = s.correct / s.total, rival = s.idx / s.total;
    final msg = me > rival
        ? 'انت قدام السلحفاة! 🎉'
        : me == rival
            ? 'متعادلين — يلا!'
            : 'السلحفاة قدام شوية 💪';
    Widget lane(String runner, double at) => Container(
          height: 46,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: const LinearGradient(
              colors: [Color(0xFFEFE6D6), Color(0xFFE6DCCA)],
              stops: [.5, .5],
              tileMode: TileMode.repeated,
              end: Alignment(-.92, 0),
            ),
          ),
          child: LayoutBuilder(
            builder: (_, box) => Stack(children: [
              const PositionedDirectional(end: 6, top: 0, bottom: 0, child: Center(child: Text('🏁', style: TextStyle(fontSize: 24)))),
              AnimatedPositionedDirectional(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                start: (box.maxWidth - 40) * at.clamp(0, 1),
                top: 0,
                bottom: 0,
                child: Center(child: Text(runner, style: const TextStyle(fontSize: 30))),
              ),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 10),
      child: Column(children: [
        lane('🏃', me),
        lane('🐢', rival),
        Text(msg, style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      ]),
    );
  }
}

// ---------------------------------------------------------------- 🧩 البازل

/// صورة مقسومة ٢×٢: كل إجابة صح بتكشف قطعة. كل قطعة بترسم الصورة كاملة
/// بحجم الشبكة ومزحزحة بحيث يبان جزءها هي بس — زي بازل حقيقي.
class PuzzleGrid extends StatelessWidget {
  const PuzzleGrid({super.key, required this.pic, required this.open});
  final String pic;
  final int open;

  @override
  Widget build(BuildContext context) {
    const cols = 2, rows = 2, total = cols * rows, gap = 5.0;
    final side = context.clampVw(200, 54, 264);
    final piece = (side - gap * (cols + 1)) / cols;
    final shown = open.clamp(0, total);
    return Column(children: [
      Container(
        width: side,
        padding: const EdgeInsets.all(gap),
        margin: const EdgeInsets.only(top: 6, bottom: 4),
        // الإطار أغمق من القطع عشان الحدود بينها تبان
        decoration: BoxDecoration(color: const Color(0xFFC5CFDC), borderRadius: BorderRadius.circular(18)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(spacing: gap, runSpacing: gap, children: [
            for (var i = 0; i < total; i++)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Container(
                  width: piece,
                  height: piece,
                  color: i < shown ? Colors.white : const Color(0xFFEDF1F6),
                  child: i < shown
                      ? OverflowBox(
                          alignment: Alignment.topLeft,
                          maxWidth: piece * cols + gap,
                          maxHeight: piece * rows + gap,
                          child: Transform.translate(
                            offset: Offset(-(i % cols) * (piece + gap), -(i ~/ cols) * (piece + gap)),
                            child: SizedBox(
                              width: piece * cols + gap,
                              height: piece * rows + gap,
                              child: Center(child: Text(pic, style: TextStyle(fontSize: side * .7, height: 1))),
                            ),
                          ),
                        ).animate().fadeIn(duration: 350.ms).scaleXY(begin: .9, end: 1, duration: 350.ms)
                      : Center(child: Text('?', style: kidText(piece * .38, color: const Color(0xFFB4C0CF)))),
                ),
              ),
          ]),
        ),
      ),
      Text('${ar(shown)} / ${ar(total)} قطعة ظهرت',
          style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      const SizedBox(height: 8),
    ]);
  }
}

// ---------------------------------------------------------------- 🔺 الأشكال

/// شكل ملوّن من اختيار "شكل|لون" — من غير لون (المستوى الأول) بيترسم بنفسجي.
class ShapeIcon extends StatelessWidget {
  const ShapeIcon(this.value, {super.key, this.size = 56});
  final String value;
  final double size;

  @override
  Widget build(BuildContext context) {
    final [shape, color] = value.split('|');
    final c = shapeColors[color]?.$1 ?? 0xFF7A5CFF;
    return CustomPaint(size: Size.square(size), painter: _ShapePainter(shape, Color(c)));
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);
  final String shape;
  final Color color;

  // نفس نقط clip-path في الويب (بالنسبة المئوية)
  static const _star = [50, 0, 61, 35, 98, 35, 68, 57, 79, 91, 50, 70, 21, 91, 32, 57, 2, 35, 39, 35];
  static const _heart = [50, 100, 10, 60, 2, 36, 10, 16, 28, 10, 50, 26, 72, 10, 90, 16, 98, 36, 90, 60];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final w = size.width;
    Path poly(List<int> pts) {
      final p = Path()..moveTo(pts[0] * w / 100, pts[1] * w / 100);
      for (var i = 2; i < pts.length; i += 2) {
        p.lineTo(pts[i] * w / 100, pts[i + 1] * w / 100);
      }
      return p..close();
    }

    switch (shape) {
      case 'circle':
        canvas.drawCircle(Offset(w / 2, w / 2), w / 2, paint);
      case 'square':
        canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(w * .16)), paint);
      case 'triangle':
        canvas.drawPath(Path()..moveTo(w / 2, 0)..lineTo(w, w)..lineTo(0, w)..close(), paint);
      case 'star':
        canvas.drawPath(poly(_star), paint);
      default:
        canvas.drawPath(poly(_heart), paint);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) => old.shape != shape || old.color != color;
}

// ---------------------------------------------------------------- 🔵 دواير الذاكرة

/// عدد دواير في شبكة مرتّبة — أسهل في العدّ من صف نقط.
class DotCount extends StatelessWidget {
  const DotCount(this.n, {super.key, required this.color, this.dot = 12});
  final int n;
  final Color color;
  final double dot;

  @override
  Widget build(BuildContext context) {
    final cols = n == 4 ? 2 : 3;
    return SizedBox(
      width: cols * dot + (cols - 1) * dot * .7,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: dot * .7,
        runSpacing: dot * .7,
        children: [
          for (var i = 0; i < n; i++)
            Container(width: dot, height: dot, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        ],
      ),
    );
  }
}
