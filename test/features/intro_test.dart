import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/home/home_screen.dart';
import 'package:rehlati/features/intro/intro_screen.dart';
import 'package:rehlati/features/profiles/profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;
import 'parent_flow_test.dart' show answerOf;

/// الترحيب: أول تشغيل بس، وبعده "مين معانا؟" وشاشة الاسم والعمر.
void main() {
  Future<SharedPreferences> pumpHome(WidgetTester tester, Map<String, Object> values, {GoRouter? router}) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        quranChaptersProvider.overrideWith((ref) async => const <QuranChapter>[]),
      ],
      child: router == null
          ? const MaterialApp(
              locale: Locale('ar'),
              supportedLocales: [Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              home: HomeScreen(),
            )
          : MaterialApp.router(
              routerConfig: router,
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
            ),
    ));
    await tester.pump(const Duration(seconds: 1));
    return prefs;
  }

  Future<void> tap(WidgetTester tester, String text) async {
    await tester.tap(find.text(text));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  testWidgets('a fresh install walks through the intro once, then setup', (tester) async {
    final prefs = await pumpHome(tester, {});
    expect(find.byType(IntroScreen), findsOneWidget);
    expect(find.text('أهلاً بيك يا بطل!'), findsOneWidget);

    await tap(tester, 'التالي');
    expect(find.text('خمس عوالم مستنياك'), findsOneWidget);
    await tap(tester, 'التالي');
    expect(find.text('اجمع النجوم واكسب الكؤوس'), findsOneWidget);
    await tap(tester, '🎒 يلا نبدأ الرحلة');
    expect(find.text('مين معانا دلوقتي؟'), findsOneWidget);
    expect(prefs.getBool(IntroController.key), isNull, reason: 'the intro is done only after picking who is here');
    await tap(tester, 'أنا البطل');

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(prefs.getBool(IntroController.key), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('skip goes to the role choice, then the child goes to setup', (tester) async {
    final prefs = await pumpHome(tester, {});
    await tap(tester, 'تخطّي');
    expect(find.text('مين معانا دلوقتي؟'), findsOneWidget);
    await tap(tester, 'أنا البطل');
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(prefs.getBool(IntroController.key), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('seen intro, reset child or a new sibling go straight to setup', (tester) async {
    await pumpHome(tester, {IntroController.key: true});
    expect(find.byType(SetupScreen), findsOneWidget);
    await tester.pumpWidget(const SizedBox());

    // أخ جديد من لوحة ولي الأمر على جهاز من قبل الترحيب
    await pumpHome(tester, {
      ProgressRepository.profilesKey: jsonEncode({'active': 'c1', 'ids': ['main', 'c1']}),
      ProgressRepository.key: jsonEncode({'name': 'يوسف', 'setupDone': true, 'grade': 'kg2'}),
    });
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.byType(IntroScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the parent answers the gate, adds a child and lands on the dashboard', (tester) async {
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
    ]);
    addTearDown(router.dispose);
    final prefs = await pumpHome(tester, {}, router: router);
    await tap(tester, 'تخطّي');

    // إجابة غلط: يفضل على "مين معانا؟"
    await tap(tester, 'أنا ولي الأمر');
    await tester.enterText(find.byType(TextField), '1');
    await tap(tester, 'دخول');
    expect(find.text('مين معانا دلوقتي؟'), findsOneWidget);

    await tap(tester, 'أنا ولي الأمر');
    await tester.enterText(find.byType(TextField), '${answerOf(tester.widget<Text>(find.textContaining('×')).data!)}');
    await tap(tester, 'دخول');
    expect(find.text('👋 أهلاً بيك يا ولي الأمر'), findsOneWidget);
    expect(find.text('مثال توضيحي'), findsOneWidget);

    await tester.ensureVisible(find.text('➕ ضيف طفلك'));
    await tap(tester, '➕ ضيف طفلك');
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(prefs.getBool(IntroController.key), isTrue);

    await tester.enterText(find.byType(TextField), 'يوسف');
    await tester.ensureVisible(find.text('KG2'));
    await tap(tester, 'KG2');
    await tester.ensureVisible(find.text('🚀 يلا نبدأ'));
    await tap(tester, '🚀 يلا نبدأ');
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('🧒 سلّم الجهاز ليوسف'), findsOneWidget);

    await tester.ensureVisible(find.text('🧒 سلّم الجهاز ليوسف'));
    await tap(tester, '🧒 سلّم الجهاز ليوسف');
    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.text('أهلاً يا يوسف!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
