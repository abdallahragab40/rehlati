import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/home/home_screen.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// السن من ٣ لـ ١٢ في شاشة البداية، والصف الدراسي من لوحة ولي الأمر.
void main() {
  Future<ProviderContainer> pump(WidgetTester tester, Map<String, Object> values, Widget app) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final scope = ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        quranChaptersProvider.overrideWith((ref) async => const <QuranChapter>[]),
      ],
      child: app,
    );
    await tester.pumpWidget(scope);
    await tester.pump(const Duration(seconds: 1));
    return ProviderScope.containerOf(tester.element(find.byType(app.runtimeType)));
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('setup offers ages up to 12 and describes the introductory older maths pack', (tester) async {
    final c = await pump(
      tester,
      {'rehlati.intro.v1': true},
      const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: HomeScreen(),
      ),
    );
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('سنة'), findsNWidgets(2), reason: '١١ و١٢ سنة، مش سنين');

    await tester.tap(find.text('١١'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('فيه رحلة للقسمة والكسور لسن ٩–١٢'), findsOneWidget);

    await tester.ensureVisible(find.text('🚀 يلا نبدأ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('🚀 يلا نبدأ'));
    // الرئيسية فيها أنيميشن متكررة — مش بنستنى settle
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(c.read(progressProvider).age, 11);
    expect(c.read(progressProvider).level('math'), 3);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a parent sets and clears the school grade, and age keeps its own value', (tester) async {
    final router = GoRouter(
      initialLocation: '/parent',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
      ],
    );
    addTearDown(router.dispose);
    final c = await pump(tester, {
      ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'سارة', 'age': 7}),
    }, MaterialApp.router(routerConfig: router, locale: const Locale('ar')));
    await tester.pumpAndSettle();

    await tap(tester, find.text('🏫 الصف'));
    expect(find.text('تانية ابتدائي ⭐'), findsOneWidget, reason: 'the usual grade for age 7 is suggested');
    expect(find.text('مش عايز أحدد'), findsNothing);
    await tap(tester, find.text('تالتة ابتدائي'));
    expect(c.read(progressProvider).grade, 'p3');
    expect(c.read(progressProvider).age, 7);
    expect(find.textContaining('سارة • ٧ سنين • تالتة ابتدائي'), findsOneWidget);

    await tap(tester, find.text('🏫 الصف'));
    await tap(tester, find.text('مش عايز أحدد'));
    expect(c.read(progressProvider).grade, isNull);
  });
}
