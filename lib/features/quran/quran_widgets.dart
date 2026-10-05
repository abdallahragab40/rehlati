/// عناصر عالم القرآن المشتركة: مشهد السما، صندوق الآية، أزرار المشغّل، اختيار القارئ.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../content/quran_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/arabic.dart';
import '../../core/widgets/kid_widgets.dart';

const quranMint = Color(0xFF2FC9B4);
const quranMintDark = Color(0xFF1C8E7F);

// ---------------------------------------------------------------- مشهد السما

/// مشهد هادئ: سماء وغيم وطيور ونجوم وهلال ونخل وقبّة.
class QuranSky extends StatefulWidget {
  const QuranSky({super.key});

  @override
  State<QuranSky> createState() => _QuranSkyState();
}

class _QuranSkyState extends State<QuranSky> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final _t = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  static double _wave(double t, double period, [double delay = 0]) =>
      math.sin(2 * math.pi * (t - delay) / period - math.pi / 2) * .5 + .5;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF123A6B), Color(0xFF2C6BA8), Color(0xFF79B7D9), Color(0xFFCFE8E4)],
              stops: [0, .38, .72, 1],
            ),
          ),
          child: LayoutBuilder(
            builder: (context, box) => ValueListenableBuilder<double>(
              valueListenable: _t,
              builder: (context, t, _) => _scene(box.biggest, still ? 3 : t),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scene(Size s, double t) {
    final w = s.width, h = s.height;
    double vw(double min, double v, double max) => (w * v / 100).clamp(min, max);
    double phase(double dur, double delay) => ((t - delay) % dur) / dur;
    final children = <Widget>[];

    // نجوم بتلمع
    const stars = [(8, 14), (22, 9), (38, 17), (55, 8), (71, 15), (86, 10), (94, 20), (16, 24), (64, 22)];
    for (final (i, (x, y)) in stars.indexed) {
      final k = _wave(t, 2.6, i * .45);
      children.add(Positioned(
        left: w * x / 100,
        top: h * y / 100,
        child: Opacity(
          opacity: .25 + .75 * k,
          child: Transform.scale(
            scale: .7 + .55 * k,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xD9FFFFFF), blurRadius: 8, spreadRadius: 2)],
              ),
            ),
          ),
        ),
      ));
    }

    // الهلال (inset-inline-end = شمال في RTL)
    final m = _wave(t, 9);
    children.add(Positioned(
      top: h * .06 - 10 * m,
      left: w * .10,
      child: Transform.rotate(
        angle: (-6 + 10 * m) * math.pi / 180,
        child: Text('🌙', style: TextStyle(fontSize: vw(34, 9, 54), shadows: const [
          Shadow(color: Color(0xBFFFDC8C), blurRadius: 14),
        ])),
      ),
    ));

    // غيم ناعم
    const clouds = [(.16, 1.0, 1.0, 42.0, 0.0), (.30, .7, .75, 58.0, 6.0), (.46, 1.15, .5, 72.0, 18.0)];
    for (final (top, scale, op, dur, delay) in clouds) {
      final right = -160 + (w * 1.12 + 160) * phase(dur, delay);
      children.add(Positioned(
        top: h * top,
        left: w - right - 120,
        child: Opacity(opacity: op, child: Transform.scale(scale: scale, child: const _SoftCloud())),
      ));
    }

    // طيور
    const birds = [(.22, 1.0, 1.0, 24.0, 0.0, .5), (.27, .72, 1.0, 30.0, 3.0, .42), (.18, .58, .8, 34.0, 9.0, .58),
      (.35, .85, 1.0, 28.0, 14.0, .46), (.31, .5, .7, 38.0, 20.0, .5)];
    final bw = vw(26, 7, 40);
    for (final (top, scale, op, dur, delay, flap) in birds) {
      final p = phase(dur, delay);
      final right = -60 + (w * 1.08 + 60) * p;
      // ارتفاع بيطلع وينزل (keyframes fly)
      final bob = p < .25 ? -22 * p / .25 : p < .5 ? -22 + 32 * (p - .25) / .25 : p < .75 ? 10 - 24 * (p - .5) / .25 : -14 + 14 * (p - .75) / .25;
      final f = (t % (flap * 2)) / flap;
      children.add(Positioned(
        top: h * top + bob,
        left: w - right - bw,
        child: Opacity(
          opacity: op,
          child: Transform.scale(
            scale: scale,
            child: CustomPaint(size: Size(bw, bw * 22 / 40), painter: _BirdPainter(1 - .65 * (f <= 1 ? f : 2 - f))),
          ),
        ),
      ));
    }

    // نخل وقبّة تحت
    final sway = (-3 + 6 * _wave(t, 6)) * math.pi / 180;
    final sway2 = (-3 + 6 * _wave(t, 6, 1.4)) * math.pi / 180;
    final domeSize = vw(54, 15, 92);
    children
      ..add(Positioned(
        bottom: 0,
        right: w * .02,
        child: Transform.rotate(
          angle: sway,
          alignment: Alignment.bottomCenter,
          child: Text('🌴', style: TextStyle(fontSize: vw(46, 13, 80), height: 1)),
        ),
      ))
      ..add(Positioned(
        bottom: 0,
        left: w * .03,
        child: Opacity(
          opacity: .85,
          child: Transform.rotate(
            angle: sway2,
            alignment: Alignment.bottomCenter,
            child: Text('🌴', style: TextStyle(fontSize: vw(36, 10, 62), height: 1)),
          ),
        ),
      ))
      ..add(Positioned(
        bottom: -4,
        left: w / 2 - domeSize * .55,
        child: Opacity(opacity: .9, child: Text('🕌', style: TextStyle(fontSize: domeSize, height: 1))),
      ));

    return Stack(clipBehavior: Clip.hardEdge, children: children);
  }
}

