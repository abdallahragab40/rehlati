/// رسومات المشاهد — نفس رسومات SVG في js/scenes.js بس مرسومة بـ CustomPainter
/// عشان الأجزاء الصغيرة (ديل القطة، رجليها، دخان القطر) تتحرك.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

final _paths = <String, Path>{};
Path _p(String d) => _paths.putIfAbsent(d, () => parseSvgPathData(d));

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round;

/// رسّام مبني على viewBox — بيكبّر الرسمة على مقاس الويدجت.
abstract class ArtPainter extends CustomPainter {
  ArtPainter(this.view);
  final Size view;

  void draw(Canvas c);

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / view.width, size.height / view.height);
    draw(canvas);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ويدجت بيرسم Art بعرض معيّن والارتفاع حسب نسبة الـ viewBox.
class ArtBox extends StatelessWidget {
  const ArtBox({super.key, required this.painter, required this.width, this.child});
  final ArtPainter painter;
  final double width;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: width,
        height: width * painter.view.height / painter.view.width,
        child: CustomPaint(painter: painter, child: child),
      );
}

// ---------------------------------------------------------------- الشمس

class SunPainter extends ArtPainter {
  /// [turn] لفّة الأشعة (٠–١).
  SunPainter(this.turn) : super(const Size(120, 120));
  final double turn;

  @override
  void draw(Canvas c) {
    c
      ..save()
      ..translate(60, 60)
      ..rotate(turn * 2 * math.pi);
    final ray = _stroke(const Color(0xFFFFCF4A), 7);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      c.drawLine(Offset(math.cos(a) * 40, math.sin(a) * 40), Offset(math.cos(a) * 54, math.sin(a) * 54), ray);
    }
    c
      ..restore()
      ..drawCircle(const Offset(60, 60), 32, _fill(const Color(0xFFFFD95E)))
      ..drawCircle(const Offset(50, 55), 3.6, _fill(const Color(0xFFE09B00)))
      ..drawCircle(const Offset(70, 55), 3.6, _fill(const Color(0xFFE09B00)))
      ..drawPath(_p('M50 68 q10 9 20 0'), _stroke(const Color(0xFFE09B00), 3.4));
  }
}

// ---------------------------------------------------------------- السحاب

class CloudPainter extends ArtPainter {
  CloudPainter() : super(const Size(130, 56));

  @override
  void draw(Canvas c) {
    final w = _fill(Colors.white);
    c
      ..drawOval(Rect.fromCenter(center: const Offset(36, 34), width: 52, height: 34), w)
      ..drawOval(Rect.fromCenter(center: const Offset(66, 26), width: 46, height: 42), w)
      ..drawOval(Rect.fromCenter(center: const Offset(95, 35), width: 40, height: 30), w)
      ..drawRRect(RRect.fromLTRBR(18, 33, 110, 50, const Radius.circular(8.5)), w);
  }
}

// ---------------------------------------------------------------- البالونة

class BalloonPainter extends ArtPainter {
  BalloonPainter(this.color) : super(const Size(64, 104));
  final Color color;

  @override
  void draw(Canvas c) {
    c
      ..drawOval(Rect.fromCenter(center: const Offset(32, 33), width: 50, height: 60), _fill(color))
      ..drawOval(Rect.fromCenter(center: const Offset(23, 23), width: 14, height: 20), _fill(const Color(0x59FFFFFF)))
      ..drawPath(_p('M32 62 l-6 9 h12 z'), _fill(color))
      ..drawPath(_p('M32 71 q8 12 0 24'), _stroke(const Color(0xCCFFFFFF), 2.5));
  }
}

