import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/core/widgets/learning_scope.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 5, 10);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  /// تطبيق صغير: الرئيسية، نشاط جوه LearningScope، وشاشة "وقت الراحة".
  Future<(ProviderContainer, GoRouter)> pumpApp(
    WidgetTester tester, {
    int limitMin = 0,
    int playedMs = 0,
    bool stopsItself = false,
  }) async {
    final p = ProgressData(settings: Settings(limitMin: limitMin))..addTime(playedMs);
    SharedPreferences.setMockInitialValues({ProgressRepository.key: jsonEncode(p.toJson())});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [sharedPrefsProvider.overrideWithValue(prefs)]);
    addTearDown(c.dispose);
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Text('home')),
      GoRoute(
        path: '/act',
        builder: (_, _) => LearningScope(stopsItself: stopsItself, child: const Text('activity')),
      ),
      GoRoute(path: '/timeup', builder: (_, _) => const Text('rest')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp.router(routerConfig: router),
    ));
    return (c, router);
  }

  Future<void> play(WidgetTester tester, int halfMinutes) async {
    for (var i = 0; i < halfMinutes; i++) {
      now = now.add(LearningScope.tick);
      await tester.pump(LearningScope.tick);
    }
  }

  Future<void> lifecycle(WidgetTester tester, List<AppLifecycleState> states) async {
    for (final s in states) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
  }

  testWidgets('an exhausted limit blocks direct entry without starting the activity', (tester) async {
    final (_, router) = await pumpApp(tester, limitMin: 10, playedMs: 10 * 60000);
    router.push('/act');
    await tester.pump();
    expect(find.text('activity'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('rest'), findsOneWidget);

    // الرجوع من وقت الراحة بيودّي للي قبل النشاط
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('activity time is recorded and a free activity stops when the limit is reached', (tester) async {
    final (c, router) = await pumpApp(tester, limitMin: 2);
    router.push('/act');
    await tester.pumpAndSettle();
    expect(find.text('activity'), findsOneWidget);

    await play(tester, 3);
    expect(c.read(progressProvider).todayMs, 90000);
    expect(find.text('activity'), findsOneWidget);

    await play(tester, 1);
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).todayMs, 120000);
    expect(find.text('rest'), findsOneWidget);
  });

  testWidgets('an activity that stops itself is not interrupted by the scope', (tester) async {
    final (c, router) = await pumpApp(tester, limitMin: 1, stopsItself: true);
    router.push('/act');
    await tester.pumpAndSettle();
    await play(tester, 4);
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).limitReached, isTrue);
    expect(find.text('activity'), findsOneWidget);
  });

  testWidgets('background time is not counted and leaving records the rest', (tester) async {
    final (c, router) = await pumpApp(tester);
    router.push('/act');
    await tester.pumpAndSettle();
    await play(tester, 1);

    await lifecycle(tester, [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]);
    now = now.add(const Duration(minutes: 10));
    await lifecycle(tester, [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]);

    now = now.add(const Duration(seconds: 20));
    router.pop();
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).todayMs, 50000);

    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 1));
    expect(c.read(progressProvider).todayMs, 50000, reason: 'home is not learning time');
  });
}