class _SoftCloud extends StatelessWidget {
  const _SoftCloud();

  @override
  Widget build(BuildContext context) => Container(
        width: 120,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0x8CFFFFFF),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(color: Color(0x8CFFFFFF), offset: Offset(34, 8), spreadRadius: -6),
            BoxShadow(color: Color(0x73FFFFFF), offset: Offset(-34, 10), spreadRadius: -8),
          ],
        ),
      );
}

class _BirdPainter extends CustomPainter {
  _BirdPainter(this.flap);
  final double flap;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / 40, size.height / 22)
      // الجناحين بيرفرفوا حوالين النقطة (20, 11)
      ..translate(0, 11)
      ..scale(1, flap)
      ..translate(0, -11);
    final p = Paint()
      ..color = AppColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawPath(Path()..moveTo(2, 13)..quadraticBezierTo(10, 3, 20, 11), p)
      ..drawPath(Path()..moveTo(20, 11)..quadraticBezierTo(30, 3, 38, 13), p);
  }

  @override
  bool shouldRepaint(_BirdPainter old) => old.flap != flap;
}

// ---------------------------------------------------------------- الآيات

/// رقم الآية في دايرة.
class AyahNumber extends StatelessWidget {
  const AyahNumber(this.n, {super.key});
  final int n;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: quranMint, shape: BoxShape.circle),
        child: Text(ar(n), style: kidText(15, color: Colors.white, height: 1)),
      );
}

TextStyle ayahStyle(BuildContext context, {bool big = false}) => TextStyle(
      fontFamily: quranFont,
      fontSize: big ? context.clampVw(24, 6.4, 34) : context.clampVw(21, 5.4, 28),
      height: big ? 2.2 : 2.1,
      color: AppColors.ink,
    );

/// صندوق الآية — النص بيتعرض كما ورد من المصدر بدون أي تعديل.
class AyahBox extends StatelessWidget {
  const AyahBox(this.ayah, {super.key, this.active = false, this.big = false, this.onTap});
  final Ayah ayah;
  final bool active;
  final bool big;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0x242FC9B4) : AppColors.paper2,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: active ? quranMint : Colors.transparent, width: 3),
          ),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: ayah.text),
              const TextSpan(text: ' '),
              WidgetSpan(alignment: PlaceholderAlignment.middle, child: AyahNumber(ayah.number)),
            ]),
            textAlign: TextAlign.center,
            style: ayahStyle(context, big: big),
          ),
        ),
      );
}

