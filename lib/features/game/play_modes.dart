/// واجهات ألعاب التفكير والحركة: الظل، الأضداد، السلال، الأكواب، المتاهة، الألوان، وارسم بصباعك.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../content/play_data.dart';
import '../../core/motion.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/kid_widgets.dart';
import '../../domain/engine/game_engine.dart';
import '../../domain/question.dart';
import 'modes.dart';

TextStyle _emoji(double size) => TextStyle(fontSize: size, height: 1.1);

/// لوحة بيضا صغيرة جوه زرار الاختيار — الظل والأضداد بيبانوا عليها أوضح من لون المرحلة.
class _Panel extends StatelessWidget {
  const _Panel({required this.child, required this.size});
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
        child: child,
      );
}

// ---------------------------------------------------------------- 👤 الظل

/// الإيموجي أسود بالكامل (لون الحبر) — نفس filter: brightness(0) في الويب.
class ShadowPic extends StatelessWidget {
  const ShadowPic(this.emoji, {super.key, required this.size});
  final String emoji;
  final double size;

  static const _ink = <double>[
    0, 0, 0, 0, 45, //
    0, 0, 0, 0, 55,
    0, 0, 0, 0, 72,
    0, 0, 0, 1, 0,
  ];

  @override
  Widget build(BuildContext context) => _Panel(
        size: size,
        child: ColorFiltered(
          colorFilter: const ColorFilter.matrix(_ink),
          child: Text(emoji, style: _emoji(size * .62)),
        ),
      );
}

// ---------------------------------------------------------------- 🔄 الأضداد

/// رسمة صفة من "مفتاح|إيموجي": الحجم للكبير والصغير، الطول، المكان من الترابيزة،
/// والكوباية المليانة والفاضية. الباقي إيموجي عادي.
class OppositePic extends StatelessWidget {
  const OppositePic(this.spec, {super.key, required this.size});
  final String spec;
  final double size;

  @override
  Widget build(BuildContext context) {
    final i = spec.indexOf('|');
    final kind = spec.substring(0, i), e = spec.substring(i + 1);
    final Widget pic = switch (kind) {
      'big' => Text(e, style: _emoji(size * .7)),
      'small' => Align(alignment: Alignment.bottomCenter, child: Text(e, style: _emoji(size * .3))),
      'tall' => Transform.scale(scaleX: .9, scaleY: 1.5, child: Text(e, style: _emoji(size * .48))),
      'short' => Align(
          alignment: Alignment.bottomCenter,
          child: Transform.scale(scaleX: .9, scaleY: .6, alignment: Alignment.bottomCenter, child: Text(e, style: _emoji(size * .48))),
        ),
      'up' || 'down' => _Table(e, up: kind == 'up', size: size),
      'full' || 'empty' => CustomPaint(size: Size(size * .5, size * .66), painter: _GlassPainter(full: kind == 'full')),
      _ => Text(e, style: _emoji(size * .6)),
    };
    return _Panel(size: size, child: Padding(padding: EdgeInsets.all(size * .06), child: Center(child: pic)));
  }
}

/// ترابيزة بنية وحاجة فوقها أو تحتها.
class _Table extends StatelessWidget {
  const _Table(this.e, {required this.up, required this.size});
  final String e;
  final bool up;
  final double size;

  @override
  Widget build(BuildContext context) {
    const wood = Color(0xFFA0673A);
    final w = size * .8, top = size * .42;
    return SizedBox(
      width: w,
      height: size * .86,
      child: Stack(alignment: Alignment.topCenter, children: [
        Positioned(top: top, left: 0, right: 0, child: Container(height: size * .07, decoration: BoxDecoration(color: wood, borderRadius: BorderRadius.circular(4)))),
        Positioned(top: top, bottom: 0, left: w * .08, child: Container(width: size * .05, color: wood)),
        Positioned(top: top, bottom: 0, right: w * .08, child: Container(width: size * .05, color: wood)),
        if (up)
          Positioned(top: 0, height: top, child: Center(child: Text(e, style: _emoji(size * .3))))
        else
          Positioned(bottom: 0, child: Text(e, style: _emoji(size * .3))),
      ]),
    );
  }
}

