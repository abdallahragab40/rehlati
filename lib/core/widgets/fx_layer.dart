/// طبقة المؤثرات فوق كل الشاشات (زي #fx في الويب): نجوم بتطير، ومضة، رسائل، حلقات، كونفيتي.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../theme/app_theme.dart';

class _Fx {
  _Fx(this.id, this.builder);
  final int id;
  final Widget Function(Size screen) builder;
}

class FxController extends ChangeNotifier {
  final _items = <_Fx>[];
  final _rnd = math.Random();
  int _seq = 0;

  void _add(Duration life, Widget Function(Size) b) {
    final fx = _Fx(_seq++, b);
    _items.add(fx);
    notifyListeners();
    Timer(life, () {
      _items.remove(fx);
      notifyListeners();
    });
  }

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  /// مركز أي ويدجت على الشاشة — عشان المؤثر يطلع من مكان الزرار.
  static Offset? centerOf(GlobalKey? key) {
    final box = key?.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || !box.attached) return null;
    return box.localToGlobal(box.size.center(Offset.zero));
  }

  /// نجوم/إيموجي بتتطاير من نقطة.
  void burst(Offset? at, int n, String ch) {
    if (at == null) return;
    for (var i = 0; i < n; i++) {
      final dx = _r(-130, 130), dy = _r(-170, -50), rot = _r(-220, 220) / 360;
      _add(950.ms, (_) => Positioned(
            left: at.dx - 18,
            top: at.dy - 22,
            child: Text(ch, style: const TextStyle(fontSize: 30))
                .animate()
                .move(begin: Offset.zero, end: Offset(dx, dy), duration: 900.ms, curve: Curves.easeOut)
                .scaleXY(begin: .4, end: 1.4, duration: 900.ms)
                .rotate(begin: 0, end: rot, duration: 900.ms)
                .fadeOut(duration: 900.ms, curve: Curves.easeIn),
          ));
    }
  }

  /// ومضة لون على الشاشة كلها — خضرا للصح وحمرا للغلط.
  void flash({required bool ok}) {
    final c = ok ? const Color(0x6B64D16B) : const Color(0x57FF6B6B);
    _add(700.ms, (_) => Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(center: const Alignment(0, .1), radius: .9, colors: [c, c.withAlpha(0)], stops: const [0, .62]),
            ),
          ).animate().fadeIn(duration: 117.ms).then().fadeOut(duration: 533.ms),
        ));
  }

  /// رسالة بتطلع في النص وتختفي.
  void popMsg(String text, {bool big = false, bool sad = false}) {
    final life = big ? 1600 : 1200;
    final (bg, fg, sh) = sad
        ? (AppColors.paper, AppColors.ink, AppColors.shadow)
        : big
            ? (AppColors.coral, Colors.white, const Color(0xFFCC4444))
            : (AppColors.gold, const Color(0xFF4A2B00), AppColors.goldDark);
    _add(life.ms, (s) => Positioned(
          left: 0,
          right: 0,
          top: s.height * .42,
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: s.width * .86),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [BoxShadow(color: sh, offset: const Offset(0, 8))],
              ),
              child: Text(text, textAlign: TextAlign.center, style: kidText(sad ? 40 : (big ? 34 : 28), color: fg)),
            )
                .animate()
                .scaleXY(begin: .3, end: 1, duration: (life * .22).round().ms, curve: Curves.easeOutBack)
                .fadeIn(duration: (life * .22).round().ms)
                .then(delay: (life * .5).round().ms)
                .fadeOut(duration: (life * .28).round().ms)
                .moveY(begin: 0, end: -20, duration: (life * .28).round().ms),
          ),
        ));
  }

  /// حلقات لامعة حوالين العنصر.
  void sparkle(Offset? at) {
    if (at == null) return;
    for (var i = 0; i < 3; i++) {
      _add(1300.ms, (_) => Positioned(
            left: at.dx - 15,
            top: at.dy - 15,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gold, width: 5)),
            )
                .animate(delay: (i * 160).ms)
                .scaleXY(begin: .4, end: 5.5, duration: 1000.ms, curve: Curves.easeOut)
                .fade(begin: .9, end: 0, duration: 1000.ms),
          ));
    }
  }

  void confetti(int n) {
    for (var i = 0; i < n; i++) {
      final x = _r(0, 1), dur = _r(1.8, 3.4), delay = _r(0, .9);
      final color = AppColors.confetti[_rnd.nextInt(AppColors.confetti.length)];
      _add(4200.ms, (s) => Positioned(
            left: x * s.width,
            top: -24,
            child: Container(
              width: 12,
              height: 18,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
            )
                .animate(delay: (delay * 1000).round().ms)
                .moveY(begin: 0, end: s.height * 1.1, duration: (dur * 1000).round().ms)
                .rotate(begin: 0, end: 2, duration: (dur * 1000).round().ms),
          ));
    }
  }
}

final fxProvider = ChangeNotifierProvider<FxController>((ref) => FxController());

/// بتتحط مرة واحدة فوق التطبيق كله (MaterialApp.builder).
class FxLayer extends ConsumerWidget {
  const FxLayer({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fx = ref.watch(fxProvider);
    final size = MediaQuery.sizeOf(context);
    return Stack(
      children: [
        child,
        IgnorePointer(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              const SizedBox.expand(),
              for (final f in fx._items) KeyedSubtree(key: ValueKey(f.id), child: f.builder(size)),
            ],
          ),
        ),
      ],
    );
  }
}
