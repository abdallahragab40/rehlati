import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/settings/settings_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'parent_flow_test.dart' show answerOf;

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// الإعدادات بتتعدّل في مكانها — الزرار لازم يتحدّث على الشاشة فورًا.
void main() {
  testWidgets('settings switches and choices update when tapped', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(builder: (c) => TextButton(onPressed: () => showSettingsSheet(c), child: const Text('open'))),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    bool switchOf(String label) => tester
        .widget<Switch>(find.descendant(
            of: find.ancestor(of: find.text(label), matching: find.byType(Row)), matching: find.byType(Switch)))
        .value;

    expect(switchOf('🎵 أصوات اللعبة'), isTrue);
    await tester.tap(find.descendant(
        of: find.ancestor(of: find.text('🎵 أصوات اللعبة'), matching: find.byType(Row)), matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(switchOf('🎵 أصوات اللعبة'), isFalse);

    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '123')).selected, isFalse);
    await tester.tap(find.text('123'));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '123')).selected, isTrue);
  });

  testWidgets('resetting progress needs the parent gate', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({ProgressRepository.key: '{"stars": 5, "setupDone": true}'});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      speechProvider.overrideWithValue(FakeSpeech()),
      sfxProvider.overrideWithValue(FakeSfx()),
    ]);
    addTearDown(c.dispose);
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(builder: (c) => TextButton(onPressed: () => showSettingsSheet(c), child: const Text('open'))),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(
        routerConfig: router,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    Future<void> tapReset() async {
      await tester.ensureVisible(find.text('🗑️ إعادة ضبط التقدم'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🗑️ إعادة ضبط التقدم'));
      await tester.pumpAndSettle();
    }

    // طفل بيدوس: السؤال بيظهر، والإجابة الغلط مابتوصلش لتأكيد المسح
    await tapReset();
    expect(find.text('للأهل فقط'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('إعادة ضبط التقدم؟'), findsNothing);
    expect(c.read(progressProvider).stars, 5);
    await tester.pump(const Duration(seconds: 5)); // رسالة "إجابة غير صحيحة" تختفي
    await tester.pumpAndSettle();

    // ولي الأمر: الإجابة الصح بتفتح التأكيد
    await tapReset();
    await tester.enterText(find.byType(TextField), '${answerOf(tester.widget<Text>(find.textContaining('كام')).data!)}');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.text('إعادة ضبط التقدم؟'), findsOneWidget);
    await tester.tap(find.text('لا'));
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).stars, 5);
  });
}
