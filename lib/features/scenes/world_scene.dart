/// المشهد المتحرك ورا خريطة كل عالم — منقول من WORLD_SCENES و css/quran.css.
///
/// ساعة واحدة (Ticker) بتحرك كل العناصر؛ كل عنصر بيحسب مكانه من الوقت.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'art.dart';

class _SceneSpec {
  const _SceneSpec(this.sky, this.hills, this.balloons, this.rider, {this.kite = false, this.clouds = 3});
  final List<Color> sky;
  final List<Color> hills;
  final List<(String, Color)> balloons;
  final String rider;
  final bool kite;
  final int clouds;
}

const _specs = {
  'math': _SceneSpec(
    [Color(0xFF8FD6FF), Color(0xFFD8F1FF)], [Color(0xFF63C96A), Color(0xFF8ADB7E)],
    [('٤', Color(0xFFFF6B6B)), ('٧', Color(0xFF7A5CFF)), ('٩', Color(0xFF2FC9B4))], 'train'),
  'arabic': _SceneSpec(
    [Color(0xFFFFC98A), Color(0xFFFFF0D6)], [Color(0xFF5FC46B), Color(0xFF86D77C)],
    [('أ', Color(0xFFFF9F1C)), ('ب', Color(0xFFE8564F)), ('ت', Color(0xFF7A5CFF))], 'cat', kite: true, clouds: 2),
  'english': _SceneSpec(
    [Color(0xFF9FD8FF), Color(0xFFE6F6FF)], [Color(0xFF5BBF8E), Color(0xFF84D6A6)],
    [('A', Color(0xFF4CB8FF)), ('b', Color(0xFFFF6B6B)), ('C', Color(0xFFFFC43D))], 'car'),
  // عالم الألعاب: سما وردي مليانة بالونات ملوّنة، ومن غير حد ماشي على الأرض
  'games': _SceneSpec(
    [Color(0xFFFFD9E2), Color(0xFFFFF4E6)], [Color(0xFF4CC9A7), Color(0xFF7FE0C2)],
    [('٧', Color(0xFFFF6B6B)), ('٣', Color(0xFF4CC9A7)), ('٥', Color(0xFF4C9BFF))], 'none', clouds: 2),
};

class WorldScene extends StatefulWidget {
  const WorldScene({super.key, required this.world});
  final String world;

  @override
  State<WorldScene> createState() => _WorldSceneState();
}