class _GlassPainter extends CustomPainter {
  _GlassPainter({required this.full});
  final bool full;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final glass = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(w * .85, h)
      ..lineTo(w * .15, h)
      ..close();
    canvas.drawPath(glass, Paint()..color = const Color(0xFFF1F7FF));
    if (full) {
      final level = h * .12;
      final water = Path()
        ..moveTo(w * (level / h) * .15, level)
        ..lineTo(w - w * (level / h) * .15, level)
        ..lineTo(w * .85, h)
        ..lineTo(w * .15, h)
        ..close();
      canvas.drawPath(water, Paint()..color = const Color(0xFF63B3ED));
    }
    canvas.drawPath(
      glass,
      Paint()
        ..color = const Color(0xFF4A5568)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, w * .06)
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_GlassPainter old) => old.full != full;
}

// ---------------------------------------------------------------- 🗂️ صنّف

/// سلة النوع: صورتين منه واسمه.
class CategoryChoice extends StatelessWidget {
  const CategoryChoice(this.cat, {super.key});
  final String cat;

  @override
  Widget build(BuildContext context) {
    final (name, pics) = thingCats[cat]!;
    final e = context.clampVw(26, 7, 36);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(pics.join(' '), style: _emoji(e)),
      Text(name, style: kidText(context.clampVw(20, 5.4, 26), color: Colors.white)),
    ]);
  }
}

/// إيموجي وتحته اسمه (خطوات الوضوء والحكاية).
class PicNameChoice extends StatelessWidget {
  const PicNameChoice(this.emoji, this.name, {super.key});
  final String emoji;
  final String? name;

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: _emoji(context.clampVw(38, 10, 52))),
        if (name != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(name!,
                textAlign: TextAlign.center,
                style: kidText(context.clampVw(14, 3.8, 17), color: Colors.white, height: 1.25)),
          ),
      ]);
}

// ---------------------------------------------------------------- 🖼️ صورة كبيرة

class EmojiView extends StatelessWidget {
  const EmojiView(this.v, {super.key});
  final EmojiVisual v;

  @override
  Widget build(BuildContext context) => Column(children: [
        Text(v.emoji, style: _emoji(context.clampVw(88, 24, 124)))
            .anim()
            .scaleXY(begin: .5, end: 1, duration: 420.ms, curve: Curves.easeOutBack),
        if (v.caption != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(v.caption!, textAlign: TextAlign.center, style: kidText(context.clampVw(22, 6, 30), height: 1.35)),
          ),
      ]);
}

// ---------------------------------------------------------------- 🐱 فين القطة؟

class CupsGame extends StatelessWidget {
  const CupsGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q, n = q.cupCount;
    final slots = s.cupSlots.length == n ? s.cupSlots : [for (var i = 0; i < n; i++) i];
    final move = Duration(milliseconds: (q.cupStepMs * .8).round());
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final w = math.min(box.maxWidth, 440.0), slot = w / n;
        final cup = math.min(slot * .82, 110.0), h = cup * 1.9;
        double x(int i) => slot * slots[i] + (slot - cup) / 2;
        return SizedBox(
          width: w,
          height: h,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(height: 10, decoration: BoxDecoration(color: AppColors.line, borderRadius: BorderRadius.circular(6))),
            ),
            AnimatedPositioned(
              duration: move,
              curve: Curves.easeInOut,
              left: x(q.catCup),
              bottom: 6,
              width: cup,
              child: Center(child: Text('🐱', style: _emoji(cup * .56))),
            ),
            for (var i = 0; i < n; i++)
              AnimatedPositioned(
                key: ValueKey('cup$i'),
                duration: move,
                curve: Curves.easeInOut,
                left: x(i),
                bottom: s.cupLifted.contains(i) ? cup * .78 : 6,
                width: cup,
                height: cup,
                child: KeyedSubtree(key: keyFor('cup$i'), child: _cup(i, cup)),
              ),
          ]),
        );
      }),
      const SizedBox(height: 10),
      Text(q.hint,
          textAlign: TextAlign.center,
          style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
    ]);
  }

  Widget _cup(int i, double size) {
    Widget c = CustomPaint(size: Size.square(size), painter: _CupPainter(cupColors[i % cupColors.length]));
    if (s.wrongAnchor == 'cup$i') c = c.anim(key: ValueKey(s.wrongTick)).shakeX(hz: 5, amount: 6, duration: 400.ms);
    return Semantics(
      button: true,
      label: 'كوباية ${i + 1}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: s.cupReady && !s.locked ? () => engine.cupPick(i) : null,
        child: c,
      ),
    );
  }

  static const cupColors = [Color(0xFFFF6B6B), Color(0xFF4C9BFF), Color(0xFF36B37E), Color(0xFFC06BE8)];
}

