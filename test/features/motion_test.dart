import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/motion.dart';
import 'package:rehlati/core/widgets/fx_layer.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  tearDown(() => Motion.reduced = false);

  Widget pulse() => const Text('hint', textDirection: TextDirection.rtl)
      .anim(onPlay: (c) => c.repeat(reverse: true))
      .scaleXY(begin: 1, end: 1.1, duration: 400.ms);

  Widget entrance() => const Text('star', textDirection: TextDirection.rtl).anim(delay: 300.ms).fadeIn(duration: 400.ms);

  testWidgets('normally effects play and repeat', (tester) async {
    await tester.pumpWidget(Column(children: [pulse(), entrance()]));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(tester.widget<FadeTransition>(find.byType(FadeTransition).first).opacity.value, lessThan(1));
    await tester.pump(const Duration(milliseconds: 400)); // مهلة الـ delay تخلص
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('with reduced motion effects show their end state and nothing keeps animating', (tester) async {
    Motion.reduced = true;
    await tester.pumpWidget(Column(children: [pulse(), entrance()]));
    await tester.pump(const Duration(milliseconds: 1)); // مؤقت صفري بتعمله flutter_animate دايمًا
    expect(tester.binding.hasScheduledFrame, isFalse, reason: 'no repeating animation');
    expect(tester.widget<FadeTransition>(find.byType(FadeTransition).first).opacity.value, 1, reason: 'entrance already finished');
  });

  testWidgets('the calm setting turns motion down like the system setting', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MaterialApp(home: FxLayer(child: SizedBox())),
    ));
    expect(Motion.reduced, isFalse);
    expect(c.read(fxProvider).reduceMotion, isFalse);

    c.read(progressProvider.notifier).update((p) => p.settings.calm = true);
    await tester.pump();
    expect(Motion.reduced, isTrue);
    expect(c.read(fxProvider).reduceMotion, isTrue);
    expect(Settings.fromJson(c.read(progressProvider).settings.toJson()).calm, isTrue);

    c.read(progressProvider.notifier).update((p) => p.settings.calm = false);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(home: FxLayer(child: SizedBox())),
      ),
    ));
    expect(Motion.reduced, isTrue, reason: 'the system setting alone also counts');
  });

  testWidgets('effect texts above the navigator get no fallback underline', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    // زي التطبيق: الطبقة في builder فوق الـ Navigator، مش جوه شاشة
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(builder: (_, child) => FxLayer(child: child!), home: const SizedBox()),
    ));
    c.read(fxProvider).popMsg('🔥 ٥ على التوالي!', big: true);
    await tester.pump(const Duration(milliseconds: 100));
    final text = tester.widget<RichText>(find.descendant(of: find.text('🔥 ٥ على التوالي!'), matching: find.byType(RichText)));
    expect(text.text.style?.decoration ?? TextDecoration.none, TextDecoration.none);
    await tester.pump(const Duration(seconds: 5)); // الرسالة تخلص وتتشال
    await tester.pumpWidget(const SizedBox());
  });
}
