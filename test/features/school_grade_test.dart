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
import 'package:rehlati/features/profiles/profiles.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// شاشة البداية: الاسم والمرحلة (KG1 لسادسة) إجباري، ولو حاجة ناقصة بيظهر toast. والمرحلة بتتغيّر من لوحة ولي الأمر.
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

  const home = MaterialApp(
    locale: Locale('ar'),
    supportedLocales: [Locale('ar')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: HomeScreen(),
  );

  Future<void> start(WidgetTester tester) async {
    await tester.ensureVisible(find.text('🚀 يلا نبدأ'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('🚀 يلا نبدأ'));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('setup offers KG1 to sixth primary and needs both the name and the grade', (tester) async {
    final c = await pump(tester, {'rehlati.intro.v1': true}, home);
    for (final g in ['KG1', 'KG2', 'أولى', 'تانية', 'تالتة', 'رابعة', 'خامسة', 'سادسة']) {
      expect(find.text(g), findsOneWidget, reason: g);
    }
    expect(find.text('عنده كام سنة؟'), findsNothing, reason: 'the age is not asked any more');

    await start(tester);
    expect(find.text('اكتب اسم الطفل واختار المرحلة الدراسية عشان نبدأ'), findsOneWidget);
    expect(c.read(progressProvider).setupDone, isFalse);
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('اكتب اسم الطفل واختار المرحلة الدراسية عشان نبدأ'), findsNothing, reason: 'the toast goes away');

    await tester.enterText(find.byType(TextField), 'س');
    await start(tester);
    expect(find.text('الاسم قصير قوي — اكتب حرفين على الأقل'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '  سارة ');
    await start(tester);
    expect(find.text('اختار المرحلة الدراسية الأول 🎒'), findsOneWidget);
    expect(c.read(progressProvider).setupDone, isFalse);

    await tester.ensureVisible(find.text('خامسة'));
    await tester.tap(find.text('خامسة'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('دروس كتاب الوزارة بتاعة خامسة ابتدائي'), findsOneWidget);
    await start(tester);
    // الرئيسية فيها أنيميشن متكررة — مش بنستنى settle
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    final p = c.read(progressProvider);
    expect([p.name, p.grade, p.age, p.setupDone], ['سارة', 'p5', 10, true]);
    expect(p.level('math'), 3);
    expect(find.text('أهلاً يا سارة!'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('old progress without a grade goes back to setup, keeps its stars and has no cancel', (tester) async {
    final c = await pump(tester, {
      ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'يوسف', 'stars': 40}),
    }, home);
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('👋 نكمّل الرحلة!'), findsOneWidget);
    expect(find.text('إلغاء'), findsNothing);
    expect(find.widgetWithText(TextField, 'يوسف'), findsOneWidget, reason: 'the saved name is kept');

    await tester.ensureVisible(find.text('KG2'));
    await tester.tap(find.text('KG2'));
    await start(tester);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect([c.read(progressProvider).grade, c.read(progressProvider).stars], ['kg2', 40]);
    expect(find.byType(SetupScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a parent changes the grade and the name from the dashboard, never to nothing', (tester) async {
    final router = GoRouter(
      initialLocation: '/parent',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox()),
        GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
      ],
    );
    addTearDown(router.dispose);
    final c = await pump(tester, {
      // تقدّم قديم بالسن بس: ٧ سنين بقت تانية ابتدائي
      ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'سارة', 'age': 7}),
    }, MaterialApp.router(routerConfig: router, locale: const Locale('ar')));
    await tester.pumpAndSettle();
    expect(find.text('🎒 تانية ابتدائي'), findsOneWidget);
    expect(find.text('🎂 السن'), findsNothing);

    await tap(tester, find.text('🎒 المرحلة'));
    expect(find.text('مش عايز أحدد'), findsNothing, reason: 'the grade is required');
    await tap(tester, find.text('تالتة'));
    expect(c.read(progressProvider).grade, 'p3');
    expect(find.textContaining('المرحلة بقت تالتة ابتدائي'), findsOneWidget);
    expect(find.textContaining('سارة • تالتة ابتدائي'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));

    await tap(tester, find.text('✏️ الاسم'));
    await tester.enterText(find.byType(TextField), '   ');
    await tap(tester, find.text('حفظ'));
    expect(find.text('اكتب اسم الطفل الأول ✏️'), findsOneWidget);
    expect(find.text('اسم الطفل'), findsOneWidget, reason: 'the dialog stays open');
    expect(c.read(progressProvider).name, 'سارة');
    await tester.enterText(find.byType(TextField), 'سارة أحمد');
    await tap(tester, find.text('حفظ'));
    expect(c.read(progressProvider).name, 'سارة أحمد');
    expect(find.text('الاسم اتحفظ: سارة أحمد'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
  });
}