class _WorldSceneState extends State<WorldScene> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    // ٣٠ إطار في الثانية كفاية لحركة هادية — نص الشغل والبطارية
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

  /// مرحلة حركة متكررة (٠–١) — التأخير بيتعامل كإزاحة عشان العنصر يبان من الأول.
  static double phase(double t, double dur, [double delay = 0]) => ((t - delay) % dur) / dur;

  @override
  Widget build(BuildContext context) {
    final spec = _specs[widget.world];
    if (spec == null) return const SizedBox();
    // الحركة الهادية بتتقفل لو المستخدم طالب تقليل الحركة
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [spec.sky[0], spec.sky[1], spec.sky[1]],
              stops: const [0, .62, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) => ValueListenableBuilder<double>(
              valueListenable: _t,
              builder: (context, t, _) => _build(context, spec, box.biggest, still ? 12 : t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _build(BuildContext context, _SceneSpec spec, Size s, double t) {
    final w = s.width, h = s.height;
    double vw(double min, double v, double max) => (w * v / 100).clamp(min, max);
    final children = <Widget>[];

    // الشمس: فوق على الشمال (inset-inline-end في صفحة RTL)
    final sunW = vw(72, 17, 120);
    children.add(Positioned(
      top: h * .04,
      left: w * .07,
      child: ArtBox(painter: SunPainter(t / 26), width: sunW),
    ));

    // السحاب بيعدّي من اليمين للشمال
    const clouds = [(.11, 1.0, .92, 48.0, 0.0), (.24, .72, .85, 66.0, 8.0), (.38, 1.15, .6, 84.0, 22.0)];
    final cloudW = vw(90, 26, 150);
    for (final (top, scale, op, dur, delay) in clouds.take(spec.clouds)) {
      final right = -170 + (w * 1.12 + 170) * phase(t, dur, delay);
      children.add(Positioned(
        top: h * top,
        left: w - right - cloudW,
        child: Opacity(
          opacity: op,
          child: Transform.scale(scale: scale, child: ArtBox(painter: CloudPainter(), width: cloudW)),
        ),
      ));
    }

    // طيارة ورق بتتمايل
    if (spec.kite) {
      final kw = vw(44, 11, 66);
      final k = math.sin(2 * math.pi * t / 7 - math.pi / 2) * .5 + .5; // ٠ → ١ → ٠
      children.add(Positioned(
        top: h * .14 - 16 * k,
        right: w * .14,
        child: Transform.rotate(
          angle: (-9 + 18 * k) * math.pi / 180,
          alignment: Alignment.topCenter,
          child: ArtBox(painter: KitePainter(), width: kw),
        ),
      ));
    }

    // بالونات بتطلع لفوق وتتمايل
    final bw = vw(42, 11, 62);
    const floaty = [(.12, 26.0, 0.0), (.46, 34.0, 9.0), (.76, 30.0, 18.0)];
    for (var i = 0; i < spec.balloons.length; i++) {
      final (start, dur, delay) = floaty[i];
      final p = phase(t, dur, delay);
      final bottom = -130 + (h * 1.12 + 130) * p;
      final (dx, rot) = _sway(p);
      children.add(Positioned(
        bottom: bottom,
        right: w * start + dx,
        child: Transform.rotate(
          angle: rot * math.pi / 180,
          child: Balloon(spec.balloons[i].$1, spec.balloons[i].$2, width: bw),
        ),
      ));
    }

    // التلال
    children.add(Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: (h * .22).clamp(90, 170),
      child: CustomPaint(painter: HillsPainter(spec.hills[0], spec.hills[1])),
    ));

    if (spec.rider == 'none') return Stack(clipBehavior: Clip.hardEdge, children: children);

    // اللي بيمشي على الأرض: القطر أو القطة أو العربية
    final (riderW, dur, delay) = switch (spec.rider) {
      'train' => (vw(170, 46, 290), 34.0, 0.0),
      'cat' => (vw(80, 21, 130), 40.0, 4.0),
      _ => (vw(110, 28, 170), 26.0, 2.0),
    };
    final right = -320 + (w * 1.08 + 320) * phase(t, dur, delay);
    final Widget rider = switch (spec.rider) {
      'train' => Train(
          labels: const ['١', '٢', '٣'],
          colors: const [Color(0xFFFFC43D), Color(0xFF2FC9B4), Color(0xFF7A5CFF)],
          width: riderW,
          t: t,
        ),
      'cat' => ArtBox(painter: CatPainter(t), width: riderW),
      _ => ArtBox(painter: CarPainter(), width: riderW),
    };
    children.add(Positioned(bottom: h * .03, left: w - right - riderW, child: rider));

    return Stack(clipBehavior: Clip.hardEdge, children: children);
  }

  /// تمايل البالونة: keyframes rise في الويب (إزاحة أفقية + ميل).
  static (double, double) _sway(double p) {
    const keys = [(0.0, 0.0, -4.0), (.25, 18.0, 4.0), (.5, -14.0, -4.0), (.75, 12.0, 3.0), (1.0, 0.0, 0.0)];
    for (var i = 0; i < keys.length - 1; i++) {
      final (a, x0, r0) = keys[i];
      final (b, x1, r1) = keys[i + 1];
      if (p <= b) {
        final k = (p - a) / (b - a);
        return (x0 + (x1 - x0) * k, r0 + (r1 - r0) * k);
      }
    }
    return (0, 0);
  }
}

/// غلاف بيحط المشهد ورا محتوى أي شاشة.
Widget sceneBackground(String world) => WorldScene(key: ValueKey(world), world: world);