/// زرار المشغّل (.pbtn).
class PlayerButton extends StatelessWidget {
  const PlayerButton(this.label, {super.key, required this.onTap, this.main = false, this.ok = false, this.semantic});
  final String label;
  final VoidCallback onTap;
  final bool main;
  final bool ok;
  final String? semantic;

  @override
  Widget build(BuildContext context) => Pressable3D(
        onTap: onTap,
        radius: 22,
        depth: 6,
        semanticLabel: semantic ?? label,
        color: main ? quranMint : (ok ? AppColors.grassDark : AppColors.paper),
        shadowColor: main ? quranMintDark : (ok ? const Color(0x40000000) : AppColors.shadow),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              widthFactor: 1,
              child: ExcludeSemantics(
                child: Text(label,
                    style: kidText(main || ok ? 20 : 24, color: main || ok ? Colors.white : AppColors.ink)),
              ),
            ),
          ),
        ),
      );
}

/// صف اختيار القارئ.
class ReciterPicker extends StatelessWidget {
  const ReciterPicker({super.key, required this.label, required this.value, required this.options, required this.onChanged});
  final String label;
  final String value;
  final List<Reciter> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(maxWidth: 560),
        margin: const EdgeInsets.only(top: 18),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: AppColors.shadow, offset: Offset(0, 5))],
        ),
        child: Row(children: [
          Text(label, style: kidText(16, weight: FontWeight.w700)),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              underline: const SizedBox(),
              style: kidText(15, weight: FontWeight.w700),
              items: [
                for (final r in options)
                  DropdownMenuItem(value: r.id, child: Text(r.label, overflow: TextOverflow.ellipsis)),
              ],
              onChanged: (v) => v == null ? null : onChanged(v),
            ),
          ),
        ]),
      );
}

// ---------------------------------------------------------------- تحميل وأخطاء

class QuranLoading extends StatelessWidget {
  const QuranLoading(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => QCard(
        child: Column(children: [
          const Text('📖', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text(text, style: kidText(24), textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text('بنجيب النص من المصدر الموثوق…', style: kidText(15, weight: FontWeight.w700, color: AppColors.inkSoft)),
          const SizedBox(height: 14),
          const CircularProgressIndicator(color: quranMint),
        ]),
      );
}

class QuranFailed extends StatelessWidget {
  const QuranFailed({super.key, required this.error, required this.sourceLabel, required this.onRetry, required this.onHome});
  final Object error;
  final String sourceLabel;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) => QCard(
        child: Column(children: [
          const Text('📡', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          Text('مش قادر أوصل لمصدر النص', style: kidText(22), textAlign: TextAlign.center),
          NoteBox(Text(
            'القسم ده بيجيب النص القرآني من مصدر موثوق على الإنترنت، فمحتاج اتصال أول مرة بس، '
            'وبعدين بيشتغل أوفلاين.\n\nالسبب: $error\nالمصدر: $sourceLabel',
          )),
          const SizedBox(height: 14),
          Wrap(spacing: 10, alignment: WrapAlignment.center, children: [
            KidButton('🔄 جرّب تاني', onTap: onRetry),
            KidButton('🏠 الرئيسية', kind: BtnKind.ghost, onTap: onHome),
          ]),
        ]),
      );
}

/// النقط اللي فوق (آية كام من كام).
class AyahDots extends StatelessWidget {
  const AyahDots({super.key, required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: Wrap(alignment: WrapAlignment.center, spacing: 6, runSpacing: 6, children: [
          for (var i = 0; i < count; i++)
            AnimatedScale(
              scale: i == current ? 1.35 : 1,
              duration: const Duration(milliseconds: 200),
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < current ? AppColors.gold : (i == current ? AppColors.paper : const Color(0x8CFFFFFF)),
                ),
              ),
            ),
        ]),
      );
}
