import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// مستوى لكل مادة من لوحة ولي الأمر.
void main() {
  testWidgets('a parent sets a level for one subject and puts it back', (tester) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({
      ProgressRepository.key: jsonEncode({'setupDone': true, 'name': 'سارة', 'age': 6}),
    });
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(initialLocation: '/parent', routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
        quranChaptersProvider.overrideWith((ref) async => const <QuranChapter>[]),
      ],
      child: MaterialApp.router(routerConfig: router, locale: const Locale('ar')),
    ));
    await tester.pumpAndSettle();
    final c = ProviderScope.containerOf(tester.element(find.byType(DashboardScreen)));

    Finder chip(String world, String label) =>
        find.descendant(of: find.byKey(Key('level-$world')), matching: find.widgetWithText(ChoiceChip, label));
    Future<void> tap(Finder f) async {
      await tester.ensureVisible(f);
      await tester.pumpAndSettle();
      await tester.tap(f);
      await tester.pumpAndSettle();
    }

    expect(tester.widget<ChoiceChip>(chip('english', 'زي الباقي')).selected, isTrue);
    await tap(chip('english', 'سهل'));
    expect(c.read(progressProvider).settings.worldLevel, {'english': 1});
    expect(c.read(progressProvider).level('english'), 1);
    expect(c.read(progressProvider).level('math'), 3, reason: 'other subjects keep the age level');

    await tap(chip('english', 'زي الباقي'));
    expect(c.read(progressProvider).settings.worldLevel, isEmpty);
  });
}