/// بالونة بحرف أو رقم جواها.
class Balloon extends StatelessWidget {
  const Balloon(this.ch, this.color, {super.key, required this.width});
  final String ch;
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => ArtBox(
        painter: BalloonPainter(color),
        width: width,
        child: Align(
          alignment: const Alignment(0, -.42),
          child: Text(ch,
              style: TextStyle(fontFamily: 'Baloo', fontSize: width * .42, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
        ),
      );
}

// ---------------------------------------------------------------- القطر

const _wheel = Color(0xFF3B4A63), _hub = Color(0xFFC9D6E8);

class TrainPainter extends ArtPainter {
  /// [t] ثواني من بداية المشهد — للدخان.
  TrainPainter(this.colors, this.t) : super(Size(80 + colors.length * 54.0, 86));
  final List<Color> colors;
  final double t;

  @override
  void draw(Canvas c) {
    for (var i = 0; i < colors.length; i++) {
      c
        ..save()
        ..translate(i * 54.0, 0)
        ..drawRRect(RRect.fromLTRBR(0, 30, 46, 64, const Radius.circular(9)), _fill(colors[i]))
        ..drawCircle(const Offset(12, 70), 9, _fill(_wheel))
        ..drawCircle(const Offset(12, 70), 3.2, _fill(_hub))
        ..drawCircle(const Offset(34, 70), 9, _fill(_wheel))
        ..drawCircle(const Offset(34, 70), 3.2, _fill(_hub))
        ..drawRRect(RRect.fromLTRBR(-8, 52, 2, 57, const Radius.circular(2.5)), _fill(const Color(0xFF6B7A94)))
        ..restore();
    }
    c
      ..save()
      ..translate(colors.length * 54.0, 0)
      ..drawRRect(RRect.fromLTRBR(0, 22, 56, 64, const Radius.circular(10)), _fill(const Color(0xFFE8564F)))
      ..drawRRect(RRect.fromLTRBR(30, 4, 54, 28, const Radius.circular(7)), _fill(const Color(0xFFC7403A)))
      ..drawRRect(RRect.fromLTRBR(35, 9, 49, 21, const Radius.circular(4)), _fill(const Color(0xFFBFE3FF)))
      ..drawRRect(RRect.fromLTRBR(6, 2, 19, 24, const Radius.circular(5)), _fill(const Color(0xFFC7403A)));
    // ٣ نفخات دخان كل ٢.٤ ثانية بفرق ٠.٨
    for (final (i, r) in [7.0, 6.0, 5.0].indexed) {
      final p = ((t - i * .8) % 2.4) / 2.4;
      final e = Curves.easeOut.transform(p);
      c.drawCircle(
        Offset(12 - 26 * e, -2 - 46 * e),
        r * (.5 + 1.2 * e),
        _fill(Colors.white.withValues(alpha: .85 * (1 - e))),
      );
    }
    c
      ..drawCircle(const Offset(14, 70), 11, _fill(_wheel))
      ..drawCircle(const Offset(14, 70), 4, _fill(_hub))
      ..drawCircle(const Offset(42, 70), 11, _fill(_wheel))
      ..drawCircle(const Offset(42, 70), 4, _fill(_hub))
      ..restore();
  }
}

/// قطر بعربيات فيها أرقام.
class Train extends StatelessWidget {
  const Train({super.key, required this.labels, required this.colors, required this.width, required this.t});
  final List<String> labels;
  final List<Color> colors;
  final double width;
  final double t;

  @override
  Widget build(BuildContext context) {
    final p = TrainPainter(colors, t);
    final k = width / p.view.width;
    return ArtBox(
      painter: p,
      width: width,
      child: Stack(children: [
        for (var i = 0; i < labels.length; i++)
          Positioned(
            left: i * 54 * k,
            top: 30 * k,
            width: 46 * k,
            height: 34 * k,
            child: Center(
              child: Text(labels[i],
                  style: TextStyle(fontFamily: 'Baloo', fontSize: 24 * k, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
            ),
          ),
      ]),
    );
  }
}

// ---------------------------------------------------------------- القطة

class CatPainter extends ArtPainter {
  CatPainter(this.t) : super(const Size(110, 80));
  final double t;

  @override
  void draw(Canvas c) {
    // الديل بيتهز (alternate ١.٣ ثانية) والرجلين بيمشوا (alternate ٠.٤٢)
    double alt(double period) {
      final p = (t % (period * 2)) / period;
      return Curves.easeInOut.transform(p <= 1 ? p : 2 - p);
    }

    final wag = (-12 + 26 * alt(1.3)) * math.pi / 180;
    c
      ..save()
      ..translate(25.3, 48.6)
      ..rotate(wag)
      ..translate(-25.3, -48.6)
      ..drawPath(_p('M28 50 q-20 0 -18 -18 q1 -11 11 -9'), _stroke(const Color(0xFFE8973A), 8))
      ..restore()
      ..drawOval(Rect.fromCenter(center: const Offset(54, 52), width: 60, height: 36), _fill(const Color(0xFFF7AE4A)));
    final step = -3 + 6 * alt(.42);
    final leg = _fill(const Color(0xFFE8973A));
    c
      ..drawRRect(RRect.fromLTRBR(36 + step, 63, 44 + step, 77, const Radius.circular(4)), leg)
      ..drawRRect(RRect.fromLTRBR(64 + step, 63, 72 + step, 77, const Radius.circular(4)), leg)
      ..drawRRect(RRect.fromLTRBR(48, 63, 56, 77, const Radius.circular(4)), _fill(const Color(0xFFF7AE4A)))
      ..drawCircle(const Offset(86, 36), 19, _fill(const Color(0xFFFBB85C)))
      ..drawPath(_p('M72 23 l-2 -14 l13 7 z'), _fill(const Color(0xFFFBB85C)))
      ..drawPath(_p('M100 23 l3 -14 l-13 7 z'), _fill(const Color(0xFFFBB85C)))
      ..drawPath(_p('M74 22 l-1 -8 l7 4 z'), _fill(const Color(0xFFF08C94)))
      ..drawPath(_p('M98 22 l2 -8 l-7 4 z'), _fill(const Color(0xFFF08C94)))
      ..drawCircle(const Offset(79, 34), 3.4, _fill(const Color(0xFF36405A)))
      ..drawCircle(const Offset(93, 34), 3.4, _fill(const Color(0xFF36405A)))
      ..drawPath(_p('M86 41 l-4 3 h8 z'), _fill(const Color(0xFFF08C94)))
      ..drawPath(_p('M86 44 q-5 5 -9 1 M86 44 q5 5 9 1'), _stroke(const Color(0xFF36405A), 2));
  }
}

// ---------------------------------------------------------------- العربية

class CarPainter extends ArtPainter {
  CarPainter() : super(const Size(140, 76));

  @override
  void draw(Canvas c) {
    c
      ..drawPath(
          _p('M12 52 q0 -14 14 -14 l12 0 q10 -16 28 -16 l16 0 q14 0 20 16 l14 0 q14 0 14 14 l0 6 q0 6 -6 6 l-106 0 q-6 0 -6 -6 z'),
          _fill(const Color(0xFF4CB8FF)))
      ..drawPath(_p('M50 38 q8 -12 18 -12 l10 0 l0 12 z'), _fill(const Color(0xFFCFEBFF)))
      ..drawPath(_p('M84 26 q10 0 15 12 l-15 0 z'), _fill(const Color(0xFFCFEBFF)))
      ..drawCircle(const Offset(40, 38), 5, _fill(const Color(0xFFFFE08A)))
      ..drawCircle(const Offset(40, 64), 12, _fill(_wheel))
      ..drawCircle(const Offset(40, 64), 4.5, _fill(const Color(0xFFD7E3F2)))
      ..drawCircle(const Offset(104, 64), 12, _fill(_wheel))
      ..drawCircle(const Offset(104, 64), 4.5, _fill(const Color(0xFFD7E3F2)));
  }
}

// ---------------------------------------------------------------- الطيارة الورق

class KitePainter extends ArtPainter {
  KitePainter() : super(const Size(70, 130));

  @override
  void draw(Canvas c) {
    c
      ..drawPath(_p('M35 4 L62 40 L35 78 L8 40 Z'), _fill(const Color(0xFFFF7A59)))
      ..drawPath(_p('M35 4 L35 78 M8 40 L62 40'), _stroke(const Color(0x99FFFFFF), 2.5))
      ..drawPath(_p('M35 78 q10 16 -4 26 q-12 10 2 22'), _stroke(const Color(0xFFFFC43D), 3))
      ..drawPath(_p('M28 92 l14 0 M24 108 l14 0'), _stroke(const Color(0xFF2FC9B4), 4));
  }
}

// ---------------------------------------------------------------- التلال

class HillsPainter extends CustomPainter {
  HillsPainter(this.front, this.back);
  final Color front, back;

  @override
  void paint(Canvas canvas, Size size) {
    // preserveAspectRatio="none" — بتتمط على عرض الشاشة
    canvas
      ..save()
      ..scale(size.width / 400, size.height / 110)
      ..drawPath(_p('M0 58 q60 -34 120 -4 q55 27 110 -8 q60 -38 170 8 L400 110 L0 110 Z'), _fill(back))
      ..drawPath(_p('M0 80 q70 -26 140 2 q70 28 140 -4 q60 -26 120 6 L400 110 L0 110 Z'), _fill(front))
      ..restore();
  }

  @override
  bool shouldRepaint(HillsPainter old) => old.front != front || old.back != back;
}
