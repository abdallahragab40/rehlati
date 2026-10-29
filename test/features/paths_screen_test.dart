import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/paths/paths_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// مسارات التعلّم: القايمة، والدرس الحالي بأنشطته، والدروس الجاية مقفولة.
void main() {
  Future<GoRouter> pump(WidgetTester tester, Map<String, Object> values) async {
    tester.view
      ..physicalSize = const Size(360 * 3, 780 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final router = GoRouter(initialLocation: '/paths', routes: [
      GoRoute(path: '/', builder: (_, _) => const SizedBox()),
      GoRoute(path: '/paths', builder: (_, _) => const PathsScreen()),
      GoRoute(path: '/path/:id', builder: (_, s) => PathScreen(id: s.pathParameters['id']!)),
      GoRoute(path: '/play/:stage', builder: (_, s) => Text('play ${s.pathParameters['stage']} ${s.uri.query}')),
      GoRoute(path: '/madd/:stage', builder: (_, s) => Text('madd ${s.pathParameters['stage']} ${s.uri.query}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        speechProvider.overrideWithValue(FakeSpeech()),
        sfxProvider.overrideWithValue(FakeSfx()),
      ],
      child: MaterialApp.router(routerConfig: router, locale: const Locale('ar')),
    ));
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> tap(WidgetTester tester, Finder f) async {
    await tester.ensureVisible(f);
    await tester.pumpAndSettle();
    await tester.tap(f);
    await tester.pumpAndSettle();
  }

  testWidgets('a new child opens the first maths lesson and plays from the path', (tester) async {
    await pump(tester, {ProgressRepository.key: jsonEncode({'setupDone': true, 'age': 6})});
    expect(find.text('رحلة القراءة الأولى'), findsOneWidget);
    expect(find.text('درس ١ من ١٦'), findsNWidgets(9));

    final mathRow = find.ancestor(of: find.text('رحلة الأرقام'), matching: find.byType(Row)).first;
    await tap(tester, find.descendant(of: mathRow, matching: find.text('▶️ يلا')));
    expect(find.text('الأسبوع ١: الأعداد لحد ٢٠'), findsOneWidget);
    expect(find.text('🔒'), findsNWidgets(15), reason: 'only the first lesson is open');
    expect(find.text('⬜ 🔢 العد'), findsOneWidget);

    await tap(tester, find.text('▶️ يلا').first);
    expect(find.text('play counting from=path'), findsOneWidget);
  });

  testWidgets('a finished step and lesson show as done, and madd stages open their lesson first', (tester) async {
    await pump(tester, {
      ProgressRepository.key: jsonEncode({
        'setupDone': true,
        'paths': {
          'reading1': [
            for (final (l, ss) in [
              ('r1', ['ar_pick', 'ar_table']),
              ('r2', ['ar_match', 'ar_pick']),
              ('r3', ['ar_table', 'ar_match']),
              ('r4', ['ar_pick', 'ar_match', 'ar_table']),
              ('r5', ['ar_haraka', 'ar_haraka_pick']),
              ('r6', ['ar_haraka_pick', 'ar_build']),
              ('r7', ['ar_haraka', 'ar_compose']),
              ('r8', ['ar_haraka', 'ar_haraka_pick', 'ar_complete']),
              ('r9', ['madd_alif']),
            ])
              for (final s in ss) '$l:$s',
          ],
        },
      }),
    });
    expect(find.text('درس ٩ من ١٦'), findsOneWidget);
    final readingRow = find.ancestor(of: find.text('رحلة القراءة الأولى'), matching: find.byType(Row)).first;
    await tap(tester, find.descendant(of: readingRow, matching: find.text('▶️ كمّل')));

    expect(find.text('✅'), findsNWidgets(8));
    expect(find.text('✅ 🟦 المد بالألف'), findsOneWidget);
    expect(find.text('▶️ يلا'), findsOneWidget, reason: 'only the unfinished step can be started');
    await tap(tester, find.text('▶️ يلا'));
    expect(find.text('madd madd_waw from=path'), findsOneWidget);
  });
}