/// كوباية مقلوبة: أضيق فوق وبوقها تحت، بشريط أبيض.
class _CupPainter extends CustomPainter {
  _CupPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = Path()
      ..moveTo(w * .2, 0)
      ..lineTo(w * .8, 0)
      ..lineTo(w * .96, h)
      ..lineTo(w * .04, h)
      ..close();
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawRect(Rect.fromLTWH(w * .1, h * .45, w * .8, h * .12), Paint()..color = Colors.white.withValues(alpha: .85));
    canvas.drawRRect(
      RRect.fromLTRBR(0, h * .9, w, h, const Radius.circular(6)),
      Paint()..color = Color.lerp(color, Colors.black, .2)!,
    );
  }

  @override
  bool shouldRepaint(_CupPainter old) => old.color != color;
}

// ---------------------------------------------------------------- 🐰 المتاهة

class MazeGame extends StatelessWidget {
  const MazeGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  /// الضغطة على اللوحة: خطوة ناحية الصباع في الاتجاه الأبعد.
  void _toward(Offset p, double cell) {
    final n = s.q.mazeSize;
    final c = Offset((s.mazeAt % n + .5) * cell, (s.mazeAt ~/ n + .5) * cell);
    final d = p - c;
    if (d.distance < cell * .4) return;
    d.dx.abs() > d.dy.abs() ? engine.mazeMove(0, d.dx.sign.toInt()) : engine.mazeMove(d.dy.sign.toInt(), 0);
  }

  @override
  Widget build(BuildContext context) {
    final q = s.q, n = q.mazeSize;
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth, 360.0), cell = side / n;
        Widget board = Container(
          width: side,
          height: side,
          decoration: BoxDecoration(color: const Color(0xFFEFF8E8), borderRadius: BorderRadius.circular(16)),
          child: Stack(children: [
            CustomPaint(size: Size.square(side), painter: _MazePainter(n, q.mazeWalls, [...s.mazeTrail], s.stage.color)),
            Positioned(
              left: (q.mazeGoal % n) * cell,
              top: (q.mazeGoal ~/ n) * cell,
              width: cell,
              height: cell,
              child: Center(child: Text('🥕', style: _emoji(cell * .55))),
            ),
            AnimatedPositioned(
              key: keyFor('maze'),
              duration: const Duration(milliseconds: 180),
              left: (s.mazeAt % n) * cell,
              top: (s.mazeAt ~/ n) * cell,
              width: cell,
              height: cell,
              child: Center(child: Text('🐰', style: _emoji(cell * .6))),
            ),
          ]),
        );
        if (s.mazeBump > 0) board = board.anim(key: ValueKey('bump${s.mazeBump}')).shakeX(hz: 6, amount: 5, duration: 300.ms);
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Semantics(
            label: 'المتاهة: الأرنب لازم يوصل للجزرة',
            child: GestureDetector(
              onTapUp: s.locked ? null : (d) => _toward(d.localPosition, cell),
              onPanEnd: s.locked
                  ? null
                  : (d) {
                      final v = d.velocity.pixelsPerSecond;
                      if (v.distance < 150) return;
                      v.dx.abs() > v.dy.abs() ? engine.mazeMove(0, v.dx.sign.toInt()) : engine.mazeMove(v.dy.sign.toInt(), 0);
                    },
              child: board,
            ),
          ),
        );
      }),
      const SizedBox(height: 14),
      _ArrowPad(onMove: s.locked ? null : engine.mazeMove, color: s.stage.color),
    ]);
  }
}

