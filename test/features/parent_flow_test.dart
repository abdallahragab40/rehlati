import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rehlati/domain/paths.dart';
import 'package:rehlati/features/paths/paths_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/core/widgets/top_bar.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/features/parent/dashboard_screen.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:rehlati/features/world_map/world_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/engine_test.dart' show FakeSfx, FakeSpeech;

/// يحوّل "كام ١٣ × ٧ ؟" لإجابة رقمية.
int answerOf(String q) {
  final latin = q.replaceAllMapped(RegExp('[٠-٩]'), (m) => '${m[0]!.codeUnitAt(0) - 0x0660}');
  final n = RegExp(r'\d+').allMatches(latin).map((m) => int.parse(m[0]!)).toList();
  return n[0] * n[1];
}

Future<void> pumpApp(
  WidgetTester tester, {
  Widget home = const ScreenFrame(child: SizedBox(height: 100)),
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => home),
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
  if (settle) await tester.pumpAndSettle();
}

Future<void> openGate(WidgetTester tester) async {
  await tester.tap(find.text('⚙️'));
  await tester.pumpAndSettle();
  final row = find.ancestor(of: find.text('👨‍👩‍👦 لوحة ولي الأمر'), matching: find.byType(Row));
  final open = find.descendant(of: row, matching: find.text('افتح'));
  await tester.ensureVisible(open);
  await tester.pumpAndSettle();
  await tester.tap(open);
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

  testWidgets('the home screen has a parent button behind the gate', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    await pumpApp(tester, home: const ScreenFrame(parent: true, child: SizedBox(height: 100)));

    await tester.tap(find.text('👨‍👩‍👦'));
    await tester.pumpAndSettle();
    final q = tester.widget<Text>(find.textContaining('×')).data!;
    await tester.enterText(find.byType(TextField), '${answerOf(q)}');
    await tester.tap(find.text('دخول'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);

    // التبويبات: الدليل فيه الدليلين، والإعدادات فيها التذكير
    await tester.tap(find.text('❤️ الدليل'));
    await tester.pumpAndSettle();
    expect(find.text('دليل ولي الأمر'), findsWidgets);
    expect(find.text('إزاي تستخدم التطبيق'), findsOneWidget);
    await tester.tap(find.text('⚙️ الإعدادات'));
    await tester.pumpAndSettle();
    expect(find.text('⏰ تذكير يومي'), findsOneWidget);
    expect(find.text('👧👦 الأطفال'), findsNothing);
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

  testWidgets('only the parent answer skips a stage on the map', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    // الخريطة فيها أنيميشن متكررة — مش بنستنى settle
    Future<void> frames() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpApp(tester, home: const WorldMapScreen(world: 'math'), settle: false);
    await frames();
    final p = ProviderScope.containerOf(tester.element(find.byType(WorldMapScreen))).read(progressProvider);
    expect(find.text('⏭️'), findsOneWidget, reason: 'only the first open stage can be skipped');

    await tester.tap(find.text('⏭️'));
    await frames();
    await tester.enterText(find.byType(TextField), '1');
    await tester.tap(find.text('دخول'));
    await frames();
    expect([p.skipped, p.isUnlocked('chooseNumber')], [isEmpty, false]);

    await tester.tap(find.text('⏭️'));
    await frames();
    final q = tester.widget<Text>(find.textContaining('×')).data!;
    await tester.enterText(find.byType(TextField), '${answerOf(q)}');
    await tester.tap(find.text('دخول'));
    await frames();
    final now = ProviderScope.containerOf(tester.element(find.byType(WorldMapScreen))).read(progressProvider);
    expect([now.skipped, now.isUnlocked('chooseNumber')], [['counting'], true]);
    expect(find.text('⏭️ اتخطّت'), findsOneWidget);
    expect(find.text('⏭️'), findsOneWidget, reason: 'the newly opened stage can be skipped next');
  });

  testWidgets('only the parent answer skips a learning-path step', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    Future<void> frames() async {
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await pumpApp(tester, home: const PathScreen(id: 'math1'), settle: false);
    await frames();
    final p = ProviderScope.containerOf(tester.element(find.byType(PathScreen))).read(progressProvider);
    expect(find.text('⏭️'), findsNWidgets(2), reason: 'one per step of the current lesson');

    await tester.tap(find.text('⏭️').first);
    await frames();
    final q = tester.widget<Text>(find.textContaining('×')).data!;
    await tester.enterText(find.byType(TextField), '${answerOf(q)}');
    await tester.tap(find.text('دخول'));
    await frames();
    expect(mathPath.skippedCount(p), 1);
    expect(find.text('⏭️'), findsOneWidget);
  });
}
