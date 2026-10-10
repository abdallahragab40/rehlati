import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:rehlati/content/quran_config.dart';
import 'package:rehlati/core/audio/audio_providers.dart';
import 'package:rehlati/domain/progress/learning_time.dart';
import 'package:rehlati/domain/progress/progress_controller.dart';
import 'package:rehlati/domain/progress/progress_data.dart';
import 'package:rehlati/domain/stages.dart';
import 'package:rehlati/features/daily/week_card.dart';
import 'package:rehlati/features/quran/quran_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'engine_test.dart' show FakeSfx, FakeSpeech, makeContainer;

List<String> targets(List<JourneyStep> s) => [for (final x in s) x.target];

void main() {
  late DateTime now;
  setUp(() {
    now = DateTime(2026, 10, 10, 9);
    ProgressData.clock = () => now;
  });
  tearDown(() => ProgressData.clock = DateTime.now);

  group('suggestions', () {
    test('a new child gets one clear starting suggestion', () {
      expect(targets(practiceSuggestions(ProgressData())), ['stage:counting']);
    });

    test('due reviews come first, then repeated mistakes, a surah, and at most three', () {
      final p = ProgressData(
        unlocked: ['counting', 'chooseNumber', 'addition'],
        best: {'counting': 3, 'chooseNumber': 2, 'addition': 1},
        skills: {'addition|add:3+4': 4, 'subtraction|sub:5-2': 6},
        quran: {'112:memorize': 3},
      )..recordMastery('chooseNumber', 9, 10);
      now = now.add(const Duration(days: 1));
      final s = practiceSuggestions(p);
      expect(targets(s), ['stage:chooseNumber', 'stage:addition', 'quran:112:review']);
      expect([for (final x in s) x.kind], [StepKind.review, StepKind.practice, StepKind.quran]);
      expect(targets(s), isNot(contains('stage:subtraction')), reason: 'locked stages are never suggested');
    });

    test('every stage suggestion opens an unlocked activity with a round', () {
      final p = ProgressData(best: {'counting': 1}, skills: {'counting|count:3': 3});
      for (final s in practiceSuggestions(p)) {
        if (s.stage case final st?) {
          expect(p.isUnlocked(st.id), isTrue);
          expect(st.isLearn, isFalse);
        }
      }
    });
  });

  test('learning time is split by world and adds up to the day total', () async {
    final c = await makeContainer();
    final t = c.read(learningTimeProvider)..enter('quran');
    now = now.add(const Duration(minutes: 1));
    t
      ..leave()
      ..enter('math');
    now = now.add(const Duration(seconds: 90));
    t.leave();
    final p = c.read(progressProvider);
    expect(p.weekWorlds(), {'quran': 60000, 'math': 90000});
    expect(p.weekWorlds().values.reduce((a, b) => a + b), p.weekSum().ms);
    expect(ProgressData.fromJson(p.toJson()).weekWorlds(), p.weekWorlds());
  });

  testWidgets('the weekly card names the child, explains the empty week and opens a suggestion', (tester) async {
    tester.view.physicalSize = const Size(1200, 2600);
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(overrides: [
      sharedPrefsProvider.overrideWithValue(prefs),
      speechProvider.overrideWithValue(FakeSpeech()),
      sfxProvider.overrideWithValue(FakeSfx()),
      quranChaptersProvider.overrideWith((ref) async => const <QuranChapter>[]),
    ]);
    addTearDown(c.dispose);
    c.read(progressProvider.notifier).update((p) => p.name = 'سارة');
    final router = GoRouter(routes: [
      GoRoute(path: '/', builder: (_, _) => const Scaffold(body: SingleChildScrollView(child: WeekCard()))),
      GoRoute(path: '/play/:stage', builder: (_, s) => Text('play ${s.pathParameters['stage']}')),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp.router(routerConfig: router)));
    await tester.pumpAndSettle();

    expect(find.textContaining('تقرير سارة'), findsOneWidget);
    expect(find.textContaining('لسه مفيش نشاط'), findsOneWidget);
    await tester.ensureVisible(find.text('تدرّب دلوقتي'));
    await tester.tap(find.text('تدرّب دلوقتي'));
    await tester.pumpAndSettle();
    expect(find.text('play ${packs['counting']!.id}'), findsOneWidget);
  });
}
