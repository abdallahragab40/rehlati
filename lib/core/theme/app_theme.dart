/// الألوان والخطوط — منقولة من متغيرات css/style.css.
///
/// التطبيق نهاري دائمًا — الألوان الفاتحة أنسب للأطفال ومفيش وضع ليلي.
library;

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const sky1 = Color(0xFF58C7F3);
  static const sky2 = Color(0xFFA9E7FF);
  static const grass = Color(0xFF64D16B);
  static const grassDark = Color(0xFF36A94E);
  static const gold = Color(0xFFFFC43D);
  static const goldDark = Color(0xFFE39A00);
  static const coral = Color(0xFFFF6B6B);
  static const grape = Color(0xFF7A5CFF);
  static const mint = Color(0xFF2FC9B4);
  static const ink = Color(0xFF1B3557);
  static const inkSoft = Color(0xFF4C6A90);
  static const paper = Colors.white;
  static const paper2 = Color(0xFFF2F8FF);
  static const line = Color(0x241B3557); // rgba(27,53,87,.14)
  static const shadow = Color(0x381B3557); // rgba(27,53,87,.22)
  static const okBg = Color(0xFFDFF7E2);
  static const okInk = Color(0xFF17632E);
  static const noBg = Color(0xFFFFE6E6);
  static const noInk = Color(0xFFA62828);
  static const noteBg = Color(0xFFFFF3D6);
  static const noteInk = Color(0xFF7A4B00);
  static const confetti = [
    Color(0xFFFF6B6B), Color(0xFF7A5CFF), Color(0xFF2FC9B4), Color(0xFFFF9F1C), Color(0xFF4CB8FF),
    Color(0xFF1FAE9B), Color(0xFFE05FA8), Color(0xFF5FBF5F), Color(0xFFFFC43D), Color(0xFF6C7BFF),
  ];
}

const appFont = 'Baloo';
const quranFont = 'AmiriQuran';

/// أقصى عرض للمحتوى (زي #app في الويب) — على التابلت المحتوى بيتوسّط.
const maxContentWidth = 860.0;

/// نفس `clamp(min, Nvw, max)` في CSS — المقاس بيكبر مع عرض الشاشة لحد حد معيّن.
extension Responsive on BuildContext {
  double clampVw(double min, double vw, double max) {
    final w = MediaQuery.sizeOf(this).width.clamp(0.0, maxContentWidth);
    return (w * vw / 100).clamp(min, max);
  }
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    fontFamily: appFont,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.grape, surface: AppColors.paper),
    scaffoldBackgroundColor: AppColors.sky1,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.ink, displayColor: AppColors.ink, fontFamily: appFont),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: KidPageTransitions(),
      TargetPlatform.iOS: KidPageTransitions(),
    }),
  );
}

/// انتقال الشاشات: الجديدة بتنط لقدام (تكبير بارتداد خفيف) والقديمة بتبعد لورا شوية.
class KidPageTransitions extends PageTransitionsBuilder {
  const KidPageTransitions();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 420);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 280);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fade = CurvedAnimation(parent: animation, curve: const Interval(0, .5, curve: Curves.easeOut));
    if (MediaQuery.disableAnimationsOf(context)) return FadeTransition(opacity: fade, child: child);
    final pop = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    final away = CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInOut);
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: .94).animate(away),
      child: FadeTransition(
        opacity: fade,
        child: ScaleTransition(scale: Tween(begin: .86, end: 1.0).animate(pop), child: child),
      ),
    );
  }
}

TextStyle kidText(double size, {FontWeight weight = FontWeight.w800, Color color = AppColors.ink, double? height}) =>
    TextStyle(fontFamily: appFont, fontSize: size, fontWeight: weight, color: color, height: height);

/// مصفوفة تقليل التشبّع (filter: saturate(s)) — ١ = الألوان كاملة، ٠ = رمادي.
List<double> saturation(double s) {
  const r = .2126, g = .7152, b = .0722;
  return [
    r + (1 - r) * s, g - g * s, b - b * s, 0, 0,
    r - r * s, g + (1 - g) * s, b - b * s, 0, 0,
    r - r * s, g - g * s, b + (1 - b) * s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}
