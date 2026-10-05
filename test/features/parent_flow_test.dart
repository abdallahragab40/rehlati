import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/widgets/top_bar.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// يحوّل "كام ١٣ × ٧ ؟" لإجابة رقمية.
int answerOf(String q) {
  final latin = q.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  final n = RegExp(r'\d+').allMatches(latin).map((m) => int.parse(m[0]!)).toList();
  return n[0] * n[1];
}

Future<void> pumpApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => const ScreenFrame(child: SizedBox(height: 100))),
    GoRoute(path: '/parent', builder: (_, _) => const DashboardScreen()),
  ]);
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
}

Future<void> openGate(WidgetTester tester) async {
  await tester.tap(find.text('⚙️'));
  await tester.pumpAndSettle();
  final row = find.ancestor(of: find.text('👨‍👩‍👦 لوحة ولي الأمر'), matching: find.byType(Row));
  await tester.tap(find.descendant(of: row, matching: find.text('افتح')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the right answer opens the parent dashboard', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await openGate(tester);

    final q = tester.widget<Text>(find.textContaining('كام')).data!;
    await tester.enterText(find.byType(TextField), '${answerOf(q)}');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(find.text('بدون اسم'), findsOneWidget);
  });

  testWidgets('a wrong answer keeps the child out', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await openGate(tester);

    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsNothing);
    expect(find.text('إجابة غير صحيحة.'), findsOneWidget);
  });
}
