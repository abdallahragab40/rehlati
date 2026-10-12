import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/home/home_screen.dart';
import 'package:rehlati/features/intro/intro_screen.dart';
import 'package:rehlati/features/profiles/profiles.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// الترحيب: أول تشغيل بس، وبعده شاشة الاسم والعمر.
void main() {
  Future<SharedPreferences> pumpHome(WidgetTester tester, Map<String, Object> values) async {
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
      ],
      child: const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeScreen(),
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

    expect(find.byType(SetupScreen), findsOneWidget);
    expect(prefs.getBool(IntroController.key), isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('skip goes straight to setup', (tester) async {
    final prefs = await pumpHome(tester, {});
    await tap(tester, 'تخطّي');
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
      ProgressRepository.key: jsonEncode({'name': 'يوسف', 'setupDone': true}),
    });
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.byType(IntroScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
}