/// أسهم كبيرة بالاتجاهات الحقيقية (مش معكوسة في العربي).
class _ArrowPad extends StatelessWidget {
  const _ArrowPad({required this.onMove, required this.color});
  final void Function(int dr, int dc)? onMove;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = context.clampVw(62, 16, 76);
    Widget key(String icon, String label, int dr, int dc) => Pressable3D(
          onTap: onMove == null ? null : () => onMove!(dr, dc),
          color: color,
          radius: 20,
          depth: 6,
          semanticLabel: label,
          child: SizedBox.square(dimension: d, child: Center(child: Text(icon, style: kidText(d * .5, color: Colors.white)))),
        );
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(spacing: 8, children: [
        key('↑', 'فوق', -1, 0),
        Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 8, children: [
          key('←', 'شمال', 0, -1),
          key('↓', 'تحت', 1, 0),
          key('→', 'يمين', 0, 1),
        ]),
      ]),
    );
  }
}

class _MazePainter extends CustomPainter {
  _MazePainter(this.n, this.walls, this.trail, this.color);
  final int n;
  final List<int> walls;
  final List<int> trail;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / n;
    Offset center(int i) => Offset((i % n + .5) * cell, (i ~/ n + .5) * cell);
    // أثر الأرنب
    if (trail.length > 1) {
      final path = Path()..moveTo(center(trail.first).dx, center(trail.first).dy);
      for (final i in trail.skip(1)) {
        path.lineTo(center(i).dx, center(i).dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: .35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell * .22
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    final wall = Paint()
      ..color = const Color(0xFF3F6B2A)
      ..strokeWidth = math.max(4, cell * .09)
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n * n; i++) {
      final x = (i % n) * cell, y = (i ~/ n) * cell, w = walls[i];
      if (w & mazeN != 0) canvas.drawLine(Offset(x, y), Offset(x + cell, y), wall);
      if (w & mazeW != 0) canvas.drawLine(Offset(x, y), Offset(x, y + cell), wall);
      if (w & mazeS != 0) canvas.drawLine(Offset(x, y + cell), Offset(x + cell, y + cell), wall);
      if (w & mazeE != 0) canvas.drawLine(Offset(x + cell, y), Offset(x + cell, y + cell), wall);
    }
  }

  @override
  bool shouldRepaint(_MazePainter old) => old.trail.length != trail.length || old.walls != walls || old.trail.lastOrNull != trail.lastOrNull;
}

// ---------------------------------------------------------------- 🚦 كرر الألوان

class LightsGame extends StatelessWidget {
  const LightsGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  Widget build(BuildContext context) {
    final q = s.q;
    final size = context.clampVw(112, 30, 150);
    final pads = [for (final p in q.pads) KeyedSubtree(key: keyFor('pad${p.k}'), child: _pad(p, size))];
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, spacing: 10, children: [
          for (var i = 0; i < q.beats.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 16,
              height: 16,
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < s.picked.length ? AppColors.grass : AppColors.line),
            ),
        ]),
      ),
      Directionality(
        textDirection: TextDirection.ltr,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 14,
          children: pads.length == 4 ? [pads[0], pads[1], const SizedBox(width: double.infinity), pads[2], pads[3]] : pads,
        ),
      ),
      const SizedBox(height: 12),
      KidButton('▶️ شوف تاني', kind: BtnKind.ghost, onTap: s.rhythmLock || s.locked ? null : engine.rhythmPlay),
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
    final c = Color(p.color);
    return Semantics(
      button: true,
      label: p.name,
      child: GestureDetector(
        onTap: () => engine.rhythmTap(p.k),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: size,
          height: size,
          transform: Matrix4.diagonal3Values(lit ? 1.08 : 1, lit ? 1.08 : 1, 1),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: lit ? Color.lerp(c, Colors.white, .25) : c.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(size * .3),
            border: Border.all(color: Colors.white, width: lit ? 6 : 4),
            boxShadow: [
              if (lit) BoxShadow(color: c.withValues(alpha: .8), blurRadius: 28, spreadRadius: 6),
              BoxShadow(color: Color.lerp(c, Colors.black, .3)!.withValues(alpha: .5), offset: const Offset(0, 6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- ✍️ ارسم بصباعك

/// الشكل بيترسم رمادي والطفل يمشي عليه بصباعه. بنرسم الشكل على شبكة صغيرة (٤٠×٤٠)
/// عشان نعرف خاناته: الرسمة تنجح لما تغطّي معظم الخانات من غير ما تطلع برّه كتير.
/// ترتيب الخطوط واتجاهها مش متحسوبين — الهدف إن الإيد تتعوّد على الشكل.
class TraceGame extends StatefulWidget {
  const TraceGame({super.key, required this.s, required this.engine, required this.keyFor});
  final GameSession s;
  final GameEngine engine;
  final KeyFor keyFor;

  @override
  State<TraceGame> createState() => _TraceGameState();
}

class _TraceGameState extends State<TraceGame> {
  static const grid = 40;

  /// نسبة الشكل اللي لازم تتغطّى، وأقل نسبة من الرسمة لازم تكون فوق الشكل.
  static const needCover = .72, needOn = .6;

  final _strokes = <List<Offset>>[];
  List<bool>? _mask, _near;
  final _covered = <int>{};
  int _points = 0, _on = 0, _targets = 0;
  double _side = 0;
  int _tick = 0;

  String get glyph => widget.s.q.trace!;

  TextPainter _painter(double side) => TextPainter(
        text: TextSpan(text: glyph, style: kidText(side * (glyph.runes.length > 1 ? .5 : .72), height: 1.2)),
        textDirection: widget.s.q.ltr ? TextDirection.ltr : TextDirection.rtl,
      )..layout();

  @override
  void didUpdateWidget(TraceGame old) {
    super.didUpdateWidget(old);
    if (widget.s.traceTick != _tick) _clear();
  }

  void _clear() {
    _tick = widget.s.traceTick;
    _strokes.clear();
    _covered.clear();
    _points = 0;
    _on = 0;
  }

  /// قناع الشكل على الشبكة، والقناع "الواسع" شوية عشان الصباع مش دقيق.
  Future<void> _buildMask(double side) async {
    _side = side;
    final rec = ui.PictureRecorder();
    final canvas = Canvas(rec)..scale(grid / side);
    final tp = _painter(side);
    tp.paint(canvas, Offset((side - tp.width) / 2, (side - tp.height) / 2));
    final img = rec.endRecording().toImageSync(grid, grid);
    final data = await img.toByteData();
    img.dispose();
    if (!mounted || data == null) return;
    final mask = [for (var i = 0; i < grid * grid; i++) data.getUint8(i * 4 + 3) > 60];
    final near = List<bool>.filled(grid * grid, false);
    for (var i = 0; i < mask.length; i++) {
      if (!mask[i]) continue;
      final r = i ~/ grid, c = i % grid;
      for (var dr = -3; dr <= 3; dr++) {
        for (var dc = -3; dc <= 3; dc++) {
          final rr = r + dr, cc = c + dc;
          if (rr >= 0 && rr < grid && cc >= 0 && cc < grid) near[rr * grid + cc] = true;
        }
      }
    }
    setState(() {
      _mask = mask;
      _near = near;
      _targets = mask.where((m) => m).length;
    });
  }

  void _add(Offset p) {
    final mask = _mask, near = _near;
    if (mask == null || near == null) return;
    final g = grid / _side;
    final r = (p.dy * g).floor(), c = (p.dx * g).floor();
    if (r < 0 || r >= grid || c < 0 || c >= grid) {
      _points++;
      return;
    }
    _points++;
    if (near[r * grid + c]) _on++;
    // الصباع بيغطّي دايرة نص قطرها ٣ خانات
    for (var dr = -3; dr <= 3; dr++) {
      for (var dc = -3; dc <= 3; dc++) {
        final rr = r + dr, cc = c + dc;
        if (dr * dr + dc * dc > 10 || rr < 0 || rr >= grid || cc < 0 || cc >= grid) continue;
        if (mask[rr * grid + cc]) _covered.add(rr * grid + cc);
      }
    }
  }

  void _end() {
    if (_targets == 0 || widget.s.locked) return;
    final cover = _covered.length / _targets, on = _points == 0 ? 1 : _on / _points;
    if (cover >= needCover && on >= needOn) {
      widget.engine.traceDone();
    } else if (_points > 30 && on < needOn - .15) {
      widget.engine.traceOff();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final color = s.stage.color;
    return Column(children: [
      LayoutBuilder(builder: (context, box) {
        final side = math.min(box.maxWidth, 320.0);
        if (side != _side) {
          _side = side;
          _mask = null;
          _clear();
          _buildMask(side);
        }
        final done = s.locked;
        return Semantics(
          label: s.q.isEnglish ? 'Drawing board: trace $glyph' : 'لوحة الرسم: ارسم $glyph',
          child: GestureDetector(
            key: widget.keyFor('trace'),
            onPanStart: done
                ? null
                : (d) => setState(() {
                      _strokes.add([d.localPosition]);
                      _add(d.localPosition);
                    }),
            onPanUpdate: done
                ? null
                : (d) => setState(() {
                      if (_strokes.isEmpty) _strokes.add([]);
                      _strokes.last.add(d.localPosition);
                      _add(d.localPosition);
                    }),
            onPanEnd: done ? null : (_) => _end(),
            child: Container(
              width: side,
              height: side,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line, width: 3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CustomPaint(
                  size: Size.square(side),
                  painter: _TracePainter(_painter(side), [for (final st in _strokes) [...st]], color, done: done),
                ),
              ),
            ),
          ),
        );
      }),
      const SizedBox(height: 10),
      KidButton(s.q.isEnglish ? '🧽 Clear' : '🧽 امسح', kind: BtnKind.ghost, onTap: s.locked ? null : widget.engine.traceClear),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(s.q.hint,
            textAlign: TextAlign.center,
            style: kidText(context.clampVw(14, 3.6, 17), weight: FontWeight.w700, color: AppColors.inkSoft)),
      ),
    ]);
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter(this.tp, this.strokes, this.color, {required this.done});
  final TextPainter tp;
  final List<List<Offset>> strokes;
  final Color color;
  final bool done;

  @override
  void paint(Canvas canvas, Size size) {
    final at = Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2);
    // الشكل الرمادي (أو ملوّن لما الرسمة تخلص)
    final style = tp.text!.style!;
    final guide = TextPainter(
      text: TextSpan(text: (tp.text! as TextSpan).text, style: style.copyWith(color: done ? color : const Color(0xFFE3E8EF))),
      textDirection: tp.textDirection,
    )..layout();
    guide.paint(canvas, at);
    final line = Paint()
      ..color = color.withValues(alpha: done ? .0 : .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .075
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final st in strokes) {
      if (st.length == 1) {
        canvas.drawCircle(st.first, line.strokeWidth / 2, Paint()..color = line.color);
        continue;
      }
      final p = Path()..moveTo(st.first.dx, st.first.dy);
      for (final o in st.skip(1)) {
        p.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(p, line);
    }
  }

  @override
  bool shouldRepaint(_TracePainter old) => true;
}
